`timescale 1ns / 1ps

module tb_edge_detector;
  logic clk;
  logic rst;
  logic adat_in;
  logic edge_pulse;
  logic synced;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  adat_rx_edge_detector u_dut (
      .i_clk(clk),
      .i_rst(rst),
      .i_adat(adat_in),
      .o_edge(edge_pulse),
      .o_synced(synced)
  );

  int pass;

  initial begin
    pass = 1;
    rst = 1'b0;
    adat_in = 1'b0;
    repeat (2) @(posedge clk);
    rst = 1'b1;
    repeat (2) @(posedge clk);

    if (edge_pulse !== 1'b0 || synced !== 1'b0) begin
      $display("FAIL: reset state edge=%b synced=%b", edge_pulse, synced);
      pass = 0;
    end

    adat_in = 1'b1;
    repeat (3) @(posedge clk);
    if (synced !== 1'b1) begin
      $display("FAIL: synced did not go high");
      pass = 0;
    end

    adat_in = 1'b0;
    repeat (3) @(posedge clk);
    if (synced !== 1'b0) begin
      $display("FAIL: synced did not go low");
      pass = 0;
    end

    if (pass) begin
      $display("*** TEST PASSED ***");
    end else begin
      $display("*** TEST FAILED ***");
    end

    #20;
    $finish;
  end

  initial begin
    $dumpfile("tb_edge_detector.vcd");
    $dumpvars(0, tb_edge_detector);
  end
endmodule
