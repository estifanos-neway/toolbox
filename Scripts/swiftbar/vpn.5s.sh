#!/bin/bash

# SwiftBar plugin for VPN control
# <swiftbar.title>VPN Controller</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.author>Estifanos Neway</swiftbar.author>
# <swiftbar.desc>Start/Stop VPN Python script with status indicator</swiftbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

# hide default items
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>false</swiftbar.hideSwiftBar>

# Configuration
VPN_SCRIPT="/Users/estifanosneway/Documents/Projects/tool-box/Scripts/swiftbar/vpn.py"
PID_FILE="$HOME/.vpn_script.pid"

# Check if the VPN script is running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            # Verify it's actually our Python script
            if ps -p "$pid" -o command= | grep -q "vpn.py"; then
                return 0
            fi
        fi
        # PID file exists but process is not running, clean up
        rm -f "$PID_FILE"
    fi
    return 1
}

# Start the VPN script
start_vpn() {
    if is_running; then
        echo "VPN is already running"
        exit 0
    fi
    
    if [[ ! -f "$VPN_SCRIPT" ]]; then
        echo "Error: VPN script not found at $VPN_SCRIPT"
        exit 1
    fi
    
    # Start the Python script in the background
    nohup python "$VPN_SCRIPT" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    echo "VPN started (PID: $pid)"
}

# Stop the VPN script
stop_vpn() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo "VPN stopped"
        else
            rm -f "$PID_FILE"
            echo "VPN was not running"
        fi
    else
        # Try to find and kill any running vpn.py process
        pkill -f "python.*vpn.py"
        echo "VPN stopped"
    fi
}

# Handle actions
if [[ "$1" == "start" ]]; then
    start_vpn
    exit 0
elif [[ "$1" == "stop" ]]; then
    stop_vpn
    exit 0
fi

# Display status
if is_running; then
    # Running - click to stop
    echo "😼 | bash='$0' param1=stop terminal=false refresh=true"
    echo "---"
    PID=$(cat "$PID_FILE")
    echo "pid: $PID"
    echo "---"
    echo "😺 stop vpn | bash='$0' param1=stop terminal=false refresh=true"
else
    # Not running - click to start
    echo "😺 | bash='$0' param1=start terminal=false refresh=true"
    echo "---"
    echo "😼 start vpn | bash='$0' param1=start terminal=false refresh=true"
fi

