#!/bin/bash

# Convert Markdown to Professional PDF for CTO Presentation
# Uses pandoc with LuaLaTeX

echo "Converting docs.md to professional PDF..."

pandoc docs.md \
  -o docs.pdf \
  --pdf-engine=lualatex \
  --toc \
  --toc-depth=3 \
  --number-sections \
  --highlight-style=tango \
  --variable geometry:margin=0.6in \
  --variable fontsize=8pt \
  --variable linestretch=1.15 \
  --variable pagestyle=plain \
  --variable documentclass=report \
  --variable subparagraph \
  -V header-includes='\usepackage{titlesec}' \
  -V header-includes='\usepackage{parskip}' \
  -V header-includes='\setlength{\parskip}{6pt plus 2pt minus 1pt}' \
  -V header-includes='\setlength{\parindent}{0pt}' \
  -V header-includes='\titlespacing*{\chapter}{0pt}{20pt}{15pt}' \
  -V header-includes='\titlespacing*{\section}{0pt}{14pt plus 4pt minus 2pt}{8pt plus 2pt minus 2pt}' \
  -V header-includes='\titlespacing*{\subsection}{0pt}{12pt plus 4pt minus 2pt}{6pt plus 2pt minus 2pt}' \
  -V header-includes='\titlespacing*{\subsubsection}{0pt}{10pt plus 4pt minus 2pt}{4pt plus 2pt minus 2pt}' \
  -V header-includes='\usepackage{enumitem}' \
  -V header-includes='\setlist{itemsep=2pt, parsep=2pt, topsep=4pt}' \
  -V header-includes='\usepackage{caption}' \
  -V header-includes='\captionsetup{font=small, labelfont=bf, skip=8pt}' \
  -V header-includes='\usepackage{booktabs}' \
  -V header-includes='\renewcommand{\arraystretch}{1.3}' \
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  --metadata title="Extensible BI Dashboard Framework - Technical Documentation" \
  --metadata author="Jehu Shalom Amanna - Frontend Solutions Architect" \
  --metadata date="$(date '+%B %d, %Y')"

if [ $? -eq 0 ]; then
    echo "✓ Successfully created docs.pdf"
    echo "✓ File size: $(du -h docs.pdf | cut -f1)"
    echo ""
    echo "PDF created with:"
    echo "  - Professional LaTeX formatting"
    echo "  - Table of contents with 3 levels"
    echo "  - Numbered sections"
    echo "  - Syntax highlighting for code"
    echo "  - Hyperlinked cross-references"
    echo "  - 0.5-inch margins, 7.5pt font"
else
    echo "✗ Error creating PDF"
    exit 1
fi
