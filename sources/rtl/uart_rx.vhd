library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        CLK_FREQ        : integer := 100_000_000;
        BAUD_RATE       : integer := 115_200
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        rx              : in  std_logic;
        ready           : out std_logic;
        dout            : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of uart_rx is

    type state_type is (idle, center_wait, data, stop);
    signal state : state_type := idle;

    constant BAUD_TICKS           : integer                                   := integer(real(CLK_FREQ) / real(BAUD_RATE));
    signal   tick_cnt             : integer           range 0 to BAUD_TICKS-1 := 0;
    signal   center_bit           : integer           range 0 to BAUD_TICKS-1 := integer(real(BAUD_TICKS) / real(2));
    signal   bit_cnt              : integer           range 0 to 7            := 0;
    signal   baud_tick            : std_logic                                 := '0';
    signal   rx_reg               : std_logic_vector  (7 downto 0)            := (others => '0');
    signal   rx_buf               : std_logic_vector  (7 downto 0)            := (others => '0');
    signal   rx_ff                : std_logic                                 := '0';

begin

    process(clk, rst)
    begin
        if rst = '1' then
            tick_cnt  <= 0;
            baud_tick <= '0';
        elsif rising_edge(clk) then
            if (state = center_wait and tick_cnt = center_bit) or (state = idle)then
                tick_cnt  <= 0;
                baud_tick <= '0';
            elsif tick_cnt = BAUD_TICKS - 1 then
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
            rx_reg <= (others => '0');
            rx_buf <= (others => '0');
            ready <= '0';
            rx_ff <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    ready <= '0';
                    if rx = '0' then
                        rx_ff <= rx;
                        state <= center_wait;
                    end if;
            
                when center_wait =>
                    if tick_cnt = center_bit then
                        if rx_ff = rx then 
                            state <= data;
                        else 
                            state <= idle;
                        end if;
                    end if;
            
                when others =>
                    if baud_tick = '1' then
                        case state is
                            when data =>
                                rx_reg <= rx & rx_reg(7 downto 1);
                                if bit_cnt = 7 then
                                    bit_cnt <= 0;
                                    state <= stop;
                                else
                                    bit_cnt <= bit_cnt + 1;
                                end if;

                            when stop =>
                                if rx = '1' then
                                    rx_buf <= rx_reg;
                                    ready <= '1';
                                end if;
                                state <= idle;
            
                            when others => null;
                        end case;
                    end if;
            end case;

        end if;
    end process;

    dout <= rx_buf;

end architecture;
