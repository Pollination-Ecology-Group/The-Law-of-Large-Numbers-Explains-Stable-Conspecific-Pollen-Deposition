import re

target_file = "scripts/Analysis_FML_Z.R"

with open(target_file, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith("# ") and "---" in line:
        if not line.startswith("## ----"):
            # Replace all '-' with '=' in visual dividers
            line = line.replace("-", "=")
    new_lines.append(line)

with open(target_file, "w") as f:
    f.writelines(new_lines)

print("Dividers fixed successfully.")
