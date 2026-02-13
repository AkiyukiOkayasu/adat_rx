# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

ADAT受信機のRTL実装。TOSLINK ADAT信号を受信し、8チャンネル24bit PCMデータを出力する。Veryl言語で実装。

## コマンド

```bash
# フォーマット
veryl fmt

# ビルド（Veryl → SystemVerilog生成）
veryl build

# テスト実行
veryl test

# 波形付きテスト（FST出力）
veryl test --wave

# 波形表示（macOS）
surfer src/tb_adat_rx.fst

# クリーン
veryl clean
```

## アーキテクチャ

パイプライン構成でADAT信号を処理：

```
ADAT入力 → timing_tracker → bit_decoder → frame_parser → output_interface → PCM出力
              (エッジ検出)    (NRZI/4B5B)   (30bit→24bit)   (ワードクロック)
```

### 主要モジュール

| モジュール | 役割 |
|-----------|------|
| `adat_rx.veryl` | トップモジュール。全パイプラインステージを接続 |
| `adat_pkg.veryl` | 共有型・定数（SampleRateEnum、タイミング閾値） |
| `timing_tracker.veryl` | エッジタイミング検出・同期判定 |
| `bit_decoder.veryl` | NRZI + 時間ビンデコード |
| `frame_parser.veryl` | 30bitニブル → 24bit PCM変換 |
| `output_interface.veryl` | ワードクロック生成、S/MUX判定 |

## コーディング規約

- ドキュメントコメント・実装コメントは日本語、識別子・ポート名は英語
- ポート命名: 入力は`i_`、出力は`o_`、アクティブローは`_n`接尾辞
- 共有型を使う場合は `adat_pkg::*` をインポート
- リセットは全モジュールでアクティブハイ `i_rst`

## 編集禁止ファイル

- `target/` - 生成されたSystemVerilog（`veryl build`で再生成）
- `dependencies/std/` - vendored標準ライブラリ
- `doc/` - 生成ドキュメント

## テスト

- シミュレータ: Verilator
- 波形フォーマット: FST
- macOSではGTKWaveではなくSurferを使用
