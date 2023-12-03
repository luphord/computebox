#! /usr/bin/doit -f


def task_update_package_index():
    """Update local package index using apt-get update."""
    return {"actions": ["sudo apt-get update"]}
