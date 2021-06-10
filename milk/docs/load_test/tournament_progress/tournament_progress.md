# 大会進行

ループ
- 大会情報取得
- 対戦相手の情報取得
- state取得
    - isAloneなら待つ
    - isLoserなら終了
    - isPendingならリクエストを送信
    - isFinishedなら終了
    - isAssistantかisManagerなら終了
ループ