library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        rx              : in  std_logic;
        ready           : out std_logic;
        dout            : out std_logic_vector(7 downto 0);
        parity_error    : out std_logic
    );
end entity;

architecture rtl of uart_rx is

    type state_type is (idle, center_wait, data, parity, stop);
    signal state : state_type := idle;

    signal tick_cnt         : unsigned          (4 downto 0)            := (others => '0');
    signal tick_cnt_prev2   : std_logic                                 := '0';
    signal tick_4           : std_logic                                 := '0';
    signal rx_reg           : std_logic_vector  (7 downto 0)            := (others => '0');
    signal rx_buf           : std_logic_vector  (7 downto 0)            := (others => '0');
    signal parity_bit       : std_logic                                 := '0';
    signal calc_parity      : std_logic                                 := '0';
    signal rx_ff            : std_logic                                 := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            tick_cnt <= "00001";
        elsif rising_edge(clk) then
            if (state = center_wait and tick_cnt = to_unsigned(2, tick_cnt'length)) or (state = idle) then
                tick_cnt <= "00001";
            elsif (state /= idle) then
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
            rx_reg <= (others => '0');
            rx_buf <= (others => '0');
            parity_bit <= '0';
            calc_parity <= '0';
            ready <= '0';
            parity_error <= '0';
            rx_ff <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    ready <= '0';
                    parity_error <= '0';
                    if rx = '0' then
                        rx_ff <= rx;
                        state <= center_wait;
                    end if;
            
                when center_wait =>
                    if tick_cnt = 2 then
                        if rx_ff = rx then 
                            state <= data;
                        else 
                            state <= idle;
                        end if;
                    end if;
            
                when others =>
                    if tick_4 = '1' then
                        case state is
                            when data =>
                                rx_reg <= rx_reg(6 downto 0) & rx;
                                if tick_cnt = to_unsigned(1, tick_cnt'length) then
                                    state <= parity;
                                end if;
            
                            when parity =>
                                parity_bit <= rx;
                                calc_parity <= rx_reg(0) xnor rx_reg(1) xnor rx_reg(2) xnor rx_reg(3) xnor
                                               rx_reg(4) xnor rx_reg(5) xnor rx_reg(6) xnor rx_reg(7);
                                state <= stop;
            
                            when stop =>
                                if rx = '1' then
                                    if parity_bit /= calc_parity then
                                        parity_error <= '1';
                                    end if;
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
