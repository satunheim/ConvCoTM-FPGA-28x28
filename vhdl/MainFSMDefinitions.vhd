library ieee;
use IEEE.STD_LOGIC_1164.ALL;

package MainFSMDefinitions is

    constant SWIDTH: Integer := 20;
    
    -- The states in FSM_main are one-hot encoded.
    
    constant InitialState         	                : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "000001";
    
    constant initializeLFSR                         : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "000010";
    constant InitializePhase0                       : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "000100";
    constant InitializeTAsAndLFSRsANDWeights        : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "001000";
    constant InitializePhase1                       : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "010000";
    constant FinishedInitialize                     : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "000" & "100000";
    
    constant Inference            	                : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "001" & "000000";  
    constant FinishedInference    	                : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "010" & "000000";
    constant keepClassDecision                      : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000000" & "100" & "000000"; 
    
    constant Learn_PatchGenAndReservoirSampling1    : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000001" & "000" & "000000";
    constant Learn_SamplePredictClass1              : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000010" & "000" & "000000";

    constant Learn_UpdateClausesAndTAsAndWeights1   : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0000100" & "000" & "000000";
    constant Learn_PatchGenAndReservoirSampling2    : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0001000" & "000" & "000000";
    constant Learn_SamplePredictClass2              : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0010000" & "000" & "000000";
    constant Learn_UpdateClausesAndTAsAndWeights2   : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "0100000" & "000" & "000000";
    constant FinishedTraining        	            : std_logic_vector(SWIDTH-1 downto 0)   := "0000" & "1000000" & "000" & "000000";
   
    -- The following states are defined but not used in the implementation. They are reserved for future use 
    -- for loading a model (TA actions and weights) from the system processsor.
    constant Phase0LoadMODEL                        : std_logic_vector(SWIDTH-1 downto 0)   := "0001" & "0000000" & "000" & "000000";
    constant LoadMODEL                              : std_logic_vector(SWIDTH-1 downto 0)   := "0010" & "0000000" & "000" & "000000";
    constant Phase1LoadMODEL                        : std_logic_vector(SWIDTH-1 downto 0)   := "0100" & "0000000" & "000" & "000000";
    constant FinishedLoadMODEL                      : std_logic_vector(SWIDTH-1 downto 0)   := "1000" & "0000000" & "000" & "000000";
     
    -- TBD: States for writing a trained model back to the system procesor.
    
end package;