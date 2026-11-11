#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '    # fallback prompt; replaced by Starship below when installed
export PATH="$HOME/.local/bin:$PATH"
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# Greeting: a random Pokémon next to the system summary (~/.config/fastfetch/config.jsonc)
if command -v pokemon-colorscripts >/dev/null; then
    fastfetch --file-raw <(pokemon-colorscripts -r --no-title)
else
    fastfetch
fi

# Prompt: ~/.config/starship.toml
command -v starship >/dev/null && eval "$(starship init bash)"



alias server-mode="sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target && echo 'Server Mode ACTIVE: Laptop will stay awake when closed.'"
alias laptop-mode="sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target && echo 'Laptop Mode ACTIVE: Normal sleep restored.'"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
