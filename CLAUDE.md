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

## コーディング規約

- ドキュメントコメント・実装コメントは日本語を使用
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
- 波形ビューワー: Surfer
