#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='\033[1m\W > \033[0m'

alias ls='exa -lha --color=auto --group-directories-first'

alias l='ls'
alias v='vim'
alias c='cd'
alias c.='cd ..'
alias q='exit'
alias m='neomutt'
alias f='firefox &'
alias n='newsboat'
alias s='sxiv'

alias pl='pacman -Qe'
alias pf='pacman -Ss'
alias pi='sudo pacman -Sy'
alias pp='sudo pacman -Syu'

alias g='git'
alias ga='git add'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gg='git clone'

alias rrm='rm -rf'

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
