# コンテナイメージを使用した Lambda デプロイ

AWS CLIとDockerを使用して、コンテナイメージとしてLambda関数をデプロイする方法です。

## 概要

このディレクトリには、コンテナイメージを使用してLambda関数をデプロイするための以下のファイルが含まれています：

- `lambda_function.py` - Lambda関数のコード（外部パッケージrequestsを使用）
- `requirements.txt` - Pythonパッケージの依存関係
- `Dockerfile.lambda` - Lambda用Dockerイメージ
- `deploy.sh` - デプロイスクリプト
- `cleanup.sh` - リソース削除スクリプト

## ZIPデプロイとの比較

| 項目 | ZIPデプロイ | コンテナイメージ |
|------|------------|------------------|
| 最大サイズ | 50MB（圧縮）/ 250MB（解凍） | 10GB |
| ベースイメージ | AWS提供のランタイム | カスタマイズ可能 |
| OS依存パッケージ | 導入が複雑 | Dockerfileで簡単に導入 |
| ビルド環境 | Lambda互換環境が必要 | Docker環境があればOK |

## 前提条件

### AWS認証情報

`.env`ファイルを作成してAWS認証情報を設定してください：

```bash
cp .env.example .env
```

`.env`ファイルを編集して認証情報を入力：

```
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
```

### 必要な権限

使用するIAMユーザーには以下の権限が必要です：

- Lambda関数の作成・更新・削除
- IAMロールの作成・削除
- IAMポリシーのアタッチ・デタッチ
- ECRリポジトリの作成・削除
- ECRへのイメージプッシュ

### ローカル環境

- Dockerがインストールされていること
- AWS CLIがインストールされていること

## デプロイ方法

### 1. 環境変数を読み込み

```bash
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
```

### 2. デプロイを実行

```bash
chmod +x deploy.sh
./deploy.sh
```

## デプロイスクリプトの動作

`deploy.sh`スクリプトは以下の処理を行います：

1. IAMロールの確認・作成
   - ロール名: `lambda-deploy-test-role`
   - Lambda基本実行ポリシーをアタッチ

2. ECRリポジトリの確認・作成
   - リポジトリ名: `lambda-deploy-test`

3. ECRへのログイン

4. Dockerイメージのビルド
   - `Dockerfile.lambda`を使用
   - AWS Lambda Python 3.12ベースイメージ

5. ECRへのプッシュ

6. Lambda関数の作成・更新
   - 関数名: `lambda-deploy-test-container`
   - パッケージタイプ: Image

## 動作確認

デプロイ完了後、以下の方法で動作を確認できます：

### マネジメントコンソールでテスト

1. デプロイ完了時に表示されるLambdaコンソールのURLにアクセス

2. 「テスト」タブを開く

3. テストイベントを作成（イベント名は任意、JSONは空の`{}`でOK）

4. 「テスト」ボタンをクリック

5. 実行結果を確認

### AWS CLIでテスト

```bash
aws lambda invoke \
  --function-name lambda-deploy-test-container \
  --region us-east-1 \
  --payload '{}' \
  response.json

cat response.json
```

## クリーンアップ

作成したリソースを削除する場合：

```bash
chmod +x cleanup.sh
./cleanup.sh
```

以下のリソースが削除されます：
- Lambda関数 (`lambda-deploy-test-container`)
- ECRリポジトリ (`lambda-deploy-test`) とイメージ
- IAMロール (`lambda-deploy-test-role`)
- ローカルDockerイメージ

## ファイル構成

```
container/
├── .env.example            # 環境変数のサンプル
├── .gitignore              # 除外設定
├── Dockerfile.lambda       # Lambda用Dockerイメージ
├── README.md               # このファイル
├── cleanup.sh              # クリーンアップスクリプト
├── deploy.sh               # デプロイスクリプト
├── lambda_function.py      # Lambda関数コード
└── requirements.txt        # Pythonパッケージ依存関係
```

## Dockerfile.lambdaの解説

```dockerfile
# AWS Lambda Python 3.12 ベースイメージを使用
FROM public.ecr.aws/lambda/python:3.12

# 依存パッケージをインストール
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Lambda関数コードをコピー
COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

# ハンドラーを指定
CMD ["lambda_function.lambda_handler"]
```

- `LAMBDA_TASK_ROOT`: Lambda関数コードの配置先（`/var/task`）
- `CMD`: Lambda関数のハンドラーを指定

## トラブルシューティング

### ECRへのプッシュが失敗する

- AWS認証情報が正しく設定されているか確認
- ECRへのプッシュ権限があるか確認
- `aws ecr get-login-password`でログインできるか確認

### Lambda関数のタイムアウト

コンテナイメージの場合、初回起動（コールドスタート）に時間がかかることがあります。タイムアウト値を増やすことを検討してください。

### イメージサイズが大きい

- 不要なパッケージを削除
- マルチステージビルドを検討
- slim版のベースイメージを使用

## 参考資料

- [コンテナイメージを使用した Lambda 関数のデプロイ](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/images-create.html)
- [AWS Lambda の Python ベースイメージ](https://gallery.ecr.aws/lambda/python)
- [Lambda コンテナイメージのベストプラクティス](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/images-create.html#images-create-best-practices)
