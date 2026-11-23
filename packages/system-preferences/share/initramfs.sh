rebuild_initramfs() {
    local ID
    . /etc/os-release
    case $ID in
        debian) sudo /usr/sbin/update-initramfs -u ;;
        arch) sudo mkinitcpio -P ;;
        omarchy)
            if ! command -v limine-mkinitcpio >/dev/null; then
                sudo pacman -S --needed --noconfirm limine-mkinitcpio-hook
            fi
            sudo limine-mkinitcpio
            ;;
    esac
}
