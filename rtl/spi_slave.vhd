----------------------------------------------------------------------------------
--  Spi Slave Unit
--  This code implements a simple SPI slave unit with 8-bit address and 8-bit data
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
    port (
        clk                 : in std_logic;                          -- Main clock
        --SPI Slave Interface
        sclk                : in  std_logic;                         -- Clock
        cs                  : in  std_logic;                         -- Chip-select
        MOSI                : in  std_logic;                         -- Master Out Slave In
        MISO                : out std_logic;                         -- Master In Slave Out 
        --RAM Interface
        data_read           : in  std_logic_vector   (7 downto 0);   -- Data read from RAM
        addrs               : out std_logic_vector   (7 downto 0);   -- Counter address
        data_write          : out std_logic_vector   (7 downto 0);   -- Data to write to RAM
        we                  : out std_logic;                         -- Signal to write to RAM
        ce                  : out std_logic                          -- Signal to enable RAM
    );
end spi_slave;

architecture rtl of spi_slave is

    signal data_shift_reg   : std_logic_vector        (7 downto 0)     := (others => '0');
    signal bit_cnt          : unsigned                (3 downto 0)     := (others => '0');
    signal addr_reg         : std_logic_vector        (7 downto 0)     := (others => '0');
    signal sclk_meta        : std_logic                                := '0';
    signal cs_meta          : std_logic                                := '0';
    signal mosi_meta        : std_logic                                := '0';
    signal sclk_reg         : std_logic                                := '0';
    signal cs_reg           : std_logic                                := '0';
    signal mosi_reg         : std_logic                                := '0';
    signal spi_clk_reg      : std_logic                                := '0';
    signal spi_clk_fedge    : std_logic                                := '0';
    signal spi_clk_redge    : std_logic                                := '0';

begin
    -- Input synchronization
    sync_ffs: process(clk)
    begin
        if rising_edge(clk) then
            sclk_meta   <= sclk;
            cs_meta     <= cs;
            mosi_meta   <= MOSI;
            sclk_reg    <= sclk_meta;
            cs_reg      <= cs_meta;
            mosi_reg    <= mosi_meta;
        end if;
    end process sync_ffs;

    -- SPI clock register
    spi_clk_reg_p : process(clk)
    begin
        if rising_edge(clk) then
            spi_clk_reg <= sclk_reg;
        end if;
    end process spi_clk_reg_p;

    spi_clk_fedge <= not sclk_reg and spi_clk_reg;
    spi_clk_redge <= sclk_reg and not spi_clk_reg;

    -- Bit counter
    bit_cnt_p : process (clk)
    begin
        if (rising_edge(clk)) then
            if (cs_reg = '1') then
                bit_cnt <= (others => '0');
            elsif (spi_clk_fedge = '1') then
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt = "0111") then
                    bit_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process bit_cnt_p;

    -- Address register
    address_reg_p : process(clk)
    begin
        if (rising_edge(clk)) then
            if (cs_reg = '0' and bit_cnt = "0000") then
                addr_reg <= data_shift_reg;
            end if;
        end if;
    end process address_reg_p;

    -- Data register
    data_shift_reg_p : process(clk)
    begin
        if (rising_edge(clk)) then
            if (cs_reg = '0') then
                data_shift_reg(7 downto 1) <= data_shift_reg(6 downto 0);
                data_shift_reg(0) <= mosi_reg;
                
                if (bit_cnt = "0111") then
                    data_write <= data_shift_reg;
                    we <= '1';
                else
                    we <= '0';
                end if;
            end if;
        end if;
    end process data_shift_reg_p;

    -- MISO register
    miso_p : process(clk)
    begin
        if(rising_edge(clk)) then
            if (spi_clk_fedge = '1' and cs_reg = '0') then
                MISO <= data_read(7);
                ce <= '1';
            end if;
        end if;
    end process miso_p;

    -- Assign outputs
    addrs <= addr_reg;              -- Address assignment
    we <= not cs_reg;               -- Write enable when CS is low
    ce <= not cs_reg;               -- Enable RAM when CS is low
    data_write <= data_shift_reg;   -- Data to be written
    MISO <= data_read(7);           -- Output data from RAM

end rtl;
