library verilog;
use verilog.vl_types.all;
entity Decode is
    port(
        I_CLOCK         : in     vl_logic;
        I_LOCK          : in     vl_logic;
        I_PC            : in     vl_logic_vector(15 downto 0);
        I_IR            : in     vl_logic_vector(31 downto 0);
        I_FetchStall    : in     vl_logic;
        I_WriteBackEnable: in     vl_logic;
        I_WriteBackRegIdx: in     vl_logic_vector(3 downto 0);
        I_WriteBackData : in     vl_logic_vector(15 downto 0);
        I_WriteBackEnableV: in     vl_logic;
        I_WriteBackRegIdxV: in     vl_logic_vector(5 downto 0);
        I_WriteBackRegIdxV_Idx: in     vl_logic_vector(1 downto 0);
        I_WriteBackDataV: in     vl_logic_vector(63 downto 0);
        O_LOCK          : out    vl_logic;
        O_PC            : out    vl_logic_vector(15 downto 0);
        O_Opcode        : out    vl_logic_vector(7 downto 0);
        O_Imm           : out    vl_logic_vector(15 downto 0);
        O_DestRegIdx    : out    vl_logic_vector(3 downto 0);
        O_DestValue     : out    vl_logic_vector(15 downto 0);
        O_Src1Value     : out    vl_logic_vector(15 downto 0);
        O_Src2Value     : out    vl_logic_vector(15 downto 0);
        O_Src1ValueV    : out    vl_logic_vector(63 downto 0);
        O_Src2ValueV    : out    vl_logic_vector(63 downto 0);
        O_DestValueV    : out    vl_logic_vector(63 downto 0);
        O_DestRegIdxV   : out    vl_logic_vector(5 downto 0);
        O_DestRegIdxV_Idx: out    vl_logic_vector(1 downto 0);
        O_Type          : out    vl_logic_vector(3 downto 0);
        O_FetchStall    : out    vl_logic;
        O_DepStall      : out    vl_logic;
        O_BranchStallSignal: out    vl_logic;
        O_DepStallSignal: out    vl_logic
    );
end Decode;
