#!/usr/bin/env bash
# Rebuild index.html from the CV markdown and copy the photo and PDF.
set -euo pipefail
SRC=$(cd "${CV_SRC:-$(dirname "$0")/../cv}" && pwd)
cd "$(dirname "$0")"
cp "$SRC/viktor-ganin-photo.jpg" .

# Web PDF: same layout and print settings as cv-viktor-ganin-main.pdf, without lines marked <!-- private --> (contacts)
TMP=$(mktemp --suffix=.html)
trap 'rm -f "$TMP"' EXIT
{
  echo '<!doctype html><html><head><meta charset="utf-8"><title>Viktor Ganin — CV</title>'
  echo "<base href=\"file://$PWD/\">"
  echo '<style>@page{size:A4;margin:8mm 9mm} html,body{margin:0;background:#fff;-webkit-print-color-adjust:exact;print-color-adjust:exact} body{zoom:0.77} li{break-inside:avoid} a{color:#2f6db5}</style>'
  echo '</head><body>'
  grep -v -e '<!-- private -->' "$SRC/cv-viktor-ganin-main.md"
  echo '</body></html>'
} > "$TMP"
chromium-browser --headless --disable-gpu --no-sandbox --allow-file-access-from-files --no-pdf-header-footer \
  --print-to-pdf="$PWD/viktor-ganin-cv.pdf" "$TMP" >/dev/null 2>&1
# Copy <!-- pdf-author/subject/keywords: ... --> comments from the CV into the PDF metadata for ATS
/usr/bin/python3 - "$SRC/cv-viktor-ganin-main.md" viktor-ganin-cv.pdf <<'PY'
import re, sys, pikepdf
src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
meta = dict(re.findall(r"^<!-- pdf-(author|subject|keywords): (.*?) -->$", text, re.M))
with pikepdf.open(out, allow_overwriting_input=True) as pdf:
    for key, value in meta.items():
        pdf.docinfo["/" + key.capitalize()] = value
    pdf.save(out)
PY
{
  echo '<!doctype html><html lang="en"><head><meta charset="utf-8">'
  echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
  echo '<meta name="robots" content="noindex">'
  echo '<title>Viktor Ganin — DevOps Engineer</title>'
  # Same author/keywords as the PDF metadata
  sed -n 's/^<!-- pdf-\(author\|keywords\): \(.*\) -->$/<meta name="\1" content="\2">/p' "$SRC/cv-viktor-ganin-main.md"
  echo '<style>body{margin:24px auto;max-width:960px;background:#fff}'
  echo '.pdf-btn{display:inline-block;margin-top:6px;background:#4F46E5;color:#fff !important;text-decoration:none;padding:5px 12px;border-radius:4px;font-size:13px;line-height:1.6}'
  echo '.pdf-btn:hover{background:#3730a3}'
  # Phones: stack the header cells and the two columns; inline styles need !important
  echo '@media screen and (max-width:720px){'
  echo ' body{margin:12px}'
  echo ' body>div{font-size:14px !important}'
  echo ' body>div table,body>div tbody,body>div tr,body>div td{display:block;width:100% !important;box-sizing:border-box}'
  echo ' body>div>table:first-of-type tr{display:flex;flex-direction:column}'
  echo ' body>div>table:first-of-type td{padding:0 0 12px 0 !important;text-align:left !important}'
  echo ' body>div>table:first-of-type td:nth-child(2){order:-1;text-align:center !important}'
  echo ' body>div>table:first-of-type td:nth-child(3){padding-left:40px !important;line-height:1.9 !important}'
  echo ' body>div>table:last-of-type td{padding:0 !important}'
  echo ' body>div>table:last-of-type td:last-child{margin-top:18px}'
  echo ' body>div>table:last-of-type td:first-child>div[style*="padding-left: 40px"]{padding-left:22px !important}'
  echo ' body>div>table:last-of-type td:first-child>div[style*="border-left"]{border-left-width:12px !important;padding-left:10px !important}'
  echo ' body>div>table:last-of-type td:first-child>div[style*="margin: 0 0 8px 40px"]{margin-left:0 !important}'
  echo ' img{width:110px !important;height:110px !important}'
  echo '}'
  echo '@media print{.pdf-btn{display:none} @page{size:A4;margin:8mm 9mm} body{zoom:.77;margin:0} li{break-inside:avoid}}</style>'
  echo '</head><body>'
  # Leave the email address off the public page; put the download button under the GitHub link
  grep -v -e '<!-- private -->' -e '^<!-- pdf-' "$SRC/cv-viktor-ganin-main.md" \
    | sed '/github\.com\/v1k-t0r<\/a>/s|$|<br><br>\n<a class="pdf-btn" href="viktor-ganin-cv.pdf" download="Viktor_Ganin_CV.pdf">⤓ Download PDF</a>|'
  echo '</body></html>'
} > index.html
if grep -qi -e 'mailto:' -e '@gmail\.com' -e 't\.me/' index.html; then echo "error: private contact still in index.html" >&2; exit 1; fi
if pdftotext viktor-ganin-cv.pdf - | grep -qi -e '@gmail\.com' -e 't\.me/'; then echo "error: private contact still in viktor-ganin-cv.pdf" >&2; exit 1; fi
pdfinfo viktor-ganin-cv.pdf | grep -q '^Keywords:' || { echo "error: PDF metadata missing" >&2; exit 1; }
grep -q 'class="pdf-btn"' index.html || { echo "error: download button missing" >&2; exit 1; }
echo "index.html and viktor-ganin-cv.pdf rebuilt"
