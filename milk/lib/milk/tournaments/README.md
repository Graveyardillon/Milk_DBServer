# tournaments
大会に関するスキーマ群

## assistant.ex
大会のアシスタントに関するスキーマ

### fields

| フィールド名 | 説明 |
| --- | --- |
| tournament_id | どの大会のアシスタントなのかを表すtournament_id |
| user_id | 誰がアシスタントなのかを表すユーザーid |

## entrant.ex
参加者に関するスキーマ

### fields

| フィールド名 | 説明 |
| --- | --- |
| rank | 参加者の現在のランク |
| tournament_id | 参加している大会のid |
| user_id | 参加者のユーザーid |

## tournament_chat_topic.ex
大会のグループチャットのtopicに関するスキーマ

### fields

| フィールド名 | 説明 |
| --- | --- |
| topic_name | topicの名前 |
| tab_index | topicのタブが並べられている順番を管理するためのフィールド |
| tournament_id | 大会のid |
| chat_room_id | 関連付いたチャットルームのid |

## team.ex
大会に参加するチームについてのスキーマ
チームで参加するタイプの大会はentrantの代わりにteamを利用すると考えて良い
### fields

| フィールド名 | 説明 |
| --- | --- |
| name | チーム名 |
| size | チームの最大人数 |
| tournament_id | 参加する大会のid |

## team_invitation.ex
大会に参加するチームの招待についてのスキーマ

### fields
| フィールド名 | 説明 |
| --- | --- |
| destination_id | 宛先ユーザーのid |
| sender_id | 差出人ユーザーのid |
| team_id | 招待しているチームのid |
| text | 招待の文章 |

## team_member.ex
大会に参加するチームのメンバーについてのスキーマ

### fields
 | フィールド名 | 説明 |
 | --- | --- |
 | user_id | メンバーのユーザーid |
 | team_id | 所属しているチームのid |
 | is_leader | チームのリーダーかどうか |

## tournament.ex
大会自体のスキーマ

## fields

| フィールド名 | 説明 |
| --- | --- |
| capacity | 大会に参加できる上限人数 |
| deadline | 大会の参加可能締め切り |
| description | 大会の説明 |
| event_date | 大会の開催日時 |
| name | 大会名 |
| type | 大会の開催種類 |
| url | 大会をアプリで直接開くことのできるurl |
| thumbnail_path | 大会のサムネイル画像が格納されている場所へのパスもしくはurl |
| password | 大会のパスワード |
| count | 大会の参加人数、チーム数 |
| game_name | 大会で扱うゲームのタイトル |
| is_started | 大会がすでに開始しているかどうかのbool |
| start_recruiting | 大会の募集開始日時 |
| platform_id | 大会の扱うプラットフォームのid |
| game_id | （今は使われていない）扱っているゲームのid |
| master_id | 大会を開催したユーザーのid |

### type
