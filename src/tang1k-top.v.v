module top 
   (
    mclk,
    rst_n,
    red,
    blue
    );
   //inputs
   input                     mclk;
   input                     rst_n;
   //outputs
   output                    red;
   output                    blue;

   wire [17:0] rom_data;
   wire [8:0] rom_addr;
   wire rom_enable;

   wire [7:0] outval;
   wire iow;
   reg redled;
   reg [27:0] bluecnt;

   wire clk;

//   Gowin_rPLL pll (
//        .clkout(clk), //output clkout
//        .clkin(mclk) //input clkin
//    );

  assign clk = mclk;

  isp8_core m8_1
      (
    .clk (clk),
    .rst_n (rst_n),
    .ext_mem_din ( 8'b0 ),
    .ext_mem_ready (1'b1),

    .ext_io_din ( 8'b0 ),
    .intr (1'b0),
    .ext_addr (),
    .ext_addr_cyc (),
    .ext_dout (outval),
    .ext_mem_wr (),
    .ext_mem_rd (),

    .ext_io_wr (iow),
    .ext_io_rd (),
    .intr_ack (),

    .ext_prom_addr (rom_addr),
    .ext_prom_instr (rom_data),
    .ext_prom_enable (rom_enable)
    );

    always @(posedge clk)
     begin
      if (~rst_n)
       redled <= 1'b1;
      else if (iow)
       redled <= outval[0];
     end
    assign red = redled;

    always @(posedge clk)
       bluecnt <= bluecnt + 'd1;

    assign blue = 1'b1; //bluecnt[27];

    Gowin_pROM rom (
        .dout(rom_data), //output [17:0] dout
        .clk(clk), //input clk
        .oce(1'b1), //input oce
        .ce(rom_enable), //input ce
        .reset(1'b0), //input reset
        .ad(rom_addr) //input [8:0] ad
    );
endmodule
