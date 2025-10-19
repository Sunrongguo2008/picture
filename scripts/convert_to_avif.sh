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

# === Build find exclude arguments ===
EXCLUDE_ARGS=()
for dir in $EXCLUDE_DIRS; do
  EXCLUDE_ARGS+=(-path "./$dir" -prune -o)
done

# === Find and convert images ===
find . \( "${EXCLUDE_ARGS[@]}" \) -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r file; do
  avif="${file%.*}.avif"

  # Skip if AVIF already exists
  if [[ -f "$avif" ]]; then
    echo "Skipping existing: $avif"
    continue
  fi

  # Convert
  echo "Converting: $file → $avif"
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
