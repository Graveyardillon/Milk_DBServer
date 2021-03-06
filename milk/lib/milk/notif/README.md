# notif
通知に関連するモジュール群です

## notification.ex
通知に関するスキーマファイルです。

### fields

| フィールド名 | 説明 |
| --- | --- |
| content | お知らせ内容 |
| process_code | 通知の後で処理をすることがあるので、それに使うコード |
| data | 通知の後の処理に使うデータ |
| user_id | 誰に向けての通知なのかを表すユーザーid |