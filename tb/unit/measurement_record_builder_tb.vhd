library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.measurement_pkg.all;

entity measurement_record_builder_tb is
end entity measurement_record_builder_tb;

architecture sim of measurement_record_builder_tb is

    constant CLK_PERIOD : time := 20 ns;

    signal clk            : std_logic := '0';
    signal reset_n        : std_logic := '0';

    signal input_valid    : std_logic := '0';
    signal timestamp_in   : timestamp_t := (others => '0');
    signal channel_id_in  : channel_id_t := CHANNEL_INVALID;
    signal sample_in      : sample_t := (others => '0');
    signal status_in      : status_t := STATUS_NONE;
    signal sequence_id_in : sequence_id_t := (others => '0');

    signal record_out     : measurement_record_t;
    signal packed_record  : packed_measurement_record_t;
    signal record_valid   : std_logic;

    signal simulation_done : boolean := false;

begin

    dut : entity work.measurement_record_builder
        port map (
            clk            => clk,
            reset_n        => reset_n,
            input_valid    => input_valid,
            timestamp_in   => timestamp_in,
            channel_id_in  => channel_id_in,
            sample_in      => sample_in,
            status_in      => status_in,
            sequence_id_in => sequence_id_in,
            record_out     => record_out,
            packed_record  => packed_record,
            record_valid   => record_valid
        );

    clock_process : process
    begin
        while not simulation_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stimulus_process : process

        variable expected_record : measurement_record_t;

    begin

        -----------------------------------------------------------------------
        -- Test 1: Reset
        -----------------------------------------------------------------------

        report "TEST 1: Reset behavior";

        reset_n <= '0';
        wait for 3 * CLK_PERIOD;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert record_out = MEASUREMENT_RECORD_RESET
            report "Reset test failed: record_out not reset"
            severity error;

        assert record_valid = '0'
            report "Reset test failed: record_valid asserted"
            severity error;

        -----------------------------------------------------------------------
        -- Test 2: Capture positive sample
        -----------------------------------------------------------------------

        report "TEST 2: Capture positive measurement";

        reset_n        <= '1';
        timestamp_in   <= to_unsigned(1000, TIMESTAMP_WIDTH);
        channel_id_in  <= CHANNEL_ADC;
        sample_in      <= to_signed(1234, SAMPLE_WIDTH);
        status_in      <= STATUS_VALID;
        sequence_id_in <= to_unsigned(10, SEQUENCE_WIDTH);
        input_valid    <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        expected_record.timestamp   := to_unsigned(1000, TIMESTAMP_WIDTH);
        expected_record.channel_id  := CHANNEL_ADC;
        expected_record.sample      := to_signed(1234, SAMPLE_WIDTH);
        expected_record.status      := STATUS_VALID;
        expected_record.sequence_id := to_unsigned(10, SEQUENCE_WIDTH);

        assert record_out = expected_record
            report "Positive measurement capture failed"
            severity error;

        assert packed_record = pack_record(expected_record)
            report "Packed record mismatch for positive sample"
            severity error;

        assert record_valid = '1'
            report "record_valid not asserted during valid input"
            severity error;

        -----------------------------------------------------------------------
        -- Test 3: record_valid pulse
        -----------------------------------------------------------------------

        report "TEST 3: record_valid pulse width";

        input_valid <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert record_valid = '0'
            report "record_valid remained high for more than one cycle"
            severity error;

        assert record_out = expected_record
            report "record_out changed without input_valid"
            severity error;

        -----------------------------------------------------------------------
        -- Test 4: Capture negative sample
        -----------------------------------------------------------------------

        report "TEST 4: Capture negative measurement";

        timestamp_in   <= to_unsigned(2000, TIMESTAMP_WIDTH);
        channel_id_in  <= CHANNEL_UART;
        sample_in      <= to_signed(-250, SAMPLE_WIDTH);
        status_in      <= set_status_bit(
                              STATUS_VALID,
                              STATUS_DATA_ERROR_BIT
                          );
        sequence_id_in <= to_unsigned(11, SEQUENCE_WIDTH);
        input_valid    <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        expected_record.timestamp   := to_unsigned(2000, TIMESTAMP_WIDTH);
        expected_record.channel_id  := CHANNEL_UART;
        expected_record.sample      := to_signed(-250, SAMPLE_WIDTH);
        expected_record.status      := set_status_bit(
                                           STATUS_VALID,
                                           STATUS_DATA_ERROR_BIT
                                       );
        expected_record.sequence_id := to_unsigned(11, SEQUENCE_WIDTH);

        assert record_out = expected_record
            report "Negative measurement capture failed"
            severity error;

        assert packed_record = pack_record(expected_record)
            report "Packed record mismatch for negative sample"
            severity error;

        assert unpack_record(packed_record) = expected_record
            report "Pack/unpack round-trip failed"
            severity error;

        assert record_valid = '1'
            report "record_valid not asserted for negative measurement"
            severity error;

        input_valid <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert record_valid = '0'
            report "record_valid did not return low"
            severity error;

        -----------------------------------------------------------------------
        -- Final result
        -----------------------------------------------------------------------

        report "==============================================";
        report "MEASUREMENT RECORD BUILDER TEST PASSED";
        report "==============================================";

        simulation_done <= true;

        wait for CLK_PERIOD;
        wait;

    end process;

end architecture sim;