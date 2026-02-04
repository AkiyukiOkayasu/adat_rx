# ADAT デコーダー Veryl ライブラリ 実装プラン

## プロジェクト概要

### ゴール

- **入力**: ADAT光信号（TOSLINKから電気変換済み）
- **出力**: PCMデータ + ワードクロック
  - 48kHz: 8ch × 24bit
  - 96kHz: 4ch × 24bit (S/MUX2)
  - 192kHz: 2ch × 24bit (S/MUX4)（優先度低）
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

- S/MUX2の自動判定とその動作テスト

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

UserBit[2]がHighのときはS/MUX2と判別できる。
<https://en.wikipedia.org/wiki/ADAT_Lightpipe>

### チャンネルマッピング

- **48kHz (8ch)**: Ch0-Ch7 そのまま出力
- **96kHz (4ch)**: Ch0: Out0ch first sample, Ch1: Out0ch second sample, Ch2: Out1ch first sample, Ch3: Out1ch second sample, Ch4: Out2ch first sample, Ch5: Out2ch second sample, Ch6: Out3ch first sample, Ch7: Out3ch second sample
- **192kHz (2ch)**: Ch0: Out0ch first sample, Ch1: Out0ch second sample, Ch2: Out0ch third sample, Ch3: Out0ch fourth sample, Ch4: Out1ch first sample, Ch5: Out1ch second sample, Ch6: Out1ch third sample, Ch7: Out1ch fourth sample

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
