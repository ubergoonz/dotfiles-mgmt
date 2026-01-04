#!/usr/bin/env bash

#######################################
# Dotfiles Management Tool
# Syncs dotfiles from home directory to _homeroot and commits to git
#######################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Directories
ETC_DIR="$ROOT_DIR/_etc"
HOMEROOT_DIR="$ROOT_DIR/_homeroot"
CONFIG_FILE="$ETC_DIR/managed-files.yaml"

# Dry run mode flag
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#######################################
# Print usage information
#######################################
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Dotfiles Management Tool - Sync and manage your dotfiles

OPTIONS:
    -d, --dry-run    Perform a dry run without copying files
    -h, --help       Display this help message

EXAMPLES:
    $(basename "$0")              # Normal sync with confirmation prompt
    $(basename "$0") --dry-run    # Preview changes without copying

EOF
    exit 0
}

#######################################
# Print colored message
# Arguments:
#   $1 - Color
#   $2 - Message
#######################################
print_msg() {
    echo -e "${1}${2}${NC}"
}

#######################################
# Parse YAML file (simple parser)
# This is a basic YAML parser for simple key-value structures
#######################################
parse_yaml() {
    local yaml_file=$1
    local prefix=${2:-}
    
    # Remove comments and empty lines
    sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$yaml_file"
}

#######################################
# Check if required tools are installed
#######################################
check_dependencies() {
    local deps=("git")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_msg "$RED" "Error: $dep is not installed"
            exit 1
        fi
    done
}

#######################################
# Read configuration from YAML
#######################################
read_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_msg "$RED" "Error: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    print_msg "$BLUE" "Reading configuration from $CONFIG_FILE"
}

#######################################
# Extract repository URL from YAML
#######################################
get_repo_url() {
    grep -A 10 "^repository:" "$CONFIG_FILE" | grep "url:" | head -1 | sed 's/.*url:[[:space:]]*"\(.*\)".*/\1/'
}

#######################################
# Extract branch from YAML
#######################################
get_branch() {
    local branch=$(grep -A 10 "^repository:" "$CONFIG_FILE" | grep "branch:" | head -1 | sed 's/.*branch:[[:space:]]*"\(.*\)".*/\1/')
    echo "${branch:-main}"
}

#######################################
# Detect git provider (github/gitlab)
#######################################
detect_provider() {
    local url=$1
    
    if [[ "$url" == *"github.com"* ]]; then
        echo "github"
    elif [[ "$url" == *"gitlab.com"* ]]; then
        echo "gitlab"
    else
        echo "unknown"
    fi
}

#######################################
# Extract file mappings from YAML
#######################################
get_file_mappings() {
    awk '
    /^files:/ { in_files=1; next }
    in_files && /^[^ ]/ { in_files=0 }
    in_files && /source:/ { 
        gsub(/.*source:[[:space:]]*"/, "")
        gsub(/".*/, "")
        gsub(/~/, ENVIRON["HOME"])
        source=$0
    }
    in_files && /dest:/ {
        gsub(/.*dest:[[:space:]]*"/, "")
        gsub(/".*/, "")
        dest=$0
        print source "|" dest
    }
    ' "$CONFIG_FILE"
}

#######################################
# Copy file or directory with change detection
# Arguments:
#   $1 - Source path
#   $2 - Destination path (relative to _homeroot)
# Returns:
#   0 if copied (changed), 1 if skipped (no change)
#######################################
sync_file() {
    local source=$1
    local dest_rel=$2
    local dest="$HOMEROOT_DIR/$dest_rel"
    
    # Expand tilde in source
    source="${source/#\~/$HOME}"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        print_msg "$YELLOW" "  ⚠ Skip: Source does not exist: $source"
        return 1
    fi
    
    # Check if it's a directory
    if [[ -d "$source" ]]; then
        # For directories, use rsync for efficient syncing
        if command -v rsync &> /dev/null; then
            local changes=$(rsync -avn --delete "$source/" "$dest/" 2>/dev/null | grep -v "^sending\|^sent\|^total" | wc -l)
            if [[ $changes -gt 0 ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    print_msg "$YELLOW" "  🔍 Would sync directory: $dest_rel"
                    rsync -avn --delete "$source/" "$dest/" 2>/dev/null | grep -E "^deleting|<f|>f|cd" | head -5 | sed 's/^/       /'
                    local remaining=$(rsync -avn --delete "$source/" "$dest/" 2>/dev/null | grep -E "^deleting|<f|>f|cd" | wc -l)
                    if [[ $remaining -gt 5 ]]; then
                        print_msg "$BLUE" "       ... and $((remaining - 5)) more changes"
                    fi
                else
                    mkdir -p "$(dirname "$dest")"
                    rsync -av --delete "$source/" "$dest/" > /dev/null
                    print_msg "$GREEN" "  ✓ Synced directory: $dest_rel"
                fi
                return 0
            else
                print_msg "$BLUE" "  ≈ No changes: $dest_rel"
                return 1
            fi
        else
            # Fallback to cp if rsync not available
            if [[ "$DRY_RUN" == "true" ]]; then
                print_msg "$YELLOW" "  🔍 Would copy directory: $dest_rel"
            else
                mkdir -p "$(dirname "$dest")"
                cp -R "$source" "$dest"
                print_msg "$GREEN" "  ✓ Copied directory: $dest_rel"
            fi
            return 0
        fi
    else
        # For files, check if content differs
        if [[ -f "$dest" ]] && cmp -s "$source" "$dest"; then
            print_msg "$BLUE" "  ≈ No changes: $dest_rel"
            return 1
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                if [[ -f "$dest" ]]; then
                    print_msg "$YELLOW" "  🔍 Would update file: $dest_rel"
                else
                    print_msg "$YELLOW" "  🔍 Would create file: $dest_rel"
                fi
            else
                mkdir -p "$(dirname "$dest")"
                cp "$source" "$dest"
                print_msg "$GREEN" "  ✓ Copied file: $dest_rel"
            fi
            return 0
        fi
    fi
}

#######################################
# Sync all managed files
#######################################
sync_all_files() {
    if [[ "$DRY_RUN" == "true" ]]; then
        print_msg "$YELLOW" "\n=== DRY RUN: Preview changes (no files will be copied) ==="
    else
        print_msg "$BLUE" "\n=== Syncing dotfiles to $HOMEROOT_DIR ==="
    fi
    
    local changed=0
    local total=0
    
    while IFS='|' read -r source dest; do
        # Skip empty lines
        [[ -z "$source" ]] && continue
        
        ((total++))
        
        if sync_file "$source" "$dest"; then
            ((changed++))
        fi
    done < <(get_file_mappings)
    
    print_msg "$BLUE" "\n=== Summary: $changed/$total files changed ==="
    
    # Return 0 (success) if there were changes, 1 (failure) if no changes
    [[ $changed -gt 0 ]]
}

#######################################
# Commit and push changes to git
#######################################
push_to_git() {
    local repo_url=$(get_repo_url)
    local branch=$(get_branch)
    local provider=$(detect_provider "$repo_url")
    
    print_msg "$BLUE" "\n=== Git Operations ==="
    print_msg "$BLUE" "Repository: $repo_url"
    print_msg "$BLUE" "Branch: $branch"
    print_msg "$BLUE" "Provider: $provider"
    
    cd "$ROOT_DIR"
    
    # Initialize git if needed
    if [[ ! -d ".git" ]]; then
        print_msg "$YELLOW" "Initializing git repository..."
        git init
        git remote add origin "$repo_url"
    fi
    
    # Check if there are changes to commit
    if [[ -z $(git status -s) ]]; then
        print_msg "$BLUE" "No changes to commit"
        return 0
    fi
    
    # Stage all changes in _homeroot
    git add _homeroot/
    
    # Also add config files
    git add _etc/managed-files.yaml _bin/ README.md 2>/dev/null || true
    
    # Check if there are staged changes
    if [[ -z $(git diff --cached --name-only) ]]; then
        print_msg "$BLUE" "No changes to commit"
        return 0
    fi
    
    # Commit with timestamp
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    git commit -m "Update dotfiles - $timestamp"
    
    # Push to remote
    print_msg "$YELLOW" "Pushing to $provider ($branch)..."
    
    # Set upstream if needed
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
        git push -u origin "$branch"
    else
        git push
    fi
    
    print_msg "$GREEN" "✓ Successfully pushed to $provider"
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_msg "$RED" "Unknown option: $1"
                usage
                ;;
        esac
    done
}

#######################################
# Main function
#######################################
main() {
    # Parse command line arguments
    parse_args "$@"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_msg "$YELLOW" "╔════════════════════════════════════╗"
        print_msg "$YELLOW" "║   Dotfiles Tool - DRY RUN MODE     ║"
        print_msg "$YELLOW" "╚════════════════════════════════════╝"
    else
        print_msg "$BLUE" "╔════════════════════════════════════╗"
        print_msg "$BLUE" "║   Dotfiles Management Tool         ║"
        print_msg "$BLUE" "╚════════════════════════════════════╝"
    fi
    
    check_dependencies
    read_config
    
    # Sync files
    sync_all_files
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_msg "$YELLOW" "\n🔍 Dry run complete - no files were actually copied"
        print_msg "$BLUE" "Run without --dry-run to apply these changes"
    else
        # Check if there are uncommitted git changes
        cd "$ROOT_DIR"
        if [[ -n $(git status -s 2>/dev/null) ]]; then
            # If there are git changes, offer to push
            read -p "$(echo -e "\n${YELLOW}Git changes detected. Push to git? (y/N): ${NC}")" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                push_to_git
            else
                print_msg "$BLUE" "Skipped git push"
            fi
        else
            print_msg "$BLUE" "\nNo git changes to push"
        fi
    fi
    
    print_msg "$GREEN" "\n✓ Done!"
}

# Run main function only if not being sourced
if [[ -z "${_SKIP_MAIN_EXEC:-}" ]]; then
    main "$@"
fi
