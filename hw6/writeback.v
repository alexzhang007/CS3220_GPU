`include "global_def.h"

module Writeback(
  I_CLOCK,
  I_LOCK,
  I_Opcode,
  I_ALUOut,
  I_MemOut,
  I_DestRegIdx,
  I_FetchStall,
  I_DepStall,
  
  O_LOCK,
  
  O_Opcode,
  
  O_WriteBackEnable,
  O_WriteBackRegIdx,
  O_WriteBackData,

  O_WriteBackEnableV,
  O_WriteBackRegIdxV,
  O_WriteBackDataV,
  
  O_VR, // to Geometry Stage

  O_FetchStall,
  O_DepStall  
);

/////////////////////////////////////////
// IN/OUT DEFINITION GOES HERE
/////////////////////////////////////////
//
// Inputs from the memory stage
input I_CLOCK;
input I_LOCK;
input I_FetchStall;
input I_DepStall;
input [`OPCODE_WIDTH-1:0] I_Opcode;
input [3:0] I_DestRegIdx;
input [`REG_WIDTH-1:0] I_ALUOut;
input [`REG_WIDTH-1:0] I_MemOut;


// Outputs to the decode stage
output O_WriteBackEnable;
output [3:0] O_WriteBackRegIdx;
output [`REG_WIDTH-1:0] O_WriteBackData;

output O_WriteBackEnableV;
output [5:0] O_WriteBackRegIdxV;
output [1:0] O_WriteBackRegIdxV_Idx;
output [`VREG_WIDTH-1:0] O_WriteBackDataV;

output [`OPCODE_WIDTH-1:0] O_Opcode;

output O_FetchStall;
output O_DepStall;

/////////////////////////////////////////
// ## Note ##
// - Assign output signals depending on opcode.
// - A few examples are provided.
/////////////////////////////////////////
assign O_WriteBackEnable = 
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
      (I_Opcode == `OP_ADD_D  ) ? (1'b1) :
      (I_Opcode == `OP_ADDI_D ) ? (1'b1) :
	   (I_Opcode == `OP_AND_D  ) ? (1'b1) :
      (I_Opcode == `OP_ANDI_D ) ? (1'b1) :
	   (I_Opcode == `OP_MOV    ) ? (1'b1) :
	   (I_Opcode == `OP_MOVI_D ) ? (1'b1) :
	   (I_Opcode == `OP_LDW    ) ? (1'b1) :
	   (I_Opcode == `OP_JSR    ) ? (1'b1) : 
      (I_Opcode == `OP_JSRR   ) ? (1'b1) : 
		// vector operaitons
		(I_Opcode == `OP_VCOMPMOV  ) ? (1'b1) : 
	   (I_Opcode == `OP_VCOMPMOVI ) ? (1'b1) : 
	     (1'b0)
    ): (1'b0)):
	 (1'b0));

assign O_WriteBackRegIdx = 
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_ADD_D  ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_ADDI_D ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_AND_D  ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_ANDI_D ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_MOV    ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_MOVI_D ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_LDW    ) ? (I_DestRegIdx) :
		(I_Opcode == `OP_JSR    ) ? (I_DestRegIdx) : 
		(I_Opcode == `OP_JSRR   ) ? (I_DestRegIdx) :  
        (4'hX)
    ): (4'hX)):
	 (4'hX));

assign O_WriteBackData = 
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_ADD_D ) ? (I_ALUOut) :
		(I_Opcode == `OP_ADDI_D) ? (I_ALUOut) :
		(I_Opcode == `OP_AND_D ) ? (I_ALUOut) :
		(I_Opcode == `OP_ANDI_D) ? (I_ALUOut) :
		(I_Opcode == `OP_MOV   ) ? (I_ALUOut) :
		(I_Opcode == `OP_MOVI_D) ? (I_ALUOut) :
		(I_Opcode == `OP_LDW   ) ? (I_MemOut) :
		(I_Opcode == `OP_JSR   ) ? (I_ALUOut) :
		(I_Opcode == `OP_JSRR  ) ? (I_ALUOut) :
		
		// below operations depend on both WritebackEnableV and WritebackEnable
		(I_Opcode == `OP_VCOMPMOV  ) ? (I_ALUOut) :
	   (I_Opcode == `OP_VCOMPMOVI ) ? (I_ALUOut) :
		
		  (16'hXXXX)
    ): (16'hXXXX)):
	 (16'hXXXX));

// vector operations
assign O_WriteBackEnableV = 
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_VADD      ) ? (1'b1) :
	   (I_Opcode == `OP_VMOV      ) ? (1'b1) : 
	   (I_Opcode == `OP_VCOMPMOV  ) ? (1'b1) :
	   (I_Opcode == `OP_VCOMPMOVI ) ? (1'b1) :
	     (1'b0)
    ): (1'b0)):
	 (1'b0));

assign O_WriteBackRegIdxV = // 6 bits
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_VADD      ) ? (I_DestRegIdxV) :
	   (I_Opcode == `OP_VMOV      ) ? (I_DestRegIdxV) : 
	   (I_Opcode == `OP_VCOMPMOV  ) ? (I_DestRegIdxV) :
	   (I_Opcode == `OP_VCOMPMOVI ) ? (I_DestRegIdxV) :
        (6'bXXXXXX)
    ): (6'bXXXXXX)):
	 (6'bXXXXXX));

assign O_WriteBackRegIdxV_Idx = // 2bits
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_VCOMPMOV  ) ? (I_DestRegIdxV_Idx) :
	   (I_Opcode == `OP_VCOMPMOVI ) ? (I_DestRegIdxV_Idx) :
        (2'bXX)
    ): (2'bXX)):
	 (2'bXX));

assign O_WriteBackDataV = 
  ((I_LOCK == 1'b1) ? (
	((I_FetchStall==1'b0) && (I_DepStall == 1'b0)) ? 
    (
	   (I_Opcode == `OP_VADD      ) ? (I_ALUOutV) :
	   (I_Opcode == `OP_VMOV      ) ? (I_ALUOutV) : 
		  (64'hXXXXXXXXXXXXXXXX)
    ): (64'hXXXXXXXXXXXXXXXX)):
	 (64'hXXXXXXXXXXXXXXXX));

endmodule // module Writeback
