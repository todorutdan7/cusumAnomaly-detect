library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity axis_cusum_comparator is
    Port (
        aclk : IN STD_LOGIC;
        
        s_axis_gp_tvalid : IN STD_LOGIC;
        s_axis_gp_tready : OUT STD_LOGIC;
        s_axis_gp_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        s_axis_gm_tvalid : IN STD_LOGIC;
        s_axis_gm_tready : OUT STD_LOGIC;
        s_axis_gm_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        s_axis_th_tvalid : IN STD_LOGIC;
        s_axis_th_tready : OUT STD_LOGIC;
        s_axis_th_tdata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        m_axis_gp_out_tvalid : OUT STD_LOGIC;
        m_axis_gp_out_tready : IN STD_LOGIC;
        m_axis_gp_out_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        m_axis_gm_out_tvalid : OUT STD_LOGIC;
        m_axis_gm_out_tready : IN STD_LOGIC;
        m_axis_gm_out_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        m_axis_label_tvalid : OUT STD_LOGIC;
        m_axis_label_tready : IN STD_LOGIC;
        m_axis_label_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end axis_cusum_comparator;

architecture Behavioral of axis_cusum_comparator is
    type state_type is (S_READ, S_WRITE);
    signal state : state_type := S_READ;

    signal gp_res : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal gm_res : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal label_res : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    
    signal internal_ready, external_ready, inputs_valid : STD_LOGIC := '0';
    signal outputs_ready : STD_LOGIC := '0';

begin

    internal_ready <= '1' when state = S_READ else '0';
    inputs_valid <= s_axis_gp_tvalid and s_axis_gm_tvalid and s_axis_th_tvalid;
    external_ready <= internal_ready and inputs_valid;

    s_axis_gp_tready <= external_ready;
    s_axis_gm_tready <= external_ready;
    s_axis_th_tready <= external_ready;

    outputs_ready <= m_axis_gp_out_tready and m_axis_gm_out_tready and m_axis_label_tready;

    m_axis_gp_out_tvalid <= '1' when state = S_WRITE else '0';
    m_axis_gm_out_tvalid <= '1' when state = S_WRITE else '0';
    m_axis_label_tvalid  <= '1' when state = S_WRITE else '0';

    m_axis_gp_out_tdata <= gp_res;
    m_axis_gm_out_tdata <= gm_res;
    m_axis_label_tdata  <= label_res;

    process(aclk)
    begin
        if rising_edge(aclk) then
            case state is
                when S_READ =>
                    if external_ready = '1' then
                        if (s_axis_gp_tdata > s_axis_th_tdata) or (s_axis_gm_tdata > s_axis_th_tdata) then
                            label_res <= (0 => '1', others => '0'); 
                            gp_res <= (others => '0'); 
                            gm_res <= (others => '0'); 
                        else
                            label_res <= (others => '0'); 
                            gp_res <= s_axis_gp_tdata; 
                            gm_res <= s_axis_gm_tdata; 
                        end if;
                        
                        state <= S_WRITE;
                    end if;

                when S_WRITE =>
                    if outputs_ready = '1' then
                        state <= S_READ;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;