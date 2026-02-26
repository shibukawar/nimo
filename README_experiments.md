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

---

## Batch Benchmarking Reproduction

This section describes how to reproduce the **multi-batch** experiments using the `run_benchmarks.sh` scripts located in `multi_batch_experiments_grain_boundary/` and `multi_batch_experiments_melting_temperature/`.

### Overview

| Directory | Methods | NTS Batch Sizes | PHYSBO Batch Sizes | Trials |
|---|---|---|---|---|
| `multi_batch_experiments_grain_boundary/` | NTS (conservative), PHYSBO | 12, 24, 48 | 1 | 5 |
| `multi_batch_experiments_melting_temperature/` | NTS (conservative), PHYSBO | 3, 5, 15 | 1 | 5 |

Each script uses [papermill](https://papermill.readthedocs.io/) to execute parameterized notebooks and outputs results into per-run directories.

### Prerequisites

#### 1. Create the virtual environment (Python 3.12.7)

```bash
cd /path/to/nimo-fork

# Create .venv with Python 3.12.7
# If pyenv is available:
pyenv local 3.12.7
python -m venv .venv

# Or specify the interpreter explicitly:
# /path/to/python3.12 -m venv .venv

source .venv/bin/activate
```

#### 2. Install the nimo package and all dependencies

```bash
# Install nimo in editable mode (installs core dependencies declared in pyproject.toml)
pip install -e .

# Install the full set of pinned experiment dependencies
pip install -r requirements.txt
```

The `requirements.txt` at the repository root was generated with `pip freeze` and pins every package (including `papermill`, `ipykernel`, `physbo`, `scikit-learn`, `scipy`, etc.) to the exact versions used in the experiments.

#### 3. Register the virtual environment as a Jupyter kernel

```bash
python -m ipykernel install --user --name nimo-venv --display-name "nimo-venv"
```

This kernel name (`nimo-venv`) is what the `run_benchmarks.sh` scripts pass to `papermill -k nimo-venv`.

### Running the Grain Boundary Batch Experiments

```bash
cd multi_batch_experiments_grain_boundary/
bash run_benchmarks.sh
```

The script will:
- Generate YAML config files in `configs/` via `envsubst` from the template files (`nts_settings.tmpl.yaml`, `physbo_settings.tmpl.yaml`)
- Copy `descriptor_search_space.tmpl.csv` to a per-run CSV in the output directory
- Execute notebooks in parallel (up to 5 concurrent jobs) using `papermill`
- Skip any run whose output directory already exists (safe to resume)

**Output directories created:**

```
multi_batch_experiments_grain_boundary/
├── configs/                              # Auto-generated YAML configs
├── data_conservative_batch12_trial1/ to _5/
├── data_conservative_batch24_trial1/ to _5/
├── data_conservative_batch48_trial1/ to _5/
└── data_physbo_batch1_trial1/     to _5/
```

Each output directory contains the executed notebook (`executed_notebook.ipynb`) and result files (`objective_by_iter.pkl`, `sample_by_iter.pkl`).

### Running the Melting Temperature Batch Experiments

```bash
cd multi_batch_experiments_melting_temperature/
bash run_benchmarks.sh
```

The script will:
- Generate YAML config files in `configs/` from the template files
- Copy `mp_search_space.tmpl.csv` to a per-run CSV in the output directory
- Execute NTS notebooks with limited parallelism (sequential by default) and PHYSBO sequentially
- Skip any run whose output directory already exists

**Output directories created:**

```
multi_batch_experiments_melting_temperature/
├── configs/                              # Auto-generated YAML configs
├── data_conservative_batch3_trial1/  to _5/
├── data_conservative_batch5_trial1/  to _5/
├── data_conservative_batch15_trial1/ to _5/
└── data_physbo_batch1_trial1/        to _5/
```

### Generating Comparison Figures

After all runs have completed, generate the comparison figures by running the analysis notebook in each directory:

```bash
# Grain boundary
cd multi_batch_experiments_grain_boundary/
jupyter nbconvert --to notebook --execute circles_comparison.ipynb

# Melting temperature
cd multi_batch_experiments_melting_temperature/
jupyter nbconvert --to notebook --execute circles_comparison.ipynb
```

Figures are saved in the `figures/` subdirectory of each experiment directory.

### Resuming Interrupted Runs

Both scripts check whether the output directory for a given run already exists and skip it if so. To resume after an interruption, simply re-run the script:

```bash
bash run_benchmarks.sh
```

Only the missing runs will be executed.
