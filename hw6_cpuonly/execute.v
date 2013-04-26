`include "global_def.h"
  
module Execute(
  I_CLOCK,
  I_LOCK,
  
  I_PC,
  I_Opcode,
  
  I_Imm,
  I_Type,
  // scalar
  I_Src1Value,
  I_Src2Value,
  I_DestValue,
  I_DestRegIdx,
  
  // vector
  I_Src1ValueV,
  I_Src2ValueV,
  I_DestValueV,
  
  I_DestRegIdxV,
  I_DestRegIdxV_Idx,
    
  I_FetchStall,
  I_DepStall,
  
  O_LOCK,
  O_Opcode,
  
  // scalar out
  O_ALUOut,
  O_DestValue,
  O_DestRegIdx,
  
  // vector out
  O_ALUOutV,
  O_DestValueV,
  O_DestRegIdxV,
  O_DestRegIdxV_Idx,
  
  O_Type,
  
  O_FetchStall,
  O_DepStall
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the decode stage
input I_CLOCK;
input I_LOCK;
input [`PC_WIDTH-1:0] I_PC;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input I_FetchStall;
input I_DepStall;

input [`REG_WIDTH-1:0] I_Imm;

// scalar
input [3:0] I_DestRegIdx;
input [`REG_WIDTH-1:0] I_Src1Value;
input [`REG_WIDTH-1:0] I_Src2Value;
input [`REG_WIDTH-1:0] I_DestValue;

// vector
input [5:0] I_DestRegIdxV;
input [1:0] I_DestRegIdxV_Idx;
input [`VREG_WIDTH-1:0] I_Src1ValueV;
input [`VREG_WIDTH-1:0] I_Src2ValueV;
input [`VREG_WIDTH-1:0] I_DestValueV;

// GPU
input [3:0] I_Type;

// Outputs to the memory stage
output reg O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg O_FetchStall;
output reg O_DepStall;

// scalar
output reg [`REG_WIDTH-1:0] O_ALUOut;
output reg [3:0] O_DestRegIdx;
output reg [`REG_WIDTH-1:0] O_DestValue;

// vector
output reg [`VREG_WIDTH-1:0] O_ALUOutV;
output reg [`VREG_WIDTH-1:0] O_DestValueV;
output reg [5:0] O_DestRegIdxV;
output reg [1:0] O_DestRegIdxV_Idx;

// GPU
output reg [3:0] O_Type;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

/////////////////////////////////////////
// ## Note ##
// - Do the appropriate ALU operations.
/////////////////////////////////////////
always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  // O_FetchStall <= I_FetchStall;

  if (I_LOCK == 1'b1) 
  begin
    	 
	  if (I_FetchStall==1'b0 && I_DepStall==1'b0) begin
	 
		O_DestValue <= I_DestValue;
	   O_DestRegIdx <= I_DestRegIdx;
	   O_Opcode <= I_Opcode;
		O_DepStall <= 1'b0;
		O_FetchStall <= 1'b0;
	 
	   case (I_Opcode)
		  `OP_ADD_D:  O_ALUOut <= $signed(I_Src1Value) + $signed(I_Src2Value);
		  `OP_ADDI_D: O_ALUOut <= $signed(I_Src1Value) + $signed(I_Imm);
		  `OP_AND_D:  O_ALUOut <= I_Src1Value & I_Src2Value;
		  `OP_ANDI_D: O_ALUOut <= I_Src1Value & $signed(I_Imm);
		  `OP_MOV:    O_ALUOut <= I_Src2Value;	
		  `OP_MOVI_D: O_ALUOut <= $signed(I_Imm);
		  `OP_ADD_F:  O_ALUOut <= I_Src1Value + I_Src2Value;
		  `OP_ADD_F:  O_ALUOut <= I_Src1Value + I_Imm;
		  `OP_MOVI_F: O_ALUOut <= I_Imm;
		  `OP_LDW: O_ALUOut    <= I_Src1Value + $signed(I_Imm);
		  `OP_STW: O_ALUOut    <= I_Src1Value + $signed(I_Imm);    
		  `OP_BRN, `OP_BRZ, `OP_BRP, `OP_BRNZ, `OP_BRZP, `OP_BRNP, `OP_BRNZP: O_ALUOut <= I_PC + $signed(I_Imm);
		  `OP_JSR: O_ALUOut    <= I_PC + $signed(I_Imm);
		  `OP_JMP: O_ALUOut    <= I_DestValue;
		  `OP_JSRR: O_ALUOut   <= I_DestValue;
		  // vector
		  //
		  // [ elmt0 ] => [ 15:0  ]
		  // | elmt1 | => | 31:16 |
		  // | elmt2 | => | 47:32 |
		  // [ elmt3 ] => [ 63:48 ]
		  `OP_VADD:
			begin
				// O_DestValueV <= ((I_Src1ValueV[63:48] + I_Src1ValueV[63:48])<<`VDEST3) | ((I_Src1ValueV[47:32] + I_Src1ValueV[47:32])<<`VDEST2) | ((I_Src1ValueV[31:16] + I_Src1ValueV[31:16])<<`VDEST1) | ((I_Src1ValueV[15:0] + I_Src1ValueV[15:0])<<`VDEST0);
				O_ALUOutV  <= {(I_Src1ValueV[63:48] + I_Src1ValueV[63:48]), 
				               (I_Src1ValueV[47:32] + I_Src1ValueV[47:32]), 
									(I_Src1ValueV[31:16] + I_Src1ValueV[31:16]), 
									(I_Src1ValueV[15:0]  + I_Src1ValueV[15:0] )};
				O_DestRegIdxV <= I_DestRegIdxV;
			end
			`OP_VMOV:
			begin
				O_ALUOutV     <= I_DestValueV;
				O_DestRegIdxV <= I_DestRegIdxV;
			end
			`OP_VMOVI:
			begin
				O_ALUOutV     <= I_DestValueV;
				O_DestRegIdxV <= I_DestRegIdxV;
			end
			`OP_VCOMPMOV: // dest[idx] <- src
			begin
				O_ALUOut          <= I_DestValue; // scalar
				O_DestRegIdxV_Idx <= I_DestRegIdxV_Idx;
				O_DestRegIdxV     <= I_DestRegIdxV;
			end
			`OP_VCOMPMOVI: // dest[idx] <- imm16
			begin
				O_ALUOut          <= $signed(I_Imm);
				O_DestRegIdxV_Idx <= I_DestRegIdxV_Idx;
				O_DestRegIdxV     <= I_DestRegIdxV;
			end
			// GPU 
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_Type;
			end
		endcase
			 
	 end // if (I_FetchStall==1'b0 && I_DepStall==1'b0)
	 else O_DepStall <= 1'b1;
	 
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1;
  
end // always @(negedge I_CLOCK)

endmodule // module Execute
