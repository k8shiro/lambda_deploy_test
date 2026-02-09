"""
Lambda関数のサンプルコード

外部パッケージ（requests, pyfiglet）を使用するシンプルな例
依存パッケージはLambdaレイヤーから提供される
"""

import json
import requests
import pyfiglet
from datetime import datetime


def lambda_handler(event, context):
    """
    Lambda関数のエントリーポイント

    Args:
        event: Lambda関数に渡されるイベントデータ
        context: Lambda関数の実行コンテキスト

    Returns:
        dict: ステータスコードとボディを含むレスポンス
    """

    # 現在時刻を取得
    current_time = datetime.now().isoformat()

    # pyfigletでアスキーアートを生成
    ascii_art = pyfiglet.figlet_format("Hello Lambda!")

    # 外部パッケージ（requests）を使用した例
    try:
        # JSONPlaceholderの公開APIを使用
        response = requests.get('https://jsonplaceholder.typicode.com/posts/1', timeout=5)
        api_data = response.json()

        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Hello from Lambda (deployed via AWS CLI with Layer)!',
                'ascii_art': ascii_art,
                'timestamp': current_time,
                'external_api_response': {
                    'title': api_data.get('title'),
                    'userId': api_data.get('userId')
                },
                'requests_version': requests.__version__,
                'pyfiglet_version': pyfiglet.__version__
            }, ensure_ascii=False)
        }

    except Exception as e:
        result = {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error occurred',
                'error': str(e),
                'timestamp': current_time
            }, ensure_ascii=False)
        }

    return result
