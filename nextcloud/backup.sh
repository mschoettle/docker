#!/bin/bash

LOGFILE="/var/log/backup/nextcloud.log"
BACKUP_DIRECTORY="/mnt/mydisk/docker-volumes/nextcloud"
CREDENTIALS_DIRECTORY="/home/pi/.backup"

REPOSITORY="/mnt/backup/nextcloud"
PASSWORD_FILE="$CREDENTIALS_DIRECTORY/nextcloud"

# get PARTUUID of backup disk with blkid
BACKUP_DISK_UUID="BACKUP_DISK_PARTUUID"
BACKUP_DISK_DIRECTORY="/mnt/backup"

set -eu

timestamp() {
    date +%Y-%m-%d\ %T:
}

log() {
   echo "$(timestamp) $1" >> $LOGFILE
}

container() {
  docker ps -qf "name=nextcloud-app"
}

cleanup() {
    umount $BACKUP_DISK_DIRECTORY 2>> $LOGFILE
    docker exec -u www-data $(container) php occ maintenance:mode --off &>> $LOGFILE
    docker exec -u www-data $(container) sh -c 'rm production.sql'
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

# setting the credentials

log "starting nextcloud backup"

mount /dev/disk/by-partuuid/$BACKUP_DISK_UUID $BACKUP_DISK_DIRECTORY 2>> $LOGFILE

docker exec -u www-data $(container) php occ maintenance:mode --on &>> $LOGFILE

log "backup up database..."
# copy it into container to have the right permissions
mysqldump --single-transaction -h localhost -u root nextcloud | docker exec -i -u www-data $(container) sh -c 'cat - > /var/www/html/production.sql' 2>> $LOGFILE

#log "copying data..."
#rsync -rvia --delete --exclude ".DS_Store" $BACKUP_DIRECTORY /mnt/pidata/backup/nextcloud

log "backing up using restic..."
restic -r $REPOSITORY --password-file=$PASSWORD_FILE backup $BACKUP_DIRECTORY &>> $LOGFILE

log "checking repository integrity..."
restic -r $REPOSITORY --password-file=$PASSWORD_FILE -q check &>> $LOGFILE

log "cleaning up..."
cleanup

log "nextcloud backup completed"
