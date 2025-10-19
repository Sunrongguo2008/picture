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

# === Function: check if path is in excluded dirs ===
is_excluded() {
  for dir in $EXCLUDE_DIRS; do
    [[ $1 == $dir* || $1 == ./$dir* ]] && return 0
  done
  return 1
}

# === Find and convert images manually (no fancy find logic) ===
while IFS= read -r -d '' file; do
  # Skip excluded paths
  if is_excluded "$file"; then
    continue
  fi

  # Remove leading ./ for display
  file="${file#./}"

  avif="${file%.*}.avif"

  # Skip if AVIF already exists
  if [[ -f "$avif" ]]; then
    echo "Skipping existing: $avif"
    continue
  fi

  echo "Converting: $file → $avif"
  mkdir -p "$(dirname "$avif")"
  avifenc --min $QUALITY_MIN --max $QUALITY_MAX --speed $SPEED "$file" "$avif"

  orig_size=$(du -h "$file" | cut -f1)
  new_size=$(du -h "$avif" | cut -f1)

  # Avoid duplicate entries in README
  if ! grep -q "\`${file}\`" "$README"; then
    awk -v entry="- [ ] \`${file}\` (${orig_size}) -> \`${avif}\` (${new_size})" '
      /^## 待修改/ {print; print entry; next}
      1
    ' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"
  fi

done < <(find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0)

echo "✅ Conversion complete. Entries added to README."
