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
		shortdesc = "Paroles";
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
    message_wgt = dialog:add_label("", 3, 10, 1, 1)
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
    if vlc.input.is_playing() then
        set_lyrics_listening_file()
        display_lyrics()
    else
        display_message_VLC_not_playing()
    end
end

function display_lyrics_selected()
	local i = selection_lyrics_wgt:get_value()
    lyrics_file = list_table[i]
    display_lyrics()
end

function open_current_music_folder()
    if vlc.input.is_playing() then
        io.popen(BROWSER..' "'..get_listening_file_path()..'"')
    else
        display_message_VLC_not_playing()
    end
end

function open_lyrics_folder()
	io.popen(BROWSER..' "'..LYRICS_FOLDER..'"')
end

function modify_lyrics()
    if lyrics_file ~= "" then
        io.popen(EDITOR.." '"..lyrics_file.."'")
    else
        -- Escape quotes whereas display a message saying : modify metadatas cause there are quotes in artist or title
        io.popen(EDITOR.." '"..escape_character_in_quote(get_formatted_file_path()).."'")
    end
end

-- 
function display_message_VLC_not_playing()
    message_wgt:set_text("<i>No file started in VLC</i>")
end

function display_lyrics()
    if lyrics_file ~= "" then
        title_wgt:set_text("<strong>"..get_file_name_LINUX(lyrics_file).."<strong>")
        lyrics_wgt:set_text("<h3>"..get_lyrics(lyrics_file).."</h3>")
        message_wgt:set_text("")
    else
        title_wgt:set_text("<strong>"..get_formatted_file_name().."<strong>")
        lyrics_wgt:set_text("<h3></h3>")
        message_wgt:set_text("<i>No lyrics found</i>")
    end
end

function set_lyrics_listening_file()
	local lyrics_listening_file = ""
    -- Try with audio file name
	local lyrics_listening_file = get_listening_file_path().."."..LYRICS_EXTENSION
	local f = io.open(lyrics_listening_file, "rt")
	if f~=nil then
        f:close()
        lyrics_file = lyrics_listening_file
        return
    end
    -- Try with metadatas
    local lyrics_listening_file = get_formatted_file_path()
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
function get_listening_file_metadata(metadata)
	local item = vlc.input.item()
	if item~=nil then
		local metas = item:metas()
		if metas[metadata] then
			return metas[metadata]
		else
			return ""
		end
	end
    return ""
end

function get_lyrics(path)
    local file = io.open(path, "rt")
    if file==nil then
        return ""
    end

	local content = ""
	for line in file:lines() do
        content = content..line.."<br />"
	end

    file:close()
    return content
end

function get_listening_file_uri()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
	local uri = item:uri()
    uri = vlc.strings.decode_uri(uri)
	return uri
end

function get_listening_file_path()
	return get_file_path(get_listening_file_uri())
end

function get_listening_file_filename()
	return get_file_name_LINUX(get_listening_file_uri())
end

function get_formatted_file_path()
	return LYRICS_FOLDER..get_formatted_file_name().."."..LYRICS_EXTENSION
end

function get_formatted_file_name()
	return get_listening_file_metadata("artist").." - "..get_listening_file_metadata("title")
end

function get_file_path(uri)
    return vlc.strings.make_path(uri)
end

function get_file_path_LINUX(uri)
	uri = string.gsub(uri, "^file://", "")
	uri = uri:match("/.*/")
    return uri
end

function get_file_name_LINUX(uri)
	uri = uri:match("([^/]+)$")
	uri = string.gsub(uri, "^(.+)%.%w+$", "%1")
    return uri
end

function get_file_name_WINDOWS(uri)
	uri = uri:match("([^\]+)$")
	uri = string.gsub(uri, "^(.+)%.%w+$", "%1")
    return uri
end

function get_file_extention(uri)
	uri = uri:match("([^.]+)$")
    return uri
end

function escape_character_in_quote(str)
    for i = 1, string.len(str) do
       if str:sub(i,i) == "'" then
            str = str:sub(1, pos-1).." "..str:sub(pos+1)
        end
    end
    return str
end
