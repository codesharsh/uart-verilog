# UART Transmitter/Receiver in Verilog

A UART (Universal Asynchronous Receiver/Transmitter) implementation in Verilog, 
built to move beyond HDLBits and practice real hardware design: baud rate 
generation, FSM design, and modular datapath architecture.

## Status
✅ Core design complete — TX and RX built, loopback simulation run

- [x] `baud_gen` — configurable baud rate tick generator
- [x] `Tx_fsm` — transmitter control FSM
- [x] `piso` — parallel-in-serial-out shift register (TX datapath)
- [x] `parity_gen` — parity bit calculator
- [x] `mux` — TX output selector
- [x] `uart_tx` — top-level transmitter (wires above modules together)
- [x] `RX_fsm` — receiver control FSM
- [x] `detect_start` — start bit edge detector
- [x] `sipo` — serial-in-parallel-out shift register (RX datapath)
- [x] `parity_check` — parity error detection
- [x] `stop_bit_check` — stop bit error detection
- [x] `uart_rx` — top-level receiver
- [x] Loopback testbench (TX → RX)

> Note: loopback results need re-verification — waveform review flagged a 
> possible mismatch between sent and received data that wasn't fully 
> root-caused. Revisit before treating this as fully verified.

## Architecture

Each UART frame: `[Start bit (0)] [8 data bits, LSB first] [Parity bit] [Stop bit (1)]`

The design uses a `baud_gen` module to divide a system clock down to a `tick` 
signal pulsing once per bit period. TX and RX FSMs use this tick to time their 
state transitions, rather than being clocked directly at the baud rate.

### TX structure
- `Tx_fsm`: controller — decides state, drives `select`/`shift`/`load_data`/`tx_busy`
- `piso`: shift register holding the byte being sent
- `parity_gen`: computes parity bit from input byte (combinational)
- `mux`: selects start bit / data bit / parity bit / stop bit onto the output line

### RX structure
- `RX_fsm`: controller — includes a dedicated START state to wait out the full
  start-bit period before sampling data (avoids off-by-one-bit corruption)
- `detect_start`: edge detector, pulses `start_bit` on falling edge of `RX_in`
- `sipo`: shift register assembling the incoming byte
- `parity_check`: recomputes expected parity from received byte, compares to
  received parity bit
- `stop_bit_check`: verifies stop bit is HIGH, flags error if not

### Known simplifications (vs. production UART)
- No 16x oversampling on RX — RX shares the same 1x `tick` as TX, which only
  works correctly when TX and RX clocks are phase-aligned (true in this
  simulation/loopback setup, not true for physically separate devices)
- Parity errors are flagged but don't interrupt the frame — RX always
  completes START→DATA→PARITY→STOP→IDLE regardless of error status

## Tools
- Icarus Verilog (simulation)
- GTKWave (waveform viewing)

## Simulating
```bash
iverilog -o sim baud_gen.v Tx_fsm.v piso.v parity_gen.v mux.v uart_tx.v \
  RX_fsm.v detect_start.v sipo.v parity_check.v stop_bit_check.v uart_rx.v \
  uart_tb.v
vvp sim
gtkwave uart.vcd
```

## Next steps
- Re-verify loopback correctness bit-by-bit against a known test byte
- Add proper self-checking (`$display` PASS/FAIL) to the testbench
- Consider adding 16x oversampling on RX for robustness to clock drift
