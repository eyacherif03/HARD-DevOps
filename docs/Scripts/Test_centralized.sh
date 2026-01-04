#!/bin/bash

SERVICES=("jenkins" "nexus" "sonarqube" "grafana" "prometheus")
RESULTS_FILE="resultats_centralized.txt"
BACKUP_DIR="/home/ubuntu/local_snapshots"
DATE_TAG=$(date +%Y%m%d_%H%M%S)


mkdir -p "$BACKUP_DIR"
rm -f "$RESULTS_FILE"


########################
# 1 : Backup #
########################
for SERVICE in "${SERVICES[@]}"; do
    SNAPSHOT_NAME="snapshot_${SERVICE}_${DATE_TAG}"
    SRC_PATH="/var/lib/docker/volumes/${SERVICE}-data/_data"
    ARCHIVE_PATH="$BACKUP_DIR/${SNAPSHOT_NAME}.tar.gz"

    echo "[INFO] Sauvegarde locale de $SERVICE → $ARCHIVE_PATH"
    tar -czf "$ARCHIVE_PATH" -C "$SRC_PATH" . 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "$SERVICE | $SNAPSHOT_NAME | SAUVEGARDE_FAIL" >> "$RESULTS_FILE"
    else
        echo "$SERVICE | $SNAPSHOT_NAME | SAUVEGARDE_OK" >> "$RESULTS_FILE"
    fi
done

#####################################################################
# 2 : ChaosD 
#####################################################################
sudo chaosd attack disk fill --path /home/ubuntu/local_snapshots --percent 90 --fallocate=false
sleep 5

###########################################
# 3 : Restoration     #
###########################################
for SERVICE in "${SERVICES[@]}"; do
    SNAPSHOT_NAME="snapshot_${SERVICE}_${DATE_TAG}"
    ARCHIVE_PATH="$BACKUP_DIR/${SNAPSHOT_NAME}.tar.gz"
    DEST_PATH="/var/lib/docker/volumes/${SERVICE}-data/_data"

    sudo docker stop "$SERVICE" >/dev/null 2>&1

    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo "$SERVICE | $SNAPSHOT_NAME | RESTORE_FAIL_NOFILE" >> "$RESULTS_FILE"
        continue
    fi

    sudo rm -rf "$DEST_PATH"/*
    sudo tar -xzf "$ARCHIVE_PATH" -C "$DEST_PATH" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "$SERVICE | $SNAPSHOT_NAME | RESTORE_FAIL" >> "$RESULTS_FILE"
    else
        sudo docker start "$SERVICE" >/dev/null 2>&1
        echo "$SERVICE | $SNAPSHOT_NAME | RESTORE_OK" >> "$RESULTS_FILE"
    fi
done


##############################
# Results#
##############################
TOTAL=$(grep -c "RESTORE_" "$RESULTS_FILE")
OK=$(grep -c "RESTORE_OK" "$RESULTS_FILE")
FAIL=$(grep -c -E "RESTORE_FAIL|RESTORE_FAIL_NOFILE" "$RESULTS_FILE")
TAUX=$((FAIL * 100 / TOTAL))

echo "[RESULTS] Restored Snapshots : $OK / $TOTAL" | tee -a "$RESULTS_FILE"
echo "[RESULTS] Lost Snapshots : $FAIL / $TOTAL" | tee -a "$RESULTS_FILE"
echo "[RESULTS] Loss : ${Rate}%" | tee -a "$RESULTS_FILE"