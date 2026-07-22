# UART Transmitter in Verilog

An 8-bit UART transmitter built and verified from scratch in Verilog, including a configurable baud rate generator, a finite state machine controlling the transmission sequence, and a shift register for serializing data.

## What it does

Takes an 8-bit parallel byte and transmits it serially, one bit at a time, following the standard UART frame format:

Idle (1) -> Start bit (0) -> 8 data bits (LSB first) -> Stop bit (1) -> Idle

## Modules

- **baud_gen** - generates a periodic `tick` pulse by dividing down the system clock, used to time each bit period
- **uart_tx** - the transmitter itself: an FSM (IDLE -> START -> DATA -> STOP) combined with an 8-bit shift register and a bit counter, all gated by the baud tick

## How it works

1. On `start`, the FSM loads the input byte into an internal shift register
2. It emits a start bit (0) for one bit period
3. It shifts out all 8 data bits, least-significant bit first, one per baud tick
4. It emits a stop bit (1), then returns to idle, ready for the next byte

## Verification

`testbench.sv` instantiates both modules together, generates a clock and reset, pulses `start` with a sample byte, and monitors `tx`, `state`, `bit_count`, and `shift_register` over time. The transmitted bit sequence was traced and verified by hand against the simulation output to confirm correct LSB-first framing.

## Tools used

Written and simulated in Icarus Verilog via EDA Playground.

## Author

Gagan Krishna S
