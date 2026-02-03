---
name: create-pr
description: Create a GitHub pull request using gh CLI with proper formatting
disable-model-invocation: true
---

# Create PR

Create a GitHub pull request using GitHub CLI.

## Creating a New Pull Request

1. First, prepare your PR description following the template in `.github/pull_request_template.md`

2. Use the `gh pr create --draft` command:

```bash
gh pr create --draft --title "feat(scope): your descriptive title" --body "Your PR description" --base main
```

For more complex PR descriptions with proper formatting, use `--body-file`:

```bash
gh pr create --draft --title "feat(scope): your descriptive title" --body-file .github/pull_request_template.md --base main
```

## Best Practices

1. **Language**: Always use English for PR titles and descriptions

2. **PR Title Format**: Use Conventional Commits format (no emojis)
   - Follow the same format as commit messages: `type(scope): description`
   - Examples:
     - `feat(supabase): add staging remote configuration`
     - `fix(auth): fix login redirect issue`
     - `docs(readme): update installation instructions`

3. **Description Template**: Always use PR template structure from `.github/pull_request_template.md`

4. **Template Accuracy**: Ensure your PR description precisely follows the template structure:
   - Don't modify or rename the PR-Agent sections (`pr_agent:summary` and `pr_agent:walkthrough`)
   - Keep all section headers exactly as they appear in the template
   - Don't add custom sections that aren't in the template

5. **Draft PRs**: Start as draft when the work is in progress
   - Use `--draft` flag in the command
   - Convert to ready for review when complete using `gh pr ready`

### Common Mistakes to Avoid

- **Using Non-English Text**: All PR content must be in English
- **Incorrect Section Headers**: Always use the exact section headers from the template
- **Adding Custom Sections**: Stick to the sections defined in the template
- **Using Outdated Templates**: Always refer to the current `.github/pull_request_template.md` file
- **Missing Sections**: Always include all template sections, even if some are marked as "N/A" or "None"

## Additional GitHub CLI PR Commands

```bash
gh pr list --author "@me"                        # List your open PRs
gh pr status                                      # Check PR status
gh pr view <PR-NUMBER>                           # View a specific PR
gh pr checkout <PR-NUMBER>                       # Check out a PR branch locally
gh pr ready <PR-NUMBER>                          # Convert draft PR to ready
gh pr edit <PR-NUMBER> --add-reviewer user1,user2 # Add reviewers
gh pr merge <PR-NUMBER> --squash                 # Merge PR
```
