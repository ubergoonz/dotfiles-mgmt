#!/usr/bin/env bash

#######################################
# Dotfiles TUI - Terminal User Interface
# Interactive menu for managing dotfiles
#######################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
ETC_DIR="$ROOT_DIR/_etc"
CONFIG_FILE="$ETC_DIR/managed-files.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#######################################
# Print colored message
#######################################
print_msg() {
    echo -e "${1}${2}${NC}"
}

#######################################
# Print header
#######################################
print_header() {
    clear
    print_msg "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_msg "$CYAN" "║         Dotfiles Management - TUI                    ║"
    print_msg "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo
}

#######################################
# Print main menu
#######################################
print_main_menu() {
    print_header
    print_msg "$BOLD" "Main Menu:"
    echo
    print_msg "$GREEN" "  1) 📁 View tracked files"
    print_msg "$GREEN" "  2) ➕ Add file to track"
    print_msg "$GREEN" "  3) ➖ Remove tracked file"
    print_msg "$GREEN" "  4) ⚙️ Configure git repository"
    echo
    print_msg "$BLUE" "  5) 🔍 Sync (dry-run preview)"
    print_msg "$BLUE" "  6) 🔄 Sync (interactive)"
    print_msg "$BLUE" "  7) 🚀 Sync and auto-push"
    echo
    print_msg "$YELLOW" "  8) 📝 Edit config file directly"
    print_msg "$YELLOW" "  9) ℹ️  View current configuration"
    echo
    print_msg "$RED" "  0) 🚪 Exit"
    echo
}

#######################################
# View tracked files
#######################################
view_tracked_files() {
    print_header
    print_msg "$BOLD" "📁 Currently Tracked Files:"
    echo
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_msg "$RED" "Configuration file not found!"
        return
    fi
    
    local count=0
    while IFS= read -r line; do
        if [[ "$line" =~ source:[[:space:]]*\"(.+)\" ]]; then
            local source="${BASH_REMATCH[1]}"
            ((count++))
            
            # Expand tilde for checking
            local expanded_source="${source/#\~/$HOME}"
            
            if [[ -e "$expanded_source" ]]; then
                print_msg "$GREEN" "  ✓ $source"
            else
                print_msg "$RED" "  ✗ $source (not found)"
            fi
        fi
    done < "$CONFIG_FILE"
    
    echo
    print_msg "$BLUE" "Total: $count files/directories tracked"
    echo
}

#######################################
# Add file to track
#######################################
add_file_to_track() {
    print_header
    print_msg "$BOLD" "➕ Add File to Track"
    echo
    
    # Get source path
    read -p "$(echo -e "${CYAN}Enter source path (use ~ for home): ${NC}")" source_path
    
    if [[ -z "$source_path" ]]; then
        print_msg "$RED" "Source path cannot be empty"
        return
    fi
    
    # Expand tilde to check if file exists
    local expanded_path="${source_path/#\~/$HOME}"
    if [[ ! -e "$expanded_path" ]]; then
        print_msg "$YELLOW" "⚠️  Warning: File does not exist: $source_path"
        read -p "$(echo -e "${YELLOW}Continue anyway? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_msg "$BLUE" "Cancelled"
            return
        fi
    fi
    
    # Get destination path
    local suggested_dest
    if [[ "$source_path" =~ ^\~/?(.+)$ ]]; then
        suggested_dest="${BASH_REMATCH[1]}"
    else
        suggested_dest=$(basename "$source_path")
    fi
    
    read -p "$(echo -e "${CYAN}Destination path in _homeroot/ [${suggested_dest}]: ${NC}")" dest_path
    dest_path="${dest_path:-$suggested_dest}"
    
    # Add to YAML file
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local new_entry="  - source: \"$source_path\"\n    dest: \"$dest_path\""
    
    # Find the files: section and add after it
    if grep -q "^files:" "$CONFIG_FILE"; then
        # Create temporary file with the new entry
        awk -v entry="$new_entry" -v ts="$timestamp" '
        /^files:/ { 
            print
            if (!added) {
                print ""
                print "  # Added via TUI on " ts
                print entry
                added=1
            }
            next
        }
        { print }
        ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        print_msg "$GREEN" "✓ Added to configuration:"
        print_msg "$BLUE" "  Source: $source_path"
        print_msg "$BLUE" "  Dest:   $dest_path"
    else
        print_msg "$RED" "Error: Could not find 'files:' section in config"
    fi
    
    echo
}

#######################################
# Remove tracked file
#######################################
remove_tracked_file() {
    print_header
    print_msg "$BOLD" "➖ Remove Tracked File"
    echo
    
    # List files with numbers
    local -a files
    local count=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ source:[[:space:]]*\"(.+)\" ]]; then
            files+=("${BASH_REMATCH[1]}")
            ((count++))
            print_msg "$CYAN" "  $count) ${BASH_REMATCH[1]}"
        fi
    done < "$CONFIG_FILE"
    
    if [[ $count -eq 0 ]]; then
        print_msg "$YELLOW" "No files to remove"
        return
    fi
    
    echo
    read -p "$(echo -e "${CYAN}Enter number to remove (0 to cancel): ${NC}")" choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt $count ]]; then
        print_msg "$BLUE" "Cancelled"
        return
    fi
    
    local file_to_remove="${files[$((choice-1))]}"
    
    # Confirm
    read -p "$(echo -e "${YELLOW}Remove '$file_to_remove'? (y/N): ${NC}")" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "$BLUE" "Cancelled"
        return
    fi
    
    # Remove the entry from YAML (remove source and dest lines)
    awk -v pattern="$file_to_remove" '
    BEGIN { skip=0 }
    /source:/ && $0 ~ pattern { skip=2; next }
    skip > 0 { skip--; next }
    /^[[:space:]]*#.*Added via TUI/ { next }
    { print }
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    print_msg "$GREEN" "✓ Removed: $file_to_remove"
    echo
}

#######################################
# Configure git repository
#######################################
configure_git_repo() {
    print_header
    print_msg "$BOLD" "⚙️  Configure Git Repository"
    echo
    
    # Get current values
    local current_url=$(grep -A 5 "^repository:" "$CONFIG_FILE" | grep "url:" | sed 's/.*url:[[:space:]]*"\(.*\)".*/\1/')
    local current_branch=$(grep -A 5 "^repository:" "$CONFIG_FILE" | grep "branch:" | sed 's/.*branch:[[:space:]]*"\(.*\)".*/\1/')
    
    print_msg "$BLUE" "Current URL: $current_url"
    print_msg "$BLUE" "Current Branch: $current_branch"
    echo
    
    # Get new URL
    read -p "$(echo -e "${CYAN}New repository URL [${current_url}]: ${NC}")" new_url
    new_url="${new_url:-$current_url}"
    
    # Get new branch
    read -p "$(echo -e "${CYAN}New branch [${current_branch:-main}]: ${NC}")" new_branch
    new_branch="${new_branch:-${current_branch:-main}}"
    
    # Update config file
    sed -i.bak -E "s|(url:[[:space:]]*\").*(\")|\1${new_url}\2|" "$CONFIG_FILE"
    sed -i.bak -E "s|(branch:[[:space:]]*\").*(\")|\1${new_branch}\2|" "$CONFIG_FILE"
    rm -f "$CONFIG_FILE.bak"
    
    print_msg "$GREEN" "✓ Configuration updated:"
    print_msg "$BLUE" "  URL: $new_url"
    print_msg "$BLUE" "  Branch: $new_branch"
    echo
}

#######################################
# View current configuration
#######################################
view_configuration() {
    print_header
    print_msg "$BOLD" "ℹ️  Current Configuration"
    echo
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_msg "$RED" "Configuration file not found!"
        return
    fi
    
    # Extract and display key info
    local url=$(grep -A 5 "^repository:" "$CONFIG_FILE" | grep "url:" | sed 's/.*url:[[:space:]]*"\(.*\)".*/\1/')
    local branch=$(grep -A 5 "^repository:" "$CONFIG_FILE" | grep "branch:" | sed 's/.*branch:[[:space:]]*"\(.*\)".*/\1/')
    
    print_msg "$CYAN" "Git Repository:"
    print_msg "$BLUE" "  URL: $url"
    print_msg "$BLUE" "  Branch: ${branch:-main}"
    echo
    
    print_msg "$CYAN" "Paths:"
    print_msg "$BLUE" "  Config: $CONFIG_FILE"
    print_msg "$BLUE" "  Homeroot: $ROOT_DIR/_homeroot"
    echo
    
    # Count tracked files
    local count=$(grep -c "source:" "$CONFIG_FILE" || echo "0")
    print_msg "$CYAN" "Tracked Files: $count"
    echo
    
    # Git status if repo exists
    if [[ -d "$ROOT_DIR/.git" ]]; then
        print_msg "$CYAN" "Git Status:"
        cd "$ROOT_DIR"
        local status=$(git status -s | wc -l | tr -d ' ')
        if [[ "$status" -gt 0 ]]; then
            print_msg "$YELLOW" "  ⚠️  $status uncommitted changes"
        else
            print_msg "$GREEN" "  ✓ Clean working tree"
        fi
    else
        print_msg "$YELLOW" "  Git not initialized"
    fi
    
    echo
}

#######################################
# Run sync operations
#######################################
run_sync() {
    local mode=$1
    
    print_header
    
    case $mode in
        dry-run)
            print_msg "$BOLD" "🔍 Running Dry-Run Preview..."
            echo
            "$SCRIPT_DIR/dotfiles-sync.sh" --dry-run
            ;;
        interactive)
            print_msg "$BOLD" "🔄 Running Interactive Sync..."
            echo
            "$SCRIPT_DIR/dotfiles-sync.sh"
            ;;
        auto-push)
            print_msg "$BOLD" "🚀 Running Auto-Push..."
            echo
            "$SCRIPT_DIR/dotfiles-push.sh"
            ;;
    esac
    
    echo
}

#######################################
# Edit config file directly
#######################################
edit_config() {
    local editor="${EDITOR:-${VISUAL:-vim}}"
    
    print_msg "$YELLOW" "Opening config in $editor..."
    sleep 1
    
    "$editor" "$CONFIG_FILE"
}

#######################################
# Wait for user input
#######################################
pause() {
    read -p "$(echo -e "${CYAN}Press Enter to continue...${NC}")"
}

#######################################
# Main menu loop
#######################################
main() {
    while true; do
        print_main_menu
        
        read -p "$(echo -e "${BOLD}${CYAN}Select option: ${NC}")" choice
        echo
        
        case $choice in
            1)
                view_tracked_files
                pause
                ;;
            2)
                add_file_to_track
                pause
                ;;
            3)
                remove_tracked_file
                pause
                ;;
            4)
                configure_git_repo
                pause
                ;;
            5)
                run_sync "dry-run"
                pause
                ;;
            6)
                run_sync "interactive"
                pause
                ;;
            7)
                run_sync "auto-push"
                pause
                ;;
            8)
                edit_config
                ;;
            9)
                view_configuration
                pause
                ;;
            0)
                print_msg "$GREEN" "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_msg "$RED" "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"
