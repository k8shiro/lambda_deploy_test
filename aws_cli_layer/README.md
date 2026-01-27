# AWS CLI を使用した Lambda デプロイ（レイヤー版）

AWS CLIを使用してLambda関数をデプロイする方法です。依存パッケージはLambdaレイヤーとして分離してデプロイします。

## 概要

このディレクトリには、AWS CLIを使用してLambda関数とレイヤーをデプロイするための以下のファイルが含まれています：

- `lambda_function.py` - Lambda関数のコード（外部パッケージrequestsを使用）
- `requirements.txt` - Pythonパッケージの依存関係（レイヤーに含まれる）
- `Dockerfile` - デプロイ環境用のDockerイメージ
- `deploy.sh` - デプロイスクリプト
- `cleanup.sh` - リソース削除スクリプト

## レイヤーを使用するメリット

- 関数コードのZIPサイズを削減（デプロイが高速化）
- 複数のLambda関数で同じレイヤーを共有可能
- 依存パッケージの更新が容易（レイヤーのみ更新）

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

※ `.env`ファイルはGitにコミットしないでください（`.gitignore`に追加済み）

### 必要な権限

使用するIAMユーザーには以下の権限が必要です：

- Lambda関数の作成・更新・削除
- Lambdaレイヤーの作成・削除
- IAMロールの作成・削除
- IAMポリシーのアタッチ・デタッチ

## デプロイ方法

### 1. Dockerイメージをビルド

```bash
docker build -t lambda-deploy-cli-layer .
```

### 2. コンテナを起動してデプロイ

```bash
docker run --rm -it \
  -v $(pwd):/app \
  --env-file .env \
  -e AWS_PAGER= \
  lambda-deploy-cli-layer \
  bash -c "chmod +x deploy.sh && ./deploy.sh"
```

## デプロイスクリプトの動作

`deploy.sh`スクリプトは以下の処理を行います：

1. IAMロールの確認・作成
   - ロール名: `lambda-deploy-test-role`
   - Lambda基本実行ポリシーをアタッチ

2. レイヤー用パッケージの作成
   - requirements.txtから依存パッケージをインストール
   - `python/`ディレクトリ構造でZIP化

3. Lambdaレイヤーの作成・更新
   - レイヤー名: `lambda-deploy-test-layer`

4. Lambda関数用パッケージの作成
   - 関数コードのみをZIP化（依存パッケージは含まない）

5. Lambda関数の作成・更新
   - 関数名: `lambda-deploy-test-cli-layer`
   - ランタイム: Python 3.12
   - リージョン: .envで指定したリージョン（デフォルト: us-east-1）
   - レイヤーを紐付け

## 動作確認

デプロイ完了後、以下の方法で動作を確認できます：

### マネジメントコンソールでテスト

1. デプロイ完了時に表示されるLambdaコンソールのURLにアクセス

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
  --function-name lambda-deploy-test-cli-layer \
  --region us-east-1 \
  --payload '{}' \
  response.json

cat response.json
```

## クリーンアップ

作成したリソースを削除する場合：

```bash
docker run --rm -it \
  -v $(pwd):/app \
  --env-file .env \
  -e AWS_PAGER= \
  lambda-deploy-cli-layer \
  bash -c "chmod +x cleanup.sh && ./cleanup.sh"
```

以下のリソースが削除されます：
- Lambda関数 (`lambda-deploy-test-cli-layer`)
- Lambdaレイヤー (`lambda-deploy-test-layer`) の全バージョン
- IAMロール (`lambda-deploy-test-role`)
- ローカルの一時ファイル（package/, layer/, lambda_function.zip, layer.zip）

## ファイル構成

```
aws_cli_layer/
├── .env.example            # 環境変数のサンプル
├── .gitignore              # ビルド成果物の除外
├── Dockerfile              # デプロイ環境用Dockerイメージ
├── README.md               # このファイル
├── cleanup.sh              # クリーンアップスクリプト
├── deploy.sh               # デプロイスクリプト
├── lambda_function.py      # Lambda関数コード
└── requirements.txt        # Pythonパッケージ依存関係
```

## aws_cli/との違い

| 項目 | aws_cli/ | aws_cli_layer/ |
|------|----------|----------------|
| 依存パッケージ | 関数コードと一緒にZIP | レイヤーとして分離 |
| 関数ZIPサイズ | 大きい | 小さい（コードのみ） |
| 依存更新 | 関数全体を再デプロイ | レイヤーのみ更新 |
| 共有 | 不可 | 複数関数で共有可能 |

## トラブルシューティング

### デプロイパッケージが大きすぎる場合

Lambdaレイヤーは250MB（解凍後）の制限があります。依存パッケージが大きい場合は以下の対策を検討してください：

- 不要なパッケージを削除
- 複数のレイヤーに分割
- コンテナイメージを使用（`../container/`を参照）

### IAMロールの権限エラー

IAMロールの作成・削除権限がない場合は、AWS管理者に依頼してロールを事前に作成してもらい、スクリプト内のロール作成部分をスキップするよう修正してください。

### レイヤーが見つからないエラー

Lambda関数の設定更新時にレイヤーARNが正しく設定されていることを確認してください。レイヤーは同じリージョンに存在する必要があります。

## 参考資料

- [AWS CLI Lambda コマンドリファレンス](https://docs.aws.amazon.com/cli/latest/reference/lambda/)
- [Lambda レイヤーの作成と管理](https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html)
- [Lambda デプロイパッケージ](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
