# Shell Completion Installation Guide

`aswitch` provides shell completion scripts for multiple shells to make command usage faster and easier.

## Available Completions

| Shell | Script Path |
|-------|-------------|
| Zsh | `completions/_aswitch` |
| PowerShell | `completions/aswitch.ps1` |
| Bash | *Unsupported* |
| Fish | *Unsupported* |

---

## Installation Instructions

### Zsh
1. Copy the completion script to your zsh site-functions directory:
   ```bash
   # System-wide installation (requires sudo)
   sudo cp completions/_aswitch /usr/share/zsh/site-functions/
   
   # Or user-specific installation
   cp completions/_aswitch ~/.zsh/functions/
   # Ensure ~/.zsh/functions is in your $fpath (add to ~/.zshrc if needed):
   # fpath=(~/.zsh/functions $fpath)
   ```
2. Restart your shell or reload completions:
   ```bash
   compinit
   ```

### PowerShell
1. Option 1: Load automatically via PowerShell profile (recommended):
   ```powershell
   # Add the following line to your PowerShell profile (run `notepad $PROFILE` to edit)
   . "path/to/aswitch/completions/aswitch.ps1"
   
   # Example if aswitch is cloned to d:\coding\project\aswitch:
   . "d:\coding\project\aswitch\completions\aswitch.ps1"
   ```
2. Option 2: Copy to a central completions directory:
   ```powershell
   # Create a completions directory if it doesn't exist
   New-Item -ItemType Directory -Force ~\Documents\WindowsPowerShell\completions
   
   # Copy the completion script
   Copy-Item completions\aswitch.ps1 ~\Documents\WindowsPowerShell\completions\
   
   # Add to profile:
   . ~\Documents\WindowsPowerShell\completions\aswitch.ps1
   ```
3. Restart PowerShell or reload your profile to activate:
   ```powershell
   . $PROFILE
   ```

### Bash
*Unsupported*

### Fish
*Unsupported*

---

## Verifying Installation

After installation, test that completions work by typing:
```bash
aswitch <tab>
```

You should see the list of available commands autocomplete.
