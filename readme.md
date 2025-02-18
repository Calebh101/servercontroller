# What is this?

This program is designed to help me manage my server. It has many built-in tools for doing so, including a DDNS update client, pm2, and systemctl. Includes Discord bot support.

# Who is this for?

Just me. You can use or remix it if you want but I specifically tailored it to me for my server management.

# Usage

## Setup

Add \<path to servercontroller\>/bin to your path to be able to run it from anywhere.

```bash
echo '\nexport PATH="$PATH:<path to servercontroller>/bin"' >> ~/.bashrc
source ~/.bashrc
```

Replace \<path to servercontroller\> with the path to where this is.

## Usage

(sudo) servercontroller [options]

Examples:

- sudo servercontroller -b
- servercontroller -dbxs

### Options

Options to add to the command.

- -d: debug mode
- -b (auto option): automatically runs backup.sh without needing human interaction
- -s (auto option): automatically starts all services and nodes without human interaction
- -x (auto option): automatically kills all services and nodes without human interaction
- -xs (auto option) (in this order): automatically restarts all services and nodes without human interaction

# Changelog

## 0.0.0

### 0.0.0A

- Initial release
- Supports systemctl and node

## 0.1.0

### 0.1.0A

- Added pre-flight checks
    - root user (warns the user if the program is being run as root user)
    - public.env.sh (warns the user if it exists)
    - env.sh (warns the user if it doesn't exist, or if it doesn't exist but default.env.sh is still found)
- Switched from node to pm2
- New R# option to restart service
- Deprecated public.env.sh
- Debug mode is no longer a variable, it's now a paramter: -d
- Now includes default.env.sh
- Debug addon improvements
- Other small things

## 0.1.1

### 0.1.1A

- New script options:
    - -b (auto option): automatically runs backup.sh without needing human interaction
    - -s (auto option): automatically starts all services and nodes without human interaction
    - -x (auto option): automatically kills all services and nodes without human interaction
    - -xs (auto option): automatically restarts all services and nodes without human interaction
- Deprecated serverbackup (will not work after 0.1.1A)
- Deprecated pre-flight check "root user"

### 0.1.1B

- Removed serverbackup (replaced with servercontroller -b)
- Fixed bug affecting auto services

## Next Up

Future goals:

- A way to configure the script to automatically start everything at startup