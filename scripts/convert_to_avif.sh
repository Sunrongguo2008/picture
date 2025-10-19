#!/usr/bin/env bash
set -e

# === CONFIG ===
QUALITY_MIN=0
QUALITY_MAX=30
SPEED=0
README="README.md"
TMPFILE=$(mktemp)
EXCLUDE_DIRS=".git .github node_modules .npm .cache"

# === Initialize README sections ===
if ! grep -q "## 待修改" "$README"; then
  echo -e "\n## 待修改\n" >> "$README"
fi

if ! grep -q "## 完成" "$README"; then
  echo -e "\n## 完成\n" >> "$README"
fi

# === Build find command safely ===
EXCLUDE_EXPR=()
for dir in $EXCLUDE_DIRS; do
  EXCLUDE_EXPR+=(-path "./$dir" -prune -o)
done

# 最后一组条件后加一个 -false 避免多余的 -o
EXCLUDE_EXPR+=(-false)

# === Find and convert images ===
find . \( "${EXCLUDE_EXPR[@]}" \) -o -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r file; do
  # 跳过以 ./ 开头的 find 结果前缀，方便打印
  file="${file#./}"

  # 跳过空行
  [ -z "$file" ] && continue

  avif="${file%.*}.avif"

  # Skip if AVIF already exists
  if [[ -f "$avif" ]]; then
    echo "Skipping existing: $avif"
    continue
  fi

  # Convert
  echo "Converting: $file → $avif"
  mkdir -p "$(dirname "$avif")"
  avifenc --min $QUALITY_MIN --max $QUALITY_MAX --speed $SPEED "$file" "$avif"

  # Get sizes
  orig_size=$(du -h "$file" | cut -f1)
  new_size=$(du -h "$avif" | cut -f1)

  # Add entry to README "待修改" section
  awk -v entry="- [ ] \`${file}\` (${orig_size}) -> \`${avif}\` (${new_size})" '
    /^## 待修改/ {print; print entry; next}
    1
  ' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"
done

echo "✅ Conversion complete. Entries added to README."
