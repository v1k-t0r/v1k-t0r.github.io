#!/usr/bin/env bash
# Rebuild index.html from the CV markdown and copy the photo and PDF.
set -euo pipefail
SRC=$(cd "${CV_SRC:-$(dirname "$0")/../cv}" && pwd)
cd "$(dirname "$0")"
cp "$SRC/viktor-ganin-photo.jpg" .

# Public copy of the CV: no lines marked <!-- private --> (contacts), and no city.
# The CV marks the city as <span data-city>City, </span>; drop the span and every keyword containing the city.
CITY=$(grep -o '<span data-city>[^<]*</span>' "$SRC/cv-viktor-ganin-main.md" | head -1 | sed -e 's/<[^>]*>//g' -e 's/, *$//')
[[ -n $CITY ]] || { echo "error: no <span data-city> in the CV" >&2; exit 1; }
PUB=$(mktemp --suffix=.md)
TMP=$(mktemp --suffix=.html)
trap 'rm -f "$TMP" "$PUB"' EXIT
grep -v -e '<!-- private -->' "$SRC/cv-viktor-ganin-main.md" \
  | sed -e 's|<span data-city>[^<]*</span>||g' \
        -e "/^<!-- pdf-keywords:/s/ [^,]*$CITY[^,]*,//g" > "$PUB"

# Web PDF: same layout and print settings as cv-viktor-ganin-main.pdf
{
  echo '<!doctype html><html><head><meta charset="utf-8"><title>Viktor Ganin — CV</title>'
  echo "<base href=\"file://$PWD/\">"
  echo '<style>@page{size:A4;margin:8mm 9mm} html,body{margin:0;background:#fff;-webkit-print-color-adjust:exact;print-color-adjust:exact} body{zoom:0.77} li{break-inside:avoid} a{color:#2f6db5}</style>'
  echo '</head><body>'
  cat "$PUB"
  echo '</body></html>'
} > "$TMP"
chromium-browser --headless --disable-gpu --no-sandbox --allow-file-access-from-files --no-pdf-header-footer \
  --print-to-pdf="$PWD/viktor-ganin-cv.pdf" "$TMP" >/dev/null 2>&1
# Copy <!-- pdf-author/subject/keywords: ... --> comments from the CV into the PDF metadata for ATS
/usr/bin/python3 - "$PUB" viktor-ganin-cv.pdf <<'PY'
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
  echo '<script>try{var t=localStorage.getItem("theme");if(t)document.documentElement.className=t}catch(e){}</script>'
  # Same author/keywords as the PDF metadata
  sed -n 's/^<!-- pdf-\(author\|keywords\): \(.*\) -->$/<meta name="\1" content="\2">/p' "$PUB"
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
  # Dark theme: the CV colours are inline styles, so override them by their values; screen only, PDF and print stay light
  dark_rules() {
    local p=$1
    echo "$p{color-scheme:dark}"
    echo "$p body,$p body>div{background:#16181d !important;color:#e2e4e9 !important}"
    echo "$p [style*=\"color: #1a1a1a\"]{color:#e2e4e9 !important}"
    echo "$p [style*=\"color: #333\"]{color:#d2d5db !important}"
    echo "$p [style*=\"color: #444\"]{color:#b9bdc5 !important}"
    echo "$p [style*=\"color: #555\"]{color:#a9aeb7 !important}"
    echo "$p [style*=\"color: #777\"]{color:#939aa4 !important}"
    echo "$p [style*=\"color: #4F46E5\"]{color:#8f96ff !important}"
    echo "$p [style*=\"solid #2d3a45\"]{border-color:#56687a !important}"
    echo "$p [style*=\"border-bottom: 2px solid #4F46E5\"]{border-bottom-color:#7b7ff7 !important}"
    echo "$p a{color:#8ab4f8}"
    echo "$p svg [fill=\"#4F46E5\"]{fill:#8f96ff}"
    echo "$p svg [stroke=\"#fff\"]{stroke:#16181d}"
    echo "$p .theme-btn{color:#e2e4e9;border-color:#8f96ff}"
  }
  echo '.theme-btn{display:inline-block;margin:6px 0 0 6px;background:transparent;color:#4F46E5;border:1px solid #4F46E5;border-radius:4px;padding:4px 9px;font-size:13px;line-height:1.6;cursor:pointer;vertical-align:top}'
  echo '.theme-btn:hover{background:rgba(79,70,229,.12)}'
  echo '@media screen{'
  dark_rules 'html.dark'
  echo '}'
  echo '@media screen and (prefers-color-scheme:dark){'
  dark_rules 'html:not(.light)'
  echo '}'
  echo '@media print{.pdf-btn,.theme-btn{display:none} @page{size:A4;margin:8mm 9mm} body{zoom:.77;margin:0} li{break-inside:avoid}}</style>'
  echo '</head><body>'
  # Leave the email address off the public page; put the download button under the last contact line (location)
  grep -v -e '^<!-- pdf-' "$PUB" \
    | sed '/Montenegro (CET)<\/span>/s|$|<br><br>\n<a class="pdf-btn" href="viktor-ganin-cv.pdf" download="Viktor_Ganin_CV.pdf">⤓ Download PDF</a> <button class="theme-btn" type="button" aria-label="Switch light or dark theme" title="Switch light or dark theme"><svg width="14" height="14" viewBox="0 0 24 24" style="vertical-align:-2px"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M12 3a9 9 0 0 1 0 18z" fill="currentColor"/></svg></button>|'
  # Theme toggle: remembers the choice; without one the page follows the system setting
  echo '<script>(function(){var h=document.documentElement,b=document.querySelector(".theme-btn");'
  echo 'function dark(){return h.classList.contains("dark")||(!h.classList.contains("light")&&matchMedia("(prefers-color-scheme: dark)").matches)}'
  echo 'b.addEventListener("click",function(){var t=dark()?"light":"dark";h.className=t;try{localStorage.setItem("theme",t)}catch(e){}})})()</script>'
  echo '</body></html>'
} > index.html
if grep -qi -e 'mailto:' -e '@gmail\.com' -e 't\.me/' index.html; then echo "error: private contact still in index.html" >&2; exit 1; fi
if pdftotext viktor-ganin-cv.pdf - | grep -qi -e '@gmail\.com' -e 't\.me/'; then echo "error: private contact still in viktor-ganin-cv.pdf" >&2; exit 1; fi
pdfinfo viktor-ganin-cv.pdf | grep -q '^Keywords:' || { echo "error: PDF metadata missing" >&2; exit 1; }
grep -q 'class="pdf-btn"' index.html || { echo "error: download button missing" >&2; exit 1; }
grep -q 'class="theme-btn"' index.html || { echo "error: theme button missing" >&2; exit 1; }
if grep -q 'data-city' index.html; then echo "error: city still in the public header" >&2; exit 1; fi
if pdfinfo viktor-ganin-cv.pdf | grep -q "^Keywords:.*$CITY" || grep -q "<meta name=\"keywords\"[^>]*$CITY" index.html; then echo "error: city still in the public keywords" >&2; exit 1; fi
echo "index.html and viktor-ganin-cv.pdf rebuilt"
