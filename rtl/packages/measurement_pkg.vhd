library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Package: measurement_pkg
--
-- Description:
--   Defines common data widths, channel identifiers, status-bit positions,
--   the measurement record type, and conversion functions used throughout
--   the FPGA Flight Measurement Gateway.
--
-- Measurement record layout:
--
--   Bits 111 downto 48 : Timestamp
--   Bits  47 downto 40 : Channel ID
--   Bits  39 downto 24 : Sample
--   Bits  23 downto 16 : Status
--   Bits  15 downto  0 : Sequence ID
--
-- Total width: 112 bits
-------------------------------------------------------------------------------

package measurement_pkg is

    ---------------------------------------------------------------------------
    -- Global data-width constants
    ---------------------------------------------------------------------------

    constant SAMPLE_WIDTH       : positive := 16;
    constant TIMESTAMP_WIDTH    : positive := 64;
    constant CHANNEL_WIDTH      : positive := 8;
    constant STATUS_WIDTH       : positive := 8;
    constant SEQUENCE_WIDTH     : positive := 16;

    constant MEASUREMENT_RECORD_WIDTH : positive :=
        TIMESTAMP_WIDTH +
        CHANNEL_WIDTH +
        SAMPLE_WIDTH +
        STATUS_WIDTH +
        SEQUENCE_WIDTH;

    ---------------------------------------------------------------------------
    -- Common subtypes
    ---------------------------------------------------------------------------

    subtype sample_t is
        signed(SAMPLE_WIDTH - 1 downto 0);

    subtype timestamp_t is
        unsigned(TIMESTAMP_WIDTH - 1 downto 0);

    subtype channel_id_t is
        unsigned(CHANNEL_WIDTH - 1 downto 0);

    subtype status_t is
        std_logic_vector(STATUS_WIDTH - 1 downto 0);

    subtype sequence_id_t is
        unsigned(SEQUENCE_WIDTH - 1 downto 0);

    subtype packed_measurement_record_t is
        std_logic_vector(MEASUREMENT_RECORD_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------------
    -- Measurement channel identifiers
    ---------------------------------------------------------------------------

    constant CHANNEL_INVALID : channel_id_t := x"00";
    constant CHANNEL_ADC     : channel_id_t := x"01";
    constant CHANNEL_UART    : channel_id_t := x"02";
    constant CHANNEL_PULSE   : channel_id_t := x"03";
    constant CHANNEL_DIGITAL : channel_id_t := x"04";
    constant CHANNEL_TEST    : channel_id_t := x"FF";

    ---------------------------------------------------------------------------
    -- Status-bit positions
    ---------------------------------------------------------------------------

    constant STATUS_VALID_BIT         : natural := 0;
    constant STATUS_SATURATION_BIT    : natural := 1;
    constant STATUS_FIFO_OVERFLOW_BIT : natural := 2;
    constant STATUS_SYNC_ERROR_BIT    : natural := 3;
    constant STATUS_DATA_ERROR_BIT    : natural := 4;

    ---------------------------------------------------------------------------
    -- Common status values
    ---------------------------------------------------------------------------

    constant STATUS_NONE : status_t := (others => '0');

    constant STATUS_VALID : status_t :=
        (
            STATUS_VALID_BIT => '1',
            others           => '0'
        );

    ---------------------------------------------------------------------------
    -- Structured measurement record
    ---------------------------------------------------------------------------

    type measurement_record_t is record
        timestamp   : timestamp_t;
        channel_id  : channel_id_t;
        sample      : sample_t;
        status      : status_t;
        sequence_id : sequence_id_t;
    end record;

    ---------------------------------------------------------------------------
    -- Default/empty measurement record
    ---------------------------------------------------------------------------

    constant MEASUREMENT_RECORD_RESET : measurement_record_t :=
        (
            timestamp   => (others => '0'),
            channel_id  => CHANNEL_INVALID,
            sample      => (others => '0'),
            status      => STATUS_NONE,
            sequence_id => (others => '0')
        );

    ---------------------------------------------------------------------------
    -- Packed-record bit locations
    ---------------------------------------------------------------------------

    constant SEQUENCE_LSB : natural := 0;
    constant SEQUENCE_MSB : natural :=
        SEQUENCE_LSB + SEQUENCE_WIDTH - 1;

    constant STATUS_LSB : natural :=
        SEQUENCE_MSB + 1;
    constant STATUS_MSB : natural :=
        STATUS_LSB + STATUS_WIDTH - 1;

    constant SAMPLE_LSB : natural :=
        STATUS_MSB + 1;
    constant SAMPLE_MSB : natural :=
        SAMPLE_LSB + SAMPLE_WIDTH - 1;

    constant CHANNEL_LSB : natural :=
        SAMPLE_MSB + 1;
    constant CHANNEL_MSB : natural :=
        CHANNEL_LSB + CHANNEL_WIDTH - 1;

    constant TIMESTAMP_LSB : natural :=
        CHANNEL_MSB + 1;
    constant TIMESTAMP_MSB : natural :=
        TIMESTAMP_LSB + TIMESTAMP_WIDTH - 1;

    ---------------------------------------------------------------------------
    -- Conversion functions
    ---------------------------------------------------------------------------

    function pack_record(
        measurement : measurement_record_t
    ) return packed_measurement_record_t;

    function unpack_record(
        packed_data : packed_measurement_record_t
    ) return measurement_record_t;

    ---------------------------------------------------------------------------
    -- Status helper functions
    ---------------------------------------------------------------------------

    function set_status_bit(
        current_status : status_t;
        bit_position   : natural;
        bit_value      : std_logic := '1'
    ) return status_t;

    function status_bit_is_set(
        current_status : status_t;
        bit_position   : natural
    ) return boolean;

end package measurement_pkg;


package body measurement_pkg is

    ---------------------------------------------------------------------------
    -- Function: pack_record
    --
    -- Converts the structured measurement record into a packed vector suitable
    -- for FIFO storage, bus transfer, file output, or testbench comparison.
    ---------------------------------------------------------------------------

    function pack_record(
        measurement : measurement_record_t
    ) return packed_measurement_record_t is

        variable packed_data : packed_measurement_record_t :=
            (others => '0');

    begin

        packed_data(TIMESTAMP_MSB downto TIMESTAMP_LSB) :=
            std_logic_vector(measurement.timestamp);

        packed_data(CHANNEL_MSB downto CHANNEL_LSB) :=
            std_logic_vector(measurement.channel_id);

        packed_data(SAMPLE_MSB downto SAMPLE_LSB) :=
            std_logic_vector(measurement.sample);

        packed_data(STATUS_MSB downto STATUS_LSB) :=
            measurement.status;

        packed_data(SEQUENCE_MSB downto SEQUENCE_LSB) :=
            std_logic_vector(measurement.sequence_id);

        return packed_data;

    end function pack_record;


    ---------------------------------------------------------------------------
    -- Function: unpack_record
    --
    -- Converts a packed measurement vector back into the structured record
    -- representation used internally by the RTL modules.
    ---------------------------------------------------------------------------

    function unpack_record(
        packed_data : packed_measurement_record_t
    ) return measurement_record_t is

        variable measurement : measurement_record_t :=
            MEASUREMENT_RECORD_RESET;

    begin

        measurement.timestamp :=
            unsigned(
                packed_data(TIMESTAMP_MSB downto TIMESTAMP_LSB)
            );

        measurement.channel_id :=
            unsigned(
                packed_data(CHANNEL_MSB downto CHANNEL_LSB)
            );

        measurement.sample :=
            signed(
                packed_data(SAMPLE_MSB downto SAMPLE_LSB)
            );

        measurement.status :=
            packed_data(STATUS_MSB downto STATUS_LSB);

        measurement.sequence_id :=
            unsigned(
                packed_data(SEQUENCE_MSB downto SEQUENCE_LSB)
            );

        return measurement;

    end function unpack_record;


    ---------------------------------------------------------------------------
    -- Function: set_status_bit
    --
    -- Returns an updated copy of the status vector without modifying the
    -- original input value.
    ---------------------------------------------------------------------------

    function set_status_bit(
        current_status : status_t;
        bit_position   : natural;
        bit_value      : std_logic := '1'
    ) return status_t is

        variable updated_status : status_t := current_status;

    begin

        assert bit_position < STATUS_WIDTH
            report "set_status_bit: bit_position is outside the status vector"
            severity failure;

        if bit_position < STATUS_WIDTH then
            updated_status(bit_position) := bit_value;
        end if;

        return updated_status;

    end function set_status_bit;


    ---------------------------------------------------------------------------
    -- Function: status_bit_is_set
    --
    -- Returns true when the selected status bit is asserted.
    ---------------------------------------------------------------------------

    function status_bit_is_set(
        current_status : status_t;
        bit_position   : natural
    ) return boolean is

    begin

        assert bit_position < STATUS_WIDTH
            report "status_bit_is_set: bit_position is outside the status vector"
            severity failure;

        if bit_position < STATUS_WIDTH then
            return current_status(bit_position) = '1';
        else
            return false;
        end if;

    end function status_bit_is_set;

end package body measurement_pkg;