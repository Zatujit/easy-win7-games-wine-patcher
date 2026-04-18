import subprocess
import sys

# Install pe_tools (available as pip package) to make the parser work

def get_reshack_lines(mui_path, name, skip_types=('MUI',)):
    result = subprocess.run(['peresed', '--print-tree', mui_path], capture_output=True, text=True)
    current_type = None
    current_name = None
    lines = []
    for line in result.stdout.splitlines():
        stripped = line.strip()
        if not stripped or stripped == 'resources:':
            continue
        depth = len(line) - len(line.lstrip())
        if depth == 2:
            current_type = stripped
        elif depth == 4:
            current_name = stripped.split(':')[0].strip()
        elif depth == 6:
            if current_type in skip_types:
                continue
            lang = stripped.split(':')[0].strip()

            if current_type == "RT_STRING":
                current_type = "STRINGTABLE"
            elif current_type == "RT_MENU":
                current_type = "MENU"
            elif current_type == "RT_DIALOG":
                current_type = "DIALOG"
            elif current_type == "RT_ACCELERATOR":
                current_type = "ACCELERATORS"
            elif current_type == "RT_VERSION":
                current_type = "VERSIONINFO"

            lines.append(f'-addoverwrite "{name}_resources.res", {current_type},{current_name},{lang}')
    return lines

MUI_FILE=sys.argv[1]
NAME=sys.argv[2]

print('\n'.join(get_reshack_lines(MUI_FILE, NAME)))
