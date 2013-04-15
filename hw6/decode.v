`include "global_def.h"

module Decode(
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_IR,
  I_FetchStall,
  I_WriteBackEnable,
  I_WriteBackRegIdx,
  I_WriteBackData,
  O_LOCK,
  O_PC,
  O_Opcode,
  O_Src1Value,
  O_Src2Value,
  O_DestRegIdx,
  O_DestValue,
  O_Imm,
  O_FetchStall,
  O_DepStall,
  O_BranchStallSignal,
  O_DepStallSignal
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the fetch stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`IR_WIDTH-1:0] I_IR;
input I_FetchStall;

// Inputs from the writeback stage

// scalar:
input I_WriteBackEnable;
input [3:0] I_WriteBackRegIdx;
input [`REG_WIDTH-1:0] I_WriteBackData;

// vector:
input I_WriteBackEnableV;
input [5:0] I_WriteBackRegIdxV;
input [`VREG_WIDTH-1:0] I_WriteBackDataV;


// Outputs to the execute stage
output reg O_LOCK;
output reg [`PC_WIDTH-1:0] O_PC;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg O_FetchStall;

output reg [`REG_WIDTH-1:0] O_Imm;

// scalar:
output reg [`REG_WIDTH-1:0] O_Src1Value;
output reg [`REG_WIDTH-1:0] O_Src2Value;
output reg [3:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_DestValue;

// vector:
output reg [`VREG_WIDTH-1:0] O_Src1ValueV;
output reg [`VREG_WIDTH-1:0] O_Src2ValueV;
output reg [5:0] O_DestRegIdxV;
output reg [`VREG_WIDTH-1:0] O_DestValueV;
output reg [1:0] O_DestRegIdxV_Idx;

// GPU
output reg [3:0] O_Type;

/////////////////////////////////////////
// ## Note ##
// O_DepStall: Asserted when current instruction should be waiting for data dependency resolves. 
// - Like O_FetchStall, the instruction with O_DepStall == 1 will be treated as NOP in the following stages.
/////////////////////////////////////////
output reg O_DepStall;  

// Outputs to the fetch stage
output O_DepStallSignal;
output O_BranchStallSignal;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//
// Architectural Registers
reg [`REG_WIDTH-1:0] RF[0:`NUM_RF-1]; // Scalar Register File (R0-R7: Integer, R8-R15: Floating-point)
reg [`VREG_WIDTH-1:0] VRF[0:`NUM_VRF-1]; // Vector Register File

// Valid bits for tracking the register dependence information
reg [`NUM_RF-1:0] RF_VALID; // Valid bits for Scalar Register File
// reg VRF_VALID[0:`NUM_VRF-1]; // Valid bits for Vector Register File
reg [`NUM_VRF-1:0] VRF_VALID; // Valid bits for Vector Register File

wire [`REG_WIDTH-1:0] Imm32; // Sign-extended immediate value
reg [2:0] ConditionalCode; // Set based on the written-back result

wire __DepStallSignal;
wire __BranchStallSignal;

/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//
reg[7:0] trav;

initial
begin
  for (trav = 0; trav < `NUM_RF; trav = trav + 1'b1)
  begin
    RF[trav] = 0;
    // RF_VALID[trav] = 1;  
  end 
    
  for (trav = 0; trav < `NUM_VRF; trav = trav + 1'b1)
  begin
    VRF[trav] = 0;
    // VRF_VALID[trav] = 1;  
  end 
  
  RF_VALID = 16'b1111111111111111;
  VRF_VALID = 64'b1111111111111111111111111111111111111111111111111111111111111111;

  ConditionalCode = 3'b000;

  O_PC = 0;
  O_Opcode = 0;
  O_DepStall = 0;
end // initial

/////////////////////////////////////////////
// ## Note ##
// __DepStallSignal: Data dependency detected (1) or not (0).
// - Keep in mind that since valid bit is only updated in negative clock
//   edge, you need to take currently written-back information, if there is, into account
//   when asserting this signal as well as valid-bit information.
/////////////////////////////////////////////
assign __DepStallSignal = 
  (I_LOCK == 1'b1) ? 
    (
	 (I_IR[31:24] == `OP_ADD_D) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!( ((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16])) && ((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) &  (16'b0000000000000001<<I_IR[11:8])) )
					) : !( (RF_VALID & (16'b0000000000000001<<I_IR[19:16])) && (RF_VALID &  (16'b0000000000000001<<I_IR[11:8])) )
		) : 
		(I_IR[31:24] == `OP_ADDI_D) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[19:16]))
		) :  
	  (I_IR[31:24] == `OP_AND_D) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!( ((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16])) && ((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) &  (16'b0000000000000001<<I_IR[11:8])) )
					) : !( (RF_VALID & (16'b0000000000000001<<I_IR[19:16])) && (RF_VALID &  (16'b0000000000000001<<I_IR[11:8])) )
		) :
	  (I_IR[31:24] == `OP_ANDI_D) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[19:16]))
		) :
		(I_IR[31:24] == `OP_MOV) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[11:8]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[11:8]))
		) :
		(I_IR[31:24] == `OP_LDW) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!( (RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]) )
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[19:16]) )
		) :
	  (I_IR[31:24] == `OP_STW) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!( (((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]))!=16'b0000000000000000) && (((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) &  (16'b0000000000000001<<I_IR[23:20]))!=16'b0000000000000000) )
					) : !( (RF_VALID & (16'b0000000000000001<<I_IR[19:16])) && (RF_VALID & (16'b0000000000000001<<I_IR[23:20])) )
		) :
	  (I_IR[31:27] == `OP_BR) ? ( // if branch wait till all registers become valid
			(I_WriteBackEnable == 1'b1) ? (
					(((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b1111111111111111)) != 16'b1111111111111111)
					) : (( RF_VALID & (16'b1111111111111111)) != 16'b1111111111111111)
		) :
	  (I_IR[31:24] == `OP_JMP) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[19:16]) )
		) :
		(I_IR[31:24] == `OP_JSRR) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[19:16]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[19:16]) )
		) :
		(I_IR[31:24] == `OP_MOVI_D ) ? (1'b0) : // no dependency
	   (I_IR[31:24] == `OP_JSR    ) ? (1'b0) : // no dependency
		
		// vector operations
		(I_IR[31:24] == `OP_VADD) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!( ((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[13:8])) && ((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) &  (64'b1<<I_IR[5:0])) )
					) : !( (VRF_VALID & (64'b1<<I_IR[13:8])) && (VRF_VALID &  (64'b1<<I_IR[5:0])) )
		) : 
		(I_IR[31:24] == `OP_VMOV) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[13:8]))
					) : !( VRF_VALID & (64'b1<<I_IR[13:8]))
		) :
		(I_IR[31:24] == `OP_VMOVI ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_VCOMPMOV) ? (
			(I_WriteBackEnable == 1'b1) ? (
					!((RF_VALID|((16'b0000000000000001)<<I_WriteBackRegIdx)) & (16'b0000000000000001<<I_IR[11:8]))
					) : !( RF_VALID & (16'b0000000000000001<<I_IR[11:8]))
		) :
		(I_IR[31:24] == `OP_VCOMPMOVI ) ? (1'b0) : // no dependency

		// GPU operations
		(I_IR[31:24] == `OP_SETVERTEX) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[21:16]))
					) : !( VRF_VALID & (64'b1<<I_IR[21:16]))
		) :
		(I_IR[31:24] == `OP_SETCOLOR) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[21:16]))
					) : !( VRF_VALID & (64'b1<<I_IR[21:16]))
		) :
		(I_IR[31:24] == `OP_ROTATE) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[21:16]))
					) : !( VRF_VALID & (64'b1<<I_IR[21:16]))
		) :
		(I_IR[31:24] == `OP_TRANSLATE) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[21:16]))
					) : !( VRF_VALID & (64'b1<<I_IR[21:16]))
		) :
		(I_IR[31:24] == `OP_SCALE) ? (
			(I_WriteBackEnableV == 1'b1) ? (
					!((VRF_VALID|((64'b1)<<I_WriteBackRegIdxV)) & (64'b1<<I_IR[21:16]))
					) : !( VRF_VALID & (64'b1<<I_IR[21:16]))
		) :
		(I_IR[31:24] == `OP_PUSHMATRIX     ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_POPMATRIX      ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_BEGINPRIMITIVE ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_ENDPRIMITIVE   ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_LOADIDENTITY   ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_FLUSH          ) ? (1'b0) : // no dependency
		(I_IR[31:24] == `OP_DRAW           ) ? (1'b0) : // no dependency
	       (1'b0)
    ) : (1'b0);

assign O_DepStallSignal = __DepStallSignal;

// O_BranchStallSignal: Branch instruction detected (1) or not (0).
assign __BranchStallSignal = 
  (I_LOCK == 1'b1) ? 
    ((I_IR[31:24] == `OP_BRN  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRZ  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRP  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNZ ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNP ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRZP ) ? (1'b1) : 
     (I_IR[31:24] == `OP_BRNZP) ? (1'b1) : 
     (I_IR[31:24] == `OP_JMP  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_JSR  ) ? (1'b1) : 
     (I_IR[31:24] == `OP_JSRR ) ? (1'b1) : 
     (1'b0)
    ) : (1'b0);

// if there is a dependency, then do assert BranchStall until dependency resolved
assign O_BranchStallSignal = (__DepStallSignal==1'b0) ? __BranchStallSignal : 1'b0;

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ## Note ##
// First half clock cycle to write data back into the register file 
// 1. To write data back into the register file
// 2. Update Conditional Code to the following branch instruction to refer
/////////////////////////////////////////
always @(posedge I_CLOCK) begin

  if (I_LOCK == 1'b1) begin
    
	 if (I_WriteBackEnable==1'b1) begin
		
		 // write data back into the register file
		 RF[I_WriteBackRegIdx] <= I_WriteBackData;
		 
		 // Update Conditional Code to the following branch instruction to refer
		 if      ($signed(I_WriteBackData)>0) ConditionalCode = 3'b001; // CC = P
		 else if ($signed(I_WriteBackData)<0) ConditionalCode = 3'b100; // CC = N
		 else                                 ConditionalCode = 3'b010; // CC = Z
		 
	end // if (I_WriteBackEnable==1'b1)
	else if (I_WriteBackEnableV==1'b1) begin
		VRF[I_WriteBackRegIdxV] <= I_WriteBackDataV;
	end
	 
  end // if (I_LOCK == 1'b1)
  
end // always @(posedge I_CLOCK)

/////////////////////////////////////////
// ## Note ##
// Second half clock cycle to read data from the register file
// 1. To read data from the register file
// 2. To update valid bit for the corresponding register (for both writeback instruction and current instruction) 
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  // O_FetchStall <= I_FetchStall;

  if (I_LOCK == 1'b1)
  begin
    
	 if (I_WriteBackEnable==1'b1 ) RF_VALID  = (RF_VALID | ((16'b0000000000000001)<<I_WriteBackRegIdx));
	 if (I_WriteBackEnableV==1'b1) VRF_VALID = (VRF_VALID | ((16'b0000000000000001)<<I_WriteBackRegIdxV));
	 
	 if (__DepStallSignal==1'b1) begin // && __WriteToRead==1'b0) begin
		O_DepStall <= 1'b1;
		O_FetchStall <= 1'b1;
	 end // if (__DepStallSignal==1'b1)
	 else if (__DepStallSignal==1'b0) begin // || __WriteToRead==1'b1) begin
		
			O_PC <= I_PC;
			O_Opcode <= I_IR[31:24];
			O_DepStall <= 1'b0;
			O_FetchStall <= 1'b0;
			
			// if (__BranchStallSignal==1'b1) O_BranchStallSignal <= 1'b1;
			// else O_BranchStallSignal <= 1'b0;
			
			case(I_IR[31:24])
			`OP_ADD_D, `OP_AND_D: // check [19:16], [11:8]
			begin
				O_Src1Value <= RF[I_IR[19:16]];
				O_Src2Value <= RF[I_IR[11:8]];
				O_DestRegIdx <= I_IR[23:20];
				RF_VALID = (RF_VALID & ~((16'b0000000000000001)<<I_IR[23:20]));
			end // end case `OP_ADD_D, `OP_AND_D
			`OP_ADDI_D, `OP_ANDI_D, `OP_LDW:  // check [19:16]
			begin
				O_Src1Value <= RF[I_IR[19:16]];
				O_Imm <= $signed(Imm32);
				O_DestRegIdx <= I_IR[23:20];
				RF_VALID = (RF_VALID & ~((16'b0000000000000001)<<I_IR[23:20]));
			end // end case `OP_ADDI_D, `OP_ANDI_D, `OP_LDW
			`OP_MOV:  // check [11:8]
			begin
				O_Src2Value <= RF[I_IR[11:8]];
				O_DestRegIdx <= I_IR[19:16];
				RF_VALID = (RF_VALID & ~((16'b0000000000000001)<<I_IR[19:16]));
			end // end case `OP_MOV
			`OP_MOVI_D:  
			begin
				O_Imm <= $signed(Imm32);
				O_DestRegIdx <= I_IR[19:16];
				RF_VALID = (RF_VALID & ~((16'b0000000000000001)<<I_IR[19:16]));
			end // end case `OP_MOVI_D
			`OP_STW:  // check [23:20], [19:16]
			begin
				O_DestValue <= RF[I_IR[23:20]];
				O_Src1Value <= RF[I_IR[19:16]];
				O_Imm <= $signed(Imm32);
			end // end case `OP_STW
			`OP_JSR:  
			begin
				O_Imm <= $signed(Imm32<<2);
				O_DestValue <= I_PC;
				O_DestRegIdx <= 4'h7;
				RF_VALID = ( RF_VALID & ~(16'b0000000010000000) ); // invalidate R7
			end // end case `OP_JSR
			`OP_JMP: // check [19:16]
			begin
				O_DestValue <= RF[I_IR[19:16]];
			end // end case `OP_JMP
			`OP_JSRR: // check [19:16]
			begin
				O_DestValue <= I_PC; // next PC
				O_DestRegIdx <= 4'h7;
				RF_VALID = ( RF_VALID & ~(16'b0000000010000000) ); // invalidate R7
			end // end case `OP_JSRR
			`OP_BRN, `OP_BRZ, `OP_BRP, `OP_BRNZ, `OP_BRZP, `OP_BRNP, `OP_BRNZP: 
			begin
				O_Imm <= ((ConditionalCode & I_IR[26:24])? ($signed(Imm32<<2)): 0);
			end
			// vector
			`OP_VADD:
			begin
				O_Src1ValueV  <= VRF[I_IR[13:8]];
				O_Src2ValueV  <= VRF[I_IR[5:0]];
				O_DestRegIdxV <= I_IR[21:16];
				VRF_VALID = (VRF_VALID & ~((64'b1)<<I_IR[21:16]));
			end
			`OP_VMOV:
			begin
				O_DestValueV  <= VRF[I_IR[13:8]];
				VRF_VALID = (VRF_VALID & ~((64'b1)<<I_IR[21:16]));
			end
			`OP_VMOVI:
			begin
				O_Imm <= $signed(Imm32);
				O_DestRegIdxV <= I_IR[21:16];
				VRF_VALID = (VRF_VALID & ~((64'b1)<<I_IR[21:16]));
			end
			`OP_VCOMPMOV:
			begin
				O_DestValue <= RF[I_IR[11:8]];
				O_DestRegIdxV_Idx <= I_IR[23:22];
				O_DestRegIdxV     <= I_IR[21:16];
				VRF_VALID = (VRF_VALID & ~((64'b1)<<I_IR[21:16]));
			end
			`OP_VCOMPMOVI:
			begin
				O_Imm <= $signed(Imm32);
				O_DestRegIdxV_Idx <= I_IR[23:22];
				O_DestRegIdxV     <= I_IR[21:16];
				VRF_VALID = (VRF_VALID & ~((64'b1)<<I_IR[21:16]));
			end
			// GPU 
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= VRF[I_IR[21:16]];
			end
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_IR[19:16];
			end
			endcase	
			
			// for OP_PUSHMATRIX, OP_POPMATRIX, OP_FLUSH, OP_LOADIDENTITY, OP_ENDPRIMITIVE
			// just pass the opcode
	
	 end // end else if (__DepStallSignal==1'b0)
	 
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1; // I_FetchStall;
end // always @(negedge I_CLOCK)

/////////////////////////////////////////
// COMBINATIONAL LOGIC GOES HERE
/////////////////////////////////////////
//
SignExtension SE0(.In(I_IR[15:0]), .Out(Imm32));

endmodule // module Decode
