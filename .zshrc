# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  brew
  xcode
  docker
  mise
  git
  gradle
  autojump
  thefuck
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
#
export AWS_PAGER=""

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ==============================================================================
# INTEGRATIONS
# ==============================================================================

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# ==============================================================================
# EDITOR CONFIGURATION
# ==============================================================================

export EDITOR="nvim"
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES

# ==============================================================================
# ALIASES
# ==============================================================================

# Vim/Neovim
alias vim="nvim"
alias vi="nvim"

# Thefuck alias
alias frick=fuck

# Dotfiles management
# Make sure the --git-dir is the same as the directory where you created the repo above
alias config="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

# Git aliases
alias gpam='gitPullAndMerge'

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Pull a branch and merge it into the current branch with error handling
function gitPullAndMerge() {
  if [[ -z "$1" ]]; then
    echo "Usage: gitPullAndMerge <branch>"
    return 1
  fi

  local target_branch="$1"
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [[ -z "$current_branch" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  if ! git show-ref --verify --quiet "refs/heads/$target_branch" && \
     ! git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
    echo "Error: Branch '$target_branch' does not exist"
    return 1
  fi

  # Check if target branch is checked out in a worktree
  local worktree_path
  worktree_path=$(git worktree list --porcelain 2>/dev/null | awk -v branch="$target_branch" '
    /^worktree / { sub(/^worktree /, ""); wt = $0 }
    /^branch refs\/heads\// {
      sub(/^branch refs\/heads\//, "")
      if ($0 == branch) print wt
    }')

  if [[ -n "$worktree_path" ]]; then
    echo "Branch '$target_branch' is checked out in worktree: $worktree_path"
    echo "Fetching latest changes for $target_branch from origin..."
    git fetch origin "$target_branch" || return 1

    echo "Merging origin/$target_branch into $current_branch"
    git merge "origin/$target_branch"
    return $?
  fi

  echo "Switching to branch: $target_branch"
  git checkout "$target_branch" || return 1

  echo "Pulling latest changes..."
  git pull || {
    echo "Pull failed, returning to $current_branch"
    git checkout "$current_branch"
    return 1
  }

  echo "Returning to branch: $current_branch"
  git checkout "$current_branch" || return 1

  echo "Merging $target_branch into $current_branch"
  git merge "$target_branch"
}

# Autocomplete for gitPullAndMerge - completes branch names
_gitPullAndMerge() {
  local branches
  branches=(${(f)"$(git branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | sort -u)"})
  _describe 'branch' branches
}
compdef _gitPullAndMerge gitPullAndMerge gpam

# Autocomplete for config alias (dotfiles management)
_config() {
  service=git
  words=('git' "${words[@]:1}")
  (( CURRENT++ ))
  _git
}
compdef _config config

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Local binaries
export PATH=$PATH:$HOME/.local/bin

# Android Studio
export PATH="/Applications/Android Studio.app/Contents/MacOS:$PATH"

# Bun
export PATH="/Users/gvanderclay/.bun/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/gvanderclay/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# LM Studio CLI
export PATH="$PATH:/Users/gvanderclay/.lmstudio/bin"

# Antigravity
export PATH="/Users/gvanderclay/.antigravity/antigravity/bin:$PATH"
