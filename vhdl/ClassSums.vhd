library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all;  
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
 
entity ClassSums is   
    Port (
          i_clk                      : in STD_LOGIC;
          i_rst                      : in STD_LOGIC;
          i_adderEnable              : in STD_LOGIC;
          i_learn                    : in std_logic;
          i_sample_predict           : in std_logic;
          
          i_inputsFromSeqORedClauses : in STD_LOGIC_VECTOR (NClauses-1 downto 0); 
          
          i_weightClass0 : in clause_weights;
          i_weightClass1 : in clause_weights; 
          i_weightClass2 : in clause_weights;
          i_weightClass3 : in clause_weights; 
          i_weightClass4 : in clause_weights;
          i_weightClass5 : in clause_weights; 
          i_weightClass6 : in clause_weights;
          i_weightClass7 : in clause_weights; 
          i_weightClass8 : in clause_weights;
          i_weightClass9 : in clause_weights;       
          
          i_MainFSMstate : in std_logic_vector(SWIDTH-1 downto 0);
          
	      o_sumClass0    : out signed(NBsum-1 downto 0);  
	      o_sumClass1    : out signed(NBsum-1 downto 0);
	      o_sumClass2    : out signed(NBsum-1 downto 0);
	      o_sumClass3    : out signed(NBsum-1 downto 0);
	      o_sumClass4    : out signed(NBsum-1 downto 0);
	      o_sumClass5    : out signed(NBsum-1 downto 0); 
	      o_sumClass6    : out signed(NBsum-1 downto 0);
	      o_sumClass7    : out signed(NBsum-1 downto 0);
	      o_sumClass8    : out signed(NBsum-1 downto 0);
	      o_sumClass9    : out signed(NBsum-1 downto 0);
	      
	      o_sum0_stored  : out signed(NBsum-1 downto 0);
	      o_sum1_stored  : out signed(NBsum-1 downto 0);
	      o_sum2_stored  : out signed(NBsum-1 downto 0);
	      o_sum3_stored  : out signed(NBsum-1 downto 0);
	      o_sum4_stored  : out signed(NBsum-1 downto 0);
	      o_sum5_stored  : out signed(NBsum-1 downto 0);
	      o_sum6_stored  : out signed(NBsum-1 downto 0);
	      o_sum7_stored  : out signed(NBsum-1 downto 0);
	      o_sum8_stored  : out signed(NBsum-1 downto 0);
	      o_sum9_stored  : out signed(NBsum-1 downto 0)
	      ); 
	      
end ClassSums; 

architecture rtl of ClassSums is
    
    signal w_sumClass0 : signed(NBsum-1 downto 0);
    signal w_sumClass1 : signed(NBsum-1 downto 0);
    signal w_sumClass2 : signed(NBsum-1 downto 0);
    signal w_sumClass3 : signed(NBsum-1 downto 0);
    signal w_sumClass4 : signed(NBsum-1 downto 0);
    signal w_sumClass5 : signed(NBsum-1 downto 0);
    signal w_sumClass6 : signed(NBsum-1 downto 0);
    signal w_sumClass7 : signed(NBsum-1 downto 0);
    signal w_sumClass8 : signed(NBsum-1 downto 0);
    signal w_sumClass9 : signed(NBsum-1 downto 0);
    
    signal w_sum0_stored : signed(NBsum-1 downto 0);
    signal w_sum1_stored : signed(NBsum-1 downto 0);
    signal w_sum2_stored : signed(NBsum-1 downto 0);
    signal w_sum3_stored : signed(NBsum-1 downto 0);
    signal w_sum4_stored : signed(NBsum-1 downto 0);
    signal w_sum5_stored : signed(NBsum-1 downto 0);
    signal w_sum6_stored : signed(NBsum-1 downto 0);
    signal w_sum7_stored : signed(NBsum-1 downto 0);
    signal w_sum8_stored : signed(NBsum-1 downto 0);
    signal w_sum9_stored : signed(NBsum-1 downto 0);

begin
                                                                                                                                                       
    SingleModuleClassSum0: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable,
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass0, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass0,
                o_sum_stored        => w_sum0_stored
                ); 
                
       SingleModuleClassSum1: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable,
                i_sample_predict    => i_sample_predict,  
                i_clauseWeights     => i_weightClass1, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass1,
                o_sum_stored        => w_sum1_stored 
                );                      

       SingleModuleClassSum2: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass2, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass2,
                o_sum_stored        => w_sum2_stored 
                ); 
                
       SingleModuleClassSum3: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass3, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass3,
                o_sum_stored        => w_sum3_stored 
                );    

       SingleModuleClassSum4: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass4, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass4,
                o_sum_stored        => w_sum4_stored 
                );  
                
       SingleModuleClassSum5: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass5, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass5,
                o_sum_stored        => w_sum5_stored 
                ); 
                
       SingleModuleClassSum6: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass6, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass6,
                o_sum_stored        => w_sum6_stored 
                );                      

       SingleModuleClassSum7: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass7, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass7,
                o_sum_stored        => w_sum7_stored 
                ); 
                
       SingleModuleClassSum8: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass8, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass8,
                o_sum_stored        => w_sum8_stored 
                );    

       SingleModuleClassSum9: entity work.GenerateClassSum128pipe3(rtl) 
            port map(
                i_clk               => i_clk,
                i_rst               => i_rst, 
                i_adderEnable       => i_adderEnable, 
                i_sample_predict    => i_sample_predict, 
                i_clauseWeights     => i_weightClass9, 
                i_inputsFromClauses => i_inputsFromSeqORedClauses, 
                i_MainFSMstate      => i_MainFSMstate,
                o_sum               => w_sumClass9,
                o_sum_stored        => w_sum9_stored 
                );  

        -- Connect wires to outputs:
        o_sumClass0 <= w_sumClass0;
        o_sumClass1 <= w_sumClass1;
        o_sumClass2 <= w_sumClass2;
        o_sumClass3 <= w_sumClass3;
        o_sumClass4 <= w_sumClass4;
        o_sumClass5 <= w_sumClass5;
        o_sumClass6 <= w_sumClass6;
        o_sumClass7 <= w_sumClass7;
        o_sumClass8 <= w_sumClass8;
        o_sumClass9 <= w_sumClass9;
        
        o_sum0_stored <= w_sum0_stored;
        o_sum1_stored <= w_sum1_stored;
        o_sum2_stored <= w_sum2_stored;
        o_sum3_stored <= w_sum3_stored;
        o_sum4_stored <= w_sum4_stored;
        o_sum5_stored <= w_sum5_stored;
        o_sum6_stored <= w_sum6_stored;
        o_sum7_stored <= w_sum7_stored;
        o_sum8_stored <= w_sum8_stored;
        o_sum9_stored <= w_sum9_stored;

end rtl;