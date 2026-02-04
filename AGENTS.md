# AGENTS.md

ADAT Receiver - Veryl RTL Project

## プロジェクト概要

VerylによるADAT光信号受信RTL。8チャンネル24bit PCMデータをTOSLINK入力からデコードする。

## ビルド・テスト・Lintコマンド

### Verylビルド
```bash
# フォーマットとビルド
veryl fmt
veryl build

# クリーン
veryl clean
```

### 統合テスト（シミュレーション）
```bash
cd sim/verilator

# 実行（トレースなし）
just run

# 実行（FSTトレース付き）
just run-trace

# 波形表示（Surfer）
just wave
```

### ユニットテスト
```bash
cd sim/verilator

# すべてのユニットテスト
just unit-tests

# トレース付き
just unit-tests-trace

# 単一モジュールテスト（手動）
# edge_detector, timing_tracker, bit_decoder, frame_parser, output_interface
verilator --cc --exe --build -j 0 --timing --top-module tb_edge_detector \
  -I../../target -Wno-DECLFILENAME \
  ../../target/adat_pkg.sv \
  ../../tests/tb_edge_detector.sv \
  ../../target/edge_detector.sv \
  sim_main_edge.cpp
./obj_dir/Vtb_edge_detector
```

### SV Lint
```bash
# プロジェクト全体のLint
svls

# 特定ファイルのLint
svls src/adat_rx.veryl
```

## コードスタイルガイドライン

### Veryl言語規約

#### 命名規則
- **モジュール名**: `snake_case` (例: `adat_rx`, `edge_detector`)
- **パッケージ名**: `snake_case` + `_pkg` (例: `adat_pkg`)
- **ポート名**: 
  - 入力: `i_`プレフィックス (例: `i_clk`, `i_adat`)
  - 出力: `o_`プレフィックス (例: `o_valid`, `o_channels`)
  - アクティブローは`_n`サフィックス (例: `rst_n`)
- **内部信号**: `snake_case` (例: `edge_time`, `sync_mask`)
- **定数**: `SCREAMING_SNAKE_CASE` (例: `FRAME_TIME_48K`)
- **enum**: PascalCase + 型名付き値 (例: `SampleRate::Rate48kHz`)

#### インポート
```veryl
// パッケージインポートはファイル先頭
import adat_pkg::*;

// または個別インポート
import adat_pkg::SampleRate;
```

#### モジュール定義
```veryl
/// ドキュメントコメントは3スラッシュ
/// 日本語で記述
///
/// ```wavedrom
/// {"signal": [{"name": "clk", "wave": "p....."}]}
/// ```
pub module module_name (
    /// ポート説明
    i_clk: input clock,
    i_rst: input reset,
    i_data: input logic<8>,
    o_valid: output logic,
) {
    // 内部信号宣言
    var internal_sig: logic<8>;
    
    // インスタンス化
    inst u_submodule: submodule (
        i_clk: i_clk,
        i_rst: i_rst,
        i_in: internal_sig,
        o_out: o_valid,
    );
}
```

####  always_ff（順序回路）
```veryl
always_ff (i_clk, i_rst) {
    if_reset {
        // リセット値
        counter = '0;
    } else {
        // 通常動作
        counter = counter + 1;
    }
}
```

#### always_comb（組み合わせ回路）
```veryl
always_comb {
    // 組み合わせロジック
    next_state = current_state;
    case current_state {
        State::Idle: {
            if (start) {
                next_state = State::Active;
            }
        }
        State::Active: {
            if (done) {
                next_state = State::Idle;
            }
        }
    }
}
```

### ドキュメント規約

#### wavedrom波形記述
モジュールのタイミングをWaveJSON形式で記述:

```veryl
/// ```wavedrom
/// {"signal": [
///   {"name": "clk",   "wave": "p.....|..."},
///   {"name": "dat",   "wave": "x.345x|=.x", "data": ["head", "body", "tail"]},
///   {"name": "req",   "wave": "0.1..0|1.0"},
///   {},
///   {"name": "ack",   "wave": "1.....|01."}
/// ]}
/// ```
```

#### コメント言語
- **ドキュメントコメント**: 日本語
- **実装コメント**: 日本語
- **変数名・ポート名**: 英語

### SystemVerilogテストベンチ規約

#### ファイル構成
- テストベンチ: `tests/tb_<module>.sv`
- ADATジェネレータ: `tests/adat_generator.sv`
- シミュメイン: `sim/verilator/sim_main_<module>.cpp`

#### テストベンチ構造
```systemverilog
`timescale 1ns / 1ps

module tb_module_name;
    // ポート宣言
    logic clk;
    logic rst;
    
    // クロック生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz
    end
    
    // DUTインスタンス
    module_name u_dut (
        .i_clk(clk),
        .i_rst(rst),
        // ...
    );
    
    // テストシーケンス
    initial begin
        int pass = 1;
        rst = 1'b0;
        repeat (2) @(posedge clk);
        rst = 1'b1;
        
        // テスト実行
        if (actual !== expected) begin
            $display("FAIL: expected=%h actual=%h", expected, actual);
            pass = 0;
        end
        
        if (pass) begin
            $display("*** TEST PASSED ***");
        end else begin
            $display("*** TEST FAILED ***");
        end
        $finish;
    end
    
    // VCD出力
    initial begin
        $dumpfile("tb_module_name.vcd");
        $dumpvars(0, tb_module_name);
    end
endmodule
```

## プロジェクト構造

```
adat_rx/
├── src/                    # Verylソース
│   ├── adat_pkg.veryl      # パッケージ定義
│   ├── adat_rx.veryl       # トップモジュール
│   ├── edge_detector.veryl
│   ├── timing_tracker.veryl
│   ├── bit_decoder.veryl
│   ├── frame_parser.veryl
│   └── output_interface.veryl
├── tests/                  # SVテストベンチ
│   ├── tb_adat_rx.sv
│   ├── tb_edge_detector.sv
│   └── ...
├── sim/verilator/          # シミュレーション
│   ├── Justfile
│   └── sim_main_*.cpp
└── target/                 # Veryl生成SV
```

## 現在の状況

### 実装完了済み
- ✅ ADAT受信機能（8チャンネル24bit + user data）
- ✅ 厳密比較テストパス
- ✅ 全ユニットテストパス

### TODO
- S/MUX2の自動判別機能実装とテスト
- S/MUX4の自動判別機能実装とテスト（優先度低）

## 参考リンク

- ADAT仕様: <https://notebooklm.google.com/notebook/ea8497c0-baf9-42fc-8c84-d1b15e9f7ef4>
- WaveDrom: <https://github.com/wavedrom/wavedrom>
- Veryl: <https://veryl-lang.org/>
