#!/bin/bash

SERVICES=("jenkins" "sonarqube" "nexus" "prometheus" "grafana")
REPL_FACTOR=2
SIZES=(50 75 100 150 200)
ITERATIONS=3
RESULT_FILE="/home/ubuntu/mttr_results.csv"

echo "service,taille(Mo),MTTR(s)" > "$RESULT_FILE"

for SERVICE in "${SERVICES[@]}"; do

    VOLUME="/var/lib/docker/volumes/${SERVICE}-data/_data/test"
    echo "================ SERVICE : $SERVICE ================"

    for SIZE in "${SIZES[@]}"; do
        echo "========== TAILLE : $SIZE MB =========="

        sudo rm -rf "$VOLUME"/*
        sudo mkdir -p "$VOLUME"
        sudo dd if=/dev/urandom of="$VOLUME/data_$SIZE" bs=1M count=$SIZE status=none
        sudo chown -R 1000:1000 "$VOLUME"

        TIMESTAMP=$(date +%s)
        SNAP_NAME="snapshot_${SERVICE}_${SIZE}MB_${TIMESTAMP}"
        echo "[INFO] Création du snapshot : $SNAP_NAME"
        sudo ./Backup-replication.sh "$SNAP_NAME" "$SERVICE" "$REPL_FACTOR"
        sleep 2

        TOTAL_TIME=0
        for i in $(seq 1 $ITERATIONS); do
            echo "--- Itération $i/$ITERATIONS ---"

            echo "[INFO] Injection de panne sur $SERVICE"
            sudo chaosd attack file delete --dir-name "$VOLUME"
            sleep 2

            START_TIME=$(date +%s)
            sudo ./Restoration.sh "$SNAP_NAME" "$SERVICE"
            END_TIME=$(date +%s)

            DELTA=$((END_TIME - START_TIME))
            TOTAL_TIME=$((TOTAL_TIME + DELTA))

            echo "[INFO] Récupération en $DELTA s"
            sleep 2
        done

        MTTR=$(echo "scale=2; $TOTAL_TIME / $ITERATIONS" | bc)
        echo "$SERVICE,$SIZE,$MTTR" >> "$RESULT_FILE"
        echo "MTTR($SERVICE,$SIZE MB) = $MTTR s"

    done
done
