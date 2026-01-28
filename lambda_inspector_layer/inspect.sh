#!/bin/bash
set -e

# 変数の確認
if [ -z "$FUNCTION_NAME" ]; then
  echo "エラー: FUNCTION_NAME環境変数を設定してください"
  exit 1
fi

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "=== Lambda関数の検査（レイヤー対応版）: ${FUNCTION_NAME} ==="

# 既存のディレクトリをクリーンアップ
rm -rf lambda_code/
rm -rf layers/
rm -f lambda_function.zip

# Lambda関数の情報を取得
echo "=== Lambda関数の情報を取得中 ==="
FUNCTION_INFO=$(aws lambda get-function --function-name ${FUNCTION_NAME} --region ${REGION})

# Lambda関数のコードをダウンロード
echo "=== Lambda関数のコードをダウンロード ==="
CODE_URL=$(echo "$FUNCTION_INFO" | grep -o '"Location": "[^"]*"' | head -1 | cut -d'"' -f4)
curl -s -o lambda_function.zip "$CODE_URL"

# ZIPを展開
echo "=== Lambda関数のコードを展開 ==="
mkdir -p lambda_code
unzip -q lambda_function.zip -d lambda_code/

# レイヤー情報を取得
echo "=== レイヤー情報を取得中 ==="
LAYER_ARNS=$(aws lambda get-function --function-name ${FUNCTION_NAME} --region ${REGION} \
  --query 'Configuration.Layers[].Arn' --output text 2>/dev/null || echo "")

if [ -z "$LAYER_ARNS" ] || [ "$LAYER_ARNS" = "None" ]; then
  echo "レイヤーは使用されていません。"
else
  echo "使用されているレイヤー:"
  mkdir -p layers

  LAYER_NUM=1
  for LAYER_ARN in $LAYER_ARNS; do
    echo "  - $LAYER_ARN"

    # レイヤーのコードをダウンロード
    echo "    ダウンロード中..."
    LAYER_URL=$(aws lambda get-layer-version-by-arn --arn "$LAYER_ARN" --region ${REGION} \
      --query 'Content.Location' --output text)

    LAYER_ZIP="layers/layer_${LAYER_NUM}.zip"
    LAYER_DIR="layers/layer_${LAYER_NUM}"

    curl -s -o "$LAYER_ZIP" "$LAYER_URL"

    # レイヤーを展開
    echo "    展開中..."
    mkdir -p "$LAYER_DIR"
    unzip -q "$LAYER_ZIP" -d "$LAYER_DIR"

    LAYER_NUM=$((LAYER_NUM + 1))
  done
fi

# PYTHONPATHを構築（lambda_code + 各レイヤーのpythonディレクトリ）
PYTHON_PATHS="lambda_code"

if [ -d "layers" ]; then
  for LAYER_DIR in layers/layer_*/; do
    if [ -d "${LAYER_DIR}python" ]; then
      PYTHON_PATHS="${PYTHON_PATHS}:${LAYER_DIR}python"
    fi
    # レイヤー直下にパッケージがある場合も追加
    if [ -d "$LAYER_DIR" ]; then
      PYTHON_PATHS="${PYTHON_PATHS}:${LAYER_DIR}"
    fi
  done
fi

echo ""
echo "=== インストールされているライブラリ ==="
PYTHONPATH="$PYTHON_PATHS" python list_packages.py

echo ""
echo "=== 検査完了 ==="
echo "関数コード: lambda_code/"
if [ -d "layers" ]; then
  echo "レイヤー: layers/"
fi
