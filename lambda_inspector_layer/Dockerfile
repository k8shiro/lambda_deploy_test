FROM python:3.12-slim

# 作業ディレクトリを設定
WORKDIR /app

# 必要なパッケージをインストール
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2をインストール
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# 作業用のディレクトリをマウントポイントとして使用
VOLUME /app

# デフォルトコマンド
CMD ["/bin/bash"]
