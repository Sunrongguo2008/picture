name: Cleanup Originals

on:
  workflow_dispatch:  # 手动触发

jobs:
  cleanup:
    runs-on: ubuntu-latest

    steps:
      # 完整 checkout 仓库，保证文件存在
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # 打印 obsidian 文件夹内容，确认路径
      - name: List obsidian files
        run: ls -R obsidian || echo "No obsidian folder"

      # 运行 cleanup 脚本
      - name: Cleanup originals
        run: |
          chmod +x scripts/cleanup_originals.sh
          ./scripts/cleanup_originals.sh

      # 自动 commit 和 push README（避免空 pathspec）
      - name: Commit and push changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          if [ -n "$(git status --porcelain)" ]; then
            # 使用 git add . 避免 pathspec 空错误
            git add .
            git commit -m "Cleanup originals after AVIF confirmation"
            git push
          else
            echo "No changes to commit."
