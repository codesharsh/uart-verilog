# uart-verilog
Each UART frame: `[Start bit (0)] [8 data bits, LSB first] [Parity bit] [Stop bit (1)]`

The design uses a `baud_gen` module to divide a system clock down to a `tick` 
signal pulsing once per bit period. TX and RX FSMs use this tick to time their 
state transitions, rather than being clocked directly at the baud rate.

### TX structure
- `Tx_fsm`: controller — decides state, drives `select`/`shift`/`load_data`/`tx_busy`
- `piso`: shift register holding the byte being sent
- `parity_gen`: computes parity bit from input byte (combinational)
- `mux`: selects start bit / data bit / parity bit / stop bit onto the output line
