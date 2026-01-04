#!/bin/bash

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <service_name>"
  exit 1
fi

SERVICE_NAME=$1
LOCAL_VOLUME="/var/lib/docker/volumes/${SERVICE_NAME}-data/_data"
ARCHIVE_LOCAL="/home/<REMOTE_USER>/tmp_snapshot_restore.tar.gz"
REMOTE_DIR="/home/<REMOTE_USER>/snapshots"

SSH_USER="<REMOTE_USER>"
SSH_KEY="<PATH_TO_PRIVATE_KEY>"

KEYSPACE="devops_snapshots"
TABLE="snapshot_data"

SNAPSHOT_NAME=$(cqlsh -e "
USE $KEYSPACE;
SELECT name FROM $TABLE
WHERE service='$SERVICE_NAME'
ORDER BY created_at DESC
LIMIT 1;
" | tail -n 1 | xargs)

if [ -z "$SNAPSHOT_NAME" ]; then
  echo "No snapshot found"
  exit 1
fi

echo "[INFO] Snapshot selected : $SNAPSHOT_NAME"

# Replicas via DHT
nodetool getendpoints $KEYSPACE $TABLE "$SNAPSHOT_NAME" > /tmp/replica_ips.txt

# Searching for the last replica available
FOUND=0
while read -r IP; do
  HOST=$(host "$IP" | awk '{print substr($NF,1,length($NF)-1)}')

  if ssh -o BatchMode=yes -o ConnectTimeout=3 -i "$SSH_KEY" "$SSH_USER@$HOST" \
     "test -f $REMOTE_DIR/${SNAPSHOT_NAME}.tar.gz"; then
    echo "[INFO] Snapshot found in $HOST"
    scp -i "$SSH_KEY" "$SSH_USER@$HOST:$REMOTE_DIR/${SNAPSHOT_NAME}.tar.gz" "$ARCHIVE_LOCAL"
    FOUND=1
    break
  fi
done < /tmp/replica_ips.txt

if [ "$FOUND" -ne 1 ]; then
  echo "No available snapshot"
  exit 1
fi

# Volume Restoration
rm -rf "$LOCAL_VOLUME"/*
tar -xzf "$ARCHIVE_LOCAL" -C "$LOCAL_VOLUME"

