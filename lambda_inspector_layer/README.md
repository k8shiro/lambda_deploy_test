# Lambda Inspector（レイヤー対応版）

デプロイ済みのLambda関数とそのレイヤーをダウンロードし、インストールされているライブラリを確認するためのツールです。

## 概要

このディレクトリには、Lambda関数とレイヤーのコードをダウンロードして検査するための以下のファイルが含まれています：

- `Dockerfile` - 実行環境用のDockerイメージ
- `inspect.sh` - ダウンロード・検査スクリプト（レイヤー対応）
- `list_packages.py` - ライブラリ一覧表示スクリプト

## lambda_inspector/との違い

| 項目 | lambda_inspector/ | lambda_inspector_layer/ |
|------|-------------------|-------------------------|
| 関数コード | ダウンロード可 | ダウンロード可 |
| レイヤー | 非対応 | 対応 |
| ライブラリ確認 | 関数内のみ | 関数＋レイヤー |

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
- Lambdaレイヤーの読み取り権限（`lambda:GetLayerVersion`）

## 使用方法

### 1. Dockerイメージをビルド

```bash
docker build -t lambda-inspector-layer .
```

### 2. 検査対象の関数名を設定

```bash
FUNCTION_NAME=your-lambda-function-name
```

### 3. コンテナを起動して検査を実行

```bash
docker run --rm \
  -v $(pwd):/app \
  --env-file .env \
  -e AWS_PAGER= \
  -e FUNCTION_NAME=${FUNCTION_NAME} \
  lambda-inspector-layer \
  bash -c "chmod +x inspect.sh && ./inspect.sh"
```

## 出力例

### レイヤーを使用している関数の場合

```
=== Lambda関数の検査（レイヤー対応版）: lambda-deploy-test-cli-layer ===
=== Lambda関数の情報を取得中 ===
=== Lambda関数のコードをダウンロード ===
=== Lambda関数のコードを展開 ===
=== レイヤー情報を取得中 ===
使用されているレイヤー:
  - arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1
    ダウンロード中...
    展開中...

=== インストールされているライブラリ ===
requests==2.31.0
urllib3==2.0.4
charset-normalizer==3.2.0
certifi==2023.7.22
idna==3.4

=== 検査完了 ===
関数コード: lambda_code/
レイヤー: layers/
```

### レイヤーを使用していない関数の場合

```
=== Lambda関数の検査（レイヤー対応版）: lambda-deploy-test-cli ===
=== Lambda関数の情報を取得中 ===
=== Lambda関数のコードをダウンロード ===
=== Lambda関数のコードを展開 ===
=== レイヤー情報を取得中 ===
レイヤーは使用されていません。

=== インストールされているライブラリ ===
requests==2.31.0
...

=== 検査完了 ===
関数コード: lambda_code/
```

## ファイル構成

```
lambda_inspector_layer/
├── .env.example          # 環境変数のサンプル
├── .gitignore            # 成果物の除外
├── Dockerfile            # 実行環境用Dockerイメージ
├── README.md             # このファイル
├── inspect.sh            # ダウンロード・検査スクリプト（レイヤー対応）
└── list_packages.py      # ライブラリ一覧表示スクリプト
```

## 検査後の成果物

実行後、以下のファイル・ディレクトリが作成されます：

- `lambda_function.zip` - ダウンロードしたLambda関数のZIPファイル
- `lambda_code/` - 展開されたLambda関数のコード
- `layers/` - 展開されたレイヤーのコード（レイヤーがある場合）
  - `layer_1/` - 1つ目のレイヤー
  - `layer_2/` - 2つ目のレイヤー（複数ある場合）
  - ...

これらを直接確認することで、Lambda関数とレイヤーの詳細な内容を調査できます。

## トラブルシューティング

### AccessDeniedエラー

Lambda関数またはレイヤーへのアクセス権限がない場合に発生します。IAMユーザーに以下の権限があることを確認してください：
- `lambda:GetFunction`
- `lambda:GetLayerVersion`

### 関数が見つからない

- 関数名が正しいか確認してください
- リージョンが正しいか確認してください（`.env`の`AWS_DEFAULT_REGION`）

### レイヤーのライブラリが表示されない

- レイヤーが`python/`ディレクトリ構造でパッケージされているか確認してください
- Lambda関数とレイヤーのPythonランタイムバージョンが一致しているか確認してください
