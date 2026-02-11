`timescale 1ns / 1ps

module tb_timing_tracker;
    logic clk;
    logic rst;
    logic edge_pulse;
    logic [11:0] edge_time;
    logic [9:0] max_time;
    logic sync_detect;
    logic [11:0] frame_time;

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    adat_rx_timing_tracker u_dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_edge(edge_pulse),
        .o_edge_time(edge_time),
        .o_max_time(max_time),
        .o_sync_detect(sync_detect),
        .o_frame_time(frame_time)
    );

    int pass;

    task pulse_edge(input int gap_cycles);
        begin
            edge_pulse = 1'b0;
            repeat (gap_cycles) @(posedge clk);
            edge_pulse = 1'b1;
            @(posedge clk);
            edge_pulse = 1'b0;
        end
    endtask

    initial begin
        pass = 1;
        rst = 1'b0;
        edge_pulse = 1'b0;
        repeat (2) @(posedge clk);
        rst = 1'b1;
        repeat (2) @(posedge clk);

        if (max_time !== 10'd10) begin
            $display("FAIL: max_time init %0d", max_time);
            pass = 0;
        end

        pulse_edge(4);
        if (sync_detect !== 1'b1) begin
            $display("FAIL: sync_detect should be 1 for short interval");
            pass = 0;
        end

        pulse_edge(40);
        if (sync_detect !== 1'b0) begin
            $display("FAIL: sync_detect should be 0 for long interval");
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
        $dumpfile("tb_timing_tracker.vcd");
        $dumpvars(0, tb_timing_tracker);
    end
endmodule
