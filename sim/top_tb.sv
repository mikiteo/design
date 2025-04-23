module top_tb;
    logic clk;
    logic [7:0] read_addr;
    logic calc_busy;
    logic calc_ready;
    logic [7:0] data_in;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [7:0] addr_master;
    task master_drive();
        forever begin
            @(posedge clk);
            addr_master = read_addr;
            calc_busy = 1;
            repeat (2) @(posedge clk);
            calc_busy = 0;
        end
    endtask

    logic [7:0] mem [0:255];
    task slave_drive();
        bit [7:0] value;
        bit [7:0] result;
        forever begin
            wait (calc_busy == 0);
            @(posedge clk);
            value  = mem[read_addr];
            result = value + 1;
            calc_ready = 1;
            data_in    = result;
            @(posedge clk);
            calc_ready = 0;
        end
    endtask

    logic [7:0] dist_buf [0:2];
    int index = 0;

    task push_distance(input bit [7:0] d);
        dist_buf[index] = d;
        index = (index + 1) % 3;
    endtask

    task gold_model(output logic signed [15:0] velocity, output logic signed [15:0] acceleration);
        logic signed [15:0] d0, d1, d2;
        logic signed [15:0] v1, v2;
        d0 = dist_buf[(index + 0) % 3];
        d1 = dist_buf[(index + 1) % 3];
        d2 = dist_buf[(index + 2) % 3];
        v1 = d1 - d0;
        v2 = d2 - d1;
        velocity = v2;
        acceleration = v2 - v1;
    endtask

    task monitor();
        bit [7:0] observed_data;
        forever begin
            @(posedge clk);
            if (calc_ready && calc_busy == 0) begin
                observed_data = data_in;
                push_distance(observed_data);
            end
        end
    endtask

    initial begin
        read_addr = 0;
        calc_busy = 0;
        calc_ready = 0;
        data_in = 0;
        mem[0] = 10;
        mem[1] = 12;
        mem[2] = 14;
        fork
            master_drive();
            slave_drive();
            monitor();
        join_none

        #100 $finish;
    end
endmodule
