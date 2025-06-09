library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

entity alu_ram_receive is
    generic (
        RAM_DEPTH : integer := 1024
    );
    port (
        clk                             : in  std_logic;
        rst                             : in  std_logic;
        ce                              : out std_logic;
        we                              : out std_logic;
        addr                            : out std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);
        final_cmd                       : in  std_logic;
        data_valid                      : out std_logic;
        data_ready                      : in  std_logic;
        calc_busy                       : in  std_logic
    );
end alu_ram_receive;

architecture rtl of alu_ram_receive is

    type state_type is (idle, data_from_ram_to_alu, next_addr);
    signal state : state_type := idle;
    signal addr_counter : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0) := (others => '0');

begin

    we <= '0';

    process (clk, rst)
    begin
        if rst = '1' then
            state <= idle;
            ce <= '0';
            addr_counter <= (others => '0');
            addr <= (others => '0');
            data_valid <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    data_valid <= '0';
                    ce <= '0';
                    addr <= addr_counter;
                    if calc_busy = '0' and data_ready = '1' and final_cmd = '1' then
                        state <= data_from_ram_to_alu;
                    end if;

                when data_from_ram_to_alu =>
                    ce <= '1';
                    state <= next_addr;
                    
                when next_addr =>
                    data_valid <= '1';
                    addr_counter <= std_logic_vector(unsigned(addr_counter) + 1);
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;
