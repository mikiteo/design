library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_ram_transfer is
    port (
        clk                             : in  std_logic;
        ce                              : out std_logic;
        we                              : out std_logic;
        addr                            : out std_logic_vector(7 downto 0);
        calc_ready                      : in  std_logic;
        next_data                       : in  std_logic
    );
end alu_ram_transfer;

architecture rtl of alu_ram_transfer is

    type state_type is (idle, data_from_alu_to_ram, wait_state, next_addr);
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
                    if calc_ready = '1' then
                        state <= data_from_alu_to_ram;
                    end if;

                when data_from_alu_to_ram =>
                    ce <= '1';
                    we <= '1';
                    state <= next_addr;
                    
                when next_addr =>
                    addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
                    state <= wait_state;
                
                when wait_state =>
                    if next_data = '1' then
                        state <= idle;
                    else
                        state <= wait_state;
                    end if;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;

