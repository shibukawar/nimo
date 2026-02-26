#!/bin/bash

# Scheduled run script for grain_boundary benchmarks
# Scheduled to run at 2026-02-08 04:00

TARGET_TIME="2026-02-08 04:00:00"
SCRIPT_PATH="/Users/shibukawar/workspace/nimo-fork/multi_batch_experiments_grain_boundary/run_benchmarks.sh"
LOG_PATH="/Users/shibukawar/workspace/nimo-fork/multi_batch_experiments_grain_boundary/benchmark_log.txt"

echo "Scheduling grain_boundary benchmark to run at $TARGET_TIME"

# Calculate seconds until target time
current_epoch=$(date +%s)
target_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TARGET_TIME" +%s)
sleep_seconds=$((target_epoch - current_epoch))

if [ $sleep_seconds -le 0 ]; then
    echo "Target time has already passed. Running immediately..."
    sleep_seconds=0
else
    echo "Waiting $sleep_seconds seconds ($(($sleep_seconds / 3600)) hours $(($sleep_seconds % 3600 / 60)) minutes) until $TARGET_TIME"
fi

# Sleep until target time
sleep $sleep_seconds

echo "Starting benchmark at $(date)"
bash "$SCRIPT_PATH" 2>&1 | tee "$LOG_PATH"
echo "Benchmark completed at $(date)"
