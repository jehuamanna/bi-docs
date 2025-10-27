#!/bin/bash

# Convert Markdown to Professional PDF for CTO Presentation
# Uses pandoc with custom LaTeX template

echo "Converting docs.md to professional PDF..."

pandoc docs.md \
  -o docs.pdf \
  --pdf-engine=lualatex \
  --toc \
  --toc-depth=2 \
  --number-sections \
  --highlight-style=tango \
  --variable geometry:margin=0.5in \
  --variable fontsize=7.5pt \
  --variable linestretch=1.0 \
  --metadata title="Extensible BI Dashboard Framework - Technical Documentation" \
  --metadata author="Technical Architecture Team" \
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
    echo "  - 1-inch margins, 11pt font"
else
    echo "✗ Error creating PDF"
    exit 1
fi
