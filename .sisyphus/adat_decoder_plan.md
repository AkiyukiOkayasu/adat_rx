# ADAT デコーダー Veryl ライブラリ 実装プラン

## プロジェクト概要

### ゴール
- **入力**: ADAT光信号（TOSLINKから電気変換済み）
- **出力**: PCMデータ + ワードクロック
  - 48kHz: 8ch × 24bit
  - 96kHz: 4ch × 24bit (S/MUX2)
  - 192kHz: 2ch × 24bit (S/MUX4)
- **クロック**: ADAT信号から自律的に復元（外部PLLなし）
- **テスト**: Verilatorによる徹底シミュレーション検証

### 技術仕様（ADAT プロトコル）
| 項目 | 値 |
|------|-----|
| サンプルレート | 44.1/48kHz, 88.2/96kHz, 176.4/192kHz |
| チャンネル数 | 8ch (1x), 4ch (2x), 2ch (4x) |
| ビット深度 | 24bit/ch |
| フレームサイズ | 256 bits |
| ビットレート | 12.288 Mbps (NRZI後 6.144 Mbaud) |
| エンコード | NRZI (4bit毎に1bit挿入) |
| 同期パターン | 10個の連続'0'ビット |

### フレーム構造 (256 bits)
```
[Sync 10bit] [1] [User 4bit] [1] [Ch1 30bit] [Ch2 30bit] ... [Ch8 30bit]
```

---

## 実装タスク

### Task 1: 基盤構築
**ファイル**: `src/types.veryl`

共通型定義パッケージを作成:
- AudioSample (24bit)
- ChannelAddr (3bit)
- BitCounter (8bit)
- SampleRateMode enum (Rate1x/Rate2x/Rate4x)
- 各種定数 (FRAME_BITS, BITS_PER_CHANNEL等)

### Task 2: エッジ検出モジュール
**ファイル**: `src/edge_detector.veryl`

- 2段FFによる非同期入力の同期化
- 立ち上がり/立ち下がりエッジの検出
- メタステーブル対策

### Task 3: タイミング追跡モジュール
**ファイル**: `src/timing_tracker.veryl`

- エッジ間の時間計測
- 最大時間追跡（遅い減衰付き）
- 3/4閾値による同期検出
- フレーム時間計測

### Task 4: ビットデコーダモジュール
**ファイル**: `src/bit_decoder.veryl`

時間ビニング方式:
- 0.5〜1.5 bit time → 1 bit
- 1.5〜2.5 bit time → 2 bits
- ...
- 4.5〜5.5 bit time → 5 bits

### Task 5: フレームパーサモジュール
**ファイル**: `src/frame_parser.veryl`

- 30bitシフトレジスタでデータ蓄積
- ビットカウンタベースでチャンネル抽出
- nibble結合 (4bit×6 → 24bit)

### Task 6: 出力インターフェース
**ファイル**: `src/output_interface.veryl`

- 8チャンネルPCM出力
- S/MUX対応 (96kHz→4ch, 192kHz→2ch)
- ワードクロック生成
- サンプルレート自動検出

### Task 7: トップモジュール統合
**ファイル**: `src/adat_rx.veryl`

- 全サブモジュールのインスタンス化
- 詳細なドキュメンテーションコメント
- 使用例を含む

### Task 8: テストベンチ作成
**ファイル**: 
- `tests/adat_generator.sv` - ADATパターン生成
- `tests/tb_adat_rx.sv` - 統合テストベンチ

### Task 9: シミュレーション環境
**ファイル**:
- `sim/verilator/Makefile`
- `sim/verilator/sim_main.cpp`

### Task 10: 検証実行
- 全テスト実行
- 48kHz/96kHz/192kHz各モードの検証
- 結果確認

---

## アーキテクチャ

```
adat_rx (トップ)
├── edge_detector         - 入力同期化 + エッジ検出
├── timing_tracker        - 最大時間追跡 + フレーム時間計測 + 同期検出
├── bit_decoder           - NRZI → ビット列変換 (時間ビニング)
├── frame_parser          - ビット→チャンネルデータ抽出
└── output_interface      - 8ch PCM出力 + S/MUX + ワードクロック生成
```

## S/MUX対応

### サンプルレート検出
フレーム周期から自動判定:
- 48kHz: ~2083 cycles @ 100MHz
- 96kHz: ~1042 cycles @ 100MHz  
- 192kHz: ~521 cycles @ 100MHz

### チャンネルマッピング
- **48kHz (8ch)**: Ch0-Ch7 そのまま出力
- **96kHz (4ch)**: Ch0+Ch4→Out0, Ch1+Ch5→Out1, Ch2+Ch6→Out2, Ch3+Ch7→Out3
- **192kHz (2ch)**: Ch0+Ch2+Ch4+Ch6→Out0, Ch1+Ch3+Ch5+Ch7→Out1

---

## 期待されるリソース使用量

| リソース | 推定量 |
|---------|--------|
| LUT/Logic Elements | 200-400 |
| Flip-Flops | 150-250 |
| Block RAM | 0 |
| DSP | 0 |

---

## 検証シナリオ

1. **基本動作**: 既知パターン→正確なデコード
2. **全サンプルレート**: 48kHz/96kHz/192kHz
3. **同期獲得/復帰**
4. **ジッタ耐性**: ±100ppm
5. **連続動作**: 10,000フレーム以上
