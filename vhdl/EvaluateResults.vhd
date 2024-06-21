library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;     
use work.FF.all;  
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;  
 
entity EvaluateResults is 
    Port (
        i_clk               : in STD_LOGIC;
        i_rst               : in STD_LOGIC;
        i_sample_actual     : in std_logic;
        i_sample_predict    : in std_logic;    
        i_classActual       : in unsigned(3 downto 0);  
        i_classPredict      : in unsigned(3 downto 0);
        i_MainFSMstate      : in std_logic_vector(SWIDTH-1 downto 0);  
            
        o_correctPrediction  : out std_logic;
        o_result             : out std_logic_vector(7 downto 0) 
        );
         
end EvaluateResults;

architecture rtl of EvaluateResults is

    signal w_Next               : std_logic_vector(7 downto 0);
    signal w_Reg                : std_logic_vector(7 downto 0);
    
    signal w_actual_sampled    : std_logic_vector(3 downto 0);
    signal w_predict_sampled   : std_logic_vector(3 downto 0);

begin

    SampledResultandActual :  vDFF generic map(8) port map(i_clk, w_Next, w_Reg);

    w_Next <= (others=>'1') when i_rst='1'
              else std_logic_vector(i_classActual) & w_Reg(3 downto 0) when i_sample_actual='1' and (i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=FinishedInference)
              else w_Reg(7 downto 4) & std_logic_vector(i_classPredict) when i_sample_predict='1' and (i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=FinishedInference)
              else w_Reg;
    
    w_actual_sampled <= w_Reg(7 downto 4);
    w_predict_sampled <= w_Reg(3 downto 0);
    
    o_result <= w_actual_sampled & w_predict_sampled when 
                                (i_MainFSMstate=keepClassDecision 
                                or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1
                                or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2
                                or i_MainFSMstate=Learn_SamplePredictClass2
                                or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2
                                or i_MainFSMstate=FinishedTraining
                                )
                            else (others=>'1'); -- This is an unused class.
    
    o_correctPrediction <= '1' when w_actual_sampled = w_predict_sampled and 
                               (i_MainFSMstate=keepClassDecision 
                                or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1
                                or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2
                                or i_MainFSMstate=Learn_SamplePredictClass2
                                or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2
                                or i_MainFSMstate=FinishedTraining
                                )
                            else '0';

end rtl;