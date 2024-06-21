library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;  
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;  
use work.FF.all;

-- This register is organized as follows:
-- There are NClauses registers, one for each clause.
-- Each register consists of 2*FSize SINGLE BITS.
-- All these output signals will be available continuously.
-- E.g., REGISTER(5) is the register containing the 2*FSize include/exclude signals for clause no. 5.  
-- It is only possible to update a single register one at a time. 
-- NOTE: A 0 bit in InclExcl (or InputMSBs) means "INCLUDE". 

entity REGISTER_IncludeEXclude is       
  Port (
        i_clk                   : in STD_LOGIC;
        i_rst                   : in STD_LOGIC;
        i_EnWriteMSBsTAs        : in std_logic; -- Enable write from TA MSBs to register 
        i_WriteAddr             : in std_logic_vector(NBitsClauseAddr-1 downto 0); -- Clause address
        i_InputMSBsTAs_update   : in std_logic_vector(2*FSize-1 downto 0); -- from TA RAMs ("next state" MSBs for for a given clause)
        o_InclExcl              : out include_exclude_signals
        );  
end REGISTER_IncludeEXclude;   

architecture rtl of REGISTER_IncludeEXclude is 
    
    signal w_currentstate   : include_exclude_signals;
    signal w_nxtstate       :  include_exclude_signals; 
    signal w_updateFromTA   : std_logic_vector(NClauses-1 downto 0);
    
begin

        AZ: FOR ja in 0 to NClauses-1 GENERATE
                 w_updateFromTA(ja) <='1' when i_WriteAddr=std_logic_vector(to_unsigned(ja, i_WriteAddr'length)) else '0';   
        end GENERATE AZ; 
    
    A1: FOR k in 0 to NClauses-1 GENERATE                                                                         

        w_nxtstate(k) <=          (others=>'0') when i_rst='1' 
                            else i_InputMSBsTAs_update when (i_EnWriteMSBsTAs='1' and w_updateFromTA(k)='1') -- when updating the IEregister from the TA RAM (for a given clause)
                            else w_currentstate(k);
                    
        MSBregister: vDFF generic map(2*FSize) port map(i_clk, w_nxtstate(k), w_currentstate(k));
        
        o_InclExcl(k) <= w_currentstate(k);
                          
    end GENERATE A1;
                              
end rtl;