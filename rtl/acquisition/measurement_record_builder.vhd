library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.measurement_pkg.all;

-------------------------------------------------------------------------------
-- Entity: measurement_record_builder
--
-- Description:
--   Registers incoming measurement information into a structured measurement
--   record. When input_valid is asserted, all input fields are captured on the
--   rising clock edge and record_valid is asserted for one clock cycle.
--
--   The resulting record can later be packed and written into a FIFO or exposed
--   through an Avalon-MM interface.
-------------------------------------------------------------------------------

entity measurement_record_builder is
    port (
        clk             : in  std_logic;
        reset_n         : in  std_logic;

        input_valid     : in  std_logic;
        timestamp_in    : in  timestamp_t;
        channel_id_in   : in  channel_id_t;
        sample_in       : in  sample_t;
        status_in       : in  status_t;
        sequence_id_in  : in  sequence_id_t;

        record_out      : out measurement_record_t;
        packed_record   : out packed_measurement_record_t;
        record_valid    : out std_logic
    );
end entity measurement_record_builder;


architecture rtl of measurement_record_builder is

    signal record_reg : measurement_record_t :=
        MEASUREMENT_RECORD_RESET;

    signal valid_reg : std_logic := '0';

begin

    ---------------------------------------------------------------------------
    -- Measurement-record capture
    ---------------------------------------------------------------------------

    process (clk)
    begin
        if rising_edge(clk) then

            if reset_n = '0' then

                record_reg <= MEASUREMENT_RECORD_RESET;
                valid_reg  <= '0';

            else

                -- record_valid is a one-clock-cycle pulse.
                valid_reg <= '0';

                if input_valid = '1' then

                    record_reg.timestamp   <= timestamp_in;
                    record_reg.channel_id  <= channel_id_in;
                    record_reg.sample      <= sample_in;
                    record_reg.status      <= status_in;
                    record_reg.sequence_id <= sequence_id_in;

                    valid_reg <= '1';

                end if;

            end if;

        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------

    record_out    <= record_reg;
    packed_record <= pack_record(record_reg);
    record_valid  <= valid_reg;

end architecture rtl;