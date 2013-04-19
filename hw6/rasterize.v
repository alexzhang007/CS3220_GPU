`include "global_def.h"
  
module Rasterize(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_Opcode,
  I_Src1Value,
  I_Src2Value,
  I_DestRegIdx,
  I_Imm,
  I_DestValue,
  I_FetchStall,
  I_DepStall,
  
  // vectors
  I_DestValueV,
  
  /* outputs */
  O_LOCK,
  O_ALUOut,
  O_Opcode,
  O_DestRegIdx,
  O_DestValue,
  // Stall Signals
  O_FetchStall,
  O_DepStall,
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
input [3:0] O_Type;

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


// [ [255:240] [239:224] [223:208] [207:192] ]
// | [191:176] [175:160] [159:144] [143:128] |
// | [127:112] [111:96 ] [ 95:80 ] [ 79:64 ] |
// [ [ 63:48 ] [ 47:32 ] [ 31:16 ] [ 15:0  ] ]

wire [255:0] Attribute_Matrix;
wire [255:0] Rotate_Matrix;
wire [255:0] Scale_Matrix;
wire [255:0] Translate_Matrix;

assign Rotate_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_ROTATE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK

assign Scale_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_SCALE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK

assign Translate_Matrix = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_TRANSLATE) ? 
				(
					// logic goes here
				): (`ID_MATRIX)
				
			): (`ID_MATRIX) // end I_DepStall
		): (`ID_MATRIX) // end I_FetchStall
	): (`ID_MATRIX); // end I_LOCK	


// [x] [63:48] 
// |y| [47:32]
// |z| [31:16] 0
//	[a] [15:0 ] 0
wire [63:0] Vertex_Vector;
assign Vertex_Vector = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				
				(I_Opcode==`OP_SETVERTEX) ? 
				(
					// logic goes here
				): (`VERTEX_INIT)
				
			): (`VERTEX_INIT) // end I_DepStall
		): (`VERTEX_INIT) // end I_FetchStall
	): (`VERTEX_INIT); // end I_LOCK	

	
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
    	 
	  if (I_FetchStall==1'b0 && I_DepStall==1'b0) begin
	 
		O_DestValue <= I_DestValue;
	   O_DestRegIdx <= I_DestRegIdx;
	   O_Opcode <= I_Opcode;
		O_DepStall <= 1'b0;
		O_FetchStall <= 1'b0;
	 
	   case (I_Opcode)
		  	// GPU 
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_SETVERTEX, `OP_SETCOLOR, `OP_ROTATE, `OP_TRANSLATE, `OP_SCALE:
			begin
				O_DestValueV <= I_DestValueV;
			end
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_IR[19:16];
			end
		endcase
			 
	 end // if (I_FetchStall==1'b0 && I_DepStall==1'b0)
	 else O_DepStall <= 1'b1;
	 
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1;
  
end // always @(negedge I_CLOCK)

endmodule // module Rasterize
