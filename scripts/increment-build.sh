#!/bin/bash

# Auto-increment build version script
# This script increments the CFBundleVersion in Info.plist on each build

INFO_PLIST="${SRCROOT}/Info.plist"

# Get current build number
if [ -f "$INFO_PLIST" ]; then
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST" 2>/dev/null)
    
    # If CFBundleVersion doesn't exist or is not a number, start at 1
    if [ -z "$CURRENT_BUILD" ] || ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
        CURRENT_BUILD=1
    fi
    
    # Increment build number
    NEW_BUILD=$((CURRENT_BUILD + 1))
    
    # Update Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $NEW_BUILD" "$INFO_PLIST"
    
    echo "Build version incremented: $CURRENT_BUILD -> $NEW_BUILD"
else
    echo "Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi
