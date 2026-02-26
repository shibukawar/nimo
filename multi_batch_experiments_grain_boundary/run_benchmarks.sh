#!/bin/bash

# Benchmark runner script for grain boundary experiments
# Runs NTS (conservative, moderate, aggressive), PHYSBO, and Random methods
# with varying batch sizes and multiple trials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
source "../.venv/bin/activate"

# Configuration
NTS_BATCH_SIZES=(12 24 48)
PHYSBO_BATCH_SIZES=(1)
TRIALS=(1 2 3 4 5)
NTS_MODES=("conservative")
MAX_PARALLEL=5
KERNEL="nimo-venv"

# Template files
NTS_TEMPLATE="nts_settings.tmpl.yaml"
PHYSBO_TEMPLATE="physbo_settings.tmpl.yaml"
RANDOM_TEMPLATE="random_settings.tmpl.yaml"
SEARCH_SPACE_TEMPLATE="descriptor_search_space.tmpl.csv"

# Notebook files
NTS_NOTEBOOK="descriptor_nimo_main_functions_nts.ipynb"
PHYSBO_NOTEBOOK="descriptor_nimo_main_functions_physbo_parameterized.ipynb"
RANDOM_NOTEBOOK="descriptor_nimo_main_functions_random.ipynb"

# Create output directory for configs
CONFIG_DIR="./configs"
mkdir -p "$CONFIG_DIR"

# Job control - use jobs -r to count actual running jobs

# Function to wait for a job slot
wait_for_slot() {
    local running_jobs
    running_jobs=$(jobs -r | wc -l | tr -d ' ')
    while [ "$running_jobs" -ge "$MAX_PARALLEL" ]; do
        # Wait for any background job to finish
        wait -n 2>/dev/null || true
        running_jobs=$(jobs -r | wc -l | tr -d ' ')
    done
}

echo "=========================================="
echo "Starting Grain Boundary Benchmark Experiments"
echo "Batch sizes: ${BATCH_SIZES[*]}"
echo "Trials per batch size: ${#TRIALS[@]}"
echo "Max parallel jobs: $MAX_PARALLEL"
echo "=========================================="

# Function to run a single experiment
run_experiment() {
    local method=$1
    local batch_size=$2
    local trial=$3
    local nts_mode=$4  # Only used for NTS
    
    echo ""
    echo "----------------------------------------"
    echo "Running: method=$method, batch_size=$batch_size, trial=$trial${nts_mode:+, nts_mode=$nts_mode}"
    echo "----------------------------------------"
    
    # Determine config file name and notebook
    local config_file
    local notebook
    local output_notebook
    local search_space_file
    
    if [ "$method" == "nts" ]; then
        config_file="${CONFIG_DIR}/nts_${nts_mode}_batch${batch_size}_trial${trial}.yaml"
        notebook="$NTS_NOTEBOOK"
        output_dir="./data_${nts_mode}_batch${batch_size}_trial${trial}"
        output_notebook="${output_dir}/executed_notebook.ipynb"
        search_space_file="${output_dir}/descriptor_search_space_${nts_mode}_batch${batch_size}_trial${trial}.csv"
        
        # Check if output directory already exists
        if [ -d "$output_dir" ]; then
            echo "Skipping: $output_dir already exists"
            return 0
        fi
        
        # Generate config using envsubst
        export BATCH_SIZE="$batch_size"
        export TRIAL="$trial"
        export NTS_MODE="$nts_mode"
        envsubst '${BATCH_SIZE} ${TRIAL} ${NTS_MODE}' < "$NTS_TEMPLATE" > "$config_file"
    elif [ "$method" == "physbo" ]; then
        config_file="${CONFIG_DIR}/physbo_batch${batch_size}_trial${trial}.yaml"
        notebook="$PHYSBO_NOTEBOOK"
        output_dir="./data_physbo_batch${batch_size}_trial${trial}"
        output_notebook="${output_dir}/executed_notebook.ipynb"
        search_space_file="${output_dir}/descriptor_search_space_physbo_batch${batch_size}_trial${trial}.csv"
        
        # Check if output directory already exists
        if [ -d "$output_dir" ]; then
            echo "Skipping: $output_dir already exists"
            return 0
        fi
        
        # Generate config using envsubst
        export BATCH_SIZE="$batch_size"
        export TRIAL="$trial"
        envsubst '${BATCH_SIZE} ${TRIAL}' < "$PHYSBO_TEMPLATE" > "$config_file"
    elif [ "$method" == "random" ]; then
        config_file="${CONFIG_DIR}/random_batch${batch_size}_trial${trial}.yaml"
        notebook="$RANDOM_NOTEBOOK"
        output_dir="./data_random_batch${batch_size}_trial${trial}"
        output_notebook="${output_dir}/executed_notebook.ipynb"
        search_space_file="${output_dir}/descriptor_search_space_random_batch${batch_size}_trial${trial}.csv"
        
        # Check if output directory already exists
        if [ -d "$output_dir" ]; then
            echo "Skipping: $output_dir already exists"
            return 0
        fi
        
        # Generate config using envsubst
        export BATCH_SIZE="$batch_size"
        export TRIAL="$trial"
        envsubst '${BATCH_SIZE} ${TRIAL}' < "$RANDOM_TEMPLATE" > "$config_file"
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Copy search space template
    cp "$SEARCH_SPACE_TEMPLATE" "$search_space_file"
    
    echo "Config file: $config_file"
    echo "Search space: $search_space_file"
    echo "Output notebook: $output_notebook"
    
    
    # Run papermill with the correct kernel
    papermill "$notebook" "$output_notebook" -p config_file "$config_file" -k "$KERNEL"
    
    echo "Completed: $method (batch_size=$batch_size, trial=$trial)"
}

# Main execution loop
total_experiments=0
completed_experiments=0

# Count total experiments
# NTS experiments
for batch_size in "${NTS_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        for nts_mode in "${NTS_MODES[@]}"; do
            ((total_experiments++))
        done
    done
done
# PHYSBO experiments
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        ((total_experiments++))
    done
done

echo "Total experiments to run: $total_experiments"
echo ""

# Run experiments
submitted=0

# NTS experiments
for batch_size in "${NTS_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        for nts_mode in "${NTS_MODES[@]}"; do
            wait_for_slot
            ((submitted++))
            run_experiment "nts" "$batch_size" "$trial" "$nts_mode" &
            echo "Submitted: $submitted / $total_experiments (running: $(jobs -r | wc -l | tr -d ' '))"
        done
    done
done

# PHYSBO experiments
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    for trial in "${TRIALS[@]}"; do
        wait_for_slot
        ((submitted++))
        run_experiment "physbo" "$batch_size" "$trial" &
        echo "Submitted: $submitted / $total_experiments (running: $(jobs -r | wc -l | tr -d ' '))"
    done
done

# Wait for all remaining jobs
echo ""
echo "Waiting for remaining jobs to finish..."
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
        echo "  NTS ($nts_mode) batch_size=$batch_size: $count completed"
    done
done
echo ""
echo "PHYSBO experiments:"
for batch_size in "${PHYSBO_BATCH_SIZES[@]}"; do
    count=$(ls -d data_physbo_batch${batch_size}_trial* 2>/dev/null | wc -l | tr -d ' ')
    echo "  PHYSBO batch_size=$batch_size: $count completed"
done
