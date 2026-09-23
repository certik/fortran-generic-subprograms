#!/usr/bin/env python3
"""Placeholder-aware image launcher used only by runner_selftest.py."""

import argparse
import os
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--images", type=int, required=True)
    parser.add_argument("--exe", required=True)
    args = parser.parse_args()
    if args.images < 1:
        return 125
    status = 0
    image_numbers = list(range(1, args.images + 1))
    first_image_text = os.environ.get("FAKE_LAUNCH_SELECTED_IMAGE")
    if first_image_text is not None:
        first_image = int(first_image_text)
        if first_image not in image_numbers:
            return 124
        image_numbers.remove(first_image)
        image_numbers.insert(0, first_image)
    if os.environ.get("FAKE_LAUNCH_ONCE") == "1":
        image_numbers = image_numbers[:1]
    for image in image_numbers:
        environment = os.environ.copy()
        environment["FAKE_THIS_IMAGE"] = str(image)
        environment["FAKE_NUM_IMAGES"] = str(args.images)
        completed = subprocess.run(
            [args.exe],
            check=False,
            env=environment,
        )
        if status == 0 and completed.returncode != 0:
            status = completed.returncode
        if (
            completed.returncode != 0
            and os.environ.get("FAKE_CONTINUE_AFTER_NONZERO") != "1"
        ):
            break
    return status


if __name__ == "__main__":
    sys.exit(main())
