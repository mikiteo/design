library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is generic (
        SYNTHESIS : boolean := true
);
    port (
        clk_in                    : in    std_logic;
        reset_in                  : in    std_logic;

        data_in                   : in    std_logic;
        data_out                  : out   std_logic;
        
        data_in_ram_slave_a       : in    std_logic_vector(7 downto 0);
        calc_ready                : in    std_logic;
        calc_busy                 : in    std_logic
    );
end top_module;

architecture rtl of top_module is

    -- Signals for RAM master buffer (input buffer)

    signal data_in_ram_master_a        : std_logic_vector(7 downto 0);
    signal data_out_ram_master_a       : std_logic_vector(7 downto 0);
    signal ce_ram_master_a             : std_logic;
    signal we_ram_master_a             : std_logic;
    signal addr_ram_master_a           : std_logic_vector(7 downto 0);

    signal data_in_master_ram_b        : std_logic_vector(7 downto 0);
    signal data_out_master_ram_b       : std_logic_vector(7 downto 0);
    signal ce_ram_master_b             : std_logic;
    signal we_ram_master_b             : std_logic;
    signal addr_ram_master_b           : std_logic_vector(7 downto 0);

    -- Signals for RAM slave buffer (output buffer)

    signal data_out_ram_slave_a        : std_logic_vector(7 downto 0);
    signal ce_ram_slave_a              : std_logic;
    signal we_ram_slave_a              : std_logic;
    signal addr_ram_slave_a            : std_logic_vector(7 downto 0);

    signal data_in_ram_slave_b         : std_logic_vector(7 downto 0);
    signal data_out_ram_slave_b        : std_logic_vector(7 downto 0);
    signal ce_ram_slave_b              : std_logic;
    signal we_ram_slave_b              : std_logic;
    signal addr_ram_slave_b            : std_logic_vector(7 downto 0);

    -- Signals for UART RX

    signal rx_ready                    : std_logic;
    signal parity_error                : std_logic;

    -- Signals for UART TX

    signal tx_start                    : std_logic;
    signal tx_busy                     : std_logic;
    
    -- Signals for ALU
    signal data_ready                  : std_logic;
    signal clk                         : std_logic;

component clk_wiz_0 is
    port
    (
        reset : in std_logic;
        clk_in1 : in std_logic;
        clk_out1 : out std_logic;
        clk_out2 : out std_logic;
        locked  : out std_logic
    );
end component;

begin

    -- UART RX
    uart_inst_rx: entity work.uart_rx
        port map (
            clk             => clk,
            reset           => reset_in,
            rx              => data_in,
            ready           => rx_ready,
            dout            => data_in_ram_master_a,
            parity_error    => parity_error
        );

    -- DMA UART TO MASTER_RAM CONTROLLER
    uart_ctrl_ram_master: entity work.dma_rx_bram
        port map (
            clk             => clk,
            ce              => ce_ram_master_a,
            we              => we_ram_master_a,
            addr            => addr_ram_master_a,
            ready           => rx_ready
        );

    -- MASTER DUAL-PORT RAM
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
            dinb            => (others => '0'),
            doutb           => data_out_master_ram_b
        );

    --DMA MASTER_RAM TO ALU CONTROLLER
    alu_ctrl_master: entity work.alu_ram_receive
        port map (
            clk             => clk,
            ce              => ce_ram_master_b,
            we              => we_ram_master_b,
            addr            => addr_ram_master_b,
            calc_busy       => calc_busy
        );

    ------------------------------
    -- ALU WILL BE PLACED LATER --
    ------------------------------

    --DMA ALU TO SLAVE_RAM CONTROLLER
    alu_ctrl_slave: entity work.alu_ram_transfer
        port map (
            clk             => clk,
            ce              => ce_ram_slave_a,
            we              => we_ram_slave_a,
            addr            => addr_ram_slave_a,
            calc_ready      => calc_ready,
            data_ready      => data_ready
        );

    -- SLAVE DUAL-PORT RAM
    ram_inst_slave: entity work.dp_ram
        port map (
            clka            => clk,
            wea             => we_ram_slave_a,
            ena             => ce_ram_slave_a,
            addra           => addr_ram_slave_a,
            dina            => data_in_ram_slave_a,
            douta           => open,
            web             => we_ram_slave_b,
            enb             => ce_ram_slave_b,
            addrb           => addr_ram_slave_b,
            dinb            => data_in_ram_slave_b,
            doutb           => data_out_ram_slave_b
        );

    -- DMA SLAVE_RAM TO UART TX CONTROLLER
    uart_ctrl_ram_slave: entity work.dma_bram_tx
        port map (
            clk             => clk,
            ce              => ce_ram_slave_b,
            we              => we_ram_slave_b,
            addr            => addr_ram_slave_b,
            data_ready      => data_ready,
            tx_start        => tx_start,
            busy            => tx_busy 
        );  

    -- UART TX
    uart_inst_tx: entity work.uart_tx
        port map (
            clk             => clk,
            reset           => reset_in,
            tx_start        => tx_start,
            din             => data_out_ram_slave_b,
            tx              => data_out,
            tx_busy         => tx_busy
        );
        
    clock_gen_block : if SYNTHESIS = true generate
        clock_genegate: clk_wiz_0
            port map (
                reset       => reset_in,
                clk_in1     => clk_in,
                clk_out1    => open,
                clk_out2    => clk,
                locked      => open
            );
    end generate clock_gen_block;

    no_clock_gen_block : if SYNTHESIS = false generate
        clk <= clk_in;
    end generate no_clock_gen_block;

    
 end rtl;