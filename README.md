# ADAT decoder

[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-2ea44f?logo=github)](https://akiyukiokayasu.github.io/adat_rx/)

ADAT信号を受信し、PCM信号を出力するRTL。クロックはADAT信号から作る。
Verylによる実装。

## プロジェクト状況

### 現在のステータス

- ✅ PCMデータの受信・デコード完了
- ✅ S/MUX有効検出: UserBitによるS/MUX有効/無効の自動検出
- ✅ 厳密比較テストパス（`veryl test`）: ビットパーフェクトな伝送可能
- ✅ 44.1kHz, 48kHz, 88.2kHz, 96kHzでテスト

## ADAT基本仕様

48kHzか44.1kHzが基本サンプルレートであり、8ch伝送できる。

### フレーム仕様

1フレームは256bitで構成される。
[ADATフレーム構造の詳細](https://akiyukiokayasu.github.io/adat_rx/adat_rx.html#%E3%82%B7%E3%83%AA%E3%82%A2%E3%83%AB%E4%BC%9D%E9%80%81%E9%A0%86%E3%81%A8%E3%83%93%E3%83%83%E3%83%88%E6%9C%89%E6%84%8F%E6%80%A7%E3%81%AE%E5%AE%9A%E7%BE%A9)

### エンコード

4B5B→NRZI

### S/MUX

チャンネル数を減らす代わりに基本サンプルレートより高い周波数を使うことができる。

- S/MUX2: 96kHz or 88.2kHz, 4ch
- S/MUX4: 192kHz or 176.4kHz, 2ch

UserBitで判定できるのはS/MUXが有効かどうかまでで、S/MUX2かS/MUX4かの自動判別は原理的に不可能。
外部から供給されたwordclockを用いて判別するか、エンドユーザーが明示的に切り替えるしかない。

### ADAT物理ビットレート

- 48kHz系: 12.288Mbps
- 44.1kHz系: 11.2896Mbps

S/MUX2もしくはS/MUX4になっても物理ビットレートは変わらないことに注意。
S/MUX2では1フレームあたり2サンプル分が格納される。

## クロック仕様

- システムクロック: 50MHz推奨
- 1bitあたりのクロック:
  - 48kHz時: 約4.07クロック (50MHz / 12.288MHz)
  - 44.1kHz時: 約4.43クロック (50MHz / 11.2896MHz)
- 1フレーム: 256bit

## Test

```sh
veryl test
```

### 波形出力付き

FSTファイルで出力

```sh
veryl test --wave
surfer src/tb_adat_rx.fst
```
