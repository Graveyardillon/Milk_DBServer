# マップBANとコイントス付きトーナメントの処理の流れ

大会スタートまで (IsNotStarted)
====
マッチが表示 (IsInMatch)
コイントス (ShouldFlipCoin)
マップ選択 (ShouldChooseMap)
=== 対戦 ===
スコア報告 (IsPending)
勝利 -> 次の対戦 (IsInMatchに戻る)
敗北 -> 終了 (IsLoser)
===
大会終了 (IsFinished)

# マップBANのみトーナメントの処理の流れ

大会スタートまで (IsNotStarted)
====
マッチが表示 (IsInMatch)
マップ選択 (ShouldChooseMap)
=== 対戦 ===
スコア報告 (IsPending)
勝利 -> 次の対戦 (IsInMatchに戻る)
敗北 -> 終了 (IsLoser)
===
大会終了 (IsFinished)

# BANとかなしトーナメントの処理の流れ

大会スタートまで (IsNotStarted)
====
マッチが表示 (IsInMatch)
=== 対戦 ===
スコア報告 (IsPending)
勝利 -> 次の対戦 (IsInMatchに戻る)
敗北 -> 終了 (IsLoser)
===
大会終了 (IsFinished)