library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.measurement_pkg.all;

-------------------------------------------------------------------------------
-- Entity: timestamp_counter
--
-- Description:
--   Free-running 64-bit timestamp counter.
--
--   The counter increments on every rising clock edge while enable = '1'.
--   When capture = '1', the current counter value is copied to
--   captured_timestamp and capture_valid is asserted for one clock cycle.
-------------------------------------------------------------------------------

entity timestamp_counter is
    port (
        clk                : in  std_logic;
        reset_n            : in  std_logic;
        enable             : in  std_logic;
        capture            : in  std_logic;

        current_timestamp  : out timestamp_t;
        captured_timestamp : out timestamp_t;
        capture_valid      : out std_logic
    );
end entity timestamp_counter;


architecture rtl of timestamp_counter is

    signal timestamp_reg : timestamp_t := (others => '0');
    signal captured_reg  : timestamp_t := (others => '0');
    signal valid_reg     : std_logic   := '0';

begin

    process (clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then

                timestamp_reg <= (others => '0');
                captured_reg  <= (others => '0');
                valid_reg     <= '0';

            else

                valid_reg <= '0';

                if capture = '1' then
                    captured_reg <= timestamp_reg;
                    valid_reg    <= '1';
                end if;

                if enable = '1' then
                    timestamp_reg <= timestamp_reg + 1;
                end if;

            end if;

        end if;
    end process;

    current_timestamp  <= timestamp_reg;
    captured_timestamp <= captured_reg;
    capture_valid      <= valid_reg;

end architecture rtl;