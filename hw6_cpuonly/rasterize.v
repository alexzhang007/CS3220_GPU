`include "global_def.h"
  
module Rasterize(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_Opcode, // DRAW
  I_RST_N,
  
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
input [63:0] I_T1_V2;
input [63:0] I_T1_V3;
  
input [63:0] I_T2_V1;
input [63:0] I_T2_V2;
input [63:0] I_T2_V3;
  
input [63:0] I_T3_V1;
input [63:0] I_T3_V2;
input [63:0] I_T3_V3;
  
// corresponding colors
// likely to be the same
input [15:0] I_T1_C1;
input [15:0] I_T1_C2;
input [15:0] I_T1_C3;
  
input [15:0] I_T2_C1;
input [15:0] I_T2_C2;
input [15:0] I_T2_C3;
  
input [15:0] I_T3_C1;
input [15:0] I_T3_C2;
input [15:0] I_T3_C3;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

// The value of vr[1]: X coordinate [31:16]
// The value of vr[2]: Y coordinate [47:32]
// The value of vr[3]: Z coordinate [63:48]

// triangle 1
wire [15:0] Tri1_X1;
wire [15:0] Tri1_Y1;
wire [15:0] Tri1_Z1;
wire [15:0] Tri1_X2;
wire [15:0] Tri1_Y2;
wire [15:0] Tri1_Z2;
wire [15:0] Tri1_X3;
wire [15:0] Tri1_Y3;
wire [15:0] Tri1_Z3;

// triangle 2
wire [15:0] Tri2_X1;
wire [15:0] Tri2_Y1;
wire [15:0] Tri2_Z1;
wire [15:0] Tri2_X2;
wire [15:0] Tri2_Y2;
wire [15:0] Tri2_Z2;
wire [15:0] Tri2_X3;
wire [15:0] Tri2_Y3;
wire [15:0] Tri2_Z3;

// triangle 3
wire [15:0] Tri3_X1;
wire [15:0] Tri3_Y1;
wire [15:0] Tri3_Z1;
wire [15:0] Tri3_X2;
wire [15:0] Tri3_Y2;
wire [15:0] Tri3_Z2;
wire [15:0] Tri3_X3;
wire [15:0] Tri3_Y3;
wire [15:0] Tri3_Z3;

assign Tri1_X1 = I_T1_V1[31:16];
assign Tri1_Y1 = I_T1_V1[47:32];
assign Tri1_Z1 = I_T1_V1[63:48];
assign Tri1_X2 = I_T1_V2[31:16];
assign Tri1_Y2 = I_T1_V2[47:32];
assign Tri1_Z2 = I_T1_V2[63:48];
assign Tri1_X3 = I_T1_V3[31:16];
assign Tri1_Y3 = I_T1_V3[47:32];
assign Tri1_Z3 = I_T1_V3[63:48];

assign Tri2_X1 = I_T2_V1[31:16];
assign Tri2_Y1 = I_T2_V1[47:32];
assign Tri2_Z1 = I_T2_V1[63:48];
assign Tri2_X2 = I_T2_V2[31:16];
assign Tri2_Y2 = I_T2_V2[47:32];
assign Tri2_Z2 = I_T2_V2[63:48];
assign Tri2_X3 = I_T2_V3[31:16];
assign Tri2_Y3 = I_T2_V3[47:32];
assign Tri2_Z3 = I_T2_V3[63:48];

assign Tri3_X1 = I_T3_V1[31:16];
assign Tri3_Y1 = I_T3_V1[47:32];
assign Tri3_Z1 = I_T3_V1[63:48];
assign Tri3_X2 = I_T3_V2[31:16];
assign Tri3_Y2 = I_T3_V2[47:32];
assign Tri3_Z2 = I_T3_V2[63:48];
assign Tri3_X3 = I_T3_V3[31:16];
assign Tri3_Y3 = I_T3_V3[47:32];
assign Tri3_Z3 = I_T3_V3[63:48];
	
/////////////////////////////////////////
// ALWAYS STATEMENT GOES HERE
/////////////////////////////////////////
//

always @(posedge I_CLK or negedge I_RST_N)
begin
	if (!I_RST_N) 
	begin
		// logic goes here
	end 
	else	
	begin
		// 
	end
end


always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    colInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd < 639)
        colInd <= colInd + 1;
      else
        colInd <= 0;
    end
  end
end

always @(posedge I_CLK or negedge I_RST_N)
begin
  if (!I_RST_N) begin
    rowInd <= 0;
  end else begin
    if (!I_VIDEO_ON) begin
      if (colInd == 0) begin
        if (rowInd < 399)
          rowInd <= rowInd + 1;
        else
          rowInd <= 0;
      end
    end
  end
end

endmodule // module Rasterize
