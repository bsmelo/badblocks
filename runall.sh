#!/bin/bash
# Dependencies: smartctl, grep, dd, ifind, ffind, debugfs, shred, awk
TEST="select,960000000-max"     # Self-test to be run, see `man smartctl`
FS_DEVICE="/dev/sda2"           # Target File System
POLLING_INTERVAL=5              # Interval, in seconds, between checks for a finished test

(set -x; sudo smartctl -t "${TEST}" "${FS_DEVICE}")

while true; do
    output=$(sudo smartctl -l "${FS_DEVICE}" | grep "# 1")

    if [[ $output == *"Completed: read failure"* ]]; then
        echo
        failed_lba=$(echo $output | awk '{print $10}')
        echo "Failed at ${failed_lba}"
        sudo ./fixall.sh $failed_lba

        (set -x; sudo smartctl -t "${TEST}" "${FS_DEVICE}" >/dev/null)
    elif [[ $output == *"Completed without error"* ]]; then
        echo "Completed without error"
        exit 0
    fi

    echo -ne '.'
    sleep "${POLLING_INTERVAL}"
done
