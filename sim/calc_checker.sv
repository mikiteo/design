class calc_checker;

    bit [7:0] dist_buf [2:0];
    int index = 0;

    function new();
    endfunction

    function void push_distance(input bit [7:0] d);
            dist_buf[index] = d;
            index = (index + 1) % 3;
        endfunction

    function void gold_model(output logic signed [15:0] velocity, output logic signed [15:0] acceleration);
        
        logic signed [15:0] d0, d1, d2;
        logic signed [15:0] v1, v2;
        d0 = dist_buf[(index + 0) % 3];
        d1 = dist_buf[(index + 1) % 3];
        d2 = dist_buf[(index + 2) % 3];
        v1 = d1 - d0;
        v2 = d2 - d1;
        velocity     = v2;
        acceleration = d2 - 2 * d1 + d0;
    endfunction


    task check(input bit [7:0] new_distance);
        bit signed [15:0] v, a;
        push_distance(new_distance);
        gold_model(v, a);
        $display("[GOLD MODEL] d=%0d → v=%0d, a=%0d", new_distance, v, a);
    endtask

endclass
