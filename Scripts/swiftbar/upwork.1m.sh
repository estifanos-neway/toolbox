#!/bin/bash

# SwiftBar plugin for Upwork time tracking with earnings and progress bars
# <swiftbar.title>Upwork Tracker Hours + Earnings</swiftbar.title>
# <swiftbar.version>v1.6</swiftbar.version>
# <swiftbar.author>Dagim</swiftbar.author>
# <swiftbar.desc>Show Upwork hours worked, earnings, and progress bars</swiftbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

# hide default items
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>false</swiftbar.hideSwiftBar>

RATE=9       # hourly rate in USD
ETB_RATE=160   # conversion rate USD → ETB
DAILY_GOAL=8   # in hours
WEEKLY_GOAL=45 # in hours

UPWORK_DIR="$HOME/Library/Application Support/Upwork/Upwork/Logs"
# Find the most recent log file that contains time tracking data (upwork..*.log pattern)
UPWORK_LOG=$(ls -t "$UPWORK_DIR"/upwork..*.log 2>/dev/null | head -1)

# Check if log exists
if [[ ! -f "$UPWORK_LOG" ]]; then
    echo "0:00"
    echo "---"
    echo "📊 Upwork: No Data"
    exit 0
fi

# Extract minutes from Upwork logs (handle whitespace and commas)
MINUTES_TODAY=$(grep -o '"minutesWorkedToday"[[:space:]]*:[[:space:]]*[0-9]\+' "$UPWORK_LOG" 2>/dev/null | tail -1 | grep -o '[0-9]\+')
MINUTES_WEEK=$(grep -o '"minutesWorkedThisWeek"[[:space:]]*:[[:space:]]*[0-9]\+' "$UPWORK_LOG" 2>/dev/null | tail -1 | grep -o '[0-9]\+')

# Extract last time worked timestamp
LAST_TIME_WORKED=$(grep -o '"lastTimeWorked"[[:space:]]*:[[:space:]]*[0-9]\+' "$UPWORK_LOG" 2>/dev/null | tail -1 | grep -o '[0-9]\+')

# Debug: Show extracted values (uncomment for debugging)
# echo "DEBUG: UPWORK_LOG='$UPWORK_LOG'"
# echo "DEBUG: File exists: $(test -f "$UPWORK_LOG" && echo "YES" || echo "NO")"
# echo "DEBUG: MINUTES_TODAY='$MINUTES_TODAY', MINUTES_WEEK='$MINUTES_WEEK'"

if [[ -z "$MINUTES_TODAY" && -z "$MINUTES_WEEK" ]]; then
    echo "0:00"
    echo "---"
    echo "📊 No Data"
    exit 0
fi

# Set defaults if values are missing
if [[ -z "$MINUTES_TODAY" ]]; then
    MINUTES_TODAY=0
fi
if [[ -z "$MINUTES_WEEK" ]]; then
    MINUTES_WEEK=0
fi
if [[ -z "$LAST_TIME_WORKED" ]]; then
    LAST_TIME_WORKED=0
fi

# Add 1 minute to today's work
MINUTES_TODAY=$((MINUTES_TODAY + 1))

# Calculate time since last start (current time - last time worked)
CURRENT_TIME=$(date +%s)
TIME_SINCE_LAST_START=$((CURRENT_TIME - LAST_TIME_WORKED))
MINUTES_SINCE_LAST_START=$((TIME_SINCE_LAST_START / 60 + 1))

# Convert to hours (float)
HOURS_TODAY=$(echo "scale=2; $MINUTES_TODAY / 60" | bc)
HOURS_WEEK=$(echo "scale=2; $MINUTES_WEEK / 60" | bc)
HOURS_SINCE_LAST_START=$(echo "scale=2; $MINUTES_SINCE_LAST_START / 60" | bc)

# Calculate earnings
EARNINGS_TODAY_USD=$(echo "scale=2; $HOURS_TODAY * $RATE" | bc)
EARNINGS_WEEK_USD=$(echo "scale=2; $HOURS_WEEK * $RATE" | bc)
EARNINGS_TODAY_ETB=$(echo "scale=0; $EARNINGS_TODAY_USD * $ETB_RATE" | bc)
EARNINGS_WEEK_ETB=$(echo "scale=0; $EARNINGS_WEEK_USD * $ETB_RATE" | bc)

# Format time functions
format_time() {
    printf "%d:%02d" $(( $1 / 60 )) $(( $1 % 60 ))
}

format_hours() {
    local hours=$1
    local hours_int=$(echo "$hours" | cut -d. -f1)
    local minutes_decimal=$(echo "$hours" | cut -d. -f2)
    local minutes_int=$(echo "scale=0; $minutes_decimal * 60 / 100" | bc)
    printf "%d:%02d" "$hours_int" "$minutes_int"
}

TODAY_TIME=$(format_time $MINUTES_TODAY)
WEEK_TIME=$(format_time $MINUTES_WEEK)
HOURS_TODAY_FORMATTED=$(format_hours $HOURS_TODAY)
HOURS_SINCE_FORMATTED=$(format_hours $HOURS_SINCE_LAST_START)

# Progress bar function (integer math)
progress_bar() {
    local value=$1
    local goal=$2
    local length=10
    local percent=$(echo "($value * 100)/$goal" | bc) # integer %
    if (( percent > 100 )); then percent=100; fi
    local filled=$(( percent * length / 100 ))
    local empty=$(( length - filled ))
    
    # Build filled portion
    local filled_bar=""
    for ((i=1; i<=filled; i++)); do
        filled_bar+="█"
    done
    
    # Build empty portion  
    local empty_bar=""
    for ((i=1; i<=empty; i++)); do
        empty_bar+="--"
    done
    
    printf "%s%s [%d%%]" "$filled_bar" "$empty_bar" "$percent"
}

# Build progress bars
DAILY_PROGRESS=$(progress_bar $(printf "%.0f" $HOURS_TODAY) $DAILY_GOAL)
WEEKLY_PROGRESS=$(progress_bar $(printf "%.0f" $HOURS_WEEK) $WEEKLY_GOAL)

# Get current week number
WEEK_NUMBER=$(date +%V)

# Menu bar: Show week number, today's hours and time since last start
echo "$HOURS_TODAY_FORMATTED/$HOURS_SINCE_FORMATTED-$WEEK_NUMBER"
echo "---"

# Dropdown details
echo "📅 Today: $TODAY_TIME"
echo "💵 USD: \$${EARNINGS_TODAY_USD}"
echo "🇪🇹 ETB: ${EARNINGS_TODAY_ETB} ብር"
echo "---"
echo "📊 This week: $WEEK_TIME"
echo "💵 USD: \$${EARNINGS_WEEK_USD}"
echo "🇪🇹 ETB: ${EARNINGS_WEEK_ETB} ብር"
echo "---"
echo "---"
echo "Today:        $DAILY_PROGRESS"
echo "This week: $WEEKLY_PROGRESS"
echo "---"
# echo "🔄 Refresh | refresh=true"
# echo "⚙️ Open Upwork | bash='open' param1='-a' param2='Upwork'"
