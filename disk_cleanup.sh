#!/bin/bash

# Debian System Cleanup Script
# Run with: bash cleanup.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $4}'
}

# Function to calculate freed space
calculate_freed_space() {
    local before=$1
    local after=$2
    echo "scale=2; $before - $after" | bc
}

echo "=================================="
echo "  Debian System Cleanup Script"
echo "=================================="
echo

# Check if running as root for some operations
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root - will perform system-wide cleanup"
    IS_ROOT=true
else
    print_status "Running as user - will perform user-level cleanup and request sudo when needed"
    IS_ROOT=false
fi

# Initial disk usage
print_status "Checking initial disk usage..."
INITIAL_FREE=$(df / | awk 'NR==2 {print $4}')
echo "Available space: $(get_disk_usage)"
echo

# 1. Package cleanup
print_status "Cleaning package cache and removing unused packages..."
if command -v apt &> /dev/null; then
    sudo apt autoremove -y
    sudo apt autoclean
    sudo apt clean
    print_success "Package cleanup completed"
else
    print_error "APT not found - not a Debian/Ubuntu system?"
fi
echo

# 2. Clear user cache
print_status "Clearing user cache files..."
if [ -d "$HOME/.cache" ]; then
    find "$HOME/.cache" -type f -delete 2>/dev/null || true
    print_success "User cache cleared"
fi

if [ -d "$HOME/.thumbnails" ]; then
    rm -rf "$HOME/.thumbnails"/*
    print_success "Thumbnails cleared"
fi

# Clear user trash
if [ -d "$HOME/.local/share/Trash" ]; then
    rm -rf "$HOME/.local/share/Trash"/*
    print_success "User trash cleared"
fi
echo

# 3. Clean system logs (requires sudo)
print_status "Cleaning system logs..."
if command -v journalctl &> /dev/null; then
    sudo journalctl --vacuum-time=7d
    sudo journalctl --vacuum-size=100M
    print_success "Journal logs cleaned"
fi

# Truncate old log files
if [ "$IS_ROOT" = true ] || sudo -n true 2>/dev/null; then
    sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
    sudo find /var/log -type f -name "*.log.*" -delete 2>/dev/null || true
    print_success "Log files cleaned"
fi
echo

# 4. Clear temporary files
print_status "Clearing temporary files..."
# User temp files
if [ -d "/tmp" ]; then
    find /tmp -type f -user $(whoami) -delete 2>/dev/null || true
fi

# System temp files (requires sudo)
if [ "$IS_ROOT" = true ] || sudo -n true 2>/dev/null; then
    sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
    sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    print_success "Temporary files cleared"
fi
echo

# 5. Clear browser caches (common locations)
print_status "Clearing browser caches..."
BROWSERS=("google-chrome" "chromium" "firefox" "mozilla")
for browser in "${BROWSERS[@]}"; do
    if [ -d "$HOME/.cache/$browser" ]; then
        rm -rf "$HOME/.cache/$browser"/*
        print_success "$browser cache cleared"
    fi
    if [ -d "$HOME/.config/$browser" ]; then
        find "$HOME/.config/$browser" -name "Cache" -type d -exec rm -rf {} \; 2>/dev/null || true
    fi
done
echo

# 6. Docker cleanup (if Docker is installed)
if command -v docker &> /dev/null; then
    print_status "Cleaning Docker resources..."
    if sudo docker system df &>/dev/null; then
        echo "Docker space usage before cleanup:"
        sudo docker system df
        echo
        
        # Standard Docker cleanup
        sudo docker system prune -f
        sudo docker image prune -f
        
        # Check for orphaned volumes
        print_status "Checking for orphaned Docker volumes..."
        ORPHANED_VOLUMES=$(sudo docker volume ls -qf dangling=true)
        if [ -n "$ORPHANED_VOLUMES" ]; then
            echo "Orphaned volumes found:"
            sudo docker volume ls -f dangling=true
            echo
            print_warning "Found orphaned volumes. To remove them, run:"
            echo "sudo docker volume prune -f"
            echo
        else
            print_success "No orphaned volumes found"
        fi
        
        # List all volumes for manual review
        print_status "All Docker volumes:"
        sudo docker volume ls
        echo
        
        print_success "Docker cleanup completed"
        echo "Docker space usage after cleanup:"
        sudo docker system df
    fi
    echo
fi

# 7. Find and report large files (excluding known system areas)
print_status "Finding large files (>100MB) in common directories..."
echo "Large files found:"

# Search common user and system directories, excluding problematic areas
SEARCH_DIRS=(
    "$HOME"
    "/var/log"
    "/var/cache"
    "/tmp"
    "/var/tmp"
    "/opt"
    "/usr/local"
)

for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -5
    fi
done

# Also check root level but exclude problematic directories
timeout 30 find / -maxdepth 2 -type f -size +100M \
    -not -path "/proc/*" \
    -not -path "/sys/*" \
    -not -path "/dev/*" \
    -not -path "/var/lib/docker/*" \
    -not -path "/snap/*" \
    -exec ls -lh {} \; 2>/dev/null | head -5 || print_warning "Large file search timed out after 30 seconds"
echo

# 8. Check for old kernels
print_status "Checking for old kernel versions..."
if dpkg -l | grep -q linux-image; then
    CURRENT_KERNEL=$(uname -r)
    print_status "Current kernel: $CURRENT_KERNEL"
    OLD_KERNELS=$(dpkg -l | grep linux-image | grep -v "$CURRENT_KERNEL" | awk '{print $2}' | head -5)
    if [ -n "$OLD_KERNELS" ]; then
        echo "Old kernels found (consider removing manually):"
        echo "$OLD_KERNELS"
        echo "To remove: sudo apt remove [kernel-name]"
    else
        print_success "No old kernels found"
    fi
fi
echo

# 9. Final disk usage report
print_status "Cleanup completed! Checking final disk usage..."
FINAL_FREE=$(df / | awk 'NR==2 {print $4}')
echo "Available space: $(get_disk_usage)"

if command -v bc &> /dev/null; then
    FREED=$(echo "scale=2; ($FINAL_FREE - $INITIAL_FREE) / 1024" | bc)
    if (( $(echo "$FREED > 0" | bc -l) )); then
        print_success "Approximately ${FREED}GB of space freed!"
    else
        print_status "Cleanup completed (space freed may not be immediately visible)"
    fi
else
    print_status "Install 'bc' package to see space freed calculation"
fi

echo
echo "=================================="
echo "  Cleanup Summary"
echo "=================================="
echo "✓ Package cache cleaned"
echo "✓ User cache cleared"
echo "✓ System logs cleaned"
echo "✓ Temporary files removed"
echo "✓ Browser caches cleared"
echo "✓ Docker resources cleaned (if applicable)"
echo "✓ Large files identified"
echo "✓ Old kernels checked"
echo
print_success "System cleanup completed!"
echo
echo "Manual cleanup suggestions:"
echo "• Review large files listed above"
echo "• Check ~/Downloads for old files"
echo "• Review and remove old personal files"
echo "• Consider moving large files to external storage"
