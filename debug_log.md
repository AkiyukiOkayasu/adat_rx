# ADAT Receiver デバッグログ

## 概要

ADAT光信号を受信し、8チャンネル24ビットPCMデータをデコードするRTLのデバッグ記録。

## 現在の問題

**ステータス**: レシーバーがロックできない（frame_timeは安定、data_validが出ない）

### 症状

最新のシミュレーション実行時、以下のエラーが発生：

```
=== Debug Info ===
adat_in: 1
ADAT edge: 0, Synced: 1
Frame time: 2083 (expected ~2083)
Max time: 25
Sync detect: 1
Bits valid: 1, Bit count: 1, Bits: 00001
Bit counter: 37, Shift reg: 194e95b5
Data valid: 0, Channel: 0
Frame cnt: 0
Locked: 0
FAIL: Receiver not locked
```

### 主要な問題点

1. **data_validが出ない**（frame_parserで抽出位置に到達していない）
2. **bit_counterが37で停止**（フレーム全体に到達しない）
3. **frame_parserの単体テストが不一致**（user/data抽出に失敗）

## 検証済み事項

### ADATジェネレータ
- ✅ テストパターンを正しく生成
- ✅ NRZIエンコード動作確認済み
- ✅ フレーム周期約20.48μs（正しい）

### 実装修正履歴

#### 1. frame_parserのフレーム境界処理変更
**日付**: 2026-02-03

**変更前**:
```
Sync 10bitをbit_counterに含めて抽出
User: bit 15
Ch0: bit 45 ...
```

**変更後（暫定）**:
```
同期区間をフレーム境界として扱い、Sync 10bitは数えない
User: bit 5
Ch0: bit 35 ...（現在調整中）
```

**状況**: 単体テストでuser/data抽出がまだ不一致

#### 2. timing_trackerのフレーム時間安定化
**日付**: 2026-02-03

**変更**:
- `frame_time` を初回同期では更新しない（2回目以降で確定）
- `sync_mask` 判定をエッジ時の `cur_time` 基準に固定

**結果**:
- `frame_time` が 2083 で安定

#### 3. bit_decoderのNRZIパターン修正
**日付**: 2026-02-03

**変更**:
- 2/3/4/5ビットのNRZIパターンを `00010/00100/01000/10000` に修正

**結果**:
- `bits_valid` が立つように改善

### SV Lint結果

**ツール**: svls 0.2.14

**重要な警告**:
1. **adat_generator.sv:111** - WIDTHEXPAND
   - 8-bit `clk_counter` vs 32-bit 比較
   
2. **tb_adat_rx.sv:207** - WIDTHTRUNC
   - `test_pass` (int/32-bit) を1-bitとして使用

3. **timescale不一致** - 7件
   - 設計モジュールに`timescale`宣言がない
   - テストベンチのみ`1ns/1ps`を宣言

4. **未使用信号** - 複数件
   - `tb_adat_rx.sv`: `word_clk`, `sample_rate`
   - `adat_generator.sv`: `next_state`, `nibble_counter`, `channel_counter`, `channel_encoded`

## デバッグ中の理論

### frame_parserでdata_validが出ない理由

bit_decoderが出すビット列（LSB aligned）とframe_parserのシフト順が合っていないため、
ユーザーデータ/チャンネル境界の抽出に到達していない可能性が高い。

## 次のステップ

1. **frame_parserのビット順整合**
   - bit_decoderのLSB aligned出力に合わせてシフト/抽出を再定義

2. **単体テストの期待値更新**
   - frame_parserのテストケースを新しい定義に合わせる

3. **統合テスト再実行**
   - `just run` でlock判定まで通るか確認

## 参考資料

- [ADAT Project - ackspace.nl](https://ackspace.nl/wiki/ADAT_project)
- Veryl公式ドキュメント
- Verilatorシミュレーションガイド

## 更新履歴

- **2026-02-03**: 初版作成。デバッグ状況を整理。
- **2026-02-03**: frame_time安定化、NRZIパターン修正、frame_parser同期境界の見直しを追加。
