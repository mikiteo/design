library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity empty_check is
    port (
        clk                             : in    std_logic;
        addr_r                          : in    std_logic_vector(7 downto 0);
        addr_w                          : in    std_logic_vector(7 downto 0);
        next_data                       : out   std_logic
    );
end empty_check;

architecture rtl of empty_check is
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if (unsigned(addr_r) - unsigned(addr_w)) = 1 then
                next_data <= '1';
            end if;
        end if;
    end process;

end rtl;

