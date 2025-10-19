#!/usr/bin/env bash
set -euo pipefail

README="README.md"
TMPFILE=$(mktemp)
REPO_DIR=$(pwd)  # 仓库根目录

# 初始化变量
todo_lines=""
done_lines=""
before_todo=""
after_todo=""
in_todo_section=0

echo "🧹 Cleaning up checked items..."

while IFS= read -r line; do
    if [[ "$line" == "## 待修改" ]]; then
        in_todo_section=1
        continue
    elif [[ "$line" == "## 完成" ]]; then
        in_todo_section=0
        after_todo+="$line"$'\n'
        continue
    fi

    if [[ $in_todo_section -eq 1 ]]; then
        # 已勾选条目
        if echo "$line" | grep -q '^- \[x\]'; then
            # 提取原图路径（第一个反引号里的内容）
            filepath=$(echo "$line" | awk -F'`' '{print $2}')
            fullpath="$REPO_DIR/$filepath"
            if [ -n "$filepath" ] && [ -f "$fullpath" ]; then
                echo "Deleting: $fullpath"
                rm -f -- "$fullpath"
            else
                echo "⚠️ File not found or path empty: $fullpath"
            fi
            done_lines+="$line"$'\n'
        # 未勾选条目
        elif echo "$line" | grep -q '^- \[ \]'; then
            todo_lines+="$line"$'\n'
        else
            # 待修改区的其他行保留
            todo_lines+="$line"$'\n'
        fi
    else
        # 待修改区外的内容保留
        before_todo+="$line"$'\n'
    fi
done < "$README"

# 如果 README 没有完成区，则创建
if ! grep -q "^## 完成" "$README"; then
    after_todo="## 完成"$'\n'"$done_lines"$'\n'"$after_todo"
    done_lines=""
fi

# 生成新的 README
{
    printf "%s" "$before_todo"
    printf "## 待修改\n%s" "$todo_lines"
    printf "## 完成\n%s" "$done_lines"
    printf "%s" "$after_todo"
} > "$TMPFILE"

mv "$TMPFILE" "$README"

echo "✅ Cleanup complete."
