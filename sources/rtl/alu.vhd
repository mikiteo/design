library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        DELTA_T : integer := 10
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        data_in     : in  std_logic_vector(15 downto 0);
        data_valid  : in  std_logic;
        data_ready  : out std_logic;
        calc_busy   : out std_logic;
        calc_ready  : out std_logic;
        result_out  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of alu is

    type state_type is (idle, collect, calculate, output_d, wait_d, output_v, wait_v, output_a, wait_a);
    signal state        : state_type := idle;
    signal d1, d2, d3   : unsigned(15 downto 0) := (others => '0');
    signal prev_v       : signed(15 downto 0) := (others => '0');
    signal acc          : signed(15 downto 0) := (others => '0');
    signal v_result     : signed(15 downto 0) := (others => '0');
    signal a_result     : signed(15 downto 0) := (others => '0');
    signal sample_count : integer range 0 to 3 := 0;

begin

    process(clk, rst)
        variable temp_v   : signed(31 downto 0);
        variable temp_a   : signed(31 downto 0);
        variable temp_raw : signed(31 downto 0);
        variable temp_acc : signed(31 downto 0);
    begin
        if rst = '1' then
            state <= idle;
            sample_count <= 0;
            calc_ready <= '0';
            calc_busy <= '0';
            data_ready <= '1';
            result_out <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    calc_ready <= '0';
                    calc_busy <= '0';
                    data_ready <= '1';
                    if data_valid = '1' then
                        d1 <= unsigned(data_in);
                        sample_count <= 1;
                        data_ready <= '0';
                        state <= collect;
                    end if;

                when collect =>
                    data_ready <= '1';
                    if data_valid = '1' then
                        sample_count <= sample_count + 1;
                        if sample_count = 1 then
                            data_ready <= '0';
                            d2 <= unsigned(data_in);
                        elsif sample_count = 2 then
                            d3 <= unsigned(data_in);
                            calc_busy <= '1';
                            data_ready <= '0';
                            state <= calculate;
                        end if;
                    end if;

                when calculate =>

                    temp_raw := resize(signed(d3) - signed(d2), 32);
                    temp_raw := temp_raw / to_signed(DELTA_T, 32);

                    temp_acc := temp_raw - resize(prev_v, 32);
                    temp_v := (temp_acc + resize(acc, 32)) / 2;

                    acc     <= resize(temp_v(15 downto 0), 16);
                    prev_v  <= resize(temp_raw(15 downto 0), 16);

                    temp_a   := resize(signed(d3), 32) - resize(to_signed(2, 32) * signed(resize(d2, 32)), 32) + resize(signed(d1), 32);
                    temp_a   := temp_a / to_signed(DELTA_T * DELTA_T, 32);

                    v_result <= resize(temp_v(15 downto 0), 16);
                    a_result <= resize(temp_a(15 downto 0), 16);
                    state <= output_d;

                when output_d =>
                    result_out <= std_logic_vector(d3);
                    calc_ready <= '1';
                    state <= wait_d;

                when wait_d =>
                    calc_ready <= '0';
                    state <= output_v;

                when output_v =>
                    result_out <= std_logic_vector(v_result);
                    calc_ready <= '1';
                    state <= wait_v;

                when wait_v =>
                    calc_ready <= '0';
                    state <= output_a;

                when output_a =>
                    result_out <= std_logic_vector(a_result);
                    calc_ready <= '1';
                    state <= wait_a;

                when wait_a =>
                    calc_ready <= '0';
                    calc_busy <= '0';
                    d1 <= d2;
                    d2 <= d3;
                    sample_count <= 2;
                    state <= collect;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end architecture;
