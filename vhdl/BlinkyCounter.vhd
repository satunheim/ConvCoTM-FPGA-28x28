library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;  
use work.FF.all;    
use work.SETTINGS_ConvCoTM.all;   
       
entity BlinkyCounter is 
    Port (
            i_clk           : in STD_LOGIC;
            i_rst           : in STD_LOGIC; 
            i_ctrl1         : in STD_LOGIC;
            i_ctrl2         : in STD_LOGIC; 
            i_ctrl3         : in STD_LOGIC; 
            i_ctrl4         : in STD_LOGIC;
            o_PWMout        : out std_logic;
            o_counterOut    : out STD_LOGIC
            );
end BlinkyCounter;

architecture rtl of BlinkyCounter is

    signal w_nxtCB, w_regoutCB: std_logic_vector(34 downto 0);
    signal w_sel : std_logic_vector(3 downto 0);
    signal w_PWMoutA, w_counterOutA : std_logic;

begin 

    BlinkyCounter: vDFF generic map(35) port map(i_clk, w_nxtCB, w_regoutCB);
    
    w_nxtCB <=  (others=>'0') when i_rst='1' else
                w_regoutCB+("00000000000000000000000000000000001");
    
    w_sel <= i_ctrl1 & i_ctrl2 & i_ctrl3 & i_ctrl4;
                  
    with w_sel select
        w_counterOutA <=  w_regoutCB(23) when "0000",
                          w_regoutCB(24) when "1000",
                          w_regoutCB(25) when "0100",  
                          w_regoutCB(26) when "1100",
                          w_regoutCB(22) when "0010",
                          w_regoutCB(22) when "0001",             
                          w_regoutCB(27) when others;
    
    w_PWMoutA <= w_regoutCB(18) and w_regoutCB(17);    
    
    o_PWMout <= w_PWMoutA;
    o_counterOut <= w_counterOutA and w_PWMoutA;

end rtl;
