# S/MUX対応 現状と課題

## 概要

S/MUX（Sample Multiplexing）はADATプロトコルで高サンプルレート（96kHz/192kHz）を実現する技術。複数のフレームを使って1つの論理チャンネルのデータを分割送信する。

---

## 現在の実装状況

### ✅ 完了済み

| コンポーネント | 状態 | 説明 |
|--------------|------|------|
| `adat_pkg::SampleRate` enum | ✅ 実装済み | Rate48kHz / Rate96kHz / Rate192kHzを定義 |
| `timing_tracker` | ✅ 実装済み | `frame_time`測定（sync間のクロック数） |
| `output_interface` | ✅ 判定実装済み | `frame_time`からサンプルレートを判定 |
| `frame_parser` | ✅ 実装済み | 256bitフレームから8ch×24bitを抽出 |
| テストベンチ | ✅ テスト実装済み | S/MUX2/S/MUX4パターン生成・検証 |

### 🔍 サンプルレート判定ロジック

⚠️ **誤り**: 以下のframe_timeベース判定は**不正確**です。S/MUX2では物理ビットレートが変化しないため、frame_timeでの判定は不可能です。

```veryl
// 【削除予定】古い実装（誤り）
// output_interface.veryl
always_ff (i_clk, i_rst) {
    if_reset {
        sample_rate = SampleRate::Rate48kHz;
    } else {
        if i_frame_time >: 12'd1500 {
            sample_rate = SampleRate::Rate48kHz;    // ~2083 for 48kHz
        } else if i_frame_time >: 12'd750 {
            sample_rate = SampleRate::Rate96kHz;    // ~1042 for 96kHz
        } else {
            sample_rate = SampleRate::Rate192kHz;   // ~521 for 192kHz
        }
    }
}
```

✅ **正しい方法**: UserBit[2]によるS/MUX検出

```veryl
// 【新規実装】正しい実装（UserBit[2]で判定）
var smux2_mode: logic = i_user_bits[2];
o_sample_rate = smux2_mode ? SampleRate::Rate96kHz : SampleRate::Rate48kHz;
```

### ✅ テストベンチでのS/MUX検証

`tb_adat_rx.sv`では以下を検証：
- **S/MUX2 (96kHz)**: 2フレームをキャプチャして論理4chを検証
- **S/MUX4 (192kHz)**: 4フレームをキャプチャして論理2chを検証

---

## S/MUX仕様

### フレーム構造（全モード共通）

```
[Sync 10bit][1][User 4bit][1][Ch0 30bit][Ch1 30bit]...[Ch7 30bit]
```

- **フレーム長**: 256bit（全モード共通）
- **各チャンネル**: 30bit（24bitデータ + 6bit同期ビット）

### モード別の違い

| モード | フレームレート | 物理ビットレート | 論理チャンネル数 | 1論理chあたりフレーム数 |
|-------|--------------|----------------|----------------|---------------------|
| 48kHz | 48,000Hz | 12.288Mbps（不変） | 8ch | 1フレーム |
| 96kHz S/MUX2 | 96,000Hz | 12.288Mbps（不変） | 4ch | 2フレーム |
| 192kHz S/MUX4 | 192,000Hz | 12.288Mbps（不変） | 2ch | 4フレーム |

### S/MUX2 (96kHz) データ配置

```
フレーム0: [Ch0_L][Ch1_L][Ch2_L][Ch3_L][Ch0_H][Ch1_H][Ch2_H][Ch3_H]
フレーム1: [Ch0_L][Ch1_L][Ch2_L][Ch3_L][Ch0_H][Ch1_H][Ch2_H][Ch3_H]
            └─論理Ch0─┘ └─論理Ch1─┘ └─論理Ch2─┘ └─論理Ch3─┘
```

- 96kHzサンプルをL（下位）/H（上位）の48kHzサンプルに分割
- 2フレームにわたってインターリーブ配置
- 受信側でL/Hを結合して24bit×2=48bit→最終的に24bit 96kHzサンプルに

### S/MUX4 (192kHz) データ配置

```
フレーム0: [Ch0_0][Ch1_0][x][x][x][x][x][x]
フレーム1: [Ch0_1][Ch1_1][x][x][x][x][x][x]
フレーム2: [Ch0_2][Ch1_2][x][x][x][x][x][x]
フレーム3: [Ch0_3][Ch1_3][x][x][x][x][x][x]
            └─論理Ch0─┘ └─論理Ch1─┘
```

- 192kHzサンプルを4つの48kHzサンプルに分割
- 4フレームにわたってインターリーブ配置

### ✅ S/MUX2（96kHz）DUT出力方式

物理ビットレートはS/MUX2でも**12.288Mbps固定**のため、DUT内でのデータ復元は不要です。

**DUTの役割:**
- 1フレーム受信ごとに**2回のo_valid**を出力
- o_channels[0-7]は**物理8chをそのまま出力**（チャンネルマッピングなし）
- o_sample_rateで**Rate96kHz**を出力

```
フレーム0内のデータ配置（物理チャンネル）:
┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│  Ch0    │  Ch1    │  Ch2    │  Ch3    │  Ch4    │  Ch5    │  Ch6    │  Ch7    │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│Out0 1st │Out0 2nd │Out1 1st │Out1 2nd │Out2 1st │Out2 2nd │Out3 1st │Out3 2nd │
└─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘

DUT出力タイミング:
- o_valid 1回目 (t=T)   : o_channels[0-7] = Ch0～Ch7の値、o_valid_channels=4
- o_valid 2回目 (t=T+1) : o_channels[0-7] = Ch0～Ch7の値（同じデータ）、o_valid_channels=4
```

**エンドユーザーの処理（FIFO等で実装）:**
- o_sample_rate == Rate96kHzを見てS/MUX2と判定
- o_valid_channels == 4を確認
- 1回目のo_valid: Ch0, Ch2, Ch4, Ch6（1st samples）をFIFOへ
- 2回目のo_valid: Ch1, Ch3, Ch5, Ch7（2nd samples）をFIFOへ
- FIFOから論理4ch@96kHzとして読み出し

---

## 未解決の課題

### ⚠️ 課題1: DUT内でのS/MUXデータ復元が未実装

**現状:**
- `output_interface`は物理フレーム（8ch）をそのまま出力
- S/MUXデータ復元はテストベンチ側で行っている

```veryl
// output_interface.veryl - 現状（S/MUX未対応）
always_ff (i_clk, i_rst) {
    if_reset {
        channels[0] = 24'd0;
        // ... ch1-7も同様
    } else if i_data_valid {
        channels[i_channel] = i_data;  // 単純に格納するだけ
        valid_out = i_channel == 3'd7; // Ch7受信でvalid
    }
}
```

**期待される動作:**
- S/MUX2: 2フレームをバッファリングして論理4chを出力
- S/MUX4: 4フレームをバッファリングして論理2chを出力
- `o_valid`を論理サンプル単位（48kHz: 1/48kHz, 96kHz: 1/96kHz, 192kHz: 1/192kHz）で出力

### ⚠️ 課題2: 出力インターフェースの設計

**選択肢A: DUT内でS/MUX復元**
- `output_interface`にフレームバッファを追加
- `sample_rate`に応じて出力形式を変更
- 論理チャンネル数が可変（8ch→4ch→2ch）

**選択肢B: 現状維持（テストベンチ側で処理）**
- DUTは物理フレームを出力し続ける
- 上位モジュール/テストベンチでS/MUX復元
- 実装がシンプル

### ⚠️ 課題3: 出力チャンネル数の扱い

`o_channels`は現在`logic<24> [8]`固定。S/MUX対応時：
- 常に8ch出力で未使用chは0埋め？
- 動的にチャンネル数を変更？（インターフェース変更が必要）

---

## 実装案（DUT内でS/MUX復元する場合）

### 追加要件

```veryl
module output_interface (
    // ... existing ports ...
    o_logical_channels: output logic<24> [8],  // 論理チャンネル出力
    o_logical_valid: output logic,              // 論理サンプル有効
    o_frame_sync: output logic,                // フレーム境界（デバッグ用）
)
```

### 実装方針

1. **フレームバッファ追加**
   - S/MUX4用に4フレーム分のバッファ（4×8ch×24bit）
   - フレームカウンタ（0-3）

2. **状態管理**
   ```veryl
   var frame_buffer: logic<24> [4][8];  // 4フレーム×8ch
   var frame_idx: logic<2>;              // 0-3
   ```

3. **出力生成**
   - 48kHz: フレーム受信ごとに8ch出力
   - 96kHz: 2フレーム受信ごとに4ch出力
   - 192kHz: 4フレーム受信ごとに2ch出力

### 擬似コード

```veryl
always_ff (i_clk, i_rst) {
    if_reset {
        frame_idx = 2'd0;
    } else if i_data_valid && i_channel == 3'd7 {
        // フレーム終了時
        frame_buffer[frame_idx] = channels;
        frame_idx = frame_idx + 2'd1;
        
        case sample_rate {
            Rate48kHz: {
                // 常に出力
                logical_channels = channels;
                logical_valid = 1'b1;
            }
            Rate96kHz: {
                // 2フレームごとに出力
                if frame_idx[0] == 1'b0 {
                    // L/H結合して4ch出力
                    logical_channels[0] = combine(frame_buffer[0][0], frame_buffer[1][0]);
                    // ... ch1-3も同様
                    logical_valid = 1'b1;
                }
            }
            Rate192kHz: {
                // 4フレームごとに出力
                if frame_idx == 2'd0 {
                    // 4サンプル結合して2ch出力
                    logical_channels[0] = combine4(frame_buffer[0][0], ...);
                    logical_valid = 1'b1;
                }
            }
        }
    }
}
```

---

## テスト戦略

### 現状のテスト（tb_adat_rx.sv）

1. **48kHz基本テスト**: 8chデータを生成→受信→厳密比較
2. **S/MUX2テスト**: 2フレーム生成→テストベンチ側で論理4ch復元→検証
3. **S/MUX4テスト**: 4フレーム生成→テストベンチ側で論理2ch復元→検証

### DUT内S/MUX対応後のテスト

- `o_logical_channels`と`o_logical_valid`を追加検証
- 論理サンプルレートでのvalidタイミング確認
- S/MUXデータ結合の正確性検証

---

## 次のステップ

1. **方針決定**: DUT内でS/MUX復元するか、現状維持か
2. **インターフェース設計**: 出力チャンネル形式の確定
3. **実装**: `output_interface`の拡張または新規モジュール作成
4. **テスト更新**: 新インターフェースに合わせたテストベンチ修正
5. **検証**: S/MUX2/S/MUX4の動作確認

---

## 参考資料

- [ACKspace ADAT Project](https://ackspace.nl/wiki/ADAT_project)
- Alesis S/MUX Specification (2001)
- `src/output_interface.veryl`: サンプルレート判定ロジック
- `tests/tb_adat_rx.sv`: S/MUXテスト実装
