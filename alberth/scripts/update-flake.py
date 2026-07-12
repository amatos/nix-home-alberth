#!/usr/bin/env python3
# update-flake.py — reset nixie's flake-rebuild branch to the tip of origin/main,
# update one flake input (or all of them), and push flake.lock if it changed.
#
# flake-rebuild is intentionally reset (not merged/rebased) from origin/main on
# every run and force-pushed: it is a disposable, single-commit branch, not an
# accumulating history. A future CI workflow triggers on pushes to flake-rebuild
# and merges it into main once checks pass.

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

REPO_DIR = Path.home() / "Projects" / "nixie"
REPO_REMOTE = "git@github.com:amatos/nixie.git"
MAIN_BRANCH = "main"
WORK_BRANCH = "flake-rebuild"


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    print(f"+ {' '.join(args)}")
    return subprocess.run(args, cwd=cwd, check=True)


def current_branch(repo_dir: Path) -> str:
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        cwd=repo_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def has_uncommitted_changes(repo_dir: Path) -> bool:
    # --untracked-files=no matches what `git stash push` (no --include-untracked)
    # actually acts on — including untracked files here would report a stash
    # that was never created, and the later `git stash pop` would fail.
    result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=no"],
        cwd=repo_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    return bool(result.stdout.strip())


def flake_lock_changed(repo_dir: Path) -> bool:
    result = subprocess.run(["git", "diff", "--quiet", "--", "flake.lock"], cwd=repo_dir)
    return result.returncode != 0


def commit_message(flake_input: str | None) -> str:
    return f"chore: update flake.lock\n\nUpdated input: {flake_input or 'all'}"


def update_flake(repo_dir: Path, remote: str, flake_input: str | None) -> None:
    if not repo_dir.exists():
        repo_dir.parent.mkdir(parents=True, exist_ok=True)
        run(["git", "clone", remote, str(repo_dir)], cwd=repo_dir.parent)

    previous_branch = current_branch(repo_dir)
    stashed = has_uncommitted_changes(repo_dir)
    if stashed:
        run(["git", "stash", "push", "-m", "update-flake.py autostash"], cwd=repo_dir)

    try:
        # Fetch every branch, not just main: --force-with-lease below needs a
        # fresh origin/flake-rebuild remote-tracking ref to compare against.
        # (--force-if-includes is not usable here — it additionally requires
        # flake-rebuild's reflog to already contain a transition from the old
        # remote tip, which a fresh clone's brand-new local branch never has.)
        run(["git", "fetch", "origin"], cwd=repo_dir)
        run(["git", "checkout", "-B", WORK_BRANCH, f"origin/{MAIN_BRANCH}"], cwd=repo_dir)

        if flake_input:
            run(["nix", "flake", "lock", "--update-input", flake_input], cwd=repo_dir)
        else:
            run(["nix", "flake", "update"], cwd=repo_dir)

        if not flake_lock_changed(repo_dir):
            print("flake.lock unchanged, nothing to commit")
            return

        run(["git", "add", "flake.lock"], cwd=repo_dir)
        run(["git", "commit", "-S", "-m", commit_message(flake_input)], cwd=repo_dir)
        run(["git", "push", "--force-with-lease", "origin", WORK_BRANCH], cwd=repo_dir)
    finally:
        run(["git", "checkout", previous_branch], cwd=repo_dir)
        if stashed:
            run(["git", "stash", "pop"], cwd=repo_dir)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Reset nixie's flake-rebuild branch to origin/main, update a flake "
            "input (or all inputs), and push flake.lock if it changed."
        ),
    )
    parser.add_argument(
        "flake_input",
        nargs="?",
        default=None,
        help="single flake input to update (default: update all inputs)",
    )
    args = parser.parse_args()

    try:
        update_flake(REPO_DIR, REPO_REMOTE, args.flake_input)
    except subprocess.CalledProcessError as exc:
        print(f"update-flake.py: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
