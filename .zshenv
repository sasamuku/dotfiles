# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# Load private environment variables (API keys, tokens, etc.)
# Copy .zsh_secrets.example to .zsh_secrets and add your private variables
if [[ -f "${HOME}/.zsh_secrets" ]]; then
  source "${HOME}/.zsh_secrets"
fi
