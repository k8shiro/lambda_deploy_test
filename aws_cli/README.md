# AWS CLI を使用した Lambda デプロイ

AWS CLIを直接使用してLambda関数をデプロイする方法です。

## 概要

このディレクトリには、AWS CLIを使用してLambda関数をデプロイするための以下のファイルが含まれています：

- `lambda_function.py` - Lambda関数のコード（外部パッケージrequestsを使用）
- `requirements.txt` - Pythonパッケージの依存関係
- `Dockerfile` - デプロイ環境用のDockerイメージ
- `deploy.sh` - デプロイスクリプト
- `cleanup.sh` - リソース削除スクリプト

## 前提条件

### AWS認証情報

以下のいずれかの方法でAWS認証情報を設定してください：

1. 環境変数を使用
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

2. AWS CLIの設定ファイルを使用
```bash
aws configure
```

### 必要な権限

使用するIAMユーザーには以下の権限が必要です：

- Lambda関数の作成・更新・削除
- IAMロールの作成・削除
- IAMポリシーのアタッチ・デタッチ

## デプロイ方法

### オプション1: Dockerを使用

1. Dockerイメージをビルド
```bash
docker build -t lambda-deploy-cli .
```

2. コンテナを起動してデプロイ
```bash
docker run --rm -it \
  -v $(pwd):/app \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  lambda-deploy-cli \
  bash -c "chmod +x deploy.sh && ./deploy.sh"
```

### オプション2: ローカル環境で直接実行

前提条件：
- AWS CLI v2がインストールされていること
- Python 3.12がインストールされていること

```bash
chmod +x deploy.sh
./deploy.sh
```

## デプロイスクリプトの動作

`deploy.sh`スクリプトは以下の処理を行います：

1. IAMロールの確認・作成
   - ロール名: `lambda-deploy-test-role`
   - Lambda基本実行ポリシーをアタッチ

2. デプロイパッケージの作成
   - requirements.txtから依存パッケージをインストール
   - Lambda関数コードと依存パッケージをZIP化

3. Lambda関数の作成または更新
   - 関数名: `lambda-deploy-test-cli`
   - ランタイム: Python 3.12
   - リージョン: ap-northeast-1

## 動作確認

デプロイ完了後、以下の方法で動作を確認できます：

### マネジメントコンソールでテスト

1. [Lambda コンソール](https://ap-northeast-1.console.aws.amazon.com/lambda/home?region=ap-northeast-1#/functions/lambda-deploy-test-cli)にアクセス

2. 「テスト」タブを開く

3. テストイベントを作成（イベント名は任意、JSONは空の`{}`でOK）

4. 「テスト」ボタンをクリック

5. 実行結果を確認
   - 外部APIからのデータ取得
   - requestsパッケージのバージョン
   - タイムスタンプ

### AWS CLIでテスト

```bash
aws lambda invoke \
  --function-name lambda-deploy-test-cli \
  --region ap-northeast-1 \
  --payload '{}' \
  response.json

cat response.json
```

## クリーンアップ

作成したリソースを削除する場合：

### Dockerを使用

```bash
docker run --rm -it \
  -v $(pwd):/app \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  lambda-deploy-cli \
  bash -c "chmod +x cleanup.sh && ./cleanup.sh"
```

### ローカル環境で直接実行

```bash
chmod +x cleanup.sh
./cleanup.sh
```

以下のリソースが削除されます：
- Lambda関数 (`lambda-deploy-test-cli`)
- IAMロール (`lambda-deploy-test-role`)
- ローカルの一時ファイル（package/, lambda_function.zip）

## ファイル構成

```
aws_cli/
├── Dockerfile              # デプロイ環境用Dockerイメージ
├── README.md               # このファイル
├── cleanup.sh              # クリーンアップスクリプト
├── deploy.sh               # デプロイスクリプト
├── lambda_function.py      # Lambda関数コード
└── requirements.txt        # Pythonパッケージ依存関係
```

## トラブルシューティング

### デプロイパッケージが大きすぎる場合

Lambda関数のデプロイパッケージは50MB（圧縮後）の制限があります。依存パッケージが大きい場合は以下の対策を検討してください：

- 不要なパッケージを削除
- Lambdaレイヤーを使用
- コンテナイメージを使用（`../container/`を参照）

### IAMロールの権限エラー

IAMロールの作成・削除権限がない場合は、AWS管理者に依頼してロールを事前に作成してもらい、スクリプト内のロール作成部分をスキップするよう修正してください。

### タイムアウトエラー

Lambda関数のタイムアウトはデフォルトで30秒に設定されています。処理時間がかかる場合は、`deploy.sh`内の`--timeout`値を増やしてください。

## 参考資料

- [AWS CLI Lambda コマンドリファレンス](https://docs.aws.amazon.com/cli/latest/reference/lambda/)
- [Lambda デプロイパッケージ](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
