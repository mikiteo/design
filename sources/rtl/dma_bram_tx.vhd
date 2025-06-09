library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma_bram_tx is
    port (
        clk         : in   std_logic;
        ce          : out  std_logic;
        we          : out  std_logic;
        addr        : out  std_logic_vector(7 downto 0);
        data_ready  : in   std_logic;
        tx_start    : out  std_logic;
        busy        : in   std_logic
    );
end entity dma_bram_tx;

architecture rtl of dma_bram_tx is

    type state_type is (idle, start, next_addr);
    signal state : state_type := idle;
    signal addr_counter : std_logic_vector(7 downto 0) := (others => '0');

begin

    process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    ce <= '0';
                    we <= '0';
                    addr <= addr_counter;
                    if busy = '0' and data_ready = '1' then
                        ce <= '1';
                        we <= '0';
                        state <= start;
                    end if;

                when start =>
                    tx_start <= '1';
                    state <= next_addr;

                when next_addr =>
                    addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
                    tx_start <= '0';
                    ce <= '0';
                    we <= '0';
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;    