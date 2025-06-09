library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLK_FREQ    : integer := 100_000_000;
        BAUD_RATE   : integer := 115_200
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        tx_start    : in  std_logic;
        din         : in  std_logic_vector(7 downto 0);
        tx          : out std_logic;
        tx_busy     : out std_logic
    );
end entity;

architecture rtl of uart_tx is

    type     state_type is (idle, data_write, data, stop);
    signal   state            : state_type := idle;

    constant BAUD_TICKS       : integer                                   := integer(real(CLK_FREQ) / real(BAUD_RATE));
    signal   tick_cnt         : integer           range 0 to BAUD_TICKS-1 := 0;
    signal   bit_cnt          : integer           range 0 to 7            := 0;
    signal   baud_tick        : std_logic                                 := '0';
    signal   tx_reg           : std_logic_vector  (7 downto 0)            := (others => '0');
    signal   stop_done        : unsigned          (4 downto 0)            := (others => '0');

begin

    tx_busy <= '1' when state /= idle else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            tick_cnt  <= 0;
            baud_tick <= '0';
        elsif rising_edge(clk) then
            if tick_cnt = BAUD_TICKS - 1 then
                tick_cnt  <= 0;
                baud_tick <= '1';
            else
                tick_cnt  <= tick_cnt + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            state <= idle;
            stop_done <= (others => '0');
            tx <= '1';
            tx_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    stop_done <= (others => '0');
                    if tx_start = '1' then
                        state <= data_write;
                    end if;

                when data_write =>
                    if baud_tick = '1' then
                        tx <= '0';
                        tx_reg <= din;
                        state <= data;
                    end if;

                when data =>
                    if baud_tick = '1' then
                        tx <= tx_reg(0);
                        tx_reg <= '0' & tx_reg(7 downto 1);
                        if bit_cnt = 7 then
                            bit_cnt <= 0;
                            state <= stop;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    end if;

                when stop =>
                    if baud_tick = '1' then
                        tx <= '1';
                        if stop_done = 2 then
                            state <= idle;
                        else
                            stop_done <= stop_done + 1; 
                        end if;
                    end if;

                when others =>
                    state <= idle;

            end case;
        end if;
    end process;

end architecture;
