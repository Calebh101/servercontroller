#!/bin/bash

ver=0.0.0
verS=0.0.0A

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
    echo -e "Command\tAction\n1\tStart nginx\n2\tStart database server\nX\tKill all servers and nodes\nXN\tKill all nodes\nXS\tKill all servers\nX#\tKill specific server\nB\tBackup data\n\n0\tQuit" | column -t -s $'\t'
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

command-input() {
    echo "Welcome to Calebh101 Server Controller"
    echo "servercontroller $ver ($verS)"
    echo ""
    help
    echo ""
    read -p "Select an option: >> " user_input
    clear
    echo "Selected option: $user_input"

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
                gnome-terminal --tab -- bash -c 'node /var/www/db/test/server.js; exec bash'
                ;;
            X)
                killservices
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
                echo "Launching backup script..."
                script_dir=$(dirname "$(realpath "$0")")
                gnome-terminal --tab -- bash -c "$script_dir/backup.sh; exec bash"
                echo "Launched backup script"
                ;;
            *)
                echo "Invalid command: $user_input"
                ;;
        esac
        echo ""
        command-input
    fi
}

clear
command-input