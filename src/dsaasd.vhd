library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axis_prepend_zero is
    Port (
        aclk    : IN STD_LOGIC;
        aresetn : IN STD_LOGIC;
        
        s_axis_tvalid : IN STD_LOGIC;
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tready : IN STD_LOGIC;
        m_axis_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end axis_prepend_zero;

architecture Behavioral of axis_prepend_zero is
    type state_type is (INIT_ZERO, PASS_THROUGH);
    signal state : state_type := INIT_ZERO;
begin
    process(aclk)
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                state <= INIT_ZERO;
            else
                case state is
                    when INIT_ZERO =>
                        if m_axis_tready = '1' then
                            state <= PASS_THROUGH;
                        end if;
                    when PASS_THROUGH =>
                end case;
            end if;
        end if;
    end process;

    m_axis_tvalid <= '1' when state = INIT_ZERO else s_axis_tvalid;
    m_axis_tdata  <= (others => '0') when state = INIT_ZERO else s_axis_tdata;
    
    s_axis_tready <= '0' when state = INIT_ZERO else m_axis_tready;

end Behavioral;