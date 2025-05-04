`timescale 1ns/1ps

module top_tb;

    logic clk = 0;
    logic rst = 1;

    logic main_data_in = 1;
    logic main_data_out;
    logic [7:0] final_data;
    logic parity_error;

    logic [7:0] data_in_ram_slave_a;
    logic calc_busy;
    logic calc_ready;
    
    int r_d1, r_d2, r_d3, t = 2, r_speed, r_accel, read_speed, read_accel;
    
    parameter CLK_PERIOD = 20;           // 50 MHz
    parameter BAUD_TICKS = 4;            // 4 ticks per UART bit

    top_module #(
        .SYNTHESIS(1'b0)
    ) dut (
        .clk_in(clk),
        .reset_in(rst),

        .data_in(main_data_in),
        .data_out(main_data_out),

        .data_in_ram_slave_a(data_in_ram_slave_a),
        .calc_busy(calc_busy),
        .calc_ready(calc_ready)
    );

    task send_uart_byte(input [7:0] data);
        int i;
        bit parity;
        begin

            // Start bit
            main_data_in = 0;
            repeat (BAUD_TICKS) @(posedge clk);

            // Data bits (LSB first)
            parity = 0;
            for (i = 7; i >= 0; i--) begin
                main_data_in = data[i];
                parity ^= data[i];
                repeat (BAUD_TICKS) @(posedge clk);
            end

            // Parity bit
            main_data_in = parity;
            repeat (BAUD_TICKS) @(posedge clk);

            // Stop bit
            main_data_in = 1;
            repeat (BAUD_TICKS) @(posedge clk);

        end
    endtask
    
    task automatic receive_uart_stream(
        output bit [7:0] final_data,
        output bit parity_error
    );
        int i;
        bit parity_bit;
        bit parity_calc;
        begin
            $display("[%0t] Start receiving UART data...", $time);
            // Start bit
            wait (main_data_out == 0);
            repeat (BAUD_TICKS) @(posedge clk);
            
            $display("[%0t] start skiped", $time);
            repeat (BAUD_TICKS) @(posedge clk);            
    
            // Data bits (LSB first)
            for (i = 7; i >= 0; i = i - 1) begin
                final_data[i] = main_data_out;
                $display("[%0t] [%b] data", $time, main_data_out);
                repeat (BAUD_TICKS) @(posedge clk);
            end
            $display("[%0t] end data", $time);
            // Parity
            parity_bit = main_data_out;
            repeat (BAUD_TICKS) @(posedge clk);
    
            // Stop bit
            if (main_data_out !== 1) begin
                $display("UART Stop bit error");
            end
    
            parity_calc = ~^final_data;  // XNOR all bits
            parity_error = (parity_calc !== parity_bit);
            if (parity_error)
                $display("UART Parity error: expected %0b, got %0b", parity_calc, parity_bit);
        end
    endtask


    function int calc_speed(input int d1, d2, period);
        return (d2 - d1) / period;
    endfunction

    function int calc_accel(input int d1, d2, d3, period);
        int s1, s2;
        begin
            s1 = calc_speed(d1, d2, period);
            s2 = calc_speed(d2, d3, period);
            return (s2 - s1) / period;
        end
    endfunction


    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin

        repeat (3) @(posedge clk);
        rst = 0;
        calc_busy = 1;
        send_uart_byte(8'b00001010); //send first data
        calc_busy = 0;
        @(posedge clk);
        calc_busy = 1;
        send_uart_byte(8'b00010010); //send second data
        calc_busy = 0;
        @(posedge clk);
        calc_busy = 1;
        send_uart_byte(8'b00100110); //send third data
        calc_busy = 0;
        
        @(posedge clk);
        calc_busy = 1;

        r_d1 = 8'b00001010;
        r_d2 = 8'b00010010;
        r_d3 = 8'b00100110;

        r_speed = calc_speed(r_d1, r_d2, t);
        r_accel = calc_accel(r_d1, r_d2, r_d3, t);
        
        // write data to slave ram

        fork
            begin : send_speed_process
                @(posedge clk);
                data_in_ram_slave_a = r_speed;
                calc_ready = 1;
                @(posedge clk);
                calc_ready = 0;
            end
        
            begin : receive_speed_process
                receive_uart_stream(final_data, parity_error);
            end
        join
        
        if (final_data !== r_speed) begin
            $display("Data mismatch: received %b, expected %b", final_data, r_speed);
        end else begin
            $display("Correct data received: %02h", final_data);
        end
        
        fork
            begin : send_accel_process
                @(posedge clk);
                data_in_ram_slave_a = r_accel;
                calc_ready = 1;
                @(posedge clk);
                calc_ready = 0;
            end
        
            begin : receive_accel_process
                receive_uart_stream(final_data, parity_error);
            end
        join
        
        if (final_data !== r_accel) begin
            $display("Data mismatch: received %b, expected %b", final_data, r_speed);
        end else begin
            $display("Correct data received: %02h", final_data);
        end
            
        $finish;
    end

endmodule
