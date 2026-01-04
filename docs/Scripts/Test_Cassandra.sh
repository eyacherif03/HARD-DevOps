#!/bin/bash

SERVICES=("jenkins" "nexus" "sonarqube" "grafana" "prometheus")
RESULTS_FILE="resultats_distributed_cassandra.txt"
DATE_TAG=$(date +%Y%m%d_%H%M%S)
FACTOR=2
DEAD_NODE_IP="IP_node_cassandra_1"
SSH_KEY="<PATH_TO_PRIVATE_KEY>"
SSH_USER="<REMOTE_USER>"
BACKUP_TMP="/tmp"

rm -f "$RESULTS_FILE"
echo "---------------------------------------------" >> "$RESULTS_FILE"

for SERVICE in "${SERVICES[@]}"; do
    SNAPSHOT_NAME="snapshot_${SERVICE}_${DATE_TAG}"

    sudo ./Backup-replication.sh "$SNAPSHOT_NAME" "$SERVICE" "$FACTOR"
    if [ $? -ne 0 ]; then
        echo "$SERVICE | $SNAPSHOT_NAME | SAUVEGARDE_FAIL" >> "$RESULTS_FILE"
    else
        echo "$SERVICE | $SNAPSHOT_NAME | SAUVEGARDE_OK" >> "$RESULTS_FILE"
    fi
done


ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$DEAD_NODE_IP" "sudo chaosd attack host shutdown --uid cassandra-down"
sleep 20

for SERVICE in "${SERVICES[@]}"; do
    SNAPSHOT_NAME="snapshot_${SERVICE}_${DATE_TAG}"

    sudo ./Restoration.sh "$SNAPSHOT_NAME" "$SERVICE"
    if [ $? -ne 0 ]; then
        echo "$SERVICE | $SNAPSHOT_NAME | RESTORE_FAIL" >> "$RESULTS_FILE"
    else
        echo "$SERVICE | $SNAPSHOT_NAME | RESTORE_OK" >> "$RESULTS_FILE"
    fi
done


echo "---------------------------------------------" >> "$RESULTS_FILE"
TOTAL=$(grep -c "RESTORE_" "$RESULTS_FILE")
OK=$(grep -c "RESTORE_OK" "$RESULTS_FILE")
FAIL=$(grep -c "RESTORE_FAIL" "$RESULTS_FILE")
TAUX=$((FAIL * 100 / TOTAL))

echo "Restored Snapshots : $OK / $TOTAL" | tee -a "$RESULTS_FILE"
echo "Lost Snapshots : $FAIL / $TOTAL" | tee -a "$RESULTS_FILE"
echo " Loss : ${TAUX}%" | tee -a "$RESULTS_FILE"
