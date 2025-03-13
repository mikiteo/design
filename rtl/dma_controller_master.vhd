library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_ram_controller_master is
    port (
        clk                             : in  std_logic;
        ce                              : out std_logic;
        we                              : out std_logic;
        start_transmit                  : out std_logic;
        addr                            : out std_logic_vector(7 downto 0);
        start_work                      : in  std_logic;
        spi_busy                        : in  std_logic
    );
end spi_ram_controller_master;

architecture rtl of spi_ram_controller_master is

    type state_type is (idle, data_from_ram_to_spi, wait_state, data_from_spi_to_ram, next_addr);
    signal state : state_type := idle;

    signal addr_counter : std_logic_vector(7 downto 0) := (others => '0');

begin

    process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    ce <= '0';
                    addr <= addr_counter;
                    if start_work = '1' then
                        start_transmit <= '1';
                        state <= data_from_ram_to_spi;  
                    end if;

                when data_from_ram_to_spi =>
                    ce <= '1';
                    we <= '0';
                    state <= next_addr;
                    
                when next_addr =>
                    addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
                    state <= wait_state;
                
                when wait_state =>
                    if spi_busy = '0' then
                        start_transmit <= '0';
                        state <= data_from_ram_to_spi;
                    else
                        state <= wait_state;
                    end if;

                when data_from_spi_to_ram =>
                    we <= '1';
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;
