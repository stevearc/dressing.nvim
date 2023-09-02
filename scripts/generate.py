#!/usr/bin/env python
import os
import os.path
import re

from nvim_doc_tools import indent, read_section, replace_section

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, os.path.pardir))
README = os.path.join(ROOT, "README.md")
DOC = os.path.join(ROOT, "doc", "dressing.txt")
CONFIG = os.path.join(ROOT, "lua", "dressing", "config.lua")


def main() -> None:
    """Update the README"""
    opt_lines = read_section(CONFIG, r"^\s*local default_config =", r"^}$")
    replace_section(README, r"^require\(\"dressing\"\)\.setup", r"^}\)$", opt_lines)
    replace_section(
        DOC, r"^\s*require\('dressing'\)\.setup", r"^\s*}\)$", indent(opt_lines, 4)
    )

    get_config_lines = read_section(DOC, r"^dressing.get_config", "^===")
    for i, line in enumerate(get_config_lines):
        if re.match(r"^\s*>lua$", line):
            get_config_lines[i] = "\n```lua\n"
            break
    get_config_lines.append("```\n\n")
    replace_section(
        README,
        r"^## Advanced configuration",
        r"^#",
        ["\n"] + indent(get_config_lines, -4),
    )
