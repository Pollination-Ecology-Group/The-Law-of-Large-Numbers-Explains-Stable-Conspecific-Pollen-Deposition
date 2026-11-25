#!/usr/bin/env python3
"""Build a clean, standards-compliant Pandoc reference DOCX (tech_docs/template.docx)."""

import subprocess
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
CT_NS = "http://schemas.openxmlformats.org/package/2006/content-types"

ET.register_namespace("w", W)
ET.register_namespace("r", R)


def w_el(tag, attrib=None):
    return ET.Element(f"{{{W}}}{tag}", {f"{{{W}}}{k}": v for k, v in (attrib or {}).items()})


def set_sub(parent, tag, attrib=None):
    el = parent.find(f"{{{W}}}{tag}")
    if el is None:
        el = ET.SubElement(parent, f"{{{W}}}{tag}")
    el.attrib.clear()
    for k, v in (attrib or {}).items():
        el.set(f"{{{W}}}{k}", v)
    return el


def remove_sub(parent, tag):
    for el in list(parent.findall(f"{{{W}}}{tag}")):
        parent.remove(el)


def configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=None, italic=None, color="000000"):
    set_sub(rPr, "rFonts", {"ascii": font, "hAnsi": font, "cs": font, "eastAsia": font})
    remove_sub(rPr, "rFonts")  # recreate cleanly without theme attributes
    rf = ET.SubElement(rPr, f"{{{W}}}rFonts")
    rf.set(f"{{{W}}}ascii", font)
    rf.set(f"{{{W}}}hAnsi", font)
    rf.set(f"{{{W}}}cs", font)
    rf.set(f"{{{W}}}eastAsia", font)

    set_sub(rPr, "sz", {"val": size_half_pt})
    set_sub(rPr, "szCs", {"val": size_half_pt})
    if color is not None:
        set_sub(rPr, "color", {"val": color})
    if bold is True:
        set_sub(rPr, "b")
        set_sub(rPr, "bCs")
    elif bold is False:
        remove_sub(rPr, "b")
        remove_sub(rPr, "bCs")
    if italic is True:
        set_sub(rPr, "i")
        set_sub(rPr, "iCs")
    elif italic is False:
        remove_sub(rPr, "i")
        remove_sub(rPr, "iCs")


def main():
    out_path = Path("tech_docs/template.docx")
    with tempfile.NamedTemporaryFile(suffix=".docx", delete=False) as tmp:
        ref_path = Path(tmp.name)

    raw = subprocess.check_output(["quarto", "pandoc", "--print-default-data-file", "reference.docx"])
    ref_path.write_bytes(raw)

    with zipfile.ZipFile(ref_path, "r") as zin:
        entries = {name: zin.read(name) for name in zin.namelist()}
    ref_path.unlink(missing_ok=True)

    # 1. Configure word/styles.xml so every Pandoc style exists with uniform typography
    styles_root = ET.fromstring(entries["word/styles.xml"])

    # Update docDefaults
    doc_defaults = styles_root.find(f"{{{W}}}docDefaults")
    if doc_defaults is not None:
        rPrDefault = doc_defaults.find(f"{{{W}}}rPrDefault")
        if rPrDefault is not None:
            rPr = rPrDefault.find(f"{{{W}}}rPr")
            if rPr is None:
                rPr = ET.SubElement(rPrDefault, f"{{{W}}}rPr")
            configure_font(rPr, font="Liberation Serif", size_half_pt="24", color="000000")
        pPrDefault = doc_defaults.find(f"{{{W}}}pPrDefault")
        if pPrDefault is not None:
            pPr = pPrDefault.find(f"{{{W}}}pPr")
            if pPr is not None:
                remove_sub(pPr, "suppressAutoHyphens")

    styles_by_id = {
        s.get(f"{{{W}}}styleId"): s for s in styles_root.findall(f"{{{W}}}style")
    }

    def get_pPr_rPr(style_el):
        pPr = style_el.find(f"{{{W}}}pPr")
        if pPr is None:
            pPr = ET.SubElement(style_el, f"{{{W}}}pPr")
        rPr = style_el.find(f"{{{W}}}rPr")
        if rPr is None:
            rPr = ET.SubElement(style_el, f"{{{W}}}rPr")
        remove_sub(pPr, "suppressAutoHyphens")
        return pPr, rPr

    # Core body styles: Normal, BodyText, FirstParagraph MUST have 100% identical spacing & font
    for sid in ("Normal", "BodyText", "FirstParagraph"):
        s = styles_by_id[sid]
        pPr, rPr = get_pPr_rPr(s)
        set_sub(pPr, "widowControl")
        set_sub(pPr, "spacing", {"before": "0", "after": "160", "line": "360", "lineRule": "auto"})
        set_sub(pPr, "ind", {"left": "0", "right": "0", "firstLine": "0"})
        set_sub(pPr, "jc", {"val": "both"})
        configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=False, italic=False, color="000000")

    # Compact style (bullet lists: ORCIDs, Abstract bullets, Supplementary Data bullets)
    s = styles_by_id["Compact"]
    pPr, rPr = get_pPr_rPr(s)
    set_sub(pPr, "spacing", {"before": "0", "after": "80", "line": "300", "lineRule": "auto"})
    set_sub(pPr, "jc", {"val": "both"})
    configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=False, italic=False, color="000000")

    # BlockText / Abstract
    for sid in ("BlockText", "Abstract"):
        if sid in styles_by_id:
            pPr, rPr = get_pPr_rPr(styles_by_id[sid])
            set_sub(pPr, "spacing", {"before": "0", "after": "160", "line": "360", "lineRule": "auto"})
            set_sub(pPr, "jc", {"val": "both"})
            configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=False, italic=False, color="000000")

    # Bibliography (hanging indent, left-aligned so DOIs/URLs don't stretch spaces)
    s = styles_by_id["Bibliography"]
    pPr, rPr = get_pPr_rPr(s)
    set_sub(pPr, "spacing", {"before": "0", "after": "120", "line": "300", "lineRule": "auto"})
    set_sub(pPr, "ind", {"left": "480", "hanging": "480"})
    set_sub(pPr, "jc", {"val": "left"})
    configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=False, italic=False, color="000000")

    # Title, Subtitle, Author, Date
    if "Title" in styles_by_id:
        pPr, rPr = get_pPr_rPr(styles_by_id["Title"])
        set_sub(pPr, "keepNext")
        set_sub(pPr, "keepLines")
        set_sub(pPr, "spacing", {"before": "0", "after": "200", "line": "300", "lineRule": "auto"})
        set_sub(pPr, "jc", {"val": "left"})
        configure_font(rPr, font="Liberation Serif", size_half_pt="32", bold=True, italic=False, color="000000")

    if "Subtitle" in styles_by_id:
        pPr, rPr = get_pPr_rPr(styles_by_id["Subtitle"])
        set_sub(pPr, "keepNext")
        set_sub(pPr, "spacing", {"before": "0", "after": "160", "line": "276", "lineRule": "auto"})
        set_sub(pPr, "jc", {"val": "left"})
        configure_font(rPr, font="Liberation Serif", size_half_pt="26", bold=False, italic=True, color="000000")

    for sid in ("Author", "Date"):
        if sid in styles_by_id:
            pPr, rPr = get_pPr_rPr(styles_by_id[sid])
            set_sub(pPr, "spacing", {"before": "0", "after": "120", "line": "276", "lineRule": "auto"})
            set_sub(pPr, "jc", {"val": "left"})
            configure_font(rPr, font="Liberation Serif", size_half_pt="24", bold=False, italic=False, color="000000")

    # Headings 1-6 (no automatic numbering, clean academic hierarchy)
    heading_specs = {
        "Heading1": ("30", True, False, "280", "120"),
        "Heading2": ("28", True, False, "260", "120"),
        "Heading3": ("25", True, False, "200", "100"),
        "Heading4": ("24", True, True, "160", "80"),
        "Heading5": ("24", False, True, "140", "60"),
        "Heading6": ("24", False, True, "120", "60"),
        "AbstractTitle": ("28", True, False, "240", "120"),
    }
    for sid, (sz, b, it, bef, aft) in heading_specs.items():
        if sid in styles_by_id:
            pPr, rPr = get_pPr_rPr(styles_by_id[sid])
            remove_sub(pPr, "numPr")
            set_sub(pPr, "keepNext")
            set_sub(pPr, "keepLines")
            set_sub(pPr, "spacing", {"before": bef, "after": aft, "line": "276", "lineRule": "auto"})
            set_sub(pPr, "jc", {"val": "left"})
            configure_font(rPr, font="Liberation Serif", size_half_pt=sz, bold=b, italic=it, color="000000")

    # Figure containers & Captions (suppress line numbers, keep figure attached to caption)
    for sid in ("Figure", "CaptionedFigure"):
        if sid in styles_by_id:
            pPr, rPr = get_pPr_rPr(styles_by_id[sid])
            set_sub(pPr, "keepNext")
            set_sub(pPr, "suppressLineNumbers")
            set_sub(pPr, "spacing", {"before": "180", "after": "80", "line": "240", "lineRule": "auto"})
            set_sub(pPr, "jc", {"val": "center"})
            configure_font(rPr, font="Liberation Serif", size_half_pt="22", bold=False, italic=False, color="000000")

    for sid in ("Caption", "ImageCaption", "TableCaption"):
        if sid in styles_by_id:
            pPr, rPr = get_pPr_rPr(styles_by_id[sid])
            set_sub(pPr, "suppressLineNumbers")
            if sid == "TableCaption":
                set_sub(pPr, "keepNext")
                set_sub(pPr, "spacing", {"before": "180", "after": "80", "line": "276", "lineRule": "auto"})
            else:
                remove_sub(pPr, "keepNext")
                set_sub(pPr, "spacing", {"before": "60", "after": "220", "line": "276", "lineRule": "auto"})
            set_sub(pPr, "jc", {"val": "both"})
            configure_font(rPr, font="Liberation Serif", size_half_pt="22", bold=False, italic=False, color="000000")

    # Character styles: VerbatimChar, Hyperlink, LineNumber, Footer
    if "VerbatimChar" in styles_by_id:
        rPr = styles_by_id["VerbatimChar"].find(f"{{{W}}}rPr")
        if rPr is None:
            rPr = ET.SubElement(styles_by_id["VerbatimChar"], f"{{{W}}}rPr")
        configure_font(rPr, font="Liberation Mono", size_half_pt="21", color="000000")

    if "Hyperlink" in styles_by_id:
        rPr = styles_by_id["Hyperlink"].find(f"{{{W}}}rPr")
        if rPr is None:
            rPr = ET.SubElement(styles_by_id["Hyperlink"], f"{{{W}}}rPr")
        set_sub(rPr, "color", {"val": "003366"})
        set_sub(rPr, "u", {"val": "single"})

    if "LineNumber" not in styles_by_id:
        ln_style = w_el("style", {"type": "character", "styleId": "LineNumber"})
        set_sub(ln_style, "name", {"val": "line number"})
        set_sub(ln_style, "basedOn", {"val": "DefaultParagraphFont"})
        rPr = ET.SubElement(ln_style, f"{{{W}}}rPr")
        configure_font(rPr, font="Liberation Serif", size_half_pt="19", bold=False, italic=False, color="666666")
        styles_root.append(ln_style)

    if "Footer" not in styles_by_id:
        ftr_style = w_el("style", {"type": "paragraph", "styleId": "Footer"})
        set_sub(ftr_style, "name", {"val": "footer"})
        set_sub(ftr_style, "basedOn", {"val": "Normal"})
        pPr = ET.SubElement(ftr_style, f"{{{W}}}pPr")
        set_sub(pPr, "suppressLineNumbers")
        set_sub(pPr, "spacing", {"before": "0", "after": "0", "line": "240", "lineRule": "auto"})
        set_sub(pPr, "jc", {"val": "center"})
        rPr = ET.SubElement(ftr_style, f"{{{W}}}rPr")
        configure_font(rPr, font="Liberation Serif", size_half_pt="22", bold=False, italic=False, color="000000")
        styles_root.append(ftr_style)

    entries["word/styles.xml"] = ET.tostring(styles_root, encoding="utf-8", xml_declaration=True)

    # 2. Clean word/settings.xml (ensure no autoHyphenation conflict)
    settings_root = ET.fromstring(entries["word/settings.xml"])
    remove_sub(settings_root, "autoHyphenation")
    entries["word/settings.xml"] = ET.tostring(settings_root, encoding="utf-8", xml_declaration=True)

    # 3. Clean word/numbering.xml so bullets use standard Unicode '•' in Liberation Serif
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
                remove_sub(rPr, "rFonts")
                rf = ET.SubElement(rPr, f"{{{W}}}rFonts")
                rf.set(f"{{{W}}}ascii", "Liberation Serif")
                rf.set(f"{{{W}}}hAnsi", "Liberation Serif")
                rf.set(f"{{{W}}}cs", "Liberation Serif")
        entries["word/numbering.xml"] = ET.tostring(num_root, encoding="utf-8", xml_declaration=True)

    # 4. Add clean centered page-number footer (word/footer1.xml)
    footer_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="{W}" xmlns:r="{R}">
  <w:p>
    <w:pPr>
      <w:pStyle w:val="Footer"/>
      <w:suppressLineNumbers/>
      <w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:r><w:fldChar w:fldCharType="begin"/></w:r>
    <w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>
    <w:r><w:fldChar w:fldCharType="separate"/></w:r>
    <w:r><w:t>1</w:t></w:r>
    <w:r><w:fldChar w:fldCharType="end"/></w:r>
  </w:p>
</w:ftr>'''
    entries["word/footer1.xml"] = footer_xml.encode("utf-8")

    # Register footer1.xml in word/_rels/document.xml.rels
    ET.register_namespace("", PKG_REL)
    rels_root = ET.fromstring(entries["word/_rels/document.xml.rels"])
    existing_ids = {rel.get("Id") for rel in rels_root}
    footer_rid = "rIdFooter1"
    if footer_rid not in existing_ids:
        rel_el = ET.SubElement(rels_root, f"{{{PKG_REL}}}Relationship")
        rel_el.set("Id", footer_rid)
        rel_el.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer")
        rel_el.set("Target", "footer1.xml")
    entries["word/_rels/document.xml.rels"] = ET.tostring(rels_root, encoding="utf-8", xml_declaration=True)

    # Register footer1.xml in [Content_Types].xml
    ET.register_namespace("", CT_NS)
    ct_root = ET.fromstring(entries["[Content_Types].xml"])
    has_ftr_override = any(
        ov.get("PartName") == "/word/footer1.xml" for ov in ct_root.findall(f"{{{CT_NS}}}Override")
    )
    if not has_ftr_override:
        ov = ET.SubElement(ct_root, f"{{{CT_NS}}}Override")
        ov.set("PartName", "/word/footer1.xml")
        ov.set("ContentType", "application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml")
    entries["[Content_Types].xml"] = ET.tostring(ct_root, encoding="utf-8", xml_declaration=True)

    # 5. Set A4 page size, 1-inch margins, footer reference, and continuous line numbers in document.xml
    ET.register_namespace("w", W)
    ET.register_namespace("r", R)
    doc_root = ET.fromstring(entries["word/document.xml"])
    body = doc_root.find(f"{{{W}}}body")
    sectPr = body.find(f"{{{W}}}sectPr")
    if sectPr is None:
        sectPr = ET.SubElement(body, f"{{{W}}}sectPr")
    sectPr.clear()

    ftr_ref = ET.SubElement(sectPr, f"{{{W}}}footerReference")
    ftr_ref.set(f"{{{W}}}type", "default")
    ftr_ref.set(f"{{{R}}}id", footer_rid)

    set_sub(sectPr, "pgSz", {"w": "11906", "h": "16838"})
    set_sub(
        sectPr,
        "pgMar",
        {
            "top": "1440",
            "bottom": "1440",
            "left": "1440",
            "right": "1440",
            "header": "720",
            "footer": "720",
            "gutter": "0",
        },
    )
    set_sub(sectPr, "lnNumType", {"countBy": "1", "restart": "continuous", "distance": "360"})
    set_sub(sectPr, "pgNumType", {"fmt": "decimal"})
    entries["word/document.xml"] = ET.tostring(doc_root, encoding="utf-8", xml_declaration=True)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zout:
        for name, data in entries.items():
            zout.writestr(name, data)
    print(f"Successfully built {out_path}")


if __name__ == "__main__":
    main()

