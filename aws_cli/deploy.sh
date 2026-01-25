#!/bin/bash

# Lambda関数デプロイスクリプト

set -e

# 設定
FUNCTION_NAME="lambda-deploy-test-cli"
ROLE_NAME="lambda-deploy-test-role"
REGION="ap-northeast-1"
RUNTIME="python3.12"
HANDLER="lambda_function.lambda_handler"

echo "=== Lambda関数デプロイスクリプト (AWS CLI) ==="

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

# デプロイパッケージを作成
echo "デプロイパッケージを作成中..."
rm -rf package
rm -f lambda_function.zip

# 依存パッケージをインストール
if [ -f requirements.txt ]; then
    echo "依存パッケージをインストール中..."
    pip install -r requirements.txt -t package/
else
    mkdir -p package
fi

# Lambda関数コードをパッケージに追加
cp lambda_function.py package/

# ZIPファイルを作成
cd package
zip -r ../lambda_function.zip .
cd ..

echo "デプロイパッケージの作成が完了しました。"

# Lambda関数の存在確認
echo "Lambda関数を確認中..."
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Lambda関数を更新中..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://lambda_function.zip \
        --region "$REGION"

    echo "Lambda関数の設定を更新中..."
    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --runtime "$RUNTIME" \
        --handler "$HANDLER" \
        --timeout 30 \
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
        --region "$REGION"
fi

echo ""
echo "=== デプロイ完了 ==="
echo "関数名: $FUNCTION_NAME"
echo "リージョン: $REGION"
echo ""
echo "マネジメントコンソールでテストしてください："
echo "https://ap-northeast-1.console.aws.amazon.com/lambda/home?region=ap-northeast-1#/functions/$FUNCTION_NAME"
