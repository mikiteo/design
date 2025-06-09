library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

entity top_module is generic (
        BAUD_RATE   : integer                       := 115_200;
        CLK_FREQ    : integer                       := 50_000_000;
        RAM_WIDTH   : integer                       := 16;
        RAM_DEPTH   : integer                       := 1024;
        DELTA_T     : integer                       := 10
);
    port (
        clk                   : in  std_logic;
        sw                    : in  std_logic_vector(1 downto 0);
        
        -- UART RX
        ck_io1                : in  std_logic;
        ce_ram_slave_a        : out std_logic;
        we_ram_slave_a        : out std_logic;
        addr_ram_slave_a      : out std_logic_vector(1 downto 0);
        data_in_ram_slave_a   : out std_logic_vector(15 downto 0);
        
        data_spi_ready        : out std_logic;

        -- UART TX
        ck_io0                : out std_logic
    );
end top_module;

architecture rtl of top_module is


    constant CYCLES_PER_DELTA : integer := (CLK_FREQ/ 1000)  * DELTA_T;

    signal reset_in                    : std_logic;
    signal tx                          : std_logic;
    signal rx                          : std_logic;

    signal rx_byte                     : std_logic_vector(7 downto 0);
    signal tx_byte                     : std_logic_vector(7 downto 0);

    signal delta_counter               : integer range 0 to CYCLES_PER_DELTA := 0;

    signal data_check                  : std_logic; 
    signal calc_busy                   : std_logic;
    signal calc_ready                  : std_logic;
    signal data_valid                  : std_logic;
    signal data_ready                  : std_logic;
    signal final_cmd                   : std_logic;

    signal data_in_ram_master_a        : std_logic_vector(15 downto 0);
    signal data_out_ram_master_a       : std_logic_vector(15 downto 0);
    signal we_ram_master_a             : std_logic;
    signal ce_ram_master_a             : std_logic;
    signal addr_ram_master_a           : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);

    signal data_in_ram_master_b        : std_logic_vector(15 downto 0);
    signal data_out_ram_master_b       : std_logic_vector(15 downto 0);
    signal we_ram_master_b             : std_logic;
    signal ce_ram_master_b             : std_logic;
    signal addr_ram_master_b           : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);

    signal data_out_ram_slave_a        : std_logic_vector(15 downto 0);

    signal data_in_ram_slave_b         : std_logic_vector(15 downto 0);
    signal data_out_ram_slave_b        : std_logic_vector(15 downto 0);
    signal addr_ram_slave_b            : std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);
    signal we_ram_slave_b              : std_logic;
    signal ce_ram_slave_b              : std_logic;


    -- Signals for UART RX

    signal rx_ready                    : std_logic;

    -- Signals for UART TX

    signal tx_start                    : std_logic;
    signal tx_busy                     : std_logic;

begin

    reset_in <= sw(0);
    ck_io0   <= tx;
    rx       <= ck_io1;

    process(clk)
    begin
        if rising_edge(clk) then
            if delta_counter = CYCLES_PER_DELTA - 1 then
                delta_counter <= 0;
                data_check <= '1';
            else
                delta_counter <= delta_counter + 1;
                data_check <= '0';
            end if;
        end if;
    end process;

    -- UART RX
    rx_inst : entity work.uart_rx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk           => clk,
            rst           => reset_in,
            rx            => rx,
            ready         => rx_ready,
            dout          => rx_byte
        );

    -- UART PACKET RECEIVER
    uart_packet_receiver: entity work.uart_packet_receiver
        generic map (
            RAM_DEPTH   => RAM_DEPTH
        )
        port map (
            clk         => clk,
            rst         => reset_in,
            rx_data     => rx_byte,
            rx_ready    => rx_ready,
            final_cmd   => final_cmd,
            we          => we_ram_master_a,
            ce          => ce_ram_master_a,
            addr        => addr_ram_master_a,
            dout        => data_in_ram_master_a
        );

    -- MASTER DUAL-PORT RAM
    ram_inst_master: entity work.dp_ram
        generic map (
            RAM_WIDTH       => RAM_WIDTH,
            RAM_DEPTH       => RAM_DEPTH
        )
        port map (
            clka            => clk,
            rsta            => reset_in,
            wea             => we_ram_master_a,
            ena             => ce_ram_master_a,
            addra           => addr_ram_master_a,
            dina            => data_in_ram_master_a,
            douta           => data_out_ram_master_a,
            rstb            => reset_in,
            web             => we_ram_master_b,
            enb             => ce_ram_master_b,
            addrb           => addr_ram_master_b,
            dinb            => (others => '0'),
            doutb           => data_out_ram_master_b
        );

    --DMA MASTER_RAM TO ALU CONTROLLER
    alu_ctrl_master: entity work.alu_ram_receive
        generic map (
            RAM_DEPTH => RAM_DEPTH
        )
        port map (
            clk             => clk,
            rst             => reset_in,
            ce              => ce_ram_master_b,
            we              => we_ram_master_b,
            addr            => addr_ram_master_b,
            final_cmd       => final_cmd,
            data_valid      => data_valid,
            data_ready      => data_ready,
            calc_busy       => calc_busy
        );

    arithmetic_logic_unit: entity work.alu
        generic map (
            DELTA_T => DELTA_T
        )
        port map (
            clk             => clk,
            rst             => reset_in,
            data_in         => data_out_ram_master_b,
            data_valid      => data_valid,
            data_ready      => data_ready,
            result_out      => data_in_ram_slave_a,
            calc_ready      => calc_ready,
            calc_busy       => calc_busy
        );

    --DMA ALU TO SLAVE_RAM CONTROLLER
    alu_ctrl_slave: entity work.alu_ram_transfer
        generic map (
            RAM_DEPTH => 4
        )
        port map (
            clk             => clk,
            rst             => reset_in,
            ce              => ce_ram_slave_a,
            we              => we_ram_slave_a,
            addr            => addr_ram_slave_a,
            data_ready      => data_spi_ready,
            calc_ready      => calc_ready
        );

    uart_packet_transfer: entity work.uart_packet_transfer
        port map (
            clk             => clk,
            rst             => reset_in,
            dout            => tx_byte,
            data_check      => data_check,
            tx_start        => tx_start,
            tx_busy         => tx_busy
        );

    -- UART TX
    tx_inst: entity work.uart_tx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk         => clk,
            rst         => reset_in,
            tx_start    => tx_start,
            din         => tx_byte,
            tx          => tx,
            tx_busy     => tx_busy
        );

 end rtl;