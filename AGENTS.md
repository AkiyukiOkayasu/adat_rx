# AGENTS.md

## ルール

- コメントやプランは日本語で記述する
- Makefileは使用しない。タスクは`justfile`で管理する
- `just build`/`just run`の前に`veryl fmt`が自動実行されるように保つ
- VerylのドキュメンテーションコメントではWavedromを使う
- SV lint（svls）は実行し、警告があれば記録する

## 現在の状況

### 実装完了済み

- `justfile`によるタスク管理
- 全モジュールのwavedromドキュメント追加
- `sim/verilator/justfile`に`veryl fmt`自動実行設定済み
- `sim/verilator/justfile`にユニットテスト一括タスク追加
- ✅ ADAT受信機能（8チャンネル24bit + user data）
- ✅ 厳密比較テストパス
- ✅ 全ユニットテストパス

### 解決済みの問題

- ~~シミュレーション: レシーバーがロックできない~~ → テストベンチ修正で解決
- ~~厳密比較テストのパス~~ → 完了
- ~~frame_parserのビット順整合~~ → user data抽出のビット順修正で解決
- 詳細は`debug_log.md`を参照

### 残りのタスク（任意）

- SV lint警告の修正（11件、全て軽微）
