#!/bin/bash

# Incus + Colima Setup Script for macOS
# This script automates the installation and configuration of Incus with Colima

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROFILE_NAME="incus"
CPU_COUNT=4
MEMORY_GB=8
DISK_GB=100

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed successfully"
    else
        print_status "Homebrew already installed"
    fi
}

# Function to install packages
install_packages() {
    print_status "Installing Colima and Incus..."
    
    # Update Homebrew first
    brew update
    
    # Install required packages
    brew install colima incus
    
    print_success "Colima and Incus installed successfully"
}

# Function to setup Colima with Incus
setup_colima() {
    print_status "Setting up Colima with Incus runtime..."
    
    # Check if any colima instance is running
    if colima status >/dev/null 2>&1; then
        print_warning "Existing Colima instance detected"
        
        # Ask user if they want to delete existing setup
        echo -n "Do you want to delete the existing Colima setup and start fresh? [y/N]: "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_status "Stopping and deleting existing Colima setup..."
            colima stop 2>/dev/null || true
            echo "y" | colima delete 2>/dev/null || true
            print_success "Existing setup removed"
        else
            print_status "Creating new Incus profile instead..."
            PROFILE_NAME="incus-$(date +%s)"
        fi
    fi
    
    # Start Colima with Incus runtime
    print_status "Starting Colima with Incus runtime (Profile: $PROFILE_NAME)..."
    print_status "Configuration: CPU=$CPU_COUNT, Memory=${MEMORY_GB}GB, Disk=${DISK_GB}GB"
    
    if [[ "$PROFILE_NAME" == "incus" ]] && ! colima status >/dev/null 2>&1; then
        # Default profile, clean start
        colima start --runtime incus --cpu "$CPU_COUNT" --memory "$MEMORY_GB" --disk "$DISK_GB"
    else
        # Named profile
        colima start "$PROFILE_NAME" --runtime incus --cpu "$CPU_COUNT" --memory "$MEMORY_GB" --disk "$DISK_GB"
    fi
    
    print_success "Colima started with Incus runtime"
}

# Function to verify setup
verify_setup() {
    print_status "Verifying Incus setup..."
    
    # Check Colima status
    if colima status >/dev/null 2>&1; then
        print_success "Colima is running"
        colima status
    else
        print_error "Colima is not running"
        return 1
    fi
    
    # Check Incus remotes
    print_status "Available Incus remotes:"
    incus remote list
    
    # Get current default remote
    CURRENT_REMOTE=$(incus remote get-default)
    print_success "Current default remote: $CURRENT_REMOTE"
    
    # Test container creation
    print_status "Testing container creation..."
    CONTAINER_NAME="test-$(date +%s)"
    
    if incus launch images:alpine/edge "$CONTAINER_NAME" >/dev/null 2>&1; then
        print_success "Test container '$CONTAINER_NAME' created successfully"
        
        # Wait a moment for container to start
        sleep 3
        
        # Show container list
        print_status "Current containers:"
        incus list
        
        # Clean up test container
        incus delete "$CONTAINER_NAME" --force >/dev/null 2>&1
        print_success "Test container cleaned up"
    else
        print_error "Failed to create test container"
        return 1
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF

${GREEN}Incus + Colima Setup Complete!${NC}

${BLUE}Common Commands:${NC}
  # Launch a new container
  incus launch images:debian/13 my-container
  incus launch images:ubuntu/22.04 ubuntu-container
  incus launch images:alpine/edge alpine-container
  
  # List containers
  incus list
  
  # Shell into a container
  incus shell my-container
  
  # Execute commands in a container
  incus exec my-container -- ls -la
  
  # Stop/start containers
  incus stop my-container
  incus start my-container
  
  # Delete containers
  incus delete my-container --force

${BLUE}Colima Management:${NC}
  # Check Colima status
  colima status
  
  # Stop Colima
  colima stop$(if [[ "$PROFILE_NAME" != "incus" ]]; then echo " $PROFILE_NAME"; fi)
  
  # Start Colima
  colima start$(if [[ "$PROFILE_NAME" != "incus" ]]; then echo " $PROFILE_NAME"; fi)
  
  # List all Colima profiles
  colima list

${BLUE}Available Image Sources:${NC}
  images:alpine/edge
  images:debian/12, images:debian/13
  images:ubuntu/20.04, images:ubuntu/22.04, images:ubuntu/24.04
  images:fedora/39, images:fedora/40
  
${YELLOW}Note:${NC} Your current Incus remote is: $(incus remote get-default 2>/dev/null || echo "Not available")

EOF
}

# Main function
main() {
    echo -e "${GREEN}=== Incus + Colima Setup Script for macOS ===${NC}"
    echo
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE_NAME="$2"
                shift 2
                ;;
            --cpu)
                CPU_COUNT="$2"
                shift 2
                ;;
            --memory)
                MEMORY_GB="$2"
                shift 2
                ;;
            --disk)
                DISK_GB="$2"
                shift 2
                ;;
            --help)
                cat << EOF
Usage: $0 [OPTIONS]

Options:
  --profile NAME    Colima profile name (default: incus)
  --cpu COUNT       Number of CPUs (default: 4)
  --memory GB       Memory in GB (default: 8)
  --disk GB         Disk size in GB (default: 100)
  --help           Show this help message

Examples:
  $0
  $0 --profile my-incus --cpu 6 --memory 12
  $0 --cpu 2 --memory 4 --disk 50
EOF
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_status "Configuration: Profile=$PROFILE_NAME, CPU=$CPU_COUNT, Memory=${MEMORY_GB}GB, Disk=${DISK_GB}GB"
    echo
    
    # Run setup steps
    install_homebrew
    echo
    
    install_packages
    echo
    
    setup_colima
    echo
    
    verify_setup
    echo
    
    show_usage
    
    print_success "Setup completed successfully! 🎉"
}

# Run main function with all arguments
main "$@"
