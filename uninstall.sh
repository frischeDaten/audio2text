#!/bin/bash

# Audio2Text Complete Uninstaller
# Removes all traces of Audio2Text installation from macOS
#
# This script completely removes:
# - Installation directory
# - Desktop app
# - PATH modifications
# - Cache files
# - Configuration files
# - Logs

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Audio2Text"
INSTALL_DIR="$HOME/Applications/Audio2Text"
DESKTOP_APP="$HOME/Applications/Audio2Text.app"
LOG_FILE="$HOME/Audio2Text-uninstall.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                       🗑️  Audio2Text Uninstaller                       ║"
    echo "║                                                                        ║"
    echo "║                   Complete removal of Audio2Text                      ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
    log "STEP: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

check_what_exists() {
    print_step "Scanning for Audio2Text installations..."
    
    local found_something=false
    
    # Check main installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Found installation directory: $INSTALL_DIR"
        found_something=true
    fi
    
    # Check desktop app
    if [[ -d "$DESKTOP_APP" ]]; then
        print_info "Found desktop app: $DESKTOP_APP"
        found_something=true
    fi
    
    # Check PATH modifications
    local shell_files=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile")
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]] && grep -q "Audio2Text" "$shell_file" 2>/dev/null; then
            print_info "Found PATH modification in: $shell_file"
            found_something=true
        fi
    done
    
    # Check for running processes
    if pgrep -f "audio2text\|Audio2Text" > /dev/null 2>&1; then
        print_warning "Audio2Text processes are currently running"
        print_info "These will be terminated during uninstallation"
        found_something=true
    fi
    
    # Check cache directories
    local cache_dirs=(
        "$HOME/.cache/huggingface"
        "$HOME/.cache/mlx"
        "$HOME/.cache/transformers"
        "$HOME/Library/Caches/Audio2Text"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            print_info "Found cache directory: $cache_dir"
            found_something=true
        fi
    done
    
    # Check logs
    if ls "$HOME"/Audio2Text*.log > /dev/null 2>&1; then
        print_info "Found log files: $HOME/Audio2Text*.log"
        found_something=true
    fi
    
    if [[ "$found_something" != true ]]; then
        print_info "No Audio2Text installation found"
        echo
        echo "Nothing to uninstall. Audio2Text is not installed on this system."
        exit 0
    fi
    
    echo
    print_warning "The following will be permanently deleted:"
    echo "  • All Audio2Text files and directories"
    echo "  • Desktop application"
    echo "  • Configuration files"
    echo "  • Downloaded AI models"
    echo "  • Cache files"
    echo "  • Log files"
    echo "  • PATH modifications in shell profiles"
    echo
}

confirm_uninstall() {
    print_step "Confirmation required..."
    
    echo -e "${YELLOW}WARNING: This will permanently delete ALL Audio2Text files and data.${NC}"
    echo -e "${YELLOW}This action cannot be undone.${NC}"
    echo
    echo "Are you sure you want to completely uninstall Audio2Text? (type 'yes' to confirm)"
    read -r response
    
    if [[ "$response" != "yes" ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
    
    echo
    print_info "Proceeding with complete uninstallation..."
    log "User confirmed uninstallation"
}

stop_processes() {
    print_step "Stopping Audio2Text processes..."
    
    # Find and stop Audio2Text processes
    if pgrep -f "audio2text\|Audio2Text" > /dev/null 2>&1; then
        print_info "Terminating running Audio2Text processes..."
        pkill -f "audio2text\|Audio2Text" || true
        sleep 2
        
        # Force kill if still running
        if pgrep -f "audio2text\|Audio2Text" > /dev/null 2>&1; then
            print_warning "Force killing stubborn processes..."
            pkill -9 -f "audio2text\|Audio2Text" || true
            sleep 1
        fi
        
        print_success "Processes stopped ✓"
    else
        print_success "No running processes found ✓"
    fi
}

remove_installation() {
    print_step "Removing installation files..."
    
    # Remove main installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Removing $INSTALL_DIR..."
        rm -rf "$INSTALL_DIR"
        print_success "Installation directory removed ✓"
    fi
    
    # Remove desktop app
    if [[ -d "$DESKTOP_APP" ]]; then
        print_info "Removing desktop app $DESKTOP_APP..."
        rm -rf "$DESKTOP_APP"
        print_success "Desktop app removed ✓"
    fi
}

remove_path_modifications() {
    print_step "Removing PATH modifications..."
    
    local shell_files=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile")
    local modified_files=()
    
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]] && grep -q "Audio2Text" "$shell_file" 2>/dev/null; then
            print_info "Cleaning PATH from $shell_file..."
            
            # Create backup
            cp "$shell_file" "$shell_file.audio2text-backup.$(date +%s)"
            
            # Remove Audio2Text lines
            sed -i.tmp '/Audio2Text/d' "$shell_file" 2>/dev/null || {
                # Fallback for systems where sed -i behaves differently
                grep -v "Audio2Text" "$shell_file" > "$shell_file.tmp" && mv "$shell_file.tmp" "$shell_file"
            }
            rm -f "$shell_file.tmp" 2>/dev/null || true
            
            modified_files+=("$shell_file")
            print_success "Cleaned PATH from $(basename "$shell_file") ✓"
        fi
    done
    
    if [[ ${#modified_files[@]} -eq 0 ]]; then
        print_success "No PATH modifications found ✓"
    else
        print_info "Modified shell profiles: ${modified_files[*]}"
        print_warning "Backups created with .audio2text-backup extension"
        print_info "Restart your terminal or run 'source ~/.zshrc' to apply changes"
    fi
}

remove_cache_files() {
    print_step "Removing cache files..."
    
    # Standard cache directories
    local cache_dirs=(
        "$HOME/.cache/huggingface/hub/models--mlx-community*"
        "$HOME/.cache/huggingface/hub/models--pyannote*"
        "$HOME/.cache/mlx"
        "$HOME/.cache/transformers/models--*whisper*"
        "$HOME/Library/Caches/Audio2Text"
    )
    
    local removed_count=0
    
    for cache_pattern in "${cache_dirs[@]}"; do
        if ls $cache_pattern > /dev/null 2>&1; then
            print_info "Removing cache: $cache_pattern"
            rm -rf $cache_pattern 2>/dev/null || true
            ((removed_count++))
        fi
    done
    
    # Remove specific model caches (be conservative)
    if [[ -d "$HOME/.cache/huggingface/hub" ]]; then
        find "$HOME/.cache/huggingface/hub" -name "*whisper*" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$HOME/.cache/huggingface/hub" -name "*mlx-community*" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$HOME/.cache/huggingface/hub" -name "*pyannote*" -type d -exec rm -rf {} + 2>/dev/null || true
    fi
    
    if [[ $removed_count -gt 0 ]]; then
        print_success "Cache files removed ✓"
    else
        print_success "No cache files found ✓"
    fi
}

remove_logs() {
    print_step "Removing log files..."
    
    # Remove Audio2Text logs
    local log_count=0
    if ls "$HOME"/Audio2Text*.log > /dev/null 2>&1; then
        for log_file in "$HOME"/Audio2Text*.log; do
            if [[ "$log_file" != "$LOG_FILE" ]]; then  # Don't delete current uninstall log
                rm -f "$log_file"
                ((log_count++))
            fi
        done
    fi
    
    if [[ $log_count -gt 0 ]]; then
        print_success "Removed $log_count log files ✓"
    else
        print_success "No log files found ✓"
    fi
}

cleanup_homebrew() {
    print_step "Checking Homebrew packages..."
    
    # Check if Homebrew packages were installed only for Audio2Text
    # We'll be conservative and only suggest removal
    
    local audio2text_packages=("python@3.11" "ffmpeg")
    local suggest_removal=()
    
    for package in "${audio2text_packages[@]}"; do
        if command -v brew >/dev/null 2>&1 && brew list "$package" >/dev/null 2>&1; then
            suggest_removal+=("$package")
        fi
    done
    
    if [[ ${#suggest_removal[@]} -gt 0 ]]; then
        print_info "The following Homebrew packages were installed for Audio2Text:"
        for package in "${suggest_removal[@]}"; do
            echo "  • $package"
        done
        echo
        print_warning "These packages were NOT removed as they might be used by other applications."
        print_info "To remove them manually (if not needed), run:"
        for package in "${suggest_removal[@]}"; do
            echo "  brew uninstall $package"
        done
        echo
    else
        print_success "No Homebrew packages to consider ✓"
    fi
}

final_verification() {
    print_step "Verifying complete removal..."
    
    local issues_found=false
    
    # Check if main directories still exist
    if [[ -d "$INSTALL_DIR" ]]; then
        print_error "Installation directory still exists: $INSTALL_DIR"
        issues_found=true
    fi
    
    if [[ -d "$DESKTOP_APP" ]]; then
        print_error "Desktop app still exists: $DESKTOP_APP"
        issues_found=true
    fi
    
    # Check if audio2text command is still in PATH
    if command -v audio2text >/dev/null 2>&1; then
        print_warning "audio2text command still in PATH (restart terminal to fix)"
    fi
    
    if [[ "$issues_found" == true ]]; then
        print_error "Some files could not be removed"
        print_info "You may need to remove them manually with administrator privileges"
        return 1
    else
        print_success "Complete removal verified ✓"
        return 0
    fi
}

show_summary() {
    echo
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                     ✅ Uninstallation Complete                         ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_success "Audio2Text has been completely removed from your system"
    
    echo
    print_info "What was removed:"
    echo "  ✅ Installation directory: ~/Applications/Audio2Text/"
    echo "  ✅ Desktop application: ~/Applications/Audio2Text.app"
    echo "  ✅ Configuration files and AI models"
    echo "  ✅ Cache files and temporary data"
    echo "  ✅ Log files"
    echo "  ✅ PATH modifications in shell profiles"
    
    echo
    print_info "What was NOT removed:"
    echo "  • Homebrew (if it was already installed)"
    echo "  • Python 3.11 (might be used by other apps)"
    echo "  • FFmpeg (might be used by other apps)"
    echo "  • Shell profile backups (.audio2text-backup files)"
    
    echo
    print_warning "Important notes:"
    echo "  • Restart your terminal to clear the audio2text command from PATH"
    echo "  • Shell profile backups were created for safety"
    echo "  • Homebrew packages were left intact (remove manually if not needed)"
    
    echo
    print_info "Uninstallation log saved to: $LOG_FILE"
    echo
    print_success "Thank you for using Audio2Text! 🎙️"
}

# Main uninstallation process
main() {
    print_header
    log "Starting Audio2Text uninstallation"
    
    check_what_exists
    confirm_uninstall
    stop_processes
    remove_installation
    remove_path_modifications
    remove_cache_files
    remove_logs
    cleanup_homebrew
    
    if final_verification; then
        show_summary
        log "Uninstallation completed successfully"
    else
        print_error "Uninstallation completed with issues - see above"
        log "Uninstallation completed with issues"
        exit 1
    fi
}

# Run main uninstallation
main "$@"
