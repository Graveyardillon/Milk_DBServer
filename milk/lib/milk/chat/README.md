# chat

## chats.ex
チャットに関するスキーマファイルです。
チャットはチャットルームの中でチャットメンバーに共有されます。

### fields

| フィールド名 | 説明 |
| --- | --- |
| index | チャットの順番 |
| word | チャット内容の文字列 |
| user_id | チャットを送信したユーザーのid |
| chat_room | 所属しているルームのid |

## chat_room.ex
チャットルームに関するスキーマファイルです。

### fields

| フィールド名 | 説明 |
| --- | --- |
| count | ルームの中のチャットの個数 |
| last_chat | 最後に送信されたチャット |
| name | チャットルームの名前 |
| member_count | ルームに参加しているメンバーの数 |
| is_private | ルームがDMかどうかを判別するためのbool |

## chat_member.ex
ルームに参加したユーザーはチャットメンバーとして扱われます。
これはそのチャットメンバーに関するスキーマファイルです。

## fields

| フィールド名 | 説明 |
| --- | --- |
| authority | チャットメンバーの権限レベル |
| user_id | チャットメンバーのユーザーid |
| chat_room_id | 所属しているルームのid |