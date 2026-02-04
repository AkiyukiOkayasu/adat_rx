# ADAT Receiver デバッグログ

## 現在の問題

## 検証済み事項

- ✅ 48kHzでは正しくデコードできた（厳密比較までOK）

### ADATジェネレータ

- ✅ テストパターンを正しく生成
- ✅ NRZIエンコード動作確認済み
- ✅ フレーム周期約20.48μs（正しい）

## 参考資料

- [ADAT Project - ackspace.nl](https://ackspace.nl/wiki/ADAT_project)
- Veryl公式ドキュメント
- Verilatorシミュレーションガイド

## 更新履歴

- **2026-02-03**: 初版作成。デバッグ状況を整理。
- **2026-02-03**: frame_time安定化、NRZIパターン修正、frame_parser同期境界の見直しを追加。
