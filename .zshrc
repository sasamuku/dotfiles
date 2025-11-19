# Initialize sheldon plugin manager
eval "$(sheldon source)"

# Initialize completion system
autoload -Uz compinit && compinit

# Completion settings
setopt auto_menu
setopt auto_list
setopt list_packed
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Initialize starship prompt
eval "$(starship init zsh)"

# history
HISTFILE=$HOME/.zsh-history
HISTSIZE=100000
SAVEHIST=1000000
setopt inc_append_history
setopt share_history

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf options
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --preview-window=right:60%
  --bind ctrl-/:toggle-preview
'

# fzf history search with Ctrl+R (shows matching entries as you type)
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:wrap
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
"

# cdr with fzf
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
function fzf-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | fzf --prompt="cdr > " --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd `echo $selected_dir | awk '{print$2}'`"
        CURSOR=$#BUFFER
        zle reset-prompt
    fi
}
zle -N fzf-cdr
bindkey '^G' fzf-cdr

# environment varibles
export CLICOLOR=1

# direnv
eval "$(direnv hook zsh)"

# alias
alias ls="ls -la -G"
alias showz="cat ~/.zshrc"
alias editz='$EDITOR ~/.zshrc'
alias sourcez="source ~/.zshrc"
alias be='bundle exec'
alias cl='claude'
alias lg='lazygit'

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Claude Code
export PATH="$HOME/.claude/local:$PATH"

# kiro
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# mise
eval "$(mise activate zsh)"

# Load custom functions
if [[ -f "$HOME/.config/zsh/functions/wt.zsh" ]]; then
    source "$HOME/.config/zsh/functions/wt.zsh"
fi

if [[ -f "$HOME/.config/zsh/functions/ghq.zsh" ]]; then
    source "$HOME/.config/zsh/functions/ghq.zsh"
fi
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"
