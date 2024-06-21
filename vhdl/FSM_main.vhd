library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;   
use work.SETTINGS_ConvCoTM.all;  
use work.FF.all;
use work.MainFSMDefinitions.all;     

entity FSM_main is       
     Port (
           i_clk                    : in std_logic; 
           i_rst                    : in std_logic; 
           i_start                  : in std_logic; 
           i_learn                  : in std_logic;
           i_enLFSRs_init           : in std_logic;
           i_Initialize             : in std_logic;       
           i_LoadModel              : in std_logic; -- For future usage.
           i_FinishedLoadModel      : in std_logic;
           i_test                   : in std_logic_vector(2 downto 0);
           
           o_EnModelLoad            : out std_logic;
           o_EnRAM_ModelLoad        : out std_logic;

           o_en_generate_patches    : out std_logic; 
           
           o_resetBcounter          : out std_logic; 
           o_reset_one_detected     : out std_logic;
           o_clauseAddress          : out std_logic_vector(NBitsClauseAddr-1 downto 0);
           o_ClauseCounterFinished  : out std_logic; 
           o_TA_RAM_write_enable    : out std_logic;
           
           o_enable_adders          : out std_logic;
           o_sample_actual_class    : out std_logic;
           o_sample_predicted_class : out std_logic; 
           
           o_initializeTAs_and_Weights : out std_logic;
           o_EnWriteMSBsTAsIEreg       : out std_logic;
           
           o_intr2                     : out std_logic;
           
           o_MainFSMstate           : out std_logic_vector(SWIDTH-1 downto 0)
           ); 
end FSM_main;

architecture rtl of FSM_main is 

    signal w_currentstate                       : std_logic_vector(SWIDTH-1 downto 0); 
    signal w_nextstate                          : std_logic_vector(SWIDTH-1 downto 0);
    signal w_next1                              : std_logic_vector(SWIDTH-1 downto 0);
    
    signal w_initres                            : std_logic;
    signal w_resetBandPcountersA                : std_logic;
    
    signal w_engenpatchA                        : std_logic;
    
    signal w_rstCountClauses                    : std_logic;
    signal w_CountClausesEnable                 : std_logic;
    signal w_ClauseCounterFinished              : std_logic;
    signal w_clauseAddress                      : std_logic_vector(NBitsClauseAddr-1 downto 0);
    
    signal w_enable_div2_clauseCounter          : std_logic;
    signal w_div2ClauseCounterFinished          : std_logic;
    signal w_div2clauseAddress                  : std_logic_vector(NBitsClauseAddr-1 downto 0);         
    signal w_div2c_lsb                          : std_logic;
    
    signal w_TA_RAM_write_enable                : std_logic;
    
    signal w_resetPcounter                      : std_logic;
    signal w_enablePcounter                     : std_logic;
    signal w_PcounterFinished                   : std_logic;

    signal w_reset_eval_counter                 : std_logic;
    signal w_enable_eval_counter                : std_logic;
    signal w_enable_adders                      : std_logic;
    signal w_sample_actual_class                : std_logic;
    signal w_sample_predicted_class             : std_logic;
    
    signal w_skip                               : std_logic;

begin
    
    w_initres <='1' when (i_rst='1' OR (w_currentstate /=Inference and w_currentstate /= Learn_PatchGenAndReservoirSampling1 
                          and w_currentstate /= Learn_PatchGenAndReservoirSampling2)) 
                    else '0';
           
    DelayInitialReset : sDFF port map(i_clk, w_initres, w_resetBandPcountersA);
                     
    w_resetPcounter <= '1' when w_resetBandPcountersA='1' else '0';
    

    o_resetBcounter <= '1' when w_resetBandPcountersA='1'  
                         else '0';
   
    o_reset_one_detected <= '1' when w_resetBandPcountersA='1' 
                         else '0';
                         
    w_enablePcounter <='1' when (w_currentstate=InitialState or w_currentstate=Learn_PatchGenAndReservoirSampling1 
                                or w_currentstate=Learn_PatchGenAndReservoirSampling2
                                or w_currentstate=Inference) else '0';   
    
    -------------------------------------------------------------------------------------------------------------------------------------------------
    w_engenpatchA <= '1' when (w_currentstate = Inference OR 
                               w_currentstate = Learn_PatchGenAndReservoirSampling1 or w_currentstate = Learn_PatchGenAndReservoirSampling2) else '0';
    
    o_en_generate_patches <= w_engenpatchA;
    -------------------------------------------------------------------------------------------------------------------------------------------------

    w_rstCountClauses    <= '1' when i_rst='1' or w_currentstate=Initialstate else '0'; -- MUST BE CHECKED!
    
    w_CountClausesEnable <= '1' when (i_rst='1'  
                                or w_currentstate = Phase0LoadMODEL or w_currentstate = LoadMODEL
                                OR w_currentstate=InitializePhase0 or w_currentstate=InitializeTAsAndLFSRsANDWeights or w_currentstate=InitializePhase1)
                                else '0';
                                
    w_enable_div2_clauseCounter <= '1' when (w_currentstate=Learn_UpdateClausesAndTAsAndWeights1 or w_currentstate=Learn_UpdateClausesAndTAsAndWeights2) 
                                 else '0';
    
    -------------------------------------------------------------------------------------------------------------------------------------------------
    o_EnModelLoad <= '1' when w_currentstate = LoadMODEL or w_currentstate = Phase1LoadMODEL
                         else '0';

    o_EnRAM_ModelLoad <= '1' when w_currentstate = Phase0LoadMODEL OR w_currentstate = LoadMODEL
                         else '0';
    
    -------------------------------------------------------------------------------------------------------------------------------------------------
                          
    w_TA_RAM_write_enable <= '1' when (w_currentstate=InitializePhase0 or w_currentstate=InitializeTAsAndLFSRsANDWeights or w_currentstate=InitializePhase1)
                             else (w_enable_div2_clauseCounter and w_div2c_lsb) when (w_currentstate=Learn_UpdateClausesAndTAsAndWeights1 or w_currentstate=Learn_UpdateClausesAndTAsAndWeights2) 
                             else '0';
    
    o_TA_RAM_write_enable <= w_TA_RAM_write_enable;
    
    o_EnWriteMSBsTAsIEreg <= w_TA_RAM_write_enable;
    
    o_initializeTAs_and_Weights <='1' when (w_currentstate=InitializePhase0 or w_currentstate=InitializeTAsAndLFSRsANDWeights) else '0';                      
 
    w_skip <=i_test(1);
   
    -------------------------------------------------------------------------------------------------  
    CounterPatchGen : entity work.Pcounter(rtl)  
            port map(i_clk                           => i_clk,
                     i_rst                           => w_resetPcounter,
                     i_en                            => w_enablePcounter,
                     i_start                         => i_start,
                     i_learn                         => i_learn,
                     o_PcounterFinished              => w_PcounterFinished
                     );
   
    -------------------------------------------------------------------------------------------------
    -- CLAUSE COUNTER:
    
    CountClauses : entity work.clauseCounter(rtl)  
            port map(i_clk                           => i_clk,
                     i_rst                           => w_rstCountClauses,
                     i_en                            => w_CountClausesEnable,
                     o_cCounterFinished              => w_ClauseCounterFinished,
                     o_clauseAddress                 => w_clauseAddress
                     );
    o_ClauseCounterFinished <= w_ClauseCounterFinished;  -- This signal is needed only for the "GenerateThePatches" module.
    
    o_clauseAddress <= w_div2clauseAddress when (w_currentstate=Learn_UpdateClausesAndTAsAndWeights1 or w_currentstate=Learn_UpdateClausesAndTAsAndWeights2) 
                                            else w_clauseAddress;
    
    ---------------------------------------------------------------------------------------------------
    --- CLAUSE COUNTER HALF SPEED: for use for TA RAM access during:
    -- w_currentstate=Learn_UpdateClausesAndTAsAndWeights1 or w_currentstate=Learn_UpdateClausesAndTAsAndWeights2
    -- Here two clock cycles are needed 
    -- per update, and therefore this counter is operating at half speed.
    CountClausesHalfSpeed : entity work.count_clauses_halfspeed(rtl)  
            port map(i_clk                           => i_clk,
                     i_rst                           => w_rstCountClauses,
                     i_en                            => w_enable_div2_clauseCounter,
                     o_cCounterFinished              => w_div2ClauseCounterFinished, 
                                                        -- This signal is used during the sequential clause
                                                        -- update (where a clause's TAs are updated in parallel. The TA update requires two clock cycles.
                                                        -- During Initialization the standard clauseAddress is used (updated every clock cycle).
                     o_clauseAddress                 => w_div2clauseAddress,
                     o_lsb                           => w_div2c_lsb
                     );
    
    -------------------------------------------------------------------------------------------------
    -- EVAL COUNTER: (used when we want to sample the actual and prediced classes, 
    -- as well as enable the adders and class decision modules.
    
    w_reset_eval_counter <= '1' when i_rst='1' or not(w_currentstate=FinishedInference or w_currentstate=Learn_SamplePredictClass1 or w_currentstate=Learn_SamplePredictClass2) else '0';
    w_enable_eval_counter <='1' when w_currentstate=FinishedInference or w_currentstate=Learn_SamplePredictClass1 or w_currentstate=Learn_SamplePredictClass2 else '0';
    
    ModuleEvalCounter : entity work.counter_eval(rtl)  
            port map(i_clk                    => i_clk,
                     i_rst                    => w_reset_eval_counter,
                     i_en                     => w_enable_eval_counter,
                     i_learn                  => i_learn,
                     o_enable_adders          => w_enable_adders,
                     o_sample_actual_class    => w_sample_actual_class,
                     o_sample_predicted_class => w_sample_predicted_class
                     );
                     
    o_enable_adders             <= w_enable_adders;
    o_sample_actual_class       <= w_sample_actual_class;
    o_sample_predicted_class    <= w_sample_predicted_class;
    
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- FSM:
    MAINSTATEREG: vDFF generic map(SWIDTH) port map(i_clk, w_nextstate, w_currentstate);
    
    w_nextstate <= InitialState when i_rst='1' else w_next1;
    
    
   
      process(
              w_currentstate, 
              i_Initialize,
              i_enLFSRs_init,
              w_div2ClauseCounterFinished,
              i_start, 
              i_learn,
              i_LoadModel,
              w_PcounterFinished, 
              w_ClauseCounterFinished,
              w_sample_predicted_class,
              w_skip 
              ) 
      begin
              
        case w_currentstate is
        
            when InitialState =>    
                    IF i_enLFSRs_init='1' THEN
                        w_next1 <= initializeLFSR;
                    ELSIF i_LoadModel='1' THEN -- Not implemented
                        w_next1 <= Phase0LoadMODEL;
                    ELSIF i_start='0' THEN 
                        w_next1 <= InitialState;
                    ELSIF i_start='1' and i_learn='0' THEN 
                        w_next1 <= Inference; 
                    ELSIF i_start='1' and i_learn='1' THEN
                        w_next1 <= Learn_PatchGenAndReservoirSampling1; 
                    ELSE w_next1<=InitialState;
                    END IF;
            
            -------------------
            -- Inference:
            when Inference =>  
                    IF w_PcounterFinished='1' THEN 
                    -- The sample counter is used to count the eact number of clock cycles required for a 
                    -- complete patch generation.
                        w_next1 <= FinishedInference;
                    ELSE w_next1<=Inference;
                    END IF;
                    
            when FinishedInference =>
                    IF w_sample_predicted_class='1' THEN 
                        w_next1 <= keepClassDecision;
                    ELSE w_next1<=FinishedInference;
                    END IF;
            
            when keepClassDecision =>
                    IF i_start='1' THEN 
                        w_next1 <= keepClassDecision; 
                        -- The processor will hold i_start high until it has read the class prediction and the actual class
                    ELSE w_next1<=InitialState;
                    END IF;  
            
            -----
            -- Training:      
                   
            when Learn_PatchGenAndReservoirSampling1 =>
                    IF  w_PcounterFinished='1' THEN 
                        w_next1 <= Learn_SamplePredictClass1;
                    ELSE w_next1<=Learn_PatchGenAndReservoirSampling1;
                    END IF; 
                    
            
             when Learn_SamplePredictClass1 =>
                    IF w_sample_predicted_class='1' THEN 
                        w_next1 <= Learn_UpdateClausesAndTAsAndWeights1;
                    ELSE w_next1<=Learn_SamplePredictClass1;
                    END IF;
                          
            when Learn_UpdateClausesAndTAsAndWeights1 =>
                    IF w_div2ClauseCounterFinished='0' THEN
                        w_next1 <= Learn_UpdateClausesAndTAsAndWeights1;
                    ELSIF w_skip='1' THEN 
                        w_next1 <= Learn_UpdateClausesAndTAsAndWeights2;
                    ELSE w_next1 <= Learn_PatchGenAndReservoirSampling2; 
                    END IF;
            
            when Learn_PatchGenAndReservoirSampling2 =>
                    IF  w_PcounterFinished='1' THEN 
                        w_next1 <= Learn_SamplePredictClass2;
                    ELSE w_next1<=Learn_PatchGenAndReservoirSampling2;
                    END IF; 
            
            when Learn_SamplePredictClass2 =>
                    IF w_sample_predicted_class='1' THEN 
                        w_next1 <= Learn_UpdateClausesAndTAsAndWeights2;
                    ELSE w_next1<=Learn_SamplePredictClass2;
                    END IF;
            
            when Learn_UpdateClausesAndTAsAndWeights2 =>
                    IF w_div2ClauseCounterFinished='0' THEN
                        w_next1 <= Learn_UpdateClausesAndTAsAndWeights2;
                    ELSE w_next1 <= FinishedTraining; 
                    END IF;
              
            when FinishedTraining =>
                    IF i_start='1' THEN 
                        w_next1 <= FinishedTraining;
                    ELSE w_next1<=InitialState;
                    END IF;     

            ---------------------------------------------------------------------------------------------
            
            when initializeLFSR => 
                    IF i_Initialize='1' THEN
                         w_next1 <= InitializePhase0;
                    ELSE w_next1 <= initializeLFSR;
                    END IF;  
            
            when InitializePhase0 =>
                         w_next1 <= InitializeTAsAndLFSRsANDWeights;

            when InitializeTAsAndLFSRsANDWeights => -- In this state all TA are set in state N,
                                                    -- and all weights are randomly set to either -1 or +1.
                    IF w_ClauseCounterFinished='1' THEN
                         w_next1 <= InitializePhase1;
                    ELSE w_next1 <= InitializeTAsAndLFSRsANDWeights;
                    END IF;  
                    
            when InitializePhase1 =>
                         w_next1 <= FinishedInitialize;                                        
            
            when FinishedInitialize =>   
                    IF i_Initialize='1' or i_enLFSRs_init='1' THEN  
                    -- We can safely set both these signals low immediately after i_Initialize has been set to 1, because the 
                    -- rest of the initialization process does not depend on these signals (but on w_ClauseCounterFinished).
                         w_next1 <= FinishedInitialize;
                    ELSE w_next1 <= InitialState;
                    END IF;  
                                                 
            when others =>
                   w_next1 <= InitialState;
                    
           end case;             
    end process;
    
    o_intr2 <= '1' when (w_currentstate=keepClassDecision or w_currentstate=FinishedTraining
                        or w_currentstate=FinishedInitialize or w_currentstate=FinishedLoadMODEL) -- or w_currentstate=FinishedWriteMODEL)
                    else '0';
    
    
    o_MainFSMstate <= w_currentstate;
    
end rtl;