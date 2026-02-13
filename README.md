# ADAT decoder

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
<img width="10420" height="126" alt="wavedrom(2)" src="https://github.com/user-attachments/assets/5244e7e5-140d-446a-850c-879a64533172" />


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
