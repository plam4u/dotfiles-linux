#!/usr/bin/env bash

# Workspace 1: Development (Terminal, ChatGPT)
xfce4-terminal \
    --disable-server \
    --class=DevTerminal \
    --command="tmux new-session -A -s main" &
# if command -v chatgpt >/dev/null; then
#     chatgpt &
# fi

# ChatGPT PWA
gtk-launch "brave-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop" &

# Workspace 2: Browser
if command -v brave-browser >/dev/null; then
    brave-browser &
elif command -v flatpak >/dev/null && flatpak info com.brave.Browser >/dev/null 2>&1; then
    flatpak run com.brave.Browser &
fi

# Workspace 3: Messaging (Telegram, WhatsApp)
if command -v flatpak >/dev/null && flatpak info org.telegram.desktop >/dev/null 2>&1; then
    flatpak run org.telegram.desktop &
fi
whatsapp=brave-hnpfjngllnobngcgfapefoaidbinmjnm-Default
if [[ -f ${XDG_DATA_HOME:-$HOME/.local/share}/applications/$whatsapp.desktop ]] && command -v gtk-launch >/dev/null; then
    gtk-launch "$whatsapp" &
fi

# Workspace 4: Media (YouTube, Twitch, Plex)
# gtk-launch brave-agimnkijcaahngcdmfeangaknmldooml-Default &
# gtk-launch brave-idniplokpnmiplmpfgamffjpfbfemgim-Default &
# gtk-launch brave-bdlnfdpdhknidkahpgicifonclffkmck-Default &

# Workspace 5: Gaming
# steam &

# Workspace 6: Notes
# obsidian &

# Scratchpad
"$HOME/.config/i3/scratch-terminal.sh" &

# Return to workspace 1
i3-msg "workspace number 1"
