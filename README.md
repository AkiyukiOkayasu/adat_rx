# ADAT decoder

ADAT信号を受信し、PCM信号を出力するRTL。クロックはADAT信号から作る。
Verylによる実装。

## プロジェクト状況

### 現在のステータス

- ✅ 8チャンネル24bit PCMデータの受信・デコード完了
- ✅ 4bitユーザーデータの抽出完了
- ✅ サンプルレート対応: 48kHz, 44.1kHz, 96kHz (S/MUX2), 88.2kHz (S/MUX2)
- ✅ 厳密比較テストパス（`veryl test`）

### TODO

- S/MUX4の自動判別が可能かどうかさらに検討→おそらく無理
- Wavedromの波形記述の修正
- ドキュメントの改善
- テストベンチ用の内部プローブ信号の整理を検討

## ADAT基本仕様

48kHzか44.1kHzが基本サンプルレートであり、8ch伝送できる。
1フレームは256bit。

### エンコード

4B5B→NRZI

### S/MUX

チャンネル数を減らす代わりに基本サンプルレートより高い周波数を使うことができる。

- S/MUX2: 96kHz or 88.2kHz, 4ch
- S/MUX4: 192kHz or 176.4kHz, 2ch

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
