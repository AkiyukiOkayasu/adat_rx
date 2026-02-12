// ADAT受信器テストベンチ: ジェネレータ生成データとの厳密比較

`timescale 1ns / 1ps

module tb_adat_rx;
  // パッケージをインポート
  import adat_rx_adat_pkg::*;

  // クロック・リセット
  logic           clk;
  logic           rst;

  // DUT信号
  logic           adat_in;
  logic    [ 3:0] user_out;
  logic           word_clk;
  SmuxMode        smux_mode;
  logic    [23:0] channels  [0:7];
  logic           valid;
  logic           locked;

  // テストデータ
  logic    [23:0] test_audio[0:7];
  logic    [ 3:0] test_user;
  logic           gen_start;
  logic           gen_done;

  // クロック生成 (50MHz)
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  // ADATジェネレータ (通常モード)
  adat_generator #(
      .CLK_FREQ(50_000_000),
      .SAMPLE_RATE(48000),
      .SMUX2_MODE(0)
  ) u_gen (
      .clk(clk),
      .rst_n(rst),
      .audio_in(test_audio),
      .user_in(test_user),
      .start(gen_start),
      .adat_out(adat_in),
      .frame_done(gen_done)
  );

  // ADATジェネレータ (44.1kHzモード用)
  logic        adat_in_44k;
  logic        gen_done_44k;
  logic        gen_start_44k;
  logic [23:0] test_audio_44k[0:7];
  logic [ 3:0] test_user_44k;

  adat_generator #(
      .CLK_FREQ(50_000_000),
      .SAMPLE_RATE(44100),
      .SMUX2_MODE(0)
  ) u_gen_44k (
      .clk(clk),
      .rst_n(rst),
      .audio_in(test_audio_44k),
      .user_in(test_user_44k),
      .start(gen_start_44k),
      .adat_out(adat_in_44k),
      .frame_done(gen_done_44k)
  );

  // ADATジェネレータ (S/MUX2モード用 - 96kHz)
  logic        adat_in_smux2;
  logic        gen_done_smux2;
  logic        gen_start_smux2;
  logic [23:0] test_audio_smux2[0:7];
  logic [ 3:0] test_user_smux2;

  adat_generator #(
      .CLK_FREQ(50_000_000),
      .SAMPLE_RATE(48000),
      .SMUX2_MODE(1)
  ) u_gen_smux2 (
      .clk(clk),
      .rst_n(rst),
      .audio_in(test_audio_smux2),
      .user_in(test_user_smux2),
      .start(gen_start_smux2),
      .adat_out(adat_in_smux2),
      .frame_done(gen_done_smux2)
  );

  // ADATジェネレータ (S/MUX2モード用 - 88.2kHz)
  logic        adat_in_smux2_88k;
  logic        gen_done_smux2_88k;
  logic        gen_start_smux2_88k;
  logic [23:0] test_audio_smux2_88k[0:7];
  logic [ 3:0] test_user_smux2_88k;

  adat_generator #(
      .CLK_FREQ(50_000_000),
      .SAMPLE_RATE(44100),
      .SMUX2_MODE(1)
  ) u_gen_smux2_88k (
      .clk(clk),
      .rst_n(rst),
      .audio_in(test_audio_smux2_88k),
      .user_in(test_user_smux2_88k),
      .start(gen_start_smux2_88k),
      .adat_out(adat_in_smux2_88k),
      .frame_done(gen_done_smux2_88k)
  );

  // Multiplexed ADAT input (select between normal, 44.1kHz, S/MUX2 96kHz, and S/MUX2 88.2kHz generators)
  logic adat_in_muxed;
  assign adat_in_muxed = gen_start_smux2_88k ? adat_in_smux2_88k : (gen_start_smux2 ? adat_in_smux2 : (gen_start_44k ? adat_in_44k : adat_in));

  // DUT内部プローブ(デバッグ用)
  logic        dbg_adat_edge;
  logic        dbg_adat_synced;
  logic [11:0] dbg_frame_time;
  logic [ 9:0] dbg_max_time;
  logic        dbg_sync_detect;
  logic [ 4:0] dbg_bits;
  logic [ 2:0] dbg_bit_count;
  logic        dbg_bits_valid;
  logic [29:0] dbg_shift_reg;
  logic [ 7:0] dbg_bit_counter;
  logic [ 2:0] dbg_channel;
  logic        dbg_data_valid;
  logic [ 3:0] dbg_frame_cnt;
  logic [ 3:0] valid_channels;

  adat_rx_adat_rx u_dut (
      .i_clk(clk),
      .i_rst(rst),
      .i_adat(adat_in_muxed),
      .o_user(user_out),
      .o_word_clk(word_clk),
      .o_smux_mode(smux_mode),
      .o_channels(channels),
      .o_valid(valid),
      .o_locked(locked),
      .o_valid_channels(valid_channels)
  );

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

  // Metrics collection
  /* verilator lint_off BLKSEQ */
  always @(posedge clk) begin
    if (dbg_bits_valid) begin
      bits_valid_count++;
      if (dbg_bit_count >= 1 && dbg_bit_count <= 5) bit_count_hist[dbg_bit_count]++;
    end
    if (dbg_data_valid) begin
      if (dbg_channel <= 7) boundary_pass[dbg_channel]++;
    end
  end
  /* verilator lint_on BLKSEQ */

  int frame_count;
  int error_count;
  int test_pass;
  logic got_valid;

  // Metrics counters
  int bits_valid_count;
  int bit_count_hist[0:5];  // index 0 unused, 1-5 for bit counts
  int boundary_pass[0:7];  // boundary crossing counts for each channel

  // S/MUX2 test variables
  int smux2_errors;
  int valid_count_per_frame;

  initial begin
    $display("Clock: 50MHz, Sample Rate: 48kHz");
    $display("=== ADAT Receiver Test (Strict Comparison) ===");

    // 初期化 (DUT: アクティブローリセット)
    rst = 0;
    gen_start = 0;
    frame_count = 0;
    error_count = 0;
    test_pass = 1;

    // Metrics initialization
    bits_valid_count = 0;
    for (int i = 0; i <= 5; i++) bit_count_hist[i] = 0;
    for (int i = 0; i <= 7; i++) boundary_pass[i] = 0;

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

    $display("\n--- Monitoring first frame ---");
    fork
      begin
        int edge_count = 0;
        int timeout = 0;
        while (edge_count < 100 && timeout < 50000) begin
          @(posedge clk);
          timeout++;
          if (dbg_adat_edge) begin
            edge_count++;
            if (edge_count <= 5) begin
              $display("Edge %0d detected at time %0t: adat_in=%b, synced=%b", edge_count, $time,
                       adat_in, dbg_adat_synced);
            end
          end
        end
        $display("Total edges detected: %0d", edge_count);
      end
    join_none

    // フレーム完了を待つ（メインスレッドで実行）
    repeat (10) begin
      @(posedge gen_done);
      #10;
      frame_count++;
      $display("Frame %0d completed", frame_count);
    end

    // エッジモニタを停止
    disable fork;

    // ロック確認
    #100;

    $display("\n=== Metrics ===");
    $display("bits_valid_count: %0d", bits_valid_count);
    $display("bit_count_hist: 1bit=%0d, 2bit=%0d, 3bit=%0d, 4bit=%0d, 5bit=%0d", bit_count_hist[1],
             bit_count_hist[2], bit_count_hist[3], bit_count_hist[4], bit_count_hist[5]);
    $display(
        "boundary_pass: ch0=%0d, ch1=%0d, ch2=%0d, ch3=%0d, ch4=%0d, ch5=%0d, ch6=%0d, ch7=%0d",
        boundary_pass[0], boundary_pass[1], boundary_pass[2], boundary_pass[3], boundary_pass[4],
        boundary_pass[5], boundary_pass[6], boundary_pass[7]);

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
        begin
          @(posedge valid);
          got_valid = 1'b1;
        end
        begin
          #200_000;
        end
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
          $display("  Channel %0d: FAIL - Expected: %h, Got: %h", i, test_audio[i], channels[i]);
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

    // ==================== 44.1kHz TEST ====================
    $display("\n=== 44.1kHz Test ===");
    $display("Clock: 50MHz, Sample Rate: 44.1kHz");

    // テストデータ設定
    test_user_44k = 4'hB;
    test_audio_44k[0] = 24'h441100;
    test_audio_44k[1] = 24'h441111;
    test_audio_44k[2] = 24'h441122;
    test_audio_44k[3] = 24'h441133;
    test_audio_44k[4] = 24'h441144;
    test_audio_44k[5] = 24'h441155;
    test_audio_44k[6] = 24'h441166;
    test_audio_44k[7] = 24'h441177;

    // リセット
    rst = 0;
    gen_start = 0;
    gen_start_44k = 0;
    gen_start_smux2 = 0;
    frame_count = 0;
    error_count = 0;
    test_pass = 1;
    #100;
    rst = 1;
    #100;

    // 44.1kHzフレーム送信開始
    gen_start_44k = 1;

    // フレーム送信
    repeat (10) begin
      @(posedge gen_done_44k);
      #10;
      frame_count++;
      $display("44.1kHz Frame %0d completed", frame_count);
    end

    // ロック確認
    #100;

    $display("\n=== 44.1kHz Debug Info ===");
    $display("Frame time: %0d (expected ~2268 for 44.1kHz)", dbg_frame_time);
    $display("Max time: %0d", dbg_max_time);
    $display("Locked: %b", locked);

    if (!locked) begin
      $display("44.1kHz FAIL: Receiver not locked");
      test_pass = 0;
      $finish;
    end else begin
      $display("44.1kHz PASS: Receiver locked");
    end

    $display("\n44.1kHz: Starting strict data comparison...");

    repeat (5) begin
      got_valid = 1'b0;
      fork
        begin
          @(posedge valid);
          got_valid = 1'b1;
        end
        begin
          #200_000;
        end
      join_any
      disable fork;

      if (!got_valid) begin
        $display("44.1kHz FAIL: Timeout waiting for valid");
        error_count++;
        test_pass = 0;
        $finish;
      end

      #10;

      $display("\n44.1kHz Frame received, comparing all channels:");
      for (int i = 0; i < 8; i++) begin
        if (channels[i] !== test_audio_44k[i]) begin
          $display("  44.1kHz Channel %0d: FAIL - Expected: %h, Got: %h", i, test_audio_44k[i],
                   channels[i]);
          error_count++;
          test_pass = 0;
        end else begin
          $display("  44.1kHz Channel %0d: PASS - %h", i, channels[i]);
        end
      end

      if (user_out !== test_user_44k) begin
        $display("  44.1kHz User data: FAIL - Expected: %h, Got: %h", test_user_44k, user_out);
        error_count++;
        test_pass = 0;
      end else begin
        $display("  44.1kHz User data: PASS - %h", user_out);
      end

      #100;
    end

    $display("\n=== 44.1kHz Test Results ===");
    $display("Frames sent: %0d", frame_count);
    $display("Errors: %0d", error_count);

    if (test_pass && error_count == 0) begin
      $display("*** 44.1kHz TEST PASSED ***");
    end else begin
      $display("*** 44.1kHz TEST FAILED ***");
    end

    // ==================== S/MUX2 TEST ====================
    $display("\n=== S/MUX2 Test (96kHz 4ch mode) ===");

    // テストデータ設定 (8チャンネル分のデータを用意)
    test_user_smux2 = 4'b0000;  // user_in[2]は自動的に1になる
    test_audio_smux2[0] = 24'hAA0000;
    test_audio_smux2[1] = 24'hAA1111;
    test_audio_smux2[2] = 24'hBB0000;
    test_audio_smux2[3] = 24'hBB1111;
    test_audio_smux2[4] = 24'hCC0000;
    test_audio_smux2[5] = 24'hCC1111;
    test_audio_smux2[6] = 24'hDD0000;
    test_audio_smux2[7] = 24'hDD1111;

    // リセット
    rst = 0;
    gen_start = 0;
    gen_start_smux2 = 0;
    #100;
    rst = 1;
    #100;

    // S/MUX2フレーム送信開始
    gen_start_smux2 = 1;

    // 10フレーム送信
    repeat (10) begin
      @(posedge gen_done_smux2);
      #10;
    end

    // ロック確認
    #100;
    if (!locked) begin
      $display("S/MUX2 FAIL (expected): Receiver not locked");
    end else begin
      $display("S/MUX2: Receiver locked");
    end

    // S/MUX2期待値チェック (これらは現在のDUTでは失敗するはず)
    smux2_errors = 0;
    valid_count_per_frame = 0;

    // 1フレーム分のo_validパルスをカウント (クロック周波数非依存)
    @(posedge gen_done_smux2);
    @(negedge gen_done_smux2);  // frame_doneパルスが終わるまで待つ
    fork
      begin
        repeat (10000) begin
          @(posedge clk);
          if (valid) valid_count_per_frame = valid_count_per_frame + 1;
        end
      end
      begin
        @(posedge gen_done_smux2);
      end
    join_any
    disable fork;

    $display("S/MUX2: o_valid pulses per frame: %0d (expected: 2)", valid_count_per_frame);
    if (valid_count_per_frame != 2) begin
      $display("  FAIL (expected): o_valid count mismatch");
      smux2_errors = smux2_errors + 1;
    end

    // サンプルレートチェック
    $display("S/MUX2: user_out (user_bits): %b", user_out);
    $display("S/MUX2: o_valid_channels: %0d (expected: 4)", valid_channels);
    $display("S/MUX2: o_smux_mode: %s (expected: Smux2)", smux_mode.name());
    if (smux_mode != SmuxMode_Smux2) begin
      $display("  FAIL (expected): S/MUX mode is not S/MUX2");
      smux2_errors = smux2_errors + 1;
    end

    // データ整合性チェック (物理チャンネル0-7がそのまま出力されることを確認)
    @(posedge valid);
    #10;
    $display("S/MUX2: Checking data integrity...");
    for (int i = 0; i < 8; i = i + 1) begin
      if (channels[i] !== test_audio_smux2[i]) begin
        $display("  Channel %0d: FAIL - Expected: %h, Got: %h", i, test_audio_smux2[i],
                 channels[i]);
        smux2_errors = smux2_errors + 1;
      end else begin
        $display("  Channel %0d: PASS - %h", i, channels[i]);
      end
    end

    $display("\n=== S/MUX2 Test Results ===");
    $display("Errors: %0d", smux2_errors);
    if (smux2_errors > 0) begin
      $display("*** S/MUX2 TEST FAILED ***");
    end else begin
      $display("*** S/MUX2 TEST PASSED ***");
    end

    // ==================== 88.2kHz S/MUX2 TEST ====================
    $display("\n=== 88.2kHz S/MUX2 Test (88.2kHz 4ch mode) ===");

    // テストデータ設定 (8チャンネル分のデータを用意)
    test_user_smux2_88k = 4'b0000;  // user_in[2]は自動的に1になる
    test_audio_smux2_88k[0] = 24'h882000;
    test_audio_smux2_88k[1] = 24'h882111;
    test_audio_smux2_88k[2] = 24'h882200;
    test_audio_smux2_88k[3] = 24'h882311;
    test_audio_smux2_88k[4] = 24'h882400;
    test_audio_smux2_88k[5] = 24'h882511;
    test_audio_smux2_88k[6] = 24'h882600;
    test_audio_smux2_88k[7] = 24'h882711;

    // リセット
    rst = 0;
    gen_start = 0;
    gen_start_44k = 0;
    gen_start_smux2 = 0;
    gen_start_smux2_88k = 0;
    #100;
    rst = 1;
    #100;

    // 88.2kHz S/MUX2フレーム送信開始
    gen_start_smux2_88k = 1;

    // 10フレーム送信
    repeat (10) begin
      @(posedge gen_done_smux2_88k);
      #10;
    end

    // ロック確認
    #100;
    if (!locked) begin
      $display("88.2kHz S/MUX2 FAIL (expected): Receiver not locked");
    end else begin
      $display("88.2kHz S/MUX2: Receiver locked");
    end

    // S/MUX2期待値チェック (これらは現在のDUTでは失敗するはず)
    smux2_errors = 0;
    valid_count_per_frame = 0;

    // 1フレーム分のo_validパルスをカウント (クロック周波数非依存)
    @(posedge gen_done_smux2_88k);
    @(negedge gen_done_smux2_88k);  // frame_doneパルスが終わるまで待つ
    fork
      begin
        repeat (10000) begin
          @(posedge clk);
          if (valid) valid_count_per_frame = valid_count_per_frame + 1;
        end
      end
      begin
        @(posedge gen_done_smux2_88k);
      end
    join_any
    disable fork;

    $display("88.2kHz S/MUX2: o_valid pulses per frame: %0d (expected: 2)", valid_count_per_frame);
    if (valid_count_per_frame != 2) begin
      $display("  88.2kHz FAIL (expected): o_valid count mismatch");
      smux2_errors = smux2_errors + 1;
    end

    // サンプルレートチェック
    $display("88.2kHz S/MUX2: user_out (user_bits): %b", user_out);
    $display("88.2kHz S/MUX2: o_valid_channels: %0d (expected: 4)", valid_channels);
    $display("88.2kHz S/MUX2: o_smux_mode: %s (expected: Smux2)", smux_mode.name());
    if (smux_mode != SmuxMode_Smux2) begin
      $display("  88.2kHz FAIL (expected): S/MUX mode is not S/MUX2");
      smux2_errors = smux2_errors + 1;
    end

    // データ整合性チェック (物理チャンネル0-7がそのまま出力されることを確認)
    @(posedge valid);
    #10;
    $display("88.2kHz S/MUX2: Checking data integrity...");
    for (int i = 0; i < 8; i = i + 1) begin
      if (channels[i] !== test_audio_smux2_88k[i]) begin
        $display("  88.2kHz Channel %0d: FAIL - Expected: %h, Got: %h", i, test_audio_smux2_88k[i],
                 channels[i]);
        smux2_errors = smux2_errors + 1;
      end else begin
        $display("  88.2kHz Channel %0d: PASS - %h", i, channels[i]);
      end
    end

    $display("\n=== 88.2kHz S/MUX2 Test Results ===");
    $display("Errors: %0d", smux2_errors);
    if (smux2_errors > 0) begin
      $display("*** 88.2kHz S/MUX2 TEST FAILED ***");
    end else begin
      $display("*** 88.2kHz S/MUX2 TEST PASSED ***");
    end

    #1000;
    $finish;
  end

  // 波形ダンプ
  initial begin
    $dumpfile("adat_rx.fst");
    $dumpvars(0, tb_adat_rx);
  end

endmodule
