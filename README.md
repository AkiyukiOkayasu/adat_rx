# ADAT transceiver

[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-2ea44f?logo=github)](https://akiyukiokayasu.github.io/adat_rx/)

ADAT光入力をデコードして24bit PCMを出力、または24bit PCMをADATフレームにエンコードして送信するVeryl RTL。  
受信クロックは入力ADATから復元します（外部PLL不要）。

## できること

- ADAT受信と8ch 24bit PCMデコード
- ADAT送信と8ch 24bit PCMエンコード
- 44.1kHz / 48kHz 系での動作
- 96kHz / 88.2kHz 入力（S/MUX有効）の受信テスト済み
- UserBitに基づくS/MUX有効フラグ設定（送信）と検出（受信: `o_smux_active`）
- 外部フレームクロック入力による送信タイミング制御

## 導入前に知るべきこと

- 受信側の `o_frame_clk` はADATフレーム周期であり、再生サンプルレートそのものではありません。  
  例: 通常モードでは `o_frame_clk` と実サンプルレートは一致しますが、S/MUX有効時は一致しません。
- S/MUXの基本、モード（S/MUX2/S/MUX4）、制約は [`ADAT_SPEC.md` の「5. S/MUX」](ADAT_SPEC.md#smux) を参照
- `S/MUX2`/`S/MUX4` のモード対応は [`ADAT_SPEC.md` の「5.1 モード対応」](ADAT_SPEC.md#smux-modes) を参照
- S/MUX時の論理チャンネル割り当ては [`ADAT_SPEC.md` の「5.2 物理スロットと論理チャンネルの関係」](ADAT_SPEC.md#smux-channel-mapping) を参照
- S/MUX判別の制約（UserBitのみではS/MUX2/4を判別不可）は [`ADAT_SPEC.md` の「6. 重要な制約」](ADAT_SPEC.md#smux-limitations) を参照

## I/O要点

### RX (Receiver)

- 入力: `i_clk`（推奨50MHz）, `i_rst`, `i_adat`
- 出力: `o_channels[8]`, `o_valid`, `o_locked`, `o_frame_clk`, `o_smux_active`

### TX (Transmitter)

- 入力: `i_clk`（50MHz）, `i_rst`, `i_frame_clk`, `i_channels[8]`, `i_smux_active`
- 出力: `o_adat`

## 使用例

### RX (Receiver)

```veryl
inst rx: adat_rx (
    i_clk         : clk,
    i_rst         : rst,
    i_adat        : adat_in,
    o_channels    : channels_out,
    o_valid       : valid,
    o_locked      : locked,
    o_frame_clk   : frame_clk_rx,
    o_smux_active : smux_active,
);
```

### TX (Transmitter)

```veryl
import adat_pkg::AdatFamily;
inst tx: adat_tx #(
    ADAT_FAMILY: AdatFamily::F48K
) (
    i_clk         : clk,
    i_rst         : rst,
    i_frame_clk   : frame_clk_tx,
    i_channels    : channels_in,
    i_smux_active : smux_active,
    o_adat        : adat_out,
);
```

## 開発者向け（任意）

Verylには組み込みテスト実行機能があり、RTL変更時の回帰確認に使えます。

### テスト実行

```sh
veryl test
```

### 波形確認

```sh
veryl test --wave
surfer src/tb_adat_rx.fst
```

## ドキュメント

- API/設計ドキュメント: <https://akiyukiokayasu.github.io/adat_rx/>
- ADAT基本仕様メモ（本リポジトリ）: [`ADAT_SPEC.md`](ADAT_SPEC.md)
- ADATフレーム構造の詳細: <https://akiyukiokayasu.github.io/adat_rx/adat_rx.html#%E3%82%B7%E3%83%AA%E3%82%A2%E3%83%AB%E4%BC%9D%E9%80%81%E9%A0%86%E3%81%A8%E3%83%93%E3%83%83%E3%83%88%E6%9C%89%E6%84%8F%E6%80%A7%E3%81%AE%E5%AE%9A%E7%BE%A9>
