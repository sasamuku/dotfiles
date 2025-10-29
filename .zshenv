# Load private environment variables (API keys, tokens, etc.)
# Copy .zsh_secrets.example to .zsh_secrets and add your private variables
if [[ -f "${HOME}/.zsh_secrets" ]]; then
  source "${HOME}/.zsh_secrets"
fi
