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
        mosi                : in  std_logic;                         -- Master Out Slave In
        miso                : out std_logic;                         -- Master In Slave Out 
        --RAM Interface
        data_read           : in  std_logic_vector   (7 downto 0);   -- Data read from RAM
        data_write          : out std_logic_vector   (7 downto 0);   -- Data to write to RAM
        --Service ports
        start_transmit      : in  std_logic;                         -- Start signal
        busy_out            : out std_logic                          -- Busy signal
    );
end spi_slave;

architecture rtl of spi_slave is

    type state_t is (idle, start_transfer, transfer_data, end_transfer);
    signal state            : state_t                                           := idle;
    signal shift_reg        : std_logic_vector       (7 downto 0)               := (others => '0');
    signal bit_cnt          : unsigned               (3 downto 0)               := (others => '0');
    
begin
    -- FSM for SPI Slave
    process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    busy_out <= '0';
                    bit_cnt <= (others => '0');
                    miso <= '0';

                    if start_transmit = '1' and cs = '0' then
                        busy_out <= '1';
                        state <= start_transfer;
                    end if;

                when start_transfer =>
                    shift_reg <= data_read;
                    state <= transfer_data;

                when transfer_data =>
                    if cs = '1' then
                        state <= idle;
                    elsif sclk = '1' then
                        miso <= shift_reg(7);
                        shift_reg <= shift_reg(6 downto 0) & mosi;
                        bit_cnt <= bit_cnt + 1;
                    end if;
                    if bit_cnt = 8 then
                        busy_out <= '0';
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
