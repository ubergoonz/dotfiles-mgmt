# Dotfiles Management Tool

A bash-based dotfiles management system that automatically syncs your configuration files and pushes them to GitHub or GitLab.

## ✨ Features

- 🎯 **Interactive Terminal UI**: User-friendly menu for all operations
- 🚀 **One-Command Initialization**: Quick setup with guided configuration
- 🔍 **Dry-Run Preview**: See what would change before making any modifications
- 📁 **Smart Change Detection**: Only copies files that have actually changed
- 📂 **Directory Support**: Can sync entire directories using rsync
- 🔄 **Multiple Modes**: Interactive, automatic, or TUI-based workflows
- 🎨 **Color-Coded Output**: Easy to read status messages
- 📝 **Simple YAML Configuration**: Easy to configure and maintain
- 🌐 **Multi-Provider Support**: Works with both GitHub and GitLab

## 📁 Project Structure

```
dotfiles-mgmt/
├── _bin/                    # Scripts directory
│   ├── dotfiles-init.sh    # One-time initialization (run first!)
│   ├── dotfiles-tui.sh     # Terminal UI (recommended for beginners)
│   ├── dotfiles-sync.sh    # Main sync script (interactive)
│   └── dotfiles-push.sh    # Auto-push script (non-interactive)
├── _etc/                    # Configuration directory
│   └── managed-files.yaml  # File mappings and repository settings
├── _homeroot/              # Synced dotfiles (mirrors your home directory)
└── README.md
```

## 🚀 Quick Start

### Step 1: Initialize (First Time Setup)

Run the initialization script to set up your dotfiles management:

```bash
./_bin/dotfiles-init.sh
```

This will:
- ✅ Collect your GitHub/GitLab repository URL
- ✅ Configure git user name and email
- ✅ Create the configuration file
- ✅ Initialize git repository
- ✅ Offer to perform initial sync

**What you'll need:**
- A GitHub or GitLab repository URL (e.g., `https://github.com/username/dotfiles.git`)
- Your git user name and email

### Step 2: Use the Tool

After initialization, you have three ways to use the tool:

#### Option A: Terminal UI (Recommended for Beginners)

```bash
./_bin/dotfiles-tui.sh
```

Interactive menu with options to:
- 📁 View tracked files
- ➕ Add files to track
- ➖ Remove tracked files
- ⚙️ Configure git repository
- 🔍 Preview changes (dry-run)
- 🔄 Sync files
- 🚀 Auto-push to git

#### Option B: Command Line (Interactive)

```bash
# Preview changes without copying
./_bin/dotfiles-sync.sh --dry-run

# Sync files and prompt before pushing
./_bin/dotfiles-sync.sh

# Show help
./_bin/dotfiles-sync.sh --help
```

#### Option C: Automated Push

```bash
# Sync and automatically push to git (no prompts)
./_bin/dotfiles-push.sh
```

## 📖 Detailed Usage

### Using the Terminal UI

The TUI provides the easiest way to manage your dotfiles:

```bash
./_bin/dotfiles-tui.sh
```

**Menu Options:**

1. **View tracked files** - See all currently tracked files with status (✓ found / ✗ missing)
2. **Add file to track** - Interactively add a new file or directory
   - Enter the source path (e.g., `~/.zshrc`)
   - Specify destination path in `_homeroot/`
   - File is added to configuration automatically
3. **Remove tracked file** - Select and remove files from tracking
4. **Configure git repository** - Update repository URL or branch
5. **Sync (dry-run preview)** - Preview changes without copying anything
6. **Sync (interactive)** - Sync files and optionally push with confirmation
7. **Sync and auto-push** - Automatically sync and push all changes
8. **Edit config file** - Open YAML config in your default editor
9. **View current configuration** - Display settings and tracked files

**Navigation:** Use number keys to select options, press `0` to exit

### Using Command Line Scripts

**Dry-run (preview only):**
```bash
./_bin/dotfiles-sync.sh --dry-run
```
- Shows what would be copied
- No files are actually modified
- Safe to run anytime

**Interactive sync:**
```bash
./_bin/dotfiles-sync.sh
```
- Copies changed files from `~` to `_homeroot/`
- Checks git repository for uncommitted changes
- Prompts before pushing to remote

**Automatic push:**
```bash
./_bin/dotfiles-push.sh
```
- Syncs all files
- Automatically pushes to git if there are changes
- No user interaction required
- Perfect for cron jobs or automation

### Manual Configuration

Edit the configuration file directly:

```bash
# Using your preferred editor
$EDITOR _etc/managed-files.yaml

# Or use the TUI menu option 8
```

**Configuration format:**
```yaml
repository:
  url: "https://github.com/username/dotfiles.git"
  branch: "main"

files:
  - source: "~/.zshrc"        # Path in your home directory
    dest: ".zshrc"            # Path in _homeroot/
  
  - source: "~/.config/nvim"  # Can track directories too
    dest: ".config/nvim"
```

## 🔧 How It Works

1. **Read Configuration**: Parses `managed-files.yaml` for file mappings and repository settings
2. **Sync Files**: Copies configured files from your home directory to `_homeroot/`
3. **Change Detection**: Uses `cmp` for files and `rsync` for directories to detect changes
4. **Git Operations**: 
   - Checks for uncommitted changes with `git status`
   - Commits changes with timestamp
   - Pushes to configured remote repository

## ⚙️ Advanced Usage

### Schedule Automatic Backups

Add to your crontab to sync daily:

```bash
# Edit crontab
crontab -e

# Sync at 6 PM daily
0 18 * * * /path/to/dotfiles-mgmt/_bin/dotfiles-push.sh

# Sync every 4 hours
0 */4 * * * /path/to/dotfiles-mgmt/_bin/dotfiles-push.sh
```

### Shell Aliases

Add convenient aliases to your shell configuration:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias dotfiles='/path/to/dotfiles-mgmt/_bin/dotfiles-tui.sh'
alias dotfiles-sync='/path/to/dotfiles-mgmt/_bin/dotfiles-sync.sh'
alias dotfiles-push='/path/to/dotfiles-mgmt/_bin/dotfiles-push.sh'
```

Then use:
```bash
dotfiles           # Launch TUI
dotfiles-sync      # Interactive sync
dotfiles-push      # Auto-push
```

### Common Dotfiles to Track

**Shell configs:**
- `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`
- `~/.profile`, `~/.zprofile`
- `~/.aliases`

**Git:**
- `~/.gitconfig`
- `~/.gitignore_global`

**Editors:**
- `~/.vimrc`, `~/.vim/`
- `~/.config/nvim/`
- `~/Library/Application Support/Code/User/settings.json` (VS Code on macOS)

**Terminal:**
- `~/.tmux.conf`
- `~/.config/starship.toml`
- `~/.config/alacritty/`

**SSH:**
- `~/.ssh/config` (be careful with sensitive files!)

## 🔄 Restoring Dotfiles on a New Machine

To restore your dotfiles on a new machine:

```bash
# 1. Clone your dotfiles repository
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles

# 2. Review what's tracked
./_bin/dotfiles-tui.sh  # Option 1 to view files

# 3. Manually copy or symlink files from _homeroot/ to ~
cp _homeroot/.zshrc ~/
cp _homeroot/.gitconfig ~/
# ... etc

# Or create symlinks
ln -s $(pwd)/_homeroot/.zshrc ~/.zshrc
ln -s $(pwd)/_homeroot/.gitconfig ~/.gitconfig
# ... etc
```

**Future enhancement:** A restore script could be added to automate this process.

## 🔍 Troubleshooting

### Scripts won't run

Make sure scripts are executable:
```bash
chmod +x _bin/*.sh
```

### Git push fails

- Verify your repository URL: check `_etc/managed-files.yaml`
- Ensure you have push access to the repository
- Check git credentials: `git config --global credential.helper`
- For SSH URLs, ensure your SSH key is added to GitHub/GitLab

### File not syncing

- Verify the source path exists: `ls -la ~/path/to/file`
- Check file permissions
- Look for error messages in script output
- Try dry-run to see what would happen: `./_bin/dotfiles-sync.sh --dry-run`

### "awk: calling undefined function strftime" error

This has been fixed in the latest version. Update your scripts or run:
```bash
git pull origin main
```

## 📚 Script Reference

| Script | Purpose | Interactive | Auto-push |
|--------|---------|-------------|-----------|
| `dotfiles-init.sh` | One-time setup | ✅ | - |
| `dotfiles-tui.sh` | Menu-driven interface | ✅ | Optional |
| `dotfiles-sync.sh` | Sync with confirmation | ✅ | ❌ |
| `dotfiles-sync.sh --dry-run` | Preview changes only | ✅ | ❌ |
| `dotfiles-push.sh` | Sync and auto-push | ❌ | ✅ |

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Submit bug reports or feature requests
- Create pull requests for improvements
- Share your dotfiles configurations

## 📝 License

MIT

## 💡 Tips

- **Start small**: Begin with just a few important dotfiles
- **Use dry-run**: Always preview changes with `--dry-run` before syncing
- **Regular backups**: Set up a cron job for automatic daily backups
- **Be careful**: Don't track sensitive files (SSH keys, API tokens, etc.)
- **Use .gitignore**: Add sensitive patterns to `.gitignore`
- **Test restores**: Periodically test restoring on a fresh system/VM

## 🆘 Getting Help

1. Run `./_bin/dotfiles-sync.sh --help` for command line options
2. Check the configuration: `./_bin/dotfiles-tui.sh` → Option 9
3. Review tracked files: `./_bin/dotfiles-tui.sh` → Option 1
4. Try dry-run mode to see what would happen: `./_bin/dotfiles-sync.sh --dry-run`
