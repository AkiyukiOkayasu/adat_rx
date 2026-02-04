# ADAT Receiver デバッグログ

## 概要

ADAT光信号を受信し、8チャンネル24ビットPCMデータをデコードするRTLのデバッグ記録。

## 現在の問題

**ステータス**: ✅ 解決済み - 全テストパス

### 解決内容（2026-02-04）

1. **テストベンチの早期終了問題**
   - `fork/join_any` を `fork...join_none` + メインスレッドでのフレーム待ちに変更
   - 10フレーム分のシミュレーション完了を確認

2. **ユーザーデータのビット順反転**
   - `frame_parser` の user 抽出を `{shift_next[0], shift_next[1], shift_next[2], shift_next[3]}` に修正
   - `0xA` が正しく抽出されるようになった

### テスト結果

```
just run        → TEST PASSED（8チャンネル全て一致、user一致）
just unit-tests → 全5テストPASS
```

### 以前の根本原因（参考）

**テストベンチの `fork/join_any` による早期終了**

問題箇所（`tests/tb_adat_rx.sv` 156-184行）:
```systemverilog
fork
    begin
        // エッジ検出カウンター - 20エッジで終了
        while (edge_count < 20 && timeout < 10000) ...
    end
    begin
        // フレーム完了待ち - 10フレーム
        repeat (10) @(posedge gen_done);
    end
join_any       // ← どちらかが終わると即座にreturn
disable fork;  // ← フレーム完了待ちをkill
```

**問題の流れ**:
1. 20エッジ検出（約37ビット分）でエッジモニタが終了
2. `join_any` により即座にforkブロックを抜ける
3. `disable fork` でフレーム完了待ちスレッドが強制終了
4. 1フレーム（256ビット）も完了していない状態でロック確認
5. 当然ロックできずFAIL

**計測値による裏付け**:
- `bits_valid_count: 19` (1フレームには約100回以上必要)
- `bit_counter: 37` (1フレームは256ビット)
- `boundary_pass: ch0=1, ch1-7=0` (チャンネル0境界のみ通過)

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

**ツール**: Verilator 5.044 (`--lint-only -Wall`)

**2026-02-04 更新**: 11件の警告（全て軽微、機能に影響なし）

| カテゴリ | 件数 | 内容 |
|----------|------|------|
| WIDTHTRUNC | 2 | `bit_decoder` の幅切り詰め |
| UNUSEDSIGNAL | 4 | デバッグ用の未使用信号 (`synced`, `max_time` 等) |
| UNUSEDPARAM | 5 | 将来の拡張用パラメータ (`FRAME_TIME_*`, `RATE_THRESHOLD_*`) |

**注記**: DECLFILENAME警告はVerylのモジュール命名規則によるもの（`adat_rx_`プレフィックス）。無視可。

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

## bit_counter デバッグ手順

### 目的

`bit_counter` が 256 まで進まず停止する原因を特定する。

### 手順

1. **bit_count分布の計測**
   - `tb_adat_rx.sv` に `bit_count` のヒストグラムカウンタを追加
   - 1フレーム内での `bit_count` 合計が 256 に近いか確認

2. **bits_validパルス数の計測**
   - `bits_valid` の立ち上がり回数を1フレーム内でカウント
   - 期待値（フレーム内のエッジ数）と比較

3. **sync境界の確認**
   - `sync_detect` が 0/1 になるタイミングを波形で確認
   - `frame_parser` が途中でリセットされていないかを確認

4. **edge_timeとbit_timeの比率確認**
   - `edge_time`, `bit_time`, `t1..t4` をログ出力
   - 実データでの `bit_count` 判定が妥当か確認

5. **境界到達の確認**
   - `bit_counter` が 35/65/95/…/245 を超えた回数をカウント
   - どの境界で止まるかを特定

6. **修正後の再テスト**
   - `just run` → `just run-trace` の順で確認
   - 改善がなければ `bit_decoder` のしきい値と `sync_detect` 判定を再調整

## 参考資料

- [ADAT Project - ackspace.nl](https://ackspace.nl/wiki/ADAT_project)
- Veryl公式ドキュメント
- Verilatorシミュレーションガイド

## 更新履歴

- **2026-02-03**: 初版作成。デバッグ状況を整理。
- **2026-02-03**: frame_time安定化、NRZIパターン修正、frame_parser同期境界の見直しを追加。
