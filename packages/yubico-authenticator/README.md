# Yubico Authenticator

Run `./bin/pm install yubico-authenticator` from the repository root. The
package installs the Flathub build for your user and enables the host PC/SC
socket so the smart-card service starts on demand.

Connect the YubiKey and open **Yubico Authenticator** from the app menu, or run
`flatpak run com.yubico.yubioath`.

If the app reports a smart-card connection error, check
`systemctl status pcscd.socket` and `journalctl -b -u pcscd.service`.
