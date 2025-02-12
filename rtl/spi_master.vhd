-----------------------------------------------------------------------------------
--  SPI Master Unit
--  This code implements a simple SPI master unit with 8-bit address and 8-bit data
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    port (
        clk                 : in  std_logic;                         -- Main clock
        --SPI Master Interface
        sclk                : out std_logic;                         -- SPI Clock (external)
        cs                  : out std_logic;                         -- Chip Select
        MOSI                : out std_logic;                         -- Master Out Slave In
        MISO                : in  std_logic;                         -- Master In Slave Out
        --RAM Interface
        data_read           : in  std_logic_vector   (7 downto 0);   -- Data read from RAM
        addrs               : out std_logic_vector   (7 downto 0);   -- Address to RAM
        data_write          : out std_logic_vector   (7 downto 0);   -- Data to write to RAM
        we                  : out std_logic;                         -- Write enable to RAM
        ce                  : out std_logic                          -- RAM Enable
    );
end spi_master;

architecture rtl of spi_master is

    signal data_shift_reg   : std_logic_vector       (7 downto 0)    := (others => '0');
    signal bit_cnt          : unsigned               (3 downto 0)    := (others => '0');
    signal addr_reg         : std_logic_vector       (7 downto 0)    := (others => '0');
    signal busy_reg         : std_logic                              := '0';
    signal sclk_reg         : std_logic                              := '0';
    signal miso_meta        : std_logic                              := '0';
    signal miso_reg         : std_logic                              := '0';
    signal cs_reg           : std_logic                              := '0';

begin
    --Input synchronisation
    sync_ffs: process(clk)
    begin
        if rising_edge(clk) then
            miso_meta   <= MISO;
            miso_reg    <= miso_meta;
        end if;
    end process sync_ffs;

    -- SPI clock register
    sclk_reg_p : process(clk)
    begin
        if rising_edge(clk) then
            sclk_reg <= clk;
        end if;
    end process sclk_reg_p;

    -- Bit Counter
    bit_cnt_p : process(clk)
    begin
        if rising_edge(clk) then
            if busy_reg = '1' then
                if bit_cnt = "0111" then
                    busy_reg <= '0';
                    cs_reg <= '1';
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process bit_cnt_p;

    -- Address register
    address_logic_p : process(clk)
    begin
        if (rising_edge(clk)) then
            if (cs_reg = '0' and bit_cnt = "0000") then
                addr_reg <= data_shift_reg;
            end if;
        end if;
    end process address_logic_p;

    -- Start Transmission
    start_trans_p : process(clk)
    begin
        if rising_edge(clk) then
            if (busy_reg = '0' and (data_read /= data_shift_reg)) then
                data_shift_reg <= data_read;
                bit_cnt <= (others => '0');
                cs_reg <= '0';
                busy_reg <= '1';
            end if;
        end if;
    end process start_trans_p;

    -- Data Transmission
    data_trans_p : process(clk)
    begin
        if rising_edge(clk) then
            if busy_reg = '1' then
                data_shift_reg(7 downto 1) <= data_shift_reg(6 downto 0);
                data_shift_reg(0) <= miso_reg;
            end if;
        end if;
    end process data_trans_p;

    -- Assign outputs

    MOSI <= data_shift_reg(7);      -- Send most significant bit first
    cs <= cs_reg;                   -- Chip Select output
    addrs <= addr_reg;              -- Address assignment
    sclk <= sclk_reg;               -- SPI Clock output
    we <= not cs_reg;               -- Write enable when CS is low
    ce <= not cs_reg;               -- Enable RAM when CS is low
    data_write <= data_shift_reg;   -- Data to be written

end rtl;
