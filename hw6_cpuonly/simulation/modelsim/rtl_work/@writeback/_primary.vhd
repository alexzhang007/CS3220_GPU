library verilog;
use verilog.vl_types.all;
entity Writeback is
    port(
        I_CLOCK         : in     vl_logic;
        I_LOCK          : in     vl_logic;
        I_Opcode        : in     vl_logic_vector(7 downto 0);
        I_ALUOut        : in     vl_logic_vector(15 downto 0);
        I_ALUOutV       : in     vl_logic_vector(63 downto 0);
        I_MemOut        : in     vl_logic_vector(15 downto 0);
        I_DestRegIdx    : in     vl_logic_vector(3 downto 0);
        I_DestRegIdxV   : in     vl_logic_vector(5 downto 0);
        I_DestRegIdxV_Idx: in     vl_logic_vector(2 downto 0);
        I_FetchStall    : in     vl_logic;
        I_DepStall      : in     vl_logic;
        O_WriteBackEnable: out    vl_logic;
        O_WriteBackRegIdx: out    vl_logic_vector(3 downto 0);
        O_WriteBackData : out    vl_logic_vector(15 downto 0);
        O_WriteBackEnableV: out    vl_logic;
        O_WriteBackRegIdxV: out    vl_logic_vector(5 downto 0);
        O_WriteBackRegIdxV_Idx: out    vl_logic_vector(1 downto 0);
        O_WriteBackDataV: out    vl_logic_vector(63 downto 0);
        O_FetchStall    : out    vl_logic;
        O_DepStall      : out    vl_logic
    );
end Writeback;
