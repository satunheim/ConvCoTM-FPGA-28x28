library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;  
  
entity DecideClauseUpdate is
    Port   (
            i_clk                       : in STD_LOGIC;
            i_rst                       : in STD_LOGIC;
            i_adderEnable               : in STD_LOGIC;
            i_learn                     : in std_logic;
            i_sample_predicted_class    : in std_logic;
            
            i_LFSRinput                 : in unsigned (23 downto 0); -- unsigned (23 downto 0);

            i_classSum0                 : in signed(NBsum-1 downto 0);
            i_classSum1                 : in signed(NBsum-1 downto 0);
            i_classSum2                 : in signed(NBsum-1 downto 0);
            i_classSum3                 : in signed(NBsum-1 downto 0);
            i_classSum4                 : in signed(NBsum-1 downto 0);
            i_classSum5                 : in signed(NBsum-1 downto 0);
            i_classSum6                 : in signed(NBsum-1 downto 0);
            i_classSum7                 : in signed(NBsum-1 downto 0);
            i_classSum8                 : in signed(NBsum-1 downto 0);
            i_classSum9                 : in signed(NBsum-1 downto 0);
            
            i_ClassSelect               : in std_logic_vector(3 downto 0);  

            i_train_Target              : in std_logic;
            
            i_MainFSMstate              : in std_logic_vector(SWIDTH-1 downto 0);
            
            i_T_hyper                   : in std_logic_vector(7 downto 0); 
            
            o_CompOut1                  : out std_logic;
            o_CompOut2                  : out std_logic
            );
end DecideClauseUpdate;

architecture RTL of DecideClauseUpdate is
   
    signal w_selected_classSum          : signed(NBsum-1 downto 0);
    signal w_selCS                      : std_logic_vector(NBsum-1 downto 0);
    
    signal w_classSumA                  : std_logic_vector(35 downto 0);
    signal w_classSumB                  : signed(35 downto 0);
    signal w_classSumClipped            : signed(35 downto 0);
   
    signal w_T_hyper                    : std_logic_vector(35 downto 0);
    signal w_T_pos                      : signed(35 downto 0);
    signal w_T_neg                      : signed(35 downto 0);
    signal w_IncrementvectorT           : signed(35 downto 0);
    
    signal w_summation_margin           : signed(35 downto 0);
    signal w_d1                         : signed(35 downto 0);
    signal w_d2                         : signed(35 downto 0);
    signal w_d                          : signed(35 downto 0);
    
    signal w_2xT_pos                    : std_logic_vector(10 downto 0);
    signal w_2xT_pos_signed             : signed(10 downto 0);
    signal w_TminusC                    : signed(35 downto 0);
    signal w_TplusC                     : signed(35 downto 0);

    signal w_LFSRinput_unsigned         : unsigned(24 downto 0);
    signal w_LFSR_midpoint              : unsigned(24 downto 0);
    signal w_LFSRinput_signed           : signed(24 downto 0);
   
    signal w_Leftside1                   : signed(35 downto 0);
    signal w_Leftside2                   : signed(35 downto 0);
    signal w_Rightside1                  : signed(35 downto 0);
    signal w_Rightside2                  : signed(35 downto 0);
    
    signal w_d_exp2L                     : signed(35 downto 0);
    
    signal w_enReg                      : std_logic;
    signal w_nxtRegClassSum             : std_logic_vector(NBsum-1 downto 0); -- NBsum=9
    signal w_RegClassSum                : std_logic_vector(NBsum-1 downto 0);
    
    signal w_enable_comp_out            : std_logic;
    
    signal w_CompOut1                   : std_logic;
    
begin
    
    ModuleMUXClassSum : entity work.MUX_ClassSum(RTL)
            Port map (
                      i_classSum0   => i_classSum0,
                      i_classSum1   => i_classSum1,
                      i_classSum2   => i_classSum2,
                      i_classSum3   => i_classSum3,
                      i_classSum4   => i_classSum4,
                      i_classSum5   => i_classSum5,
                      i_classSum6   => i_classSum6,
                      i_classSum7   => i_classSum7,
                      i_classSum8   => i_classSum8,
                      i_classSum9   => i_classSum9,
            
                      i_ClassSelect => i_ClassSelect,
                      i_learn       => i_learn,
                      
                      o_MuxOut      => w_selected_classSum
                      );
    
    w_selCS     <= std_logic_vector(w_selected_classSum);
    
    -- Sign extension:
    w_classSumA <= ((36-NBsum) downto 0 => w_selCS(NBsum-1)) & w_selCS(NBsum-2 downto 0);
    
    w_classSumB <= signed(w_classSumA);

    w_T_hyper <= "0000" & "00000000" & "00000000" & "00000000" & i_T_hyper; 

    w_T_pos <= signed(w_T_hyper);
    
    w_IncrementvectorT <= (0 => '1', others=>'0');
    w_T_neg <= signed(not(w_T_hyper))+w_IncrementvectorT;

    w_summation_margin <= w_T_pos when i_train_Target='1' 
                                  else w_T_neg;
                                  
    -- Clipping:
    w_classSumClipped <=       w_T_pos when w_classSumB >= w_T_pos 
                          else w_T_neg when w_classSumB <= w_T_neg
                          else w_classSumB;
    
    -- Summation margin and absolute value:
    w_d1 <= w_summation_margin - w_classSumClipped;
    w_d2 <= w_classSumClipped  - w_summation_margin;
    
    w_d <= w_d1 when w_d1(35)='0' else w_d2;  -- ensures w_d is positive
   
--------------------------------------------------------                  
    -- Left side:
    
    w_2xT_pos <= w_T_hyper(9 downto 0) & '0';
    w_2xT_pos_signed <=signed(w_2xT_pos);
    
    w_LFSRinput_unsigned <= '0' & i_LFSRinput;
    w_LFSRinput_signed <= signed(w_LFSRinput_unsigned);
    
    w_Leftside1 <= w_2xT_pos_signed * w_LFSRinput_signed;
    
    ------------------------------
    -- Right side:
    
    w_d_exp2L <= w_d(11 downto 0) & "00000000" & "00000000" & "00000000";  
    
    w_Rightside1 <= w_d_exp2L; 
     
    w_Leftside2 <= w_Leftside1;        
          
    w_Rightside2 <= w_Rightside1; 
    ----------------------------------------------------------------------------------------------------
    
    w_enable_comp_out <= '1' when (i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_MainFSMstate=Learn_UpdateClausesAndTAsAndWeights2)
                        else '0';

    w_CompOut1 <= '1' when (w_Leftside1 < w_Rightside1) and w_enable_comp_out='1' else '0'; 
    o_CompOut1 <= w_CompOut1;
    o_CompOut2 <= w_CompOut1; -- o_CompOut2 is the same as o_CompOut11 and can be skipped.

end RTL;

