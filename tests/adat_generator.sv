// ADATパターンジェネレータ
// 
// テスト用にADAT信号を生成する。
// 8チャンネル24ビットPCMデータをADATフレームにエンコードし、
// NRZI変換してシリアル出力する。

`timescale 1ns / 1ps

module adat_generator #(
    parameter int CLK_FREQ = 100_000_000,  // システムクロック周波数
    parameter int SAMPLE_RATE = 48000      // サンプルレート
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [23:0] audio_in [0:7],    // 8チャンネル入力
    input  logic [3:0]  user_in,           // ユーザーデータ
    input  logic        start,             // フレーム生成開始
    output logic        adat_out,          // ADAT出力 (NRZI)
    output logic        frame_done         // フレーム完了
);

    // 1ビットあたりのクロック数
    // 48kHz: 256ビット/フレーム = 12.288Mbps
    // 100MHz / 12.288MHz ≈ 8.14 clocks/bit
    localparam int CLOCKS_PER_BIT = CLK_FREQ / (SAMPLE_RATE * 256);
    
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
    logic [4:0]  nibble_counter;   // ニブルカウンタ (0-5)
    logic [2:0]  channel_counter;  // チャンネルカウンタ (0-7)
    
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
    always_comb begin
        // Sync: 10ビットの0
        build_frame[255:246] = 10'b0000000000;
        // Pre-user sync bit
        build_frame[245] = 1'b1;
        // User data (4bit)
        build_frame[244:241] = user_in;
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
                    end
                end
                
                SYNC: begin
                    if (clk_counter >= CLOCKS_PER_BIT - 1) begin
                        clk_counter <= 8'd0;
                        // NRZIエンコード: 1なら遷移
                        if (current_bit) begin
                            nrzi_level <= ~nrzi_level;
                        end
                        
                        if (bit_counter >= 8'd255) begin
                            state <= IDLE;
                            frame_done <= 1'b1;
                        end else begin
                            bit_counter <= bit_counter + 8'd1;
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
