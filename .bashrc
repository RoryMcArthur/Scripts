#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# alias ls='ls  -lha --color=auto --group-directories-first'
alias ls='exa -lha --color=auto --group-directories-first'
alias du='du -h -d 0'
alias df='df -h'
alias pm='sudo pacman'
alias sd='sudo shutdown now'
PATH="$HOME/bin:$PATH"

# XDG_CONFIG_HOME="$HOME/.config"

# line width of manpages
export MANWIDTH=80

export LANG=en_US.UTF-8
export LC_TIME=en_US.UTF-8
