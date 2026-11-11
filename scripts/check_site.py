#!/usr/bin/env python3
"""Check the rendered site in docs/ against the .qmd sources.

Fails (exit 1) if:
  - a rendered .qmd has no HTML page
  - a page linked from another page does not exist (broken internal link)
Warns if a protocol/buffer has no PDF.
Run from anywhere:  python3 scripts/check_site.py
"""
import glob, os, re, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
docs = os.path.join(root, "docs")
errors, warnings = [], []

for q in glob.glob(os.path.join(root, "**", "*.qmd"), recursive=True):
    rel = os.path.relpath(q, root)
    if rel.startswith(("docs", ".quarto", "protocols_src/templates/blocks")) or os.path.basename(q).startswith("_"):
        continue
    base = os.path.join(docs, rel[:-4])
    name = os.path.basename(q)
    if not os.path.exists(base + ".html"):
        # authoring templates are intentionally PDF-only; everything else needs a web page
        if "/templates/" in rel and os.path.exists(base + ".pdf"):
            continue
        errors.append(f"no HTML for {rel}")
    if (name.startswith(("prot_", "buf_"))) and not os.path.exists(base + ".pdf"):
        warnings.append(f"no PDF for {rel}")

checked = 0
for f in glob.glob(os.path.join(docs, "**", "*.html"), recursive=True):
    if "site_libs" in f or os.path.basename(f) == "404.html":
        continue  # 404.html uses root-relative links by design
    html = open(f, encoding="utf-8", errors="ignore").read()
    for u in re.findall(r'href="([^"#?]+\.(?:html|pdf))"', html):
        if re.match(r"^[a-z]+:", u):
            continue
        checked += 1
        target = os.path.normpath(os.path.join(os.path.dirname(f), u))
        if not os.path.exists(target):
            errors.append(f"broken link in {os.path.relpath(f, docs)}: {u}")

print(f"{checked} internal page links checked")
for w in warnings: print("WARNING:", w)
for e in errors: print("ERROR:", e)
print(f"{len(errors)} errors, {len(warnings)} warnings")
sys.exit(1 if errors else 0)
