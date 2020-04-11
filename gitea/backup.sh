#!/bin/bash

LOGFILE="/var/log/backup/gitea.log"
FILENAME="gitea-dump.zip"
BACKUP_DIRECTORY="/mnt/mydisk/docker-volumes/gitea/backup"
CREDENTIALS_DIRECTORY="/home/pi/.backup"

REPOSITORY="/mnt/backup/gitea"
PASSWORD_FILE="$CREDENTIALS_DIRECTORY/gitea"

# see output of blkid for PARTUUID
BACKUP_DISK_UUID="BACKUP-DISK-PARTUUID"
BACKUP_DISK_DIRECTORY="/mnt/backup"

set -eu

timestamp() {
    date +%Y-%m-%d\ %T:
}

log() {
   echo "$(timestamp) $1" >> $LOGFILE
}

container() {
  docker ps -qf "name=gitea"
}

cleanup() {
    umount $BACKUP_DISK_DIRECTORY 2>> $LOGFILE
    docker exec $(container) sh -c 'rm -r /data/backup/*'
}

abort() {
    log "an error occurred. cleaning up and exiting..."
    cleanup
    exit $?
}

# Make sure you are root, see: https://askubuntu.com/a/30157
if ! [ $(id -u) = 0 ]; then
    echo "Needs to be run as root. Exiting..."
    exit 1
fi

trap 'abort' ERR

# Ensure the backup directory exists and is empty
if ! [ -d $BACKUP_DIRECTORY ]; then
    log "Backup directory does not exist. Required with permissions for git user. Exiting..."
    exit 1
fi

if [ "$(ls -A $BACKUP_DIRECTORY)" ]; then
    log "Backup directory needs to be empty. Exiting..."
    exit 1
fi

log "mounting backup disk"
mount /dev/disk/by-partuuid/$BACKUP_DISK_UUID $BACKUP_DISK_DIRECTORY 2>> $LOGFILE

log "starting gitea backup"

log "dumping complete data"
docker exec -e FILENAME=$FILENAME -u git -w /data/backup $(container) sh -c '/app/gitea/gitea dump -c /data/gitea/conf/app.ini --file $FILENAME' 2>> $LOGFILE
log "dumping completed"

log "preparing data"

# Extract back and repo zip file to take advantage of de-duplication in backup
cd $BACKUP_DIRECTORY

unzip $FILENAME > /dev/null
rm $FILENAME
unzip gitea-repo.zip > /dev/null

log "backing up locally using restic"

restic -r $REPOSITORY --password-file=$PASSWORD_FILE backup $BACKUP_DIRECTORY &>> $LOGFILE

log "checking repository integrity..."
restic -r $REPOSITORY --password-file=$PASSWORD_FILE -q check &>> $LOGFILE

log "cleaning up..."
cleanup

log "gitea backup completed"
