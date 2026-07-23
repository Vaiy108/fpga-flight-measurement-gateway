library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.measurement_pkg.all;

-------------------------------------------------------------------------------
-- Testbench: timestamp_counter_tb
--
-- Verifies:
--   1. Reset behavior
--   2. Counter increment
--   3. Counter hold when disabled
--   4. Timestamp capture
--   5. capture_valid pulse width
-------------------------------------------------------------------------------

entity timestamp_counter_tb is
end entity timestamp_counter_tb;


architecture sim of timestamp_counter_tb is

    ---------------------------------------------------------------------------
    -- Testbench constants
    ---------------------------------------------------------------------------

    constant CLK_PERIOD : time := 20 ns;

    ---------------------------------------------------------------------------
    -- DUT signals
    ---------------------------------------------------------------------------

    signal clk                : std_logic := '0';
    signal reset_n            : std_logic := '0';
    signal enable             : std_logic := '0';
    signal capture            : std_logic := '0';

    signal current_timestamp  : timestamp_t;
    signal captured_timestamp : timestamp_t;
    signal capture_valid      : std_logic;

    signal simulation_done    : boolean := false;

begin

    ---------------------------------------------------------------------------
    -- Device Under Test
    ---------------------------------------------------------------------------

    dut : entity work.timestamp_counter
        port map (
            clk                => clk,
            reset_n            => reset_n,
            enable             => enable,
            capture            => capture,
            current_timestamp  => current_timestamp,
            captured_timestamp => captured_timestamp,
            capture_valid      => capture_valid
        );

    ---------------------------------------------------------------------------
    -- Clock generation
    ---------------------------------------------------------------------------

    clock_process : process
    begin

        while not simulation_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;

        wait;

    end process clock_process;

    ---------------------------------------------------------------------------
    -- Stimulus and checks
    ---------------------------------------------------------------------------

    stimulus_process : process

        variable timestamp_before_hold : timestamp_t;
        variable expected_capture      : timestamp_t;

    begin

        -----------------------------------------------------------------------
        -- Test 1: Reset
        -----------------------------------------------------------------------

        report "TEST 1: Reset behavior";

        reset_n <= '0';
        enable  <= '0';
        capture <= '0';

        wait for 3 * CLK_PERIOD;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = to_unsigned(0, TIMESTAMP_WIDTH)
            report "Reset test failed: current_timestamp is not zero"
            severity error;

        assert captured_timestamp = to_unsigned(0, TIMESTAMP_WIDTH)
            report "Reset test failed: captured_timestamp is not zero"
            severity error;

        assert capture_valid = '0'
            report "Reset test failed: capture_valid is asserted"
            severity error;

        -----------------------------------------------------------------------
        -- Release reset
        -----------------------------------------------------------------------

        reset_n <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        -----------------------------------------------------------------------
        -- Test 2: Counter increment
        -----------------------------------------------------------------------

        report "TEST 2: Counter increment";

        enable <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = to_unsigned(1, TIMESTAMP_WIDTH)
            report "Increment test failed after first enabled clock"
            severity error;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = to_unsigned(2, TIMESTAMP_WIDTH)
            report "Increment test failed after second enabled clock"
            severity error;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = to_unsigned(3, TIMESTAMP_WIDTH)
            report "Increment test failed after third enabled clock"
            severity error;

        -----------------------------------------------------------------------
        -- Test 3: Counter hold
        -----------------------------------------------------------------------

        report "TEST 3: Counter hold when disabled";

        enable <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        timestamp_before_hold := current_timestamp;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = timestamp_before_hold
            report "Hold test failed: counter changed while enable was low"
            severity error;

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp = timestamp_before_hold
            report "Hold test failed: counter did not remain constant"
            severity error;

        -----------------------------------------------------------------------
        -- Test 4: Timestamp capture
        -----------------------------------------------------------------------

        report "TEST 4: Timestamp capture";

        enable <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        expected_capture := current_timestamp;

        capture <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert captured_timestamp = expected_capture
            report "Capture test failed: captured timestamp is incorrect"
            severity error;

        assert capture_valid = '1'
            report "Capture test failed: capture_valid was not asserted"
            severity error;

        capture <= '0';

        -----------------------------------------------------------------------
        -- Test 5: capture_valid one-cycle pulse
        -----------------------------------------------------------------------

        report "TEST 5: capture_valid pulse width";

        wait until rising_edge(clk);
        wait for 1 ns;

        assert capture_valid = '0'
            report "Pulse-width test failed: capture_valid remained high"
            severity error;

        -----------------------------------------------------------------------
        -- Test 6: Counter continues after capture
        -----------------------------------------------------------------------

        report "TEST 6: Counter continues after capture";

        wait until rising_edge(clk);
        wait for 1 ns;

        assert current_timestamp > captured_timestamp
            report "Post-capture test failed: counter did not continue"
            severity error;

        -----------------------------------------------------------------------
        -- Final result
        -----------------------------------------------------------------------

        report "==============================================";
        report "TIMESTAMP COUNTER TEST PASSED";
        report "==============================================";

        simulation_done <= true;

        wait for CLK_PERIOD;
        wait;

    end process stimulus_process;

end architecture sim;