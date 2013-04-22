`include "global_def.h"
  
module Rasterize(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_Opcode, // DRAW
  
  // vertices for 3 triangles
  I_T1_V1,
  I_T1_V2,
  I_T1_V3,
  
  I_T2_V1,
  I_T2_V2,
  I_T2_V3,
  
  I_T3_V1,
  I_T3_V2,
  I_T3_V3,
  
  // corresponding colors
  I_T1_C1, // how many bits????
  I_T1_C2,
  I_T1_C3,
  
  I_T2_C1,
  I_T2_C2,
  I_T2_C3,
  
  I_T3_C1,
  I_T3_C2,
  I_T3_C3,
   
  // vectors
  I_DestValueV,
  
  /* outputs */
  O_LOCK,
  O_ALUOut,
  O_Opcode,
  O_DestRegIdx,
  O_DestValue,

  // stall and/or flush
  O_RasterizerStall_F,
  O_RasterizerStall_D,
  O_RasterizerStall_E,
  O_RasterizerStall_M,
  O_RasterizerStall_W,
  O_RasterizerStall_V
  
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

// vertices for 3 triangles
input [63:0] I_T1_V1;
input [63:0] I_T1_V2,
input [63:0] I_T1_V3,
  
input [63:0] I_T2_V1,
input [63:0] I_T2_V2,
input [63:0] I_T2_V3,
  
input [63:0] I_T3_V1,
input [63:0] I_T3_V2,
input [63:0] I_T3_V3,
  
// corresponding colors
  I_T1_C1,
  I_T1_C2,
  I_T1_C3,
  
  I_T2_C1,
  I_T2_C2,
  I_T2_C3,
  
  I_T3_C1,
  I_T3_C2,
  I_T3_C3,


// Outputs to the next stage
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

always @(negedge I_CLOCK)
begin
  O_LOCK <= I_LOCK;
  // O_FetchStall <= I_FetchStall;

  if (I_LOCK == 1'b1) 
  begin
    	 
	  
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1;
  
end // always @(negedge I_CLOCK)

endmodule // module Rasterize
