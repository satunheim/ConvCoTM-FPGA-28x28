library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  

entity ConvCoTM28x28 is
    Port (clk, rst, start, learn : in STD_LOGIC;
         -- singleImageInference : in std_logic;    

         -- Input registers from Processing System:
         CTRL : in std_logic_vector(31 downto 0);
         -- weightsON <= CTRL(0);
         -- shuffle <= CTRL(1);
         -- MVFLA <= CTRL(2);
         -- pregenTAteam <= CTRL(3);
         -- lengthLFSRs <= CTRL(6 downto 4);
         -- seedsel <= CTRL(7); 
         -- traindataRAMselect <= CTRL(8); -- (0 means training data WITHOUT noise (with the test data actually), -- 1 means WITH noise)
         -- singleImageInference <=CTRL(9); 
         -- NOT USED CTRL(10);
         -- NOT USED CTRL(11); 
         -- EPOCHCTRL <= CTRL(15 downto 12);
         -- TESTSAMPLESCTRL <= CTRL(19 downto 16);
         -- TRAININGSAMPLESCTRL <= <= CTRL(23 downto 20);
         -- DvalueSelect <= CTRL(27 downto 24);
         -- Not used: CTRL(31 downto 28)
         -- Not implemented: TAmode, loadTA, storeTA  

         IMAGE : in std_logic_vector(15 downto 0);

         sel1, sel0 : in std_logic; -- select between datasets in RAMs.
         -- "00" - These 3 RAMs contain dataset for 2P (2 Patterns) for Class1 and 4P for Class0. 40% noise added to the noisy set. 
         -- "01" - These 3 RAMs contain dataset for 2P (2 Patterns) for Class1 and 4P for Class0. 30% noise added to the noisy set.
         -- "10" - These 3 RAMs contain dataset for 2P (2 Patterns) for Class1 and 4P for Class0. 20% noise added to the noisy set.
         -- "11" - These 3 RAMs contain dataset for 2P (2 Patterns) for Class1 and 4P for Class0. 10% noise added to the noisy set.

         --------------------------------------
         --OUTPUT PINS:
         blinkout : out STD_LOGIC;
         LED1_InitialState, LED2_FinishedInf, LED3_FinishedLearn : out STD_LOGIC;
         PredictResult : out std_logic;
         -- In singleInageInference mode the label is set to '0'. Thus, if the prediction is classs 0 TrueNegative will be 1, 
         -- while if the prediction is class 1 FalsePositive will be 1.
         classPredictSingleG : out std_logic; -- control signal Green to RGB LED (indicates predicted class 1)
         classPredictSingleB : out std_logic; -- control signal Blue to RGB LED (indicates predicted class 0)

         --OUTPUT REGISTERS from CTMv1 to Processing System (PS):
         --Errors : out unsigned(1+NBitsEval-1 downto 0); -- NBitsEval=21, so Errors is 22 bits wide.
         Errors : out std_logic_vector(31 downto 0); -- 
         -- OUTPUT registers - noy fed to the PS
         TruePositive, TrueNegative, FalsePositive, FalseNegative : out std_logic_vector(NBitsEval-1 downto 0);

         PMODB, PMODC, PMODD, PMODE :  out std_logic_vector(3 downto 0)
        );

end ConvCoTM28x28;

architecture Behavioral of ConvCoTM28x28 is

    component singleTM
        Port (clk, rst, resetRegisters, ResetTAteams, learn, weightsON, updateSeqOR, enAdders, directTAteamCtrl : in STD_LOGIC;
             MVFLA : in STD_LOGIC;

             FSMstate : in std_logic_vector(SWIDTH-1 downto 0);
             TMClass : in Std_logic_vector(3 downto 0);
             TargetClass: in Std_logic_vector(3 downto 0); -- The TargetClass and NegTargetClass inputs are only used in this module during training. We apply the delayed versions here.
             NegTargetClass: in Std_logic_vector(3 downto 0);

             -- For TAs:
             CountClausesEnableDelayed : in std_logic;
             EnTAteamT, EnTAteamNT : in Std_logic_vector(0 to NClauses-1); -- enable signals for single TA teams (per clause)

             incr, decr : in Std_logic_vector(0 to 2*FSize-1); -- For all TA teams. EnTAteams decide which team to update
             updateW : in std_logic_vector(0 to NClauses-1); -- For weightsForClauses
             incrW, decrW : in std_logic; -- For weightsForClauses

             incrN, decrN : in Std_logic_vector(0 to 2*FSize-1); -- For all TA teams. EnTAteams decide which team to update
             updateWN : in std_logic_vector(0 to NClauses-1); -- For weightsForClauses
             incrWN, decrWN : in std_logic; -- For weightsForClauses         

             clauseAddress :  in std_logic_vector(5 downto 0); -- for selection of TAteamSignals

             WindowFeatures : in std_logic_vector(0 to FSize-1); -- Connects to the current patch. 
             -- In training mode this is the randomly selected patch.
             classSumOut : out signed(15 downto 0);
             classSumForClassDecision : out signed(15 downto 0);
             ClauseOutputs : out STD_LOGIC_VECTOR (0 to NClauses-1);
             selectedTAteamSignals : out Std_logic_vector(0 to 2*FSize-1)
            );
    end component;

    component ClassDecision is
        Port (clk, rst : in STD_LOGIC; --maybe these signals wil not be needed unless pipelining is necessary.
             classSum0 : in signed(15 downto 0);
             classSum1 : in signed(15 downto 0);
             --          classSum2 : in signed(15 downto 0);
             --          classSum3 : in signed(15 downto 0);
             --          classSum4 : in signed(15 downto 0);  
             --          classSum5 : in signed(15 downto 0);
             --          classSum6 : in signed(15 downto 0);
             --          classSum7 : in signed(15 downto 0);
             --          classSum8 : in signed(15 downto 0);
             --          classSum9 : in signed(15 downto 0);
             classPredict : out unsigned(3 downto 0)); -- suitable for up to 16 class systems 
    end component;

    component TrainCTM is
            Port (clk, rst, learn : in STD_LOGIC;
         WindowFeatures : in std_logic_vector(0 to FSize-1); -- This is the current patch

         TargetClass: in std_logic_vector(3 downto 0); 
         NegTargetClass: in std_logic_vector(3 downto 0); 
         isTarget : in std_logic; -- 1 means target, 0 means negative target for this instance of TrainCTM
         
         enLFSRs : in std_logic; -- enable random number generators
         lengthLFSRs : in std_logic_vector(2 downto 0); -- enable random number generators
         seedsel : in std_logic;
         enRegisterUpdate : in std_logic;
         ResetRegisters : in std_logic; -- the N counters must be reset before each example.
         
         helpmaskSingleInference : out std_logic;
         
         ClauseInput0, ClauseInput1 : in STD_LOGIC_VECTOR (0 to NClauses-1);        
--         ClauseInput2, ClauseInput3, ClauseInput4, ClauseInput5, 
--         ClauseInput6, ClauseInput7, ClauseInput8, ClauseInput9 : in STD_LOGIC_VECTOR (0 to NClauses-1);
         
         classSumIn0, classSumIn1 : in signed(15 downto 0);         
--         classSumIn2, classSumIn3, classSumIn4, classSumIn5 : in signed(15 downto 0);
--         classSumIn6, classSumIn7, classSumIn8, classSumIn9 : in signed(15 downto 0);
         
         TAteamInput0, TAteamInput1 : in std_logic_vector(0 to 2*FSize-1);         
--         TAteamInput2, TAteamInput3,
--         TAteamInput4, TAteamInput5, TAteamInput6, TAteamInput7,
--         TAteamInput8, TAteamInput9 : in std_logic_vector(0 to 2*FSize-1);
         
         clauseAddress : in std_logic_vector(5 downto 0); -- same for both training modules
         
         MVFLA : in std_logic;  -- 0 means "standard" TA updating, 1 means deterministic based on the Dvalue
         Dvalue : in std_logic_vector(15 downto 0); -- not used
         DvalueSelect : in std_logic_vector(3 downto 0);
         
         -- OUTPUTS:
         EnTAteam  : out std_logic_vector(0 to NClauses-1); 
         incr, decr : out std_logic_vector(0 to 2*FSize-1);
         updateW : out std_logic_vector(0 to NClauses-1);
         incrW, decrW : out std_logic 
        );
    end component;  

    component BCounter is
        Port ( clk, rst : in STD_LOGIC;
             BxCounterValue : out std_logic_vector(2 downto 0);
             ByCounterValue : out std_logic_vector(2 downto 0);
             BCounterFinished : out STD_LOGIC;
             IncrIMAddr : out STD_LOGIC;
             --           updateOR : out STD_LOGIC;
             updateEval : out STD_LOGIC;
             PAddress : out std_logic_vector(3 downto 0)
            );
    end component;

    component GenerateThePatches is
        port (clk, en, rst, resetRegisters, start, learn, BCounterFinished : in STD_LOGIC;
             CCcounterFinished : in std_logic;

             BxCounterValue : in std_logic_vector(2 downto 0);
             ByCounterValue : in std_logic_vector(2 downto 0);
             Imagevector : in STD_LOGIC_VECTOR(0 to ImageSize*ImageSize);
             -- newSampleA : out std_logic;
             updateOR : out std_logic;
             WindowFeatures : out std_logic_vector(0 to FSize-1));
    end component;

    component FSM_main is
        Port ( clk, rst, start, learn, patchCounterFin, sampleCounterFin, supressSampleload : in STD_LOGIC;
             FinishedInitialize : in std_logic;
             ClauseCounterFinished : in std_logic;
             ECounterFinished : in std_logic;
             engenpatch, engenpatchLearn : out std_logic;
             keepAdders : out STD_LOGIC;
             resetScounter, resetPcounter, loadSample : out std_logic;
             rstCountClauses, CountClausesEnable, clkEnTAs: out std_logic;
             FSMstate : out std_logic_vector(SWIDTH-1 downto 0);
             toLED1, toLED2, toLED3 : out STD_LOGIC
            );
    end component;

    component sample_counter is
        Port ( clk, rst, en, start, learn, singleInf, IncrIMAddr : in STD_LOGIC; -- the start signal here comes one clk period before the one used for all other modules.
             TESTSAMPLES: in std_logic_vector(15 downto 0); -- note: max is 2^13=8192
             TRAININGSAMPLES : in std_logic_vector(15 downto 0);
             shuffle : in std_logic;
             resetL : in std_logic;
             enLFSRs : in std_logic;
             selLFSRs : in std_logic_vector(3 downto 0);
             counter_finished : out STD_LOGIC;
             supress_sampleload : out STD_LOGIC;
             imageRAMaddr : out std_logic_vector(12 downto 0));
    end component;
    
--    component sample_counterB is
--        Port ( clk, rst, en, start, learn, singleInf, IncrIMAddr : in STD_LOGIC; -- the start signal here comes one clk period before the one used for all other modules.
--             TESTSAMPLES: in std_logic_vector(15 downto 0); -- note: max is 2^13=8192
--             TRAININGSAMPLES : in std_logic_vector(15 downto 0);
--             shuffle : in std_logic;
--             resetL : in std_logic;
--             enLFSRs : in std_logic;
--             selLFSRs : in std_logic_vector(3 downto 0);
--             addrShuffleRAM : in  std_logic_vector(12 downto 0);
--             --
--             counter_finished : out STD_LOGIC;
--             supress_sampleload : out STD_LOGIC;
--             imageRAMaddr : out std_logic_vector(12 downto 0));
--    end component;

    component imageRAMsX3 is
        Port (clk : in STD_LOGIC;
             enb1, enb2, enb3 : in std_logic;
             select1, select0 : std_logic;
             addrb1, addrb2, addrb3 : in std_logic_vector(12 downto 0);
             dob : out std_logic_vector(0 to 16)
            );
    end component;

    component EvaluateCTM is
        Port ( clk, update, keepAdders, engenpatch, rst : in STD_LOGIC;
             learn : in std_logic;
             FSMstate : in std_logic_vector(SWIDTH-1 downto 0);
             TruePositive, TrueNegative, FalsePositive, FalseNegative : out std_logic_vector(NBitsEval-1 downto 0);
             classActual  : in unsigned(3 downto 0);
             classActualDelayed : out unsigned(3 downto 0);
             classPredict : in unsigned(3 downto 0);
             correctPrediction : out std_logic;
             classPredictSingle : out std_logic);
    end component;

    component Synchronizer is
        Port ( clk, in0, in1, in2, in3 : in STD_LOGIC;
             out0, out1A, out1B, out2, out3 : out STD_LOGIC  -- out1A is used for the address (S) counter
            );
    end component;

    component FindNegTarget is
        Port (
            -- LFSRinput : in std_logic_vector(17 downto 0); -- For 10-class system
            learn : in std_logic;
            TargetClass : in std_logic_vector(3 downto 0);
            NegTargetClass : out std_logic_vector(3 downto 0)
        );
    end component;

    component clauseCounter is
        Port (clk, rst, en : in STD_LOGIC;
             cCounterFinished : out STD_LOGIC;
             clauseAddress : out std_logic_vector(5 downto 0);
             CountClausesEnableDelayed : out std_logic
            );
    end component;

    component BlinkyCounter is
        Port ( clk, rst, ctrl1, ctrl2, ctrl3, ctrl4 : in STD_LOGIC;
             PWMout : out std_logic;
             counterOut : out STD_LOGIC);
    end component;
    
    component EpochCounter is
        Port ( clk, rst, en, learn : in STD_LOGIC;
             EPOCHS : in std_logic_vector(15 downto 0);
             EcounterRegister : out std_logic_vector(11 downto 0);
             EcounterFinished : out STD_LOGIC);
    end component;

    component DecodeCTRLsignals is
        Port (Input1 : in STD_LOGIC_VECTOR(31 downto 0);

             EPOCHS : out std_logic_vector(15 downto 0);
             TESTSAMPLES : out  STD_LOGIC_VECTOR(15 downto 0);
             TRAININGSAMPLES : out  STD_LOGIC_VECTOR(15 downto 0);
             Dvalue : out std_logic_vector(15 downto 0)

            );
    end component;
    
--    component Encode4bitTO7segs is
--        port( bin4 : in std_logic_vector(3 downto 0); 
--              segments7 : out std_logic_vector(6 downto 0));  
--    end component;

    --------------------------------------------------------------------------------------------------------------------------
    -- SIGNALS:

    -- For Synchronizer:
    signal rstM, startMminusOne, startM, learnM, weightsONM : STD_LOGIC;
    --signal TAmodeM, LoadTAM, StoreTAM : STD_LOGIC;
    
    signal EPOCHS, TESTSAMPLES, TRAININGSAMPLES, Dvalue : std_logic_vector(15 downto 0);       

    -- For FSM_main:
    signal resetScounter, resetPcounter : std_logic;
    --signal InitialStateA : std_logic;
    signal CountClausesEnable : std_logic;
    signal FSMstate : std_logic_vector(SWIDTH-1 downto 0);

    -- For ClauseWeights:
    signal enWeights : std_logic;
    signal loadsample, supressSampleLoad, clkEnTAs : STD_LOGIC;

    -- For SCounter (i.e., the sample counter):
    signal SCounterFinished : std_logic;
--    signal addrShuffleRAM : std_logic_vector(12 downto 0);

    -- For BCounter (i.e., the patch counter):
    signal BxCounterValue :  std_logic_vector(2 downto 0);
    signal ByCounterValue :  std_logic_vector(2 downto 0);
    signal PatchAddr :  std_logic_vector(3 downto 0);
    signal BCounterFinished, LoadNewRow, IncrIMAddr, updateEval : std_logic;

    -- For "GenPatches" and patchfeatureregisterRAM:
    signal enGenPatch, engenpatchLearn, updateOR : std_logic;
    signal enGenPatch0, enGenPatch1 : std_logiC; 
    signal updateOR0, updateOR1 : std_logic;

    signal WindowFeatures : std_logic_vector(0 to FSize-1);

    -- For "3x ImagesRAM":
    signal addrRAMs : std_logic_vector(12 downto 0);
    signal ImagevectorRAM, Imagevector, ImagevectorToOutput : STD_LOGIC_VECTOR (0 to ImageSize*ImageSize);
    signal enRAM1, enRAM2, enRAM3 : std_logic;

    -- For "DecideClass":
    signal classPredictA : unsigned(3 downto 0);
    signal classSum0, classSum1 :  signed(15 downto 0);
    signal classSum0eval, classSum1eval :  signed(15 downto 0);
    
    signal classSum2, classSum3, classSum4, classSum5 :  signed(15 downto 0);
    signal classSum6, classSum7, classSum8, classSum9 :  signed(15 downto 0);

    -- For "ModuleEvaluateCTM":
    signal TruePositiveA, TrueNegativeA, FalsePositiveA, FalseNegativeA : std_logic_vector(NBitsEval-1 downto 0);
    -- signal TruePositive, TrueNegative, FalsePositive, FalseNegative : std_logic_vector(NBitsEval-1 downto 0);
    signal ErrorsB : unsigned(NBitsEval downto 0); -- NOTE: One bit more than for the TruePositive etc.
    signal ErrorsA, ErrorsAllZeros : std_logic_vector(1+NBitsEval-1 downto 0);
    signal keepAdders, correctPredictionA : std_logic;

    -- For TMs:
    signal ResetTAteams : std_logic;
    signal enAdders0, enAdders1 : std_logic;
    signal ResetRegisters, ResetRegistersInference, ResetRegistersLearn : std_logic;
    signal incrT, decrT, incrNT, decrNT : std_logic_vector(0 to 2*FSize-1);
    signal incrWT, decrWT, incrWNT, decrWNT : std_logic;
    signal updateWT, updateWNT : std_logic_vector(0 to NClauses-1);
    
    signal ClauseOutputs0, ClauseOutputs1 :  STD_LOGIC_VECTOR (0 to NClauses-1); -- To be fed to TrainCTM 
    signal ClauseOutputs2, ClauseOutputs3, ClauseOutputs4, ClauseOutputs5 : STD_LOGIC_VECTOR (0 to NClauses-1);
    signal ClauseOutputs6, ClauseOutputs7, ClauseOutputs8, ClauseOutputs9 : STD_LOGIC_VECTOR (0 to NClauses-1);
    
    signal TAteamOutput0, TAteamOutput1 : std_logic_vector(0 to 2*FSize-1); -- To be fed to TrainCTM 
    signal TAteamOutput2, TAteamOutput3, TAteamOutput4, TAteamOutput5 : std_logic_vector(0 to 2*FSize-1); 
    signal TAteamOutput6, TAteamOutput7, TAteamOutput8, TAteamOutput9 : std_logic_vector(0 to 2*FSize-1);
    
    signal enLFSRs, ResetNCounters : std_logic;
    
     --  For "CountClauses":
     signal rstCountClauses : std_logic;
     signal clauseAddressOut : std_logic_vector(5 downto 0);
     signal clauseAddress :  std_logic_vector(5 downto 0);
     signal cCounterFinished : std_logic;
     signal CountClausesEnableDelayed : std_logic;
    
    -- Fror TrainingModules:
    signal TargetClass, NegTargetClass : std_logic_vector(3 downto 0);
    signal TargetClassDelayed, NegTargetClassDelayed : std_logic_vector(3 downto 0); 
    signal TargetClassDelayedUS : unsigned(3 downto 0); 
    signal defClass0, defClass1 : std_logic_vector(3 downto 0);
    
    signal EnTAteamT, EnTAteamNT : Std_logic_vector(0 to NClauses-1);

    -- signal classPredict :  std_logic; 
    -- signal correctPrediction : std_logic;
    
    -- For BlinkyCounter:
    signal PWMsignal : std_logic;
    signal blinkoutA : std_logic;
    
    signal enableScounter : std_logic;
    
    --signal TAmode, loadTA, storeTA : std_logic;
    signal toLED1A, toLED2A, toLED3A : std_logic;
    signal resetEvaluate : std_logic;
    signal IntermA : std_logic_vector(1 downto 0);
    
    signal enEcounter, EcounterFinished : std_logic;
    signal EcounterRegister : std_logic_vector(11 downto 0);
    
    signal weightsON, shuffle, MVFLA : std_logic;
    signal pregenTAteam : std_logic;
    signal lengthLFSRs : std_logic_vector(2 downto 0);
    signal singleImageInference : std_logic;
    
    signal NU1, NU2, NU3, NU4 : std_logic;
    signal a1, a2 : std_logic;
    signal traindataRAMselect : std_logic;
    
    -- signal EPOCHCTRL, TESTSAMPLESCTRL, TRAININGSAMPLESCTRL, DvalueSelect : std_logic_vector(2 downto 0);
    
    signal DvalueSelect : std_logic_vector(3 downto 0);
    
    signal classPredictSingleA, helpmaskSingleInference, NotConnected1 : std_logic;
    
    signal FinishedInitialize : std_logic;
    signal seedsel : std_logic;
    
    signal segment0, segment1, segment2, segment3 : std_logic_vector(6 downto 0); 
    
    signal selectErrorsOutput : std_logic_vector(1 downto 0);
    signal ErrorsInterm : std_logic_vector(31 downto 0);
    
    -- DCounter:
--    signal resetDcounter, enDcounter : std_logic;
--    signal DcounterOut : std_logic_vector(15 downto 0);   

    -------------------------------------------------------------------------------------------------------------------------------------
begin

    ModuleDecodeControl : DecodeCTRLsignals port map(CTRL, EPOCHS, TESTSAMPLES, TRAININGSAMPLES, Dvalue);

    SyncInputs: Synchronizer port map(clk,
                 rst, start, learn, weightsON,
                 rstM, startMminusOne, startM, learnM, weightsONM);

    fsmCTM: FSM_main port map(clk, rstM, startM, learnM,
                 BCounterFinished, SCounterFinished, supressSampleLoad,
                 FinishedInitialize,
                 cCounterFinished,
                 EcounterFinished,
                 enGenPatch, engenpatchLearn, keepAdders, resetScounter, resetPcounter, loadsample,
                 rstCountClauses, CountClausesEnable, clkEnTAs,
                 FSMstate,
                 toLED1A, toLED2A, toLED3A);

    FinishedInitialize <='1'; -- Needs to be implemented by a counter in the final version.

    LED1_InitialState <= toLED1A;
    LED2_FinishedInf <= toLED2A;
    LED3_FinishedLearn <= toLED3A;

    TargetClass <= "000" & Imagevector(16); -- I.e., the label from the current training example

    TargetClassDelayed <= std_logic_vector(TargetClassDelayedUS) when learn='1' else "0000";
    -- TargetClassDelayedUS comes from EvaluateCTM
    ModuleFindNegTarget: FindNegTarget port map(learn, TargetClassDelayed, NegTargetClassDelayed);

    -- Definition of classes. 
    defClass0 <= "0000";
    defClass1 <= "0001";

    TM1 : singleTM port map (clk, rstM, resetRegisters, ResetTAteams, learnM, weightsONM, updateOR, enAdders1, pregenTAteam,
                 MVFLA,
                 FSMstate,
                 defClass1,
                 TargetClassDelayed, NegTargetClassDelayed,
                 CountClausesEnableDelayed, EnTAteamT, EnTAteamT,  -- EnTAteamT = EnTAteamNT
                 incrT, decrT,
                 EnTAteamT, -- updateWT=EnTAteamT, -- updateWT = updateWNT
                 incrWT, decrWT,
                 --
                 incrNT, decrNT,
                 EnTAteamT, -- -- updateWT = EnTAteamT, updateWT=EnTAteamT
                 incrWNT, decrWNT,
                 clauseAddress,
                 WindowFeatures,
                 -- Outputs: 
                 classSum1,
                 classSum1eval,
                 ClauseOutputs1, TAteamOutput1);

    TM0 : singleTM port map (clk, rstM, resetRegisters, ResetTAteams, learnM, weightsONM, updateOR, enAdders0, pregenTAteam,
                 MVFLA,
                 FSMstate,
                 defClass0, 
                 TargetClassDelayed, NegTargetClassDelayed, 
                 CountClausesEnableDelayed, EnTAteamT, EnTAteamT, -- EnTAteamT = EnTAteamNT
                 incrT, decrT,
                 EnTAteamT, 
                 incrWT, decrWT, 
                 --
                 incrNT, decrNT,
                 EnTAteamT, -- is the same as updateWNT=updateWT. Can be optimized away during synthesis.
                 incrWNT, decrWNT, 
                 clauseAddress,
                 WindowFeatures, 
                 -- Outputs: 
                 classSum0, 
                 classSum0eval,
                 ClauseOutputs0, TAteamOutput0);
                 

    TrainTARGET : TrainCTM port map (clk, rstM, learnM, WindowFeatures,
                 
                 TargetClassDelayed, NegTargetClassDelayed,
                 '1', -- means this TrainCTM module trains the Target class
                 enLFSRs, lengthLFSRs, seedsel,
                 engenpatchLearn, resetRegisters,
                 helpmaskSingleInference,
                 
                 ClauseOutputs0, ClauseOutputs1, 
--                 ClauseOutputs2, ClauseOutputs3, ClauseOutputs4, ClauseOutputs5, 
--                 ClauseOutputs6, ClauseOutputs7, ClauseOutputs8, ClauseOutputs9,
                 
                 classSum0, classSum1, 
--                 classSum2, classSum3, classSum4, classSum5, classSum6, classSum7, classSum8, classSum9,
                 
                 TAteamOutput0, TAteamOutput1, 
--                 TAteamOutput2, TAteamOutput3, TAteamOutput4, TAteamOutput5, TAteamOutput6, TAteamOutput7,
--                 TAteamOutput8, TAteamOutput9, 
                 
                 clauseAddress,
                 MVFLA,
                 Dvalue,
                 DvalueSelect,
                 ---
                 EnTAteamT, 
                 incrT, decrT,
                 updateWT, 
                 incrWT, decrWT
                );
                
    TrainNEGTARGET : TrainCTM port map (clk, rstM, learnM, WindowFeatures,
                 TargetClassDelayed, NegTargetClassDelayed,
                 '0', -- means this TrainCTM module trains the Negative Target class
                 enLFSRs, lengthLFSRs, seedsel,
                 engenpatchLearn, resetRegisters,
                 NotConnected1,
                 
                 ClauseOutputs0, ClauseOutputs1, 
--                 ClauseOutputs2, ClauseOutputs3, ClauseOutputs4, ClauseOutputs5, 
--                 ClauseOutputs6, ClauseOutputs7, ClauseOutputs8, ClauseOutputs9,
                 
                 classSum0, classSum1, 
--                 classSum2, classSum3, classSum4, classSum5, classSum6, classSum7, classSum8, classSum9,
                 
                 TAteamOutput0, TAteamOutput1, 
--                 TAteamOutput2, TAteamOutput3, TAteamOutput4, TAteamOutput5, TAteamOutput6, 
--                 TAteamOutput7,TAteamOutput8, TAteamOutput9, 
                 
                 clauseAddress,
                 MVFLA,
                 Dvalue,
                 DvalueSelect,
                 -----
                 EnTAteamNT, -- We strictly do not need this. It is sufficient with EnTAteamT from TrainTARGET
                 incrNT, decrNT,
                 updateWNT, -- We strictly do not need this. It is sufficient with updateWT from TrainTARGET
                 incrWNT, decrWNT
                );

    Ecounter : EpochCounter port map (clk, resetScounter, enEcounter, learnM, EPOCHS, EcounterRegister, EcounterFinished);
    enEcounter <= resetScounter or supressSampleLoad;


    SCounter: sample_counter port map(clk, resetScounter, enableScounter, startMminusOne, learnM, singleImageInference,
                                      IncrIMAddr, 
                                      TESTSAMPLES, TRAININGSAMPLES,
                                      shuffle, rstM, enLFSRs, EcounterRegister(3 downto 0), SCounterFinished, supressSampleLoad, addrRAMs);
                                      
--    SCounterB: sample_counterB port map(clk, resetScounter, enableScounter, startMminusOne, learnM, singleImageInference,
--                                      IncrIMAddr, 
--                                      TESTSAMPLES, TRAININGSAMPLES,
--                                      shuffle, rstM, enLFSRs, EcounterRegister(3 downto 0), 
--                                      addrShuffleRAM,
--                                      SCounterFinished, supressSampleLoad, addrRAMs);
    
    enableScounter <='1' when (FSMstate=InitialState or FSMstate=Learning or FSMstate=UpdateClausesAndTAs 
                              or FSMstate=Inference) else '0';          

    CountClauses : clauseCounter port map(clk, rstCountClauses, CountClausesEnable, cCounterFinished, clauseAddressOut, CountClausesEnableDelayed);

    clauseAddress <= clauseAddressOut; 

    BPatchCounter : Bcounter port map(clk, resetPcounter, BxCounterValue, ByCounterValue,
                 BCounterFinished, IncrIMAddr, updateEval, PatchAddr);

    GenPatches: GenerateThePatches port map(clk, enGenPatch, rstM, resetRegisters, startM, learnM,
                 BCounterFinished, 
                 cCounterFinished,
                 BxCounterValue, ByCounterValue, Imagevector,
                 updateOR, WindowFeatures);

    DecideClass : ClassDecision port map(clk, rstM, 
                 classSum0eval,
                 classSum1eval, 
--                 classSum2, classSum3, classSum4, classSum5, 
--                 classSum6, classSum7, classSum8, classSum9, 
                 classPredictA);
    
    RAM3Xmodule : imageRAMsX3 port map(clk, enRAM1, enRAM2, enRAM3, sel1, sel0, addrRAMs, addrRAMs, addrRAMs, ImagevectorRAM);
        -- RAM1 = Training data without noise
        -- RAM2 = Training Data with 40% noise
        -- RAM3 = Test data
        
    Imagevector <= ImagevectorRAM when singleImageInference='0' else IMAGE & '0';
    -- The '0' that is appended to IMAGE is a dummy label and is not used during singleImageInference mode.

    ModuleEvaluateCTM : EvaluateCTM port map(clk, updateEval, keepAdders, enGenPatch, resetEvaluate, learnM, FSMstate, TruePositiveA,
                 TrueNegativeA, FalsePositiveA, FalseNegativeA, unsigned(TargetClass), TargetClassDelayedUS, 
                 classPredictA, correctPredictionA, classPredictSingleA);
    
    classPredictSingleG <= '1' when PWMsignal='1' and singleImageInference='1' and helpmaskSingleInference='0' 
                            and classPredictSingleA='1' and FSMstate=FinishedInf 
                            else '0';
--    classPredictSingleB <= ('1' and PWMsignal and singleImageInference and not(helpmaskSingleInference)) 
--                            when classPredictSingleA='0' and FSMstate=FinishedInf 
--                            else '0';
    classPredictSingleB <= '1' when PWMsignal='1' and singleImageInference='1' and helpmaskSingleInference='0' 
                               and classPredictSingleA='0' and FSMstate=FinishedInf 
                               else '0';
    
    PredictResult <= classPredictSingleA when FSMstate=FinishedInf else '0';
    
    IntermA <= rstM & toLED1A;
    resetEvaluate <= '1' when IntermA="10" or IntermA="11" or IntermA="01" else '0'; 
    TruePositive <= TruePositiveA;  
    TrueNegative <= TrueNegativeA;
    FalsePositive <= FalsePositiveA;
    FalseNegative <= FalseNegativeA;
    
    ErrorsB <= unsigned('0' & FalsePositiveA) + unsigned('0' & FalseNegativeA); -- 2 Bits
    -- ErrorsAllZeros <= (others => '0');
    
    ---
--    selectErrorsOutput <= sel1 & sel0;
    
--    ImagevectorToOutput <= Imagevector when FSMstate=Initialstate else "00000000000000000";
    
--    with selectErrorsOutput select
--        ErrorsInterm <= "000000" & std_logic_vector(ErrorsB) when "00",
--                  "000000000000000" & Imagevector when "01",
--                  -- "000000" & "00000000" & "00000000" & WindowFeatures when "10",
--                  -- std_logic_vector(classSum1eval) & std_logic_vector(classSum0eval) when "11",
--                  "00000000" & "00000000" & "00000000" & "00000000" when others;
    
    ErrorsInterm <= "000000" & std_logic_vector(ErrorsB);
    
    Errors <= ErrorsInterm when (FSMstate=InitialState or FSMstate=FinishedInf or FSMstate=FinishedLearn) 
              else "00000000" & "00000000" & "00000000" & "00000000";
    -------------------------------

    
--    ModuleSegment3: Encode4bitTO7segs port map (ErrorsA(15 downto 12), segment3);
--    ModuleSegment2: Encode4bitTO7segs port map (ErrorsA(11 downto 8), segment2);
--    ModuleSegment1: Encode4bitTO7segs port map (ErrorsA(7 downto 4), segment1);
--    ModuleSegment0: Encode4bitTO7segs port map (ErrorsA(3 downto 0), segment0);

--    -- Map segment0-segment3 to PMOD outputs, and add PWM signal from blinky:
--    PMODB(3 downto 0) <=segment1(3 downto 0) when PWMsignal='1' else segment0(3 downto 0);
--    PMODC(3 downto 0) <='1' & segment1(6 downto 4) when PWMsignal='1' else '0' & segment0(6 downto 4);
--    PMODD(3 downto 0) <=segment3(3 downto 0) when PWMsignal='1' else segment2(3 downto 0);
--    PMODE(3 downto 0) <= '1' & segment3(6 downto 4) when PWMsignal='1' else '0' & segment2(6 downto 4);
    PMODB(3 downto 0) <="0000"; 
    PMODC(3 downto 0) <="0000";
    PMODD(3 downto 0) <="0000";
    PMODE(3 downto 0) <="0000";

    Blinky: BlinkyCounter port map(clk, rstM, startM, learnM, '0', '0', PWMsignal, blinkoutA);
    blinkout <= blinkoutA;
    
    ------------------------------------------------------------------------
    -- EXTERNAL CONTROL SIGNALS:
    ------------------------------------------------------------------------
    weightsON <= CTRL(0);
    shuffle <= CTRL(1); 
    MVFLA <= CTRL(2);
    pregenTAteam <= CTRL(3);
    lengthLFSRs <= CTRL(6 downto 4);
    seedsel <= CTRL(7); 
    traindataRAMselect <= CTRL(8);
    singleImageInference <= CTRL(9);
    -- Not used: CTRL(10)
    -- Not used: CTRL(11)
    -- The following signalks are connected directly to the decoder module:
    -- EPOCHCTRL <= CTRL(15 downto 12); 
    -- TRAININGSAMPLESCTRL <= <= CTRL(23 downto 20);
    DvalueSelect <= CTRL(27 downto 24);
    -- Not used: CTRL(31 downto 28)
    -- Not implemented: TAmode, loadTA, storeTA   

    ----------------------------------------------------------------------
    -- Generate enable signals for RAMs:
    ----------------------------------------------------------------------
    a1 <= '1' when (FSMstate=InitialState or FSMstate=Learning or FSMstate=UpdateClausesAndTAs) else '0';
    a2 <= '1' when (FSMstate=InitialState or FSMstate= Inference) else '0';
    
    enRAM1 <='1'  when learn='1' and a1='1' and traindataRAMselect='0' else '0'; -- Use training data without noise                    
    enRAM2 <= '1' when learn='1' and a1='1' and traindataRAMselect='1' else '0'; -- Use training data with noise              
    enRAM3 <= '1' when learn='0' and a2='1' else '0';
    -----------------
    
    enLFSRs <='1' when (learn='1' and (FSMstate=InitializeTAsAndLFSRs or FSMstate=InitialState or FSMstate=Learning or FSMstate=UpdateClausesAndTAs)) or rstM='1' else '0';
    ResetTAteams <=rstM;  
    ResetRegistersInference <='1' when FSMstate=InitialState else '0'; -- preliminary. MUST BE CHECKED!
    ResetRegistersLearn <='1' when FSMstate=InitialState or cCounterFinished='1' else '0';    
    ResetRegisters <= ResetRegistersInference when learn='0' else ResetRegistersLearn;
    
    
    -- These signals are set to 0. Will probably not implement their functions.
--    TAmode <= '0';
--    loadTA <= '0';  
--    storeTA <='0';
    
    -- The following are preliminary signals:
    enAdders0 <= '1';
    enAdders1 <='1';
   

    -- The following are not used for 2-class systems. Can be enabled for up to 10 classes.
--    classSum2 <= "10000000" & "00000000";
--    classSum3 <= "10000000" & "00000000";
--    classSum4 <= "10000000" & "00000000";
--    classSum5 <= "10000000" & "00000000";
--    classSum6 <= "10000000" & "00000000";
--    classSum7 <= "10000000" & "00000000";
--    classSum8 <= "10000000" & "00000000";
--    classSum9 <= "10000000" & "00000000";
    
--    TAteamOutput2 <= "0000000000" & "0000000000";
--    TAteamOutput3 <= "0000000000" & "0000000000";
--    TAteamOutput4 <= "0000000000" & "0000000000";
--    TAteamOutput5 <= "0000000000" & "0000000000";
--    TAteamOutput6 <= "0000000000" & "0000000000";
--    TAteamOutput7 <= "0000000000" & "0000000000";
--    TAteamOutput8 <= "0000000000" & "0000000000";
--    TAteamOutput9 <= "0000000000" & "0000000000";
    
--    ClauseOutputs2 <= (others => '0');
--    ClauseOutputs3 <= (others => '0');
--    ClauseOutputs4 <= (others => '0');
--    ClauseOutputs5 <= (others => '0');
--    ClauseOutputs6 <= (others => '0');
--    ClauseOutputs7 <= (others => '0');
--    ClauseOutputs8 <= (others => '0');
--    ClauseOutputs9 <= (others => '0');
    
end Behavioral;
