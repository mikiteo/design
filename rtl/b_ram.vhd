library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;
USE std.textio.all;

entity dp_ram is
generic (
    RAM_WIDTH : integer := 8;
    RAM_DEPTH : integer := 256
);

port (
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0);
        doutb : out std_logic_vector(RAM_WIDTH-1 downto 0);
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);
        addrb : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);
        dinb  : in std_logic_vector(RAM_WIDTH-1 downto 0);
        clka  : in std_logic;
        wea   : in std_logic;
        web   : in std_logic;
        ena   : in std_logic;
        enb   : in std_logic
);

end dp_ram;

architecture rtl of dp_ram is

constant C_RAM_WIDTH : integer := RAM_WIDTH;
constant C_RAM_DEPTH : integer := RAM_DEPTH;

type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0);

signal ram_data_a : std_logic_vector(C_RAM_WIDTH-1 downto 0);
signal ram_data_b : std_logic_vector(C_RAM_WIDTH-1 downto 0);

shared variable ram_name : ram_type := (others => (others => '0'));

begin

process(clka)
begin
    if rising_edge(clka) then
        if ena = '1' then
            if wea = '1' then
                ram_name(to_integer(unsigned(addra))) := dina;
            else
                ram_data_a <= ram_name(to_integer(unsigned(addra)));
            end if;
        end if;
    end if;
end process;

douta <= ram_data_a;

process(clka)
begin
    if rising_edge(clka) then
        if enb = '1' then
            if web = '1' then
                ram_name(to_integer(unsigned(addrb))) := dinb;
            else
                ram_data_b <= ram_name(to_integer(unsigned(addrb)));
            end if;
        end if;
    end if;
end process;

doutb <= ram_data_b;

end rtl;
