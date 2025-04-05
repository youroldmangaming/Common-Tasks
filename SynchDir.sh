#!/bin/bash

# Script to sync /mnt/bigbird to /media/usb/bigbird
# Created: April 05, 2025
# usage ./backup_synch.sh --setup-cron

# Set source and destination paths
SOURCE_DIR="/mnt/bigbird/"
DEST_DIR="/media/usb/bigbird/"
LOG_FILE="/home/$(whoami)/rsync_bigbird_backup.log"
SCRIPT_PATH="$(realpath "$0")"
CRON_TIME="0 2 * * *"  # Default: Run at 2 AM daily

# Function for logging with timestamps
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to setup cron job
setup_cron() {
    log "INFO" "Checking for existing cron job..."
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        log "INFO" "Cron job already exists. Skipping cron setup."
    else
        log "INFO" "Setting up new cron job to run at $CRON_TIME"
        (crontab -l 2>/dev/null; echo "$CRON_TIME $SCRIPT_PATH") | crontab -
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Cron job added successfully. Backup will run at specified time."
        else
            log "ERROR" "Failed to add cron job."
        fi
    fi
}

# Calculate space requirements
check_space() {
    log "INFO" "Checking space requirements..."
    if [ -d "$SOURCE_DIR" ]; then
        SOURCE_SIZE=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
        log "INFO" "Source directory size: $SOURCE_SIZE"
        
        if [ -d "/media/usb" ]; then
            DEST_AVAIL=$(df -h /media/usb | tail -1 | awk '{print $4}')
            log "INFO" "Destination available space: $DEST_AVAIL"
        else
            log "WARNING" "Cannot check destination space - USB not mounted"
        fi
    else
        log "WARNING" "Cannot check source size - directory not available"
    fi
}

# Main script starts here
log "INFO" "==== Backup Script Started ===="

# Check if source is mounted
if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR" "Source directory $SOURCE_DIR is not available. Aborting."
    exit 1
fi

# Check if destination drive is mounted
if [ ! -d "/media/usb" ]; then
    log "ERROR" "USB drive is not mounted at /media/usb. Aborting."
    exit 1
fi

# Check space before backup
check_space

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    log "INFO" "Creating destination directory $DEST_DIR"
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to create destination directory. Aborting."
        exit 1
    fi
fi

# Run rsync
log "INFO" "Starting rsync operation from $SOURCE_DIR to $DEST_DIR"
rsync -avz --progress --stats "$SOURCE_DIR" "$DEST_DIR" 2>&1 | while read line; do
    log "RSYNC" "$line"
done

# Check rsync exit status (need to use pipestatus because of the pipe to while loop)
RSYNC_STATUS=${PIPESTATUS[0]}
if [ $RSYNC_STATUS -eq 0 ]; then
    log "SUCCESS" "Backup completed successfully"
else
    log "ERROR" "Backup failed with error code $RSYNC_STATUS"
fi

# Setup cron job if requested
if [ "$1" = "--setup-cron" ]; then
    log "INFO" "Setting up scheduled backups..."
    setup_cron
fi

# Final summary
if [ -d "$DEST_DIR" ]; then
    FINAL_SIZE=$(du -sh "$DEST_DIR" 2>/dev/null | cut -f1)
    log "INFO" "Final backup size at destination: $FINAL_SIZE"
fi

log "INFO" "==== Backup Script Completed ===="
