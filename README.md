Verilog UART (Transmitter + Receiver)

A from-scratch UART transmitter and receiver written in Verilog, verified in Icarus Verilog 12.0 on EDA Playground. No external IP, no generated cores — every state machine, shift register, and timing decision here was designed, simulated, and debugged by hand.

Why this project

Most tutorial UART designs stop at "transmitter works, done." I wanted the harder half too: a receiver that has to recover a bitstream with no shared clock reference beyond an over-sampled tick, and get every sampling instant right without asking the transmitter for help. Building the receiver surfaced a real timing bug (see below) that a copy-pasted design would never have taught me.

Architecture

Three modules, no shared state beyond wires:

Module	Role
baud_gen	Free-running counter (count, 0–3) that pulses tick once every 4 clock cycles — the shared timing reference for both tx and rx.
uart_tx	4-state FSM (IDLE → START → DATA → STOP) that serializes an 8-bit byte onto tx, LSB-first, framed with a start bit (0) and stop bit (1).
uart_rx	4-state FSM (IDLE → START → DATA → STOP) that recovers an 8-bit byte from rx, sampling at the mid-bit point of each baud period to avoid edge noise.
 IDLE  --rx==0-->  START  --start bit verified + tick-->  DATA  --8 bits sampled-->  STOP  --stop bit verified-->  IDLE
Ports

baud_gen

Port	Dir	Width	Description
clk	in	1	System clock
rst	in	1	Synchronous reset
tick	out	1	Pulses high once per baud period
count	out	3	Free-running 0–3 counter within a baud period

uart_tx

Port	Dir	Width	Description
clk, rst, tick	in	—	Shared with baud_gen
start	in	1	Pulse high to begin transmission
data_in	in	8	Byte to transmit
tx	out	1	Serial output line (idle-high)
busy	out	1	High while a transmission is in flight

uart_rx

Port	Dir	Width	Description
clk, rst, tick	in	—	Shared with baud_gen
count	in	3	Shared baud-period counter (not owned by rx — it only reads it)
rx	in	1	Serial input line
data_out	out	8	Recovered byte, valid when data_ready pulses
data_ready	out	1	Pulses high for one clock when a byte has been fully received
Frame format
idle(1) → start(0) → D0 D1 D2 D3 D4 D5 D6 D7 (LSB first) → stop(1) → idle(1)

Both tx and rx sample/drive bits at count == 2 — the midpoint of each 4-cycle baud period — rather than on the tick edge itself, to stay clear of line noise and clock-domain drift right at bit boundaries.

Verification

Tested in a combined testbench with uart_rx.rx wired directly to uart_tx.tx, so every run is a full send → receive pipeline test, not two modules verified in isolation. Confirmed against three data patterns chosen to hit different edge cases:

data_in	Why this pattern	Result
10110010	Mixed bits — general case	✅ data_out == data_in, data_ready pulses for exactly 1 cycle
11111111	Line only toggles low for the start bit; everything else idle-high — stresses whether the receiver can tell "still receiving" from "back to idle"	✅ pass
00000000	Line stays low through the entire byte — stresses whether IDLE's start-bit detection could incorrectly re-fire mid-byte	✅ pass

Each run's $monitor trace was checked cycle-by-cycle: state transitions, bit_count incrementing exactly once per tick, and data_ready pulsing for precisely one clock cycle on completion.

Debugging notes: the off-by-one bit-shift bug

The most interesting bug in this project wasn't a typo — it was a genuine timing-design mistake, and it's worth writing up because the fix generalizes to any two FSMs coordinating over a shared counter.

Symptom: with data_in = 8'b10110010, the receiver produced data_out = 0110010x — every bit landed one position too high, and bit 0 was never written at all.

Root cause: in the original START state, the moment the start bit was verified (count == 2), the FSM transitioned straight to DATA on that same clock edge:

verilog
START: begin
  if (count == 2) begin
    if (rx == 0)
      state <= DATA;   // BUG: jumps immediately, mid-baud-period
  end
end

The problem: count is a shared, free-running counter owned by baud_gen — it doesn't reset just because uart_rx changed state. So DATA became active with count already partway through its 0→3 cycle, not freshly at 0. That meant DATA's own if (count == 2) check fired against a stale count value left over from the tail end of the start bit's window — the FSM advanced bit_count once without rx_shift[0] ever getting sampled, and everything after that landed one slot too high.

Fix: introduce a start_ok register that decouples "start bit verified" from "transition to DATA." Verification happens at count == 2 as before, but the actual state change is deferred to the next tick — a clean baud-period boundary — guaranteeing DATA always begins with count starting fresh from 0:

verilog
START: begin
  if (count == 2) begin
    if (rx == 0)
      start_ok <= 1;
    else begin
      state <= IDLE;
      start_ok <= 0;
    end
  end else if (tick) begin
    if (start_ok) begin
      state <= DATA;
      start_ok <= 0;
    end
  end
end

After this fix, data_out matched data_in exactly across all three test patterns.

Other bugs fixed along the way
#	Bug	Fix
1	rx <= 1; inside reset — attempted write to an input port	Removed
2	STOP checked if (rx == 0) — wrong stop-bit polarity	Changed to rx == 1
3	STOP sampled at count == 0 instead of count == 2	Fixed sampling point
4	data_output vs data_out naming mismatch between design and testbench	Fixed
5	count declared reg in testbench instead of wire (it's driven by baud_gen)	Changed to wire
6	baud_gen instantiation missing .count(count) connection	Added
7	uart_rx instantiated with .tx(tx) instead of .rx(tx), missing leading dots on ports	Fixed
8	parameter IDLE = ...; START = ...; — semicolons used instead of commas, breaking the whole file's parse	Changed to commas
9	data_ready <= 0 missing semicolon — same cascading parse failure	Added semicolon
10	DATA checked if (count == 7) instead of if (bit_count == 7) — count only ever reaches 3, so this never fired and the receiver hung in DATA forever	Fixed variable reference
11	bit_count never reset to 0 — started as x (unknown), so bit_count == 7 was never true	Added bit_count <= 0; to reset block
Files
design.sv — baud_gen, uart_tx, uart_rx modules
testbench.sv — combined tx→rx pipeline testbench with $monitor trace
Next steps
SystemVerilog/UVM verification testbench (constrained-random data, coverage)
Synthesis (Yosys) + static timing analysis (OpenSTA)
