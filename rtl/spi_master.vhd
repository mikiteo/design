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
        ce                  : out std_logic                          -- RAM Enable
    );
end spi_master;

architecture rtl of spi_master is

    constant CLK_FREQ       : natural                := 100_000_000; -- 100 MHz 
    constant SCLK_FREQ      : natural                := 50_000_000;  -- 50 MHz 
    constant DIVIDER_VALUE  : natural                := (CLK_FREQ / SCLK_FREQ) / 2;
    constant WIDTH_CLK_CNT  : natural                := natural(ceil(log2(real(DIVIDER_VALUE))));

    type   state_t          is (idle, first_edge, second_edge, transmit_end, transmit_gap);
    signal state            : state_t                                           := idle;
    signal sclk_reg         : std_logic                                         := '0';
    signal cs_reg           : std_logic                                         := '1';
    signal data_shift_reg   : std_logic_vector       (7 downto 0);
    signal bit_cnt          : unsigned               (2 downto 0)               := (others => '0');
    signal sys_clk_cnt      : unsigned               (WIDTH_CLK_CNT-1 downto 0) := (others => '0');
    signal sys_clk_cnt_max  : std_logic;

begin
     -- System clock counter
    sys_clk_cnt_max <= '1' when (to_integer(sys_clk_cnt) = DIVIDER_VALUE-1) else '0';
    process(clk)
    begin
        if falling_edge(clk) then
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
        if falling_edge(clk) then
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
                    if data_read /= data_shift_reg then
                        data_shift_reg <= data_read;
                        state <= first_edge;
                    end if;
                when first_edge =>
                    cs_reg <= '0';
                    bit_cnt <= (others => '0');
                    state <= second_edge;
                when second_edge =>
                    if sclk_reg = '1' then
                        data_shift_reg(7 downto 1) <= data_shift_reg(6 downto 0);
                        data_shift_reg(0) <= '0';
                        if bit_cnt = "0111" then
                            state <= transmit_end;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    end if;
                when transmit_end =>
                    cs_reg <= '1';
                    state <= transmit_gap;
                when transmit_gap =>
                    state <= idle;
                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

    -- Output signals
    MOSI <= data_shift_reg(7);
    cs <= cs_reg;
    addrs <= (others => '0');  
    sclk <= sclk_reg;
    we <= not cs_reg;
    ce <= not cs_reg;
    data_write <= data_shift_reg;

end rtl;
