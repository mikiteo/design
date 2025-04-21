`timescale 1ns/1ps
import calc_pkg::*;

module top_tb;

    logic clk;
    calc_if vif(clk);

    top_module dut (
        .clk         (clk),
        .calc_busy   (vif.calc_busy),
        .calc_ready  (vif.calc_ready),
        .data_in     (vif.data_in),
        .data_out    (vif.data_out),
        .read_addr   (vif.read_addr),
        .write_addr  (vif.write_addr),
        .next_data   (vif.next_data)
    );

    calc_agent agent;
    calc_checker scoreboard;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        agent = new(0, vif);
        scoreboard = new();

        agent.mem[0] = 8'd100;
        agent.mem[1] = 8'd106;
        agent.mem[2] = 8'd113;
        agent.mem[3] = 8'd120;
        agent.mem[4] = 8'd128;

        fork
            agent.drive();
            forever begin
                @(posedge clk);
                if (vif.calc_ready) begin
                    scoreboard.check(vif.data_in);
                end
            end
        join_any

        $finish;
    end

endmodule
