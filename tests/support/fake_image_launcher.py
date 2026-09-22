#!/usr/bin/env python3
"""Placeholder-aware image launcher used only by runner_selftest.py."""

import argparse
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--images", type=int, required=True)
    parser.add_argument("--exe", required=True)
    args = parser.parse_args()
    if args.images < 1:
        return 125
    completed = subprocess.run([args.exe], check=False)
    return completed.returncode


if __name__ == "__main__":
    sys.exit(main())
