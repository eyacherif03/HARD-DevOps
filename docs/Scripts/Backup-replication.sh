#!/bin/bash

if [ $# -ne 3 ]; then
  echo "USAGE: $0 <snapshot_name> <service_name> <replication_factor>"
  exit 1
fi

SNAPSHOT_NAME=$1
SERVICE_NAME=$2
RF=$3

VOLUME="/var/lib/docker/volumes/${SERVICE_NAME}-data/_data"
ARCHIVE="/home/<REMOTE_USER>/${SNAPSHOT_NAME}.tar.gz"
REMOTE_DIR="/home/<REMOTE_USER>/snapshots"

SSH_USER="<REMOTE_USER>"
SSH_KEY="<PATH_TO_PRIVATE_KEY>"

KEYSPACE="devops_snapshots"
TABLE="snapshot_data"


rm -f "$ARCHIVE"
tar -czf "$ARCHIVE" -C "$VOLUME" . || exit 1

cqlsh <<CQL
CREATE KEYSPACE IF NOT EXISTS $KEYSPACE
WITH replication = {'class':'SimpleStrategy','replication_factor': $RF};

USE $KEYSPACE;

CREATE TABLE IF NOT EXISTS $TABLE (
  service TEXT,
  created_at TIMESTAMP,
  name TEXT,
  PRIMARY KEY (service, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

INSERT INTO $TABLE (service, created_at, name)
VALUES ('$SERVICE_NAME', toTimestamp(now()), '$SNAPSHOT_NAME');
CQL

sleep 2

nodetool getendpoints $KEYSPACE $TABLE "$SNAPSHOT_NAME" > /tmp/replica_ips.txt

if [ ! -s /tmp/replica_ips.txt ]; then
  echo "No replica returned by Cassandra"
  exit 1

while read -r IP; do
  HOST=$(host "$IP" | awk '{print substr($NF,1,length($NF)-1)}')
  LOCAL_HOST=$(hostname -f)

  if [ "$HOST" != "$LOCAL_HOST" ]; then
    echo "  Replicate to $HOST"
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$HOST" "mkdir -p $REMOTE_DIR"
    scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$ARCHIVE" "$SSH_USER@$HOST:$REMOTE_DIR/"
  fi
done < /tmp/replica_ips.txt


