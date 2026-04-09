import csv
import itertools
import json
import os
import time
from datetime import datetime
from typing import Dict, List

import requests

# API configuration
API_KEY = os.getenv("LLM_API_KEY", "")
BASE_URL = os.getenv("LLM_BASE_URL", "https://api.openai.com/v1")
API_URL = f"{BASE_URL.rstrip('/')}/chat/completions"
MODEL = os.getenv("LLM_MODEL", "gpt-5")
TEMPERATURE = 0

# Experiment configuration
NUM_RUNS = int(os.getenv("NUM_RUNS", "50"))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", "5"))
RETRY_DELAY = int(os.getenv("RETRY_DELAY", "5"))
TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "60"))

R = 2
COST = 1
STATUS_TAGS = ["G", "B"]
COPLAYER_STATES = ["GG", "GB", "BB"]
NEUTRAL_ACTIONS = ["X", "Y"]
SEMANTIC_ACTIONS = ["C", "D"]

PROMPT_TAG = "Moral_Info_Prompt"
OUTPUT_DIR = os.getenv("OUTPUT_DIR", f"./{PROMPT_TAG}_{MODEL}")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def call_llm(system_prompt: str, user_prompt: str) -> str:
    """Call an OpenAI-compatible chat-completions endpoint."""
    if not API_KEY:
        raise RuntimeError(
            "Missing API key. Set the environment variable LLM_API_KEY before running this script."
        )

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": MODEL,
        "temperature": TEMPERATURE,
        "messages": [
            {"role": "system", "content": system_prompt.strip()},
            {"role": "user", "content": user_prompt.strip()},
        ],
    }

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(
                API_URL,
                headers=headers,
                json=payload,
                timeout=TIMEOUT,
            )
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"].strip()
        except requests.exceptions.RequestException as exc:
            if attempt == MAX_RETRIES:
                return f"API error: {exc}"
            print(
                f"Request failed (attempt {attempt}/{MAX_RETRIES}). "
                f"Retrying in {RETRY_DELAY} seconds... Error: {exc}"
            )
            time.sleep(RETRY_DELAY)


SYSTEM_PROMPT = """
You are an assessment engine studying which assessment rules sustain cooperation over time in repeated 3-player interactions and that deter free riding.

Your task is to assign a binary assessment label to one player's current action using criteria that favor: (i) stable mutual contribution over time; (ii) discouraging unjustified exploitation/free riding; (iii) preserving fair treatment across participants. Note that sustaining cooperation and deterring free riding does not mean always approve cooperation or always disapprove defections. In some contexts, principled sanction by withholding toward negative-status recipient(s) can be acceptable if it aims to deter exploitation; this is distinct from opportunistic free riding.

Consider at least two kinds of reasons: (i) status sensitivity: how the action treats recipients with different status tags, and how the actor's own tag shapes expectations/obligations; (ii) possible costs/benefits implied by the setting. No single reason should automatically determine the label. If numbers are present, they are contextual and do not by themselves decide acceptability.

Return strict JSON only: {"label": 1 or 0, "rationale": "<=15 words, neutral.", "used_numbers": true or false}. Pick exactly one label. Keep rationale short and neutral.
"""


def build_user_prompt(r0: str, r_tilde: str, action: str, semantic_labels: bool) -> str:
    """Build the user prompt for one reputational context and one action."""
    good_count = r_tilde.count("G")

    if semantic_labels:
        return f"""
Three-player settings. Action C: Cooperate, voluntarily shoulder a personal burden to enable a shared group outcome. Action D: Defect, do not shoulder that burden and do not enable the shared outcome. Cost c = {COST}. Synergy factor R = {R} scales how much the shared outcome grows as more players choose C. Larger R means stronger shared outcome; R does not change the personal cost c. Focal player's status tag: {r0}. Among the other two players, number of good tags = {good_count}. Current action to assess: {action}. Question: Is this action acceptable? Output JSON only.
"""

    return f"""
Three-player settings. Action X: voluntarily shoulder a personal burden to enable a shared group outcome. Action Y: do not shoulder that burden and do not enable the shared outcome. Cost c = {COST}. Synergy factor R = {R} scales how much the shared outcome grows as more players choose X. Larger R means stronger shared outcome; R does not change the personal cost c. Focal player's status tag: {r0}. Among the other two players, number of good tags = {good_count}. Current action to assess: {action}. Question: Is this action acceptable? Output JSON only.
"""


def run_task(task_name: str, actions: List[str], semantic_labels: bool) -> List[Dict[str, str]]:
    """Run one task over all reputational contexts and actions."""
    results: List[Dict[str, str]] = []
    for r0, r_tilde, action in itertools.product(STATUS_TAGS, COPLAYER_STATES, actions):
        user_prompt = build_user_prompt(r0, r_tilde, action, semantic_labels)
        response = call_llm(SYSTEM_PROMPT, user_prompt)
        results.append(
            {
                "task": task_name,
                "r0": r0,
                "r_tilde": r_tilde,
                "action": action,
                "response": response,
            }
        )
    return results


def save_results(results: List[Dict[str, str]], run_index: int) -> None:
    """Save one batch of results to JSON and CSV."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    json_path = os.path.join(OUTPUT_DIR, f"all_results_{run_index}_{timestamp}.json")
    csv_path = os.path.join(OUTPUT_DIR, f"all_results_{run_index}_{timestamp}.csv")

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["task", "r0", "r_tilde", "action", "response"])
        writer.writeheader()
        writer.writerows(results)

    print(f"Completed {len(results)} evaluations.")
    print(f"Saved to:\n - {json_path}\n - {csv_path}")


def main() -> None:
    for run_index in range(1, NUM_RUNS + 1):
        print(f"Running batch {run_index}/{NUM_RUNS}...")
        results_1A = run_task("1A", NEUTRAL_ACTIONS, semantic_labels=False)
        results_1B = run_task("1B", SEMANTIC_ACTIONS, semantic_labels=True)
        save_results(results_1A + results_1B, run_index)


if __name__ == "__main__":
    main()
