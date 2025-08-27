# cidr-info.plugin.zsh
# zcomet plugin wrapper for cidr-info.sh

# Location of the script (assuming installed with plugin)
script_path="${0:A:h}/cidr-info.sh"

# Add the script directory to PATH
export PATH="$PATH:${0:A:h}"

# Define a convenient function
cidr_info() {
  "$script_path" "$@"
}

# Optional alias
alias cidr=cidr_info

# Add completions dir to fpath
fpath+=("${0:A:h}/completions")

# Initialize completions if needed
if ! typeset -f compinit >/dev/null; then
  autoload -Uz compinit
fi
if ! whence -w _complete >/dev/null 2>&1; then
  compinit -i
fi
