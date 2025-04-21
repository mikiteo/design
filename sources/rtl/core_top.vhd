library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_module is
    port (
        clk           : in  std_logic;

        calc_busy     : in  std_logic;
        calc_ready    : in  std_logic;
        data_in       : in  std_logic_vector(7 downto 0);
        data_out      : out std_logic_vector(7 downto 0);

        read_addr     : out std_logic_vector(7 downto 0);
        write_addr    : out std_logic_vector(7 downto 0);

        next_data     : out std_logic
    );
end top_module;

architecture rtl of top_module is

    signal addr_r, addr_w : std_logic_vector(7 downto 0);
    signal douta, doutb   : std_logic_vector(7 downto 0);
    signal dina, dinb     : std_logic_vector(7 downto 0);
    signal wea, web       : std_logic := '0';
    signal ena, enb       : std_logic := '0';
    signal next_data_sig : std_logic;


begin

    fsm_receive_inst : entity work.alu_ram_receive(rtl)
        port map (
            clk         => clk,
            ce          => ena,
            we          => wea,
            addr        => addr_r,
            calc_busy   => calc_busy,
            next_data   => next_data_sig
        );

    fsm_transfer_inst : entity work.alu_ram_transfer(rtl)
        port map (
            clk         => clk,
            ce          => enb,
            we          => web,
            addr        => addr_w,
            calc_ready  => calc_ready,
            next_data   => next_data_sig
        );

    fsm_empty_inst : entity work.empty_check(rtl)
        port map (
            clk         => clk,
            addr_r      => addr_r,
            addr_w      => addr_w,
            next_data   => next_data
        );

    bram_inst : entity work.dp_ram(rtl)
        generic map (
            RAM_WIDTH => 8,
            RAM_DEPTH => 256
        )
        port map (
            douta => douta,
            doutb => doutb,
            addra => addr_r,
            addrb => addr_w,
            dina  => data_in,
            dinb  => data_in,
            clka  => clk,
            wea   => wea,
            web   => web,
            ena   => ena,
            enb   => enb
        );

    read_addr  <= addr_r;
    write_addr <= addr_w;

    data_out <= douta;

end rtl;
