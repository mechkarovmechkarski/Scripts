#!/usr/bin/env bash

### improvements ideas
# can add feature to ask if you want to backup all disks and skip CD/DVD
###
#
snapshot_name="guest-state"
snapshot_location="$HOME/overlay1.qcow2"
backup_location="$HOME/backups"

echo -e "\e[36m[CHECK]\e[0mBackup location: $backup_location"
echo "Waiting for 3 sec"
sleep 3

if [ ! -d $backup_location ]; then
	echo -e "\e[42m[INFO]\e[0mCreating main backup location folder"
	mkdir -p $backup_location
fi

echo -e "\e[32m[INFO]\e[0mAll VMs"
sudo virsh list --all

read -p $'\e[36m[INPUT]\e[0mType name of the VM you want to backup?' vm_name

SECONDS=0

vm_backup_location=$backup_location/$vm_name
echo -e "\e[32m[INFO]\e[0mCurrent snapshots"
sudo virsh snapshot-list $vm_name

if [ ! -d $vm_backup_location ]; then
	echo -e "\e[32m[INFO]\e[0mCreating VM backup location folder - $vm_backup_location"
	mkdir -p $vm_backup_location
fi
echo -e "\e[36m[CHECK]\e[0mBackups:"
sudo ls -lhp $vm_backup_location
number_of_backups=$(sudo ls -lhp $vm_backup_location | wc -l)
echo -e "\e[32m[INFO]\e[0mBackups real size:"
sudo du -h $vm_backup_location

disks_raw=$(sudo virsh domblklist $vm_name)
number_of_disks=$(echo $disks_raw | wc -w)
number_of_disks=$(((($number_of_disks-3))/2))
echo -e "\e[32m[INFO]\e[0mNumber of VM disks - $number_of_disks"

for (( i = 0; i < 1; i++ ));
do
	disk_full_path=$(echo $disks_raw | awk '{print $5}')
        disk_name=$(echo $disk_full_path | awk -F"/" '{print $NF}')
	backup_disk_name=""
	read -p $'\e[36m[INPUT]\e[0mEnter backup name [OR LEAVE DEFAULT]:' backup_disk_name
        if [[ -z "$backup_disk_name" ]]; then
		backup_disk_name=$disk_name-$number_of_backups.bak
	fi

        echo -e "\e[32m[INFO]\e[0mDisk location - $disk_full_path"
	echo -e "\e[32m[INFO]\e[0mCreating a snapshot for vda disk only..."
	sudo virsh snapshot-create-as --domain $vm_name --name $snapshot_name \
        --diskspec vda,file=$snapshot_location \
	--disk-only --atomic --quiesce

	echo -e "\e[32m[INFO]\e[0mSnapshots"
	sudo virsh snapshot-list $vm_name

	echo -e "\e[32m[INFO]\e[0mBacking up vda disk..."
	sudo rsync -avhWS --progress $disk_full_path \
		"$vm_backup_location/$backup_disk_name"
	
	echo -e "\e[32m[INFO]\e[0mBlockcommiting..."
	sudo virsh blockcommit $vm_name vda --active --verbose --pivot
	
	echo -e "\e[32m[INFO]\e[0mRemoving snapshot created..."
	sudo virsh snapshot-delete $vm_name --metadata $snapshot_name
	sudo rm $snapshot_location
done

echo -e "\e[32m[INFO]\e[0mSnapshots"
sudo virsh snapshot-list $vm_name
echo -e "\e[32m[INFO]\e[0mDone"
duration=$SECONDS
echo -e "\e[32m[INFO]\e[0mElapsed time: $((duration / 60)) minutes and $((duration % 60)) seconds"

