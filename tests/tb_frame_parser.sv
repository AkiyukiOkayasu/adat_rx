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

        // user bits at bit 5
        // Frame structure after sync: [1-bit separator][4-bit user][1-bit separator]...
        // After 5 bits: shift_next[4] = separator, shift_next[3:0] = user data
        // Extraction reverses: {shift_next[0], shift_next[1], shift_next[2], shift_next[3]} = user
        //
        // For user = 0xA = 1010b, we need:
        //   shift_next[0]=1, [1]=0, [2]=1, [3]=0, [4]=1(separator)
        // Shift puts i_bits in order: shift_next[4:0] = {i_bits[0], i_bits[1], i_bits[2], i_bits[3], i_bits[4]}
        // So i_bits[0]=1, [1]=0, [2]=1, [3]=0, [4]=1 → i_bits = 5'b10101
        push_bits(5'b10101, 3'd5);
        if (user !== 4'b1010) begin
            $display("FAIL: user expected 1010 got %b", user);
            pass = 0;
        end

        // ch0 data at bit 35 (30 bits after)
        // For data = 0xFFFFFF, each nibble = 0xF = 1111b
        // Reversed = 1111b, so input = 5'b11111
        repeat (6) begin
            push_bits(5'b11111, 3'd5);
        end
        if (!(data_valid && channel == 3'd0 && data == 24'hFFFFFF)) begin
            $display("FAIL: ch0 data expected FFFFFF got %h", data);
            pass = 0;
        end

        // === Bit order verification test ===
        $display("=== Bit Order Verification ===");

        // Reset for new test
        sync = 1'b0;
        @(posedge clk);
        sync = 1'b1;
        repeat (2) @(posedge clk);

        // Test pattern: Ch0 = 24'h123456
        // 30bit encoding: 6 nibbles of 5 bits each
        // Each nibble: {data[3:0], sync_bit}
        // frame_parser extracts: {shift_next[29:26], shift_next[24:21], ...}
        // which gets nibble upper 4 bits from each 5-bit segment
        //
        // Because bits are reversed during shift ({i_bits[0], i_bits[1], ...}),
        // and then extracted in specific positions, the input encoding must match
        // what bit_decoder actually produces.
        //
        // For 24'h123456:
        // nibble 5 (MSB): 0x1 = 0001b -> input needs to produce shift_next[29:26] = 0001
        // nibble 4: 0x2 = 0010b -> shift_next[24:21] = 0010
        // nibble 3: 0x3 = 0011b -> shift_next[19:16] = 0011
        // nibble 2: 0x4 = 0100b -> shift_next[14:11] = 0100
        // nibble 1: 0x5 = 0101b -> shift_next[9:6] = 0101
        // nibble 0 (LSB): 0x6 = 0110b -> shift_next[4:1] = 0110
        //
        // The shift operation reverses bits: {shift_reg[24:0], i_bits[0], i_bits[1], i_bits[2], i_bits[3], i_bits[4]}
        // So for 5 bits input, the MSB of i_bits ends up at lower position in shift_reg
        // After 5-bit push, bits land at [4:0] in order: {i_bits[4], i_bits[3], i_bits[2], i_bits[1], i_bits[0]} reversed
        // Actually: shift_next = {shift_reg[24:0], i_bits[0], i_bits[1], i_bits[2], i_bits[3], i_bits[4]}
        // So i_bits[0] goes to position 4, i_bits[4] goes to position 0
        //
        // For nibble to appear as DATA at [29:26] after 6 pushes:
        // - First push puts 5 bits at [4:0]
        // - After 6 pushes, first nibble is at [29:25]
        // - Extraction takes [29:26] = bits 29,28,27,26
        // - These correspond to: i_bits[0] at 29, i_bits[1] at 28, i_bits[2] at 27, i_bits[3] at 26
        // - So for data nibble 0x1 = 0001b, we need i_bits[0]=0, i_bits[1]=0, i_bits[2]=0, i_bits[3]=1
        // - That means i_bits = 5'b?1000 where ? is sync bit at i_bits[4]
        // - i_bits = 5'b11000 (sync=1, data reversed = 1000)

        // Push user bits first (5 bits) - user = 0xA
        push_bits(5'b11010, 3'd5);  // user = 0xA = 1010b (reversed in input)

        // Push 30 bits for Ch0 as 6 x 5-bit nibbles
        // Each nibble format: {sync, data_reversed[3:0]}
        // 0x1 = 0001b reversed = 1000b -> 5'b11000
        // 0x2 = 0010b reversed = 0100b -> 5'b10100
        // 0x3 = 0011b reversed = 1100b -> 5'b11100
        // 0x4 = 0100b reversed = 0010b -> 5'b10010
        // 0x5 = 0101b reversed = 1010b -> 5'b11010
        // 0x6 = 0110b reversed = 0110b -> 5'b10110
        push_bits(5'b11000, 3'd5);  // nibble 5: 0x1
        push_bits(5'b10100, 3'd5);  // nibble 4: 0x2
        push_bits(5'b11100, 3'd5);  // nibble 3: 0x3
        push_bits(5'b10010, 3'd5);  // nibble 2: 0x4
        push_bits(5'b11010, 3'd5);  // nibble 1: 0x5
        push_bits(5'b10110, 3'd5);  // nibble 0: 0x6

        // Check if frame_parser extracts 24'h123456
        if (!(data_valid && channel == 3'd0)) begin
            $display("FAIL: bit-order - data_valid=%b channel=%0d (expected valid, ch0)", data_valid, channel);
            pass = 0;
        end else if (data !== 24'h123456) begin
            $display("FAIL: bit-order - Expected 123456 got %h", data);
            pass = 0;
        end else begin
            $display("PASS: bit-order test");
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
