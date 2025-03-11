-----------------------------------------------------------------------------------
--  SPI Master Unit
--  This code implements a simple SPI master unit with 8-bit address and 8-bit data
-----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ram_pkg.all;



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
        addrs               : out std_logic_vector   (7 downto 0);   -- Address to RAM
        data_write          : out std_logic_vector   (7 downto 0);   -- Data to write to RAM
        we                  : out std_logic;                         -- Write enable to RAM
        ce                  : out std_logic;                          -- RAM Enable
        --Service ports
        start_in            : in  std_logic;                         -- Start signal
        busy_out            : out std_logic                          -- Busy signal
    );
end spi_master;



architecture rtl of spi_master is

    type state_t is (idle, read_ram, start_transfer, transfer_data, write_ram, end_transfer);
    signal state            : state_t                                           := idle;
    signal data_shift_reg   : std_logic_vector       (7 downto 0);
    signal sclk_reg         : std_logic                                         := '0';
    signal bit_cnt          : unsigned               (2 downto 0)               := (others => '0');
    signal sys_clk_reg      : std_logic                                         := '0';
    signal sys_clk_cnt      : std_logic_vector       (1 downto 0)               := "00";
    signal addr_counter     : unsigned               (7 downto 0)               := (others => '0');
    
begin
    -- FSM for SPI Master
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    cs <= '1';
                    busy_out <= '0';
                    we <= '0';
                    ce <= '0';
                    if start_in = '1' then
                        state <= read_ram;
                    end if;

                when read_ram =>
                    ce <= '1';
                    addrs <= std_logic_vector(addr_counter);
                    state <= start_transfer;

                when start_transfer =>
                    cs <= '0';
                    busy_out <= '1';
                    bit_cnt <= (others => '0');
                    sys_clk_reg <= '0';
                    data_shift_reg <= data_read;                   
                    state <= transfer_data;

                when transfer_data =>
                    sys_clk_reg <= not sys_clk_reg;
                    sclk <= sys_clk_reg;

                    if sys_clk_reg = '1' then
                        mosi <= data_shift_reg(7);
                        data_shift_reg(7 downto 1) <= data_shift_reg(6 downto 0);
                        data_shift_reg(0) <= '0';
                        
                        if bit_cnt = "111" then
                            state <= write_ram;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    end if;

                when write_ram =>
                    sclk <= '0';
                    cs <= '1';
                    data_write <= data_shift_reg;
                    we <= '1';
                    state <= end_transfer;

                when end_transfer =>
                    we <= '0';
                    busy_out <= '0';
                    addr_counter <= addr_counter + 1;
                    if start_in = '1' then
                        state <= read_ram;
                    else
                        state <= idle;
                    end if;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end rtl;
