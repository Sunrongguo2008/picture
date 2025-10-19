#!/usr/bin/env bash
set -euo pipefail

README="README.md"
TMPFILE=$(mktemp)

# 初始化变量，防止 unbound variable
todo_lines=""
done_lines=""

echo "🧹 Cleaning up checked items..."

# Step 1: 分区提取 README
before_todo=""
after_todo=""
in_todo_section=0

while IFS= read -r line; do
    if [[ "$line" =~ ^##\ 待修改 ]]; then
        in_todo_section=1
        continue  # 不把标题加入 before_todo
    elif [[ "$line" =~ ^##\ 完成 ]]; then
        in_todo_section=0
        after_todo+="$line"$'\n'
        continue
    fi

    if [[ $in_todo_section -eq 1 ]]; then
        # 待修改区行处理
        if [[ "$line" =~ ^-.\ \[x\] ]]; then
            # 提取路径
            filepath=$(echo "$line" | sed -n 's/.*`\([^`]*\.\(png\|jpg\|jpeg\|webp\)\)`.*/\1/p')
            if [ -n "$filepath" ] && [ -f "$filepath" ]; then
                echo "Deleting: $filepath"
                rm -f -- "$filepath"
            fi
            done_lines+="$line"$'\n'
        elif [[ "$line" =~ ^-.\ \[ \] ]]; then
            # 未勾选保留
            todo_lines+="$line"$'\n'
        else
            # 其他行保留在待修改区
            todo_lines+="$line"$'\n'
        fi
    else
        # 待修改区之外的内容保留
        before_todo+="$line"$'\n'
    fi
done < "$README"

# Step 2: 检查 README 中是否已有完成区
if ! grep -q "^## 完成" "$README"; then
    after_todo="## 完成"$'\n'"$done_lines"$'\n'"$after_todo"
    done_lines=""
fi

# Step 3: 生成新的 README
{
    printf "%s" "$before_todo"
    printf "## 待修改\n%s" "$todo_lines"
    printf "## 完成\n%s" "$done_lines"
    printf "%s" "$after_todo"
} > "$TMPFILE"

mv "$TMPFILE" "$README"

echo "✅ Cleanup complete."
