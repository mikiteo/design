library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

entity uart_packet_receiver is
    generic (
        RAM_DEPTH   : integer := 1024
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx_data     : in  std_logic_vector(7 downto 0);
        rx_ready    : in  std_logic;
        final_cmd   : out std_logic;
        we          : out std_logic;
        ce          : out std_logic;
        addr        : out std_logic_vector(clogb2(RAM_DEPTH - 1) downto 0);
        dout        : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of uart_packet_receiver is

    type state_type is (idle, x55, xAA, x81, x03, xXX1, xXX2, x00, xFA, stop);
    signal state       : state_type := idle;
    signal cnt         : integer range 0 to 7 := 0;
    signal packet      : std_logic_vector(63 downto 0);
    signal addr_cnt    : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0) := (others => '0');

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state    <= idle;
            we       <= '0';
            ce       <= '0';
            cnt      <= 0;
            dout  <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    we <= '0';
                    ce <= '0';  
                    final_cmd <= '0';
                    if rx_data = x"55" and rx_ready = '1' then
                        packet(63 downto 56) <= rx_data;
                        state <= x55;
                    end if;

                when x55 =>
                    if rx_data = x"AA" and rx_ready = '1' then
                        packet(55 downto 48) <= rx_data;
                        cnt <= 2;
                        state <= xAA;
                    end if;

                when xAA to x00 =>
                    if rx_ready = '1' then
                        packet((8-cnt)*8-1 downto (8-cnt)*8-8) <= rx_data;
                        cnt <= cnt + 1;
                        if cnt = 7 then
                            state <= xFA;
                        else
                            state <= state_type'succ(state);
                        end if;
                    end if;

                when xFA =>
                        packet(7 downto 0) <= rx_data;
                        if packet(15 downto 8) = x"00" then
                            dout <= packet(31 downto 24) & packet(23 downto 16);
                            addr <= addr_cnt;
                            we   <= '1';
                            ce   <= '1';
                            addr_cnt <= std_logic_vector(unsigned(addr_cnt) + 1);
                        end if;
                        state <= stop;

                when stop =>
                    final_cmd <= '1';
                    we <= '0';
                    ce <= '0';
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;
end architecture;
