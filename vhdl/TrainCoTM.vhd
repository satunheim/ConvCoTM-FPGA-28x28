library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;  
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all;  
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  

entity TrainCoTM is   
    Port (
      i_clk                     : in STD_LOGIC;
      i_rst                     : in STD_LOGIC;
      i_learn                   : in STD_LOGIC;
      i_lengthLFSRs             : in std_logic_vector(2 downto 0);
      i_reset_per_sample        : in std_logic; 
      i_en_register_update      : in std_logic;  
      i_adderEnable             : in std_logic;
      i_sample_predicted_class  : in std_logic;
      
      i_WindowFeatures          : in STD_LOGIC_VECTOR (FSize-1 downto 0);
      i_ClausesInput            : in STD_LOGIC_VECTOR (NClauses-1 downto 0);
      i_TA_actions              : in std_logic_vector(2*FSize-1 downto 0); -- read from RAM, for a single clause
      
      i_ImageLabel              : in std_logic_vector(3 downto 0);
      i_NegTargetClass          : in std_logic_vector(3 downto 0);
      
      i_PatchAddress            : in std_logic_vector(NBitsPatchAddr-1 downto 0);
      
      i_classSum0               : in signed(NBsum-1 downto 0);
      i_classSum1               : in signed(NBsum-1 downto 0);
      i_classSum2               : in signed(NBsum-1 downto 0);
      i_classSum3               : in signed(NBsum-1 downto 0);
      i_classSum4               : in signed(NBsum-1 downto 0);
      i_classSum5               : in signed(NBsum-1 downto 0);
      i_classSum6               : in signed(NBsum-1 downto 0);
      i_classSum7               : in signed(NBsum-1 downto 0);
      i_classSum8               : in signed(NBsum-1 downto 0);
      i_classSum9               : in signed(NBsum-1 downto 0);
      
      i_ClauseAddress           : in std_logic_vector(NBitsClauseAddr-1 downto 0);
      
      i_weightClass0            : in clause_weights;
      i_weightClass1            : in clause_weights;
      i_weightClass2            : in clause_weights;
      i_weightClass3            : in clause_weights;  
      i_weightClass4            : in clause_weights;
      i_weightClass5            : in clause_weights;
      i_weightClass6            : in clause_weights;
      i_weightClass7            : in clause_weights;
      i_weightClass8            : in clause_weights;
      i_weightClass9            : in clause_weights;
      
      i_EndOfPatches            : in std_logic;
      
      i_MainFSMstate            : in std_logic_vector(SWIDTH-1 downto 0);
 
      i_T_hyper                 : in std_logic_vector(7 downto 0);
      i_s_hyper                 : in std_logic_vector(3 downto 0); 
      
      i_en_LFSR_ClauseUpdate    : in std_logic;
      
      o_ClassSelect             : out std_logic_vector(3 downto 0);
      
      o_EnTAteam                : out std_logic_vector(NClauses-1 downto 0); 
      
      o_incrTA                  : out std_logic_vector(2*FSize-1 downto 0);
      o_decrTA                  : out std_logic_vector(2*FSize-1 downto 0);
            
      o_TypeIa                  : out std_logic;
      o_TypeII                  : out std_logic;
      
      o_LFSRwordSingle          : out unsigned (23 downto 0) 
      ); 	      
end TrainCoTM;  

architecture RTL of TrainCoTM is

    signal w_LFSRwords                : LFSRrandomnumbers;
    signal w_enLFSRs                  : std_logic;
    
    signal w_CompOutC1                : std_logic;
    signal w_CompOutC2                : std_logic;

    signal w_UpdateReservoirRegisters : updateflagsPerClause;  
    signal w_enableRegNcount          : updateflagsPerClause; 
    signal w_UpdateReg                : updateflagsPerClause; 
    signal w_ClauseJvalue             : updateflagsPerClause;
    
    signal w_CompOutTA1               : updateflagsPerLiteral;
    signal w_CompOutTA2               : updateflagsPerLiteral;

    signal w_enRegisterUpdateDelayed  : std_logic;
    signal w_clauseSignalsDelayed     : STD_LOGIC_VECTOR (NClauses-1 downto 0);
    signal w_WindowFeaturesDelayed    : STD_LOGIC_VECTOR (FSize-1 downto 0);
    
    signal w_nxtNCount                : arrayOfPatchCounters;
    signal w_NCount                   : arrayOfPatchCounters;
    
    signal w_nxtRegPatchAddr          : arrayOfPatchAddresses; 
    signal w_RegPatchAddr             : arrayOfPatchAddresses;
    
    signal w_reset1                  : std_logic;
    
    signal w_addrsFromRegGroup0      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup1      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup2      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup3      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup4      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup5      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup6      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup7      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup8      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup9      :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup10     :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup11     :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup12     :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup13     :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup14     :  array32ofPatchAddresses;
    signal w_addrsFromRegGroup15     :  array32ofPatchAddresses;
    
    signal w_clauseWeightsGroup0       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup1       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup2       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup3       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup4       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup5       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup6       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup7       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup8       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup9       :  array32ofClauseWeights;
    signal w_clauseWeightsGroup10      :  array32ofClauseWeights;
    signal w_clauseWeightsGroup11      :  array32ofClauseWeights;
    signal w_clauseWeightsGroup12      :  array32ofClauseWeights;
    signal w_clauseWeightsGroup13      :  array32ofClauseWeights;
    signal w_clauseWeightsGroup14      :  array32ofClauseWeights;
    signal w_clauseWeightsGroup15      :  array32ofClauseWeights;
    
    signal w_s_hyper                   : unsigned(3 downto 0); 
    signal w_s_hyper_minus_one         : unsigned(3 downto 0); 
    signal w_s_hyper_minus_one_stdv    : std_logic_vector(3 downto 0); 
    
    signal w_Rightside1_TAupdate          : unsigned(27 downto 0);
    signal w_Rightside2_TAupdate          : unsigned(27 downto 0);
    
    signal w_numberA                      : std_logic_vector(27 downto 0);
    signal w_numberB                      : std_logic_vector(27 downto 0);
    
    type arrayOfTempUnsigned is array (0 to NClauses-1) of unsigned(NBitsClauseAddr-1 downto 0);

    signal w_TempJ1                     : arrayOfTempUnsigned;
    
    signal w_EnTAteam                   : std_logic_vector(NClauses-1 downto 0);    
    
    signal w_PatchSelected              : STD_LOGIC_VECTOR (FSize-1 downto 0);  
    signal w_Literals                   : STD_LOGIC_VECTOR (2*FSize-1 downto 0);   
    
    signal w_ResetRegisters             : std_logic;
    
    signal w_en_delaysignals            : std_logic;

    signal w_EnableReservoirSamplingA   : std_logic;
    signal w_EnableReservoirSamplingB   : std_logic;
    signal w_EnableReservoirSampling    : std_logic;
    
    signal w_Patch_RAM_write            : std_logic;
    signal w_en_Patch_RAM               : std_logic;
    
    signal w_train_Target               : std_logic;
    
    signal w_yi                         : std_logic;
    signal w_ClassSelect                : std_logic_vector(3 downto 0);
    
    signal w_addr_patch_RAM             : std_logic_vector(NBitsPatchAddr-1 downto 0);
    signal w_patchaddress_for_clause    : std_logic_vector(NBitsPatchAddr-1 downto 0);
    signal w_PatchAddress_T             : std_logic_vector(NBitsPatchAddr-1 downto 0);
    
    signal w_resetBcounterT             : std_logic;
    
    signal w_classWeights               : clause_weights;
    
    signal w_clauseweight               : signed(NBitsIW-1 downto 0);
    
    signal w_posW                       : std_logic; -- indicates positive weight
    signal w_TypeIaG                    : std_logic;
    signal w_TypeIIG                    : std_logic;
    signal w_cj                         : std_logic; -- clause value

    signal w_incrIa                     : std_logic_vector(2*FSize-1 downto 0);
    signal w_decrIb                     : std_logic_vector(2*FSize-1 downto 0);
    signal w_incrII                     : std_logic_vector(2*FSize-1 downto 0);
    
    signal w_updateTAsandWeights        : std_logic;
       
begin

    w_enLFSRs <= ((i_rst or i_learn) and i_en_LFSR_ClauseUpdate) when (i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2)
                 else (i_rst or i_learn); 
    
    w_EnableReservoirSamplingA <='1' when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2)
                        else '0';
    
    DelayEnableReservoirSampling : sDFF port map(i_clk, w_EnableReservoirSamplingA, w_EnableReservoirSamplingB);
    
    w_EnableReservoirSampling <= w_EnableReservoirSamplingB;
  
    BankOfRandomNumbers : entity work.BankOfLFSRs(RTL) 
        Port map (
             clk                => i_clk,               
             i_rst              => i_rst,
             i_en               => w_enLFSRs,
             i_isTarget         => w_yi, 
             i_lengthLFSRs      => i_lengthLFSRs,
             o_regout           => w_LFSRwords
            );

     RAM_StorePatches : entity work.RAM_patches(syn)
             port map( 
                      clk   => i_clk,
                      we    => w_Patch_RAM_write, 
                      en    => w_en_Patch_RAM,  
                      addr  => w_addr_patch_RAM,
                      di    => i_WindowFeatures, 
                      do    => w_PatchSelected
                     );

    w_addr_patch_RAM <= i_PatchAddress when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_SamplePredictClass1 
                                             or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2 or i_MainFSMstate=Learn_SamplePredictClass2)
                                       else w_patchaddress_for_clause;

    w_Patch_RAM_write <='1' when i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 
                    else '0';

    w_en_Patch_RAM <='1' when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1 or
                               i_MainFSMstate=Learn_PatchGenAndReservoirSampling2 or i_MainFSMstate=Learn_SamplePredictClass2 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2) 
                    else '0';
    
    
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    -- RESERVOIR SAMPLING - combined with the patch generation/window sliding:
   
        w_ResetRegisters <='1' when (i_rst='1' or i_MainFSMstate=InitialState) 
                          else '0';
   
        AJ: FOR j in 0 to NClauses-1 GENERATE
    
            ReservoirSamplingUpdate : entity work.rndReservoirSampleTest(RTL)
                 port map
                    (
                    i_LFSRinput         => unsigned(w_LFSRwords(j)),
                    i_ClauseSignal      => i_ClausesInput(j), 
                    i_Ncounter          => w_NCount(j), 
                    i_enable            => w_EnableReservoirSampling, 
                    o_UpdateRreg        => w_UpdateReg(j)
                    );
            
            w_UpdateReservoirRegisters(j) <= ((w_UpdateReg(j) AND w_EnableReservoirSampling) OR w_ResetRegisters) and i_learn;
            
            w_enableRegNcount(j) <= '1' when w_ResetRegisters='1' or (i_ClausesInput(j)='1' and w_EnableReservoirSampling='1' and (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2) and i_EndOfPatches='0')
                                    else '0';

            RegisterPatchPerClause  : vDFFce generic map(NBitsPatchAddr) port map(i_clk, w_UpdateReservoirRegisters(j), w_nxtRegPatchAddr(j), w_RegPatchAddr(j));
                
            w_nxtRegPatchAddr(j) <=   (others=>'0') when  (i_rst='1' OR w_ResetRegisters='1')
                                    else i_PatchAddress when w_UpdateReservoirRegisters(j)='1'
                                    else w_RegPatchAddr(j);

            RegisterNcounter : vDFFce generic map(9) port map(i_clk, w_enableRegNcount(j), w_nxtNCount(j), w_NCount(j));
                                  
            w_nxtNCount(j) <= (others=>'0') when (i_rst='1' OR w_ResetRegisters='1' or w_EnableReservoirSampling='0')
                                  else w_NCount(j)+"000000001" when i_ClausesInput(j)='1' and w_EnableReservoirSampling='1' and (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_PatchGenAndReservoirSampling2) and i_EndOfPatches='0'
                                  else w_NCount(j);
            
            w_ClauseJvalue(j) <= '1' when w_NCount(j)/="000000000" else '0';  -- For non-zero NCount(j) we know that c(j)=1 for at least one patch.                                 

        end GENERATE AJ;
        
    ----------------------------------------------------------------------------------------------------------------------------------------------        
    
    w_ClassSelect <= i_ImageLabel when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1)
                     else i_NegTargetClass when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling2 or i_MainFSMstate=Learn_SamplePredictClass2 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2 or i_MainFSMstate=FinishedTraining)
                     else "0000";
                     
    o_ClassSelect <= w_ClassSelect;
    
    w_train_Target <= '1' when (i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1)
                     else '0';
                     
    with w_ClassSelect select
        w_classWeights <= i_weightClass0 when "0000",
                          i_weightClass1 when "0001",
                          i_weightClass2 when "0010",
                          i_weightClass3 when "0011",
                          i_weightClass4 when "0100",
                          i_weightClass5 when "0101",
                          i_weightClass6 when "0110",
                          i_weightClass7 when "0111",
                          i_weightClass8 when "1000",
                          i_weightClass9 when "1001",
                          i_weightClass0 when others;
                     
    -- The following is needed to extract group of signals. Needed because of type issues!                 
    BJ: FOR r in 0 to 31 GENERATE
    
        w_addrsFromRegGroup0(r)  <= w_RegPatchAddr(r);
        w_addrsFromRegGroup1(r)  <= w_RegPatchAddr(r+32);
        w_addrsFromRegGroup2(r)  <= w_RegPatchAddr(r+64);
        w_addrsFromRegGroup3(r)  <= w_RegPatchAddr(r+96);
        
        w_clauseWeightsGroup0(r)  <= w_classWeights(r);
        w_clauseWeightsGroup1(r)  <= w_classWeights(r+32);
        w_clauseWeightsGroup2(r)  <= w_classWeights(r+64);
        w_clauseWeightsGroup3(r)  <= w_classWeights(r+96);

    end GENERATE BJ; 
    ---------------------------------------------------------------------------------------------------------------------------

    -- This part of the module is used to decide if a clause is to be updated, based on T and class sum.
    -- The clauses are updated in sequence one by one AFTER the patch generation/reservoir sampling.
    
    w_reset1 <='1' when (i_rst='1' or i_MainFSMstate=InitialState)
                else '0';
    
    DecideClauseUpdate : entity work.DecideClauseUpdate(RTL)
            Port map 
                    (
                    i_clk                       => i_clk,
                    i_rst                       => w_reset1,
                    i_adderEnable               => i_adderEnable,
                    i_learn                     => i_learn,
                    i_sample_predicted_class    => i_sample_predicted_class,
                    
                    i_LFSRinput                 => unsigned(w_LFSRwords(0)), -- Not used simultaneously with other random decisions!

                    i_classSum0                 => i_classSum0,
                    i_classSum1                 => i_classSum1,
                    i_classSum2                 => i_classSum2,
                    i_classSum3                 => i_classSum3,
                    i_classSum4                 => i_classSum4,
                    i_classSum5                 => i_classSum5,
                    i_classSum6                 => i_classSum6,
                    i_classSum7                 => i_classSum7,
                    i_classSum8                 => i_classSum8,
                    i_classSum9                 => i_classSum9,
                    
                    i_ClassSelect               => w_ClassSelect,
                    
                    i_train_Target              => w_train_Target,
                    
                    i_MainFSMstate              => i_MainFSMstate,
                    
                    i_T_hyper                   => i_T_hyper,
 
                    o_CompOut1                  => w_CompOutC1, -- used for TypeI feedback, both for Target and Negative target
                    o_CompOut2                  => w_CompOutC2  -- used for TypeII feedback, both for Target and Negative target
                    );
    
-- The following performs the TA updating, which here is done sequentially for each clause 0 to NClauses-1. 
-- First enable signals per clause are defined.
    
    AY: FOR m in 0 to NClauses-1 GENERATE  
         w_TempJ1(m) <= to_unsigned(m, w_TempJ1(m)'length); 
         w_EnTAteam(m) <= '1' when i_clauseAddress = std_logic_vector(w_TempJ1(m)) else '0';  
    end GENERATE AY;    
    
    o_EnTAteam <= w_EnTAteam;
    
     
     MUX_AddrPatchPerClause : entity work.MUX_patch_address(RTL_128)   
            Port map (
                  i_addrFromReg0    => w_addrsFromRegGroup0,
                  i_addrFromReg1    => w_addrsFromRegGroup1,
                  i_addrFromReg2    => w_addrsFromRegGroup2,
                  i_addrFromReg3    => w_addrsFromRegGroup3,
                  i_addrFromReg4    => w_addrsFromRegGroup4,
                  i_addrFromReg5    => w_addrsFromRegGroup5,
                  i_addrFromReg6    => w_addrsFromRegGroup6,
                  i_addrFromReg7    => w_addrsFromRegGroup7,
                  i_addrFromReg8    => w_addrsFromRegGroup8,
                  i_addrFromReg9    => w_addrsFromRegGroup9,
                  i_addrFromReg10   => w_addrsFromRegGroup10,
                  i_addrFromReg11   => w_addrsFromRegGroup11,
                  i_addrFromReg12   => w_addrsFromRegGroup12,
                  i_addrFromReg13   => w_addrsFromRegGroup13,
                  i_addrFromReg14   => w_addrsFromRegGroup14,
                  i_addrFromReg15   => w_addrsFromRegGroup15,
                  
                  i_sel             => i_clauseAddress,
                  o_MuxOut          => w_patchaddress_for_clause
                  );
     
     MUX_WeightPerClause: entity work.MUX_clause_weights(RTL_128)  
        Port map
            (
              i_clauseWeightsGroup0   => w_clauseWeightsGroup0,
              i_clauseWeightsGroup1   => w_clauseWeightsGroup1,
              i_clauseWeightsGroup2   => w_clauseWeightsGroup2,
              i_clauseWeightsGroup3   => w_clauseWeightsGroup3,
              i_clauseWeightsGroup4   => w_clauseWeightsGroup4,
              i_clauseWeightsGroup5   => w_clauseWeightsGroup5,
              i_clauseWeightsGroup6   => w_clauseWeightsGroup6,
              i_clauseWeightsGroup7   => w_clauseWeightsGroup7,
              i_clauseWeightsGroup8   => w_clauseWeightsGroup8,
              i_clauseWeightsGroup9   => w_clauseWeightsGroup9,
              i_clauseWeightsGroup10  => w_clauseWeightsGroup10,
              i_clauseWeightsGroup11  => w_clauseWeightsGroup11,
              i_clauseWeightsGroup12  => w_clauseWeightsGroup12,
              i_clauseWeightsGroup13  => w_clauseWeightsGroup13,
              i_clauseWeightsGroup14  => w_clauseWeightsGroup14,
              i_clauseWeightsGroup15  => w_clauseWeightsGroup15,
              
              i_sel                   => i_clauseAddress, 
              o_MuxOut                => w_clauseweight
              ); 
     
     w_posW <='1' when w_clauseweight >=0 else '0';

     w_Literals <= w_PatchSelected & not(w_PatchSelected);
    
    w_yi <= '1' when i_MainFSMstate=Learn_PatchGenAndReservoirSampling1 or i_MainFSMstate=Learn_SamplePredictClass1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1
            else '0';
    -- For the target class y(i)=1. 
    -- For the Negative Target class y(i)=0.  NOTE: For the ConvCoTM where we train the Target and Negative Target in sequence, this 
    -- does not matteer. We could have hardwired w_yi. 
    
    w_s_hyper <= unsigned(i_s_hyper);  -- 4 bits
    
    w_s_hyper_minus_one <= w_s_hyper - "0001";
    
    w_s_hyper_minus_one_stdv <= std_logic_vector(w_s_hyper_minus_one);
    
    w_numberA <= w_s_hyper_minus_one_stdv & "00000000" & "00000000" & "00000000";
    
    w_numberB <= "0001" & "00000000" & "00000000" & "00000000";  -- equals 2^L=2^24.
    
    w_Rightside1_TAupdate <= unsigned(w_numberA);
    
    w_Rightside2_TAupdate <= unsigned(w_numberB); 
    
    w_cj <= w_ClauseJvalue(to_integer(unsigned(i_ClauseAddress)));  
    
    w_updateTAsandWeights <= '1' when (i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2)
                            else '0';
    
    A1: FOR k in 0 to 2*FSize-1 GENERATE  
         
            Module_rnd_TA_update : entity work.rndComparatorForTAupdate(RTL)
               Port map (  
                    i_LFSRinput         => unsigned(w_LFSRwords(k+1)), -- We add 1 as w_LFSRwords(0) is used for the clause updating decision.
                    i_Rightside1        => w_Rightside1_TAupdate,
                    i_Rightside2        => w_Rightside2_TAupdate,
                    i_s_hyper           => w_s_hyper,
                    i_MainFSMstate      => i_MainFSMstate,
                    o_CompOut1          => w_CompOutTA1(k), 
                    o_CompOut2          => w_CompOutTA2(k)
                    );
            
            
            -- Type Ia feedback:
            w_incrIa(k) <= '1' when (((w_yi='1' and w_posW='1') or (w_yi='0' and w_posW='0')) 
                            and w_cj='1' and w_CompOutC1='1' and w_Literals(k)='1' and w_CompOutTA1(k)='1')
                           else '0';
            
            -- Type Ib feedback: 
            w_decrIb(k) <= '1' when (((w_yi='1' and w_posW='1') or (w_yi='0' and w_posW='0')) 
                                    and (w_cj='0' or w_Literals(k)='0') and w_CompOutC1='1' and w_CompOutTA2(k)='1')
                            else '0'; 
            
            -- Type II feedback:               
            w_incrII(k) <= '1' when (((w_yi='1' and w_posW='0') or (w_yi='0' and w_posW='1')) 
                                    and w_cj='1' and w_CompOutC2='1' and i_TA_actions(k)='0' and w_Literals(k)='0')
                           else '0';
            -- NOTE: w_CompOutC1 is the same signal as w_CompOutC2!
                           
            o_incrTA(k) <= w_incrIa(k) or w_incrII(k);
            o_decrTA(k) <= w_decrIb(k);
                    
        end GENERATE A1;
      
      -- To weight module - for updating:
      o_TypeIa <= (w_yi XNOR w_posW) and w_cj and w_CompOutC1 and w_updateTAsandWeights;
      o_TypeII <= (w_yi XOR w_posW) and w_cj and w_CompOutC2 and w_updateTAsandWeights;

      o_LFSRwordSingle <= unsigned(w_LFSRwords(0));
        
end RTL;