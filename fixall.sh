#!/bin/bash

# Copyright (C) 2017 bsmelo.io
#
# This file is subject to the terms and conditions of the GNU General
# Public License v3.0. See the file LICENSE in the top level directory
# for more details.

# Dependencies: smartctl, grep, dd, ifind, ffind, debugfs, shred, awk
FS_TYPE="ext4"                  # "NTFS" or "ext4"
STARTING_BLOCK=16001024         # From `sudo fdisk -lu /dev/sda`
DEVICE="/dev/sda"               # Target Physical Device
FS_DEVICE="/dev/sda2"           # Target File System
AUTO_INODE="NOOOONE"            # Known bad inode (useful for big files spanning multiple bad sectors)
# We assume a Block Size of 4086 bytes and a Sector of 512 bytes

run_dd_ntfs ()
{
    (set -x; sudo dd seek="$1" count=1 oflag=direct if=/dev/zero of="${DEVICE}")
    sudo sync
    echo
    echo
}

run_dd_ext3 ()
{
    (set -x; sudo dd if=/dev/zero of="${FS_DEVICE}" bs=4096 count=1 seek="$1")
    sudo sync
    echo
    echo
}

b=$((($1-${STARTING_BLOCK})/8))
echo "Block is ${b}"

if [ "${FS_TYPE}" == "NTFS" ]; then
    inode=$(sudo ifind -d $b "${FS_DEVICE}")
    echo "Inode is ${inode}"

    if [[ $inode == "${AUTO_INODE}" ]]; then
        echo "Auto"
        run_dd_ntfs $1
    else
        fname=$(sudo ffind "${FS_DEVICE}" $inode)
        echo "File is ${fname}"

        read -r -p "Should we delete this block? " response
        if [[ $response == "y" ]]
        then
            run_dd_ntfs $1
        fi
    fi
elif [ "${FS_TYPE}" == "ext4" ]; then
    output=$(set -x; sudo debugfs -R "testb ${b}" "${FS_DEVICE}")
    if [[ $output == *"not in use"* ]]; then
        echo "Block is not in use"

        read -r -p "Should we delete this block? " response
        if [[ $response == "y" ]]
        then
            run_dd_ext3 $b
        fi

        exit 0
    fi
    inode=$(set -x; sudo debugfs -R "icheck ${b}" "${FS_DEVICE}" | awk 'NR == 2 {print $2}')
    echo "Inode is ${inode}"

    if [[ $inode == "${AUTO_INODE}" ]]; then
        echo "Auto"
        run_dd_ext3 $b
    else
        fname=$(set -x; sudo debugfs -R "ncheck ${inode}" "${FS_DEVICE}" | awk 'NR == 2 { s = ""; for (i = 2; i <= NF; i++) s = s $i " "; print s }')
        echo "File is ${fname}"

        read -r -p "Should we delete this block? " response
        if [[ $response == "y" ]]
        then
            run_dd_ext3 $b
        else
        read -r -p "Should we shred this file? " response
            if [[ $response == "y" ]]
            then
                (set -x; shred --iterations=2 --remove "${fname}")
            fi
        fi
    fi
else
    echo "Unsupported File System type"
    exit 1
fi
