# reports

## tournament_report.ex
大会の通報に関するスキーマファイルです。
通報が行われるとdiscordに通知が行くようになっています。

### fields

| フィールド名 | 説明 |
| --- | --- |
| reporter_id | 通報者のユーザーid |
| master_id | 大会の開催者のid |
| platform_id | プラットフォームのid |
| report_type | 通報の種類 |
| capacity | 大会の人数 |
| deadline | 大会の参加募集締め切り日時 |
| description | 大会の説明 |
| event_date | 大会の開催日 |
| name | 大会名 |
| type | 大会の種類 |
| url | 大会のurl |
| thumbnail_path | 大会のサムネイル画像のパス |
| count | 大会の参加人数 |
| game_name | 大会で利用するゲームの名前 |
| start_recruiting | 大会の参加募集開始日時 |

## user_report.ex
ユーザーの通報に関するスキーマファイルです。
通報が行われるとdiscordに通知が行くようになっています。

### fields

| フィールド名 | 説明 |
| --- | --- |
| reporter_id | 通報者のid |
| reportee_id | 通報されたユーザーのid |
| report_type | 通報の種類 |