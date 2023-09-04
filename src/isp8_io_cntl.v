//----------------------------------------------------------------------------
// 
//  Name:   isp8_io_cntl.v
// 
//  Description:  Input/Output control logic
// 
//  $Revision: 1.0 $
//  
//----------------------------------------------------------------------------
// Permission:
//
//   Lattice Semiconductor grants permission to use this code for use
//   in synthesis for any Lattice programmable logic product.  Other
//   use of this code, including the selling or duplication of any
//   portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Lattice Semiconductor provides no warranty
//   regarding the use or functionality of this code.
//----------------------------------------------------------------------------
//
//    Lattice Semiconductor Corporation
//    5555 NE Moore Court
//    Hillsboro, OR 97124
//    U.S.A
//
//    TEL: 1-800-Lattice (USA and Canada)
//    408-826-6000 (other locations)
//
//    web: http://www.latticesemi.com/
//    email: techsupport@latticesemi.com
//--------------------------------------------------------

module  isp8_io_cntl #(
              parameter PORT_AW=8
                       )
                      (
                       clk         ,
                       rst_n       ,
                       import      ,
                       importi     ,
                       export      ,
                       exporti     ,
                       ssp         ,
                       sspi        ,
                       lsp         ,
                       lspi        ,
                       addr_cyc    ,
                       ext_addr_cyc,
                       addr_rb     ,
                       dout_rd     ,
                       dout_rb     ,
                       ext_addr    ,
                       ext_dout    ,
                       ext_mem_wr  ,
                       ext_mem_rd  ,
                       ext_io_wr   ,
                       ext_io_rd   
                       );
    //inputs 
     input           clk          ;                    
     input           rst_n        ;
     input           import       ;
     input           importi      ;
     input           export       ;
     input           exporti      ;
     input           ssp          ;
     input           sspi         ;
     input           lsp          ;
     input           lspi         ;
     input           addr_cyc     ;
     input           ext_addr_cyc ;
            
     input  [4:0]            addr_rb    ;
     input  [7:0]            dout_rd    ;
     input  [7:0]            dout_rb    ;
     //outputs 
     output  [PORT_AW - 1:0]  ext_addr   ;
     output  [7:0]            ext_dout   ;
     output                   ext_mem_wr ;
     output                   ext_mem_rd ;
     output                   ext_io_wr  ;
     output                   ext_io_rd  ;
  //-------------------------------------

      reg  [PORT_AW - 1:0]  ext_addr     ;   
      reg  [7:0]            ext_dout     ;
      reg                   ext_mem_wr   ;
      reg                   ext_mem_rd   ;
      reg                   ext_io_wr    ;
      reg                   ext_io_rd    ;
      
always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) begin  
           ext_dout  <= 0;
           ext_io_wr <= 0;
           ext_io_rd <= 0;
end
else begin
           ext_dout  <= dout_rd;
           ext_io_wr <= (export | exporti) & (addr_cyc || ext_addr_cyc);
           ext_io_rd <= (import | importi) & (addr_cyc || ext_addr_cyc); 
end
end


always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) 
  ext_addr <= 0;
else if ((export ) | (import ) || (lsp ) || (ssp )) 
  ext_addr <= {3'b000,addr_rb};
else
  ext_addr <= dout_rb[PORT_AW - 1: 0];
end


always @(posedge clk or negedge rst_n) 
begin
if (!rst_n) begin  
    ext_mem_wr  <= 0;
    ext_mem_rd  <= 0;
end
else begin
    ext_mem_wr  <= (sspi || ssp) & (addr_cyc || ext_addr_cyc);
    ext_mem_rd  <= (lspi || lsp) & (addr_cyc || ext_addr_cyc);
end
end


endmodule        
      
       
    