#!/bin/bash

# Lambda関数クリーンアップスクリプト（コンテナイメージ版）

set -e

# 設定
FUNCTION_NAME="lambda-deploy-test-container"
ROLE_NAME="lambda-deploy-test-role"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ECR_REPO_NAME="lambda-deploy-test"

echo "=== Lambda関数クリーンアップスクリプト (コンテナイメージ版) ==="

# Lambda関数の削除
echo "=== Lambda関数を確認中 ==="
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Lambda関数を削除中..."
    aws lambda delete-function \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION"
    echo "Lambda関数を削除しました。"
else
    echo "Lambda関数は存在しません。"
fi

# ECRリポジトリの削除
echo "=== ECRリポジトリを確認中 ==="
if aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "ECRリポジトリを削除中（イメージも含む）..."
    aws ecr delete-repository \
        --repository-name "$ECR_REPO_NAME" \
        --force \
        --region "$REGION"
    echo "ECRリポジトリを削除しました。"
else
    echo "ECRリポジトリは存在しません。"
fi

# IAMロールの削除
echo "=== IAMロールを確認中 ==="
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "IAMロールからポリシーをデタッチ中..."
    # アタッチされているポリシーを取得してデタッチ
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$ROLE_NAME" \
        --query 'AttachedPolicies[].PolicyArn' \
        --output text)

    for POLICY_ARN in $ATTACHED_POLICIES; do
        echo "ポリシーをデタッチ中: $POLICY_ARN"
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "$POLICY_ARN"
    done

    echo "IAMロールを削除中..."
    aws iam delete-role \
        --role-name "$ROLE_NAME"
    echo "IAMロールを削除しました。"
else
    echo "IAMロールは存在しません。"
fi

# ローカルDockerイメージの削除
echo "=== ローカルDockerイメージをクリーンアップ中 ==="
docker rmi "${ECR_REPO_NAME}:latest" 2>/dev/null || true
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -n "$ACCOUNT_ID" ]; then
    docker rmi "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:latest" 2>/dev/null || true
fi

rm -f /tmp/trust-policy.json

echo ""
echo "=== クリーンアップ完了 ==="
