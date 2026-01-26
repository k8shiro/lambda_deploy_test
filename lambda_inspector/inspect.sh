#!/bin/bash
set -e

# 変数の確認
if [ -z "$FUNCTION_NAME" ]; then
  echo "エラー: FUNCTION_NAME環境変数を設定してください"
  exit 1
fi

echo "=== Lambda関数のダウンロード: ${FUNCTION_NAME} ==="

# Lambda関数のコードURLを取得してダウンロード
aws lambda get-function --function-name ${FUNCTION_NAME} --query 'Code.Location' --output text | xargs curl -o lambda_function.zip

# ZIPを展開
echo "=== ZIPを展開 ==="
unzip -o lambda_function.zip -d lambda_code/

# ライブラリ一覧を表示
echo "=== インストールされているライブラリ ==="
PYTHONPATH=lambda_code/ python list_packages.py
