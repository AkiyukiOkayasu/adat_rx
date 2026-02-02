// ADAT受信器テストベンチ
//
// adat_rxモジュールの検証を行う。
// ADATジェネレータで生成したテストパターンをデコードし、
// 生成データと完全一致することを確認する。

`timescale 1ns / 1ps

module tb_adat_rx;
    // パッケージをインポート
    import adat_rx_adat_pkg::*;

    // クロック・リセット
    logic clk;
    logic rst;
    
    // DUT信号
    logic        adat_in;
    logic [3:0]  user_out;
    logic        word_clk;
    SampleRate   sample_rate;
    logic [23:0] channels [0:7];
    logic        valid;
    logic        locked;
    
    // テストデータ
    logic [23:0] test_audio [0:7];
    logic [3:0]  test_user;
    logic        gen_start;
    logic        gen_done;
    
    // クロック生成 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // ADATジェネレータ
    adat_generator #(
        .CLK_FREQ(100_000_000),
        .SAMPLE_RATE(48000)
    ) u_gen (
        .clk(clk),
        .rst_n(rst),
        .audio_in(test_audio),
        .user_in(test_user),
        .start(gen_start),
        .adat_out(adat_in),
        .frame_done(gen_done)
    );
    
    // DUT internal probes for debugging
    logic        dbg_adat_edge;
    logic        dbg_adat_synced;
    logic [11:0] dbg_frame_time;
    logic [9:0]  dbg_max_time;
    logic        dbg_sync_detect;
    logic [4:0]  dbg_bits;
    logic [2:0]  dbg_bit_count;
    logic        dbg_bits_valid;
    logic [29:0] dbg_shift_reg;
    logic [7:0]  dbg_bit_counter;
    logic [2:0]  dbg_channel;
    logic        dbg_data_valid;
    logic [3:0]  dbg_frame_cnt;
    
    adat_rx_adat_rx u_dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_adat(adat_in),
        .o_user(user_out),
        .o_word_clk(word_clk),
        .o_sample_rate(sample_rate),
        .o_channels(channels),
        .o_valid(valid),
        .o_locked(locked)
    );
    
    // Probe internal signals
    assign dbg_adat_edge = u_dut.adat_edge;
    assign dbg_adat_synced = u_dut.synced;
    assign dbg_frame_time = u_dut.frame_time;
    assign dbg_max_time = u_dut.max_time;
    assign dbg_sync_detect = u_dut.sync_detect;
    assign dbg_bits = u_dut.bits;
    assign dbg_bit_count = u_dut.bit_count;
    assign dbg_bits_valid = u_dut.bits_valid;
    assign dbg_shift_reg = u_dut.u_frame_parser.shift_reg;
    assign dbg_bit_counter = u_dut.u_frame_parser.bit_counter;
    assign dbg_channel = u_dut.channel;
    assign dbg_data_valid = u_dut.data_valid;
    assign dbg_frame_cnt = u_dut.u_output_interface.frame_cnt;
    
    int frame_count;
    int error_count;
    int test_pass;
    logic got_valid;
    
    initial begin
        $display("Clock: 100MHz, Sample Rate: 48kHz");
        $display("=== ADAT Receiver Test (Strict Comparison) ===");
        
        // 初期化 (DUTはアクティブローリセット)
        rst = 0;
        gen_start = 0;
        frame_count = 0;
        error_count = 0;
        test_pass = 1;
        
        // テストデータ設定
        test_user = 4'hA;
        test_audio[0] = 24'h123456;
        test_audio[1] = 24'h789ABC;
        test_audio[2] = 24'hDEF012;
        test_audio[3] = 24'h345678;
        test_audio[4] = 24'h9ABCDE;
        test_audio[5] = 24'hF01234;
        test_audio[6] = 24'h567890;
        test_audio[7] = 24'hABCDEF;
        
        // リセット解除 (アクティブローなので1にする)
        #100;
        rst = 1;
        #100;

        // 連続フレーム送信を開始（startを保持すると連続生成される）
        gen_start = 1;
        
        // 複数フレーム送信 (ロックに十分なフレーム数)
        repeat (10) begin
            @(posedge gen_done);
            #10;
            frame_count++;
            $display("Frame %0d generated", frame_count);
        end
        
        // ロック確認
        #100;
        
        // Debug output
        $display("\n=== Debug Info ===");
        $display("adat_in: %b", adat_in);
        $display("ADAT edge: %b, Synced: %b", dbg_adat_edge, dbg_adat_synced);
        $display("Frame time: %0d (expected ~2083)", dbg_frame_time);
        $display("Max time: %0d", dbg_max_time);
        $display("Sync detect: %b", dbg_sync_detect);
        $display("Bits valid: %b, Bit count: %0d, Bits: %b", dbg_bits_valid, dbg_bit_count, dbg_bits);
        $display("Bit counter: %0d, Shift reg: %h", dbg_bit_counter, dbg_shift_reg);
        $display("Data valid: %b, Channel: %0d", dbg_data_valid, dbg_channel);
        $display("Frame cnt: %0d", dbg_frame_cnt);
        $display("Locked: %b", locked);
        
        if (!locked) begin
            $display("FAIL: Receiver not locked");
            test_pass = 0;
            $finish;
        end else begin
            $display("PASS: Receiver locked");
        end
        
        $display("\nStarting strict data comparison...");
        
        repeat (5) begin
            got_valid = 1'b0;
            fork
                begin @(posedge valid); got_valid = 1'b1; end
                begin #200_000; end
            join_any
            disable fork;
            
            if (!got_valid) begin
                $display("FAIL: Timeout waiting for valid");
                error_count++;
                test_pass = 0;
                $finish;
            end
            
            #10;
            
            $display("\nFrame received, comparing all channels:");
            for (int i = 0; i < 8; i++) begin
                if (channels[i] !== test_audio[i]) begin
                    $display("  Channel %0d: FAIL - Expected: %h, Got: %h", 
                             i, test_audio[i], channels[i]);
                    error_count++;
                    test_pass = 0;
                end else begin
                    $display("  Channel %0d: PASS - %h", i, channels[i]);
                end
            end
            
            if (user_out !== test_user) begin
                $display("  User data: FAIL - Expected: %h, Got: %h", test_user, user_out);
                error_count++;
                test_pass = 0;
            end else begin
                $display("  User data: PASS - %h", user_out);
            end
            
            #100;
        end
        
        $display("\n=== Test Results ===");
        $display("Frames sent: %0d", frame_count);
        $display("Errors: %0d", error_count);
        
        if (test_pass && error_count == 0) begin
            $display("*** TEST PASSED ***");
        end else begin
            $display("*** TEST FAILED ***");
        end
        
        #1000;
        $finish;
    end
    
    // 波形ダンプ
    initial begin
        $dumpfile("adat_rx.vcd");
        $dumpvars(0, tb_adat_rx);
    end

endmodule
