#!/bin/bash

# Device model which screen should be mirrored
# To fetch this type "adb devices -l" in the terminal and copy the modelnumber from the device you want to use for screen mirroring
deviceModel=A142
pinCode="67676767"

# Get connected devices
connectedDevices="$(adb devices)"
echo connected devices output: $connectedDevices > phone-connection.log

# Get amount of connected devices
amountOfConnectedDevices="$(echo "$connectedDevices" | grep -i -w -c "device")"
echo amount of connected devices: $amountOfConnectedDevices >> phone-connection.log

# Check if there are devices connected
if [ $amountOfConnectedDevices -lt 1 ]; then
    echo zero devices connected >> phone-connection.log
    exit 1
elif [ $amountOfConnectedDevices -eq 1 ]; then
    echo 1 device connected >> phone-connection.log
    device="$(adb shell getprop ro.product.model)"
    if [ "$device" != "$deviceModel" ]; then
        echo "$device is not the same as the given device model ($deviceModel)" >> phone-connection.log
        exit 1
    fi
fi
deviceId="$(adb devices -l | grep -i $deviceModel | grep -o '^[^ ]*')"
echo selected device is: $deviceId >> phone-connection.log

# Check screen state and if phone is locked or not
screenState="$(adb shell dumpsys display | grep "mScreenOn")"
if [ "$screenState"="mScreenOn=false" ]; then
    # Unlock and open login screen
    adb -s $deviceId shell input keyevent 26
    adb -s $deviceId shell input keyevent 66
    sleep 1
    adb -s $deviceId shell input text $pinCode
    echo turned on phone screen and opened login screen >> phone-connection.log
else
    screenLockStatus="$(adb shell dumpsys deviceidle | grep 'mScreenLocked')"
    if [ "$screenLockStatus"="mScreenLocked=true"]; then
        # Open login screen
        adb -s $deviceId shell input keyevent 66
        sleep 2
        adb -s $deviceId shell input text $pinCode
        echo opened login screen and logged in>> phone-connection.log
    else
        echo "your phone is already unlocked. (idiot😅)"
    fi
fi

scrcpy -s $deviceId -S
exit
