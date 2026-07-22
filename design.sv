module baud_gen (
  input clk,
  input rst,
  output reg tick,
  output reg [2:0] count
);
  
  always @(posedge clk or posedge rst)begin
    if (rst) begin
      count <= 0;
      tick <= 0;
    end else if (count == 3) begin
      count <= 0;
      tick <= 1;
    end else begin
      count <= count+1;
      tick <= 0;
    end
  end
endmodule



module uart_tx (
  input clk,
  input rst,
  input tick,
  input start,
  input [7:0] data_in,
  output reg tx,
  output reg busy
);
  parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state;
  reg [2:0] bit_count;
  reg [7:0] shift_register;
  
  always @(posedge clk or posedge rst)begin
    if (rst) begin
      state <= IDLE;
      tx <= 1;
      busy <= 0;
    end else if (tick) begin
      case (state)
        IDLE: begin
          if (start) begin
            shift_register <= data_in;
            state <= START;
            busy <= 1;
          end
        end
          
        START: begin
          tx <= 0;
          bit_count <= 0;
          state <= DATA;
        end
          
        DATA: begin
          tx <= shift_register[0];
          shift_register <= shift_register >> 1;
          if (bit_count == 7)
            state <= STOP;
          else
            bit_count <= bit_count + 1;
        end
          
        STOP: begin
          tx <= 1;
          busy <= 0;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
