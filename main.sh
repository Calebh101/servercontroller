#!/bin/bash
echo "Starting..."

ver=0.1.1
verS=0.1.1B

script_dir=$(dirname "$(realpath "$0")")
DEBUG=0        # don't set manually here; instead, use servercontroller -d
preventexit=0  # breaks some stuff, made it because why not
autoran=0      # to log if an autorun service was called (to automatically exit the script after all autorun services are complete)

echo "Detecting environment..."
if [ -n "$GNOME_TERMINAL_SCREEN" ]; then
    terminal="gnome-terminal"
else
    terminal=$TERM_PROGRAM
fi

catch() {
    status=-1
    echo "Exiting on critical error... (status code: $status)"
    if [[ $preventexit -eq 0 ]]; then
        exit $status
    else
        echo "Preventing exit (status code: $status)"
    fi
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

echo "Running pre-flight checks..."
echo "Check deprecated: root user"

if [ -s "$script_dir/public.env.sh" ]; then
    pause "WARNING! public.env.sh detected! Using public.env.sh has been deprecated since version 0.1.0 (0.1.0A). Please move all configurations from public.env.sh to env.sh and remove public.env.sh."
else
    echo "Check passed: public.env.sh"
fi

if [ -s "$script_dir/env.sh" ]; then
    echo "Check passed: env.sh"
else
    desc="env.sh not found! env.sh is required to run this program!"
    if [ -s "$script_dir/default.env.sh" ]; then
        pause "WARNING! $desc Please edit default.env.sh for your configuration, then rename it to \"env.sh\"."
    else
        pause "WARNING! $desc Please make sure the file name is \"env.sh\" and it is found in the source directory."
    fi
    catch
fi

echo "Getting environmental variables..."
source $script_dir/env.sh

quit() {
    status=0
    echo "Exiting Server Controller..."
        if [[ $preventexit -eq 0 ]]; then
        exit $status
    else
        echo "Preventing exit (status code: $status)"
    fi
}

startservice() {
    name=$1
    echo "Starting service $name..."
    sudo systemctl start $name
    echo "Started $name"
    showservice $name
}

startnode() {
    requirecommand "pm2"
    echo "Setting up node..."
    file="$1"
    dir=$(dirname "$file")
    echo "Starting node $file..."
    pm2 start "$file" -i max
}

backup() {
    echo "Launching backup session..."
    $script_dir/backup.sh
    echo "Ended backup session"
}

help() {
    builtin echo -e "Command\tAction\n1\tStart nginx\n2\tStart node.js server\n3\tStart mongod\nD\tSelect Discord bot to start\nA\tStart all services and nodes\nX\tKill all servers and nodes\nXN\tKill all nodes\nXS\tKill all servers\n\nR#\tRestart specific service\nX#\tKill specific service\nS\tShow status\nB\tBackup\nIP\tStart noip-duc\n0\tQuit" | column -t -s $'\t'
}

startall() {
    echo "Starting all services and nodes..."
    echo "Starting services..."
    startservice "nginx"
    startservice "mongod"

    echo "Starting nodes..."
    startnode "$NODE_DIR/server.js"

    echo "Starting Discord bots..."
    echo "Finding directories..."
    directories=($(find "$DISCORD_DIR" -mindepth 1 -maxdepth 1 -type d))

    file="bot.js"

    if [ ${#directories[@]} -eq 0 ]; then
        echo "Error: No Discord bot directories found"
        catch
    fi

    for i in "${!directories[@]}"; do
        echo "Starting process..."
        dir="${directories[$((choice - 1))]}"
        filePath="$dir/$file"
        echo "Starting bot: $filePath"
        startnode "$filePath"
    done
}

stopservice() {
    name=$1
    echo "Stopping service $name..."
    sudo systemctl stop $name
    echo "Stopped $name"
    showservice $name
}

killnodes() {
    requirecommand "pm2"
    echo "Killing nodes..."
    pm2 kill
    echo "Killed nodes"
}

killservices() {
    echo "Stopping systemctl services..."
    stopservice "nginx"
    stopservice "mongod"
    echo "Stopped systemctl services"
}

showservice() {
    name=$1
    echo "Service $name status: $(systemctl is-active $name)"
}

shownode() {
    requirecommand "pm2"
    name=$1
    echo "Node $name status:"
    pm2 jlist | jq --arg name "$name" '.[] | select(.name==$name) | .pm2_env.status'
}

requirecommand() {
    command=$1
    if command -v $command &> /dev/null; then
        echo "Command available: $command"
    else
        pause "WARNING: command $command is required to use this command"
        catch
    fi
}

killall() {
    echo "Killing all services and nodes..."
    killservices
    killnodes
    echo "Killed all services and nodes"
}

echo "Scanning options..."
while getopts ":dbszx" opt; do
    case $opt in
        d)
            DEBUG=1
            echo "Debug mode enabled"
            ;;
        b)
            autoran=1
            echo "Auto service started: backup"
            backup
            echo "Auto service ended"
            ;;
        s)
            autoran=1
            echo "Auto service started: startall"
            startall
            echo "Auto service ended"
            ;;
        x)
            autoran=1
            echo "Auto service started: killall"
            killall
            echo "Auto service ended"
            ;;
        \?)
            pause "WARNING: Invalid option provided: -$OPTARG:"
            catch
            ;;
    esac
done

if [ "$autoran" -eq 1 ]; then
    echo "Ended auto services"
    quit
fi

if [ "$DEBUG" -gt 0 ]; then
    echo "Loading debug mode additions..."
    source $script_dir/debug.sh
fi

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
    echo "Showing node status..."
    requirecommand "pm2"
    pm2 list
}

fallbackcommand () {
    echo "Unable to run command via expected route"
    echo "Running command directly..."
    $1
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

    if [ ${#directories[@]} -eq 0 ]; then
        echo "Error: No Discord bot directories found"
        break
    fi

    for i in "${!directories[@]}"; do
        output+=$'\n'"$((i + 1))\t${directories[$i]}/$file"
    done

    output+=$'\n'"X\tKill all nodes"
    output+=$'\n'"S\tShow node status"
    output+=$'\n'"C\tExit"

    builtin echo -e "$output" | column -t -s $'\t'
    echo ""

    echo -n "Select an option: >> "
    read -r choice
    echo ""

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

restartnode() {
    requirecommand "pm2"
    name=$1
    echo "Restarting node $name..."
    pm2 restart $name
    echo "Restarted node"
}

restartservice() {
    name=$1
    echo "Restarting service $name..."
    sudo systemctl restart "$name"
    echo "Restarted service"
    showservice $name
}

stopnode() {
    requirecommand "pm2"
    name=$1
    echo "Stopping node $name..."
    pm2 stop $name
    echo "Stopped node"
}

command-input() {
    echo "Loading..."
    clear
    echo "Welcome to Calebh101 Server Controller"
    echo "servercontroller $ver ($verS)"
    if [[ DEBUG -eq 1 ]]; then
        echo "Running in debug mode"
    fi
    if [[ $EUID -eq 0 ]]; then
        echo "Running as sudo"
    fi
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
            A)
                startall
                ;;
            1)
                startservice "nginx"
                ;;
            X1)
                stopservice "nginx"
                ;;
            R1)
                restartservice "nginx"
                ;;
            2)
                startnode "$NODE_DIR/server.js"
                ;;
            X2)
                stopnode "server"
                ;;
            R2)
                restartnode "server"
                ;;
            3)
                startservice "mongod"
                ;;
            X3)
                stopservice "mongod"
                ;;
            R3)
                restartservice "mongod"
                ;;
            D)
                discord-input
                ;;
            X)
                killall
                ;;
            XN)
                killnodes
                ;;
            XS)
                killservices
                ;;
            X#|R#)
                echo "Please replace \"#\" with the number of the running service."
                ;;
            B)
                backup
                ;;
            S)
                echo "Showing systemctl status..."
                showservice "nginx"
                showservice "mongod"
                echo ""
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

echo "Loading..."
echo "script_dir: $script_dir"
echo "terminal: $terminal"
command-input
