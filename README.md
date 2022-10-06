# Paroles
It's a VLC extension.

# Description
Display lyrics from a lyrics folder.

The main purpose is to display lyrics of current playing file based on :
- the same name file with suffix .lyr
- or its metadatas with suffix .lyr like artist - title.lyr

Features :
- Select lyrics in lyrics folder with suffix .lyr to display it.
- Open an editor to modify lyrics

# How-to install

1. Download file to ~/.local/share/vlc/lua/extensions (create folders if needed)
2. In file parole.lua, modify LYRICS_FOLDER variable (line 5) to your lyrics folder path (ex: /home/my/path)
3. Load : Menu → Tools → Plugins and extensions -> Active extensions -> Reload extensions
4. Display : View -> Paroles

If lyrics doesn't display, right-click on playing file in vlc then Informations... to modify metadatas and match with your lyrics file.

# Compatibility
- Linux
- VLC v3.0
