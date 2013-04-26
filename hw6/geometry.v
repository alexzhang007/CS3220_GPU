`include "global_def.h"
  
module Geometry(
  
  /* inputs */
  I_CLOCK,
  I_LOCK,
  I_PC,
  I_Opcode,
  I_FetchStall,
  I_DepStall,
  
  I_Type, 
  
  // vectors
  I_VR,
  
  /* outputs */
  O_LOCK,
  O_ALUOut,
  O_Opcode,
  O_DestRegIdx,
  O_DestValue,
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

input [`VREG_WIDTH-1:0] I_VR;

input [3:0] I_Type;

output reg O_LOCK;
output reg [`OPCODE_WIDTH-1:0] O_Opcode;
output reg O_FetchStall;
output reg O_DepStall;

/////////////////////////////////////////
// WIRE/REGISTER DECLARATION GOES HERE
/////////////////////////////////////////
//

// 16 bit in 1.8.7 format
reg[`DATA_WIDTH-1:0] SinTable[0:72];
reg[`DATA_WIDTH-1:0] CosTable[0:72];


// wire[`MATRIX_SIZE-1:0] Vertex_Curr;

// signals
reg _BeginPrimitive;
reg _EndPrimitive;
reg _PushMatrix;
reg _PopMatrix;

// matrix
wire [255:0] Matrix_Curr;
wire [255:0] Matrix_In;

wire [15:0] M11;
wire [15:0] M12;
wire [15:0] M13;
wire [15:0] M14;
wire [15:0] M21;
wire [15:0] M22;
wire [15:0] M23;
wire [15:0] M24;
wire [15:0] M31;
wire [15:0] M32;
wire [15:0] M33;
wire [15:0] M34;
wire [15:0] M41;
wire [15:0] M42;
wire [15:0] M43;
wire [15:0] M44;

reg [1:0] Num_Matrices;
reg [255:0] MatrixStack [0:1]; 

// angle
wire [7:0] Angle; // 8 bit integer 
wire Z_Value; // sign (since it's fixed point, only bit-15 matters)
	
// sine and cosine
wire[15:0] Sine_Value;   // odd, 
wire[15:0] Cosine_Value; // even, ignore sine: Theta[14:7]

wire [63:0] Vertex_Curr;
reg  [127:0] Vertex_Array [0:8];
reg  [3:0]   Vertex_Idx;


// indices of color array corresponds to that of vertex array
// set colors
wire [63:0] Color_Curr;
// reg  [63:0] Color_Array [0:4];
// reg  [4:0]  Num_Colors;

// translate

// scale

// matrix
	
/////////////////////////////////////////
// INITIAL STATEMENT GOES HERE
/////////////////////////////////////////
//
initial 
begin
  $readmemh("sine_table.hex", SinTable);
  $readmemh("cosine_table.hex", CosTable);
  
  _BeginPrimitive = 1'b0;
  _EndPrimitive   = 1'b0;
  _PushMatrix     = 1'b0;
  _PopMatrix      = 1'b0;
  
  Matrix_Curr = `ID_MATRIX;
  Matrix_In = `ID_MATRIX;
  
  M11 = `FIXED_POINT_1;
  M22 = `FIXED_POINT_1; 
  M33 = `FIXED_POINT_1;
  M44 = `FIXED_POINT_1;
  
  M12 = 16'b0;
  M13 = 16'b0;
  M14 = 16'b0;
  M21 = 16'b0;
  M23 = 16'b0;
  M24 = 16'b0;
  M31 = 16'b0;
  M32 = 16'b0;
  M34 = 16'b0;
  M41 = 16'b0;
  M42 = 16'b0;
  M43 = 16'b0;
    
  Vertex_Idx = 0;
  Num_Matrices = 0;
    
end


/////////////////////////////////////////
// INITIAL/ASSIGN STATEMENT GOES HERE
/////////////////////////////////////////
//

// vector
//
// [ elmt0 ] => [ 15:0  ]
// | elmt1 | => | 31:16 |
// | elmt2 | => | 47:32 |
// [ elmt3 ] => [ 63:48 ]

assign Z_Value = // vr[3]
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_VR[63] // assuming that it's the sign bit
				): (1'bX)	
			): (1'bX) // end I_DepStall
		): (1'bX) // end I_FetchStall
	): (1'bX); // end I_LOCK

// assume Anlge = [0,36]
assign Angle = // vr[0] 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					I_DestValueV[14:7]; // grab 8 int bits from 15:0
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK


// index the trig tables using Z_Value and Angle 
// if      Angle == 0,   index == Angle
// else if Z_Value == 1, index == Angle + 36
// else                  index == Angle
	
assign Sine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					(Angle==8'h0) ?
					(
						SinTable[Angle]
					): 
					(Z_Value==1'b1) ?
					(
						SinTable[Angle+36]
					): (SinTable[Angle])
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK

assign Cosine_Value = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					(Angle==8'h0) ?
					(
						CosTable[Angle]
					): 
					(Z_Value==1'b1) ?
					(
						CosTable[Angle+36]
					): (CosTable[Angle])
				): (16'hXXXX)	
			): (16'hXXXX) // end I_DepStall
		): (16'hXXXX) // end I_FetchStall
	): (16'hXXXX); // end I_LOCK

	
// ##################
// ## SET VERTICES ##		  
// ##################

// Matrix Assignments
// 	
// [ [ 15:0  ] [ 31:16 ] [ 47:32 ] [ 63:48 ] ]
// | [ 79:64 ] [ 95:80 ] [111:96 ] [127:112] |
// | [143:128] [159:144] [175:160] [191:176] |
// [ [207:192] [223:208] [239:224] [255:240] ]

// vector
//
// [ elmt0 ] => [ 15:0  ]
// | elmt1 | => | 31:16 |
// | elmt2 | => | 47:32 |
// [ elmt3 ] => [ 63:48 ]

// The value of vr[1]: X coordinate
// The value of vr[2]: Y coordinate
// The value of vr[3]: Z coordinate
assign Vertex_Curr = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_SETVERTEX) ? 
				(
					{I_VR[31:16], I_VR[47:32], I_VR[63:48], `FIXED_POINT_1}
				): (64'hXXXXXXXXXXXXXXXX)	
			): (64'hXXXXXXXXXXXXXXXX) // end I_DepStall
		): (64'hXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (64'hXXXXXXXXXXXXXXXX); // end I_LOCK



// ################
// ## SET COLORS ##		  
// ################

assign Color_Curr = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_SETCOLOR) ? 
				(
					{I_VR[15:0], I_VR[31:16], I_VR[47:32], 16'b0}
				): (64'hXXXXXXXXXXXXXXXX)	
			): (64'hXXXXXXXXXXXXXXXX) // end I_DepStall
		): (64'hXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (64'hXXXXXXXXXXXXXXXX); // end I_LOCK


// ###############
// ## TRANSLATE ##		  
// ###############

// vr[1]=I_VR[31:16]: distance to move on x-axis
// vr[2]=I_VR[47:32]: distance to move on y-axis

// [ 1   0   0   t_x ]
// | 0   1   0   t_y |
// | 0   0   1    0  |
// [ 0   0   0    1  ] 

assign Matrix_In = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_TRANSLATE) ? 
				(
					{`FIXED_POINT_1, 16h'0, 16h'0, I_VR[31:16], 16'h0, `FIXED_POINT_1, 16'h0, I_VR[47:32], 16'h0, 16'h0, `FIXED_POINT_1, 16'h0, 16'h0, 16'h0, `FIXED_POINT_1}
				): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)	
			): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_DepStall
		): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX); // end I_LOCK

// ###########
// ## SCALE ##		  
// ###########

// [ s_x  0    0    0 ]
// |  0  s_y   0    0 |
// |  0   0   s_z   0 |
// [  0   0    0    1 ] 

assign Matrix_In = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_SCALE) ? 
				(
					{I_VR[31:16], 16h'0, 16h'0, 16h'0, 16'h0, I_VR[47:32], 16'h0, 16'h0, 16'h0, 16'h0, `FIXED_POINT_1, 16'h0, 16'h0, 16'h0, `FIXED_POINT_1}
				): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)	
			): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_DepStall
		): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX); // end I_LOCK

// ############
// ## ROTATE ##		  
// ############

// [  cos  sin   0    0 ]
// | -sin  cos   0    0 |
// |   0    0    1    0 |
// [   0    0    0    1 ] 

assign Matrix_In = 
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ? 
		(
			(I_DepStall==1'b0) ? 
			(
				(I_Opcode==`OP_ROTATE) ? 
				(
					{Cosine_Value, Sine_Value, 16h'0, 16h'0, (-1)*Sin_Value, Cosine_Value, 16'h0, 16'h0, 16'h0, 16'h0, `FIXED_POINT_1, 16'h0, 16'h0, 16'h0, `FIXED_POINT_1}
				): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)	
			): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_DepStall
		): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX); // end I_LOCK


// Matrix Assignments
// 	
// [ [ 15:0  ] [ 31:16 ] [ 47:32 ] [ 63:48 ] ]
// | [ 79:64 ] [ 95:80 ] [111:96 ] [127:112] |
// | [143:128] [159:144] [175:160] [191:176] |
// [ [207:192] [223:208] [239:224] [255:240] ]
// 
assign Matrix_Curr =
	(I_LOCK==1'b1) ? 
	(
		(I_FetchStall==1'b0) ?
		(
			(I_DepStall==1'b0) ?
			(
				(I_Opcode==`OP_ROTATE) ?
				( 
					// [  cos  sin   0    0 ]
					// | -sin  cos   0    0 |
					// |   0    0    1    0 |
					// [   0    0    0    1 ] 
					{M44, M43, M41*Sine_Value+M42*Cosine_Value, M41*Cosine_Value+M42*(-1)*Sine_Value, M34, M33, M31+M32}
					
				):
				(I_Opcode==`OP_TRANSLATE) ?
				(
					// [ s_x  0    0    0 ]
					// |  0  s_y   0    0 |
					// |  0   0   s_z   0 |
					// [  0   0    0    1 ] 

				):
				(I_Opcode==`OP_TRANSLATE) ?
				(
					// [ 1   0   0   t_x ]
					// | 0   1   0   t_y |
					// | 0   0   1    0  |
					// [ 0   0   0    1  ] 
				
				): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)
			): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_DepStall
		): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX) // end I_FetchStall
	): (256'hXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX); // end I_LOCK

// Matrix Assignments
// 	
// [ [ 15:0  ] [ 31:16 ] [ 47:32 ] [ 63:48 ] ]
// | [ 79:64 ] [ 95:80 ] [111:96 ] [127:112] |
// | [143:128] [159:144] [175:160] [191:176] |
// [ [207:192] [223:208] [239:224] [255:240] ]

assign M11 = Matrix_Curr[15:0];
assign M12 = Matrix_Curr[31:16];
assign M13 = Matrix_Curr[47:32];
assign M14 = Matrix_Curr[63:48];
assign M21 = Matrix_Curr[79:64];
assign M22 = Matrix_Curr[95:80];
assign M23 = Matrix_Curr[111:96];
assign M24 = Matrix_Curr[127:112];
assign M31 = Matrix_Curr[143:128];
assign M32 = Matrix_Curr[159:144];
assign M33 = Matrix_Curr[175:160];
assign M34 = Matrix_Curr[191:176];
assign M41 = Matrix_Curr[207:192];
assign M42 = Matrix_Curr[223:208];
assign M43 = Matrix_Curr[239:224];
assign M44 = Matrix_Curr[255:240];
	
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

	   O_Opcode <= I_Opcode;
		O_DepStall <= 1'b0;
		O_FetchStall <= 1'b0;
		
		// if SETVERTEX, form a triangle
		
		// if BEGINPRIMITIVE, enable _BeginPrimitive
	 
	   case (I_Opcode)
		  	// GPU 
			`OP_BEGINPRIMITIVE:
			begin
				O_Type <= I_Type;
				_BeginPrimitive <= 1'b1;
			end
			`OP_SETVERTEX: // assuming that the matrix has been set
			begin
				Vertex_List[Vertex_Idx] <= {Vertex_Curr, Color_Curr};
				Vertex_Idx <= Vertex_Idx + 1;
			end
			/*
			`OP_SETCOLOR:
			begin
				
			end
			*/
			`OP_PUSHMATRIX:
			begin
				
			end
			`OP_ROTATE:
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
			`OP_ENDPRIMITIVE:
			begin
				O_Type <= I_Type; // 3 or 4
			end
		endcase
			 
	 end // if (I_FetchStall==1'b0 && I_DepStall==1'b0)
	 else O_DepStall <= 1'b1;
	 
  end // if (I_LOCK == 1'b1)
  else O_FetchStall <= 1'b1;
  
end // always @(negedge I_CLOCK)

endmodule // module geometry