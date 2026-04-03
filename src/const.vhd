library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity axis_constant is
    Port (
        aclk : IN STD_LOGIC;
        val  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tready : IN STD_LOGIC;
        m_axis_tdata  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end axis_constant;

architecture Behavioral of axis_constant is
begin
    m_axis_tvalid <= '1';
    m_axis_tdata  <= val;
end Behavioral;


