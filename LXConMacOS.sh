#!/bin/bash

# Colima-Incus Setup Script
# This script installs/updates Colima, Incus, and sets up a Debian container named "trixi"

set -e  # Exit on any error

echo "🚀 Starting Colima-Incus setup..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Homebrew is installed
check_homebrew() {
    if ! command_exists brew; then
        echo "❌ Homebrew is not installed. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    echo "✅ Homebrew found"
}

# Function to update Homebrew
update_homebrew() {
    echo "🔄 Updating Homebrew..."
    brew update
}

# Function to install or update Incus
install_incus() {
    if command_exists incus; then
        echo "📦 Incus already installed, updating..."
        brew upgrade incus || echo "⚠️  Incus upgrade failed or no update available"
    else
        echo "📦 Installing Incus..."
        brew install incus
    fi
    echo "✅ Incus ready"
}

# Function to handle Colima installation/update
install_colima() {
    local needs_reinstall=false
    
    if command_exists colima; then
        echo "📦 Colima already installed"
        
        # Check if it's the HEAD version
        local colima_info=$(brew list --versions colima 2>/dev/null || echo "")
        if [[ "$colima_info" == *"HEAD"* ]]; then
            echo "🔄 Updating HEAD version of Colima..."
            brew uninstall colima
            needs_reinstall=true
        else
            echo "🔄 Switching to HEAD version of Colima..."
            brew unlink colima 2>/dev/null || true
            needs_reinstall=true
        fi
    else
        echo "📦 Installing Colima (HEAD version)..."
        needs_reinstall=true
    fi
    
    if [ "$needs_reinstall" = true ]; then
        brew install --head colima
        brew link colima
    fi
    
    echo "✅ Colima (HEAD) ready"
}

# Function to stop Colima if running
stop_colima() {
    if colima status >/dev/null 2>&1; then
        echo "🛑 Stopping existing Colima instance..."
        colima stop
    fi
}

# Function to start Colima with Incus runtime
start_colima() {
    echo "🚀 Starting Colima with Incus runtime..."
    colima start --runtime=incus
    echo "✅ Colima started with Incus runtime"
}

# Function to add remote repositories
add_remotes() {
    echo "🌐 Adding remote repositories..."
    
    # Add images remote (if not exists)
    if ! incus remote list | grep -q "images"; then
        echo "  Adding images.linuxcontainers.org remote..."
        incus remote add images https://images.linuxcontainers.org --protocol simplestreams --public
    else
        echo "  ✅ Images remote already exists"
    fi
    
    # Add Ubuntu remote (if not exists)
    if ! incus remote list | grep -q "ubuntu"; then
        echo "  Adding Ubuntu cloud images remote..."
        incus remote add ubuntu https://cloud-images.ubuntu.com/releases --protocol simplestreams --public
    else
        echo "  ✅ Ubuntu remote already exists"
    fi
    
    # Add Debian remote (if not exists)
    if ! incus remote list | grep -q "debian"; then
        echo "  Adding Debian cloud images remote..."
        incus remote add debian https://cdimage.debian.org/images/cloud --protocol simplestreams --public
    else
        echo "  ✅ Debian remote already exists"
    fi
}

# Function to create trixi container
create_trixi() {
    if incus list | grep -q "trixi"; then
        echo "📋 Container 'trixi' already exists"
        local status=$(incus list trixi -c s --format csv)
        if [ "$status" != "RUNNING" ]; then
            echo "🚀 Starting trixi container..."
            incus start trixi
        else
            echo "✅ Container 'trixi' is already running"
        fi
    else
        echo "📋 Creating Debian 13 container 'trixi'..."
        incus launch debian:13 trixi
        echo "✅ Container 'trixi' created and started"
    fi
}

# Function to show final status
show_status() {
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "📊 Status:"
    echo "  Colima: $(colima status 2>/dev/null || echo 'Not running')"
    echo "  Incus containers:"
    incus list
    echo ""
    echo "🔧 To connect to the trixi container:"
    echo "  incus exec trixi -- bash"
    echo ""
    echo "📝 Useful commands:"
    echo "  colima status          - Check Colima status"
    echo "  colima stop           - Stop Colima"
    echo "  incus list            - List all containers"
    echo "  incus stop trixi      - Stop the trixi container"
    echo "  incus delete trixi    - Delete the trixi container"
}

# Main execution
main() {
    echo "==============================================="
    echo "🐳 Colima + Incus + Trixi Setup Script"
    echo "==============================================="
    
    check_homebrew
    update_homebrew
    install_incus
    install_colima
    stop_colima
    start_colima
    add_remotes
    create_trixi
    show_status
}

# Run main function
main "$@"
