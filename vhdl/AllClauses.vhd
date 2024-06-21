library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;
use work.SETTINGS_ConvCoTM.all; 
     
entity AllClauses is     
    Port ( i_literals           : in STD_LOGIC_VECTOR (2*FSize-1 downto 0);
           i_includeSignals     : in include_exclude_signals;
           i_train_mode         : in STD_LOGIC;
           i_clk                : in std_logic;
           i_rst                : in std_logic;         
           o_FromClauses        : out std_logic_vector(NClauses-1 downto 0);
           o_one_detected       : out std_logic_vector(NClauses-1 downto 0)
           ); 
end AllClauses;

architecture rtl of AllClauses is
    
    signal w_ClauseOutput   : std_logic_vector(NClauses-1 downto 0);
    signal w_nxt            : std_logic_vector(NClauses-1 downto 0);
    signal w_Reg            : std_logic_vector(NClauses-1 downto 0);

begin  

    GEN_CLAUSES: FOR k in 0 to NClauses-1 GENERATE 
        
        Clause : entity work.TM_Clause(rtl_2) 
                            port map (
                                i_literals          => i_literals, 
                                i_include           => i_includeSignals(k), 
                                i_train_mode        => i_train_mode, 
                                o_clause_out        => w_ClauseOutput(k) 
                                );
                            
         o_FromClauses(k) <= w_ClauseOutput(k);
         
         w_nxt(k) <= '1' when i_rst='0' and w_ClauseOutput(k)='1'
                      else '0';
         
    END GENERATE GEN_CLAUSES;
    
    o_one_detected <= w_Reg;
                                                                                                                 
end rtl;
