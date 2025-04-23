library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is
    port (
        clk                     : in    std_logic;

        start_work_master       : in    std_logic;
        miso_master             : in    std_logic;
        mosi_master             : out   std_logic;
        sclk_master             : out   std_logic;
        cs_master               : out   std_logic;

        start_work_slave        : in    std_logic;
        miso_slave              : out   std_logic;
        mosi_slave              : in    std_logic;
        sclk_slave              : in    std_logic;
        cs_slave                : in    std_logic
    );
end top_module;

architecture rtl of top_module is

    -- Signals for RAM master buffer (input buffer)

    signal ce_ram_master_a             : std_logic;
    signal we_ram_master_a             : std_logic;
    signal addr_ram_master_a           : std_logic_vector(7 downto 0);
    signal data_in_ram_master_a        : std_logic_vector(7 downto 0);
    signal data_out_ram_master_a       : std_logic_vector(7 downto 0);

    signal ce_ram_master_b             : std_logic;
    signal we_ram_master_b             : std_logic;
    signal addr_ram_master_b           : std_logic_vector(7 downto 0);
    signal data_in_master_ram_b        : std_logic_vector(7 downto 0);
    signal data_out_master_ram_b       : std_logic_vector(7 downto 0);

    -- Signals for RAM slave buffer (output buffer)

    signal ce_ram_slave_a              : std_logic;
    signal we_ram_slave_a              : std_logic;
    signal addr_ram_slave_a            : std_logic_vector(7 downto 0);
    signal data_in_ram_slave_a         : std_logic_vector(7 downto 0);
    signal data_out_ram_slave_a        : std_logic_vector(7 downto 0);

    signal ce_ram_slave_b              : std_logic;
    signal we_ram_slave_b              : std_logic;
    signal addr_ram_slave_b            : std_logic_vector(7 downto 0);
    signal data_in_slave_ram_b         : std_logic_vector(7 downto 0);
    signal data_out_slave_ram_b        : std_logic_vector(7 downto 0);

    -- Signals for SPI master

    signal spi_busy_master             : std_logic;
    signal start_transmit_master       : std_logic;

    -- Signals for SPI slave

    signal spi_busy_slave              : std_logic;
    signal start_transmit_slave        : std_logic;

    -- Signals for ALU 

    signal alu_busy                    : std_logic;
    signal alu_ready                   : std_logic;
    signal next_data_alu               : std_logic;
    
    --Signals for trash
    
    signal trash_sig                    : std_logic_vector(7 downto 0);

begin

    -- Master dma spi ram controller 
    spi_ctrl_ram_master: entity work.spi_ram_controller_master
        port map (
            clk             => clk,
            start_work      => start_work_master,
            ce              => ce_ram_master_a,
            we              => we_ram_master_a,
            start_transmit  => start_transmit_master,
            addr            => addr_ram_master_a,
            spi_busy        => spi_busy_master
        );

    -- Master spi
    spi_inst_master: entity work.spi_master
        port map (
            clk             => clk,
            sclk            => sclk_master,
            cs              => cs_master,
            mosi            => mosi_master,
            miso            => miso_master,
            data_read       => data_out_ram_master_a,
            data_write      => data_in_ram_master_a,
            start_transmit  => start_transmit_master,
            busy_out        => spi_busy_master
        );
    
    -- Master dual-port RAM
    ram_inst_master: entity work.dp_ram
        port map (
            clka            => clk,
            wea             => we_ram_master_a,
            ena             => ce_ram_master_a,
            addra           => addr_ram_master_a,
            dina            => data_in_ram_master_a,
            douta           => data_out_ram_master_a,
            web             => we_ram_master_b,
            enb             => ce_ram_master_b,
            addrb           => addr_ram_master_b,
            dinb            => trash_sig,
            doutb           => open
        );

    --Master dma ram alu controller
    alu_ctrl_master: entity work.alu_ram_receive
        port map (
            clk             => clk,
            ce              => ce_ram_master_b,
            we              => we_ram_master_b,
            addr            => addr_ram_master_b,
            calc_busy       => alu_busy,
            next_data       => next_data_alu
        );

    -- Slave dma spi ram controller 
    spi_ctrl_ram_slave: entity work.spi_ram_controller_slave
        port map (
            clk             => clk,
            start_work      => start_work_slave,
            ce              => ce_ram_slave_a,
            we              => we_ram_slave_a,
            start_transmit  => start_transmit_slave,
            addr            => addr_ram_slave_a,
            spi_busy        => spi_busy_slave
        );

    -- Slave spi
    spi_inst_slave: entity work.spi_slave
        port map (
            clk             => clk,
            sclk            => sclk_slave,
            cs              => cs_slave,
            mosi            => mosi_slave,
            miso            => miso_slave,
            data_read       => data_out_ram_slave_a,
            data_write      => data_in_ram_slave_a,
            start_transmit  => start_transmit_slave,
            busy_out        => spi_busy_slave
        );

    -- Slave dual-port RAM
    ram_inst_slave: entity work.dp_ram
        port map (
            clka            => clk,
            wea             => we_ram_slave_a,
            ena             => ce_ram_slave_a,
            addra           => addr_ram_slave_a,
            dina            => data_in_ram_slave_a,
            douta           => data_out_ram_slave_a,
            web             => we_ram_slave_b,
            enb             => ce_ram_slave_b,
            addrb           => addr_ram_slave_b,
            dinb            => trash_sig,
            doutb           => open
        );

    --Slave dma ram alu controller
    alu_ctrl_slave: entity work.alu_ram_transfer
        port map (
            clk             => clk,
            ce              => ce_ram_slave_b,
            we              => we_ram_slave_b,
            addr            => addr_ram_slave_b,
            calc_ready      => alu_ready,
            next_data       => next_data_alu
        );


    empty_ctrl_alu: entity work.empty_check
        port map (
            clk            => clk,
            addr_r         => addr_ram_master_b,
            addr_w         => addr_ram_slave_b,
            next_data      => next_data_alu
        );
 end rtl;