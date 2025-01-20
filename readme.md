# What is this?

This program is designed to help me manage my server. Has many built-in tools for doing so.

# Changelog

## 0.0.0

- Initial release
- Supports systemctl and node

## 0.1.0

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

## Next Up

Future goals:

- A way to automatically run the script to do things like start services and back up via -a and others
- A way to configure the script to automatically start everything at startup