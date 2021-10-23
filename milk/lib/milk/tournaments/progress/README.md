# tournament_progress
大会の進行に関するスキーマファイル群です。

## battle_royale_log.ex
バトロワ形式のときの大会の経過を扱うためのスキーマファイルです。

### fields

| フィールド名 | 説明 |
| --- | --- |
| tournament_id | 大会id |
| loser_id | 敗北したユーザーのid |
| rank | 敗北したユーザーの敗北時ランク |

## best_of_x_tournametn_match_log.ex
Best-of方式のときの大会の経過を扱うためのスキーマファイルです。

### fields

| フィールド名 | 説明 |
| --- | --- |
| tournament_id | 大会id |
| winner_id | 勝利したユーザーのid |
| loser_id | 敗北したユーザーのid |
| winner_score | 勝利したユーザーのスコア |
| loser_score | 敗北したユーザーのスコア |
| match_index | どのマッチだったかを示すindex |

## single_tournament_match_log.ex
シングル対戦のときの大会の経過を扱うためのスキーマファイルです。

### fields

| フィールド名 | 説明 |
| --- | --- |
| tournament_id | 大会id |
| winner_id | 勝利したユーザーのid |
| loser_id | 敗北したユーザーのid |
| match_list_str | 内部のマッチリストのid |

TODO:
    singleのログ構成は変えたほうが良いかも。