library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cusum_detector is
    Port (
        aclk    : in STD_LOGIC;
        aresetn : in STD_LOGIC;

        s_axis_xt_tvalid : in STD_LOGIC;
        s_axis_xt_tready : out STD_LOGIC;
        s_axis_xt_tdata  : in STD_LOGIC_VECTOR(31 downto 0);

        s_axis_xt_prev_tvalid : in STD_LOGIC;
        s_axis_xt_prev_tready : out STD_LOGIC;
        s_axis_xt_prev_tdata  : in STD_LOGIC_VECTOR(31 downto 0);

        s_axis_drift_tvalid : in STD_LOGIC;
        s_axis_drift_tready : out STD_LOGIC;
        s_axis_drift_tdata  : in STD_LOGIC_VECTOR(31 downto 0);

        s_axis_threshold_tvalid : in STD_LOGIC;
        s_axis_threshold_tready : out STD_LOGIC;
        s_axis_threshold_tdata  : in STD_LOGIC_VECTOR(31 downto 0);

        m_axis_label_tvalid : out STD_LOGIC;
        m_axis_label_tready : in STD_LOGIC;
        m_axis_label_tdata  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end cusum_detector;

architecture Structural of cusum_detector is

    component axis_subtractor is
        Port (
            aclk : IN STD_LOGIC;
            s_axis_a_tvalid : IN STD_LOGIC; s_axis_a_tready : OUT STD_LOGIC; s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_b_tvalid : IN STD_LOGIC; s_axis_b_tready : OUT STD_LOGIC; s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC; m_axis_result_tready : IN STD_LOGIC; m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    component axis_adder is
        Port (
            aclk : IN STD_LOGIC;
            s_axis_a_tvalid : IN STD_LOGIC; s_axis_a_tready : OUT STD_LOGIC; s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_b_tvalid : IN STD_LOGIC; s_axis_b_tready : OUT STD_LOGIC; s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC; m_axis_result_tready : IN STD_LOGIC; m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    component axis_broadcaster is
        Port (
            aclk : IN STD_LOGIC;
            s_axis_tvalid : IN STD_LOGIC; s_axis_tready : OUT STD_LOGIC; s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_1_tvalid : OUT STD_LOGIC; m_axis_1_tready : IN STD_LOGIC; m_axis_1_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_2_tvalid : OUT STD_LOGIC; m_axis_2_tready : IN STD_LOGIC; m_axis_2_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    component axis_fifo is
        Generic ( DEPTH : integer := 64; WIDTH : integer := 32 );
        Port (
            aclk : IN STD_LOGIC; aresetn : IN STD_LOGIC;
            s_axis_tvalid : IN STD_LOGIC; s_axis_tready : OUT STD_LOGIC; s_axis_tdata : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
            m_axis_tvalid : OUT STD_LOGIC; m_axis_tready : IN STD_LOGIC; m_axis_tdata : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
        );
    end component;

    component axis_max is
        Port (
            aclk : IN STD_LOGIC;
            s_axis_a_tvalid : IN STD_LOGIC; s_axis_a_tready : OUT STD_LOGIC; s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_b_tvalid : IN STD_LOGIC; s_axis_b_tready : OUT STD_LOGIC; s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC; m_axis_result_tready : IN STD_LOGIC; m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    component axis_cusum_comparator is
        Port (
            aclk : IN STD_LOGIC;
            s_axis_gp_tvalid : IN STD_LOGIC; s_axis_gp_tready : OUT STD_LOGIC; s_axis_gp_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_gm_tvalid : IN STD_LOGIC; s_axis_gm_tready : OUT STD_LOGIC; s_axis_gm_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_th_tvalid : IN STD_LOGIC; s_axis_th_tready : OUT STD_LOGIC; s_axis_th_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_gp_out_tvalid : OUT STD_LOGIC; m_axis_gp_out_tready : IN STD_LOGIC; m_axis_gp_out_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_gm_out_tvalid : OUT STD_LOGIC; m_axis_gm_out_tready : IN STD_LOGIC; m_axis_gm_out_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_label_tvalid : OUT STD_LOGIC; m_axis_label_tready : IN STD_LOGIC; m_axis_label_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    -- inputs
    signal fifo_xt_valid, fifo_xt_ready : std_logic;
    signal fifo_xt_data : std_logic_vector(31 downto 0);
    signal fifo_xt_prev_valid, fifo_xt_prev_ready : std_logic;
    signal fifo_xt_prev_data : std_logic_vector(31 downto 0);

    -- ST
    signal sub_st_valid, sub_st_ready : std_logic;
    signal sub_st_data : std_logic_vector(31 downto 0);
    signal fifo_st_valid, fifo_st_ready : std_logic;
    signal fifo_st_data : std_logic_vector(31 downto 0);
    signal st_pos_valid, st_pos_ready : std_logic;
    signal st_pos_data : std_logic_vector(31 downto 0);
    signal st_neg_valid, st_neg_ready : std_logic;
    signal st_neg_data : std_logic_vector(31 downto 0);

    -- drift
    signal drift_pos_valid, drift_pos_ready : std_logic;
    signal drift_pos_data : std_logic_vector(31 downto 0);
    signal drift_neg_valid, drift_neg_ready : std_logic;
    signal drift_neg_data : std_logic_vector(31 downto 0);

    -- feedback
    signal fifo_fb_gp_valid, fifo_fb_gp_ready : std_logic;
    signal fifo_fb_gp_data : std_logic_vector(31 downto 0);
    signal fifo_fb_gm_valid, fifo_fb_gm_ready : std_logic;
    signal fifo_fb_gm_data : std_logic_vector(31 downto 0);

    -- mux
    signal init_gp_mux_valid, init_gp_mux_ready : std_logic;
    signal init_gp_mux_data : std_logic_vector(31 downto 0);
    signal init_gm_mux_valid, init_gm_mux_ready : std_logic;
    signal init_gm_mux_data : std_logic_vector(31 downto 0);

    -- init
    type init_state_type is (IDLE, RUNNING);
    signal gp_state : init_state_type := IDLE;
    signal gm_state : init_state_type := IDLE;

    -- positive top part
    signal add_pos_valid, add_pos_ready : std_logic;
    signal add_pos_data : std_logic_vector(31 downto 0);
    signal fifo_add_pos_valid, fifo_add_pos_ready : std_logic;
    signal fifo_add_pos_data : std_logic_vector(31 downto 0);
    signal sub_drift_pos_valid, sub_drift_pos_ready : std_logic;
    signal sub_drift_pos_data : std_logic_vector(31 downto 0);
    signal fifo_drift_pos_valid, fifo_drift_pos_ready : std_logic;
    signal fifo_drift_pos_data : std_logic_vector(31 downto 0);
    signal max_pos_valid, max_pos_ready : std_logic;
    signal max_pos_data : std_logic_vector(31 downto 0);
    signal fifo_max_pos_valid, fifo_max_pos_ready : std_logic;
    signal fifo_max_pos_data : std_logic_vector(31 downto 0);

    -- negative bottom part
    signal sub_neg_valid, sub_neg_ready : std_logic;
    signal sub_neg_data : std_logic_vector(31 downto 0);
    signal fifo_sub_neg_valid, fifo_sub_neg_ready : std_logic;
    signal fifo_sub_neg_data : std_logic_vector(31 downto 0);
    signal sub_drift_neg_valid, sub_drift_neg_ready : std_logic;
    signal sub_drift_neg_data : std_logic_vector(31 downto 0);
    signal fifo_drift_neg_valid, fifo_drift_neg_ready : std_logic;
    signal fifo_drift_neg_data : std_logic_vector(31 downto 0);
    signal max_neg_valid, max_neg_ready : std_logic;
    signal max_neg_data : std_logic_vector(31 downto 0);
    signal fifo_max_neg_valid, fifo_max_neg_ready : std_logic;
    signal fifo_max_neg_data : std_logic_vector(31 downto 0);

    -- comparator & feedback loop
    signal next_gp_valid, next_gp_ready : std_logic;
    signal next_gp_data : std_logic_vector(31 downto 0);
    signal next_gm_valid, next_gm_ready : std_logic;
    signal next_gm_data : std_logic_vector(31 downto 0);

    -- zero constant
    signal zero_valid : std_logic := '1';
    signal zero_data  : std_logic_vector(31 downto 0) := (others => '0');

begin
    -- always zero tvalid 1
    zero_valid <= '1';
    zero_data  <= (others => '0');

    -- fifo for xt
    FIFO_XT : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => s_axis_xt_tvalid, s_axis_tready => s_axis_xt_tready, s_axis_tdata => s_axis_xt_tdata,
        m_axis_tvalid => fifo_xt_valid, m_axis_tready => fifo_xt_ready, m_axis_tdata => fifo_xt_data
    );
    -- fifo for xt - 1
    FIFO_XT_PREV : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => s_axis_xt_prev_tvalid, s_axis_tready => s_axis_xt_prev_tready, s_axis_tdata => s_axis_xt_prev_tdata,
        m_axis_tvalid => fifo_xt_prev_valid, m_axis_tready => fifo_xt_prev_ready, m_axis_tdata => fifo_xt_prev_data
    );

    -- subtractor 
    SUB_ST : axis_subtractor
    port map (
        aclk => aclk,
        s_axis_a_tvalid => fifo_xt_valid, s_axis_a_tready => fifo_xt_ready, s_axis_a_tdata => fifo_xt_data,
        s_axis_b_tvalid => fifo_xt_prev_valid, s_axis_b_tready => fifo_xt_prev_ready, s_axis_b_tdata => fifo_xt_prev_data,
        m_axis_result_tvalid => sub_st_valid, m_axis_result_tready => sub_st_ready, m_axis_result_tdata => sub_st_data
    );

    -- subtractor to fifo 
    FIFO_ST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => sub_st_valid, s_axis_tready => sub_st_ready, s_axis_tdata => sub_st_data,
        m_axis_tvalid => fifo_st_valid, m_axis_tready => fifo_st_ready, m_axis_tdata => fifo_st_data
    );

    -- fifo to broadcaster
    BROAD_ST : axis_broadcaster
    port map (
        aclk => aclk,
        s_axis_tvalid => fifo_st_valid, s_axis_tready => fifo_st_ready, s_axis_tdata => fifo_st_data,
        m_axis_1_tvalid => st_pos_valid, m_axis_1_tready => st_pos_ready, m_axis_1_tdata => st_pos_data,
        m_axis_2_tvalid => st_neg_valid, m_axis_2_tready => st_neg_ready, m_axis_2_tdata => st_neg_data
    );

    -- drift broadcaster
    BROAD_DRIFT : axis_broadcaster
    port map (
        aclk => aclk,
        s_axis_tvalid => s_axis_drift_tvalid, s_axis_tready => s_axis_drift_tready, s_axis_tdata => s_axis_drift_tdata,
        m_axis_1_tvalid => drift_pos_valid, m_axis_1_tready => drift_pos_ready, m_axis_1_tdata => drift_pos_data,
        m_axis_2_tvalid => drift_neg_valid, m_axis_2_tready => drift_neg_ready, m_axis_2_tdata => drift_neg_data
    );

    -- 0 initial for g plus
    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            gp_state <= IDLE;
        elsif rising_edge(aclk) then
            if gp_state = IDLE then
                if init_gp_mux_ready = '1' then
                    gp_state <= RUNNING;
                end if;
            end if;
        end if;
    end process;
    -- if idle state tvalid 1, cuz 0 always valid, if running valid from fifo
    init_gp_mux_valid <= '1' when gp_state = IDLE else fifo_fb_gp_valid;
    -- if idle state send 0 if running send data from fifo
    init_gp_mux_data  <= (others => '0') when gp_state = IDLE else fifo_fb_gp_data;
    -- if idle dont read from fifo, keep ready 0, if running read value from fifo
    fifo_fb_gp_ready  <= init_gp_mux_ready when gp_state = RUNNING else '0';


    -- 0  initial for g minus
    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            gm_state <= IDLE;
        elsif rising_edge(aclk) then
            if gm_state = IDLE then
                if init_gm_mux_ready = '1' then
                    gm_state <= RUNNING;
                end if;
            end if;
        end if;
    end process;

    init_gm_mux_valid <= '1' when gm_state = IDLE else fifo_fb_gm_valid;
    init_gm_mux_data  <= (others => '0') when gm_state = IDLE else fifo_fb_gm_data;
    fifo_fb_gm_ready  <= init_gm_mux_ready when gm_state = RUNNING else '0';

    -- adder fifo sub fifo max fifo 
    ADD_POS : axis_adder
    port map (
        aclk => aclk,
        s_axis_a_tvalid => init_gp_mux_valid, s_axis_a_tready => init_gp_mux_ready, s_axis_a_tdata => init_gp_mux_data,
        s_axis_b_tvalid => st_pos_valid, s_axis_b_tready => st_pos_ready, s_axis_b_tdata => st_pos_data,
        m_axis_result_tvalid => add_pos_valid, m_axis_result_tready => add_pos_ready, m_axis_result_tdata => add_pos_data
    );

    FIFO_ADD_POS_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => add_pos_valid, s_axis_tready => add_pos_ready, s_axis_tdata => add_pos_data,
        m_axis_tvalid => fifo_add_pos_valid, m_axis_tready => fifo_add_pos_ready, m_axis_tdata => fifo_add_pos_data
    );

    SUB_DRIFT_POS : axis_subtractor
    port map (
        aclk => aclk,
        s_axis_a_tvalid => fifo_add_pos_valid, s_axis_a_tready => fifo_add_pos_ready, s_axis_a_tdata => fifo_add_pos_data,
        s_axis_b_tvalid => drift_pos_valid, s_axis_b_tready => drift_pos_ready, s_axis_b_tdata => drift_pos_data,
        m_axis_result_tvalid => sub_drift_pos_valid, m_axis_result_tready => sub_drift_pos_ready, m_axis_result_tdata => sub_drift_pos_data
    );

    FIFO_DRIFT_POS_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => sub_drift_pos_valid, s_axis_tready => sub_drift_pos_ready, s_axis_tdata => sub_drift_pos_data,
        m_axis_tvalid => fifo_drift_pos_valid, m_axis_tready => fifo_drift_pos_ready, m_axis_tdata => fifo_drift_pos_data
    );

    MAX_POS : axis_max
    port map (
        aclk => aclk,
        s_axis_a_tvalid => fifo_drift_pos_valid, s_axis_a_tready => fifo_drift_pos_ready, s_axis_a_tdata => fifo_drift_pos_data,
        s_axis_b_tvalid => zero_valid, s_axis_b_tready => open, s_axis_b_tdata => zero_data,
        m_axis_result_tvalid => max_pos_valid, m_axis_result_tready => max_pos_ready, m_axis_result_tdata => max_pos_data
    );

    FIFO_MAX_POS_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => max_pos_valid, s_axis_tready => max_pos_ready, s_axis_tdata => max_pos_data,
        m_axis_tvalid => fifo_max_pos_valid, m_axis_tready => fifo_max_pos_ready, m_axis_tdata => fifo_max_pos_data
    );

    -- sub fifo sub fifo max fifo
    SUB_NEG : axis_subtractor
    port map (
        aclk => aclk,
        s_axis_a_tvalid => init_gm_mux_valid, s_axis_a_tready => init_gm_mux_ready, s_axis_a_tdata => init_gm_mux_data,
        s_axis_b_tvalid => st_neg_valid, s_axis_b_tready => st_neg_ready, s_axis_b_tdata => st_neg_data,
        m_axis_result_tvalid => sub_neg_valid, m_axis_result_tready => sub_neg_ready, m_axis_result_tdata => sub_neg_data
    );

    FIFO_SUB_NEG_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => sub_neg_valid, s_axis_tready => sub_neg_ready, s_axis_tdata => sub_neg_data,
        m_axis_tvalid => fifo_sub_neg_valid, m_axis_tready => fifo_sub_neg_ready, m_axis_tdata => fifo_sub_neg_data
    );

    SUB_DRIFT_NEG : axis_subtractor
    port map (
        aclk => aclk,
        s_axis_a_tvalid => fifo_sub_neg_valid, s_axis_a_tready => fifo_sub_neg_ready, s_axis_a_tdata => fifo_sub_neg_data,
        s_axis_b_tvalid => drift_neg_valid, s_axis_b_tready => drift_neg_ready, s_axis_b_tdata => drift_neg_data,
        m_axis_result_tvalid => sub_drift_neg_valid, m_axis_result_tready => sub_drift_neg_ready, m_axis_result_tdata => sub_drift_neg_data
    );

    FIFO_DRIFT_NEG_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => sub_drift_neg_valid, s_axis_tready => sub_drift_neg_ready, s_axis_tdata => sub_drift_neg_data,
        m_axis_tvalid => fifo_drift_neg_valid, m_axis_tready => fifo_drift_neg_ready, m_axis_tdata => fifo_drift_neg_data
    );

    MAX_NEG : axis_max
    port map (
        aclk => aclk,
        s_axis_a_tvalid => fifo_drift_neg_valid, s_axis_a_tready => fifo_drift_neg_ready, s_axis_a_tdata => fifo_drift_neg_data,
        s_axis_b_tvalid => zero_valid, s_axis_b_tready => open, s_axis_b_tdata => zero_data,
        m_axis_result_tvalid => max_neg_valid, m_axis_result_tready => max_neg_ready, m_axis_result_tdata => max_neg_data
    );

    FIFO_MAX_NEG_INST : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => max_neg_valid, s_axis_tready => max_neg_ready, s_axis_tdata => max_neg_data,
        m_axis_tvalid => fifo_max_neg_valid, m_axis_tready => fifo_max_neg_ready, m_axis_tdata => fifo_max_neg_data
    );

    -- comparator
    COMP : axis_cusum_comparator
    port map (
        aclk => aclk,
        s_axis_gp_tvalid => fifo_max_pos_valid, s_axis_gp_tready => fifo_max_pos_ready, s_axis_gp_tdata => fifo_max_pos_data,
        s_axis_gm_tvalid => fifo_max_neg_valid, s_axis_gm_tready => fifo_max_neg_ready, s_axis_gm_tdata => fifo_max_neg_data,
        s_axis_th_tvalid => s_axis_threshold_tvalid, s_axis_th_tready => s_axis_threshold_tready, s_axis_th_tdata => s_axis_threshold_tdata,
        m_axis_gp_out_tvalid => next_gp_valid, m_axis_gp_out_tready => next_gp_ready, m_axis_gp_out_tdata => next_gp_data,
        m_axis_gm_out_tvalid => next_gm_valid, m_axis_gm_out_tready => next_gm_ready, m_axis_gm_out_tdata => next_gm_data,
        m_axis_label_tvalid => m_axis_label_tvalid, m_axis_label_tready => m_axis_label_tready, m_axis_label_tdata => m_axis_label_tdata
    );

    -- comparator back to g positive fifo
    FIFO_FEEDBACK_GP : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => next_gp_valid, s_axis_tready => next_gp_ready, s_axis_tdata => next_gp_data,
        m_axis_tvalid => fifo_fb_gp_valid, m_axis_tready => fifo_fb_gp_ready, m_axis_tdata => fifo_fb_gp_data
    );
    
    -- comprator back to g negative fifo
    FIFO_FEEDBACK_GM : axis_fifo generic map (DEPTH => 16)
    port map (
        aclk => aclk, aresetn => aresetn,
        s_axis_tvalid => next_gm_valid, s_axis_tready => next_gm_ready, s_axis_tdata => next_gm_data,
        m_axis_tvalid => fifo_fb_gm_valid, m_axis_tready => fifo_fb_gm_ready, m_axis_tdata => fifo_fb_gm_data
    );

end Structural;