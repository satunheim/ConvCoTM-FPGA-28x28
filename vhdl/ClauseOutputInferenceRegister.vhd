library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all; 
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;        
 
    
entity ClauseOutputInferenceRegister is
    port (
        i_clk, 
        i_rst, 
        i_update : std_logic;
        i_ClauseInputs  : in std_logic_vector(NClauses-1 downto 0);
        o_ClauseregOutp : out std_logic_vector(NClauses-1 downto 0)
        );                             
end ClauseOutputInferenceRegister;
 
architecture rtl of ClauseOutputInferenceRegister is

    signal w_nextstate, w_all0, w_currentstate : std_logic_vector(NClauses-1 downto 0);

begin

     w_all0 <= (others => '0');

     ClauseInfReg: vDFF generic map(NClauses) port map(i_clk, w_nextstate, w_currentstate);  
     
     w_nextstate <= (others => '0') when (i_rst='1') 
                    else (w_all0 OR i_ClauseInputs) when i_update='1' 
                    else (w_currentstate OR i_ClauseInputs);    
     
     o_ClauseregOutp <= w_currentstate;

end rtl;