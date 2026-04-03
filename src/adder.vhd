library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity axis_adder is
    Port (
        aclk : IN STD_LOGIC;
        s_axis_a_tvalid : IN STD_LOGIC;
        s_axis_a_tready : OUT STD_LOGIC;
        s_axis_a_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_b_tvalid : IN STD_LOGIC;
        s_axis_b_tready : OUT STD_LOGIC;
        s_axis_b_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_result_tvalid : OUT STD_LOGIC;
        m_axis_result_tready : IN STD_LOGIC;
        m_axis_result_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end axis_adder;

architecture Behavioral of axis_adder is
    type state_type is (S_READ, S_WRITE);
    signal state : state_type := S_READ;

    signal result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal internal_ready, external_ready, inputs_valid : STD_LOGIC := '0';
begin
    internal_ready <= '1' when state = S_READ else '0';
    
    inputs_valid <= s_axis_a_tvalid and s_axis_b_tvalid;
    
    external_ready <= internal_ready and inputs_valid;

    s_axis_a_tready <= external_ready;
    s_axis_b_tready <= external_ready;

    m_axis_result_tvalid <= '1' when state = S_WRITE else '0';
    m_axis_result_tdata  <= result;

    process(aclk)
    begin
        if rising_edge(aclk) then
            case state is
                when S_READ =>
                    if external_ready = '1' then
                        result <= s_axis_a_tdata + s_axis_b_tdata;
                        state <= S_WRITE;
                    end if;

                when S_WRITE =>
                    if m_axis_result_tready = '1' then
                        state <= S_READ;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;