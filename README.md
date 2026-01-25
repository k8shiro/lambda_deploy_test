# AWS Lambda デプロイ方法 比較プロジェクト

AWS Lambdaをデプロイする様々な方法を実装し、それぞれの特徴を比較するためのプロジェクトです。

## 概要

このリポジトリでは、以下のデプロイ方法の実装例を提供します。各方法の長所・短所を理解し、プロジェクトに最適な方法を選択するための参考資料としてご利用ください。

## デプロイ方法一覧

### 1. AWS CLI
- シンプルで直接的なデプロイ方法
- ZIPファイルベースのデプロイ
- スクリプトで自動化可能

### 2. AWS SAM (Serverless Application Model)
- AWS公式のサーバーレスアプリケーション管理ツール
- CloudFormationベースのインフラ管理

### 3. Serverless Framework
- サードパーティの人気フレームワーク
- シンプルな設定ファイル（serverless.yml）

### 4. Terraform
- Infrastructure as Code (IaC)ツール

### 5. AWS CDK (Cloud Development Kit)
- プログラミング言語でインフラを定義

### 6. コンテナイメージ
- Docker imageを使用したデプロイ
- カスタムランタイム環境


## ディレクトリ構造

```
lambda_deploy_test/
├── aws_cli/           # AWS CLIを使用したデプロイ
├── aws_sam/           # AWS SAMを使用したデプロイ
├── serverless/        # Serverless Frameworkを使用したデプロイ
├── terraform/         # Terraformを使用したデプロイ
├── aws_cdk/           # AWS CDKを使用したデプロイ
├── container/         # コンテナイメージを使用したデプロイ
└── README.md
```



