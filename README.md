# Indirect Reciprocity Beyond Pairwise Interactions

This repository contains the MATLAB, Maple, and Python code used for the study of indirect reciprocity in multiplayer interactions, including both three-player and four-player settings.

The code is organized around three main components:

- **MATLAB scripts and functions** for generating social norms and behavioral strategies, searching for ESS pairs, analyzing reputation dynamics, checking bistability, and pruning mirror-symmetric ESS pairs.
- **Maple worksheets** for symbolic calculations related to reputation equilibria.
- **Python scripts** for the large language model (LLM) experiments reported in the paper.

## Repository contents

### MATLAB scripts
- `tool_code.m`  
  Main utility script for the **three-player** case.

- `tool_code_n4.m`  
  Main utility script for the **four-player** case.

### Core MATLAB functions
- `get_ESS_linear.m`
- `get_ESS_linear_n4.m`

- `get_rep_equ.m`
- `get_rep_equ_res.m`
- `get_rep_equ_mut.m`
- `get_rep_equ_res_n4.m`
- `get_rep_equ_mut_n4.m`

- `get_rep_dym.m`
- `get_rep_dym_res.m`
- `get_rep_dym_mut.m`
- `get_rep_dym_res_n4.m`
- `get_rep_dym_mut_n4.m`

- `get_mirror_ESSpair.m`
- `get_mirror_ESSpair_n4.m`

- `bistability_check_n4.m`

- `parsave_ESS.m`
- `parsave_bist.m`
- `parsave_rep_equ.m`

- `payoff.m`

### Maple worksheets
- `rep_equ_n3.mw`  
  Symbolic calculations for the three-player case.

- `rep_equ_n4.mw`  
  Symbolic calculations for the four-player case.

### Python scripts for LLM experiments
Located in `llm_experiments/`:

- `Basic_Prompt.py`  
  LLM evaluation under the **basic prompt**.

- `Leading_Eight_Prompt.py`  
  LLM evaluation under the **leading eight prompt**.

- `Moral Info_Prompt.py`  
  LLM evaluation under the **moral information prompt**.

These scripts generate LLM judgments for the three-player indirect reciprocity setting under two action-label conditions:
- **Task 1A**: neutral action labels (`X/Y`)
- **Task 1B**: semantically loaded action labels (`C/D`)

The unused exploratory tasks in the original local code were removed from the public repository version.

## Purpose of the files

### Three-player part
The three-player MATLAB code is used to:
1. generate the full spaces of social norms and behavioral strategies,
2. search for ESS pairs under linear payoff,
3. analyze reputation dynamics and bistability,
4. check and prune mirror-symmetric ESS pairs.

The Maple worksheet `rep_equ_n3.mw` is used for symbolic derivations and checks related to reputation equilibria.

### Four-player part
The four-player MATLAB code is used to:
1. generate the full spaces of social norms and behavioral strategies,
2. search for ESS pairs under linear payoff,
3. sort and prune ESS collections,
4. analyze bistability for selected ESS pairs.

The Maple worksheet `rep_equ_n4.mw` is used for symbolic derivations and checks in the four-player setting.

### LLM experiments
The Python scripts in `llm_experiments/` are used to reproduce the LLM-based moral assessment experiments in the three-player setting.

They implement the prompt formats described in the Supplementary Information and generate structured JSON outputs containing:
- a binary assessment label (`1` for approval, `0` for disapproval),
- a short rationale,
- an indicator of whether numerical information was used in the response.

The scripts are designed for repeated API-based sampling across all combinations of:
- focal-player reputation (`G` or `B`),
- co-player reputation profile (`GG`, `GB`, or `BB`),
- action label condition (`X/Y` or `C/D`).

## Requirements

### MATLAB and Maple
The MATLAB code was written for standard MATLAB workflows and uses:
- symbolic computation (`syms`),
- parallel computation (`parpool`).

Some parts of the code therefore require the corresponding MATLAB toolboxes.

The `.mw` files require Maple to open and run.

### Python
The LLM experiment scripts require Python 3 and the following packages:
- `requests`

They also require access to an LLM API.

The following environment variables should be set before running the scripts:
- `LLM_API_KEY`
- `LLM_BASE_URL`
- `LLM_MODEL`

## Suggested usage

### Three-player case
Open `tool_code.m` and run the relevant sections in order:
1. generate norms and strategies,
2. search for ESS pairs,
3. analyze reputation dynamics,
4. check mirror symmetry and prune ESS collections.

### Four-player case
Open `tool_code_n4.m` and run the relevant sections in order:
1. generate norms and strategies,
2. search for ESS pairs,
3. sort and prune ESS collections,
4. analyze bistability for selected ESS pairs.

### LLM experiments
Run the scripts in `llm_experiments/` separately according to the prompt condition you want to reproduce:
- `Basic_Prompt.py`
- `Leading_Eight_Prompt.py`
- `Moral Info_Prompt.py`

Each script performs repeated API calls for the specified prompt type and saves the outputs in JSON and CSV formats.

## Notes

- The MATLAB scripts are organized as utility scripts with section-based execution.
- The Maple worksheets are intended as supplementary symbolic derivation files rather than as the main automated workflow.
- The Python scripts are cleaned public versions of the original LLM experiment code. Local paths, private keys, and unused exploratory tasks have been removed.
- Intermediate data and result files are not included here unless explicitly generated by the scripts.

## Citation

If you use this code, please cite the corresponding paper.

## Contact

For questions about the code, please contact the authors of the study.
