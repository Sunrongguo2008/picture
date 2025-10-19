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

# === Build prune expression safely ===
EXCLUDE_EXPR=()
for dir in $EXCLUDE_DIRS; do
  EXCLUDE_EXPR+=(-path "./$dir" -prune -o)
done

# === Find and convert images ===
# 注意这里使用括号逻辑：先排除目录，再匹配文件类型
find . \( "${EXCLUDE_EXPR[@]}" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \) | while read -r file; do
  # 去掉 ./ 前缀
  file="${file#./}"
  [ -z "$file" ] && continue

  avif="${file%.*}.avif"

  # 跳过已存在的 avif
  if [[ -f "$avif" ]]; then
    echo "Skipping existing: $avif"
    continue
  fi

  # 转换
  echo "Converting: $file → $avif"
  mkdir -p "$(dirname "$avif")"
  avifenc --min $QUALITY_MIN --max $QUALITY_MAX --speed $SPEED "$file" "$avif"

  # 获取文件大小
  orig_size=$(du -h "$file" | cut -f1)
  new_size=$(du -h "$avif" | cut -f1)

  # 写入 README
  awk -v entry="- [ ] \`${file}\` (${orig_size}) -> \`${avif}\` (${new_size})" '
    /^## 待修改/ {print; print entry; next}
    1
  ' "$README" > "$TMPFILE" && mv "$TMPFILE" "$README"
done

echo "✅ Conversion complete. Entries added to README."
