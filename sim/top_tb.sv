`timescale 1ns / 1ps

module top_module_tb;

    logic clk = 0;
    
    logic start_work_master;
    logic miso_master;
    logic mosi_master;
    logic sclk_master;
    logic cs_master;

    logic start_work_slave;
    logic miso_slave;
    logic mosi_slave = 0;
    logic sclk_slave = 0;
    logic cs_slave = 1;

    logic [7:0] fake_data = 8'b11001100;
    logic [7:0] received_data;
    integer i;

    top_module dut (
        .clk(clk),
        .start_work_slave(start_work_slave),
        .start_work_master(start_work_master),
        .miso_master(miso_master),
        .mosi_master(mosi_master),
        .sclk_master(sclk_master),
        .cs_master(cs_master),
        .miso_slave(miso_slave),
        .mosi_slave(mosi_slave),
        .sclk_slave(sclk_slave),
        .cs_slave(cs_slave)
    );
    
    always #5 clk = ~clk;   
    
    initial begin
        #5
        start_work_slave = 1;
        cs_slave = 0;
        #30
        start_work_slave = 0; 
        for (i = 0; i < 8; i = i + 1) begin
            #10 sclk_slave = 1;
            mosi_slave = fake_data[7 - i]; 
            #10 sclk_slave = 0;
        end
        #10
        cs_slave = 1;
        
        start_work_master = 1;
        #30
        start_work_master = 0;
        #200;
        $finish;
    end

endmodule
