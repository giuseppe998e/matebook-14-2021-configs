# Starship.rs
if command -v "starship" >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Syntax Highlighting plugin
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Auto Suggestions plugin
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ZSH Configs
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=1000
export SAVEHIST=$HISTSIZE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Aliases
## TLP
alias tlp-ac="sudo tlp ac"
alias tlp-bat="sudo tlp bat"
## Toolbox
alias trun="toolbox run"
alias tenter="toolbox enter"
