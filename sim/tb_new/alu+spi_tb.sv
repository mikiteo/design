`timescale 1ps/1ps
`include "spi_if.sv"
`include "spi_agent.sv"
`include "spi_transaction.sv"


module tb;

    logic clk;
    spi_if #();

    calc #(

    ) dut (
        .clk(clk),
        
        .start_work_master(start_work_master),
        .miso_master(miso_master),
        .mosi_master(mosi_master),
        .sclk_master(sclk_master),
        .cs_master(cs_master),

        .start_work_slave(start_work_slave),
        .miso_slave(miso_slave),
        .mosi_slave(mosi_slave),
        .sclk_slave(sclk_slave),
        .cs_slave(cs_slave)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    
endmodule