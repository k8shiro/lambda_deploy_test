# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

AWS Lambdaのデプロイ方法を複数実装し、それぞれの特徴を比較するためのプロジェクト。各デプロイ方法の実装例、手順、メリット・デメリットを提供する。

## ディレクトリ構造

各デプロイ方法ごとに独立したディレクトリを持つ：

- `aws_cli/` - AWS CLIを使用したデプロイ
- `aws_sam/` - AWS SAMを使用したデプロイ
- `serverless/` - Serverless Frameworkを使用したデプロイ
- `terraform/` - Terraformを使用したデプロイ
- `aws_cdk/` - AWS CDKを使用したデプロイ
- `container/` - コンテナイメージを使用したデプロイ
- `github_actions/` - GitHub Actionsを使用したCI/CD

各ディレクトリには以下が含まれる：
- README.md（手順、メリット・デメリット）
- Dockerfile（実行環境）
- Lambda関数コード（Python 3.12）
- requirements.txt（外部パッケージ依存関係）
- デプロイスクリプト

## アーキテクチャ方針

- 全てのデプロイ方法で同一のLambda関数を使用（比較の公平性）
- Lambda関数は外部Pythonパッケージを使用する例を含める
- API Gatewayなどの他のAWSリソースは作成しない
- 動作確認はマネジメントコンソール上のテストイベントで実施

## ブランチ戦略

- `main` - 本番環境相当
- `feature/*` - 機能追加用ブランチ
  - featureブランチはmainから作成
  - issueに対応する場合はissue番号を含める（例：`1-aws-cli-deploy`）

## コーディング規約

- Docstringsやコメントは日本語で記述
- docker-composeでvolumesを使う場合はバインドマウントを使用

## GitHub操作

- GitHub操作にはGitHub MCPを使用すること