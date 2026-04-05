#!/bin/bash
# preToolUse Hook — iOS コード品質ゲート

FILE_PATH="$2"
CONTENT="$3"

# Swift ファイル以外はスキップ
[[ "$FILE_PATH" != *.swift ]] && exit 0

# force unwrap チェック
if echo "$CONTENT" | grep -qE '[^!]=![^=]|[^!]![.[(]'; then
    echo "❌ BLOCKED: force unwrap（!）が含まれています"
    echo "   guard let または if let を使ってください"
    echo "$(date): BLOCKED force unwrap in $FILE_PATH" >> ~/.copilot/quality-gate.log
    exit 1
fi

exit 0
