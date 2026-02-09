#!/bin/bash

# Lambda関数デプロイスクリプト（コンテナイメージ版）

set -e

# 設定
FUNCTION_NAME="lambda-deploy-test-container"
ROLE_NAME="lambda-deploy-test-role"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ECR_REPO_NAME="lambda-deploy-test"
IMAGE_TAG="latest"

echo "=== Lambda関数デプロイスクリプト (コンテナイメージ版) ==="

# AWSアカウントIDを取得
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_URI="${ECR_URI}/${ECR_REPO_NAME}:${IMAGE_TAG}"

echo "AWSアカウントID: $ACCOUNT_ID"
echo "ECR URI: $ECR_URI"

# IAMロールの存在確認
echo "=== IAMロールを確認中 ==="
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
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
        --assume-role-policy-document file:///tmp/trust-policy.json

    # 基本実行ポリシーをアタッチ
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    echo "IAMロールの作成が完了しました。ロールの伝播を待機中（10秒）..."
    sleep 10
else
    echo "IAMロールは既に存在します。"
fi

# ロールARNを取得
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo "ロールARN: $ROLE_ARN"

# ECRリポジトリの存在確認
echo "=== ECRリポジトリを確認中 ==="
if ! aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "ECRリポジトリを作成中..."
    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region "$REGION"
    echo "ECRリポジトリを作成しました。"
else
    echo "ECRリポジトリは既に存在します。"
fi

# ECRにログイン
echo "=== ECRにログイン中 ==="
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URI"

# Dockerイメージをビルド
echo "=== Dockerイメージをビルド中 ==="
docker build -t "${ECR_REPO_NAME}:${IMAGE_TAG}" -f Dockerfile.lambda .

# イメージにタグを付ける
echo "=== イメージにタグを付与中 ==="
docker tag "${ECR_REPO_NAME}:${IMAGE_TAG}" "$IMAGE_URI"

# ECRにプッシュ
echo "=== ECRにプッシュ中 ==="
docker push "$IMAGE_URI"

# Lambda関数の存在確認
echo "=== Lambda関数を確認中 ==="
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Lambda関数を更新中..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --image-uri "$IMAGE_URI" \
        --region "$REGION"

    # 関数の更新完了を待機
    echo "関数の更新完了を待機中..."
    aws lambda wait function-updated --function-name "$FUNCTION_NAME" --region "$REGION"
else
    echo "Lambda関数を作成中..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --package-type Image \
        --code ImageUri="$IMAGE_URI" \
        --role "$ROLE_ARN" \
        --timeout 30 \
        --region "$REGION"

    # 関数の作成完了を待機
    echo "関数の作成完了を待機中..."
    aws lambda wait function-active --function-name "$FUNCTION_NAME" --region "$REGION"
fi

echo ""
echo "=== デプロイ完了 ==="
echo "関数名: $FUNCTION_NAME"
echo "イメージURI: $IMAGE_URI"
echo "リージョン: $REGION"
echo ""
echo "マネジメントコンソールでテストしてください："
echo "https://${REGION}.console.aws.amazon.com/lambda/home?region=${REGION}#/functions/$FUNCTION_NAME"
