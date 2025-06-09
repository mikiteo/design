library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_top is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        sck         : out std_logic;
        mosi        : out std_logic;
        cs          : out std_logic;
        ce          : out std_logic;
        we          : out std_logic;
        addr        : out std_logic_vector(9 downto 0);
        data_ready  : in  std_logic;
        data_in     : in  std_logic_vector(15 downto 0)
    );
end spi_master_top;

architecture rtl of spi_master_top is

    type state_type is (idle, start_read, waiting_data, transmit, finish_byte);

    signal state     : state_type := idle;
    signal addr_cnt  : std_logic_vector(9 downto 0) := (others => '0');
    signal bit_cnt   : integer := 0;
    signal cnt       : integer := 0;
    signal index     : integer := 0;
    signal i         : integer := 0;
    signal cs_cnt    : integer := 0;
    signal shift_reg : std_logic_vector(15 downto 0) := (others => '0');
    signal sck_reg   : std_logic := '0';
    type frame_array is array(0 to 2) of std_logic_vector(15 downto 0);
    signal cmd_buffer : frame_array := (
        0 => x"55AA",
        1 => x"AA00",
        2 => x"8113"
    );

begin

    we <= '0';
    
    process(clk)
    begin
        if rst = '1' then
            state     <= idle;
            addr_cnt  <= (others => '0');
            bit_cnt   <= 0;
            index     <= 0;
            shift_reg <= (others => '0');
            sck_reg   <= '0';
            i         <= 0;
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    cs <= '1';
                    addr <= (others => '0');
                    ce <= '0';
                    if data_ready = '1' then
                        ce <= '1';
                        state  <= start_read;
                    end if;

                when start_read =>
                    addr <= addr_cnt;
                    if index = 3 then
                        index <= 0;
                        addr_cnt <= (others => '0');
                        cs <= '1';
                        state <= idle;
                    else
                        state <= waiting_data;
                        cs <= '0'; 
                    end if;

                when waiting_data =>
                    i <= i + 1;
                    if i = 2 then
                        i <= 0;
                        shift_reg <= data_in;
                        state <= transmit;
                    end if;

                when transmit =>
                    sck_reg <= not sck_reg;
                    sck <= sck_reg;

                    if sck_reg = '1' then
                        mosi <= shift_reg(15);
                        shift_reg <= shift_reg(14 downto 0) & '0';
                        bit_cnt <= bit_cnt + 1;
                    end if;

                    if bit_cnt = 16 then
                        addr_cnt <= std_logic_vector(unsigned(addr_cnt) + 1);
                        bit_cnt <= 0;
                        index <= index + 1;
                        state <= start_read;
                    end if;

                when others =>
                    state <= idle;

            end case;
        end if;
    end process;
end rtl;
