# INCOMPLETE
# Various tools here to start in kiosk mode
# Should handle running media from connected USB
# OR starting X and an APP
# OR starting X and a browser
# AND allow working with multiple monitors

touch $HOME/.snippit_kiosk_begin


command -v cvlc \
|| echo "### `basename $0`: missing cvlc"
command -v matchbox-window-manager \
|| echo "### `basename $0`: missing matchbox-window-manager"
command -v chromium-browser \
|| echo "### `basename $0`: missing chromium-browser"
command -v xrandr \
|| echo "### `basename $0`: xrandr (x11-xserver-utils)"


xrandr --output HDMI-2 --auto --right-of HDMI-1 --scale-from 1024x600


touch $HOME/.snippit_kiosk_complete
