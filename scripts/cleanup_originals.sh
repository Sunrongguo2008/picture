#!/usr/bin/env bash
set -e

# --- 防止 Windows 换行符导致 awk 报错 ---
dos2unix "$0" 2>/dev/null || sed -i 's/\r$//' "$0"

README="README.md"
TMPFILE=$(mktemp)

echo "🧹 Cleaning up checked items..."

# 删除对应原始图片
grep "^- \[x\]" "$README" | while read -r line; do
  orig=$(echo "$line" | grep -oE "\`[^`]+\.(png|jpg|jpeg|webp)\`" | sed 's/`//g')
  if [ -n "$orig" ] && [ -f "$orig" ]; then
    echo "Deleting: $orig"
    rm -f "$orig"
  fi
done

# 将已勾选的项移至 “完成” 区
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
