#!/usr/bin/env python3
"""Post-process Quarto/Pandoc-generated DOCX files for clean Word & LibreOffice Writer layout.

Fixes:
1. Unwraps Quarto's 1x1 figure wrapper <w:tbl> tables into normal centered figure + caption <w:p>
   paragraphs (leaving real data tables intact), preventing grey table borders around figures.
2. Moves body-level <w:bookmarkStart>/<w:bookmarkEnd> tags inside paragraphs so LibreOffice Writer's
   docx importer never wraps paragraphs preceding tables inside grey frames without line numbers.
3. Removes stray empty or non-breaking-space-only (\u00a0) paragraphs.
4. Clamps oversized image extents proportionally (max 6.20 in wide x 6.50 in tall) so every figure
   and its caption fit together on a single A4 page without colliding with the footer.
5. Replaces Windows-only Symbol/Wingdings Private Use Area bullets in word/numbering.xml with
   standard Unicode '•' (\u2022) in Liberation Serif.
6. Suppresses line numbers inside data table cells and table caption paragraphs, and optionally
   removes document-wide line numbering (--no-line-numbers, e.g. for Cover Letter & Supplement).
7. Verifies that every referenced paragraph, character, and table style exists in word/styles.xml.
"""

import argparse
import re
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
WP = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
A = "http://schemas.openxmlformats.org/drawingml/2006/main"
PIC = "http://schemas.openxmlformats.org/drawingml/2006/picture"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

EMU_PER_INCH = 914400
MAX_WIDTH_EMU = int(6.20 * EMU_PER_INCH)
MAX_HEIGHT_EMU = int(6.50 * EMU_PER_INCH)

for prefix, uri in [
    ("w", W),
    ("wp", WP),
    ("a", A),
    ("pic", PIC),
    ("r", R),
]:
    ET.register_namespace(prefix, uri)


def ensure_pPr(p_el):
    pPr = p_el.find(f"{{{W}}}pPr")
    if pPr is None:
        pPr = ET.Element(f"{{{W}}}pPr")
        p_el.insert(0, pPr)
    return pPr


def set_w_child(parent, tag, attrib=None):
    el = parent.find(f"{{{W}}}{tag}")
    if el is None:
        el = ET.SubElement(parent, f"{{{W}}}{tag}")
    el.attrib.clear()
    for k, v in (attrib or {}).items():
        el.set(f"{{{W}}}{k}", v)
    return el


def para_text(p_el):
    return "".join(p_el.itertext())


def is_figure_wrapper_table(tbl_el):
    """Quarto wraps cross-referenced figures in a <w:tbl> containing <w:drawing>."""
    return tbl_el.find(f".//{{{W}}}drawing") is not None


def clamp_drawings(root):
    clamped = 0
    for drawing in root.findall(f".//{{{W}}}drawing"):
        extent = drawing.find(f".//{{{WP}}}extent")
        if extent is None:
            continue
        cx = int(extent.get("cx", "0"))
        cy = int(extent.get("cy", "0"))
        if cx <= 0 or cy <= 0:
            continue
        scale = min(1.0, MAX_WIDTH_EMU / cx, MAX_HEIGHT_EMU / cy)
        if scale < 0.999:
            new_cx = int(round(cx * scale))
            new_cy = int(round(cy * scale))
            extent.set("cx", str(new_cx))
            extent.set("cy", str(new_cy))
            for a_ext in drawing.findall(f".//{{{PIC}}}spPr/{{{A}}}xfrm/{{{A}}}ext"):
                a_ext.set("cx", str(new_cx))
                a_ext.set("cy", str(new_cy))
            clamped += 1
    return clamped


def clean_docx(path: Path, no_line_numbers: bool = False):
    with zipfile.ZipFile(path, "r") as zin:
        entries = {name: zin.read(name) for name in zin.namelist()}

    doc_root = ET.fromstring(entries["word/document.xml"])
    body = doc_root.find(f"{{{W}}}body")

    # Pass 1: Unwrap Quarto 1x1 figure wrapper tables into normal <w:p> elements
    new_children = []
    unwrapped_figs = 0
    for child in list(body):
        if child.tag == f"{{{W}}}tbl" and is_figure_wrapper_table(child):
            unwrapped_figs += 1
            pending_bms = []
            extracted_ps = []
            for elem in child.iter():
                if elem.tag in (f"{{{W}}}bookmarkStart", f"{{{W}}}bookmarkEnd"):
                    # Keep track if directly inside tbl/tr/tc rather than already inside a <w:p>
                    pass
            # Walk rows and cells cleanly
            for tc in child.findall(f".//{{{W}}}tc"):
                for sub in list(tc):
                    if sub.tag in (f"{{{W}}}bookmarkStart", f"{{{W}}}bookmarkEnd"):
                        pending_bms.append(sub)
                    elif sub.tag == f"{{{W}}}p":
                        extracted_ps.append(sub)

            img_ps = [p for p in extracted_ps if p.find(f".//{{{W}}}drawing") is not None]
            cap_ps = [
                p for p in extracted_ps
                if p.find(f".//{{{W}}}drawing") is None and para_text(p).strip() != ""
            ]

            for p in img_ps:
                pPr = ensure_pPr(p)
                set_w_child(pPr, "pStyle", {"val": "CaptionedFigure"})
                set_w_child(pPr, "keepNext")
                set_w_child(pPr, "suppressLineNumbers")
                set_w_child(pPr, "jc", {"val": "center"})
                new_children.append(p)

            target_bm_p = cap_ps[0] if cap_ps else (img_ps[0] if img_ps else None)
            if target_bm_p is not None and pending_bms:
                insert_idx = 1 if target_bm_p.find(f"{{{W}}}pPr") is not None else 0
                for bm in pending_bms:
                    if bm.tag == f"{{{W}}}bookmarkStart":
                        target_bm_p.insert(insert_idx, bm)
                        insert_idx += 1
                    else:
                        target_bm_p.append(bm)

            for p in cap_ps:
                pPr = ensure_pPr(p)
                set_w_child(pPr, "pStyle", {"val": "ImageCaption"})
                set_w_child(pPr, "suppressLineNumbers")
                new_children.append(p)
        else:
            new_children.append(child)

    body[:] = new_children

    # Pass 2: Move body-level <w:bookmarkStart> into the next <w:p> and close it at end of that <w:p>
    # (prevents LibreOffice Writer from framing paragraphs before tables)
    pending_starts = []
    moved_bm_ids = set()
    cleaned_children = []
    for child in list(body):
        if child.tag == f"{{{W}}}bookmarkStart":
            pending_starts.append(child)
            moved_bm_ids.add(child.get(f"{{{W}}}id"))
        elif child.tag == f"{{{W}}}bookmarkEnd":
            # Drop body-level bookmarkEnd; moved starts are closed inside their target <w:p>
            continue
        elif child.tag == f"{{{W}}}p":
            txt = para_text(child)
            has_drawing = child.find(f".//{{{W}}}drawing") is not None
            # Drop empty or non-breaking-space-only paragraphs unless they hold a drawing
            if not has_drawing and txt.replace("\xa0", "").strip() == "":
                continue
            if pending_starts:
                insert_idx = 1 if child.find(f"{{{W}}}pPr") is not None else 0
                for bms in pending_starts:
                    bm_id = bms.get(f"{{{W}}}id")
                    child.insert(insert_idx, bms)
                    insert_idx += 1
                    bme = ET.Element(f"{{{W}}}bookmarkEnd", {f"{{{W}}}id": bm_id})
                    child.append(bme)
                pending_starts.clear()

            # Style explicit "Table X." caption paragraphs so they stay with the table & skip line numbers
            stripped = txt.strip()
            if re.match(r"^Table\s+(S?\d+)[\.:]", stripped):
                pPr = ensure_pPr(child)
                set_w_child(pPr, "pStyle", {"val": "TableCaption"})
                set_w_child(pPr, "keepNext")
                set_w_child(pPr, "suppressLineNumbers")

            # Ensure any inline standalone figure paragraph also suppresses line numbers
            if has_drawing:
                pPr = ensure_pPr(child)
                set_w_child(pPr, "suppressLineNumbers")

            cleaned_children.append(child)
        elif child.tag == f"{{{W}}}tbl":
            # Real data table: suppress line numbers on all cell paragraphs
            for cell_p in child.findall(f".//{{{W}}}p"):
                pPr = ensure_pPr(cell_p)
                set_w_child(pPr, "suppressLineNumbers")
            cleaned_children.append(child)
        else:
            cleaned_children.append(child)

    body[:] = cleaned_children

    # Also remove any orphaned bookmarkEnd inside paragraphs whose bookmarkStart was dropped/moved
    all_starts = {el.get(f"{{{W}}}id") for el in body.findall(f".//{{{W}}}bookmarkStart")}
    for parent in body.iter():
        for sub in list(parent):
            if sub.tag == f"{{{W}}}bookmarkEnd" and sub.get(f"{{{W}}}id") not in all_starts:
                parent.remove(sub)

    # Pass 3: Clamp oversized figure dimensions proportionally
    clamped_count = clamp_drawings(body)

    # Pass 4: Optionally disable line numbers (e.g., Cover Letter & Supplementary Data)
    sectPr = body.find(f"{{{W}}}sectPr")
    if sectPr is not None and no_line_numbers:
        for ln in list(sectPr.findall(f"{{{W}}}lnNumType")):
            sectPr.remove(ln)

    entries["word/document.xml"] = ET.tostring(doc_root, encoding="utf-8", xml_declaration=True)

    # Pass 5: Clean word/numbering.xml bullets generated by Pandoc (replace Symbol/Wingdings PUA)
    if "word/numbering.xml" in entries:
        num_root = ET.fromstring(entries["word/numbering.xml"])
        for lvl in num_root.findall(f".//{{{W}}}lvl"):
            numFmt = lvl.find(f"{{{W}}}numFmt")
            if numFmt is not None and numFmt.get(f"{{{W}}}val") == "bullet":
                lvlText = lvl.find(f"{{{W}}}lvlText")
                if lvlText is not None:
                    lvlText.set(f"{{{W}}}val", "\u2022")
                rPr = lvl.find(f"{{{W}}}rPr")
                if rPr is None:
                    rPr = ET.SubElement(lvl, f"{{{W}}}rPr")
                for rf in list(rPr.findall(f"{{{W}}}rFonts")):
                    rPr.remove(rf)
                rf = ET.SubElement(rPr, f"{{{W}}}rFonts")
                rf.set(f"{{{W}}}ascii", "Liberation Serif")
                rf.set(f"{{{W}}}hAnsi", "Liberation Serif")
                rf.set(f"{{{W}}}cs", "Liberation Serif")
        entries["word/numbering.xml"] = ET.tostring(num_root, encoding="utf-8", xml_declaration=True)

    # Pass 6: Verify all referenced styles exist in word/styles.xml
    styles_root = ET.fromstring(entries["word/styles.xml"])
    defined_styles = {
        s.get(f"{{{W}}}styleId") for s in styles_root.findall(f"{{{W}}}style")
    }
    referenced_styles = set()
    for tag in ("pStyle", "rStyle", "tblStyle"):
        for el in doc_root.findall(f".//{{{W}}}{tag}"):
            val = el.get(f"{{{W}}}val")
            if val:
                referenced_styles.add(val)
    missing = referenced_styles - defined_styles
    if missing:
        raise RuntimeError(f"{path}: Missing style definitions in styles.xml: {sorted(missing)}")

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zout:
        for name, data in entries.items():
            zout.writestr(name, data)

    print(
        f"Cleaned {path}: unwrapped_figs={unwrapped_figs}, clamped_drawings={clamped_count}, "
        f"verified_styles={len(referenced_styles)} (0 missing)"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("docx", nargs="+", type=Path)
    parser.add_argument("--no-line-numbers", action="store_true")
    args = parser.parse_args()
    for p in args.docx:
        clean_docx(p, no_line_numbers=args.no_line_numbers)


if __name__ == "__main__":
    main()

