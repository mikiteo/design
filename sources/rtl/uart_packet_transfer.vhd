library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_packet_transfer is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        --data signals
        data_check  : in  std_logic;
        dout        : out std_logic_vector(7 downto 0);
        --tx signals
        tx_start    : out std_logic;
        tx_busy     : in  std_logic
    );
end uart_packet_transfer;

architecture rtl of uart_packet_transfer is

    type state_type is (idle, wait_busy, send_next);
    signal state       : state_type := idle;

    type frame_array is array(0 to 4) of std_logic_vector(7 downto 0);
    signal cmd_buffer : frame_array := (
        0 => x"55",
        1 => x"AA",
        2 => x"81",
        3 => x"00",
        4 => x"FA"
    );
    signal index  : integer range 0 to 4 := 0;

begin

    process(clk)
    begin
        if rst = '1' then
            state <= idle;
            index <= 0;
            dout <= (others => '0');
            tx_start <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    if data_check = '1' and tx_busy = '0' then
                        index <= 0;
                        state <= wait_busy;
                    end if;

                when wait_busy =>
                    if tx_busy = '0' then
                        dout <= cmd_buffer(index);
                        tx_start <= '1';
                        state <= send_next;
                    end if;

                when send_next =>
                    if tx_busy = '1' then
                        if index = 4 then
                            state <= idle;
                            tx_start <= '0';
                        else
                            index <= index + 1;
                            state <= wait_busy;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end rtl;
