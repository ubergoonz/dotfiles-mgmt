#!/usr/bin/env bash

#######################################
# Dotfiles Initialization Script
# One-time setup to configure dotfiles management
#######################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Directories
ETC_DIR="$ROOT_DIR/_etc"
HOMEROOT_DIR="$ROOT_DIR/_homeroot"
CONFIG_FILE="$ETC_DIR/managed-files.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#######################################
# Print colored message
#######################################
print_msg() {
    echo -e "${1}${2}${NC}"
}

#######################################
# Print welcome banner
#######################################
print_banner() {
    clear
    print_msg "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_msg "$CYAN" "║                                                      ║"
    print_msg "$CYAN" "║       Dotfiles Management - Initialization           ║"
    print_msg "$CYAN" "║                                                      ║"
    print_msg "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo
    print_msg "$BLUE" "This script will help you set up your dotfiles management system."
    print_msg "$BLUE" "You'll need a GitHub or GitLab repository to store your dotfiles."
    echo
}

#######################################
# Check if already initialized
#######################################
check_existing() {
    if [[ -d "$ROOT_DIR/.git" ]] && [[ -f "$CONFIG_FILE" ]]; then
        print_msg "$YELLOW" "⚠️  It looks like this repository is already initialized."
        echo
        read -p "$(echo -e "${YELLOW}Do you want to reconfigure? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_msg "$BLUE" "Initialization cancelled."
            exit 0
        fi
        echo
    fi
}

#######################################
# Collect git repository information
#######################################
collect_repo_info() {
    print_msg "$BOLD" "📦 Git Repository Configuration"
    echo
    
    # Repository URL
    print_msg "$CYAN" "Enter your git repository URL:"
    print_msg "$BLUE" "  Examples:"
    print_msg "$BLUE" "    • https://github.com/username/dotfiles.git"
    print_msg "$BLUE" "    • https://gitlab.com/username/dotfiles.git"
    print_msg "$BLUE" "    • git@github.com:username/dotfiles.git"
    echo
    read -p "$(echo -e "${CYAN}Repository URL: ${NC}")" REPO_URL
    
    while [[ -z "$REPO_URL" ]]; do
        print_msg "$RED" "Repository URL cannot be empty!"
        read -p "$(echo -e "${CYAN}Repository URL: ${NC}")" REPO_URL
    done
    
    # Detect provider
    if [[ "$REPO_URL" == *"github.com"* ]]; then
        PROVIDER="GitHub"
    elif [[ "$REPO_URL" == *"gitlab.com"* ]]; then
        PROVIDER="GitLab"
    else
        PROVIDER="Unknown"
    fi
    
    echo
    print_msg "$GREEN" "✓ Provider detected: $PROVIDER"
    
    # Branch name
    echo
    print_msg "$CYAN" "Enter the branch name to use (default: main):"
    read -p "$(echo -e "${CYAN}Branch: ${NC}")" BRANCH
    BRANCH="${BRANCH:-main}"
    
    echo
    print_msg "$GREEN" "✓ Branch set to: $BRANCH"
    echo
}

#######################################
# Collect user information
#######################################
collect_user_info() {
    print_msg "$BOLD" "👤 User Information"
    echo
    
    # Git user name
    local git_name=$(git config --global user.name 2>/dev/null || echo "")
    if [[ -n "$git_name" ]]; then
        print_msg "$CYAN" "Git user name (default: $git_name):"
        read -p "$(echo -e "${CYAN}Name: ${NC}")" USER_NAME
        USER_NAME="${USER_NAME:-$git_name}"
    else
        print_msg "$CYAN" "Enter your git user name:"
        read -p "$(echo -e "${CYAN}Name: ${NC}")" USER_NAME
        while [[ -z "$USER_NAME" ]]; do
            print_msg "$RED" "Name cannot be empty!"
            read -p "$(echo -e "${CYAN}Name: ${NC}")" USER_NAME
        done
    fi
    
    # Git user email
    local git_email=$(git config --global user.email 2>/dev/null || echo "")
    if [[ -n "$git_email" ]]; then
        print_msg "$CYAN" "Git user email (default: $git_email):"
        read -p "$(echo -e "${CYAN}Email: ${NC}")" USER_EMAIL
        USER_EMAIL="${USER_EMAIL:-$git_email}"
    else
        print_msg "$CYAN" "Enter your git user email:"
        read -p "$(echo -e "${CYAN}Email: ${NC}")" USER_EMAIL
        while [[ -z "$USER_EMAIL" ]]; do
            print_msg "$RED" "Email cannot be empty!"
            read -p "$(echo -e "${CYAN}Email: ${NC}")" USER_EMAIL
        done
    fi
    
    echo
    print_msg "$GREEN" "✓ User: $USER_NAME <$USER_EMAIL>"
    echo
}

#######################################
# Create configuration file
#######################################
create_config() {
    print_msg "$BOLD" "📝 Creating Configuration File"
    echo
    
    # Create directories if they don't exist
    mkdir -p "$ETC_DIR"
    mkdir -p "$HOMEROOT_DIR"
    
    # Create managed-files.yaml
    cat > "$CONFIG_FILE" << EOF
# Dotfiles Management Configuration
# Created: $(date "+%Y-%m-%d %H:%M:%S")

# Git repository settings
repository:
  # Repository URL
  url: "$REPO_URL"
  
  # Branch to push to
  branch: "$BRANCH"

# Files to manage
# Add your dotfiles here in the format:
#   - source: "~/path/to/file"
#     dest: "relative/path/in/homeroot"
files:
  # Shell configuration
  - source: "~/.zshrc"
    dest: ".zshrc"
  
  - source: "~/.bashrc"
    dest: ".bashrc"
  
  - source: "~/.profile"
    dest: ".profile"
  
  # Git configuration
  - source: "~/.gitconfig"
    dest: ".gitconfig"
  
  # Vim configuration
  - source: "~/.vimrc"
    dest: ".vimrc"

# Note: Edit this file to add/remove files to track
# Use the TUI (dotfiles-tui.sh) for an interactive interface
EOF
    
    print_msg "$GREEN" "✓ Basic configuration file created: $CONFIG_FILE"
    echo
}

#######################################
# Initialize git repository
#######################################
init_git_repo() {
    print_msg "$BOLD" "🔧 Initializing Git Repository"
    echo
    
    cd "$ROOT_DIR"
    
    # Initialize git if not already
    if [[ ! -d ".git" ]]; then
        git init
        print_msg "$GREEN" "✓ Git repository initialized"
    else
        print_msg "$BLUE" "• Git repository already exists"
    fi
    
    # Set user info for this repo
    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    print_msg "$GREEN" "✓ Git user configured"
    
    # Add remote
    if git remote | grep -q "^origin$"; then
        git remote set-url origin "$REPO_URL"
        print_msg "$GREEN" "✓ Remote 'origin' updated"
    else
        git remote add origin "$REPO_URL"
        print_msg "$GREEN" "✓ Remote 'origin' added"
    fi
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << 'EOF'
# macOS
.DS_Store

# Temp files
*.tmp
*.log

# IDE
.vscode/
.idea/
EOF
        print_msg "$GREEN" "✓ .gitignore created"
    fi
    
    echo
}

#######################################
# Create initial commit
#######################################
create_initial_commit() {
    print_msg "$BOLD" "📦 Creating Initial Commit"
    echo
    
    cd "$ROOT_DIR"
    
    # Add files
    git add _bin/ _etc/ README.md .gitignore 2>/dev/null || true
    
    # Check if there's anything to commit
    if [[ -n $(git status --porcelain) ]]; then
        git commit -m "Initial commit: Setup dotfiles management

- Add configuration and scripts
- Configure repository: $REPO_URL
- Set up by: $USER_NAME <$USER_EMAIL>
" 2>/dev/null || true
        print_msg "$GREEN" "✓ Initial commit created"
    else
        print_msg "$BLUE" "• No changes to commit"
    fi
    
    echo
}

#######################################
# Offer to do initial sync
#######################################
offer_initial_sync() {
    print_msg "$BOLD" "🔄 Initial Sync"
    echo
    print_msg "$YELLOW" "Would you like to sync your dotfiles now?"
    print_msg "$BLUE" "This will copy files from your home directory to _homeroot/"
    echo
    read -p "$(echo -e "${CYAN}Sync now? (Y/n): ${NC}")" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo
        if [[ -x "$SCRIPT_DIR/dotfiles-sync.sh" ]]; then
            "$SCRIPT_DIR/dotfiles-sync.sh" --dry-run
            echo
            read -p "$(echo -e "${CYAN}Proceed with actual sync? (Y/n): ${NC}")" -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                "$SCRIPT_DIR/dotfiles-sync.sh"
            fi
        else
            print_msg "$RED" "Error: dotfiles-sync.sh not found or not executable"
        fi
    fi
    
    echo
}

#######################################
# Print next steps
#######################################
print_next_steps() {
    print_msg "$GREEN" "╔══════════════════════════════════════════════════════╗"
    print_msg "$GREEN" "║                                                      ║"
    print_msg "$GREEN" "║            ✓ Initialization Complete!               ║"
    print_msg "$GREEN" "║                                                      ║"
    print_msg "$GREEN" "╚══════════════════════════════════════════════════════╝"
    echo
    print_msg "$BOLD" "📋 Next Steps:"
    echo
    print_msg "$CYAN" "1. Review your configuration:"
    print_msg "$BLUE" "   cat $CONFIG_FILE"
    echo
    print_msg "$CYAN" "2. Use the Terminal UI to manage your dotfiles:"
    print_msg "$BLUE" "   $SCRIPT_DIR/dotfiles-tui.sh"
    echo
    print_msg "$CYAN" "3. Or use command-line tools:"
    print_msg "$BLUE" "   $SCRIPT_DIR/dotfiles-sync.sh --dry-run  # Preview changes"
    print_msg "$BLUE" "   $SCRIPT_DIR/dotfiles-sync.sh            # Sync files"
    print_msg "$BLUE" "   $SCRIPT_DIR/dotfiles-push.sh            # Auto-push to git"
    echo
    print_msg "$CYAN" "4. Add shell aliases (optional):"
    print_msg "$BLUE" "   echo 'alias dotfiles=\"$SCRIPT_DIR/dotfiles-tui.sh\"' >> ~/.zshrc"
    echo
    print_msg "$YELLOW" "📚 Documentation: $ROOT_DIR/README.md"
    echo
}

#######################################
# Main function
#######################################
main() {
    print_banner
    check_existing
    collect_repo_info
    collect_user_info
    create_config
    init_git_repo
    create_initial_commit
    offer_initial_sync
    print_next_steps
}

# Run main function
main "$@"
