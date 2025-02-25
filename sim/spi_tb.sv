`timescale 1ns/1ps

module spi_slave_tb;
    logic clk = 0;
    logic sclk = 0;
    logic cs = 1;
    logic MOSI = 0;
    logic MISO;
    logic [7:0] data_read = 8'hA5;
    logic [7:0] addrs;
    logic [7:0] data_write;
    logic we;
    logic ce;

    spi_slave uut (
        .clk(clk),
        .sclk(sclk),
        .cs(cs),
        .MOSI(MOSI),
        .MISO(MISO),
        .data_read(data_read),
        .addrs(addrs),
        .data_write(data_write),
        .we(we),
        .ce(ce)
    );

    always #5 clk = ~clk;
    always #10 sclk = ~sclk;

    always @(posedge clk) begin
    $display("Time: %0t | bit_cnt = %0d | MOSI = %b | addrs = %h | data_write = %h | shift_reg = %b | spi_clk_redge = %b | spi_clk_fedge = %b", 
             $time, uut.bit_cnt, MOSI, uut.addrs, uut.data_write, uut.data_shift_reg, uut.spi_clk_redge, uut.spi_clk_fedge);
    end


    initial begin
        #20;

        // Start SPI transaction
        cs = 0;

        #20;
        
        // Send custom 8-bit address
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;

        //Send custom 8-bit data
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        
        // Send custom 8-bit address
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        
        //Send custom 8-bit data
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #20;
        MOSI = 1; #20;
        MOSI = 0; #10;

        // End SPI transaction
        cs = 1;
        #50;

        $display("Simulation completed");
        $stop;
    end
endmodule

`timescale 1ns/1ps

module spi_master_tb;
    logic clk = 0;
    logic sclk;
    logic aa = 0;
    logic cs;
    logic MOSI;
    logic MISO = 0;
    logic [7:0] data_read;
    logic [7:0] addrs;
    logic [7:0] data_write;
    logic we;
    logic ce;
    
    // Instantiate SPI Master
    spi_master uut (
        .clk(clk),
        .sclk(sclk),
        .cs(cs),
        .MOSI(MOSI),
        .MISO(MISO),
        .data_read(data_read),
        .addrs(addrs),
        .data_write(data_write),
        .we(we),
        .ce(ce)
    );

    // Generate Clock
    always #5 clk = ~clk;
    
    initial begin
        $display("Time(ns) | cs | sclk | MOSI | MISO | addrs | data_write | shift_reg | bit_count");
        $monitor("%0t | %b | %b | %b | %b | %h | %h | %h | %d",
                 $time, cs, sclk, MOSI, MISO, addrs, data_write, uut.data_shift_reg, uut.bit_cnt);
    end


    // SPI Data Simulation
    initial begin
        $display("Starting SPI Master Test");
        data_read = 8'hDD; 
        #200;
        data_read = 8'hFF;
        #200;
        
        $display("SPI Master Test Completed");
        $stop;
    end
endmodule
