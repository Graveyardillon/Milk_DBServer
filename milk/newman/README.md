# newman
DBにテストデータを自動で挿入します。

## Usage

```
newman run data_setup.json
```

もしくは

```
sh insert_all.sh
```

いくつかのjsonは単体で使用されることが考慮されていません。
`insert_all.sh`を使っておけば大丈夫でしょう。