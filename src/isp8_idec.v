//---------------------------------------------------------------------------
//
//  Name:   isp8_idec.v
//
//  Description:  Instruction decode logic
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

module isp8_idec
#(
parameter  PROM_AW=10
)
(
   // Inputs
   instr ,

   // Outputs
   imi_instr ,
   sub ,
   subc ,
   add ,
   addc ,
   mov ,
   andr ,
   orr ,
   xorr ,
   cmp ,
   test ,

   ror1 ,
   rorc ,
   rol1 ,
   rolc ,

   clrc ,
   setc ,
   clrz ,
   setz ,
   clri ,
   seti ,

   bz ,
   bnz ,
   bc ,
   bnc ,
   b ,
   callz ,
   callnz ,
   callc ,
   callnc ,
   call ,

   ret ,
   iret ,

   export ,
   import ,
   exporti ,
   importi ,
   ssp ,
   lsp ,
   sspi ,
   lspi ,

   addr_rb ,
   addr_rd ,
   imi_data ,
   addr_jmp ,
   update_c ,
   update_z
   );




input [17:0] instr ;

output       imi_instr ;
output       sub ;
output       subc ;
output       add ;
output       addc ;
output       mov ;
output       andr ;
output       orr ;
output       xorr ;
output       cmp ;
output       test ;
output       ror1;
output       rorc ;
output       rol1;
output       rolc ;
output       clrc ;
output       setc ;
output       clrz ;
output       setz ;
output       clri ;
output       seti ;
output       bz ;
output       bnz ;
output       bc ;
output       bnc ;
output       b ;
output       callz ;
output       callnz ;
output       callc ;
output       callnc ;
output       call ;
output       ret ;
output       iret ;
output       export ;
output       import ;
output       exporti ;
output       importi ;
output       ssp ;
output       lsp ;
output       sspi ;
output       lspi ;

output [4:0]           addr_rb ;
output [4:0]           addr_rd ;
output [7:0]           imi_data ;
output [PROM_AW -1:0] addr_jmp ;
output                 update_c ;
output                 update_z ;
//---------------------------------------------------------------------------
wire instr_l1_0, instr_l1_1, instr_l1_2, instr_l1_3 ;
wire instr_l2_0, instr_l2_1, instr_l2_2, instr_l2_3 ;
wire instr_l3_0, instr_l3_1 ;
wire instr_l4_0, instr_l4_1 ;
wire instr_l5_0, instr_l5_1, instr_l5_2, instr_l5_3 ;
wire instr_l6_0, instr_l6_1 ;
wire instr_l7_0, instr_l7_1, instr_l7_2, instr_l7_3 ;
wire ro ;
wire sc ;
wire br0;
wire ca0, ca1 ;
wire re ;
wire iels ;
wire iels_ie ;
wire iels_ls ;

// Level 1 decodes of bits [17:16]
assign instr_l1_0 = (~instr[17] & ~instr[16]) ;
assign instr_l1_1 = (~instr[17] & instr[16]) ;
assign instr_l1_2 = (instr[17] & ~instr[16]) ;
assign instr_l1_3 = (instr[17] & instr[16]) ;

// Level 2 decodes of bits [15:14]
assign instr_l2_0 = (~instr[15] & ~instr[14]) ;
assign instr_l2_1 = (~instr[15] & instr[14]) ;
assign instr_l2_2 = (instr[15] & ~instr[14]) ;
assign instr_l2_3 = (instr[15] & instr[14]) ;

// Level 3 decodes of bits [13]
assign instr_l3_0 = ~instr[13] ;
assign instr_l3_1 = instr[13] ;

// Level 4 decodes of bits [12]
assign instr_l4_0 = ~instr[12] ;
assign instr_l4_1 = instr[12] ;

// Level 5 decodes of bits [11:10]
assign instr_l5_0 = (~instr[11] & ~instr[10]) ;
assign instr_l5_1 = (~instr[11] & instr[10]) ;
assign instr_l5_2 = (instr[11] & ~instr[10]) ;
assign instr_l5_3 = (instr[11] & instr[10]) ;

// Level 6 decodes of bits [2]
assign instr_l6_0 = ~instr[2] ;
assign instr_l6_1 = instr[2] ;

// Level 7 decodes of bits [1:0]
assign instr_l7_0 = (~instr[1] & ~instr[0]) ;
assign instr_l7_1 = (~instr[1] & instr[0]) ;
assign instr_l7_2 = (instr[1] & ~instr[0]) ;
assign instr_l7_3 = (instr[1] & instr[0]) ;

// Immidiate operand instruction de
assign imi_instr = instr_l3_1 ;

// Decodes for sub* instructions
assign sub   = instr_l1_0 & instr_l2_0 ;
assign subc  = instr_l1_0 & instr_l2_1 ;

// Decodes for add* instructions
assign add   = instr_l1_0 & instr_l2_2 ;
assign addc   = instr_l1_0 & instr_l2_3 ;

// Decodes for mov* instructions
assign mov  = instr_l1_1 & instr_l2_0 ;

// Decodes for logic* instructions
assign andr = instr_l1_1 & instr_l2_1 ;
assign orr  = instr_l1_1 & instr_l2_2 ;
assign xorr = instr_l1_1 & instr_l2_3 ;

// Decodes for compare/test instructions
assign cmp   = instr_l1_2 & instr_l2_0 ;
assign test  = instr_l1_2 & instr_l2_1 ;

// Decodes for rotate instructions
assign ro    = instr_l1_2 & instr_l2_2 & instr_l3_0 ;
assign ror1  = ro & instr_l7_0 ;
assign rorc  = ro & instr_l7_2 ;
assign rol1  = ro & instr_l7_1 ;
assign rolc  = ro & instr_l7_3 ;

// Decodes for set/clear instructions
assign sc    = instr_l1_2 & instr_l2_3 & instr_l3_0;
assign clrc  = sc & instr_l6_0 & instr_l7_0 ;
assign setc  = sc & instr_l6_0 & instr_l7_1 ;
assign clrz  = sc & instr_l6_0 & instr_l7_2 ;
assign setz  = sc & instr_l6_0 & instr_l7_3 ;
assign clri  = sc & instr_l6_1 & instr_l7_0 ;
assign seti  = sc & instr_l6_1 & instr_l7_1 ;

// Decodes for import/export instructions
assign iels    = instr_l1_2 & instr_l2_3 & instr_l3_1 ;
assign iels_ie = iels & instr_l6_0 ;
assign export  = iels_ie & instr_l7_0 ;
assign import  = iels_ie & instr_l7_1 ;
assign exporti = iels_ie & instr_l7_2 ;
assign importi = iels_ie & instr_l7_3 ;

// Decodes for load/store instructions
assign iels_ls = iels & instr_l6_1 ;
assign ssp     = iels_ls & instr_l7_0 ;
assign lsp     = iels_ls & instr_l7_1 ;
assign sspi    = iels_ls & instr_l7_2 ;
assign lspi    = iels_ls & instr_l7_3 ;

// Decodes for branch instructions
assign br0   = instr_l1_3 & instr_l2_0;
assign bz    = br0 & instr_l3_0 & instr_l4_0;
assign bnz   = br0 & instr_l3_0 & instr_l4_1;
assign bc    = br0 & instr_l3_1 & instr_l4_0;
assign bnc   = br0 & instr_l3_1 & instr_l4_1;


// Decodes for call instructions
assign ca0    = instr_l1_3 & instr_l2_1;
assign callz  = ca0 & instr_l3_0 & instr_l4_0;
assign callnz = ca0 & instr_l3_0 & instr_l4_1;
assign callc  = ca0 & instr_l3_1 & instr_l4_0;
assign callnc = ca0 & instr_l3_1 & instr_l4_1;

// Decodes for unconditional branch/call/return instructions
assign re    = instr_l1_3 & instr_l2_2 ;
assign ca1   = instr_l1_3 & instr_l2_2 ;
assign call  = ca1 & instr_l3_0 & instr_l4_0;
assign ret   = re & instr_l3_0 & instr_l4_1 ;
assign iret  = re & instr_l3_1 & instr_l4_0 ;
assign b     = ca1 & instr_l3_1 & instr_l4_1;

// Undefined Opcode
// undef_op = instr_l1_3 & instr_l2_3;

// Rd address
assign addr_rd  = instr[12:8] ;

// Rb address
assign addr_rb  = instr[7:3] ;

// Constant data from immidiate instructions
assign imi_data = instr[7:0] ;

// Label from branch/call instructions


   generate
      if (PROM_AW <= 12)
         assign addr_jmp = instr[PROM_AW-1:0];
      else
         assign addr_jmp = {{PROM_AW-12{instr[11]}},instr[11:0]} ;
   endgenerate

// Enable Carry/Zero Flag update
assign update_c = (instr_l1_0 | ( instr_l1_2 & ~instr_l2_3 & instr[1]) | (instr_l1_2 & instr_l2_0)) ;

assign update_z = (instr_l1_0 | // add/sub
                   (instr_l1_1 & ~instr_l2_0) | // and/or/xor
                   ro |   // rotate
                   cmp |  // compare
                   test); // test
// setz and clrz do not activate update_z, but are used directly
// by the async_z logic in isp8_flow_ctrl.

endmodule
