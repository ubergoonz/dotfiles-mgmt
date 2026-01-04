#!/usr/bin/env bash

#######################################
# Dotfiles Auto Push
# Automatically push dotfiles to git without prompting
#######################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Directories
ETC_DIR="$ROOT_DIR/_etc"
HOMEROOT_DIR="$ROOT_DIR/_homeroot"
CONFIG_FILE="$ETC_DIR/managed-files.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dry run mode - always false for auto-push
DRY_RUN=false

#######################################
# Source shared functions from main script
# We need to prevent the main script from executing
#######################################

# Read only the function definitions from the main sync script
# Skip the main execution by using a temp variable
_SKIP_MAIN_EXEC=1
source "$SCRIPT_DIR/dotfiles-sync.sh"
unset _SKIP_MAIN_EXEC

#######################################
# Auto-push main function
#######################################
auto_push_main() {
    print_msg "$BLUE" "╔════════════════════════════════════╗"
    print_msg "$BLUE" "║   Dotfiles Auto-Push Tool          ║"
    print_msg "$BLUE" "╚════════════════════════════════════╝"
    
    check_dependencies
    read_config
    
    # Always sync files from home directory to _homeroot/
    sync_all_files
    
    cd "$ROOT_DIR"
    
    # Check if there are uncommitted changes in the git repo
    if [[ -n $(git status -s) ]]; then
        print_msg "$YELLOW" "\nGit changes detected in repository"
        push_to_git
    else
        print_msg "$BLUE" "\nNo git changes to push"
    fi
    
    print_msg "$GREEN" "\n✓ Done!"
}

# Run auto-push main function
auto_push_main "$@"
