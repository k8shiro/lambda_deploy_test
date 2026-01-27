#!/bin/bash

# Lambda関数デプロイスクリプト（レイヤー版）

set -e

# 設定
FUNCTION_NAME="lambda-deploy-test-cli-layer"
LAYER_NAME="lambda-deploy-test-layer"
ROLE_NAME="lambda-deploy-test-role"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
RUNTIME="python3.12"
HANDLER="lambda_function.lambda_handler"

echo "=== Lambda関数デプロイスクリプト (AWS CLI - レイヤー版) ==="

# IAMロールの存在確認
echo "IAMロールを確認中..."
if ! aws iam get-role --role-name "$ROLE_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "IAMロールを作成中..."

    # Trust Policy（信頼ポリシー）を作成
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # IAMロールを作成
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --region "$REGION"

    # 基本実行ポリシーをアタッチ
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --region "$REGION"

    echo "IAMロールの作成が完了しました。ロールの伝播を待機中（10秒）..."
    sleep 10
else
    echo "IAMロールは既に存在します。"
fi

# ロールARNを取得
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --region "$REGION" --query 'Role.Arn' --output text)
echo "ロールARN: $ROLE_ARN"

# レイヤー用パッケージを作成
echo "レイヤー用パッケージを作成中..."
rm -rf layer
mkdir -p layer/python

# 依存パッケージをインストール（python/ディレクトリ構造）
if [ -f requirements.txt ]; then
    echo "依存パッケージをインストール中..."
    pip install -r requirements.txt -t layer/python/
fi

# レイヤー用ZIPファイルを作成
cd layer
zip -r ../layer.zip .
cd ..

echo "レイヤー用パッケージの作成が完了しました。"

# Lambdaレイヤーを作成・更新
echo "Lambdaレイヤーを作成・更新中..."
LAYER_VERSION_ARN=$(aws lambda publish-layer-version \
    --layer-name "$LAYER_NAME" \
    --compatible-runtimes "$RUNTIME" \
    --zip-file fileb://layer.zip \
    --region "$REGION" \
    --query 'LayerVersionArn' \
    --output text)

echo "レイヤーARN: $LAYER_VERSION_ARN"

# Lambda関数用パッケージを作成（関数コードのみ）
echo "Lambda関数用パッケージを作成中..."
rm -rf package
rm -f lambda_function.zip
mkdir -p package

# Lambda関数コードをパッケージに追加
cp lambda_function.py package/

# ZIPファイルを作成
cd package
zip -r ../lambda_function.zip .
cd ..

echo "Lambda関数用パッケージの作成が完了しました。"

# Lambda関数の存在確認
echo "Lambda関数を確認中..."
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Lambda関数を更新中..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://lambda_function.zip \
        --region "$REGION"

    # 関数の更新完了を待機
    echo "関数の更新完了を待機中..."
    aws lambda wait function-updated --function-name "$FUNCTION_NAME" --region "$REGION"

    echo "Lambda関数の設定を更新中..."
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --runtime "$RUNTIME" \
        --handler "$HANDLER" \
        --timeout 30 \
        --layers "$LAYER_VERSION_ARN" \
        --region "$REGION"
else
    echo "Lambda関数を作成中..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime "$RUNTIME" \
        --role "$ROLE_ARN" \
        --handler "$HANDLER" \
        --zip-file fileb://lambda_function.zip \
        --timeout 30 \
        --layers "$LAYER_VERSION_ARN" \
        --region "$REGION"
fi

echo ""
echo "=== デプロイ完了 ==="
echo "関数名: $FUNCTION_NAME"
echo "レイヤー名: $LAYER_NAME"
echo "レイヤーARN: $LAYER_VERSION_ARN"
echo "リージョン: $REGION"
echo ""
echo "マネジメントコンソールでテストしてください："
echo "https://${REGION}.console.aws.amazon.com/lambda/home?region=${REGION}#/functions/$FUNCTION_NAME"
