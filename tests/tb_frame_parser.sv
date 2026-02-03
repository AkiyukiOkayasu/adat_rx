`timescale 1ns / 1ps

module tb_frame_parser;
    logic clk;
    logic rst;
    logic [4:0] bits;
    logic [2:0] bit_count;
    logic valid;
    logic sync;
    logic [3:0] user;
    logic [23:0] data;
    logic [2:0] channel;
    logic data_valid;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    adat_rx_frame_parser u_dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_bits(bits),
        .i_bit_count(bit_count),
        .i_valid(valid),
        .i_sync(sync),
        .o_user(user),
        .o_data(data),
        .o_channel(channel),
        .o_data_valid(data_valid)
    );

    task push_bits(input [4:0] value, input [2:0] count);
        begin
            bits = value;
            bit_count = count;
            valid = 1'b1;
            @(posedge clk);
            valid = 1'b0;
        end
    endtask

    int pass;

    initial begin
        pass = 1;
        rst = 1'b0;
        bits = 5'b0;
        bit_count = 3'd0;
        valid = 1'b0;
        sync = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b1;
        repeat (2) @(posedge clk);

        // user bits at bit 15
        push_bits(5'b00000, 3'd5);
        push_bits(5'b00000, 3'd5);
        push_bits(5'b01011, 3'd5);
        push_bits(5'b00001, 3'd1);
        if (user !== 4'b1011) begin
            $display("FAIL: user expected 1011 got %b", user);
            pass = 0;
        end

        sync = 1'b0;
        repeat (2) @(posedge clk);
        sync = 1'b1;

        // ch0 data at bit 45 (30 bits after)
        repeat (9) begin
            push_bits(5'b11111, 3'd5);
        end
        push_bits(5'b00001, 3'd1);
        if (!(data_valid && channel == 3'd0 && data == 24'hFFFFFF)) begin
            $display("FAIL: ch0 data expected FFFFFF got %h", data);
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
        $dumpfile("tb_frame_parser.vcd");
        $dumpvars(0, tb_frame_parser);
    end
endmodule
