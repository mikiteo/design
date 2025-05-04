library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        tx_start    : in  std_logic;
        din         : in  std_logic_vector(7 downto 0);
        tx          : out std_logic;
        tx_busy     : out std_logic
    );
end entity;

architecture rtl of uart_tx is

    type state_type is (idle, data, parity, stop);
    signal state     : state_type := idle;

    signal tick_cnt         : unsigned          (4 downto 0)          := (others => '0');
    signal tick_cnt_prev2   : std_logic                               := '0';
    signal tick_4           : std_logic                               := '0';
    signal tx_reg           : std_logic_vector  (7 downto 0)          := (others => '0');
    signal parity_bit       : std_logic                               := '0';

begin

    tx_busy <= '0' when state = idle else '1';

    process(clk, reset)
    begin
        if reset = '1' then
            tick_cnt <= "00001";
        elsif rising_edge(clk) then
            if state = idle then
                tick_cnt <= "00001";
            else
                tick_cnt <= tick_cnt + 1;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            tick_4 <= tick_cnt(2) xor tick_cnt_prev2;
            tick_cnt_prev2 <= tick_cnt(2);
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            state <= idle;
            tx <= '1';
            tx_reg <= (others => '0');
            parity_bit <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    if tx_start = '1' then
                        tx_reg <= din;
                        parity_bit <= din(0) xnor din(1) xnor din(2) xnor din(3) xnor
                                      din(4) xnor din(5) xnor din(6) xnor din(7);
                        tx <= '0';
                        state <= data;
                    end if;
                                
                when data =>
                    if tick_4 = '1' then
                        tx <= tx_reg(7);
                        tx_reg <= tx_reg(6 downto 0) & '0';
                        if tick_cnt = to_unsigned(1, tick_cnt'length) then
                            state <= parity;
                        end if;
                    end if;                    

                when parity =>
                    if tick_4 = '1' then
                        tx <= parity_bit;
                        state <= stop;
                    end if;
                    
                when stop =>
                    if tick_4 = '1' then
                        tx <= '1';
                        state <= idle;
                    end if;
                    
                when others =>
                    state <= idle;
                    
            end case;
        end if;
    end process;

end architecture;
