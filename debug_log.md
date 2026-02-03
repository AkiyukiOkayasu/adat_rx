# ADAT Receiver デバッグログ

## 概要

ADAT光信号を受信し、8チャンネル24ビットPCMデータをデコードするRTLのデバッグ記録。

## 現在の問題

**ステータス**: レシーバーがロックできない

### 症状

シミュレーション実行時、以下のエラーが発生：

```
=== Debug Info ===
adat_in: 0
ADAT edge: 0, Synced: 0
Frame time: 2048 (expected ~2083)
Max time: 25
Sync detect: 1
Bits valid: 0, Bit count: 1, Bits: 00001
Bit counter: 147, Shift reg: 3fffffff
Data valid: 0, Channel: 3
Frame cnt: 0
Locked: 0
FAIL: Receiver not locked
```

### 主要な問題点

1. **bit_counterが147で停止**（256になるはず）
2. **synced信号が0**（edge_detectorの出力が機能していない）
3. **bits_validが0**（bit_decoderがデータを出力していない）

## 検証済み事項

### ADATジェネレータ
- ✅ テストパターンを正しく生成
- ✅ NRZIエンコード動作確認済み
- ✅ フレーム周期約20.48μs（正しい）

### 実装修正履歴

#### 1. frame_parserのビット位置修正
**日付**: 2026-02-03

**変更前**:
```
ユーザーデータ: bit 5
チャンネル: bit 35, 65, 95, 125, 155, 185, 215, 245
```

**変更後**:
```
ユーザーデータ: bit 15
チャンネル: bit 45, 75, 105, 135, 165, 195, 225, 255
```

**理由**: ADATフレーム構造に基づく正しいビット位置
- Sync: 10 bits
- Separator: 1 bit
- User: 4 bits
- Separator: 1 bit
- Channels 0-7: 各30 bits

#### 2. timing_trackerのmax_time初期値調整
**日付**: 2026-02-03

**変更**:
```veryl
// 変更前
max_time = 10'h3FF;  // 1023

// 変更後（試行1）
max_time = 10'd0;

// 変更後（試行2）
max_time = 10'd8;

// 変更後（試行3 - 現在）
max_time = 10'd20;  // threshold = 15
```

**理論値**:
- データ期間（最大5ビット）: 40クロック → cur_time/4 = 10
- 同期期間（10ビット）: 80クロック → cur_time/4 = 20
- threshold = max_time * 0.75 = 15
- データ期間: 10 < 15 → sync_mask = 1 ✓
- 同期期間: 20 > 15 → sync_mask = 0 ✓

#### 3. wavedromドキュメント更新
**日付**: 2026-02-03

以下のモジュールにWavedrom形式のドキュメントコメントを追加：
- `src/edge_detector.veryl`
- `src/timing_tracker.veryl`
- `src/bit_decoder.veryl`
- `src/frame_parser.veryl`
- `src/output_interface.veryl`
- `src/adat_pkg.veryl`

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

### bit_counterが147で停止する理由

147 = 10 (Sync) + 1 (Separator) + 4 (User) + 1 (Separator) + 30*4.3 (Channel 0-3 部分)

sync_maskが適切に切り替わっていない可能性：
- timing_trackerの閾値計算に問題
- または、bit_decoderがsync_mask=0時にリセットされている

### synced信号が0の理由

edge_detectorの出力：
```veryl
assign o_synced = sync_ff[1];
assign o_edge = sync_ff[0] ^ sync_ff[1];
```

ADAT信号が入力されていない、またはリセット後に信号が来ていない可能性。

## 次のステップ

1. **VCD波形ダンプの有効化**
   - Verilatorの`--trace`オプションを有効化
   - GTKWaveで詳細な信号波形を確認

2. **テストベンチの簡素化**
   - 最小限のテストケースを作成
   - 手動でADATパターンを生成して入力

3. **モジュール単体テスト**
   - edge_detector単体テスト
   - timing_tracker単体テスト
   - bit_decoder単体テスト

4. **同期検出ロジックの見直し**
   - timing_trackerの同期検出アルゴリズムを根本的に見直し
   - 固定的な同期パターン検出（10ビット連続0）に変更を検討

## 参考資料

- [ADAT Project - ackspace.nl](https://ackspace.nl/wiki/ADAT_project)
- Veryl公式ドキュメント
- Verilatorシミュレーションガイド

## 更新履歴

- **2026-02-03**: 初版作成。デバッグ状況を整理。
