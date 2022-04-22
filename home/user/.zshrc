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

# History file & limits
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

