//----------------------------------------------------------------------------
//
//  Name:   isp8_core.v
//
//  Description:  Top level for Mico8 core
//
//  $Revision: 1.3 $
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
//
//----------------------------------------------------------------------------

module isp8_core #(
                   parameter PORT_AW      = 8,
                   parameter EXT_AW       = 8,
                   parameter PROM_AW      = 9,
                   parameter PROM_AD      = 512,
                   parameter REGISTERS_16 = 1,
                   parameter PGM_STACK_AW = 4,
                   parameter PGM_STACK_AD = 16)
   (
    clk,
    rst_n,
    ext_mem_din,
    ext_mem_ready,

    ext_io_din,
    intr,
    ext_addr,
    ext_addr_cyc,
    ext_dout,
    ext_mem_wr,
    ext_mem_rd,

    ext_io_wr,
    ext_io_rd,
    intr_ack,

    ext_prom_addr,
    ext_prom_instr,
    ext_prom_enable
    );
   //inputs
   input                     clk;
   input                     rst_n;
   input [7:0]               ext_mem_din;
   input                     ext_mem_ready;
   input [7:0]               ext_io_din;
   input                     intr;
   input [17:0]              ext_prom_instr;
   //outputs
   output [EXT_AW - 1:0]     ext_addr;
   output                    ext_addr_cyc;
   output [7:0]              ext_dout;
   output                    ext_mem_wr;
   output                    ext_mem_rd;
   output                    ext_io_wr;
   output                    ext_io_rd;
   output                    intr_ack;
   output [PROM_AW-1:0]      ext_prom_addr;
   output                    ext_prom_enable;

   parameter                 REG13 = 5'b01101;
   parameter                 REG14 = 5'b01110;
   parameter                 REG15 = 5'b01111;


   wire                      hi_val, lo_val;
   wire [17:0]               instr;
   wire                      imi_instr, sub, subc, add, addc, mov;
   wire                      andr, orr, xorr, cmp, test, ror1, rorc;
   wire                      rol1, rolc, clrc, setc, clrz, setz;
   wire                      clri, seti, bz, bnz, bc, bnc, b;
   wire                      callz, callnz, callc, callnc, call;
   wire                      ret, iret, export, import, exporti, importi;
   wire                      ssp, lsp, sspi, lspi;
   wire [4:0]                addr_rb;
   wire [4:0]                addr_rd;
   wire [7:0]                imi_data;
   wire [PROM_AW - 1:0]      addr_jmp;
   wire                      update_c,update_z;
   wire [7:0]                dout_rd;
   wire [7:0]                dout_rb;
   wire                      carry_flag;
   wire [7:0]                dout_alu;
   wire                      cout_alu;
   wire                      addr_cyc;
   wire                      ext_addr_cyc_int;
   wire                      data_cyc;
   wire [PROM_AW - 1:0]      prom_addr;
   wire                      prom_enable;
   wire                      wren_rd;

   reg                       wren_alu_rd;
   reg                       wren_il_rd;
   reg [7:0]                 din_rd, din_rd1;
   wire [7:0]                din_rd_int;

   reg                       rst_n_reg;
   reg [7:0]                 page_ptr1;
   reg [7:0]                 page_ptr2;
   reg [7:0] 		     page_ptr3;
   wire [PORT_AW- 1 :0]      local_ext_addr;

   assign                    hi_val = 1'b1;
   assign                    lo_val = 1'b0;
   assign                    din_rd_int = din_rd;
   
   always @(posedge clk or negedge rst_n)
     begin
        if (~rst_n)
          rst_n_reg <= 1'b0; //#1 1'b0;
        else
          rst_n_reg <= rst_n; //#1 rst_n;
     end // always @ (posedge clk or negedge rst_n)
   
   generate
      if (EXT_AW <= 8)
         assign ext_addr = local_ext_addr;
      else if ((EXT_AW > 8) && (EXT_AW < 16))
         assign ext_addr = {page_ptr1[(EXT_AW % 8)-1 : 0], local_ext_addr};
      else if (EXT_AW == 16)
         assign ext_addr = {page_ptr1, local_ext_addr};
      else if ((EXT_AW > 16) && (EXT_AW < 24 ))
         assign ext_addr = {page_ptr2[(EXT_AW % 8)-1 : 0], page_ptr1,
                            local_ext_addr};
      else if (EXT_AW == 24)
	assign ext_addr = {page_ptr2, page_ptr1, local_ext_addr};
      else if ((EXT_AW > 24) && (EXT_AW < 32))
	assign ext_addr = {page_ptr3[(EXT_AW % 8)-1 : 0], page_ptr2,
			   page_ptr1, local_ext_addr};
      else
	assign ext_addr = {page_ptr3, page_ptr2, page_ptr1, local_ext_addr};
   endgenerate

   // Instantiate Instruction Decoder.
   isp8_idec  #(
                PROM_AW
                ) u1_isp8_idec
      (
       .instr     (instr),
       .imi_instr (imi_instr),
       .sub       (sub),
       .subc      (subc),
       .add       (add),
       .addc      (addc),
       .mov       (mov),
       .andr      (andr),
       .orr       (orr),
       .xorr      (xorr),
       .cmp       (cmp),
       .test      (test),
       .ror1      (ror1),
       .rorc      (rorc),
       .rol1      (rol1),
       .rolc      (rolc),
       .clrc      (clrc),
       .setc      (setc),
       .clrz      (clrz),
       .setz      (setz),
       .clri      (clri),
       .seti      (seti),
       .bz        (bz),
       .bnz       (bnz),
       .bc        (bc),
       .bnc       (bnc),
       .b         (b),
       .callz     (callz),
       .callnz    (callnz),
       .callc     (callc),
       .callnc    (callnc),
       .call      (call),
       .ret       (ret),
       .iret      (iret),
       .export    (export),
       .import    (import),
       .exporti   (exporti),
       .importi   (importi),
       .ssp       (ssp),
       .lsp       (lsp),
       .sspi      (sspi),
       .lspi      (lspi),
       .addr_rb   (addr_rb),
       .addr_rd   (addr_rd),
       .imi_data  (imi_data),
       .addr_jmp  (addr_jmp),
       .update_c  (update_c),
       .update_z  (update_z)
       );

   //Instantiate Arithmetic/logic unit.
   isp8_alu u1_isp8_alu
      (
       .instr      (instr),
       .dout_rd    (dout_rd),
       .dout_rb    (dout_rb),
       .imi_data   (imi_data),
       .imi_instr  (imi_instr),
       .carry_flag (carry_flag),
       .sub        (sub),
       .subc       (subc),
       .addc       (addc),
       .cmp        (cmp),
       .dout_alu   (dout_alu),
       .cout_alu   (cout_alu)
       );


   //Instantiate flags/instruction read controller
   isp8_flow_cntl #(
                    PGM_STACK_AW,
                    PGM_STACK_AD,
                    PROM_AW
                    ) u1_isp8_flow_cntl
      (
       .clk          ( clk),
       .rst_n        ( rst_n_reg),
       .setc         ( setc),
       .clrc         ( clrc),
       .setz         ( setz),
       .clrz         ( clrz),
       .seti         ( seti),
       .clri         ( clri),
       .addr_jmp     ( addr_jmp),
       .update_c     ( update_c),
       .update_z     ( update_z),
       .cout_alu     ( cout_alu),
       .dout_alu     ( dout_alu),
       .bz           ( bz),
       .bnz          ( bnz),
       .bc           ( bc),
       .bnc          ( bnc),
       .b            ( b),
       .callz        ( callz),
       .callnz       ( callnz),
       .callc        ( callc),
       .callnc       ( callnc),
       .call         ( call),
       .ret          ( ret),
       .iret         ( iret),
       .intr         ( intr),
       .lsp          ( lsp),
       .lspi         ( lspi),
       .ssp          ( ssp),
       .sspi         ( sspi),
       .import       ( import),
       .importi      ( importi),
       .export       ( export),
       .exporti      ( exporti),
       .ready        ( ext_mem_ready),
       .addr_cyc     ( addr_cyc),
       .ext_addr_cyc ( ext_addr_cyc_int),
       .data_cyc     ( data_cyc),
       .prom_addr    ( prom_addr),
       .prom_enable  ( prom_enable),
       .carry_flag   ( carry_flag),
       .intr_ack     ( intr_ack)
       );
   assign    ext_addr_cyc = ext_addr_cyc_int;

   //Instantiate IO controller.
   isp8_io_cntl #(
                  PORT_AW
                  ) u1_isp8_io_cntl
      (
       . clk          ( clk),
       . rst_n        ( rst_n_reg),
       . import       ( import),
       . importi      ( importi),
       . export       ( export),
       . exporti      ( exporti),
       . ssp          ( ssp),
       . sspi         ( sspi),
       . lsp          ( lsp),
       . lspi         ( lspi),
       . addr_cyc     ( addr_cyc),
       . addr_rb      ( addr_rb),
       . dout_rd      ( dout_rd),
       . dout_rb      ( dout_rb),
       . ext_addr     ( local_ext_addr),
       . ext_dout     ( ext_dout),
       . ext_mem_wr   ( ext_mem_wr),
       . ext_mem_rd   ( ext_mem_rd),
       . ext_addr_cyc ( ext_addr_cyc_int),
       . ext_io_wr    ( ext_io_wr),
       . ext_io_rd    ( ext_io_rd)
       );
//   pmi_rom #(
//             PROM_AD,
//             PROM_AW,
//             18,
//             "noreg",
//             "disable",
//             "async",
//             PROM_FILE,
//             "hex",
//             FAMILY_NAME,
//             "pmi_rom"
//             ) u1_isp8_prom
//      (
//       .Address    (prom_addr[PROM_AW - 1:0]),
//       .OutClock   (clk),
//       .OutClockEn (prom_enable),
//       .Reset      (lo_val),
//       .Q          (instr)
//       );

   assign instr = ext_prom_instr;
   assign ext_prom_addr = prom_addr;
   assign ext_prom_enable = prom_enable;
   
   generate if ((EXT_AW > 8) && (EXT_AW <= 32))
     always@(posedge clk or negedge rst_n_reg)
       begin
          if (!rst_n_reg)
            page_ptr1 <= 0;
          else if ((addr_rd == REG13) && (wren_rd == 1'b1))
           page_ptr1 <= din_rd;
          else
            page_ptr1 <= page_ptr1;
       end
   endgenerate
   
   generate if ((EXT_AW > 8) && (EXT_AW <= 32))
     always@(posedge clk or negedge rst_n_reg)
       begin
          if (!rst_n_reg)
            page_ptr2 <= 0;
          else if ((addr_rd == REG14) && (wren_rd == 1'b1))
            page_ptr2 <= din_rd;
          else
            page_ptr2 <= page_ptr2;
       end
   endgenerate
   
   generate if ((EXT_AW > 8) && (EXT_AW <= 32))
     always@(posedge clk or negedge rst_n_reg)
       begin
          if (!rst_n_reg)
            page_ptr3 <= 0;
          else if ((addr_rd == REG15) && (wren_rd == 1'b1))
            page_ptr3 <= din_rd;
          else
            page_ptr3 <= page_ptr3;
       end
   endgenerate
   
//   generate if (REGISTERS_16 == 1)
//      pmi_distributed_dpram #(
//                              16,
//                              4,
//                              8,
//                              "noreg",
//                              "none",
//                              "binary",
//                              FAMILY_NAME,
//                              "pmi_distributed_dpram"
//                              ) u1_isp8_rfmem
//      (
//       .WrAddress( addr_rd[3:0]),
//       .Data     ( din_rd_int),
//       .WrClock  ( clk),
//       .WE       ( wren_rd),
//       .WrClockEn( hi_val),
//       .RdAddress( addr_rb[3:0]),
//       .RdClock  ( clk),
//       .RdClockEn( hi_val),
//       .Reset    ( lo_val),
//       .Q        ( dout_rb)
//       );

RAM16SDP4 u1_rfmem_low (
.DI(din_rd_int[3:0]),
.WRE(wren_rd),
.CLK(clk),
.WAD(addr_rd[3:0]),
.RAD(addr_rb[3:0]),
.DO(dout_rb[3:0])
);
RAM16SDP4 u1_rfmem_high (
.DI(din_rd_int[7:4]),
.WRE(wren_rd),
.CLK(clk),
.WAD(addr_rd[3:0]),
.RAD(addr_rb[3:0]),
.DO(dout_rb[7:4])
);

//   generate if (REGISTERS_16 == 1)
//      pmi_distributed_dpram #(
//                              16,
//                              4,
//                              8,
//                              "noreg",
//                              "none",
//                              "binary",
//                              FAMILY_NAME,
//                              "pmi_distributed_dpram"
//                              ) u2_isp8_rfmem
//         (
//          .WrAddress( addr_rd[3:0]),
//          .Data     ( din_rd_int),
//          .WrClock  ( clk),
//          .WE       ( wren_rd),
//          .WrClockEn( hi_val),
//          .RdAddress( addr_rd[3:0]),
//          .RdClock  ( clk),
//          .RdClockEn( hi_val),
//          .Reset    ( lo_val),
//          .Q        ( dout_rd)
//          );

RAM16SDP4 u2_rfmem_low (
.DI(din_rd_int[3:0]),
.WRE(wren_rd),
.CLK(clk),
.WAD(addr_rd[3:0]),
.RAD(addr_rd[3:0]),
.DO(dout_rd[3:0])
);
RAM16SDP4 u2_rfmem_high (
.DI(din_rd_int[7:4]),
.WRE(wren_rd),
.CLK(clk),
.WAD(addr_rd[3:0]),
.RAD(addr_rd[3:0]),
.DO(dout_rd[7:4])
);


   //--------------------------------------------------------------
   //Registered data and write enable for register file memory

   always@(posedge clk or negedge rst_n_reg)
      begin
         if (!rst_n_reg) begin
            wren_alu_rd <= 0;
            wren_il_rd  <= 0;
         end
         else begin
            wren_alu_rd <= (add | addc | sub | subc | mov | andr |
                            orr | xorr | ror1 | rorc | rol1 | rolc);
            wren_il_rd  <= (import | importi | lsp | lspi);
         end
      end

   always@(posedge clk or negedge rst_n_reg)
      begin
         if (!rst_n_reg)
            din_rd1 <=0;
         else
            din_rd1 <= dout_alu;
      end

   always@(import or importi or lsp or lspi or ext_mem_din or ext_io_din or din_rd1)
      begin
         if (lspi||lsp)
            din_rd <= ext_mem_din;
         else if (import | importi)
            din_rd <= ext_io_din;
         else
            din_rd <= din_rd1;
      end
   assign wren_rd = ((wren_alu_rd | wren_il_rd) & data_cyc);

endmodule

