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

# === Find all candidate images ===
while IFS= read -r -d '' file; do
  # Skip excluded directories
  if is_excluded "$file"; then
    continue
  fi

  file="${file#./}"
  avif="${file%.*}.avif"

  # --- Determine if already listed in README ---
  if grep -q "\`${file}\`" "$README"; then
    echo "Already listed in README: $file"
    continue
  fi

  # --- Check if avif exists ---
  avif_exists=false
  if [[ -f "$avif" ]]; then
    avif_exists=true
  fi

  # --- Convert if not existing ---
  if [ "$avif_exists" = false ]; then
    echo "Converting: $file → $avif"
    mkdir -p "$(dirname "$avif")"
    avifenc --min $QUALITY_MIN --max $QUALITY_MAX --speed $SPEED "$file" "$avif"
  else
    echo "AVIF already exists for: $file"
  fi

  # --- Compute sizes ---
  orig_size=$(du -h "$file" | cut -f1)
  new_size=$(du -h "$avif" | cut -f1)

  # --- Add to README if not already listed ---
  entry="- [ ] \`${file}\` (${orig_size}) -> \`${avif}\` (${new_size})"
  awk -v entry="$entry" '
    /^## 待修改/ {print; print entry; next}
    1
  ' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"

done < <(find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0)

echo "✅ Conversion complete. Entries added to README."
