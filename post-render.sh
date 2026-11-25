#!/bin/bash
cp docs/*md README.md 2>/dev/null || true

while IFS= read -r out_file; do
    case "$out_file" in
        *MS_FML.docx)
            python3 scripts/fix_docx.py "$out_file"
            ;;
        *Supplementary_Material.docx|*Cover_Letter.docx)
            python3 scripts/fix_docx.py --no-line-numbers "$out_file"
            ;;
    esac
done <<< "${QUARTO_PROJECT_OUTPUT_FILES:-}"
