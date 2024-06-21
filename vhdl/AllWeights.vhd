library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;  
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;  
use work.FF.all;

entity AllWeights is 
    Port ( 
            i_clk                           : in STD_LOGIC; 
            i_rst                           : in STD_LOGIC; 
            i_learn                         : in STD_LOGIC;
            i_en_Load_Model                 : in std_logic;
            i_update_from_model             : in std_logic_vector(NClauses-1 downto 0);
            i_update_enable_from_training   : in std_logic;
            
            i_W_Threshold_Weight_High       : in std_logic_vector(NBitsIW-2 downto 0);
            
            i_enLFSRs_init                  : in std_logic;
            i_initialize                    : in std_logic;

            i_Class                         : in std_logic_vector(3 downto 0);
            
            i_ClauseAddress                 : in std_logic_vector(NBitsClauseAddr-1 downto 0);
            
            i_TypeIa                        : in std_logic;
            i_TypeII                        : in std_logic;
            
            i_FSMstate : in std_logic_vector(SWIDTH-1 downto 0);
            
            -- For future implementation: Input weights from RAM (pre trained model). Updates in sequence clause by clause.
            i_ModelWeightClass0  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass1  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass2  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass3  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass4  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass5  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass6  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass7  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass8  : in std_logic_vector(NBitsIW-1 downto 0);
            i_ModelWeightClass9  : in std_logic_vector(NBitsIW-1 downto 0);
            
            o_weightClass0  : out clause_weights;
            o_weightClass1  : out clause_weights;
            o_weightClass2  : out clause_weights;
            o_weightClass3  : out clause_weights;  
            o_weightClass4  : out clause_weights;
            o_weightClass5  : out clause_weights;
            o_weightClass6  : out clause_weights;
            o_weightClass7  : out clause_weights;
            o_weightClass8  : out clause_weights;
            o_weightClass9  : out clause_weights
            );    
end AllWeights;

architecture rtl of AllWeights is 
    
    signal w_weightClass0  : clause_weights;
    signal w_weightClass1  : clause_weights;
    signal w_weightClass2  : clause_weights;
    signal w_weightClass3  : clause_weights;
    signal w_weightClass4  : clause_weights;
    signal w_weightClass5  : clause_weights;
    signal w_weightClass6  : clause_weights;
    signal w_weightClass7  : clause_weights;
    signal w_weightClass8  : clause_weights;
    signal w_weightClass9  : clause_weights;
    
    signal w_W_Threshold_High : signed(NBitsIW-1 downto 0);
    signal w_W_Threshold_Low  : signed(NBitsIW-1 downto 0);
    signal w_zero             : signed (NBitsIW-1 downto 0);
    
    signal w_initbit          : std_logic_vector(NClasses-1 downto 0); -- Random bits (single or multiple) from an LFSR during Initialization. One bit per class (from different LFSRs). 
    
    type   lfsrWeightsword is array (0 to NClasses-1) of std_logic_vector(15 downto 0);
    
    signal w_seed16           : lfsrWeightsword;
    signal w_regout16         : lfsrWeightsword;
    signal w_en_LFSR_init     : std_logic;
    
    type   kArray is array (0 to NClauses-1) of std_logic_vector(NBitsClauseAddr-1 downto 0);
    signal w_kAddr : kArray;
    
    signal w_update_initialization      : std_logic_vector(NClauses-1 downto 0);
    signal w_update_clauseweight_train  : std_logic_vector(NClauses-1 downto 0);
--------------------------------------------------------------------------------------

begin
  
    w_zero              <= (others => '0');
    w_W_Threshold_High  <= signed('0' & i_W_Threshold_Weight_High);
    w_W_Threshold_Low   <= w_zero - w_W_Threshold_High; 
    
    w_en_LFSR_init <= i_rst or i_initialize or i_enLFSRs_init; 
    -- The LFSRs in this module are only enabled during reset of initialization
    
    -- We could reuse LFSRs from the TrainCoTM module, but for simplicity 10 LFSRs are included here. Can be modified later if desired.
    G1: FOR g in 0 to NClasses-1 GENERATE 
    
            SingleLFSR16InitWeights : entity work.LFSR16t15t13t4t(RTL)
                         port map (
                                  clk       => i_clk, 
                                  i_rst     => i_rst, 
                                  i_en      => w_en_LFSR_init, 
                                  i_seed    => w_seed16(g), 
                                  o_regout  => w_regout16(g)
                                  );
                                  
            w_seed16(g)  <= '0' & std_logic_vector(to_unsigned(g,4)) & '0' & not(std_logic_vector(to_unsigned(g,4))) & '0' & std_logic_vector(to_unsigned(g,4)) &'1';
            w_initbit(g) <=w_regout16(g)(0);
    
     END GENERATE G1;
    
  -- Generate one set of weights for each class (output):
  ALL1: FOR k in 0 to NClauses-1 GENERATE 
  
     w_kAddr(k) <= std_logic_vector(to_unsigned(k, w_kAddr(k)'length));   
     w_update_initialization(k) <='1' when (i_ClauseAddress=w_kAddr(k) and i_initialize='1') else '0';
     w_update_clauseweight_train(k) <='1' when (i_ClauseAddress=w_kAddr(k) and i_update_enable_from_training='1') else '0';  
  
     ModuleClassWeightsPerClause : entity work.Clause_Weights_per_Class(rtl) 
       port map (
                 i_clk                          => i_clk, 
                 i_rst                          => i_rst, 
                 i_learn                        => i_learn, 
                 i_en_Load_Model                => i_en_Load_Model,
                 i_update_from_model            => i_update_from_model(k),
                 i_update_enable_from_training  => i_update_enable_from_training,
                 i_update_clauseweight_train    => w_update_clauseweight_train(k),
                 
                 i_W_Threshold_High             => w_W_Threshold_High,
                 i_W_Threshold_Low              => w_W_Threshold_Low,
                 
                 i_initialize                   => i_initialize,
                 i_initbit                      => w_initbit,  -- one random bit per class
                 i_update_init                  => w_update_initialization(k),
              
                 i_Class                        => i_Class,
                 i_ClauseAddress                => i_ClauseAddress,
                 
                 i_TypeIa                       => i_TypeIa,
                 i_TypeII                       => i_TypeII,

                i_ModelWeightClass0             =>  i_ModelWeightClass0,
                i_ModelWeightClass1             =>  i_ModelWeightClass1,
                i_ModelWeightClass2             =>  i_ModelWeightClass2,
                i_ModelWeightClass3             =>  i_ModelWeightClass3,
                i_ModelWeightClass4             =>  i_ModelWeightClass4,
                i_ModelWeightClass5             =>  i_ModelWeightClass5,
                i_ModelWeightClass6             =>  i_ModelWeightClass6,
                i_ModelWeightClass7             =>  i_ModelWeightClass7,
                i_ModelWeightClass8             =>  i_ModelWeightClass8,
                i_ModelWeightClass9             =>  i_ModelWeightClass9,
                
                i_FSMstate                      => i_FSMstate,
                
                o_weightClass0                  =>  w_weightClass0(k),
                o_weightClass1                  =>  w_weightClass1(k),
                o_weightClass2                  =>  w_weightClass2(k),
                o_weightClass3                  =>  w_weightClass3(k),
                o_weightClass4                  =>  w_weightClass4(k),
                o_weightClass5                  =>  w_weightClass5(k),
                o_weightClass6                  =>  w_weightClass6(k),
                o_weightClass7                  =>  w_weightClass7(k),
                o_weightClass8                  =>  w_weightClass8(k),
                o_weightClass9                  =>  w_weightClass9(k)
              );
              
              ----------------------------------------------------------
                -- Connect wire signals to outputs:
                o_weightClass0(k) <= w_weightClass0(k);
                o_weightClass1(k) <= w_weightClass1(k);
                o_weightClass2(k) <= w_weightClass2(k);
                o_weightClass3(k) <= w_weightClass3(k);
                o_weightClass4(k) <= w_weightClass4(k);
                o_weightClass5(k) <= w_weightClass5(k);
                o_weightClass6(k) <= w_weightClass6(k);
                o_weightClass7(k) <= w_weightClass7(k);
                o_weightClass8(k) <= w_weightClass8(k);
                o_weightClass9(k) <= w_weightClass9(k);

    END GENERATE ALL1;

end rtl;
