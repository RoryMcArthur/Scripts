[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# mouse refresh rate
xset r rate 200 50 &

# remove cursor when inactive
unclutter &

# set desktop wallpaper
xwallpaper --zoom ~/bg.jpg &

# fix screen tearing issue (imac)
picom --config /dev/null --backend glx --vsync &
# picom --backend glx --vsync &

# bind custom keyboard settings
xbindkeys &

# setup status bar loop
~/bin/dwmstatusloop &

# get bitcoin price
# ~/bin/updatebtc &

exec dwm 

