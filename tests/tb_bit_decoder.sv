`timescale 1ns / 1ps

module tb_bit_decoder;
  logic clk;
  logic rst;
  logic edge_pulse;
  logic [11:0] edge_time;
  logic [11:0] frame_time;
  logic sync_mask;
  logic [4:0] bits;
  logic [2:0] bit_count;
  logic valid;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  adat_rx_bit_decoder u_dut (
      .i_clk(clk),
      .i_rst(rst),
      .i_edge(edge_pulse),
      .i_edge_time(edge_time),
      .i_frame_time(frame_time),
      .i_sync_mask(sync_mask),
      .o_bits(bits),
      .o_bit_count(bit_count),
      .o_valid(valid)
  );

  task trigger_edge(input [11:0] interval);
    begin
      edge_time  = interval;
      edge_pulse = 1'b1;
      @(posedge clk);
      edge_pulse = 1'b0;
    end
  endtask

  int pass;

  initial begin
    pass = 1;
    rst = 1'b0;
    edge_pulse = 1'b0;
    edge_time = 12'd0;
    frame_time = 12'd2048;
    sync_mask = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b1;
    repeat (2) @(posedge clk);

    trigger_edge(12'd1);
    if (!(valid && bit_count == 3'd1 && bits == 5'b00001)) begin
      $error("FAIL: 1-bit decode");
      pass = 0;
    end

    trigger_edge(12'd16);
    if (!(valid && bit_count == 3'd2 && bits == 5'b00010)) begin
      $error("FAIL: 2-bit decode");
      pass = 0;
    end

    trigger_edge(12'd40);
    if (!(valid && bit_count == 3'd5 && bits == 5'b10000)) begin
      $error("FAIL: 5-bit decode");
      pass = 0;
    end

    sync_mask = 1'b0;
    trigger_edge(12'd1);
    if (valid) begin
      $error("FAIL: valid should be 0 during sync");
      pass = 0;
    end

    if (pass) begin
      $display("*** TEST PASSED ***");
    end else begin
      $error("*** TEST FAILED ***");
    end

    #20;
    $finish;
  end

  initial begin
    $dumpfile("tb_bit_decoder.vcd");
    $dumpvars(0, tb_bit_decoder);
  end
endmodule
