#!/bin/bash

# Benchmark runner script for melting temperature experiments
# Runs NTS (conservative) and PHYSBO methods
# with varying batch sizes and multiple trials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
source "../.venv/bin/activate"

# nimo パッケージをインポートできるよう、ワークスペースルートを PYTHONPATH に追加
export PYTHONPATH="${SCRIPT_DIR}/..:${PYTHONPATH}"

# Configuration
NTS_BATCH_SIZES=(3 5 15)
PHYSBO_BATCH_SIZES=(1)
TRIALS=(1 2 3 4 5)
NTS_MODES=("conservative")
# PHYSBO は逐次実行（乱数の再現性とファイル競合を避けるため）
MAX_PARALLEL_NTS=1
KERNEL="nimo-venv"

# Template files
NTS_TEMPLATE="nts_settings.tmpl.yaml"
PHYSBO_TEMPLATE="physbo_settings.tmpl.yaml"
SEARCH_SPACE_TEMPLATE="mp_search_space.tmpl.csv"

# Notebook files
NTS_NOTEBOOK="mp_nimo_main_functions_nts.ipynb"
PHYSBO_NOTEBOOK="mp_nimo_main_functions_physbo.ipynb"

# Create output directory for configs
CONFIG_DIR="./configs"
mkdir -p "$CONFIG_DIR"
mkdir -p "./figures"

# Function to wait for a job slot
wait_for_slot() {
    local max_jobs=$1
    local running_jobs
    running_jobs=$(jobs -r | wc -l | tr -d ' ')
    while [ "$running_jobs" -ge "$max_jobs" ]; do
        wait -n 2>/dev/null || true
        running_jobs=$(jobs -r | wc -l | tr -d ' ')
    done
}

echo "=========================================="
echo "Starting Melting Temperature Benchmark Experiments"
echo "NTS Batch sizes: ${NTS_BATCH_SIZES[*]}"
echo "NTS Modes: ${NTS_MODES[*]}"
echo "PHYSBO Batch sizes: ${PHYSBO_BATCH_SIZES[*]}"
echo "Trials per config: ${#TRIALS[@]}"
echo "Max parallel NTS jobs: $MAX_PARALLEL_NTS"
echo "PHYSBO: sequential execution"
echo "=========================================="

# Function to run a single experiment
run_experiment() {
    local method=$1
    local batch_size=$2
    local trial=$3
    local nts_mode=$4  # Only used for NTS

    local config_file
    local notebook
    local output_dir
    local output_notebook
    local search_space_file

    if [ "$method" == "nts" ]; then
        config_file="${CONFIG_DIR}/nts_${nts_mode}_batch${batch_size}_trial${trial}.yaml"
        notebook="$NTS_NOTEBOOK"
        output_dir="./data_${nts_mode}_batch${batch_size}_trial${trial}"
        output_notebook="${output_dir}/executed_notebook.ipynb"
        search_space_file="${output_dir}/mp_search_space_${nts_mode}_batch${batch_size}_trial${trial}.csv"

        if [ -d "$output_dir" ]; then
            echo "Skipping: $output_dir already exists"
            return 0
        fi

        export BATCH_SIZE="$batch_size"
        export TRIAL="$trial"
        export NTS_MODE="$nts_mode"
        envsubst '${BATCH_SIZE} ${TRIAL} ${NTS_MODE}' < "$NTS_TEMPLATE" > "$config_file"

    elif [ "$method" == "physbo" ]; then
        config_file="${CONFIG_DIR}/physbo_batch${batch_size}_trial${trial}.yaml"
        notebook="$PHYSBO_NOTEBOOK"
        output_dir="./data_physbo_batch${batch_size}_trial${trial}"
        output_notebook="${output_dir}/executed_notebook.ipynb"
        search_space_file="${output_dir}/mp_search_space_physbo_batch${batch_size}_trial${trial}.csv"

        if [ -d "$output_dir" ]; then
            echo "Skipping: $output_dir already exists"
            return 0
        fi

        export BATCH_SIZE="$batch_size"
        export TRIAL="$trial"
        envsubst '${BATCH_SIZE} ${TRIAL}' < "$PHYSBO_TEMPLATE" > "$config_file"
    fi

    # Create output directory
    mkdir -p "$output_dir"

    # Copy search space template
    cp "$SEARCH_SPACE_TEMPLATE" "$search_space_file"

    echo "[$(date '+%H:%M:%S')] START: method=$method, batch=$batch_size, trial=$trial${nts_mode:+, mode=$nts_mode}"
    echo "  Config: $config_file"
    echo "  Output: $output_notebook"

    # Run papermill from within the output directory to isolate file writes
    (
        # cd "$output_dir"
        papermill "${SCRIPT_DIR}/${notebook}" "${output_notebook}" \
            -p config_file "${SCRIPT_DIR}/${config_file}" \
            -k "$KERNEL"
    )

    echo "[$(date '+%H:%M:%S')] DONE:  method=$method, batch=$batch_size, trial=$trial${nts_mode:+, mode=$nts_mode}"
}

# Count total experiments
total_experiments=0
for batch_size in "${NTS_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        for nts_mode in "${NTS_MODES[@]}"; do
            ((total_experiments++))
        done
    done
done
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        ((total_experiments++))
    done
done
echo "Total experiments to run: $total_experiments"
echo ""

submitted=0

# ============================================================
# PHYSBO experiments - 逐次実行
# random.randint がグローバル状態に依存するため、
# 並列実行すると各trialで同じseedが生成されるバグを回避
# ============================================================
echo "--- PHYSBO experiments (sequential) ---"
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        ((submitted++))
        echo "[$submitted / $total_experiments]"
        run_experiment "physbo" "$batch_size" "$trial"
    done
done

# ============================================================
# NTS experiments - 並列実行OK
# NTSはsecrets.randbelow等を使うためtrial間の乱数衝突なし
# ============================================================
echo ""
echo "--- NTS experiments (parallel, max $MAX_PARALLEL_NTS) ---"
for batch_size in "${NTS_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        for nts_mode in "${NTS_MODES[@]}"; do
            wait_for_slot "$MAX_PARALLEL_NTS"
            ((submitted++))
            run_experiment "nts" "$batch_size" "$trial" "$nts_mode" &
            echo "Submitted: $submitted / $total_experiments (running: $(jobs -r | wc -l | tr -d ' '))"
        done
    done
done

# Wait for all remaining jobs
echo ""
echo "Waiting for remaining NTS jobs to finish..."
wait

echo ""
echo "=========================================="
echo "All experiments completed!"
echo "=========================================="

# Summary
echo ""
echo "Results summary:"
echo "----------------"
echo ""
echo "NTS experiments:"
for batch_size in "${NTS_BATCH_SIZES[@]}"; do
    for nts_mode in "${NTS_MODES[@]}"; do
        count=$(ls -d data_${nts_mode}_batch${batch_size}_trial* 2>/dev/null | wc -l | tr -d ' ')
        echo "  NTS ($nts_mode) batch=$batch_size: $count / ${#TRIALS[@]} completed"
    done
done
echo ""
echo "PHYSBO experiments:"
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    count=$(ls -d data_physbo_batch${batch_size}_trial* 2>/dev/null | wc -l | tr -d ' ')
    echo "  PHYSBO batch=$batch_size: $count / ${#TRIALS[@]} completed"
done