library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is
    port (
        clk                     : in std_logic;
        start_work_master       : in std_logic;
        start_work_slave        : in std_logic;
        miso_master             : in std_logic;
        mosi_master             : out std_logic;
        sclk_master             : out std_logic;
        cs_master               : out std_logic;
        miso_slave              : out std_logic;
        mosi_slave              : in std_logic;
        sclk_slave              : in std_logic;
        cs_slave                : in std_logic
    );
end top_module;

architecture rtl of top_module is

    signal ce_master            : std_logic;
    signal we_master            : std_logic;
    signal start_transmit_m     : std_logic;
    signal spi_busy_master      : std_logic;
    signal addr_master          : std_logic_vector(7 downto 0);
    signal data_read_master     : std_logic_vector(7 downto 0);
    signal data_write_master    : std_logic_vector(7 downto 0);

    signal ce_slave             : std_logic;
    signal we_slave             : std_logic;
    signal start_transmit_s     : std_logic;
    signal spi_busy_slave       : std_logic;
    signal addr_slave           : std_logic_vector(7 downto 0);
    signal data_read_slave      : std_logic_vector(7 downto 0);
    signal data_write_slave     : std_logic_vector(7 downto 0);

begin

    dma_ctrl_master: entity work.spi_ram_controller_master
        port map (
            clk             => clk,
            start_work      => start_work_master,
            ce              => ce_master,
            we              => we_master,
            start_transmit  => start_transmit_m,
            addr            => addr_master,
            spi_busy        => spi_busy_master
        );

    spi_inst_master: entity work.spi_master
        port map (
            clk           => clk,
            sclk          => sclk_master,
            cs            => cs_master,
            mosi          => mosi_master,
            miso          => miso_master,
            data_read     => data_read_master,
            data_write    => data_write_master,
            start_transmit => start_transmit_m,
            busy_out      => spi_busy_master
        );

    ram_inst: entity work.dp_ram
        port map (
            clka  => clk,
            wea   => we_master,
            ena   => ce_master,
            addra => addr_master,
            dina  => data_write_master,
            douta => data_read_master,
            web   => we_slave,
            enb   => ce_slave,
            addrb => addr_slave,
            dinb  => data_write_slave,
            doutb => data_read_slave
        );

    dma_ctrl_slave: entity work.spi_ram_controller_slave
        port map (
            clk             => clk,
            ce              => ce_slave,
            we              => we_slave,
            start_transmit  => start_transmit_s,
            addr            => addr_slave,
            spi_busy        => spi_busy_slave,
            start_work      => start_work_slave
        );

    spi_inst_slave: entity work.spi_slave
        port map (
            clk           => clk,
            sclk          => sclk_slave,
            cs            => cs_slave,
            mosi          => mosi_slave,
            miso          => miso_slave,
            data_read     => data_read_slave,
            data_write    => data_write_slave,
            start_transmit => start_transmit_s,
            busy_out      => spi_busy_slave
        );

end rtl;
