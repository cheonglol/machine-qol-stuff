#!/bin/bash
# RustDesk Headless XFCE - New Machine COMPLETE Setup
# Save as setup-rustdesk-headless.sh

# 1. Install dummy driver
sudo apt update && sudo apt install -y xserver-xorg-video-dummy

# 2. Create dummy display config
sudo mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-rustdesk.conf << 'EOF'
Section "Device"
    Identifier "rustdesk"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Screen"
    Identifier "rustdesk-screen"
    Device "rustdesk"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
        Virtual 1920 1080
    EndSubSection
EndSection
EOF

# 3. XFCE lid ignore (overrides GUI settings)
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitchDocked=suspend/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

# 4. Create THE SINGLE autostart script
cat > ~/rustdesk-headless.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
xset s off && xset -dpms && xset s noblank
xrandr --output eDP-1 --primary --mode 1920x1080 --rate 60.05 --fb 1920x1080 2>/dev/null || true
echo "RustDesk Headless Active" >> /tmp/rustdesk.log
EOF
chmod +x ~/rustdesk-headless.sh

# 5. systemd service (runs on boot BEFORE login)
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/rustdesk-headless.service << 'EOF'
[Unit]
Description=RustDesk Headless
After=graphical-session.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=DISPLAY=:0
ExecStart=/bin/bash %h/rustdesk-headless.sh

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable rustdesk-headless.service

echo "✅ COMPLETE! Reboot and test lid closed + RustDesk"
