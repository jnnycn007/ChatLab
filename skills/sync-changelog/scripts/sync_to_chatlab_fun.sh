#!/usr/bin/env bash
set -euo pipefail

# 同步当前仓库多语言 changelog 到 ../chatlab.fun 并提交 docs: changelogs update
# 用法：sync_to_chatlab_fun.sh <source_repo> <target_repo>
SOURCE_REPO="${1:-}"
TARGET_REPO="${2:-}"

if [[ -z "$SOURCE_REPO" || -z "$TARGET_REPO" ]]; then
  echo "错误: 缺少参数。用法: sync_to_chatlab_fun.sh <source_repo> <target_repo>" >&2
  exit 1
fi

SRC_CN="$SOURCE_REPO/docs/public/changelogs/cn.json"
SRC_EN="$SOURCE_REPO/docs/public/changelogs/en.json"
SRC_TW="$SOURCE_REPO/docs/public/changelogs/tw.json"
SRC_JA="$SOURCE_REPO/docs/public/changelogs/ja.json"
DST_CN="$TARGET_REPO/public/cn/changelogs.json"
DST_EN="$TARGET_REPO/public/en/changelogs.json"
DST_TW="$TARGET_REPO/public/tw/changelogs.json"
DST_JA="$TARGET_REPO/public/ja/changelogs.json"

# 目标文件必须预先存在，不允许自动创建。
if [[ ! -f "$DST_CN" || ! -f "$DST_EN" || ! -f "$DST_TW" || ! -f "$DST_JA" ]]; then
  echo "错误: chatlab.fun 目标 changelog 文件不存在，请先手动准备" >&2
  exit 1
fi

if [[ ! -f "$SRC_CN" || ! -f "$SRC_EN" || ! -f "$SRC_TW" || ! -f "$SRC_JA" ]]; then
  echo "错误: 源仓库 changelog 文件不存在" >&2
  exit 1
fi

cp "$SRC_CN" "$DST_CN"
cp "$SRC_EN" "$DST_EN"
cp "$SRC_TW" "$DST_TW"
cp "$SRC_JA" "$DST_JA"

# 仅提交目标文档文件，避免提交其他改动。
git -C "$TARGET_REPO" add \
  public/cn/changelogs.json \
  public/en/changelogs.json \
  public/tw/changelogs.json \
  public/ja/changelogs.json

if git -C "$TARGET_REPO" diff --cached --quiet; then
  echo "错误: chatlab.fun 没有可提交的 changelog 变更" >&2
  exit 1
fi

git -C "$TARGET_REPO" commit -m "docs: changelogs update" >/dev/null

git -C "$TARGET_REPO" rev-parse --short HEAD
