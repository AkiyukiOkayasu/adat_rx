# CLAUDE.md

## プロジェクト概要

ADAT送受信機のRTL実装。Veryl言語で記述し、Verilatorでシミュレーションする。

- **RX**: ADAT光入力 → 8ch 24bit PCM出力（クロック自動復元）
- **TX**: 8ch 24bit PCM入力 → ADAT光出力

## コマンド

```bash
veryl fmt           # フォーマット
veryl build         # Veryl → SystemVerilog生成
veryl test          # テスト実行
veryl test --wave   # 波形付きテスト（FST出力）
veryl clean         # クリーン
```

## アーキテクチャ

### RX パイプライン
```
ADAT入力 → timing_tracker → bit_decoder → frame_parser → output_interface → PCM出力
             (エッジ検出)    (NRZI/4B5B)   (30bit→24bit)   (ワードクロック)
```

### TX パイプライン
```
PCM入力 → tx_frame_builder → tx_bit_serializer → tx_nrzi_encoder → ADAT出力
           (256bitフレーム構築)  (MSB-firstシリアル化)  (NRZI変換)
```

### 共有
- `adat_pkg` — `AdatFamily` enum等の共有型定義

## コーディング規約

- コメントは日本語
- ポート命名: 入力`i_`、出力`o_`、アクティブロー`_n`接尾辞
- 共有型は `adat_pkg::*` をインポート
- リセットは全モジュールでアクティブハイ `i_rst`

## 編集禁止

- `target/` — 生成SystemVerilog
- `dependencies/std/` — vendored標準ライブラリ
- `doc/` — 生成ドキュメント

## テスト

- シミュレータ: Verilator / 波形: FST / ビューワー: Surfer
- `surfer src/<テストベンチ名>.fst` で波形表示
