#! /usr/bin/env python3

import doit


def task_update_package_index():
    """Update local package index using apt-get update."""
    return {"actions": ["sudo apt-get update"]}


if __name__ == "__main__":
    doit.run(globals())
