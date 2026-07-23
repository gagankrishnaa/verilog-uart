module uart_tx_test;
  reg clk, rst, start;
  reg [7:0] data_in;
  wire [2:0] count;
  wire tick, tx, busy, data_ready;
  wire [7:0] data_out;
  
  
  baud_gen bg (.clk(clk), .rst(rst), .tick(tick), .count(count));
  uart_tx uut (.clk(clk), .rst(rst), .tick(tick), .start(start), .data_in(data_in), .tx(tx), .busy(busy));
  uart_rx uuy (.clk(clk), .rst(rst), .tick(tick), .count(count), .rx(tx), .data_out(data_out), .data_ready(data_ready));
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst = 0;
    #2 rst = 1;
    #6 rst = 0;
  end
  
  initial begin
    start = 0;
    #12 start = 1;
    #46 start = 0;
  end
  
  initial begin
    #900 $finish;
  end
  
  initial begin
    data_in = 8'b10110010;
    $monitor ("$time=%0t clk=%b rst=%b tick=%b start=%b data_in=%b tx=%b busy=%b data_out=%b data_ready=%b count=%b", $time, clk,rst, tick, start, data_in, tx, busy, data_out, data_ready, count);
  end
endmodule
