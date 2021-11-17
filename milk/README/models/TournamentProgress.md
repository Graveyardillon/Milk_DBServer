# Tournaments.Progress
大会の経過に関するモデル
redisを使っているため、postgres用に定義したスキーマ以外のものが登場してしまう。

| Tournaments.Progress | 役割 |
| --- | --- |
| BattleRoyaleLog | バトロワ形式用の大会経過ログ |
| BestOfXTournamentMatchLog | Best-of形式の大会経過ログ |
| SingleTournamentMatchLog | シングル形式の大会経過ログ |
