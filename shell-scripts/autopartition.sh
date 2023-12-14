#!/bin/bash
BLACKLIST="/dev/sda"

usage() {
    echo "Usage: $(basename $0) <new disk>"
}

scan_for_new_disks() {
    # Looks for unpartitioned disks
    declare -a RET
    DEVS=($(ls -1 /dev/sd*|egrep -v "${BLACKLIST}"|egrep -v "[0-9]$"))
    for DEV in "${DEVS[@]}";
    do
        # Check each device if there is a "1" partition.  If not,
        # "assume" it is not partitioned.
        if [ ! -b ${DEV}1 ];
        then
            RET+="${DEV} "
        fi
    done
    echo "${RET}"
}

add_to_fstab() {
    UUID=${1}
    MOUNTPOINT=${2}
    grep "${UUID}" /etc/fstab >/dev/null 2>&1
    if [ ${?} -eq 0 ];
    then
        echo "Not adding ${UUID} to fstab again (it's already there!)"
    else
        LINE="UUID=\"${UUID}\"\t${MOUNTPOINT}\txfs\tdefaults,nofail\t0 1"
        echo "to be added ${LINE}"
        echo -e "${LINE}" >> /etc/fstab
    fi
}

is_partitioned() {
   blkid ${1} 2>&1
   return "${?}"
}

do_partition() {
# This function creates one (1) primary partition on the
# disk, using all available space
    DISK=${1}
    parted "${DISK}" --script mklabel gpt mkpart xfspart xfs 0% 100%
    mkfs.xfs "${DISK}1"
    partprobe "${DISK}1"
        mkdir /opt/sparkbeyond1
    mount "${DISK}1" /opt/sparkbeyond1
    lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"
}

if [ -z "${1}" ];
then
    DISKS=($(scan_for_new_disks))
else
    DISKS=("${@}")
fi
echo "Disks are ${DISKS[@]}"
for DISK in "${DISKS[@]}";
do
    echo "Working on ${DISK}"
    is_partitioned ${DISK}
    if [ ${?} -ne 0 ];
    then
        echo "${DISK} is not partitioned, partitioning"
        do_partition ${DISK}
    fi
    UUID=$(blkid "${DISK}1" -o value -s UUID)
    add_to_fstab "${UUID}" "/opt/sparkbeyond1"
done
