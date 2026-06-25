# Git Configuration

## SSH Key
Always use the personal SSH key for GitHub communication:
- Key: `~/.ssh/id_ed25519_pessoal`
- If the SSH agent doesn't have it loaded, run: `ssh-add ~/.ssh/id_ed25519_pessoal`
- Verify remotes use SSH (git@github.com:...), not HTTPS

## Commit Identity
Always commit with the personal email:
- Email: `kauanteixeirapereira5@gmail.com`
- Set locally if not already: `git config user.email "kauanteixeirapereira5@gmail.com"`

Before any git operation, confirm these are in effect:
```bash
git config user.email   # must return kauanteixeirapereira5@gmail.com
ssh-add -l              # must list id_ed25519_pessoal
```
