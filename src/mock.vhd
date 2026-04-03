library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =================================================================
-- 1. MOCK ROM MEMORY (Replaces Xilinx Block RAM for Simulation)
-- =================================================================
entity blk_mem_gen_0 is
  PORT (
    clka : IN STD_LOGIC; wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);      
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0); dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);    
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC; web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);      
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0); dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);    
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end blk_mem_gen_0;

architecture Behavioral of blk_mem_gen_0 is
    type rom_type is array (0 to 10) of std_logic_vector(31 downto 0);
    
    -- DATA SCENARIO:
    -- Index 0-3: Normal values around 23 degrees (2300)
    -- Index 4:   SPIKE to 50 degrees (5000) -> SHOULD TRIGGER ANOMALY
    -- Index 5:   Return to 23 degrees
    signal ROM : rom_type := (
        0 => std_logic_vector(to_signed(2300, 32)), 
        1 => std_logic_vector(to_signed(2305, 32)), 
        2 => std_logic_vector(to_signed(2295, 32)), 
        3 => std_logic_vector(to_signed(2310, 32)), 
        4 => std_logic_vector(to_signed(5000, 32)), -- ANOMALY HERE!
        5 => std_logic_vector(to_signed(2300, 32)), 
        others => (others => '0')
    );
begin
    process(clka) begin
        if rising_edge(clka) then
            if to_integer(unsigned(addra)) <= 10 then
                douta <= ROM(to_integer(unsigned(addra)));
            else
                douta <= (others => '0');
            end if;
        end if;
    end process;

    process(clkb) begin
        if rising_edge(clkb) then
            if to_integer(unsigned(addrb)) <= 10 then
                doutb <= ROM(to_integer(unsigned(addrb)));
            else
                doutb <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;

-- =================================================================
-- 2. MOCK CUSUM DETECTOR (Behavioral Model)
-- =================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cusum_detector is
    Port (
        aclk    : in STD_LOGIC;
        aresetn : in STD_LOGIC;
        s_axis_xt_tvalid : in STD_LOGIC; s_axis_xt_tready : out STD_LOGIC; s_axis_xt_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
        s_axis_xt_prev_tvalid : in STD_LOGIC; s_axis_xt_prev_tready : out STD_LOGIC; s_axis_xt_prev_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
        s_axis_drift_tvalid : in STD_LOGIC; s_axis_drift_tready : out STD_LOGIC; s_axis_drift_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
        s_axis_threshold_tvalid : in STD_LOGIC; s_axis_threshold_tready : out STD_LOGIC; s_axis_threshold_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
        m_axis_label_tvalid : out STD_LOGIC; m_axis_label_tready : in STD_LOGIC; m_axis_label_tdata  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end cusum_detector;

architecture Behavioral of cusum_detector is
begin
    -- Always ready to receive data
    s_axis_xt_tready <= '1';
    s_axis_xt_prev_tready <= '1';
    s_axis_drift_tready <= '1';
    s_axis_threshold_tready <= '1';

    process(aclk)
        variable diff : integer;
        variable th   : integer;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                m_axis_label_tvalid <= '0';
                m_axis_label_tdata <= (others => '0');
            else
                if s_axis_xt_tvalid = '1' then
                    -- Simplified Anomaly Check: Abs(Current - Prev) > Threshold
                    diff := abs(to_integer(signed(s_axis_xt_tdata)) - to_integer(signed(s_axis_xt_prev_tdata)));
                    th   := to_integer(signed(s_axis_threshold_tdata));
                    
                    m_axis_label_tvalid <= '1';
                    
                    if diff > th then
                        m_axis_label_tdata <= std_logic_vector(to_unsigned(1, 32)); -- 1 = Anomaly
                    else
                        m_axis_label_tdata <= std_logic_vector(to_unsigned(0, 32)); -- 0 = Normal
                    end if;
                else
                    m_axis_label_tvalid <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;