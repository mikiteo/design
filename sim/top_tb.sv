`timescale 1ns/1ps

module top_tb;

    logic clk = 0;
    logic rst = 1;

    logic rx = 1;
    logic tx = 1;

    logic [15:0] r_d1, r_d2, r_d3, r_speed, r_accel;
    
    parameter BAUD_RATE = 115200;
    parameter CLK_FREQ = 100_000_000;
    parameter DELTA_T = 10;
    parameter BAUD_TICKS = CLK_FREQ / BAUD_RATE;
    parameter CLK_PERIOD = 1_000_000_000 / CLK_FREQ;

    top_module #(
        .SYNTHESIS(1'b0),
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ),
        .RAM_WIDTH(16),
        .RAM_DEPTH(1024),
        .DELTA_T(DELTA_T)
    ) dut (
        .clk_in(clk),
        .sw(rst),

        .ck_io1(rx),
        .ck_io0(tx)
    );

    task send_uart_byte(input [7:0] data);
        int i;
        begin
            // Start bit
            rx = 0;
            repeat (BAUD_TICKS) @(posedge clk);
            // Data bits (LSB first)
            for (i = 7; i >= 0; i--) begin
                rx = data[i];
                repeat (BAUD_TICKS) @(posedge clk);
            end
            // Stop bit
            rx = 1;
            repeat (2*BAUD_TICKS) @(posedge clk);
        end
    endtask

    task automatic send_uart_packet(input [15:0] distance_mm);
    logic [7:0] header1;
    logic [7:0] header2;
    logic [7:0] command;
    logic [7:0] length;
    logic [7:0] dist_hi;
    logic [7:0] dist_lo;
    logic [7:0] status;
    logic [7:0] crc;

    begin
        header1 = 8'h55;
        header2 = 8'hAA;
        command = 8'h81;
        length  = 8'h03;
        dist_hi = distance_mm[15:8];
        dist_lo = distance_mm[7:0];
        status  = 8'h00;
        crc     = 8'hFA;

        send_uart_byte(header1);
        send_uart_byte(header2);
        send_uart_byte(command);
        send_uart_byte(length);
        send_uart_byte(dist_hi);
        send_uart_byte(dist_lo);
        send_uart_byte(status);
        send_uart_byte(crc);
    end
endtask


    function automatic logic signed [15:0] calc_speed(
        input logic [15:0] d2, d3, prev_v, acc,
        input int t
    );
        logic signed [31:0] v_raw;
        logic signed [31:0] delta_v;
        logic signed [15:0] filtered_v;

        begin 
            v_raw = d3 - d2;
            v_raw = v_raw / t;

            delta_v = v_raw - prev_v;
            filtered_v = (delta_v + acc) >>> 1;

            return filtered_v[15:0]; 
        end
    endfunction

    function automatic logic signed [15:0] calc_accel (
        input logic signed [15:0] d1, d2, d3,
        input int t
    );
        logic signed [31:0] temp_a;

        begin
            temp_a = d3 - (2 * d2) + d1;
            temp_a = temp_a / (t * t);
            return temp_a[15:0];
        end
    endfunction



    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin

        repeat (3) @(posedge clk);
        rst = 0;

        send_uart_packet(16'd100);
        send_uart_packet(16'd180);
        send_uart_packet(16'd380);
        send_uart_packet(16'd600);
        
        r_d1 = 100;
        r_d2 = 180;
        r_d3 = 380;

        r_speed = calc_speed(r_d2, r_d3, 0, 0, DELTA_T);
        r_accel = calc_accel(r_d1, r_d2, r_d3, DELTA_T);
            
        $finish;
    end

endmodule
