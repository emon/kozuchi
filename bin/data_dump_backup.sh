#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

RAILS_ROOT=/root/kozuchi
DATA_FILE=$RAILS_ROOT/db/data.yml
DATA_FILE_OLD=${DATA_FILE}.old
GPG_PASSWORD=$RAILS_ROOT/bin/gpg-password.txt
TODAY=`date +"%Y%m%d"`

PARENT_DIR="0B4PlbB1AYa8sZjR*********************************************" # in Google Drive
# got `gdrive list -q "name contains 'kozuchi backup'"`

cd $RAILS_ROOT

if [ -f $DATA_FILE ]; then
  mv $DATA_FILE $DATA_FILE_OLD
else
  touch $DATA_FILE_OLD
fi

./bin/rake db:data:dump

if diff -q $DATA_FILE_OLD $DATA_FILE > /dev/null; then
  echo "No need to backup"
else
  gpg --batch --passphrase-fd 0 --symmetric --compress-algo bzip2 -o- $DATA_FILE < $GPG_PASSWORD | gdrive upload - --parent $PARENT_DIR --no-progress data-${TODAY}.yml.gpg
fi

rm $DATA_FILE_OLD

