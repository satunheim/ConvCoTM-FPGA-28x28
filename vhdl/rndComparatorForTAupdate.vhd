library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all; 

entity rndComparatorForTAupdate is
    Port   (  
            i_LFSRinput     : in  unsigned (23 downto 0); -- unsigned (23 downto 0);
            i_Rightside1    : in  unsigned(27 downto 0); -- signed(28 downto 0);
            i_Rightside2    : in  unsigned(27 downto 0); -- signed(28 downto 0);
            i_s_hyper       : in  unsigned(3 downto 0);
            i_MainFSMstate  : in  std_logic_vector(SWIDTH-1 downto 0);
            o_CompOut1      : out std_logic; -- for (s-1)/s
            o_CompOut2      : out std_logic -- for (1/s)
            );
end rndComparatorForTAupdate;

architecture RTL of rndComparatorForTAupdate is

    signal w_Leftside           : unsigned(27 downto 0);
    signal w_enable_comp_out    : std_logic;
    
begin
    
    w_enable_comp_out <= '1' when (i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2)
                        else '0';
    
    w_Leftside <= i_s_hyper * i_LFSRinput;
    
    o_CompOut1 <= '1' when (w_Leftside < i_Rightside1) and w_enable_comp_out='1' else '0'; 
    o_CompOut2 <= '1' when (w_Leftside < i_Rightside2) and w_enable_comp_out='1' else '0'; 

end RTL;
