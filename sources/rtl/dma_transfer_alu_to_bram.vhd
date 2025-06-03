library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

entity alu_ram_transfer is
    generic (
        RAM_DEPTH : integer := 4
    );
    port (
        clk                             : in  std_logic;
        rst                             : in  std_logic;
        ce                              : out std_logic;
        we                              : out std_logic;
        addr                            : out std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);
        data_ready                      : out std_logic;
        calc_ready                      : in  std_logic
    );
end alu_ram_transfer;

architecture rtl of alu_ram_transfer is

    type state_type is (idle, next_addr);
    signal state : state_type := idle;
    signal write_count : integer := 0;
    signal addr_counter : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0) := (others => '0');

begin

    process (clk)
    begin
        if rst = '1' then
            state <= idle;
            addr_counter <= (others => '0');
            ce <= '0';
            we <= '0';
            write_count <= 0;
            addr <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    ce <= '0';
                    we <= '0';
                    data_ready <= '0';
                    addr <= addr_counter;
                    if calc_ready = '1' then
                        ce <= '1';
                        we <= '1';
                        write_count <= write_count + 1;
                        state <= next_addr;
                    end if;                   
                    
                when next_addr =>
                    ce <= '0';
                    we <= '0';
                    if write_count = 3 then
                        write_count <= 0;
                        data_ready <= '1';
                        addr_counter <= (others => '0');
                    else
                        addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
                    end if;
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;

