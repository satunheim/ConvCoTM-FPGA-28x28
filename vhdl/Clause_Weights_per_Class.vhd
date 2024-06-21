library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;  
use IEEE.std_logic_unsigned.all;    
use work.FF.all;  
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;  
 
entity Clause_Weights_per_Class is 
    Port (
            i_clk                           : in STD_LOGIC;
            i_rst                           : in STD_LOGIC; 
            i_learn                         : in STD_LOGIC;
            i_en_Load_Model                 : in STD_LOGIC;
            i_update_from_model             : in STD_LOGIC;
            i_update_enable_from_training   : in std_logic;
            i_update_clauseweight_train     : in std_logic;
            
            i_W_Threshold_High              : in signed(NBitsIW-1 downto 0);
            i_W_Threshold_Low               : in signed(NBitsIW-1 downto 0);
            
            i_Initialize                    : in std_logic;
            i_initbit                       : in std_logic_vector(NClasses-1 downto 0); -- Random bits (single or multiple) from an LFSR during Initialization. One bit per class (from different LFSRs). 
            i_update_init                   : in STD_LOGIC;
            
            i_Class                         : in std_logic_vector(3 downto 0);
            i_ClauseAddress                 : in std_logic_vector(NBitsClauseAddr-1 downto 0);
            
            i_TypeIa                        : in std_logic;
            i_TypeII                        : in std_logic;
            
            -- For future implementation: Input weights from RAM (pre trained model). Updated in sequence clause by clause.
            i_ModelWeightClass0             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass1             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass2             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass3             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass4             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass5             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass6             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass7             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass8             : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass9             : in std_logic_vector(NBitsIW-1 downto 0);
            
            i_FSMstate                      : in std_logic_vector(SWIDTH-1 downto 0);
            
            o_weightClass0                  : out signed(NBitsIW-1 downto 0);
            o_weightClass1                  : out signed(NBitsIW-1 downto 0);
            o_weightClass2                  : out signed(NBitsIW-1 downto 0);
            o_weightClass3                  : out signed(NBitsIW-1 downto 0);
            o_weightClass4                  : out signed(NBitsIW-1 downto 0); 
            o_weightClass5                  : out signed(NBitsIW-1 downto 0);
            o_weightClass6                  : out signed(NBitsIW-1 downto 0);
            o_weightClass7                  : out signed(NBitsIW-1 downto 0);
            o_weightClass8                  : out signed(NBitsIW-1 downto 0);
            o_weightClass9                  : out signed(NBitsIW-1 downto 0)
            );     
end Clause_Weights_per_Class;

architecture rtl of Clause_Weights_per_Class is 

    type weightregister is array (0 to NClasses-1) of std_logic_vector(NBitsIW-1 downto 0); 
    type class_weights_per_clause is array (0 to NClasses-1) of  signed (NBitsIW-1 downto 0);

    signal w_ClauseWeightsA             : class_weights_per_clause;
    signal w_ModelweightClass           : class_weights_per_clause;
    signal w_IncrementVector            : signed (NBitsIW-1 downto 0); 
    signal w_DecrementVector            : signed (NBitsIW-1 downto 0); 
    
    signal w_Initialize                 : std_logic;
    signal w_nxt, w_regout              : weightregister;
    
    signal w_updateclassweight          : std_logic_vector(NClasses-1 downto 0);  -- 
    signal w_enableupdate               : std_logic_vector(NClasses-1 downto 0); 
    
    signal w_posW                       : std_logic_vector(NClasses-1 downto 0); 
     
begin
    
    w_IncrementVector <= (0 => '1', others => '0');
    w_DecrementVector <= (others => '1');
    
    w_ModelweightClass(0) <= signed(i_ModelWeightClass0);
    w_ModelweightClass(1) <= signed(i_ModelWeightClass1);
    w_ModelweightClass(2) <= signed(i_ModelWeightClass2);
    w_ModelweightClass(3) <= signed(i_ModelWeightClass3);
    w_ModelweightClass(4) <= signed(i_ModelWeightClass4);
    w_ModelweightClass(5) <= signed(i_ModelWeightClass5);
    w_ModelweightClass(6) <= signed(i_ModelWeightClass6);
    w_ModelweightClass(7) <= signed(i_ModelWeightClass7);
    w_ModelweightClass(8) <= signed(i_ModelWeightClass8);
    w_ModelweightClass(9) <= signed(i_ModelWeightClass9);
    
-----------------------------------------------------------
    G1: FOR K in 0 to NClasses-1 GENERATE 
    
            WeightRegister: vDFFce generic map(NBitsIW) port map(i_clk, w_enableupdate(K), w_nxt(K), w_regout(K));  

            w_enableupdate(K) <= '1' when i_rst='1' or (i_en_Load_Model='1' and i_update_from_model='1') 
                                           or (i_Initialize='1' and i_update_init='1') 
                                           or (w_updateclassweight(K)='1' and i_TypeIa='1') 
                                           or (w_updateclassweight(K)='1' and i_TypeII='1')
                                     else '0';
                                    
            w_updateclassweight(K) <='1' when (to_integer(unsigned(i_Class))=K and (i_FSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_FSMstate=Learn_UpdateClausesAndTAsAndWeights2) 
                                         and i_update_enable_from_training='1' and i_update_clauseweight_train='1')
                                         else '0';
            
            w_posW(K) <='1' when signed(w_regout(K)) >=0 else '0';

            w_nxt(K) <=  
                              std_logic_vector(w_ModelweightClass(k))                   when (i_en_Load_Model='1' and i_update_from_model='1') 
                         else std_logic_vector(w_IncrementVector)                       when (i_Initialize='1' and i_update_init='1' and i_initbit(K)='1') 
                         else std_logic_vector(w_DecrementVector)                       when (i_Initialize='1' and i_update_init='1' and i_initbit(K)='0') 
                         else std_logic_vector(signed(w_regout(K)) + w_IncrementVector) when (w_updateclassweight(K)='1' and i_TypeIa='1' and w_posW(K)='1') and (signed(w_regout(K)) < i_W_Threshold_High) 
                         else std_logic_vector(signed(w_regout(K)) - w_IncrementVector) when (w_updateclassweight(K)='1' and i_TypeIa='1' and w_posW(K)='0') and (signed(w_regout(K)) > i_W_Threshold_Low)
                         else std_logic_vector(signed(w_regout(K)) - w_IncrementVector) when (w_updateclassweight(K)='1' and i_TypeII='1' and w_posW(K)='1') 
                         else std_logic_vector(signed(w_regout(K)) + w_IncrementVector) when (w_updateclassweight(K)='1' and i_TypeII='1' and w_posW(K)='0') 
                         else w_regout(K);   
             
        END GENERATE G1;
-----------------------------------------------------------

        o_weightClass0 <= signed(w_regout(0));
        o_weightClass1 <= signed(w_regout(1));
        o_weightClass2 <= signed(w_regout(2));
        o_weightClass3 <= signed(w_regout(3));
        o_weightClass4 <= signed(w_regout(4));
        o_weightClass5 <= signed(w_regout(5));
        o_weightClass6 <= signed(w_regout(6));
        o_weightClass7 <= signed(w_regout(7));
        o_weightClass8 <= signed(w_regout(8));
        o_weightClass9 <= signed(w_regout(9));

end rtl;
