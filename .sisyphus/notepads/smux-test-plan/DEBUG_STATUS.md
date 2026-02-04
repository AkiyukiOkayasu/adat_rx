# S/MUX デバッグ状況（更新）

## 変更内容
- `src/timing_tracker.veryl` の `max_time` 減衰を高速化
  - `WAIT_COUNT_MAX = 16'd255` を追加
  - `wait_count == 16'hFFFF` を `wait_count == WAIT_COUNT_MAX` に変更

## 目的
- サンプルレート遷移時に `max_time` が下がらず `frame_time` が更新されない問題を緩和し、S/MUX2/4 での同期検出を成立させる

## 実行結果
- `svls`: 警告なし
- `just run`: **PASS**（現行 `tests/tb_adat_rx.sv` は 48kHz の厳密比較のみ）
- `just unit-tests`: **PASS**（`tb_output_interface` の 96kHz/192kHz 判定含む）

## 現在の論点
- **S/MUX2/4 の統合テストコードが現行リポジトリに見当たらない**
  - `tests/tb_adat_rx.sv` は 48kHz の厳密比較のみ
  - S/MUX2/4 の PASS/FAIL を判定するセクションが存在しない

## 次の確認ポイント
- S/MUX2/4 の統合テストを含むテストベンチの有無を確認
- テストが存在する場合、上記変更で PASS するか再実行
