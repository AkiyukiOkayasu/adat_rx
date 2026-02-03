`timescale 1ns / 1ps

module tb_output_interface;
    import adat_rx_adat_pkg::*;

    typedef adat_rx_adat_pkg::SampleRate SampleRate;

    logic clk;
    logic rst;
    logic [11:0] frame_time;
    logic [23:0] data;
    logic [2:0] channel;
    logic data_valid;
    logic sync;
    SampleRate sample_rate;
    logic word_clk;
    logic [23:0] channels [0:7];
    logic valid;
    logic locked;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    adat_rx_output_interface u_dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_frame_time(frame_time),
        .i_data(data),
        .i_channel(channel),
        .i_data_valid(data_valid),
        .i_sync(sync),
        .o_sample_rate(sample_rate),
        .o_word_clk(word_clk),
        .o_channels(channels),
        .o_valid(valid),
        .o_locked(locked)
    );

    task send_frame(input int frames);
        int f;
        int ch;
        begin
            for (f = 0; f < frames; f++) begin
                for (ch = 0; ch < 8; ch++) begin
                    channel = ch[2:0];
                    data = {8'hAA, 8'h00, ch[7:0]};
                    data_valid = 1'b1;
                    @(posedge clk);
                    if (channel == 3'd7 && !valid) begin
                        $display("FAIL: valid not asserted on ch7");
                        pass = 0;
                    end
                end
                data_valid = 1'b0;
                @(posedge clk);
            end
        end
    endtask

    int pass;

    initial begin
        pass = 1;
        rst = 1'b0;
        frame_time = 12'd2048;
        data = 24'd0;
        channel = 3'd0;
        data_valid = 1'b0;
        sync = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b1;
        repeat (2) @(posedge clk);

        send_frame(5);

        if (!locked) begin
            $display("FAIL: locked not asserted");
            pass = 0;
        end
        if (sample_rate !== SampleRate_Rate48kHz) begin
            $display("FAIL: sample_rate not 48kHz");
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
        $dumpfile("tb_output_interface.vcd");
        $dumpvars(0, tb_output_interface);
    end
endmodule
