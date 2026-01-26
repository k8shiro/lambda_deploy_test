# Lambda Inspector

デプロイ済みのLambda関数をダウンロードし、インストールされているライブラリを確認するためのツールです。

## 概要

このディレクトリには、Lambda関数のコードをダウンロードして検査するための以下のファイルが含まれています：

- `Dockerfile` - 実行環境用のDockerイメージ
- `inspect.sh` - ダウンロード・検査スクリプト
- `list_packages.py` - ライブラリ一覧表示スクリプト

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

- Lambda関数の読み取り権限（`lambda:GetFunction`）

## 使用方法

### 1. Dockerイメージをビルド

```bash
docker build -t lambda-inspector .
```

### 2. 検査対象の関数名を設定

```bash
FUNCTION_NAME=your-lambda-function-name
```

### 3. コンテナを起動して検査を実行

```bash
docker run --rm -it \
  -v $(pwd):/app \
  --env-file .env \
  -e AWS_PAGER= \
  -e FUNCTION_NAME=${FUNCTION_NAME} \
  lambda-inspector \
  bash -c "chmod +x inspect.sh && ./inspect.sh"
```

## 出力例

```
=== Lambda関数のダウンロード: my-lambda-function ===
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1234k  100 1234k    0     0  1234k      0  0:00:01 --:--:--  0:00:01 1234k
=== ZIPを展開 ===
Archive:  lambda_function.zip
  inflating: lambda_code/lambda_function.py
  ...
=== インストールされているライブラリ ===
requests==2.31.0
urllib3==2.0.4
charset-normalizer==3.2.0
certifi==2023.7.22
idna==3.4
```

## ファイル構成

```
lambda_inspector/
├── .env.example          # 環境変数のサンプル
├── Dockerfile            # 実行環境用Dockerイメージ
├── README.md             # このファイル
├── inspect.sh            # ダウンロード・検査スクリプト
└── list_packages.py      # ライブラリ一覧表示スクリプト
```

## 検査後の成果物

実行後、以下のファイル・ディレクトリが作成されます：

- `lambda_function.zip` - ダウンロードしたLambda関数のZIPファイル
- `lambda_code/` - 展開されたLambda関数のコード

これらを直接確認することで、Lambda関数の詳細な内容を調査できます。

## トラブルシューティング

### AccessDeniedエラー

Lambda関数へのアクセス権限がない場合に発生します。IAMユーザーに`lambda:GetFunction`権限があることを確認してください。

### 関数が見つからない

- 関数名が正しいか確認してください
- リージョンが正しいか確認してください（`.env`の`AWS_DEFAULT_REGION`）
