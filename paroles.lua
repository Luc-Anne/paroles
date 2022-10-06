-- CONFIGURATION
BROWSER = "nautilus"
EDITOR = "gedit"

LYRICS_FOLDER = "your_path_to_lyrics_folder"
LYRICS_EXTENSION = "lyr"

dialog = nil

function descriptor()
	return {
		title = "Paroles";
        author = "Luc Anne";
		shortdesc = "Display lyrics from Lyrics folder";
		description = "<center><b>Paroles</b></center>"
		.. "Display lyrics from Lyrics folder";
        url = "https://github.com/Luc-Anne/paroles";
        version = "1.0";
		capabilities = { "input-listener"; "meta-listener" }
	}
end

-- Function triggered when the extension is activated
function activate()
	vlc.msg.dbg("[Paroles] Activating")
	init_dialog()
end

function init_dialog()
	dialog = vlc.dialog("Paroles")

	-- column, row, col_span, row_span, width, height
    dialog:add_button("Show current lyrics", display_lyrics_listening, 1, 1, 1, 1)
    title_wgt = dialog:add_label("", 2, 1, 3, 1)
    
    dialog:add_button("Show selected lyrics", display_lyrics_selected, 1, 2, 1, 1)
    selection_lyrics_wgt = dialog:add_dropdown(2, 2, 3, 1)
    fill_selection_lyrics_wgt()
    
	lyrics_wgt = dialog:add_html("", 1, 7, 4, 3)
    
    dialog:add_button("Current music folder", open_current_music_folder, 1, 10, 1, 1)
    dialog:add_button("Lyrics folder", open_lyrics_folder, 2, 10, 1, 1)
    dialog:add_button("Modify those lyrics", modify_lyrics, 4, 10, 1, 1)

	input_changed()
end

-- Function triggered when the extension is deactivated
function deactivate()
	close()
	vlc.msg.dbg("[Paroles] Deactivated")
end

-- Function triggered when the dialog is closed
function close()
	dialog:delete()
	vlc.deactivate()
end

-- Function triggered when the music changed
function input_changed()
	display_lyrics_listening()
	dialog:update()
end

-- Buttons events
function display_lyrics_listening()
    set_lyrics_listening_file()
    display_lyrics()
end

function display_lyrics_selected()
	local i = selection_lyrics_wgt:get_value()
    lyrics_file = list_table[i]
    display_lyrics()
end

function open_current_music_folder()
	io.popen(BROWSER.." '"..get_musique_path().."'")
end

function open_lyrics_folder()
	io.popen(BROWSER.." '"..LYRICS_FOLDER.."'")
end

function modify_lyrics()
	io.popen(EDITOR.." '"..lyrics_file.."'")
end

-- 
function display_lyrics()
    if lyrics_file ~= "" then
        title_wgt:set_text("<i>"..get_file_name(lyrics_file).."</i>")
        lyrics_wgt:set_text("<h3>"..read_file(lyrics_file).."</h3>")
    else
        title_wgt:set_text("<i></i>")
        lyrics_wgt:set_text("<h3></h3>")
    end
end

function get_musique_metadata(metadata)
	local item = vlc.input.item()
	if(item ~= nil) then
		local metas = item:metas()
		if metas[metadata] then
			return metas[metadata]
		else
			return ""
		end
	end
end

function set_lyrics_listening_file()
	local lyrics_listening_file = ""

    -- Try with audio file name
    local musique_uri_without_ext = get_musique_filename(get_musique_uri())
	local lyrics_listening_file = musique_uri_without_ext .. "." .. LYRICS_EXTENSION
	local f = io.open(lyrics_listening_file, "rt")
	if f~=nil then
        f:close()
        lyrics_file = lyrics_listening_file
        return
    end
    -- Try with metadatas
    local lyrics_listening_file = LYRICS_FOLDER..get_musique_metadata("artist").." - "..get_musique_metadata("title").."."..LYRICS_EXTENSION
    local f = io.open(lyrics_listening_file, "rt")
    if f~=nil then
        f:close()
        lyrics_file = lyrics_listening_file
        return
    end
    -- Empty if none
    lyrics_file = ""
end

function fill_selection_lyrics_wgt()
	list_table = {}
    
    local LYRICS_FOLDER_files = vlc.io.readdir(LYRICS_FOLDER)
    table.sort(LYRICS_FOLDER_files)
    for i,f in pairs(LYRICS_FOLDER_files) do
        local file_extention = get_file_extention(f)
        if file_extention=="lyr" then
            selection_lyrics_wgt:add_value(f, i)
            list_table[i] = LYRICS_FOLDER..f
        end
    end

end

-- File
function read_file(path)
	if path=="" then return "" end
    local file = io.open(path, "rt")
    if file==nil then return "" end
	local content = ""
	
	for line in file:lines() do
        content = content..line.."<br />"
	end

    file:close()
    return content
end

function get_musique_uri()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
	local uri = item:uri()
    uri = vlc.strings.decode_uri(uri)
	return uri
end

function get_musique_filename()
	return get_file_name(get_musique_uri())
end

function get_musique_path()
	return get_file_path(get_musique_uri())
end

function get_file_path(uri)
	uri = string.gsub(uri, "^file://", "")
	uri = uri:match("/.*/")
    return uri
end

function get_file_name(uri)
	uri = uri:match("([^/]+)$")
	uri = string.gsub(uri, "^(.+)%.%w+$", "%1")
    return uri
end

function get_file_extention(uri)
	uri = uri:match("([^.]+)$")
    return uri
end
