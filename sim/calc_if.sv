interface calc_if(input logic clk);

    logic        calc_busy;
    logic        calc_ready;
    logic [7:0]  data_in;
    logic [7:0]  data_out;

    logic [7:0]  read_addr;
    logic [7:0]  write_addr;
    logic        next_data;

endinterface : calc_if