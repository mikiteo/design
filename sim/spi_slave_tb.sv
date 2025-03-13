`timescale 1ns / 1ps

module tb_spi_slave;

    // Тактовий сигнал (50 MHz)
    reg clk = 0;
    reg cs = 1;
    reg sclk = 0;
    reg mosi = 0;
    wire miso;
    logic start_transmit = 1;
    logic [7:0] data_read = 8'hA5;
    logic [7:0] data_write;
    wire busy_out;
    reg [7:0] fake_data = 8'b11001100;
    integer i;

    // Інстанціювання тестованого модуля
    spi_slave uut (
        .clk(clk),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .data_write(data_write),
        .busy_out(busy_out),
        .start_transmit(start_transmit),
        .data_read(data_read)
    );
    
    always #5 clk = ~clk;
    always @(posedge clk) begin
        $display("%b, %b", uut.shift_reg, data_write);
    end
    
    always @(posedge clk) begin
        $display("time=%0t | bit_cnt: %d", $time, uut.bit_cnt);
    end

    // Основний тест
    initial begin

        // Ініціалізація
        cs = 1;
        mosi = 0;
        sclk = 0;

        // Активуємо SPI Slave
        #10 cs = 0;

        // Передаємо 8 біт на MOSI
        for (i = 0; i < 8; i = i + 1) begin
            #10 sclk = 1;
            mosi = fake_data[7 - i];
            #10 sclk = 0;
        end
        
        wait(busy_out == 0);
        
        #10 cs = 1;

        if (data_write == fake_data)
            $display("SPI Slave taken: %b", data_write);
        else
            $display("Error: Taken %b, waiting %b", data_write, fake_data);

        // Завершення тесту
        #100;
        $finish;
    end

endmodule
