#!/bin/bash
set -e # bail on error

#ADF_VER="v2.5"
export IDF_VER="ef4b1b7704"
export PLATFORM="esp32s3" # Current general family
export FLASH_BAUD=1843200 # Optimistic but seems to work for me for now

export SALLOW_PATH="$PWD"
#export ADF_PATH="$SALLOW_PATH/deps/esp-adf"
export IDF_PATH="$SALLOW_PATH/deps/esp-idf"

check_port() {
if [ ! $PORT ]; then
    echo "You need to define the PORT environment variable to do serial stuff - exiting"
    exit 1
fi

if [ ! -c $PORT ]; then
    echo "Cannot find configured port $PORT - exiting"
    exit 1
fi
}

# Pull in environment
if [ -r $IDF_PATH/export.sh ]; then
    . $IDF_PATH/export.sh > /dev/null
else
    echo "Environment not found - normal for setup" 
fi

print_monitor_help() {
echo "
You can exit the serial monitor with CTRL + ]
"
}


# Some of this may seem redundant but for build, clean, etc we'll probably need to do our own stuff later
case $1 in

config)
    idf.py menuconfig
;;

clean)
    idf.py clean
;;

fullclean)
    idf.py fullclean
;;

build)
    idf.py build
;;

flash)
    check_port
    print_monitor_help
    idf.py -p "$PORT" -b "$FLASH_BAUD" flash monitor
;;

monitor)
    check_port
    print_monitor_help
    idf.py -p "$PORT" monitor
;;

destroy)
    echo "YOU ARE ABOUT TO REMOVE THIS ENTIRE ENVIRONMENT AND RESET THE REPO. HIT ENTER TO CONFIRM."
    read
    echo "SERIOUSLY - YOU WILL LOSE WORK AND I WILL NOT STOP YOU IF YOU HIT ENTER AGAIN!"
    read
    echo "LAST CHANCE!"
    read
    #git reset --hard
    #git clean -fdx
    idf.py fullclean
    rm -rf ~/.espressif deps
    echo "Not a trace left. You will have to run setup again."
;;

install|setup)
    mkdir -p deps
    cd deps
    # Setup IDF
    git clone https://github.com/espressif/esp-idf.git
    cd esp-idf
    git checkout "$IDF_VER"
    git submodule update --init --recursive
    ./install.sh "$PLATFORM"

    # This is ridiculous
    #cd $IDF_PATH
    #git apply $ADF_PATH/idf_patches/idf_v4.4_freertos.patch

    cd $SALLOW_PATH
    cp sdkconfig.sallow sdkconfig

    echo "You can now run ./utils.sh config and navigate to Sallow Configuration for your environment"
;;

*)
    echo "Passing args directly to idf.py"
    shift
    idf.py "$@"
;;

esac