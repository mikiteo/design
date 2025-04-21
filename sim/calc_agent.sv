class calc_agent;

    virtual calc_if vif;
    bit is_master;
    bit [7:0] mem [256];

    function new(input bit is_master, input virtual interface calc_if vif);
        this.is_master = is_master;
        this.vif = vif;
    endfunction

    task drive_mst();
        bit [7:0] addr;
        forever begin
            @(posedge vif.clk);
            addr = vif.read_addr;
            vif.calc_busy <= 1;
            repeat (2) @(posedge vif.clk);
            vif.calc_busy <= 0;
        end
    endtask

    task drive_slv();
        bit [7:0] value;
        bit [7:0] result;
        forever begin
            wait (vif.calc_busy == 0);
            @(posedge vif.clk);
            value  = mem[vif.read_addr];
            result = value + 1;
            vif.calc_ready <= 1;
            vif.data_in    <= result;
            @(posedge vif.clk);
            vif.calc_ready <= 0;
        end
    endtask

    task drive();
        if (is_master)
            drive_mst();
        else
            drive_slv();
    endtask

    task monitor(output bit [7:0] observed_data);
        forever begin
            @(posedge vif.clk);
            if (vif.calc_ready && vif.calc_busy == 0) begin
                observed_data = vif.data_in;
            end
        end
    endtask

endclass
