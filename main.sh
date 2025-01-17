#!/bin/bash
echo "Starting..."
DEBUG=0 # Loads debug.sh addons

ver=0.0.0
verS=0.0.0A

script_dir=$(dirname "$(realpath "$0")")
declare -a PIDS

echo "Detecting environment..."
if [ -n "$GNOME_TERMINAL_SCREEN" ]; then
    terminal="gnome-terminal"
else
    terminal=$TERM_PROGRAM
fi

catch() {
    echo "An error occured"
    exit -1
}

quit() {
    echo "Exiting Server Controller..."
    exit 0
}

help() {
    builtin echo -e "Command\tAction\n1\tStart nginx\n2\tStart node.js server\n3\tStart mongod\nD\tSelect Discord bot to starts\nX\tKill all servers and nodes\nXN\tKill all nodes\nXS\tKill all servers\nX#\tKill specific server\nIP\tStart noip-duc\nB\tBackup data\nS\tShow status\n0\tQuit" | column -t -s $'\t'
}

pause() {
    message="Press enter to continue..."
    if [ $# -eq 0 ]; then
        arg=""
    else
        arg="$1 "
    fi
    printf "${arg}${message} "
    read
}

gnome-tab() {
    echo "Detecting gnome-terminal..."
    trap 'fallbackcommand "$1"' ERR
    if [[ "$terminal" == "gnome-terminal" ]]; then
        echo "Launching new tab of gnome-terminal..."
        gnome-terminal --tab -- bash -c "$1; exec bash"
    else
        echo "Error: Current terminal environment is not gnome-terminal"
        if command -v gnome-terminal &> /dev/null; then
            echo "Launching new window of gnome-terminal..."
            gnome-terminal -- bash -c "$1; exec bash"
        else
            echo "Error: Unable to launch gnome-terminal"
            fallbackcommand "$1"
        fi
    fi
}

nodestatus() {
    output=$(ps -eo pid,command | grep -E '^[[:space:]]*[0-9]+[[:space:]]+node' | awk '{print $1, $2, $3}')

    if [ -n "$output" ]; then
        echo $output
    else
        echo "No nodes running."
    fi
}

killnodes() {
    echo "Killing nodes..."
    sudo pkill node
    echo "Killed nodes"
}

killservices() {
    echo "Stopping systemctl services..."
    stopservice "nginx"
    stopservice "mongod"
    echo "Stopped systemctl services"
}

fallbackcommand () {
    echo "Unable to run command via expected route"
    echo "Running command directly..."
    $1
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

startnode () {
    echo "Setting up node..."
    file="$1"
    dir=$(dirname "$file")
    echo "Starting node $file..."
    gnome-tab "echo \"Starting node: $file\" && echo "" && cd \"$dir\" && node \"$file\""
}

discord-input() {
    echo "Finding directories..."
    directories=($(find "$DISCORD_DIR" -mindepth 1 -maxdepth 1 -type d))
    clear

    echo "Welcome to Calebh101 Discord Bot Controller"
    echo "servercontroller:D $ver ($verS)"
    echo ""

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

    builtin echo -e "$output" | column -t -s $'\t'
    echo ""

    echo -n "Select an option: >> "
    read -r choice
    echo ""

    # Validate the choice (check if it's a number and within range)
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#directories[@]} ]; then
        echo "Starting process..."
        dir="${directories[$((choice - 1))]}"
        filePath="$dir/$file"
        echo "Selected option: $dir"
        startnode "$filePath"
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
    pause "Subprocess complete."
    discord-input
}

command-input() {
    echo "Getting environmental variables..."
    source $script_dir/env.sh        # private variables
    source $script_dir/public.env.sh # public configuration
    echo "Loading..."
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
            0|exit|quit|stop|EXIT|QUIT|STOP)
                quit
                ;;
            1)
                startservice "nginx"
                ;;
            X1)
                stopservice "nginx"
                ;;
            2)
                startnode "$NODE_DIR/server.js"
                ;;
            3)
                startservice "mongod"
                ;;
            3X)
                stopservice "mongod"
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
                showservice "mongod"
                echo ""
                echo "Showing nodes status..."
                nodestatus
                ;;
            IP)
                echo "Starting noip-duc..."
                gnome-tab "noip-duc --username $NOIPUSERNAME --password $NOIPPASSWORD --hostnames $NOIPHOSTNAME"
                echo "Started noip-duc"
                ;;
            *)
                echo "Invalid command: $user_input"
                ;;
        esac
        echo ""
        pause "Process complete."
        command-input
    fi
}

if [ "$DEBUG" -gt 0 ]; then
    echo "Loading debug mode additions..."
    source $script_dir/debug.sh
fi

echo "Loading..."
echo "script_dir: $script_dir"
echo "terminal: $terminal"
command-input
