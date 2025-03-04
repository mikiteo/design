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
        MOSI                : out std_logic;                         -- Master Out Slave In
        MISO                : in  std_logic;                         -- Master In Slave Out
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

    constant CLK_FREQ       : natural                := 100_000_000; -- 100 MHz 
    constant SCLK_FREQ      : natural                := 50_000_000;  -- 50 MHz 
    constant DIVIDER_VALUE  : natural                := (CLK_FREQ / SCLK_FREQ) / 2;
    constant WIDTH_CLK_CNT  : natural                := natural(ceil(log2(real(DIVIDER_VALUE))));

    type state_t is (idle, read_ram, start_transfer, transfer_data, write_ram, end_transfer);
    signal state            : state_t                                           := idle;
    signal sclk_reg         : std_logic                                         := '0';
    signal cs_reg           : std_logic                                         := '1';
    signal data_shift_reg   : std_logic_vector       (7 downto 0);
    signal bit_cnt          : unsigned               (2 downto 0)               := (others => '0');
    signal sys_clk_cnt      : unsigned               (WIDTH_CLK_CNT-1 downto 0) := (others => '0');
    signal sys_clk_cnt_max  : std_logic;
    signal addr_counter     : unsigned               (7 downto 0)               := (others => '0');
    signal state_tr         : std_logic                                         := '0';

begin
     -- System clock counter
    sys_clk_cnt_max <= '1' when (to_integer(sys_clk_cnt) = DIVIDER_VALUE-1) else '0';
    process(clk)
    begin
        if rising_edge(clk) then
            if sys_clk_cnt_max = '1' then
                sys_clk_cnt <= (others => '0');
            else
                sys_clk_cnt <= sys_clk_cnt + 1;
            end if;
        end if;
    end process;

    -- SPI clock generation
    process(clk)
    begin
        if rising_edge(clk) then
            if sys_clk_cnt_max = '1' then
                sclk_reg <= not sclk_reg;
            end if;
        end if;
    end process;

    -- FSM for SPI Master
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    cs_reg <= '1';
                    busy_out <= '0';
                    we <= '0';
                    ce <= '0';
                    if start_in = '1' then
                        state <= read_ram;
                        state_tr <= '1';
                    end if;

                when read_ram =>
                    ce <= '1';
                    state_tr <= '0';
                    addrs <= std_logic_vector(addr_counter);
                    state <= start_transfer;

                when start_transfer =>
                    cs_reg <= '0';
                    busy_out <= '1';
                    bit_cnt <= (others => '0');
                    data_shift_reg <= data_read;
                    state <= transfer_data;

                when transfer_data =>
                    if sys_clk_cnt_max = '1' then
                        data_shift_reg(7 downto 1) <= data_shift_reg(6 downto 0);
                        data_shift_reg(0) <= '0';
                        if bit_cnt = "111" then
                            state <= write_ram;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    end if;

                when write_ram =>
                    cs_reg <= '1';
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

    -- Assign signals
    MOSI <= data_shift_reg(7);
    cs <= cs_reg;
    sclk <= sclk_reg;

end rtl;
