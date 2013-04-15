#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <bitset>
#include <stdint.h>
#include <cstring>
#include <limits.h>
#include <math.h>
#include "simulator.h"

//#define DEBUG 
//#define GRAPH_DEBUG 

using namespace std;

///////////////////////////////////////////////////////////////
//  global variable definition goes here
///////////////////////////////////////////////////////////////
//
ScalarRegister g_condition_code_register;
ScalarRegister g_scalar_registers[NUM_SCALAR_REGISTER];
VectorRegister g_vector_registers[NUM_VECTOR_REGISTER];

unsigned char g_memory[MEMORY_SIZE];
vector<TraceOp> g_trace_ops;

unsigned int g_instruction_count = 0;

// Assumption - destination : 16 matrix = 16 X 20 scalar registers
Matrix g_current_matrix;
Matrix* g_matrix_stack;
int g_matrix_stack_ptr;

Vertex g_current_vertex;
Triangle g_current_triangle;

Fragment** g_fragment_buffer;
int g_fragment_begin_x;
int g_fragment_end_x;
int g_fragment_begin_y;
int g_fragment_end_y;

Pixel** g_frame_buffer;

bool g_is_setvertex; 
bool g_is_begin_primitive; 
bool g_is_end_primitive;
bool g_is_draw; 


///////////////////////////////////////////////////////////////
// Function Implementation goes here 
///////////////////////////////////////////////////////////////
//
void InitializeGpuVariables(void) {
  g_is_setvertex = false; 
  g_is_begin_primitive = false; 
  g_is_end_primitive = false; 
  g_is_draw = false; 

	// g_current_matrix initialization
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      g_current_matrix.mat[j][k] = 0;
      if (j == k) {
        g_current_matrix.mat[j][k] = 1;
      }
    }
  }
  g_current_matrix.r = 0;
	g_current_matrix.g = 0;
	g_current_matrix.b = 0;
	g_current_matrix.a = 0;

  // g_matrix_stack initialization
  g_matrix_stack = new Matrix[16];
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        g_matrix_stack[i].mat[j][k] = 0;
        if (j == k) {
          g_matrix_stack[i].mat[j][k] = 1;
        }
      }
    }
    g_matrix_stack[i].r = 0;
    g_matrix_stack[i].g = 0;
    g_matrix_stack[i].b = 0;
    g_matrix_stack[i].a = 0;
  }
  g_matrix_stack_ptr = -1;

  // g_current_vertex initialization
  g_current_vertex.x = 0;
  g_current_vertex.y = 0;
  g_current_vertex.z = 0;
  g_current_vertex.w = 1;
  g_current_vertex.r = 0;
  g_current_vertex.g = 0;
  g_current_vertex.b = 0;
  g_current_vertex.a = 0;

  // g_current_triangle initialization
  g_current_triangle.current_vertex = 0;
  for (int i = 0; i < 3; i++) {
    g_current_triangle.v[i].x = 0;
    g_current_triangle.v[i].y = 0;
    g_current_triangle.v[i].z = 0;
    g_current_triangle.v[i].w = 1;
    g_current_triangle.v[i].r = 0;
    g_current_triangle.v[i].g = 0;
    g_current_triangle.v[i].b = 0;
    g_current_triangle.v[i].a = 0;
  }

  // g_fragment_buffer initialization
  g_fragment_buffer = new Fragment*[400];
  for (int i = 0; i < 400; i++) {
    g_fragment_buffer[i] = new Fragment[640];
  }

  for (int i = 0; i < 400; i++) {
    for (int j = 0; j < 640; j++) {
      g_fragment_buffer[i][j].depth = 3;
      g_fragment_buffer[i][j].r = 0;
      g_fragment_buffer[i][j].g = 0;
      g_fragment_buffer[i][j].b = 0;
      g_fragment_buffer[i][j].a = 0;
    }
  }
  g_fragment_begin_x = 0;
  g_fragment_end_x = 0;
  g_fragment_begin_y = 0;
  g_fragment_end_y = 0;

  // g_frame_buffer initialization
  g_frame_buffer = new Pixel*[400];
  for (int i = 0; i < 400; i++) {
    g_frame_buffer[i] = new Pixel[640];
  }

  for (int i = 0; i < 400; i++) {
    for (int j = 0; j < 640; j++) {
      g_frame_buffer[i][j].depth = 3;
      g_frame_buffer[i][j].r = 0;
      g_frame_buffer[i][j].g = 0;
      g_frame_buffer[i][j].b = 0;
      g_frame_buffer[i][j].a = 0;
    }
  }
}

void SetVertex(float x_value, float y_value, float z_value) {
  g_current_vertex.x = x_value;
  g_current_vertex.y = y_value;
  g_current_vertex.z = z_value;
}

void SetColor(unsigned char r_value, unsigned char g_value, unsigned char b_value) {
  g_current_matrix.r = r_value;
  g_current_matrix.g = g_value;
  g_current_matrix.b = b_value;
}

void Rotate(float angle, float z_value) {
  // Prepare Operand
  Matrix bak_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      bak_matrix.mat[j][k] = g_current_matrix.mat[j][k];
    }
  }

  Matrix tmp_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      tmp_matrix.mat[j][k] = 0;
      if (j == k) {
        tmp_matrix.mat[j][k] = 1;
      }
    }
  }

  if (z_value < 0) {
    angle = (-1) * angle;
  }

  tmp_matrix.mat[0][0] = cos(angle*PI/180);
  tmp_matrix.mat[1][0] = (-1) * sin(angle*PI/180);
  tmp_matrix.mat[0][1] = sin(angle*PI/180);
  tmp_matrix.mat[1][1] = cos(angle*PI/180);

  // Matrix Multiplication 
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      float result = 0;
      for (int k = 0; k < 4; k++) 
        result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
      g_current_matrix.mat[i][j] = result;
    }
  }
}

void Translate(float x_value, float y_value) {
  // Prepare Operand
  Matrix bak_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      bak_matrix.mat[j][k] = g_current_matrix.mat[j][k];
    }
  }

  Matrix tmp_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      tmp_matrix.mat[j][k] = 0;
      if (j == k) {
        tmp_matrix.mat[j][k] = 1;
      }
    }
  }

  tmp_matrix.mat[0][3] = x_value;
  tmp_matrix.mat[1][3] = y_value;

  // Matrix Multiplication 
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      float result = 0;
      for (int k = 0; k < 4; k++) 
        result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
      g_current_matrix.mat[i][j] = result;
    }
  }
}

void Scale(float x_value, float y_value) {
  // Prepare Operand
  Matrix bak_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      bak_matrix.mat[j][k] = g_current_matrix.mat[j][k];
    }
  }

  Matrix tmp_matrix;
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      tmp_matrix.mat[j][k] = 0;
      if (j == k) {
        tmp_matrix.mat[j][k] = 1;
      }
    }
  }

  tmp_matrix.mat[0][0] = x_value;
  tmp_matrix.mat[1][1] = y_value;

  // Matrix Multiplication 
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      float result = 0;
      for (int k = 0; k < 4; k++) 
        result = result + (bak_matrix.mat[i][k] * tmp_matrix.mat[k][j]);
      g_current_matrix.mat[i][j] = result;
    }
  }
}

void PushMatrix() {
  if (g_matrix_stack_ptr < 15) {
    g_matrix_stack_ptr = g_matrix_stack_ptr + 1;

    for (int j = 0; j < 4; j++) 
      for (int k = 0; k < 4; k++) 
        g_matrix_stack[g_matrix_stack_ptr].mat[j][k] = g_current_matrix.mat[j][k];

    g_matrix_stack[g_matrix_stack_ptr].r = g_current_matrix.r;
    g_matrix_stack[g_matrix_stack_ptr].g = g_current_matrix.g;
    g_matrix_stack[g_matrix_stack_ptr].b = g_current_matrix.b;
    g_matrix_stack[g_matrix_stack_ptr].a = g_current_matrix.a;
  }
}

void LoadIdentity() {
  // g_current_matrix initialization
  for (int j = 0; j < 4; j++) {
    for (int k = 0; k < 4; k++) {
      g_current_matrix.mat[j][k] = 0;
      if (j == k) {
        g_current_matrix.mat[j][k] = 1;
      }
    }
  }

  g_current_matrix.r = 0;
  g_current_matrix.g = 0;
  g_current_matrix.b = 0;
  g_current_matrix.a = 0;
}

void PopMatrix() {
  if (g_matrix_stack_ptr >= 0) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 4; k++) {
        g_current_matrix.mat[j][k] = g_matrix_stack[g_matrix_stack_ptr].mat[j][k];
      }
    }
    g_current_matrix.r = g_matrix_stack[g_matrix_stack_ptr].r;
    g_current_matrix.g = g_matrix_stack[g_matrix_stack_ptr].g;
    g_current_matrix.b = g_matrix_stack[g_matrix_stack_ptr].b;
    g_current_matrix.a = g_matrix_stack[g_matrix_stack_ptr].a;

    g_matrix_stack_ptr = g_matrix_stack_ptr - 1;
  }
}

void ProcessVertex(bool is_setvertex) {
  if (is_setvertex) {
    //Color
    g_current_vertex.r = g_current_matrix.r;
    g_current_vertex.g = g_current_matrix.g;
    g_current_vertex.b = g_current_matrix.b;
    g_current_vertex.a = g_current_matrix.a;

    float x_value = g_current_vertex.x;
    float y_value = g_current_vertex.y;
#ifdef GRAPH_DEBUG 
    printf("g_current_vertex r:%d g:%d b:%d a:%d \n",
        g_current_matrix.r, g_current_matrix.g, g_current_matrix.b, g_current_matrix.a);
#endif 
    g_current_vertex.x = 0;
    g_current_vertex.y = 0;

    float x_result = 0;
    x_result += g_current_matrix.mat[0][0] * x_value;
    x_result += g_current_matrix.mat[0][1] * y_value;
    x_result += g_current_matrix.mat[0][3] * 1;
    g_current_vertex.x = x_result;

    float y_result = 0;
    y_result += g_current_matrix.mat[1][0] * x_value;
    y_result += g_current_matrix.mat[1][1] * y_value;
    y_result += g_current_matrix.mat[1][3] * 1;
    g_current_vertex.y = y_result;
  }
}

void AssemblePrimitive(bool is_beginprimitive, bool is_setvertex) {
  if (is_beginprimitive) {
    g_current_triangle.current_vertex = 0;
  }

#ifdef GRAPH_DEBUG 
  printf("primitive_assembly g_current_triangle.v[%d].x : %lf, g_current_triangle.v[i].y : %lf\n",
      g_current_triangle.current_vertex, g_current_vertex.x, g_current_vertex.y); 
#endif 

  if (is_setvertex) {
    g_current_triangle.v[g_current_triangle.current_vertex] = g_current_vertex;
    g_current_triangle.current_vertex++;
  }
}

typedef struct edgefunction_struct {
  float a, b, c;
} edgefunction;

edgefunction edgefunctionsetup(float x_value_1, float y_value_1, float x_value_2, float y_value_2) {
  float a = (y_value_1 - y_value_2);
  float b = (x_value_2 - x_value_1);

  float c_1 = ((-1) * a) * x_value_2;
  float c_2 = ((-1) * b) * y_value_2;
  float c = c_1 + c_2;

  edgefunction edge;
  edge.a = a;
  edge.b = b;
  edge.c = c;

  return edge;
}

float calculate_edgefunction(edgefunction edge, float x_value, float y_value) {
  return (((edge.a * x_value) + (edge.b * y_value)) + edge.c);
}

bool inside(edgefunction edge, float x_value, float y_value) {
  float edge_result = calculate_edgefunction(edge, x_value, y_value);

  if (edge_result > 0) 
    return true;

  if (edge_result < 0) 
    return false;

  if (edge.a > 0) 
    return true;

  if (edge.a < 0) 
    return false;

  if (edge.b > 0) 
    return true;

  return false;
}

void Rasterization(bool is_endprimitive) {
  if (is_endprimitive) {
    //Triangle Setup
    float fragment_x[3];
    float fragment_y[3];

    for (int i = 0; i < 3; i++) {
      fragment_x[i] = (g_current_triangle.v[i].x + 5) * 64.0f;
      fragment_y[i] = (g_current_triangle.v[i].y + 5) * 40.0f;
#ifdef GRAPH_DEBUG			
      printf("g_current_triangle.v[%d].x : %lf, g_current_triangle.v[%d].y : %lf r:%d g:%d b:%d \n",
          i, g_current_triangle.v[i].x, i, g_current_triangle.v[i].y, g_current_triangle.v[i].r, 
          g_current_triangle.v[i].g, g_current_triangle.v[i].b);
      printf("fragment_x[%d] : %lf, fragment_y[%d] : %lf\n",
          i, fragment_x[i], i, fragment_y[i]);
#endif 	
    }

    //Edge Function Setup
    edgefunction edge_0 =
      edgefunctionsetup(fragment_x[2], fragment_y[2], fragment_x[1], fragment_y[1]);
    edgefunction edge_1 =
      edgefunctionsetup(fragment_x[0], fragment_y[0], fragment_x[2], fragment_y[2]);
    edgefunction edge_2 =
      edgefunctionsetup(fragment_x[1], fragment_y[1], fragment_x[0], fragment_y[0]);

    //printf("edgefunction0 : %lf, %lf, %lf\n", edge_0.a, edge_0.b, edge_0.c);
    //printf("edgefunction1 : %lf, %lf, %lf\n", edge_1.a, edge_1.b, edge_1.c);
    //printf("edgefunction2 : %lf, %lf, %lf\n", edge_2.a, edge_2.b, edge_2.c);

    //Traverse Setup
    float min_x = fragment_x[0];
    float max_x = fragment_x[0];
    float min_y = fragment_y[0];
    float max_y = fragment_y[0];

    for (int i = 1; i < 3; i++) {
      if (min_x > fragment_x[i]) 
        min_x = fragment_x[i];

      if (max_x < fragment_x[i]) 
        max_x = fragment_x[i];

      if (min_y > fragment_y[i]) 
        min_y = fragment_y[i];

      if (max_y < fragment_y[i]) 
        max_y = fragment_y[i];
    }

    if (min_x < 0) { min_x = 0; }
    if (max_x >= 639) { max_x = 639; }
    if (min_y < 0) { min_y = 0; }
    if (max_y >= 399) { max_y = 399; }

    g_fragment_begin_x = min_x;
    g_fragment_end_x = max_x;
    g_fragment_begin_y = min_y;
    g_fragment_end_y = max_y;

    float depth = g_current_triangle.v[0].z;
    float r = g_current_triangle.v[0].r;
    float g = g_current_triangle.v[0].g;
    float b = g_current_triangle.v[0].b;
    float a = g_current_triangle.v[0].a;
#ifdef GRAPH_DEBUG 
    printf("depth : %lf, r: %lf, g: %lf, b: %lf, a: %lf\n", depth, r, g, b, a);
#endif 
    //Traverse
    for (int i = g_fragment_begin_y; i < g_fragment_end_y; i++) {
      for (int j = g_fragment_begin_x; j < g_fragment_end_x; j++) {
        if (inside(edge_0, (j + 0.5), (i + 0.5)) && 
            inside(edge_1, (j + 0.5), (i + 0.5)) && 
            inside(edge_2, (j + 0.5), (i + 0.5))) {
          g_fragment_buffer[i][j].depth = depth;
          g_fragment_buffer[i][j].r = r;
          g_fragment_buffer[i][j].g = g;
          g_fragment_buffer[i][j].b = b;
          g_fragment_buffer[i][j].a = a;
        }
      }
    }
  }
}

void ProcessZBuffer() {
  for (int i = g_fragment_begin_y; i < g_fragment_end_y; i++) {
    for (int j = g_fragment_begin_x; j < g_fragment_end_x; j++) {
      if (g_fragment_buffer[i][j].depth < g_frame_buffer[i][j].depth) {
        g_frame_buffer[i][j].depth = g_fragment_buffer[i][j].depth;
        g_frame_buffer[i][j].r = g_fragment_buffer[i][j].r;
        g_frame_buffer[i][j].g = g_fragment_buffer[i][j].g;
        g_frame_buffer[i][j].b = g_fragment_buffer[i][j].b;
        g_frame_buffer[i][j].a = g_fragment_buffer[i][j].a;
      }

      g_fragment_buffer[i][j].depth = 3;
      g_fragment_buffer[i][j].r = 0;
      g_fragment_buffer[i][j].g = 0;
      g_fragment_buffer[i][j].b = 0;
      g_fragment_buffer[i][j].a = 0;
    }
  }
}

void Display() {
  static unsigned int file_index = 0;

  unsigned long header_length = 54;
  unsigned char header[54];
  memset(header, 0, 54);

  unsigned long width = 640;
  unsigned long height = 400;
  unsigned long length = header_length + 3 * width * height;

  header[0] = 'B';
  header[1] = 'M';
  header[2] = length & 0xff;
  header[3] = (length >> 8) & 0xff;
  header[4] = (length >> 16) & 0xff;
  header[5] = (length >> 24) & 0xff;
  header[10] = header_length;
  header[14] = 40;
  header[18] = width & 0xff;
  header[19] = (width >> 8) & 0xff;
  header[20] = (width >> 16) & 0xff;
  header[22] = height & 0xff;
  header[23] = (height >> 8) & 0xff;
  header[24] = (height >> 16) & 0xff;
  header[26] = 1;
  header[28] = 24;
  header[34] = 16;
  header[36] = 0x13;
  header[37] = 0x0b;
  header[42] = 0x13;
  header[43] = 0x0b;

  char file_name[64];
  sprintf(file_name, "./%ul.bmp", file_index);
  FILE* f = fopen (file_name, "wb");
  if (!f) {
    perror ("fopen");
    return;
  }

  // Write header.
  if (header_length != fwrite (header, 1, header_length, f)) {
    perror ("fwrite");
    fclose (f);
    return;
  }

  // Write pixels
  // Note : BMP has lower rows first.
  for (int i = height - 1; i >= 0; i--) {
    for (int j = 0; j < width; j++) {
      unsigned char rgba[4];
      Pixel pix = g_frame_buffer[i][j];

      rgba[0] = pix.b & 0xff;
      rgba[1] = pix.g & 0xff;
      rgba[2] = pix.r & 0xff;

      if (3 != fwrite(rgba, 1, 3, f)) {
        perror ("fwrite");
        fclose (f);
        return;
      }
    }
  }

  fclose (f);

  file_index = file_index + 1;

  for (int i = 0; i < 400; i++) {
    for (int j = 0; j < 640; j++) {
      g_frame_buffer[i][j].depth = 3;
      g_frame_buffer[i][j].r = 0;
      g_frame_buffer[i][j].g = 0;
      g_frame_buffer[i][j].b = 0;
      g_frame_buffer[i][j].a = 0;
    }
  }

  return;
}

void ProcessFrameBuffer(bool is_endprimitive, bool is_draw) {
  if (is_endprimitive) 
    ProcessZBuffer();  // in your design, no need to test z-buffer values 
  if (is_draw) 
    Display();
}

void Flush() {
  // Reset g_fragment_buffer 
  for (int i = 0; i < 400; i++) {
    for (int j = 0; j < 640; j++) {
      g_fragment_buffer[i][j].depth = 3;
      g_fragment_buffer[i][j].r = 0;
      g_fragment_buffer[i][j].g = 0;
      g_fragment_buffer[i][j].b = 0;
      g_fragment_buffer[i][j].a = 0;
    }
  }
  g_fragment_begin_x = 0;
  g_fragment_end_x = 0;
  g_fragment_begin_y = 0;
  g_fragment_end_y = 0;

  // Reset g_frame_buffer 
  for (int i = 0; i < 400; i++) {
    for (int j = 0; j < 640; j++) {
      g_frame_buffer[i][j].depth = 3;
      g_frame_buffer[i][j].r = 0;
      g_frame_buffer[i][j].g = 0;
      g_frame_buffer[i][j].b = 0;
      g_frame_buffer[i][j].a = 0;
    }
  }
}

////////////////////////////////////////////////////////////////////////
// desc: Set g_condition_code_register depending on the values of val1 and val2
// hint: bit0 (N) is set only when val1 < val2
////////////////////////////////////////////////////////////////////////
void SetConditionCodeInt(const int16_t val1, const int16_t val2) {
  if (val1 < val2)
    g_condition_code_register.int_value = 0x04;
  else if (val1 == val2)
    g_condition_code_register.int_value = 0x02;
  else // (val1 > val2)
    g_condition_code_register.int_value = 0x01;
}

////////////////////////////////////////////////////////////////////////
// desc: Set g_condition_code_register depending on the values of val1 and val2
// hint: bit0 (N) is set only when val1 < val2
////////////////////////////////////////////////////////////////////////
void SetConditionCodeFloat(const float val1, const float val2) {
  if (val1 < val2)
    g_condition_code_register.int_value = 0x04;
  else if (val1 == val2)
    g_condition_code_register.int_value = 0x02;
  else // (val1 > val2)
    g_condition_code_register.int_value = 0x01;
}

////////////////////////////////////////////////////////////////////////
// Initialize global variables
////////////////////////////////////////////////////////////////////////
void InitializeGlobalVariables() {
  memset(&g_condition_code_register, 0x00, sizeof(ScalarRegister));
  memset(g_scalar_registers, 0x00, sizeof(ScalarRegister) * NUM_SCALAR_REGISTER);
  memset(g_vector_registers, 0x00, sizeof(VectorRegister) * NUM_VECTOR_REGISTER);
  memset(g_memory, 0x00, sizeof(unsigned char) * MEMORY_SIZE);
}

////////////////////////////////////////////////////////////////////////
// desc: Convert 16-bit 2's complement signed integer to 32-bit
////////////////////////////////////////////////////////////////////////
int SignExtension(const int16_t value) {
  return (value >> 15) == 0 ? value : ((0xFFFF << 16) | value);
}

#define FLOAT_TO_FIXED187(n) ((int)((n) * (float)(1<<(7)))) & 0xffff
#define FIXED_TO_FLOAT187(n) ((float)(-1*((n>>15)&0x1)*(1<<8)) + (float)((n&(0x7fff)) / (float)(1<<7)))
float DecodeBinaryToFloatingPointNumber(int value) {
  return (float)FIXED_TO_FLOAT187(value); 
}

////////////////////////////////////////////////////////////////////////
// desc: Decode binary-encoded instruction and Parse into TraceOp structure
//       which we will use execute later
// input: 32-bit encoded instruction
// output: TraceOp structure filled with the information provided from the input
////////////////////////////////////////////////////////////////////////
TraceOp DecodeInstruction(const uint32_t instruction) {
  TraceOp ret_trace_op;
  memset(&ret_trace_op, 0x00, sizeof(ret_trace_op));

  uint8_t opcode = (instruction & 0xFF000000) >> 24;
  ret_trace_op.opcode = opcode;

  switch (opcode) {
    case OP_ADD_D: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_1_idx = (instruction & 0x000F0000) >> 16;
        int source_register_2_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_1_idx;
        ret_trace_op.scalar_registers[2] = source_register_2_idx;
      }
      break;

    case OP_ADDI_D: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_idx_idx = (instruction & 0x000F0000) >> 16;
        int immediate_value = SignExtension(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_idx_idx;
        ret_trace_op.int_value = immediate_value;
      }
      break;

    case OP_ADD_F: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_1_idx = (instruction & 0x000F0000) >> 16;
        int source_register_2_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_1_idx;
        ret_trace_op.scalar_registers[2] = source_register_2_idx;
      }
      break;

    case OP_ADDI_F: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_idx = (instruction & 0x000F0000) >> 16;
        float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_idx;
        ret_trace_op.float_value = immediate_value;
        ret_trace_op.int_value = (int) immediate_value; 
      }
      break;

    case OP_VADD: 
      {
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
        int source_register_1_idx = (instruction & 0x00003F00) >> 8;
        int source_register_2_idx = (instruction & 0x0000003F);
        ret_trace_op.vector_registers[0] = destination_register_idx;
        ret_trace_op.vector_registers[1] = source_register_1_idx;
        ret_trace_op.vector_registers[2] = source_register_2_idx;
      }
      break;

    case OP_AND_D: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_1_idx = (instruction & 0x000F0000) >> 16;
        int source_register_2_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_1_idx;
        ret_trace_op.scalar_registers[2] = source_register_2_idx;
      }
      break;

    case OP_ANDI_D: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int source_register_idx_idx = (instruction & 0x000F0000) >> 16;
        int immediate_value = SignExtension(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_idx_idx;
        ret_trace_op.int_value = immediate_value;
      }
      break;

    case OP_MOV: 
      {
        int destination_register_idx = (instruction & 0x000F0000) >> 16;
        int source_register_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = source_register_idx;
      }
      break;

    case OP_MOVI_D: 
      {
        int destination_register_idx = (instruction & 0x000F0000) >> 16;
        int immediate_value = SignExtension(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.int_value = immediate_value;
      }
      break;

    case OP_MOVI_F: 
      {
        int destination_register_idx = (instruction & 0x000F0000) >> 16;
        float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.float_value = immediate_value;
      }
      break;

    case OP_VMOV: 
      {
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
        int source_register_idx = (instruction & 0x00003F00) >> 8;
        ret_trace_op.vector_registers[0] = destination_register_idx;
        ret_trace_op.vector_registers[1] = source_register_idx;
      }
      break;

    case OP_VMOVI: 
      {
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
        float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
        ret_trace_op.vector_registers[0] = destination_register_idx;
        ret_trace_op.float_value = immediate_value;
      }
      break;

    case OP_CMP: 
      {
        int source_register_1_idx = (instruction & 0x000F0000) >> 16;
        int source_register_2_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.scalar_registers[0] = source_register_1_idx;
        ret_trace_op.scalar_registers[1] = source_register_2_idx;
      }
      break;

    case OP_CMPI: 
      {
        int source_register_idx = (instruction & 0x000F0000) >> 16;
        int immediate_value = SignExtension(instruction & 0x0000FFFF);
        ret_trace_op.scalar_registers[0] = source_register_idx;
        ret_trace_op.int_value = immediate_value;
      }
      break;

    case OP_VCOMPMOV: 
      {
        int element_idx = (instruction & 0x00C00000) >> 22;
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
        int source_register_idx = (instruction & 0x00000F00) >> 8;
        ret_trace_op.idx = element_idx;
        ret_trace_op.vector_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[0] = source_register_idx;
      }
      break;

    case OP_VCOMPMOVI: 
      {
        int element_idx = (instruction & 0x00C00000) >> 22;
        int destination_register_idx = (instruction & 0x003F0000) >> 16;
        float immediate_value = DecodeBinaryToFloatingPointNumber(instruction & 0x0000FFFF);
        ret_trace_op.idx = element_idx;
        ret_trace_op.vector_registers[0] = destination_register_idx;
        ret_trace_op.float_value = immediate_value;
        //printf("op_vcompmov immediate :%d float:%f \n", (int) (instruction & 0x0000ffff), immediate_value); 
      }
      break;

    case OP_LDB:
    case OP_LDW: 
      {
        int destination_register_idx = (instruction & 0x00F00000) >> 20;
        int base_register_idx = (instruction & 0x000F0000) >> 16;
        int offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
        ret_trace_op.scalar_registers[0] = destination_register_idx;
        ret_trace_op.scalar_registers[1] = base_register_idx;
        ret_trace_op.int_value = offset;
      }
      break;

    case OP_STB:
    case OP_STW: 
      {
        int source_register_idx = (instruction & 0x00F00000) >> 20;
        int base_register_idx = (instruction & 0x000F0000) >> 16;
        int offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
        ret_trace_op.scalar_registers[0] = source_register_idx;
        ret_trace_op.scalar_registers[1] = base_register_idx;
        ret_trace_op.int_value = offset;
      }
      break;

    case OP_BEGINPRIMITIVE: 
      {
        int primitive_type = (instruction & 0x000F0000) >> 16;
        ret_trace_op.primitive_type = primitive_type;
      }
      break;

    case OP_JMP:
    case OP_JSRR: 
      {
        int base_register = (instruction & 0x000F0000) >> 16;
        ret_trace_op.scalar_registers[0] = base_register;
      }
      break;

    case OP_SETVERTEX: 
    case OP_SETCOLOR: 
    case OP_ROTATE: 
    case OP_TRANSLATE: 
    case OP_SCALE: 
      {
        int vector_register_idx = (instruction & 0x003F0000) >> 16;
        ret_trace_op.vector_registers[0] = vector_register_idx;	
      }
      break;

    case OP_BRN: 
    case OP_BRZ:
    case OP_BRP:
    case OP_BRNZ:
    case OP_BRNP:
    case OP_BRZP:
    case OP_BRNZP:
    case OP_JSR: 
      {
        int pc_offset = SignExtension((int16_t)(instruction & 0x0000FFFF));
        ret_trace_op.int_value = pc_offset;
      }
      break;

    default:
      break;
  }

return ret_trace_op;
}

////////////////////////////////////////////////////////////////////////
// desc: Execute the behavior of the instruction (Simulate)
// input: Instruction to execute 
// output: Non-branch operation ? -1 : OTHER (PC-relative or absolute address)
////////////////////////////////////////////////////////////////////////
int ExecuteInstruction(const TraceOp &trace_op) {
  int ret_next_instruction_idx = -1;

  uint8_t opcode = trace_op.opcode;
  switch (opcode) {
    case OP_ADD_D: 
      {
        int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
        int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + source_value_2;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      }
      break;

    case OP_ADDI_D: 
      {
        int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
        int source_value_2 = trace_op.int_value;
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 + source_value_2;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      }
      break;

    case OP_ADD_F: 
      {
        float source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].float_value;
        float source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].float_value;
        g_scalar_registers[trace_op.scalar_registers[0]].float_value = source_value_1 + source_value_2;
        SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
      }
      break;

    case OP_ADDI_F: 
      {
        float source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].float_value;
        float source_value_2 = trace_op.float_value;
        g_scalar_registers[trace_op.scalar_registers[0]].float_value = source_value_1 + source_value_2;
        SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
      }
      break;

    case OP_VADD: 
      {
        for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++)
          g_vector_registers[trace_op.vector_registers[0]].element[i].float_value = 
            g_vector_registers[trace_op.vector_registers[1]].element[i].float_value +
            g_vector_registers[trace_op.vector_registers[2]].element[i].float_value;
      }
      break;

    case OP_AND_D: 
      {
        int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
        int source_value_2 = g_scalar_registers[trace_op.scalar_registers[2]].int_value;
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 & source_value_2;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      }
      break;

    case OP_ANDI_D: 
      {
        int source_value_1 = g_scalar_registers[trace_op.scalar_registers[1]].int_value;
        int source_value_2 = trace_op.int_value;
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = source_value_1 & source_value_2;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      }
      break;

    case OP_MOV: 
      {
        if (trace_op.scalar_registers[0] < 7) {
          g_scalar_registers[trace_op.scalar_registers[0]].int_value = 
            g_scalar_registers[trace_op.scalar_registers[1]].int_value;
          SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
        } else if (trace_op.scalar_registers[0] > 7) {
          g_scalar_registers[trace_op.scalar_registers[0]].float_value = 
            g_scalar_registers[trace_op.scalar_registers[1]].float_value;
          SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
        }
      }
      break;

    case OP_MOVI_D: 
      {
        g_scalar_registers[trace_op.scalar_registers[0]].int_value = trace_op.int_value;
        SetConditionCodeInt(g_scalar_registers[trace_op.scalar_registers[0]].int_value, 0);
      }
      break;

    case OP_MOVI_F: 
      {
        g_scalar_registers[trace_op.scalar_registers[0]].float_value = trace_op.float_value;
        SetConditionCodeFloat(g_scalar_registers[trace_op.scalar_registers[0]].float_value, 0.0f);
      }
      break;

    case OP_VMOV: 
      {
        for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++) {
          g_vector_registers[trace_op.vector_registers[0]].element[i].float_value =
            g_vector_registers[trace_op.vector_registers[1]].element[i].float_value;
        }
      }
      break;

    case OP_VMOVI:
      {
        for (int i = 0; i < NUM_VECTOR_ELEMENTS; i++)
          g_vector_registers[trace_op.vector_registers[0]].element[i].float_value = trace_op.float_value;
      }
      break;

    case OP_CMP: 
      {
        if (trace_op.scalar_registers[0] < 7)
          SetConditionCodeInt(
              g_scalar_registers[trace_op.scalar_registers[0]].int_value,
              g_scalar_registers[trace_op.scalar_registers[1]].int_value);
        else if (trace_op.scalar_registers[0] > 7)
          SetConditionCodeFloat(
              g_scalar_registers[trace_op.scalar_registers[0]].float_value,
              g_scalar_registers[trace_op.scalar_registers[1]].float_value);
      }
      break;

    case OP_CMPI: 
      {
        if (trace_op.scalar_registers[0] < 7)
          SetConditionCodeInt(
              g_scalar_registers[trace_op.scalar_registers[0]].int_value,
              trace_op.int_value);
        else if (trace_op.scalar_registers[0] > 7)
          SetConditionCodeFloat(
              g_scalar_registers[trace_op.scalar_registers[0]].float_value,
              trace_op.float_value);
      }
      break;

    case OP_VCOMPMOV: 
      {
        int idx = trace_op.idx;
        g_vector_registers[trace_op.vector_registers[0]].element[idx].float_value =
          g_scalar_registers[trace_op.scalar_registers[0]].float_value;
      }
      break;

    case OP_VCOMPMOVI:
      {
        int idx = trace_op.idx;
        g_vector_registers[trace_op.vector_registers[0]].element[idx].float_value =
          trace_op.float_value;
      }
      break;

    case OP_LDB: 
      {
        int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value + trace_op.int_value;
        memcpy(&g_scalar_registers[trace_op.scalar_registers[0]], &g_memory[address], sizeof(int8_t));
      }
      break;

    case OP_LDW: 
      {
        int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value + trace_op.int_value;
        memcpy(&g_scalar_registers[trace_op.scalar_registers[0]], &g_memory[address], sizeof(int16_t));
      }
      break;

    case OP_STB: 
      {
        int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value + trace_op.int_value;
        memcpy(&g_memory[address], &g_scalar_registers[trace_op.scalar_registers[0]], sizeof(int8_t));
      }
      break;

    case OP_STW:
      {
        int address = g_scalar_registers[trace_op.scalar_registers[1]].int_value + trace_op.int_value;
        memcpy(&g_memory[address], &g_scalar_registers[trace_op.scalar_registers[0]], sizeof(int16_t));
      }
      break;

    case OP_PUSHMATRIX: 
      {
        PushMatrix();
      }
      break;

    case OP_POPMATRIX: 
      {
        PopMatrix();
      }
      break;

    case OP_ENDPRIMITIVE: 
      {
        g_is_end_primitive = true;
      }
      break;

    case OP_LOADIDENTITY: 
      {
        LoadIdentity();
      }
      break;

    case OP_FLUSH: 
      {
        Flush();
      }
      break;

    case OP_DRAW: 
      {
        g_is_draw = true;
      }  
      break;

    case OP_BEGINPRIMITIVE: 
      {
        g_is_begin_primitive = true;
      }
      break;

    case OP_JMP: 
      {
        if (g_scalar_registers[trace_op.scalar_registers[0]].int_value == 0x07) // OP_RET
          ret_next_instruction_idx = g_scalar_registers[LR_IDX].int_value;
        else // OP_JMP
          ret_next_instruction_idx = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
      }
      break;

    case OP_JSRR: 
      {
        ret_next_instruction_idx = g_scalar_registers[trace_op.scalar_registers[0]].int_value;
      }
      break;

    case OP_SETVERTEX:
      {
        g_is_setvertex = true;
        float x_value = g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
        float y_value = g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
        float z_value = g_vector_registers[(trace_op.vector_registers[0])].element[3].float_value;
        SetVertex(x_value, y_value, z_value);
#ifdef GRAPH_DEBUG 
        printf("set vertex x:%f y:%f z:%f \n", x_value, y_value, z_value); 
#endif 
      }
      break;

    case OP_SETCOLOR: 
      {
        int r_value =	(int) g_vector_registers[(trace_op.vector_registers[0])].element[0].float_value;
        int g_value = (int) g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
        int b_value = (int) g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
        SetColor(r_value, g_value, b_value);
#ifdef GRAPH_DEBUG 
        printf("set color: r:%d  g:%d b:%d \n", r_value, g_value, b_value); 
#endif 
      }
      break;

    case OP_ROTATE: 
      {
        float angle = g_vector_registers[(trace_op.vector_registers[0])].element[0].float_value;
        float z_value = g_vector_registers[(trace_op.vector_registers[0])].element[3].float_value;
        // ## Note
        // With 1.8.7 fixed-point format, we cannot cover 360 degrees. 
        // So we should scale the angle by 2x; Multiply by 2 to cover 360 degrees
        Rotate(2*angle, z_value);  
      }
      break;

    case OP_TRANSLATE: 
      {
        float x_value = g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
        float y_value = g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
        Translate(x_value, y_value);
      }
      break;

    case OP_SCALE: 
      {
        float x_value = g_vector_registers[(trace_op.vector_registers[0])].element[1].float_value;
        float y_value = g_vector_registers[(trace_op.vector_registers[0])].element[2].float_value;
        Scale(x_value, y_value);
      }
      break;

    case OP_BRN: 
      {
        if (g_condition_code_register.int_value & 0x04)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRZ: 
      {
        if (g_condition_code_register.int_value & 0x02)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRP: 
      {
        if (g_condition_code_register.int_value & 0x01)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRNZ: 
      {
        if (g_condition_code_register.int_value & 0x06)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRNP: 
      {
        if (g_condition_code_register.int_value & 0x05)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRZP: 
      {
        if (g_condition_code_register.int_value & 0x03)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_BRNZP: 
      {
        if (g_condition_code_register.int_value & 0x07)
          ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    case OP_JSR: 
      {
        ret_next_instruction_idx = trace_op.int_value;
      }
      break;

    default:
      break;
  }

  return ret_next_instruction_idx;
}

////////////////////////////////////////////////////////////////////////
// desc: Dump given trace_op
////////////////////////////////////////////////////////////////////////
void PrintTraceOp(const TraceOp &trace_op) {  
  cout << "  opcode: " << SignExtension(trace_op.opcode);
  cout << ", scalar_register[0]: " << (int) trace_op.scalar_registers[0];
  cout << ", scalar_register[1]: " << (int) trace_op.scalar_registers[1];
  cout << ", scalar_register[2]: " << (int) trace_op.scalar_registers[2];
  cout << ", vector_register[0]: " << (int) trace_op.vector_registers[0];
  cout << ", vector_register[1]: " << (int) trace_op.vector_registers[1];
  cout << ", idx: " << (int) trace_op.idx;
  cout << ", primitive_index: " << (int) trace_op.primitive_type;
  cout << ", int_value: " << (int) trace_op.int_value;
  cout << ", float_value: " << (float) trace_op.float_value << endl;
}

////////////////////////////////////////////////////////////////////////
// desc: This function is called every trace is executed
//       to provide the contents of all the registers
////////////////////////////////////////////////////////////////////////
void PrintContext(const TraceOp &current_op) {
  cout << "--------------------------------------------------" << endl;
  cout << "Instruction Count: " << g_instruction_count
       << ", Current Instruction's Opcode: " << current_op.opcode
       << ", Next Instruction's Opcode: " << g_trace_ops[g_scalar_registers[PC_IDX].int_value].opcode 
       << endl;
  for (int srIdx = 0; srIdx < NUM_SCALAR_REGISTER; srIdx++) {
    cout << "R" << srIdx << ":" 
         << ((srIdx < 8 || srIdx == 15) ? g_scalar_registers[srIdx].int_value : g_scalar_registers[srIdx].float_value) 
         << (srIdx == NUM_SCALAR_REGISTER-1 ? "" : ", ");
  }
  cout << endl;
  for (int vrIdx = 0; vrIdx < NUM_VECTOR_REGISTER; vrIdx++) {
    cout << "V" << vrIdx << ":";
    for (int elmtIdx = 0; elmtIdx < NUM_VECTOR_ELEMENTS; elmtIdx++) { 
      cout << "Element[" << elmtIdx << "] = " 
           << g_vector_registers[vrIdx].element[elmtIdx].float_value 
           << (elmtIdx == NUM_VECTOR_ELEMENTS-1 ? "" : ",");
    }
    cout << endl;
  }
  cout << endl;
  cout << "--------------------------------------------------" << endl;
}

int main(int argc, char **argv) {
  ///////////////////////////////////////////////////////////////
  // Initialization 
  ///////////////////////////////////////////////////////////////
  //
  InitializeGlobalVariables();
  InitializeGpuVariables(); 

  ///////////////////////////////////////////////////////////////
  // Load Program
  ///////////////////////////////////////////////////////////////
  //
  if (argc != 2) {
    cerr << "Usage: " << argv[0] << " <input>" << endl;
    return 1;
  }

  ifstream infile(argv[1]);
  if (!infile) {
    cerr << "Error: Failed to open input file " << argv[1] << endl;
    return 1;
  }

  vector< bitset<sizeof(uint32_t)*CHAR_BIT> > instructions;
  while (!infile.eof()) {
    bitset<sizeof(uint32_t)*CHAR_BIT> bits;
    infile >> bits;
    if (infile.eof())  break;
    instructions.push_back(bits);
  }

  infile.close();

#ifdef DEBUG
  cout << "The contents of the instruction vectors are :" << endl;
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    cout << "  " << *ii << endl;
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Decode instructions into g_trace_ops
  ///////////////////////////////////////////////////////////////
  //
  for (vector< bitset<sizeof(uint32_t)*CHAR_BIT> >::iterator ii =
      instructions.begin(); ii != instructions.end(); ii++) {
    uint32_t inst = (uint32_t) ((*ii).to_ulong());
    TraceOp trace_op = DecodeInstruction(inst);
    g_trace_ops.push_back(trace_op);
  }

#ifdef DEBUG
  cout << "The contents of the g_trace_ops vectors are :" << endl;
  for (vector<TraceOp>::iterator ii = g_trace_ops.begin();
      ii != g_trace_ops.end(); ii++) {
    PrintTraceOp(*ii);
  }
#endif // DEBUG

  ///////////////////////////////////////////////////////////////
  // Execute 
  ///////////////////////////////////////////////////////////////
  //
  g_scalar_registers[PC_IDX].int_value = 0;
  for (;;) {
    TraceOp current_op = g_trace_ops[g_scalar_registers[PC_IDX].int_value];
    int idx = ExecuteInstruction(current_op);

    if (current_op.opcode == OP_JSR || current_op.opcode == OP_JSRR)
      g_scalar_registers[LR_IDX].int_value = g_scalar_registers[PC_IDX].int_value + 1;

    g_scalar_registers[PC_IDX].int_value += 1; 
    if (idx != -1) { // Branch
      if (current_op.opcode == OP_JMP || current_op.opcode == OP_JSRR) // Absolote addressing
        g_scalar_registers[PC_IDX].int_value = idx; 
      else // PC-relative addressing (OP_JSR || OP_BRXXX)
        g_scalar_registers[PC_IDX].int_value += idx; 
    }

    ProcessVertex(g_is_setvertex);
    AssemblePrimitive(g_is_begin_primitive, g_is_setvertex);
    Rasterization(g_is_end_primitive);
    ProcessFrameBuffer(g_is_end_primitive, g_is_draw);

#ifdef DEBUG
    g_instruction_count++;
#endif // DEBUG

    // End of the program
    if (g_scalar_registers[PC_IDX].int_value == g_trace_ops.size())
      break;

    g_is_setvertex = false; 
    g_is_begin_primitive = false;
    g_is_end_primitive = false; 
    g_is_draw = false; 
  }

  return 0;
}

