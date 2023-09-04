//-----------------------------------------------------------------------------
// 
//  Name:   isp8_flow_cntl.v
// 
//  Description:  Flow control logic
// 
//  $Revision: 1.2 $
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

module isp8_flow_cntl #(
                        parameter  PGM_STACK_AW=4 ,
                        parameter  PGM_STACK_AD=16 ,
                        parameter  PROM_AW=12
                        )
   (
    // Clock and Reset  
    clk ,               
    rst_n ,             
   
    // Inputs           
    setc ,              
    clrc ,              
    setz ,              
    clrz ,              
    seti ,              
    clri ,              
    addr_jmp ,          
    update_c ,          
    update_z ,          
    cout_alu ,          
    dout_alu ,          
   
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
    intr , 
    //added inputs             
    lsp ,
    lspi ,
    ssp ,
    sspi ,
    import ,
    importi ,
    export ,
    exporti ,
    ready ,                  
    // Outputs          
    addr_cyc ,
    ext_addr_cyc,          
    data_cyc ,          
    prom_addr ,
    prom_enable,
    carry_flag , 
    intr_ack            
    ); 

   input                           clk ;        
   input                           rst_n ;      

   input                           setc ;
   input                           clrc ;
   input                           setz ;
   input                           clrz ;
   input                           seti ;
   input                           clri ;
   input [PROM_AW -1:0]            addr_jmp ;
   input                           update_c ;
   input                           update_z ;
   input                           cout_alu ;
   input [7:0]                     dout_alu ;

   input                           bz ;
   input                           bnz ;
   input                           bc ;
   input                           bnc ;
   input                           b ;
   input                           callz ;
   input                           callnz ;
   input                           callc ;
   input                           callnc ;
   input                           call ;
   input                           ret ;
   input                           iret ;
   input                           intr ;
   //added inputs
   input                           lsp ;
   input                           lspi ;
   input                           ssp ;
   input                           sspi ;
   input                           import ;
   input                           importi ;
   input                           export ;
   input                           exporti ;
   input                           ready ;
   //outputs
   output                          addr_cyc ;
   output                          ext_addr_cyc ;
   output                          data_cyc ;
   output [PROM_AW -1:0]           prom_addr ;
   output                          prom_enable;
   output                          carry_flag ;
   output                          intr_ack ;

   wire                            lo_val,hi_val;
   wire [PROM_AW -1:0]             pc_int ; 
   wire                            push_enb ;
   wire                            intr_req_actv ;
   wire                            br_enb,br_enb0 ;
   wire [PROM_AW -1:0]             dout_stack ;
   wire [PROM_AW +1:0]             dout_stack_w_cz ;
   wire [PROM_AW +1:0]             din_stack_w_cz ;
   wire                            pushed_zero, pushed_carry ;
   wire                            sp_we ;
   wire                            condbr ;
   wire                            ext_cycle_type ;
   wire                            ret_cycle_type ;
   wire                            zero_flag_async;
   wire                            carry_flag_async;

   reg [PGM_STACK_AW-1:0]          stack_ptr ;
   wire [PGM_STACK_AW-1:0]         stack_ptr_int ;
   reg                             carry_flag_int ; 
   reg                             zero_flag ;      
   reg                             ie_flag ; 
   reg [PROM_AW -1:0]              pc ;
   reg                             addr_cyc_int ; 
   reg                             ext_addr_cyc_int ; 
   reg                             data_cyc_int ;
   reg                             ret_reg ; 
   reg [7:0]                       dout_alu_reg ;   
   reg                             intr_reg0 ;
   reg [PROM_AW -1:0]              addr_jmp_reg ;
   reg [PROM_AW -1:0]              prom_addr_int ;
   reg                             br_enb_reg ;
   reg                             intr_ack_int ;


   assign                          lo_val =1'b0;
   assign                          hi_val =1'b1;
   assign                          condbr =bz || bnz || bc || bnc || call || callz || callnz || callc || callnc ;
   assign                          ext_cycle_type =lspi || lsp || sspi || ssp || export || exporti || import || importi ;

   assign                          ret_cycle_type = ret || iret;

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n) begin
            addr_cyc_int     <= 1'b1;
            ext_addr_cyc_int <= 1'b1;
            data_cyc_int     <= 1'b0;
         end
         else begin
            addr_cyc_int     <= (~(addr_cyc_int) && (!(ext_addr_cyc_int)));
            ext_addr_cyc_int <= ((addr_cyc_int && ext_cycle_type) ||
                                 (ext_addr_cyc_int && ext_cycle_type && ! ready));
            data_cyc_int     <= ((addr_cyc_int && !ext_cycle_type) ||
                                 (ext_addr_cyc_int && ext_cycle_type && ready));    
         end
      end

   assign addr_cyc     = addr_cyc_int;
   assign ext_addr_cyc = ext_addr_cyc_int;
   assign data_cyc     = data_cyc_int;
   assign prom_enable  = data_cyc_int | ~rst_n;


   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n) begin
            ret_reg           <= 1'b0;
            dout_alu_reg      <= 8'h00;
         end
         else begin
            ret_reg           <= (ret | iret);
            dout_alu_reg      <= dout_alu;
         end
      end

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            intr_reg0  <= 1'b0;
         else
            if(addr_cyc_int)
               intr_reg0 <= ie_flag && intr;
            else
               intr_reg0 <= intr_reg0;
      end

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n) begin
            br_enb_reg    <= 1'b0;
            addr_jmp_reg  <= 0;
         end
         else if ( addr_cyc_int) begin
            addr_jmp_reg  <= addr_jmp;
            br_enb_reg    <= br_enb;
         end
      end

   assign intr_req_actv = (intr_reg0 & ~(intr_ack_int));
   

   //Push enable to store in stack
   assign push_enb =((callz & zero_flag) | (callc & carry_flag_int) |
                     (callnz & ~(zero_flag)) | (callnc & ~(carry_flag_int)) | call);

   //Branch enable to branch out the programm counter
   assign br_enb0 = ((bz & zero_flag) | (bc & carry_flag_int) |
                     (bnz & ~ zero_flag) | (bnc & ~ carry_flag_int)) ;

   assign br_enb  = ((bz & zero_flag) | (bc & carry_flag_int) |
                     (bnz & ~(zero_flag)) | (bnc & ~(carry_flag_int)) | b | push_enb);

   //program counter
   //Incremented every address cycle (2 clocks) and 
   //loaded with stack with return instruction.
   //loaded interrupt vector with interrupt.    
   assign pc_int = (br_enb_reg & data_cyc_int) ? (pc + addr_jmp_reg) : 
                                                 pc + 'd1;


   always@(intr_req_actv or ret_reg or dout_stack or push_enb or br_enb0 or 
           pc_int or data_cyc_int or ret_cycle_type)
      begin
         if (data_cyc_int && intr_req_actv && ~push_enb && ~br_enb0 && 
             ~ret_cycle_type)
            // block interrupt processing on braches, calls, and returns
            prom_addr_int = {PROM_AW{1'b0}};
         else if (ret_reg)
            // returning from interrupt, pull return address from the stack
            prom_addr_int = dout_stack;
         else
            // normal straight line/jump instruction
            prom_addr_int = pc_int; 
      end

   assign prom_addr = prom_addr_int; 
   
   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n) 
            // reset vector is at address 1
            pc <= {{PROM_AW{1'b0}}};
         else if (data_cyc_int)
            pc <= prom_addr_int;
      end

   //Carry flag

   // this is needed to push the correct carry flag state onto the
   // call/interrupt stack.  The equation doesn't need iret, since
   // the carry flag will be coming off the stack.
   assign carry_flag_async = (clrc ? 1'b0 :
                              setc ? 1'b1 :
                              (update_c && cout_alu) ? 1'b1 :
                              1'b0);

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            carry_flag_int <= 0;
         else if ((clrc ) | (setc ) | (update_c ) | (iret)) 
            begin
               if (clrc)
                  carry_flag_int <= 1'b0;
               else if (setc)
                  carry_flag_int <= 1'b1;
               else if (iret)
                  carry_flag_int <= pushed_carry;
               else
                  carry_flag_int <= cout_alu;
            end // if ((clrc ) | (setc ) | (update_c ) | (iret))
      end

   assign carry_flag = carry_flag_int;

   //Zero flag

   // this is needed to push the correct zero flag state onto the
   // call/interrupt stack.  The equation doesn't need iret, since
   // the zero flag will be coming off the stack.
   assign zero_flag_async = (clrz ? 1'b0 :
                             setz ? 1'b1 :
                             (update_z && dout_alu_reg == 8'h00) ? 1'b1 :
                             1'b0);

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            zero_flag <= 0;
         else if (update_z | setz | clrz | iret)
            begin
               // clearing the z bit should not be overridden by the
               // alu register being 0
               if (clrz)
                  zero_flag <= 1'b0;
               else if (setz)
                  zero_flag <= 1'b1;
               else if (iret)
                  zero_flag <= pushed_zero;
               else
                  zero_flag <= (dout_alu_reg == 8'h00);
            end // if (update_z)
      end // always@ (posedge clk or negedge rst_n)
   
   //Interrupt Enable flag
   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            ie_flag <= 0;
         else if ((clri ) | (seti ))
            ie_flag <= ~(clri);
         else
            ie_flag <= ie_flag;
      end
   
   //Generate interrupt acknowledge
   // Asserted as long as in interrupt service routine
   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            intr_ack_int <= 0;  
         else if (data_cyc_int && intr_req_actv && ~push_enb && 
                  ~br_enb0 && ~ret_cycle_type) 
            // acknowledge the intr after all change of flow opcodes complete
            //else if ((data_cyc_int ) && (intr_req_actv )) 
            intr_ack_int <= 1;
         else if (iret && data_cyc_int) 
            intr_ack_int <= 0;
         else
            intr_ack_int <= intr_ack_int;
      end

   assign intr_ack = intr_ack_int;


   assign sp_we = ((addr_cyc_int & push_enb) |
                   (data_cyc_int & intr_req_actv && ~push_enb && 
                    ~br_enb0 && ~ret_cycle_type));

//   pmi_distributed_spram # (
//                            PGM_STACK_AD,
//                            PGM_STACK_AW,
//                            (PROM_AW+2),
//                            "noreg",
//                            "none",
//                            "binary",
//                            FAMILY_NAME,
//                            "pmi_distributed_spram"
//                            ) u1_isp8_stkmem
//      (
//       .Address (stack_ptr_int),
//       .Data    (din_stack_w_cz),
//       .Clock   (clk),
//       .ClockEn (hi_val),
//       .WE      (sp_we),
//       .Reset   (lo_val),
//       .Q       (dout_stack_w_cz)
//       );

// Width => PROM_AW = 9 (512) => [8..0] => Stack +2 => 10..0

RAM16S4 stack_low (
 .DI (din_stack_w_cz[3:0]),
 .WRE (sp_we),
 .CLK (clk),
 .AD (stack_ptr_int),
 .DO (dout_stack_w_cz[3:0])
);
RAM16S4 stack_mid (
 .DI (din_stack_w_cz[7:4]),
 .WRE (sp_we),
 .CLK (clk),
 .AD (stack_ptr_int),
 .DO (dout_stack_w_cz[7:4])
);

wire bit11;     // Not used

RAM16S4 stack_high (
 .DI ({1'b0,din_stack_w_cz[10:8]}),
 .WRE (sp_we),
 .CLK (clk),
 .AD (stack_ptr_int),
 .DO ({bit11,dout_stack_w_cz[10:8]})
);

   assign din_stack_w_cz = {carry_flag_async , zero_flag_async , pc_int};
   assign dout_stack     = dout_stack_w_cz[PROM_AW - 1 : 0];
   assign pushed_carry   = dout_stack_w_cz[PROM_AW + 1];
   assign pushed_zero    = dout_stack_w_cz[PROM_AW];

   //Stack pointer
   assign stack_ptr_int = stack_ptr;

   always@(posedge clk or negedge rst_n)
      begin
         if (!rst_n)
            stack_ptr <= 0;
         else if (data_cyc_int & (push_enb  | (intr_req_actv && ~ret_cycle_type))) 
            stack_ptr <= stack_ptr + 'd1;
         else if (addr_cyc_int & ret_cycle_type) 
            stack_ptr <= stack_ptr - 'd1;
      end


endmodule 
