module uart_tx_test;
  reg clk, rst, start;
  reg [7:0] data_in;
  wire tick, tx, busy;
  
  baud_gen bg (.clk(clk), .rst(rst), .tick(tick));
  uart_tx uut (.clk(clk), .rst(rst), .tick(tick), .start(start), .data_in(data_in), .tx(tx), .busy(busy));
  
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
    #500;
    $finish;
  end
  
  initial begin
    data_in = 8'b10110010;
    $monitor ("$time=%0t clk=%b rst=%b tick=%b start=%b data_in=%b tx=%b busy=%b", $time, clk,rst, tick, start, data_in, tx, busy);
  end
endmodule
