eval "$(sheldon source)"

export EDITOR=nvim
#export JAVA_TOOL_OPTIONS="-Duser.language=ja -Duser.country=JP"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/aki/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

#Azure cli setting
autoload bashcompinit && bashcompinit
source $(brew --prefix)/etc/bash_completion.d/az

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity
export PATH="/Users/aki/.antigravity/antigravity/bin:$PATH"
export GOOGLE_CLOUD_PROJECT=backend-credentials

alias emacs='nvim' code='nvim'

# Select and cd to a ghq-managed repository using fzf
function gf() {
  local dir
  dir=$(ghq list -p | fzf --preview "ls -la {}")
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}

# Select and cd to a directory using fzf (-a to include hidden directories)
function cf() {
  local dir
  local fd_opts="--type d"
  if [[ "$1" == "-a" || "$1" == "--all" ]]; then
    fd_opts="$fd_opts --hidden"
  fi
  dir=$(fd ${=fd_opts} | fzf)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}

