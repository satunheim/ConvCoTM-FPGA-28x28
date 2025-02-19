-----------------------------------------------
--
-- This is the VHDL top module for an FPGA implementation of a Convolutional Coalesced 
-- Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training.
-- The design is described in the paper "Tsetlin Machine-Based Image Classification FPGA Accelerator With On-Device Training" 
-- in IEEE Transactions on Circuits and Systems I: Regular Papers: https://ieeexplore.ieee.org/document/10812055.
--
--------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  

entity ConvCoTM28x28 is
    Port (
            clk                           : in std_logic;
            
            i_ctrl                        : in std_logic_vector(7 downto 0);

            -- Logical mapping of i_ctrl signals to single control signals: See also the 
            -- signal declaration within this top level module.
            --    i_rst                   :  i_ctrl(0); 
            --    i_start                 :  i_ctrl(1);
            --    i_learn                 :  i_ctrl(2);
            --    i_enLFSRs_init          :  i_ctrl(3);
            --    i_initialize            :  i_ctrl(4); 
            --    i_LoadModel             :  i_ctrl(5); -- Not implemented 
            --    i_image_buffer_reset    :  i_ctrl(6);
            --                               i_ctrl(7) is not used.

            
            -- Input registers from Processing System:
            i_config                      : in std_logic_vector(31 downto 0);
            i_lengthLFSRs                 : in std_logic_vector(2 downto 0);
            
            -- AXI interface:
            axi_clk                       : in std_logic;
            axi_reset_n                   : in std_logic;
             
            -- Slave interface:
            i_data_valid                  : in std_logic;
            i_data                        : in std_logic_vector(7 downto 0);
            o_data_ready                  : out std_logic; -- hardcoded to logical 1. 
            
	    ----------------------------------------------------
	    -- Outputs:

            o_intr                        : out std_logic; -- For monitoring during simulations.  

	        o_correctPrediction           : out std_logic; -- For monitoring during simulations.

            o_Result                      : out std_logic_vector(7 downto 0); 
                                            -- Fed to FPGA system processor.

            o_ImageLabel                  : out std_logic_vector(3 downto 0); 
                                            -- For monitoring during simulations.

            o_intr2                       : out std_logic; -- For monitoring during simulations.  
            ----
            o_LED1_InitialState           : out STD_LOGIC; -- LED indicating the main FSM is in "InitialState".
            o_LED2_FinishedInference      : out STD_LOGIC; -- LED indicating the main FSM is in "FinishedInference".
            o_LED3_FinishedLearn          : out STD_LOGIC; -- LED indicating the main FSM is in "FinishedLearn".
            
            o_statereg                    : out std_logic_vector(7 downto 0); 
                                            -- Fed to FPGA system processor. 
            
            o_blinkout 			          : out STD_LOGIC 
                                            -- Output from blinker. For diagnostics of the FPGA programming.
            );
end ConvCoTM28x28;

----------------------------------------------------------------------------------------------------------------------
architecture RTL of ConvCoTM28x28 is

-- SYNCH. SIGNALS:
    signal w_sync               : std_logic_vector(7 downto 0);

-- Main control signals:      
    signal w_rst                : STD_LOGIC; 
    signal w_start              : STD_LOGIC;
    signal w_learn              : STD_LOGIC;
    signal w_i_data_ready       : std_logic;
    
    signal w_enLFSRs_init       : std_logic;
    signal w_initialize         : std_logic;
    signal w_LoadModel          : std_logic;
    signal w_image_buffer_reset : std_logic;
    
    signal w_TA_high_threshold  : std_logic_vector(7 downto 0); -- (Here: UNSIGNED)
    
--    --For FSM_Main:
    signal w_EnModelLoad                        : std_logic;
    signal w_EnRAM_ModelLoad                    : std_logic;
    --Outputs:
    signal w_en_generate_patches                : std_logic;      
    signal w_resetBcounter                      : std_logic;
    signal w_clauseAddress                      : std_logic_vector(NBitsClauseAddr-1 downto 0);
    signal w_MainFSMstate                       : std_logic_vector(SWIDTH-1 downto 0);
    signal w_enable_adders                      : std_logic;
    signal w_sample_actual_class                : std_logic;
    signal w_sample_predicted_class             : std_logic;
    signal w_initializeTAs_and_Weights          : std_logic;
 
    ------------------------------
    -- For ImageBuffer:
    signal w_ImageLabel                         : std_logic_vector(3 downto 0);
    signal w_imagedata_ready                    : std_logic;
    signal w_selImage                           : std_logic;
    
    -- For Patch Generation:
    signal w_ClauseCounterFinished              : std_logic;
    signal w_ImagevectorRow0                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow1                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow2                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow3                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow4                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow5                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow6                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow7                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow8                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow9                    : std_logic_vector(ImageSize-1 downto 0); 
    signal w_ImagevectorRow10                   : std_logic_vector(ImageSize-1 downto 0); 
    
    signal w_reset_one_detected                 : std_logic;
    
    -- For Bcounter:
    signal w_BxCounterValue     : std_logic_vector(4 downto 0);
    signal w_ByCounterValue     : std_logic_vector(4 downto 0);
    signal w_PatchAddress       : std_logic_vector(NBitsPatchAddr-1 downto 0); 
    signal w_LoadNewRow         : STD_LOGIC;
    signal w_EndOfPatches       : STD_LOGIC; 

--    -- For REGISTER_IncludeEXclude:
    signal w_Model_IEbits               : std_logic_vector(2*FSize-1 downto 0); -- for a single clause
    signal w_incexcl_signals            : include_exclude_signals;
    signal w_EnWriteMSBsTAsIEreg        : std_logic;

    -- For AllClauses:
    signal w_patchliterals : std_logic_vector(2*FSize-1 downto 0);
    signal w_patchfeatures : std_logic_vector(FSize-1 downto 0);
    signal w_clauseOutputs : std_logic_vector(NClauses-1 downto 0);
    signal w_one_detected  : std_logic_vector(NClauses-1 downto 0);

    -- For ClauseOutputInferenceRegister:
    signal w_updateSeqOR            : std_logic; 
    signal w_clauseOutputsSeqORed   : std_logic_vector(NClauses-1 downto 0);
    
        -- For OutputWeights:
    signal w_LoadIndividualWIE_model : std_logic_vector(NClauses-1 downto 0); 
    signal w_Class                  : std_logic_vector(3 downto 0);  -- From TrainCoTMM: -- Outputs Target Class when this is trained, and the Negative Target Class thereafter
    signal w_W_Threshold_Weight_High: std_logic_vector(NBitsIW-2 downto 0); -- 1 bit less than NBitsIW due unsigned format.
    
    signal w_ModelWeightClass0 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass1 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass2 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass3 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass4 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass5 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass6 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass7 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass8 : std_logic_vector(NBitsIW-1 downto 0);
    signal w_ModelWeightClass9 : std_logic_vector(NBitsIW-1 downto 0);
    
    signal w_weightClass0 : clause_weights;
    signal w_weightClass1 : clause_weights;
    signal w_weightClass2 : clause_weights;
    signal w_weightClass3 : clause_weights;
    signal w_weightClass4 : clause_weights;
    signal w_weightClass5 : clause_weights;
    signal w_weightClass6 : clause_weights;
    signal w_weightClass7 : clause_weights;
    signal w_weightClass8 : clause_weights;
    signal w_weightClass9 : clause_weights;    
    
    -- For ClassSums:
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

--    -- For "DecideClass":
    signal w_classPredict : unsigned(3 downto 0);
    
    -- For TrainCoTM:
    signal w_EnTAteam                           : std_logic_vector(NClauses-1 downto 0); 
    signal w_incrTA                             : std_logic_vector(2*FSize-1 downto 0);
    signal w_decrTA                             : std_logic_vector(2*FSize-1 downto 0);
    signal w_TypeIa                             : std_logic; 
    signal w_TypeII                             : std_logic; 
    
--    -- For "ModuleEvaluateResults":
    signal w_reset_evaluate                     : std_logic;
    
    -- For Find Negative Target Class:
    signal w_NegTargetClass                     : std_logic_vector(3 downto 0);
    signal w_LFSRwordSingle                     : unsigned (23 downto 0);
    
    -- For TrainCoTM:
    signal w_T_hyper                            : std_logic_vector(7 downto 0);
    signal w_s_hyper                            : std_logic_vector(3 downto 0);
    signal w_lengthLFSRs                        : std_logic;
    signal w_ctrl_lengthLFSRs                   : std_logic_vector(2 downto 0);
    signal w_test                               : std_logic_vector(2 downto 0);
    
    -- For TsetlinAutomata:
    signal w_includes_per_clause_from_TA        : std_logic_vector(2*FSize-1 downto 0);
    signal w_includes_per_clause_from_TA_update : std_logic_vector(2*FSize-1 downto 0);
    signal w_TA_RAM_write_enable                : std_logic;
    
--        -- For BlinkyCounter:
    signal w_PWMsignal                          : std_logic;
    signal w_blinkoutA                          : std_logic;

-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
begin 

    -- Synchronize i_ctrl signals:
    SYNCHRONIZER : entity work.Synchronizer(rtl) 
        Port map 
            (
             clk        => clk, 
             i_signal   => i_ctrl,
             o_sync     => w_sync
           );


    -- Map i_ctrl signals to single control signals:
    w_rst                   <=  w_sync(0); 
    w_start                 <=  w_sync(1);
    w_learn                 <=  w_sync(2);
    w_enLFSRs_init          <=  w_sync(3);
    w_initialize            <=  w_sync(4); 
    w_LoadModel             <=  w_sync(5); -- Not implemented 
    w_image_buffer_reset    <=  w_sync(6);
    -- i_ctrl(7) is not used.
    
    -- Map i_config signals:
    w_TA_high_threshold         <= i_config(31 downto 24); -- Here: UNSIGNED. 
    w_T_hyper                   <= i_config(23 downto 16); -- UNSIGNED. 
    w_W_Threshold_Weight_High   <= i_config(15 downto 8);  -- UNSIGNED. The MAX weight threshold is set independently of T (but should normally equal T!?)
    w_s_hyper                   <= i_config(7 downto 4);   -- UNSIGNED.
    -- i_config(3) is not used. 
    w_test                      <= i_config(2 downto 0);
                                          -- w_test(2) not used.
                                          -- w_test(1) if 1: The patch generation for Negative Target Class is skipped
                                          -- w_test(0) not used. 
    
    w_lengthLFSRs               <= i_config(3);
                                         
    MAIN_FSM : entity work.FSM_main(rtl)
        port map(  
           i_clk                        => clk,                    
           i_rst                        => w_rst,
           i_start                      => w_start,
           i_learn                      => w_learn,
           i_enLFSRs_init               => w_enLFSRs_init,
           i_Initialize                 => w_initialize,   
           i_LoadModel                  => '0', --w_LoadModel, -- Not implemented 
           i_FinishedLoadModel          => '0', -- Not implemented      
           i_test                       => w_test, 
           
           o_EnModelLoad                => w_EnModelLoad,
           o_EnRAM_ModelLoad            => w_EnRAM_ModelLoad,
           o_en_generate_patches        => w_en_generate_patches,
           o_resetBcounter              => w_resetBcounter,    
           o_reset_one_detected         => w_reset_one_detected,  
           o_clauseAddress              => w_clauseAddress,
           o_ClauseCounterFinished      => w_ClauseCounterFinished,
           o_TA_RAM_write_enable        => w_TA_RAM_write_enable,
           
           o_enable_adders              => w_enable_adders,
           o_sample_actual_class        => w_sample_actual_class,
           o_sample_predicted_class     => w_sample_predicted_class,
           
           o_initializeTAs_and_Weights  => w_initializeTAs_and_Weights,
           o_EnWriteMSBsTAsIEreg        => w_EnWriteMSBsTAsIEreg,
           
           o_intr2                      => o_intr2,
           
           o_MainFSMstate               => w_MainFSMstate     
           );
    
    MODULE_ImageDataInterface: entity work.imageDataTop(rtl)      
        port map (
             -- AXI INTERFACE:
             axi_clk            => axi_clk,
             axi_reset_n        => axi_reset_n,
             
             -- Slave interface:
             i_data_valid       => i_data_valid,
             i_data             => i_data,
             o_data_ready       => o_data_ready,
             
             -- Interrupt:
             o_intr              => o_intr,
             -------------------------------------------------------------
             -- Other signals:         
             i_image_buffer_reset       => w_image_buffer_reset,
             i_start                    => w_start,
             i_ByCounterValue           => w_ByCounterValue,
             i_MainFSMstate             => w_MainFSMstate,
             
             --------------------------------  
             -- Output signals to PatchGenerator:               
             o_ImagevectorRow0   => w_ImagevectorRow0,
             o_ImagevectorRow1   => w_ImagevectorRow1,
             o_ImagevectorRow2   => w_ImagevectorRow2,
             o_ImagevectorRow3   => w_ImagevectorRow3,
             o_ImagevectorRow4   => w_ImagevectorRow4,
             o_ImagevectorRow5   => w_ImagevectorRow5,
             o_ImagevectorRow6   => w_ImagevectorRow6, 
             o_ImagevectorRow7   => w_ImagevectorRow7,
             o_ImagevectorRow8   => w_ImagevectorRow8,
             o_ImagevectorRow9   => w_ImagevectorRow9,
             o_ImagevectorRow10  => w_ImagevectorRow10, -- The 11th row. 
             
             o_ImageLabel        => w_ImageLabel
             );   
            
          o_ImageLabel <= w_ImageLabel; -- For testing
            
    ModuleGeneratePatches : entity work.GenerateThePatches(rtl) 
         port map 
           (
           i_clk                => clk,
           i_rst                => w_rst,
           i_en                 => w_en_generate_patches,
           i_start              => w_start,
           i_learn              => w_learn,
           i_LoadNewRow         => w_LoadNewRow,
           i_EndOfPatches       => w_EndOfPatches,
           i_CCcounterFinished  => w_ClauseCounterFinished,
           i_BxCounterValue     => w_BxCounterValue,
           i_ByCounterValue     => w_ByCounterValue,
           
           i_ImagevectorRow0    => w_ImagevectorRow0,
           i_ImagevectorRow1    => w_ImagevectorRow1,
           i_ImagevectorRow2    => w_ImagevectorRow2,
           i_ImagevectorRow3    => w_ImagevectorRow3,
           i_ImagevectorRow4    => w_ImagevectorRow4,
           i_ImagevectorRow5    => w_ImagevectorRow5,
           i_ImagevectorRow6    => w_ImagevectorRow6,
           i_ImagevectorRow7    => w_ImagevectorRow7,
           i_ImagevectorRow8    => w_ImagevectorRow8,
           i_ImagevectorRow9    => w_ImagevectorRow9,
           i_ImagevectorRow10   => w_ImagevectorRow10,
           
           o_updateOR           => w_updateSeqOR,
           
           o_PatchFeatures      => w_patchfeatures,
           o_PatchLiterals      => w_patchliterals
          );
                      
    Module_Bcounter: entity work.Bcounter(rtl) 
        port map
            (
            i_clk               => clk,
            i_rst               => w_rst, 
            i_resetBounter      => w_resetBcounter, 
            
            o_BxCounterValue    => w_BxCounterValue,
            o_ByCounterValue    => w_ByCounterValue,
            o_LoadNewRow        => w_LoadNewRow,
            o_EndOfPatches      => w_EndOfPatches,
            o_PatchAddress      => w_PatchAddress
            );
    
    Module_InclExcl_REGISTER: entity work.REGISTER_IncludeEXclude(rtl) 
        port map (
            i_clk                   => clk, 
            i_rst                   => w_rst, 
            i_EnWriteMSBsTAs        => w_EnWriteMSBsTAsIEreg,
            i_WriteAddr             => w_clauseAddress, 
            i_InputMSBsTAs_update   => w_includes_per_clause_from_TA_update,
            o_InclExcl              => w_incexcl_signals
            );  
     
     Module_MODEL: entity work.Model_pretrained(behavioral) 
        port map(
            i_clk               => clk,
            i_rst               => w_rst,
            i_EnModelLoad       => w_EnModelLoad,
            i_EnRAM_ModelLoad   => w_EnRAM_ModelLoad,
            i_clauseAddress     => w_clauseAddress,
            
            o_update            => w_LoadIndividualWIE_model, 
            
            o_Model_IEbits      => w_Model_IEbits,
            o_ModelWeightClass0 => w_ModelWeightClass0,
            o_ModelWeightClass1 => w_ModelWeightClass1,
            o_ModelWeightClass2 => w_ModelWeightClass2,
            o_ModelWeightClass3 => w_ModelWeightClass3,
            o_ModelWeightClass4 => w_ModelWeightClass4,
            o_ModelWeightClass5 => w_ModelWeightClass5,
            o_ModelWeightClass6 => w_ModelWeightClass6,
            o_ModelWeightClass7 => w_ModelWeightClass7,
            o_ModelWeightClass8 => w_ModelWeightClass8,
            o_ModelWeightClass9 => w_ModelWeightClass9
            );
                

    ModuleClauseBank : entity work.AllClauses(rtl)
         port map (
            i_literals          => w_patchliterals, 
            i_includeSignals    => w_incexcl_signals, 
            i_train_mode        => w_learn, 
            i_clk               => clk,
            i_rst               => w_reset_one_detected,
            
            o_FromClauses       => w_clauseOutputs,
            o_one_detected      => w_one_detected
            );
                    
                              
    ModuleClauseOutputsORed : entity work.ClauseOutputInferenceRegister(rtl) 
        port map(
            i_clk               => clk, 
            i_rst               => w_rst, 
            i_update            => w_updateSeqOR, 
            i_ClauseInputs      => w_clauseOutputs,
            
            o_ClauseregOutp     => w_clauseOutputsSeqORed
            );      

         
     ModuleAllWeights : entity work.AllWeights(rtl) 
         port map(
            i_clk                           => clk, 
            i_rst                           => w_rst, 
            i_learn                         => w_learn,
            i_en_Load_Model                 => w_EnModelLoad, 
            i_update_from_model             => w_LoadIndividualWIE_model, 
            i_update_enable_from_training   => w_TA_RAM_write_enable, 
            
            i_W_Threshold_Weight_High       => w_W_Threshold_Weight_High,
            
            i_enLFSRs_init                  => w_enLFSRs_init,
            i_initialize                    => w_initializeTAs_and_Weights,
            
            i_Class                         => w_Class, 

            i_ClauseAddress                 => w_clauseAddress,

            i_TypeIa                        => w_TypeIa,
            i_TypeII                        => w_TypeII,
            
            i_FSMstate                      => w_MainFSMstate,
            
            i_ModelWeightClass0             => w_ModelWeightClass0,
            i_ModelWeightClass1             => w_ModelWeightClass1,
            i_ModelWeightClass2             => w_ModelWeightClass2,
            i_ModelWeightClass3             => w_ModelWeightClass3,
            i_ModelWeightClass4             => w_ModelWeightClass4,
            i_ModelWeightClass5             => w_ModelWeightClass5,
            i_ModelWeightClass6             => w_ModelWeightClass6,
            i_ModelWeightClass7             => w_ModelWeightClass7,
            i_ModelWeightClass8             => w_ModelWeightClass8,
            i_ModelWeightClass9             => w_ModelWeightClass9,
            
            o_weightClass0                  => w_weightClass0,
            o_weightClass1                  => w_weightClass1,
            o_weightClass2                  => w_weightClass2,
            o_weightClass3                  => w_weightClass3,
            o_weightClass4                  => w_weightClass4,
            o_weightClass5                  => w_weightClass5,
            o_weightClass6                  => w_weightClass6,
            o_weightClass7                  => w_weightClass7,
            o_weightClass8                  => w_weightClass8,
            o_weightClass9                  => w_weightClass9
            );

    ClassSums : entity work.ClassSums(rtl) 
        port map(
            i_clk                       => clk, 
            i_rst                       => w_rst, 
            i_adderEnable               => w_enable_adders, 
            i_learn                     => w_learn,
            i_sample_predict            => w_sample_predicted_class,

            i_inputsFromSeqORedClauses  => w_clauseOutputsSeqORed,  
            
            i_weightClass0              => w_weightClass0,
            i_weightClass1              => w_weightClass1, 
            i_weightClass2              => w_weightClass2,
            i_weightClass3              => w_weightClass3,
            i_weightClass4              => w_weightClass4,
            i_weightClass5              => w_weightClass5,
            i_weightClass6              => w_weightClass6,
            i_weightClass7              => w_weightClass7,
            i_weightClass8              => w_weightClass8,
            i_weightClass9              => w_weightClass9,
            
            i_MainFSMstate              => w_MainFSMstate,
            
            o_sumClass0                 => w_sumClass0,
            o_sumClass1                 => w_sumClass1,
            o_sumClass2                 => w_sumClass2,
            o_sumClass3                 => w_sumClass3,
            o_sumClass4                 => w_sumClass4,
            o_sumClass5                 => w_sumClass5,
            o_sumClass6                 => w_sumClass6,
            o_sumClass7                 => w_sumClass7,
            o_sumClass8                 => w_sumClass8,
            o_sumClass9                 => w_sumClass9,
            
            o_sum0_stored               => w_sum0_stored,
            o_sum1_stored               => w_sum1_stored,
            o_sum2_stored               => w_sum2_stored,
            o_sum3_stored               => w_sum3_stored,
            o_sum4_stored               => w_sum4_stored,
            o_sum5_stored               => w_sum5_stored,
            o_sum6_stored               => w_sum6_stored,
            o_sum7_stored               => w_sum7_stored,
            o_sum8_stored               => w_sum8_stored,
            o_sum9_stored               => w_sum9_stored  
            );
            
    DecideClass : entity work.ClassDecision(rtl2) 
        port map(
            i_classSum0         => w_sumClass0,
            i_classSum1         => w_sumClass1,
            i_classSum2         => w_sumClass2,
            i_classSum3         => w_sumClass3,
            i_classSum4         => w_sumClass4,
            i_classSum5         => w_sumClass5,
            i_classSum6         => w_sumClass6,
            i_classSum7         => w_sumClass7,
            i_classSum8         => w_sumClass8,
            i_classSum9         => w_sumClass9,
            
            o_classPredict      => w_classPredict 
            );
    
     w_reset_evaluate <= '1' when w_rst='1' or w_MainFSMstate=InitialState else '0';
     ModuleEvaluate : entity work.EvaluateResults(rtl)
         port map(
                i_clk               => clk,
                i_rst               => w_reset_evaluate,
                i_sample_actual     => w_sample_actual_class,
                i_sample_predict    => w_sample_predicted_class,
                i_classActual       => unsigned(w_ImageLabel),
                i_classPredict      => w_classPredict,
                i_MainFSMstate      => w_MainFSMstate,
            
                o_correctPrediction  => o_correctPrediction,
                o_result             => o_result
            );
    
      w_ctrl_lengthLFSRs <= i_lengthLFSRs;
      TrainingModule : entity work.TrainCoTM(RTL)   
            Port map (
                  i_clk                     => clk,
                  i_rst                     => w_rst,
                  i_learn                   => w_learn,
                  i_lengthLFSRs             => w_ctrl_lengthLFSRs,
                  i_reset_per_sample        => '0', 
                  i_en_register_update      => '0', 
                  i_adderEnable             => w_enable_adders,
                  i_sample_predicted_class  => w_sample_predicted_class,
                  
                  i_WindowFeatures          => w_patchfeatures,
                  i_ClausesInput            => w_clauseOutputs,
                  i_TA_actions              => w_includes_per_clause_from_TA,
                  
                  i_ImageLabel              => w_ImageLabel,
                  i_NegTargetClass          => w_NegTargetClass,
                  
                  i_PatchAddress            => w_PatchAddress,
                  
                  i_classSum0               => w_sum0_stored,
                  i_classSum1               => w_sum1_stored,
                  i_classSum2               => w_sum2_stored,
                  i_classSum3               => w_sum3_stored,
                  i_classSum4               => w_sum4_stored,
                  i_classSum5               => w_sum5_stored,
                  i_classSum6               => w_sum6_stored,
                  i_classSum7               => w_sum7_stored,
                  i_classSum8               => w_sum8_stored,
                  i_classSum9               => w_sum9_stored,
                  
                  i_ClauseAddress           => w_clauseAddress,
                  
                  i_weightClass0            => w_weightClass0,
                  i_weightClass1            => w_weightClass1,
                  i_weightClass2            => w_weightClass2,
                  i_weightClass3            => w_weightClass3,
                  i_weightClass4            => w_weightClass4,
                  i_weightClass5            => w_weightClass5,
                  i_weightClass6            => w_weightClass6,
                  i_weightClass7            => w_weightClass7,
                  i_weightClass8            => w_weightClass8,
                  i_weightClass9            => w_weightClass9,
                  
                  i_EndOfPatches            => w_EndOfPatches,
      
                  i_MainFSMstate            => w_MainFSMstate,
                  
                  i_T_hyper                 => w_T_hyper,
                  i_s_hyper                 => w_s_hyper,
                  
                  i_en_LFSR_ClauseUpdate    => w_TA_RAM_write_enable,
                  
                  o_ClassSelect             => w_Class,  -- Outputs Target Class when this is trained, and the Negative Target Class thereafter. For use with the weight updating.
                  
                  o_EnTAteam                => w_EnTAteam,
                  
                  o_incrTA                  => w_incrTA,
                  o_decrTA                  => w_decrTA,
                  
                  o_TypeIa                  => w_TypeIa,
                  o_TypeII                  => w_TypeII,
                  
                  o_LFSRwordSingle          => w_LFSRwordSingle
                  ); 	      
      
      ModuleFindNegativeTarget : entity work.FindNegativeTargetClass(RTL)
        Port map 
               ( 
               i_clk             => clk,
               i_rst             => w_rst,
               
               i_LFSRinput       => unsigned(w_LFSRwordSingle), -- Not used simultaneously with other random decisions!
               i_learn           => w_learn,
               i_FNS             => '0', -- Focused Negative Sampling. Implementation is TBD.
               
               i_TargetClass     => w_ImageLabel,
               
               i_sample_label    => w_sample_actual_class,
               i_sample_predict  => w_sample_predicted_class,
               
               i_classSum0       => w_sumClass0,
               i_classSum1       => w_sumClass1,
               i_classSum2       => w_sumClass2,
               i_classSum3       => w_sumClass3,
               i_classSum4       => w_sumClass4,
               i_classSum5       => w_sumClass5,
               i_classSum6       => w_sumClass6,
               i_classSum7       => w_sumClass7,
               i_classSum8       => w_sumClass8,
               i_classSum9       => w_sumClass9,  
               i_MainFSMstate    => w_MainFSMstate,
               
               o_NegTargetClass  => w_NegTargetClass
               );
                      
    ALL_TA : entity work.TsetlinAutomata(RTL)
            Port map(
                    i_clk                           => clk,
                    i_rst                           => w_rst,
                    i_initialize                    => w_initializeTAs_and_Weights,
                    i_EnWriteModel                  => w_EnModelLoad,
                    i_Model_IEbits                  => w_Model_IEbits,
                    i_start                         => w_start,
                    i_learn                         => w_learn,
                    i_clauseaddr                    => w_clauseAddress,
                    i_write_enable                  => w_TA_RAM_write_enable,
                    i_incr                          => w_incrTA,
                    i_decr                          => w_decrTA, 
                    i_FSMstate                      => w_MainFSMstate, 
                    i_TA_high_threshold             => w_TA_high_threshold,
                    
                    o_includes_per_clause           => w_includes_per_clause_from_TA,
                    o_includes_per_clause_IE_update => w_includes_per_clause_from_TA_update
                    );

   ---------------------------------------------
   -- Status/Diagnosis modules:
   ---------------------------------------------

    ModuleLEDcontrol : entity work.LED_control(rtl) 
        port map (
            i_FSMstate                  => w_MainFSMstate, 
            
            o_LED1_InitialState         => o_LED1_InitialState, 
            o_LED2_FinishedInf          => o_LED2_FinishedInference, 
            o_LED3_FinishedLearn        => o_LED3_FinishedLearn,          
            o_statereg                  => o_statereg
            );

    Blinky: entity work.BlinkyCounter(rtl) 
        port map(
            i_clk           => clk, 
            i_rst           => w_rst, 
            i_ctrl1         => w_start, 
            i_ctrl2         => w_learn, 
            i_ctrl3         => w_initialize, 
            i_ctrl4         => w_LoadModel, 
            o_PWMout        => w_PWMsignal,
            o_counterOut    => o_blinkout
            );

end RTL;
