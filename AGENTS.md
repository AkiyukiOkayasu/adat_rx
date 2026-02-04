# AGENTS.md

## ルール

- コメントやプランは日本語で記述する
- Makefileは使用しない。タスクは`justfile`で管理する
- `just build`/`just run`の前に`veryl fmt`が自動実行されるように保つ
- VerylのドキュメンテーションコメントではWavedromを使う
- SV lint（svls）は実行し、警告があれば記録する

## 現在の状況

### 実装完了済み
- `justfile`によるタスク管理（Makefile完全移行済み）
- 全モジュールのwavedromドキュメント追加
- `sim/verilator/justfile`に`veryl fmt`自動実行設定済み

### デバッグ中の問題
- シミュレーション: レシーバーがロックできない
- 詳細は`debug_log.md`を参照

### 未完了タスク
- 厳密比較テストのパス（データデコード問題）
- frame_parserのビット順整合
- SV lint警告の修正（任意）
