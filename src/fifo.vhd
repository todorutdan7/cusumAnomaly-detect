library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axis_fifo is
    Generic (
        DEPTH : integer := 64;
        WIDTH : integer := 32
    );
    Port (
        aclk    : IN STD_LOGIC;
        aresetn : IN STD_LOGIC; 
        
        s_axis_tvalid : IN STD_LOGIC;
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
        
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tready : IN STD_LOGIC;
        m_axis_tdata  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
    );
end axis_fifo;

architecture Behavioral of axis_fifo is
    type memory_type is array (0 to DEPTH-1) of STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal fifo_mem : memory_type := (others => (others => '0'));
    
    signal head : integer range 0 to DEPTH-1 := 0; 
    signal tail : integer range 0 to DEPTH-1 := 0; 
    signal count : integer range 0 to DEPTH := 0;
    
    signal full_sig  : std_logic;
    signal empty_sig : std_logic;
    signal wr_en     : std_logic;
    signal rd_en     : std_logic;
begin

    full_sig  <= '1' when count = DEPTH else '0';
    empty_sig <= '1' when count = 0 else '0';

    s_axis_tready <= not full_sig;
    m_axis_tvalid <= not empty_sig;
    
    wr_en <= s_axis_tvalid and (not full_sig);
    rd_en <= m_axis_tready and (not empty_sig);
    
    m_axis_tdata <= fifo_mem(tail);

    process(aclk)
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                head <= 0;
                tail <= 0;
                count <= 0;
            else
                if wr_en = '1' then
                    fifo_mem(head) <= s_axis_tdata;
                    if head = DEPTH - 1 then
                        head <= 0;
                    else
                        head <= head + 1;
                    end if;
                end if;
                
                if rd_en = '1' then
                    if tail = DEPTH - 1 then
                        tail <= 0;
                    else
                        tail <= tail + 1;
                    end if;
                end if;
                
                if wr_en = '1' and rd_en = '0' then
                    count <= count + 1;
                elsif wr_en = '0' and rd_en = '1' then
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;