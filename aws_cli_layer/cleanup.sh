#!/bin/bash

# Lambda関数クリーンアップスクリプト（レイヤー版）

set -e

# 設定
FUNCTION_NAME="lambda-deploy-test-cli-layer"
LAYER_NAME="lambda-deploy-test-layer"
ROLE_NAME="lambda-deploy-test-role"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "=== Lambda関数クリーンアップスクリプト (AWS CLI - レイヤー版) ==="

# Lambda関数の削除
echo "Lambda関数を確認中..."
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "Lambda関数を削除中..."
    aws lambda delete-function \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION"
    echo "Lambda関数を削除しました。"
else
    echo "Lambda関数は存在しません。"
fi

# Lambdaレイヤーの削除（全バージョン）
echo "Lambdaレイヤーを確認中..."
LAYER_VERSIONS=$(aws lambda list-layer-versions \
    --layer-name "$LAYER_NAME" \
    --region "$REGION" \
    --query 'LayerVersions[].Version' \
    --output text 2>/dev/null || echo "")

if [ -n "$LAYER_VERSIONS" ]; then
    echo "Lambdaレイヤーを削除中..."
    for VERSION in $LAYER_VERSIONS; do
        echo "レイヤーバージョン $VERSION を削除中..."
        aws lambda delete-layer-version \
            --layer-name "$LAYER_NAME" \
            --version-number "$VERSION" \
            --region "$REGION"
    done
    echo "Lambdaレイヤーを削除しました。"
else
    echo "Lambdaレイヤーは存在しません。"
fi

# IAMロールの削除
echo "IAMロールを確認中..."
if aws iam get-role --role-name "$ROLE_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "IAMロールからポリシーをデタッチ中..."
    # アタッチされているポリシーを取得してデタッチ
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$ROLE_NAME" \
        --region "$REGION" \
        --query 'AttachedPolicies[].PolicyArn' \
        --output text)

    for POLICY_ARN in $ATTACHED_POLICIES; do
        echo "ポリシーをデタッチ中: $POLICY_ARN"
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "$POLICY_ARN" \
            --region "$REGION"
    done

    echo "IAMロールを削除中..."
    aws iam delete-role \
        --role-name "$ROLE_NAME" \
        --region "$REGION"
    echo "IAMロールを削除しました。"
else
    echo "IAMロールは存在しません。"
fi

# ローカルファイルのクリーンアップ
echo "ローカルファイルをクリーンアップ中..."
rm -rf package
rm -rf layer
rm -f lambda_function.zip
rm -f layer.zip
rm -f /tmp/trust-policy.json

echo ""
echo "=== クリーンアップ完了 ==="
