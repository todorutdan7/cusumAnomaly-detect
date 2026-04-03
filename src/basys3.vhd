library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity basys3_top is
    Port ( 
        clk : in STD_LOGIC;
        sw  : in STD_LOGIC_VECTOR(15 downto 0);
        btn : in STD_LOGIC_VECTOR(4 downto 0);
        led : out STD_LOGIC_VECTOR(15 downto 0);
        cat : out STD_LOGIC_VECTOR(6 downto 0);
        an  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end basys3_top;

architecture Behavioral of basys3_top is

    COMPONENT blk_mem_gen_0
      PORT (
        clka : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);      
        addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);    
        douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        clkb : IN STD_LOGIC;
        web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);      
        addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);    
        doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;

    component cusum_detector is
        Port (
            aclk    : in STD_LOGIC;
            aresetn : in STD_LOGIC;
            s_axis_xt_tvalid : in STD_LOGIC; s_axis_xt_tready : out STD_LOGIC; s_axis_xt_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
            s_axis_xt_prev_tvalid : in STD_LOGIC; s_axis_xt_prev_tready : out STD_LOGIC; s_axis_xt_prev_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
            s_axis_drift_tvalid : in STD_LOGIC; s_axis_drift_tready : out STD_LOGIC; s_axis_drift_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
            s_axis_threshold_tvalid : in STD_LOGIC; s_axis_threshold_tready : out STD_LOGIC; s_axis_threshold_tdata  : in STD_LOGIC_VECTOR(31 downto 0);
            m_axis_label_tvalid : out STD_LOGIC; m_axis_label_tready : in STD_LOGIC; m_axis_label_tdata  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component debouncer is
        Port ( clk : in std_logic; btn : in std_logic; en : out std_logic );
    end component;

    component display_7seg is
        Port ( digit0, digit1, digit2, digit3 : in STD_LOGIC_VECTOR (3 downto 0); clk : in STD_LOGIC; cat : out STD_LOGIC_VECTOR (6 downto 0); an : out STD_LOGIC_VECTOR (3 downto 0));
    end component;

    signal rst_active_high : std_logic;
    signal sys_aresetn     : std_logic; 
    
    signal btn_debounced     : std_logic;
    signal btn_pulse         : std_logic; 
    signal btn_debounced_prev: std_logic := '0';

    signal current_index : unsigned(10 downto 0) := (others => '0');
    signal addr_curr_vec : std_logic_vector(10 downto 0);
    signal addr_prev_vec : std_logic_vector(10 downto 0);

    signal rom_xt      : std_logic_vector(31 downto 0);
    signal rom_xt_prev : std_logic_vector(31 downto 0);
    signal rom_wait_cnt: integer range 0 to 3 := 0; 

 
    signal axis_input_valid : std_logic := '0';
    signal axis_ready_dummy : std_logic; 
    
    signal result_valid : std_logic;
    signal result_data  : std_logic_vector(31 downto 0);
    signal latched_label: std_logic_vector(3 downto 0) := "0000";

    signal drift_val : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(50, 32));
    signal th_val    : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(200, 32));

    type state_type is (IDLE, UPDATE_ADDR, WAIT_ROM, SEND_DATA);
    signal state : state_type := IDLE;
    
    signal disp_d3, disp_d2, disp_d1, disp_d0 : std_logic_vector(3 downto 0);

begin

    -- reset active low 
    rst_active_high <= sw(0);
    sys_aresetn     <= not rst_active_high;
    
    -- led anomaly
    led(15 downto 4) <= (others => '0');
    led(3 downto 0)  <= latched_label; 

    -- address for xt xt-1
    addr_curr_vec <= std_logic_vector(current_index);
    addr_prev_vec <= std_logic_vector(current_index - 1) when current_index > 0 else (others => '0');

    -- 7seg
    disp_d3 <= "0" & std_logic_vector(current_index(10 downto 8)); 
    disp_d2 <= std_logic_vector(current_index(7 downto 4));
    disp_d1 <= std_logic_vector(current_index(3 downto 0));
    disp_d0 <= latched_label; 
    
    -- ip catalog rom 
    u_rom_ip : blk_mem_gen_0
    PORT MAP (
        clka => clk,
        wea => "0",                 
        addra => addr_curr_vec,
        dina => (others => '0'),    
        douta => rom_xt,
        
        clkb => clk,
        web => "0",                 
        addrb => addr_prev_vec,
        dinb => (others => '0'),    
        doutb => rom_xt_prev
    );
    
    -- debouncer 
    u_debouncer : debouncer port map ( 
        clk => clk, 
        btn => btn(0), 
        en  => btn_debounced 
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if sys_aresetn = '0' then
                btn_debounced_prev <= '0';
                btn_pulse <= '0';
            else
                btn_debounced_prev <= btn_debounced;
                if btn_debounced = '1' and btn_debounced_prev = '0' then
                    btn_pulse <= '1';
                else
                    btn_pulse <= '0';
                end if;
            end if;
        end if;
    end process;

    -- port map cusum 
    u_cusum : cusum_detector port map (
        aclk => clk, 
        aresetn => sys_aresetn,
        
  
        s_axis_xt_tvalid      => axis_input_valid, 
        s_axis_xt_tready      => axis_ready_dummy, 
        s_axis_xt_tdata       => rom_xt,
        
        s_axis_xt_prev_tvalid => axis_input_valid, 
        s_axis_xt_prev_tready => open, 
        s_axis_xt_prev_tdata  => rom_xt_prev,
        
       
        s_axis_drift_tvalid     => '1', 
        s_axis_drift_tready     => open, 
        s_axis_drift_tdata      => drift_val,
        
        s_axis_threshold_tvalid => '1', 
        s_axis_threshold_tready => open, 
        s_axis_threshold_tdata  => th_val,
        
        
        m_axis_label_tvalid => result_valid, 
        m_axis_label_tready => '1', 
        m_axis_label_tdata  => result_data
    );

    -- 7 seg port map 
    u_disp : display_7seg port map (
        digit3 => disp_d3,
        digit2 => disp_d2,  
        digit1 => disp_d1, 
        digit0 => disp_d0,  
        clk => clk, cat => cat, an => an
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if sys_aresetn = '0' then
                -- idle state dont do anything
                state <= IDLE;
                current_index <= (others => '0');
                axis_input_valid <= '0';
                rom_wait_cnt <= 0;
            else
                case state is
                    
                    when IDLE =>
                        -- go to update addr
                        axis_input_valid <= '0';
                        if btn_pulse = '1' then
                            state <= UPDATE_ADDR;
                        end if;
                    
                    when UPDATE_ADDR =>
                        if current_index < 2047 then
                            current_index <= current_index + 1;
                        else
                            current_index <= (others => '0');
                        end if;
                        state <= WAIT_ROM;
                        rom_wait_cnt <= 0;

                    when WAIT_ROM =>
                        -- wait 2 clk cycles 
                        if rom_wait_cnt = 2 then
                            state <= SEND_DATA;
                        else
                            rom_wait_cnt <= rom_wait_cnt + 1;
                        end if;

                    when SEND_DATA =>
                        
                        axis_input_valid <= '1';
                        state <= IDLE; 
                        
                end case;
            end if;
        end if;
    end process;





    process(clk)
    begin
        if rising_edge(clk) then
            if sys_aresetn = '0' then
                latched_label <= "0000";
            else
                if result_valid = '1' then
                    latched_label <= "000" & result_data(0);
                end if;
            end if;
        end if;
    end process;

end Behavioral;