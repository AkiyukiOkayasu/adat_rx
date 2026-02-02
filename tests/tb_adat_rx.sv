// ADAT受信器テストベンチ
//
// adat_rxモジュールの検証を行う。
// ADATジェネレータで生成したテストパターンをデコードし、
// 正しくPCMデータが復元されることを確認する。

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
    
    // DUT (Verylが生成したモジュール名を使用)
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
    
    // テストシーケンス
    int frame_count;
    int error_count;
    int test_pass;
    
    initial begin
        $display("=== ADAT Receiver Test ===");
        $display("Clock: 100MHz, Sample Rate: 48kHz");
        
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
        
        // 複数フレーム送信 (ロックに十分なフレーム数)
        repeat (10) begin
            gen_start = 1;
            #10;
            gen_start = 0;
            
            // フレーム完了待ち
            wait(gen_done);
            #10;
            
            frame_count++;
            $display("Frame %0d generated", frame_count);
            
            // 次のフレーム開始まで最小待機
            #100;
        end
        
        // ロック確認 (ロックするまで待機)
        #100_000;
        if (locked) begin
            $display("PASS: Receiver locked");
        end else begin
            $display("FAIL: Receiver not locked");
            test_pass = 0;
        end
        
        // 追加フレーム送信してデータ確認 (短縮版)
        repeat (3) begin
            gen_start = 1;
            #10;
            gen_start = 0;
            wait(gen_done);
            #10;
            
            // valid待ち
            @(posedge valid);
            #10;
            
            // データ比較
            for (int i = 0; i < 8; i++) begin
                if (channels[i] !== test_audio[i]) begin
                    $display("FAIL: Channel %0d mismatch. Expected: %h, Got: %h", 
                             i, test_audio[i], channels[i]);
                    error_count++;
                    test_pass = 0;
                end
            end
            
            // ユーザーデータ確認
            if (user_out !== test_user) begin
                $display("FAIL: User data mismatch. Expected: %h, Got: %h",
                         test_user, user_out);
                error_count++;
                test_pass = 0;
            end
            
            #1000;
        end
        
        // 結果表示
        $display("");
        $display("=== Test Results ===");
        $display("Frames sent: %0d", frame_count + 10);
        $display("Errors: %0d", error_count);
        $display("Sample Rate: %s", 
                 sample_rate == SampleRate_Rate48kHz ? "48kHz" :
                 sample_rate == SampleRate_Rate96kHz ? "96kHz" : "192kHz");
        
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
    
    // タイムアウト (十分な時間を確保)
    initial begin
        #300_000_000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
