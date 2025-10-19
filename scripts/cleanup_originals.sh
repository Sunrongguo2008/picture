#!/usr/bin/env bash
set -euo pipefail

README="README.md"
TMPFILE=$(mktemp)

echo "🧹 Cleaning up checked items..."

# ---- Delete original images listed as checked [x] ----
grep "^- \[x\]" "$README" | while IFS= read -r line; do
  # Use sed to extract the path inside backticks safely
  orig=$(echo "$line" | sed -n 's/.*`\([^`]*\.\(png\|jpg\|jpeg\|webp\)\)`.*/\1/p')
  if [ -n "$orig" ] && [ -f "$orig" ]; then
    echo "Deleting: $orig"
    rm -f -- "$orig"
  else
    echo "Not found or empty: $orig"
  fi
done

# ---- Move checked items to 完成 区 ----
awk '
  BEGIN {in_todo=0; in_done=0}
  /^## 待修改/ {in_todo=1; in_done=0; print; next}
  /^## 完成/ {in_todo=0; in_done=1; print; next}
  {
    if (in_todo && $0 ~ /^\- \[x\]/) done = done $0 "\n";
    else if (in_todo && $0 ~ /^\- \[ \]/) todo = todo $0 "\n";
    else if (!in_todo && !in_done) other = other $0 "\n";
    else if (in_done) done_section = done_section $0 "\n";
  }
  END {
    print other;
    print "## 待修改\n" todo;
    print "## 完成\n" done_section done;
  }
' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"

echo "✅ Cleanup complete."
