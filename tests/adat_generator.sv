// ADATパターンジェネレータ
// 
// テスト用にADAT信号を生成する。
// 8チャンネル24ビットPCMデータをADATフレームにエンコードし、
// NRZI変換してシリアル出力する。

`timescale 1ns / 1ps

module adat_generator #(
    parameter int CLK_FREQ = 50_000_000,   // システムクロック周波数
    parameter int SAMPLE_RATE = 48000,     // サンプルレート
    parameter int SMUX2_MODE = 0           // S/MUX2モード (0=通常, 1=S/MUX2)
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [23:0] audio_in [0:7],    // 8チャンネル入力
    input  logic [3:0]  user_in,           // ユーザーデータ
    input  logic        start,             // フレーム生成開始
    output logic        adat_out,          // ADAT出力 (NRZI)
    output logic        frame_done         // フレーム完了
);

    // 1ビットあたりのクロック数 (44.1kHz: ~4.43, 48kHz: ~4.07)
    localparam int  BIT_RATE = SAMPLE_RATE * 256;
    localparam int  CLOCKS_PER_BIT_INT = CLK_FREQ / BIT_RATE;
    localparam real CLOCKS_PER_BIT_REAL = (1.0 * CLK_FREQ) / BIT_RATE;
    localparam int  CLOCKS_PER_BIT_INIT = $rtoi(CLOCKS_PER_BIT_REAL + 0.5);
    
    // 状態
    typedef enum logic [2:0] {
        IDLE,
        SYNC,
        USER_PRE,
        USER_DATA,
        USER_POST,
        CHANNEL
    } state_t;
    
    state_t state, next_state;
    
    // カウンタ
    logic [7:0]  bit_counter;      // フレーム内ビット位置
    logic [7:0]  clk_counter;      // ビット内クロックカウンタ
    logic [7:0]  bit_clocks_target;// 現在ビットのクロック数
    logic [11:0] bit_edge_clocks;  // ビット境界の累積クロック（丸め済み）
    logic [4:0]  nibble_counter;   // ニブルカウンタ (0-5)
    logic [2:0]  channel_counter;  // チャンネルカウンタ (0-7)
    real         bit_phase_clocks; // 実数クロックの累積
    
    // データ
    logic [255:0] frame_data;      // フレームデータ (ビット列)
    logic [29:0]  channel_encoded; // エンコード済みチャンネルデータ
    logic         current_bit;     // 現在のビット
    logic         nrzi_level;      // NRZI出力レベル
    
    // 24ビットを30ビットにエンコード (4ビット + 1ビット同期) × 6
    function automatic logic [29:0] encode_24bit(input logic [23:0] data);
        logic [29:0] encoded;
        encoded[29:25] = {data[23:20], 1'b1};  // ニブル5 + sync
        encoded[24:20] = {data[19:16], 1'b1};  // ニブル4 + sync
        encoded[19:15] = {data[15:12], 1'b1};  // ニブル3 + sync
        encoded[14:10] = {data[11:8],  1'b1};  // ニブル2 + sync
        encoded[9:5]   = {data[7:4],   1'b1};  // ニブル1 + sync
        encoded[4:0]   = {data[3:0],   1'b1};  // ニブル0 + sync
        return encoded;
    endfunction
    
    // フレームデータ構築
    logic [255:0] build_frame;
    logic [3:0] effective_user_in;  // S/MUX2モードを考慮したユーザーデータ
    
    // ユーザービット調整: S/MUX2はU2=1, 44.1kHzはニブル回転
    always_comb begin
        effective_user_in = user_in;

        // 44.1kHz系ではuser nibbleを回転して整合を取る
        if ((SAMPLE_RATE == 44100) && (SMUX2_MODE == 0)) begin
            effective_user_in = {user_in[3], user_in[0], user_in[1], user_in[2]};
        end

        if (SMUX2_MODE == 1) begin
            effective_user_in[1] = 1'b1;  // U2 = 1 for S/MUX2
        end
    end
    
    always_comb begin
        build_frame[255:246] = 10'b0000000000; // Sync
        build_frame[245] = 1'b1;
        // User data (4bit)
        build_frame[244:241] = effective_user_in;
        // Post-user sync bit
        build_frame[240] = 1'b1;
        // 8チャンネル × 30ビット = 240ビット
        build_frame[239:210] = encode_24bit(audio_in[0]);
        build_frame[209:180] = encode_24bit(audio_in[1]);
        build_frame[179:150] = encode_24bit(audio_in[2]);
        build_frame[149:120] = encode_24bit(audio_in[3]);
        build_frame[119:90]  = encode_24bit(audio_in[4]);
        build_frame[89:60]   = encode_24bit(audio_in[5]);
        build_frame[59:30]   = encode_24bit(audio_in[6]);
        build_frame[29:0]    = encode_24bit(audio_in[7]);
    end
    
    // ビットカウンタからフレームデータのビットを取得
    assign current_bit = frame_data[255 - bit_counter];
    
    // メイン状態機械
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_counter <= 8'd0;
            clk_counter <= 8'd0;
            bit_clocks_target <= CLOCKS_PER_BIT_INIT;
            bit_edge_clocks <= CLOCKS_PER_BIT_INIT;
            bit_phase_clocks <= CLOCKS_PER_BIT_REAL;
            frame_data <= 256'd0;
            nrzi_level <= 1'b0;
            frame_done <= 1'b0;
        end else begin
            frame_done <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SYNC;
                        frame_data <= build_frame;
                        bit_counter <= 8'd0;
                        clk_counter <= 8'd0;
                        bit_clocks_target <= CLOCKS_PER_BIT_INIT;
                        bit_edge_clocks <= CLOCKS_PER_BIT_INIT;
                        bit_phase_clocks <= CLOCKS_PER_BIT_REAL;
                    end
                end
                
                SYNC: begin
                    if (clk_counter >= bit_clocks_target - 1) begin
                        clk_counter <= 8'd0;
                        // NRZIエンコード: 1なら遷移
                        if (current_bit) begin
                            nrzi_level <= ~nrzi_level;
                        end
                        
                        if (bit_counter >= 8'd255) begin
                            state <= IDLE;
                            frame_done <= 1'b1;
                        end else begin
                            int next_edge_clocks;
                            real next_phase_clocks;

                            bit_counter <= bit_counter + 8'd1;

                            // 次ビット幅を実数累積から決定
                            next_phase_clocks = bit_phase_clocks + CLOCKS_PER_BIT_REAL;
                            next_edge_clocks = $rtoi(next_phase_clocks + 0.5);

                            bit_phase_clocks <= next_phase_clocks;
                            bit_clocks_target <= next_edge_clocks - bit_edge_clocks;
                            bit_edge_clocks <= next_edge_clocks;
                        end
                    end else begin
                        clk_counter <= clk_counter + 8'd1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    assign adat_out = nrzi_level;

endmodule
