#!/usr/bin/env python3

"""Create webapps using Linux Mint's Webapp Manager, but with a CLI.
Source at https://github.com/luphord/computebox
"""

import argparse
from pathlib import Path
import sys
sys.path.append("/usr/lib/webapp-manager")
from common import WebAppManager

parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter
)
parser.add_argument(
    "--version", help="Print version number", default=False, action="store_true"
)
parser.add_argument("url", help="Full URL to webapp")
parser.add_argument(
    "-n",
    "--name",
    help="Name for the webapp to be used in menu",
    type=str,
    default="Web App from CLI",
)
parser.add_argument(
    "-i",
    "--icon",
    help="Path to icon file",
    type=Path,
    default=Path("/usr/share/icons/hicolor/scalable/apps/webapp-manager.svg"),
)
parser.add_argument(
    "-c",
    "--category",
    help="Category to add this webapp to (multiple allow)",
    type=str,
    nargs="*",
    default="Web",
)
parser.add_argument(
    "-b",
    "--browser",
    help="Browser to use (will be name-matched from list of supported browsers)",
    type=str,
    default="Firefox",
)
parser.add_argument(
    "-p",
    "--custom-parameters",
    help="Custom parameters to pass to browser",
    type=str,
    default="",
)
parser.add_argument(
    "--isolate-profile",
    help="Isolate browser profile",
    default=True,
    action="store_true",
)
parser.add_argument(
    "--navbar",
    help="Show navbar",
    default=False,
    action="store_true",
)
parser.add_argument(
    "--private",
    help="Use private/incognito mode",
    default=False,
    action="store_true",
)


if __name__ == "__main__":
    args = parser.parse_args()
    manager = WebAppManager()
    browser = None
    for supported_browser in manager.get_supported_browsers():
        if supported_browser.name.lower() == args.browser.lower():
            browser = supported_browser
            break
    if not browser:
        supported = ", ".join(f"'{b.name}'" for b in manager.get_supported_browsers())
        raise ValueError(
            f"Could not find browser matching '{args.browser}'; "
            f"supported browsers are {supported}")
    manager.create_webapp(
        args.name,
        args.url,
        str(args.icon),
        ";".join(args.category),
        browser,
        args.custom_parameters,
        args.isolate_profile,
        args.navbar,
        args.private
    )