library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.SETTINGS_ConvCoTM.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;      
   
entity TM_Clause is    
        Port (
              i_literals, i_include : in STD_LOGIC_VECTOR (2*FSize-1 downto 0);  
              -- NOTE: i_include(k)='1' IMPLIES that literal k is INCLUDED.   
              
              i_train_mode          : in STD_LOGIC; 
              o_clause_out          : out STD_LOGIC
              ); 
end TM_Clause;

architecture rtl_2 of TM_Clause is
   
    signal w_or_outputs : std_logic_vector (2*FSize-1 downto 0); 
    signal w_and        : std_logic;
    signal w_or         : std_logic;
    signal w_clause_out : std_logic;
    
begin

    GenORSignals: FOR ka in 0 to 2*FSize-1 GENERATE                                                                         
        w_or_outputs(ka) <= i_literals(ka) or not(i_include(ka));                            
    end GENERATE GenORSignals;

    w_and <= and_reduce(w_or_outputs);
    
    w_or <= or_reduce(i_include);

----------------------------------------------------------------------
-- When training:  Clause output should be 1 if no literal is included (w_or=0).
-- When inference: Clause output should be 0 if no literal is included (w_and=0).

    w_clause_out <= (w_and and w_or) or (not(w_or) and i_train_mode);
    
    o_clause_out <= w_clause_out;

end rtl_2; 