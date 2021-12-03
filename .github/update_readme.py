#!/usr/bin/env python
import os
import os.path
import re
from typing import List

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, os.path.pardir))
README = os.path.join(ROOT, "README.md")
DOC = os.path.join(ROOT, "doc", "dressing.txt")


def indent(lines: List[str], amount: int) -> List[str]:
    ret = []
    for line in lines:
        if amount >= 0:
            ret.append(" " * amount + line)
        else:
            space = re.match(r"[ \t]+", line)
            if space:
                ret.append(line[min(abs(amount), space.span()[1]) :])
            else:
                ret.append(line)
    return ret


def replace_section(file: str, start_pat: str, end_pat: str, lines: List[str]) -> None:
    prefix_lines: List[str] = []
    postfix_lines: List[str] = []
    file_lines = prefix_lines
    found_section = False
    with open(file, "r", encoding="utf-8") as ifile:
        inside_section = False
        for line in ifile:
            if inside_section:
                if re.match(end_pat, line):
                    inside_section = False
                    file_lines = postfix_lines
                    file_lines.append(line)
            else:
                if not found_section and re.match(start_pat, line):
                    inside_section = True
                    found_section = True
                file_lines.append(line)

    if inside_section or not found_section:
        raise Exception(f"could not find file section {start_pat}")

    all_lines = prefix_lines + lines + postfix_lines
    with open(file, "w", encoding="utf-8") as ofile:
        ofile.write("".join(all_lines))


def read_section(filename: str, start_pat: str, end_pat: str) -> List[str]:
    lines = []
    with open(filename, "r", encoding="utf-8") as ifile:
        inside_section = False
        for line in ifile:
            if inside_section:
                if re.match(end_pat, line):
                    break
                lines.append(line)
            elif re.match(start_pat, line):
                inside_section = True
    return lines


def main() -> None:
    """Update the README"""
    config_file = os.path.join(ROOT, "lua", "dressing", "config.lua")
    opt_lines = read_section(config_file, r"^\s*local default_config =", r"^}$")
    replace_section(README, r"^require\('dressing'\)\.setup", r"^}\)$", opt_lines)
    replace_section(
        DOC, r"^\s*require\('dressing'\)\.setup", r"^\s*}\)$", indent(opt_lines, 4)
    )

    get_config_lines = read_section(DOC, r"^dressing.get_config", "^===")
    for i, line in enumerate(get_config_lines):
        if re.match(r"^\s*>$", line):
            get_config_lines[i] = "```lua\n"
            break
    get_config_lines.append("```\n")
    replace_section(
        README, r"^## Advanced configuration", r"^#", indent(get_config_lines, -4)
    )


if __name__ == "__main__":
    main()
