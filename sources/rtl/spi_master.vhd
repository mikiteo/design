-----------------------------------------------------------------------------------
--  SPI Master Unit
--  This code implements a simple SPI master unit with 8-bit address and 8-bit data
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity spi_master is
    port (
        clk                 : in  std_logic;                         -- Main clock
        --SPI Master Interface
        sclk                : out std_logic;                         -- SPI Clock
        cs                  : out std_logic;                         -- Chip Select
        mosi                : out std_logic;                         -- Master Out Slave In
        miso                : in  std_logic;                         -- Master In Slave Out
        --RAM Interface
        data_read           : in  std_logic_vector   (7 downto 0);   -- Data read from RAM
        data_write          : out std_logic_vector   (7 downto 0);   -- Data to write to RAM
        --Service ports
        start_transmit      : in  std_logic;                         -- Start signal
        busy_out            : out std_logic                          -- Busy signal
    );
end spi_master;



architecture rtl of spi_master is

    type state_t is (idle, start_transfer, config_transfer, transfer_data, end_transfer);
    signal state            : state_t                                           := idle;
    signal shift_reg        : std_logic_vector       (7 downto 0)               := (others => '0');
    signal sclk_reg         : std_logic                                         := '0';
    signal bit_cnt          : unsigned               (3 downto 0)               := (others => '0');
    
begin
    -- FSM for SPI Master
    process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    busy_out <= '0';
                    cs <= '1';
                    sclk_reg <= '0';
                    bit_cnt <= (others => '0');
                    mosi <= '0';

                    if start_transmit = '1' then
                        busy_out <= '1';
                        state <= config_transfer;
                    end if;

                when config_transfer =>
                    cs <= '0';
                    state <= start_transfer;

                when start_transfer =>
                    shift_reg <= data_read;
                    state <= transfer_data;

                when transfer_data =>
                    sclk_reg <= not sclk_reg;
                    sclk <= sclk_reg;

                    if sclk_reg = '1' then
                        mosi <= shift_reg(7);
                        shift_reg <= shift_reg(6 downto 0) & miso;
                        bit_cnt <= bit_cnt + 1;
                    end if;

                    if bit_cnt = 8 then
                        busy_out <= '0';
                        cs <= '1';
                        state <= end_transfer;
                    end if;

                when end_transfer =>
                    data_write <= shift_reg; 
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;
