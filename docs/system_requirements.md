# System Requirements Specification

## 1. Purpose

This document defines the initial requirements for the FPGA Flight Measurement Gateway.

The system shall acquire heterogeneous measurement signals, assign deterministic timestamps, perform fixed-point signal processing, buffer the resulting measurement records, and make them available to embedded software through a processor-accessible interface.

The requirements are intentionally defined before RTL implementation so that the design and verification environment can be traced to explicit system behaviour.

---

## 2. System Scope

The complete system will contain:

* FPGA-based measurement acquisition interfaces
* deterministic timestamp generation
* channel identification and measurement framing
* fixed-point DSP processing
* measurement buffering
* control and status registers
* processor–FPGA communication
* embedded C firmware
* host-side telemetry and visualization
* simulation, synthesis, timing analysis, and hardware validation

---

## 3. Functional Requirements

### 3.1 Measurement Acquisition

**SYS-ACQ-001**
The system shall accept signed sample-based measurements with a minimum data width of 16 bits.

**SYS-ACQ-002**
The system shall support a valid indication for each incoming sample.

**SYS-ACQ-003**
The system shall assign a unique channel identifier to each measurement source.

**SYS-ACQ-004**
The system shall support acquisition from at least one sample-stream source.

**SYS-ACQ-005**
The final system shall support at least three different measurement-source types.

Planned source types are:

* sample-stream or ADC-style input
* pulse-frequency input
* UART-based measurement input
* synchronized discrete digital input

**SYS-ACQ-006**
The acquisition logic shall detect and report malformed or incomplete input transactions where applicable.

---

### 3.2 Timestamping

**SYS-TIM-001**
The system shall contain a free-running timestamp counter.

**SYS-TIM-002**
The timestamp width shall be 64 bits.

**SYS-TIM-003**
Every accepted measurement shall be associated with the timestamp corresponding to its acceptance event.

**SYS-TIM-004**
The timestamp counter shall reset to zero following a system reset.

**SYS-TIM-005**
The timestamp counter shall increment once per configured timestamp clock interval.

**SYS-TIM-006**
The timestamp unit shall support an external synchronization event in a later implementation phase.

**SYS-TIM-007**
The system shall detect the absence of an expected synchronization event when synchronization monitoring is enabled.

---

### 3.3 Measurement Records

**SYS-REC-001**
Every processed measurement shall be stored as a structured measurement record.

**SYS-REC-002**
A measurement record shall contain at least:

* timestamp
* channel identifier
* measurement value
* status flags
* sequence identifier

**SYS-REC-003**
The sequence identifier shall increment for each accepted measurement record.

**SYS-REC-004**
The system shall provide a status indication when a measurement value is invalid, saturated, or associated with an acquisition error.

---

### 3.4 Digital Signal Processing

**SYS-DSP-001**
The system shall support signed fixed-point DSP processing.

**SYS-DSP-002**
The first implemented DSP block shall be a finite impulse response low-pass filter.

**SYS-DSP-003**
The FIR filter shall support a minimum of 16 coefficients.

**SYS-DSP-004**
The filter coefficients shall use signed fixed-point representation.

**SYS-DSP-005**
The DSP implementation shall define its input, coefficient, accumulator, and output widths explicitly.

**SYS-DSP-006**
The system shall prevent uncontrolled arithmetic wraparound at its external DSP output.

**SYS-DSP-007**
The DSP block shall provide a valid indication aligned with each valid output sample.

**SYS-DSP-008**
The completed design shall support configurable decimation.

**SYS-DSP-009**
The completed design shall support threshold or saturation monitoring.

**SYS-DSP-010**
The fixed-point FPGA output shall be compared against a MATLAB or Octave reference model.

---

### 3.5 Measurement Buffering

**SYS-BUF-001**
Processed measurement records shall be stored in a FIFO.

**SYS-BUF-002**
The FIFO shall provide empty and full indications.

**SYS-BUF-003**
The FIFO shall provide a readable fill-level indication.

**SYS-BUF-004**
The system shall detect attempted writes when the FIFO is full.

**SYS-BUF-005**
FIFO overflow events shall set a diagnostic status flag.

**SYS-BUF-006**
FIFO overflow events shall increment an error counter.

**SYS-BUF-007**
The FIFO shall preserve measurement-record ordering.

---

### 3.6 Processor Interface

**SYS-BUS-001**
The FPGA measurement subsystem shall be accessible through an Avalon Memory-Mapped slave interface.

**SYS-BUS-002**
The processor interface shall provide control registers.

**SYS-BUS-003**
The processor interface shall provide status registers.

**SYS-BUS-004**
The processor interface shall expose FIFO data and FIFO status.

**SYS-BUS-005**
The processor interface shall expose diagnostic flags and counters.

**SYS-BUS-006**
The processor interface shall support runtime configuration of selected DSP parameters.

**SYS-BUS-007**
Read-only and read/write registers shall be explicitly identified in the register-map documentation.

**SYS-BUS-008**
Registers shall have deterministic reset values.

---

### 3.7 Embedded Firmware

**SYS-SW-001**
The embedded software shall be written in C.

**SYS-SW-002**
The software shall initialize the FPGA measurement subsystem.

**SYS-SW-003**
The software shall configure operating parameters through the Avalon-MM interface.

**SYS-SW-004**
The software shall read measurement records from the FPGA.

**SYS-SW-005**
The software shall detect and report FPGA diagnostic flags.

**SYS-SW-006**
The software shall avoid dynamic memory allocation in the primary measurement path.

**SYS-SW-007**
Memory-mapped hardware registers shall be accessed using volatile-qualified objects or equivalent vendor-supported access functions.

**SYS-SW-008**
The software shall provide a UART-based diagnostic or command interface.

---

### 3.8 Diagnostics

**SYS-DIAG-001**
The system shall contain sticky diagnostic flags for detected errors.

**SYS-DIAG-002**
Diagnostic flags shall remain asserted until explicitly cleared or until system reset.

**SYS-DIAG-003**
The system shall include a diagnostic indication for FIFO overflow.

**SYS-DIAG-004**
The completed system shall include diagnostic indications for applicable interface errors.

Planned interface errors include:

* UART framing error
* SPI timeout
* invalid register access
* synchronization loss
* DSP saturation

**SYS-DIAG-005**
Each implemented diagnostic function shall have at least one corresponding verification test.

---

## 4. Performance Requirements

**SYS-PERF-001**
The initial FPGA clock target shall be 50 MHz or greater.

**SYS-PERF-002**
The final clock target shall be selected based on the available Intel/Altera FPGA board.

**SYS-PERF-003**
The timestamp counter shall operate without reducing the accepted measurement throughput.

**SYS-PERF-004**
The pipelined DSP implementation shall target an initiation interval of one clock cycle.

**SYS-PERF-005**
All implemented clock domains shall meet timing in Intel Quartus Prime.

**SYS-PERF-006**
The repository shall include selected timing-analysis evidence for the final hardware build.

---

## 5. Verification Requirements

**SYS-VER-001**
Every major synthesizable VHDL module shall have a corresponding testbench.

**SYS-VER-002**
Testbenches shall be self-checking where practical.

**SYS-VER-003**
Verification failures shall generate VHDL assertions with meaningful messages.

**SYS-VER-004**
The timestamp unit shall be verified for:

* reset behaviour
* increment behaviour
* rollover behaviour
* timestamp capture

**SYS-VER-005**
The FIFO shall be verified for:

* empty state
* full state
* ordered data transfer
* overflow attempts
* simultaneous read and write behaviour

**SYS-VER-006**
The FIR filter shall be verified using externally generated reference vectors.

**SYS-VER-007**
The complete measurement path shall be verified using nominal and fault-injection scenarios.

**SYS-VER-008**
The repository shall maintain a requirement-to-test traceability matrix.

---

## 6. Hardware Validation Requirements

**SYS-HW-001**
The design shall be synthesized for an Intel/Altera FPGA development board.

**SYS-HW-002**
At least one measurement path shall be demonstrated on physical FPGA hardware.

**SYS-HW-003**
At least one communication interface shall be observed using a logic analyser or oscilloscope.

**SYS-HW-004**
Hardware-test evidence shall include the test setup, expected result, observed result, and conclusion.

**SYS-HW-005**
The final hardware target and FPGA device shall be documented after board identification.

---

## 7. Documentation Requirements

**SYS-DOC-001**
The system architecture shall be documented before subsystem integration.

**SYS-DOC-002**
Every hardware register shall be documented.

**SYS-DOC-003**
Fixed-point number formats shall be documented.

**SYS-DOC-004**
Clock and reset behaviour shall be documented.

**SYS-DOC-005**
Timing-analysis results shall be summarized.

**SYS-DOC-006**
Known limitations shall be stated explicitly.

**SYS-DOC-007**
Features that are planned but not implemented shall not be presented as completed functionality.

---

## 8. Initial Development Milestones

| Milestone | Description                                            |
| --------- | ------------------------------------------------------ |
| M1        | Repository structure, requirements, and architecture   |
| M2        | Common VHDL package and measurement-record definition  |
| M3        | Timestamp counter implementation and verification      |
| M4        | Measurement FIFO implementation and verification       |
| M5        | Fixed-point FIR implementation and MATLAB verification |
| M6        | Avalon-MM register interface                           |
| M7        | Nios II firmware integration                           |
| M8        | Complete-system simulation                             |
| M9        | Quartus synthesis and timing closure                   |
| M10       | Hardware demonstration and final documentation         |

---

## 9. Requirement Status

At this stage, all listed requirements have the status:

**Defined — implementation not yet started**

Requirement status will be updated as the corresponding design, verification, and hardware evidence are committed.
