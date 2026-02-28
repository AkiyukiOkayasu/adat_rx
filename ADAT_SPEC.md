# ADAT基本仕様メモ

このドキュメントは、ADAT（Alesis Digital Audio Tape optical interface）の受信実装で必要になる基礎仕様を、実装寄りに整理したものです。

## 1. ADATの基本

- 物理層はTOSLINK光（本IPへの入力は光電変換後のデジタル信号 `i_adat`）
- 1フレームあたり8スロット（8ch相当）を送る
- 各スロットは24bitオーディオ語を運ぶ
- ライン符号化はNRZI

## 2. フレーム構造（通常ADAT）

この実装では1フレームを **256bit** として扱います。

- SYNC部: 11bit（`0000000000 + separator(1)`）
- User部: 5bit（`U3..U0 + separator(1)`）
- Audio部: 8ch × 30bit = 240bit

合計: `11 + 5 + 240 = 256bit`

### 2.1 5bitニブル構造

オーディオデータは5bitニブルで送られます。

- 1ニブル = `[4bit data][1bit separator=1]`
- 24bit語は6ニブルで表現（`24 / 4 = 6`）
- 1chあたり `6 × 5 = 30bit`

### 2.2 ビット順序

本プロジェクトでの定義:

- シリアル伝送順: フレーム先頭から `build_frame[255] -> build_frame[0]`
- nibble内のdata部: MSB-first（例: `D23..D20`）
- PCMの有意性: `o_channels[x][23]` がMSB、`o_channels[x][0]` がLSB

つまり、`D23..D20, D19..D16, ..., D3..D0` がそのまま `23:20, 19:16, ..., 3:0` に対応します。

### 2.3 separator bitの意味

各5bitニブル末尾の `separator=1` は、NRZI上で定期的に遷移を作る役割があります。

- 連続無遷移区間が長くなりすぎるのを抑える
- 受信側のタイミング復元・同期維持を助ける

## 3. フレーム周期とサンプルレート

ADATの「フレーム周期」はベースレート（44.1k/48k系）で進みます。

- 48k系: フレーム周期は約 `20.83us`（= `1 / 48,000`）
- 44.1k系: フレーム周期は約 `22.68us`（= `1 / 44,100`）

このIPの `o_frame_clk` はフレーム周期クロックです。

- 通常モード: `o_frame_clk` と実サンプルレートは一致
- S/MUX有効時: 実サンプルレートは `o_frame_clk` の2倍または4倍

## 4. User bits

フレーム先頭付近に4bitのUser nibble（`U3..U0`）があります。

本IPではこのうち User Bit 2（実装上は `i_user_bits[1]`）をS/MUX有効判定に使います。

- `0`: S/MUX無効
- `1`: S/MUX有効

<a id="smux"></a>
## 5. S/MUX（Sample Multiplexing）

高サンプルレートをADATフレームに載せるために、1つの論理チャンネルを複数の物理スロットに分割して運ぶ方式です。

<a id="smux-modes"></a>
### 5.1 モード対応

- 通常ADAT（S/MUX無効）: 48k/44.1k, 8ch
- S/MUX2: 96k/88.2k, 4ch
- S/MUX4: 192k/176.4k, 2ch

<a id="smux-channel-mapping"></a>
### 5.2 物理スロットと論理チャンネルの関係

本IPの `o_channels[8]` は常に「ADATの物理スロット順」で出力されます（`[0] -> [1] -> ... -> [7]`）。

論理チャンネル再構成は利用側で実装します。

- S/MUX2
  - Logical CH0 <= `o_channels[0] + o_channels[1]`
  - Logical CH1 <= `o_channels[2] + o_channels[3]`
  - Logical CH2 <= `o_channels[4] + o_channels[5]`
  - Logical CH3 <= `o_channels[6] + o_channels[7]`
- S/MUX4
  - Logical CH0 <= `o_channels[0] + o_channels[1] + o_channels[2] + o_channels[3]`
  - Logical CH1 <= `o_channels[4] + o_channels[5] + o_channels[6] + o_channels[7]`

時間順は、各Logical CH内で添字の小さいスロットが先のサンプルです。

<a id="smux-limitations"></a>
## 6. 重要な制約（実装時の注意）

- User bitsだけで分かるのは「S/MUX有効/無効」まで
- **S/MUX2 と S/MUX4 はUser bitsのみでは判別不能**
- 判別には外部WordClock、上位設定、または別系統のメタ情報が必要
- 本IPはS/MUX時の論理チャンネル再配置を行わない

## 7. 本リポジトリ実装との対応

- フレーム/ビット構造: `src/adat_rx.veryl`
- S/MUX有効検出（User Bit 2）: `src/output_interface.veryl`
- 同期/フレーム時間追跡: `src/timing_tracker.veryl`
- 5bitニブルから24bit復元: `src/bit_decoder.veryl`, `src/frame_parser.veryl`
- `o_valid`/`o_locked` の意味: `src/output_interface.veryl`
