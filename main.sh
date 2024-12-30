#!/bin/bash

ver=0.0.0
verS=0.0.0A

script_dir=$(dirname "$(realpath "$0")")
declare -a PIDS

catch() {
    echo "An error occured"
    exit -1
}

quit() {
    echo "Exiting Server Controller..."
    exit 0
}

help() {
    echo -e "Command\tAction\n1\tStart nginx\n2\tStart node.js server\nD\tSelect Discord bot to starts\nX\tKill all servers and nodes\nXN\tKill all nodes\nXS\tKill all servers\nX#\tKill specific server\nIP\tStart noip-duc\nB\tBackup data\nS\tShow status\n0\tQuit" | column -t -s $'\t'
}

nodestatus() {
    ps -eo pid,command | grep -E '^[[:space:]]*[0-9]+[[:space:]]+node' | awk '{print $1, $2, $3}'
}

killnodes() {
    echo "Killing nodes..."
    sudo pkill node
    echo "Killed nodes"
}

killservices() {
    echo "Stopping systemctl services..."
    stopservice "nginx"
    echo "Stopped systemctl services"
}

showservice() {
    echo "$1 status: $(systemctl is-active $1)"
}

startservice() {
    echo "Starting $1..."
    sudo systemctl start $1
    echo "Started $1"
    echo "$1 status: $(systemctl is-active $1)"
}

stopservice() {
    echo "Stopping $1..."
    sudo systemctl stop $1
    echo "Stopped $1"
    echo "$1 status: $(systemctl is-active $1)"
}

discord-input() {
    clear
    echo "Welcome to Calebh101 Discord Bot Controller"
    echo "servercontroller > D $ver ($verS)"
    echo ""

    directories=($(find "$DISCORD_DIR" -mindepth 1 -maxdepth 1 -type d))
    file="bot.js"
    output="Command\tAction"

    # Check if there are any directories
    if [ ${#directories[@]} -eq 0 ]; then
        echo "Error: No Discord bot directories found"
        break
    fi

    # Add directory options to the output string
    for i in "${!directories[@]}"; do
        output+=$'\n'"$((i + 1))\t${directories[$i]}/$file"
    done

    # Add special options (X, C) to the output string
    output+=$'\n'"X\tKill all nodes"
    output+=$'\n'"S\tShow node status"
    output+=$'\n'"C\tExit"

    echo -e "$output" | column -t -s $'\t'
    echo ""

    echo -n "Select an option: >> "
    read -r choice
    echo ""

    # Validate the choice (check if it's a number and within range)
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#directories[@]} ]; then
        dir="${directories[$((choice - 1))]}"
        filePath="$dir/$file"
        echo ""
        echo "Selected option: $dir"
        echo "Starting node: $filePath"
        gnome-terminal --tab -- bash -c "node $filePath; exec bash"
    elif [[ "$choice" == "S" ]]; then
        nodestatus
    elif [[ "$choice" == "X" ]]; then
        killnodes
    elif [[ "$choice" == "C" ]]; then
        command-input
        exit
    else
        echo "Invalid selection: $choice."
    fi
    echo ""
    read -p "Subprocess complete. Press enter to continue... "
    discord-input
}

command-input() {
    source $script_dir/env.sh        # private variables
    source $script_dir/public.env.sh # public configuration
    clear
    echo "Welcome to Calebh101 Server Controller"
    echo "servercontroller $ver ($verS)"
    echo ""
    help
    echo ""
    read -p "Select an option: >> " user_input
    clear
    echo "Selected option: $user_input"
    echo "Starting process..."
    echo ""

    if [ -z "$user_input" ]; then
        quit
    else
        case "$user_input" in
            0)
                quit
                ;;
            1)
                startservice "nginx"
                ;;
            X1)
                stopservice "nginx"
                ;;
            2)
                gnome-terminal --tab -- bash -c "node $NODE_DIR/server.js; exec bash"
                ;;
            D)
                discord-input
                ;;
            X)
                killservices
                echo ""
                killnodes
                ;;
            XN)
                killnodes
                ;;
            XS)
                killservices
                ;;
            X#)
                echo "Please replace \"#\" with the number of the running server."
                ;;
            X2)
                echo "Nodes are unsupported for killing individually. Please use XN to kill all nodes."
                ;;
            B)
                echo "Launching backup session..."
                $script_dir/backup.sh
                echo "Ended backup session"
                ;;
            S)
                echo "Showing systemctl status..."
                showservice "nginx"
                echo ""
                echo "Showing nodes status..."
                nodestatus
                ;;
            IP)
                echo "Starting noip-duc..."
                gnome-terminal --tab -- bash -c "noip-duc --username $NOIPUSERNAME --password $NOIPPASSWORD --hostnames $NOIPHOSTNAME; exec bash"
                echo "Started noip-duc"
                ;;
            *)
                echo "Invalid command: $user_input"
                ;;
        esac
        echo ""
        read -p "Process complete. Press enter to continue... "
        command-input
    fi
}

command-input