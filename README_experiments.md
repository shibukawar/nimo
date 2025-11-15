# Experiments Reproduction Guide

This document describes how to reproduce the results used in "Collecting diverse near-optimal samples via nested Thompson sampling".

## Overview

The experiments consist of two main directories:
- `experiments_grain_boundary/`: Grain boundary experiments with descriptor optimization
- `experiments_melting_temperature/`: Melting point prediction experiments

## Reproduction Steps

### Step 1: Copy Template Files

In each experiment directory, copy the template CSV files (`*.tmpl.csv`) to create numbered versions (`*_1.csv` to `*_5.csv`).

#### For Grain Boundary Experiments:
```bash
cd experiments_grain_boundary/
# NTS variants
for i in {1..5}; do cp descriptor_search_space.tmpl.csv descriptor_search_space_nts_aggressive_${i}.csv; done
for i in {1..5}; do cp descriptor_search_space.tmpl.csv descriptor_search_space_nts_conservative_${i}.csv; done
for i in {1..5}; do cp descriptor_search_space.tmpl.csv descriptor_search_space_nts_moderate_${i}.csv; done
# Baselines
for i in {1..5}; do cp descriptor_search_space.tmpl.csv descriptor_search_space_physbo_${i}.csv; done
for i in {1..5}; do cp descriptor_search_space.tmpl.csv descriptor_search_space_random_${i}.csv; done
```

#### For Melting Temperature Experiments:
```bash
cd experiments_melting_temperature/
# NTS variants
for i in {1..5}; do cp mp_search_space.tmpl.csv mp_search_space_nts_aggressive_${i}.csv; done
for i in {1..5}; do cp mp_search_space.tmpl.csv mp_search_space_nts_conservative_${i}.csv; done
for i in {1..5}; do cp mp_search_space.tmpl.csv mp_search_space_nts_moderate_${i}.csv; done
# Baselines
for i in {1..5}; do cp mp_search_space.tmpl.csv mp_search_space_physbo_${i}.csv; done
for i in {1..5}; do cp mp_search_space.tmpl.csv mp_search_space_random_${i}.csv; done
```

### Step 2: Create Output Directories

Create `figures` subdirectory under each experiments directory if it doesn't already exist:

```bash
mkdir -p experiments_grain_boundary/figures
mkdir -p experiments_melting_temperature/figures
```

### Step 3: Run Individual Experiment Notebooks

Run each numbered notebook which refers to the CSV file with the same suffix number. Each notebook will create `objective_by_iter.pkl` and `sample_by_iter.pkl` files under its own output directory.

#### For Grain Boundary Experiments:

**NTS (Nested Thompson Sampling) variants:**
- `descriptor_nimo_main_functions_nts_aggressive_1.ipynb` through `_5.ipynb`
- `descriptor_nimo_main_functions_nts_conservative_1.ipynb` through `_5.ipynb`
- `descriptor_nimo_main_functions_nts_moderate_1.ipynb` through `_5.ipynb`

**PHYSBO baseline:**
- `descriptor_nimo_main_functions_physbo_1.ipynb` through `_5.ipynb`

**Random baseline:**
- `descriptor_nimo_main_functions_random_1.ipynb` through `_5.ipynb`

#### For Melting Temperature Experiments:

**NTS (Nested Thompson Sampling) variants:**
- `mp_nimo_main_functions_nts_aggressive_1.ipynb` through `_5.ipynb`
- `mp_nimo_main_functions_nts_conservative_1.ipynb` through `_5.ipynb`
- `mp_nimo_main_functions_nts_moderate_1.ipynb` through `_5.ipynb`

**PHYSBO baseline:**
- `mp_nimo_main_functions_physbo_1.ipynb` through `_5.ipynb`

**Random baseline:**
- `mp_nimo_main_functions_random_1.ipynb` through `_5.ipynb`

**Expected Output:**
Each notebook execution will create:
- `objective_by_iter.pkl`: Objective function values by iteration
- `sample_by_iter.pkl`: Sample points by iteration

These files are saved in the corresponding `data_*` directories (e.g., `data_aggressive_1/`, `data_physbo_1/`, etc.).

### Step 4: Generate Comparison Figures

Run the comparison notebooks to generate analysis figures:

#### For Grain Boundary Experiments:
```bash
cd experiments_grain_boundary/
# Run circles_comparison.ipynb
```

#### For Melting Temperature Experiments:
```bash
cd experiments_melting_temperature/
# Run circles_comparison.ipynb
```

The `circles_comparison.ipynb` notebooks will analyze the results from all methods and generate comparison figures in the `figures/` directory.

## File Organization

After running all experiments, the directory structure will include:

```
experiments_grain_boundary/
├── figures/                    # Generated comparison figures
├── data_aggressive_1/ to _5/   # NTS aggressive results
├── data_conservative_1/ to _5/ # NTS conservative results
├── data_moderate_1/ to _5/     # NTS moderate results
├── data_physbo_1/ to _5/       # PHYSBO baseline results
├── data_random_1/ to _5/       # Random baseline results
└── circles_comparison.ipynb    # Analysis notebook

experiments_melting_temperature/
├── figures/                    # Generated comparison figures
├── data_aggressive_1/ to _5/   # NTS aggressive results
├── data_conservative_1/ to _5/ # NTS conservative results
├── data_moderate_1/ to _5/     # NTS moderate results
├── data_physbo_1/ to _5/       # PHYSBO baseline results
├── data_random_1/ to _5/       # Random baseline results
└── circles_comparison.ipynb    # Analysis notebook
```

## Notes

- Each experiment is run 5 times (numbered 1-5) to collect statistical data
- The NTS method has three variants: aggressive, conservative, and moderate
- PHYSBO and random methods serve as baselines for comparison
- The `circles_comparison.ipynb` notebooks generate the final comparison figures used in the paper
