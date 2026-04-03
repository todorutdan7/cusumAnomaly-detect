library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axis_broadcaster is
    Port (
        aclk : IN STD_LOGIC;
        s_axis_tvalid : IN STD_LOGIC;
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_1_tvalid : OUT STD_LOGIC;
        m_axis_1_tready : IN STD_LOGIC;
        m_axis_1_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_2_tvalid : OUT STD_LOGIC;
        m_axis_2_tready : IN STD_LOGIC;
        m_axis_2_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end axis_broadcaster;

architecture Behavioral of axis_broadcaster is
    type state_type is (S_READ, S_WRITE);
    signal state : state_type := S_READ;
    
    signal stored_data : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal internal_ready : STD_LOGIC := '0';
begin

    s_axis_tready <= '1' when state = S_READ else '0';

    m_axis_1_tvalid <= '1' when state = S_WRITE else '0';
    m_axis_2_tvalid <= '1' when state = S_WRITE else '0';
    
    m_axis_1_tdata <= stored_data;
    m_axis_2_tdata <= stored_data;

    process(aclk)
    begin
        if rising_edge(aclk) then
            case state is
                when S_READ =>
                    if s_axis_tvalid = '1' then
                        stored_data <= s_axis_tdata;
                        state <= S_WRITE;
                    end if;

                when S_WRITE =>
                    if m_axis_1_tready = '1' and m_axis_2_tready = '1' then
                        state <= S_READ;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;