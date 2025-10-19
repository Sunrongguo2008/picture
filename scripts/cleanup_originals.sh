#!/usr/bin/env bash
set -euo pipefail

README="README.md"
TMPFILE=$(mktemp)

todo_lines=""
done_lines=""


echo "🧹 Cleaning up checked items..."

# ---- Delete original images listed as checked [x] ----
grep "^- \[x\]" "$README" | while IFS= read -r line; do
  # Use sed to extract the path inside backticks safely
orig=$(echo "$line" | sed -n 's/.*`\([^`]*\.\(png\|jpg\|jpeg\|webp\)\)`.*/\1/p')
if [ -n "$orig" ] && [ -f "$orig" ]; then
    echo "Deleting: $orig"
    rm -f -- "$orig"
fi

done

# ---- Move checked items to 完成 区 ----
awk -v todo="$todo_lines" -v done="$done_lines" '
  BEGIN {in_todo=0; in_done=0}
  /^## 待修改/ {in_todo=1; print; print todo; next}
  /^## 完成/ {in_done=1; in_todo=0; print; print done; next}
  {
    # 打印除待修改/完成区以外的行
    if (!in_todo && !in_done) print
  }
' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"


echo "✅ Cleanup complete."
