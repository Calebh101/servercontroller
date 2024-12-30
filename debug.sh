# Debug addons, that when ran from "source debug.sh" from any script, will add some new debug features.

echo "-- DEBUG MODE --"
trap DEBUG_CATCH ERR

VERSION=1.0.0
script_dir=$(dirname "$(realpath "$0")")

echo "DEBUG: Adding debug addons..."
echo "DEBUG: Script dir: $script_dir"
echo "DEBUG: Overwriting log file..."
builtin echo "-- DEBUG ADDITIONS BY CALEBH101 VERSION $VERSION --" > $script_dir/debug.log

DEBUG_CATCH () {
    echo "-- DEBUG ADDITIONS ERROR CAUGHT --"
    builtin echo "-- DEBUG ADDITIONS ERROR CAUGHT --" >> $script_dir/debug.log
}

clear () {
    echo "DEBUG: Terminal clear called"
}

exit () {
    echo "DEBUG: Script exit called"
}

source () {
    echo "DEBUG: Sourcing $*..."
    builtin source "$*"
}

echo () {
    if [ -z "$*" ]; then
        builtin echo "-- BLANK LINE --" | tee -a $script_dir/debug.log
    else
        builtin echo "echo: $*" | tee -a $script_dir/debug.log
    fi
}

echo "DEBUG: Debug addons loaded"