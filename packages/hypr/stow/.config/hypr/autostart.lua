-- Personal workspace assignments (silent keeps startup apps from taking focus).
o.window("^main-terminal$", { workspace = "1 silent" })
o.window("^(Brave-browser|brave-browser|com\\.brave\\.Browser|chromium)$", { workspace = "2 silent" })
o.window("^(org\\.telegram\\.desktop|TelegramDesktop)$", { workspace = "3 silent" })
o.window("^(chrome|brave)-web\\.whatsapp\\.com__-.*$", { workspace = "3 silent" })

o.launch_on_start(os.getenv("HOME") .. "/.local/bin/hypr-main-terminal")
o.launch_on_start("omarchy-launch-browser")
o.launch_on_start("flatpak run org.telegram.desktop")
o.launch_on_start("omarchy-launch-webapp https://web.whatsapp.com/")
