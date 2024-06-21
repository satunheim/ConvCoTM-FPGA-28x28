library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;  
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;    
   
entity FindNegativeTargetClass is
    Port ( 
          i_clk             : in std_logic;
          i_rst             : in std_logic;
          
          i_LFSRinput       : in unsigned (23 downto 0); -- comes from already running LFSR
          i_learn           : in std_logic;
          i_FNS             : in std_logic; -- Focused Negative Sampling. Implementation is TBD.
          
          i_TargetClass     : in std_logic_vector(3 downto 0); -- Comes from the image training sample. Sampled here and kept until FSM goes to InitialState.

          i_sample_label    : in std_logic;
          i_sample_predict  : in std_logic;
          
          i_classSum0       : in signed(NBsum-1 downto 0);
          i_classSum1       : in signed(NBsum-1 downto 0);
          i_classSum2       : in signed(NBsum-1 downto 0);
          i_classSum3       : in signed(NBsum-1 downto 0);
          i_classSum4       : in signed(NBsum-1 downto 0);  
          i_classSum5       : in signed(NBsum-1 downto 0);
          i_classSum6       : in signed(NBsum-1 downto 0);
          i_classSum7       : in signed(NBsum-1 downto 0);
          i_classSum8       : in signed(NBsum-1 downto 0);
          i_classSum9       : in signed(NBsum-1 downto 0);
          
          i_MainFSMstate    : in std_logic_vector(SWIDTH-1 downto 0);
          
          o_NegTargetClass  : out std_logic_vector(3 downto 0) -- updated during training and kept until FSM goes to InitialState
    ); 
end FindNegativeTargetClass;

architecture RTL of FindNegativeTargetClass is

	type elementsArray is array (0 to 8) of std_logic_vector(3 downto 0); -- For 10-class system
    signal w_elements : elementsarray; -- For 10-class system
    	
    signal w_Intermediate          : unsigned(27 downto 0); 
    
    signal w_negTargetIndex        : unsigned(3 downto 0); -- should not be lager than "1001" !
    
    signal w_nextTarget            : std_logic_vector(3 downto 0); 
    signal w_regTarget             : std_logic_vector(3 downto 0); 
    signal w_nextNegTarget         : std_logic_vector(3 downto 0); 
    signal w_regNegTarget          : std_logic_vector(3 downto 0); 
    signal w_NEXT1                 : std_logic_vector(3 downto 0);
    
    signal w_enTargetReg           : std_logic;
    signal w_enNEGTargetReg        : std_logic;


begin
    
    w_enTargetReg    <='1' when i_rst='1' or (i_sample_label='1' and i_MainFSMstate=Learn_SamplePredictClass1) 
                            else '0';
    w_enNEGTargetReg <='1' when i_rst='1' or (i_sample_predict='1' and i_MainFSMstate=Learn_SamplePredictClass1) 
                            else '0';
    
    TARGETREG: vDFFce generic map(4) port map(i_clk, w_enTargetReg, w_nextTarget, w_regTarget);
    w_nextTarget <= "0000" when i_rst='1' 
                    else i_TargetClass when i_sample_label='1'
                    else w_regTarget;
                    
    NEGTARGETREG: vDFFce generic map(4) port map(i_clk, w_enNEGTargetReg, w_nextNegTarget, w_regNegTarget);
    w_nextNegTarget <= "0000" when i_rst='1' 
                       else w_NEXT1 when i_sample_predict='1'
                       else w_regNegTarget; 
                
-- FOR 10-class system:
    with w_regTarget select
        w_elements <= ("0001", "0010", "0011", "0100", "0101", "0110", "0111", "1000", "1001") when "0000",
                      ("0000", "0010", "0011", "0100", "0101", "0110", "0111", "1000", "1001") when "0001",
                      ("0000", "0001", "0011", "0100", "0101", "0110", "0111", "1000", "1001") when "0010", --
                      ("0000", "0001", "0010", "0100", "0101", "0110", "0111", "1000", "1001") when "0011",
                      ("0000", "0001", "0010", "0011", "0101", "0110", "0111", "1000", "1001") when "0100",
                      ("0000", "0001", "0010", "0011", "0100", "0110", "0111", "1000", "1001") when "0101",
                      ("0000", "0001", "0010", "0011", "0100", "0101", "0111", "1000", "1001") when "0110",
                      ("0000", "0001", "0010", "0011", "0100", "0101", "0110", "1000", "1001") when "0111",
                      ("0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111", "1001") when "1000",
                      ("0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111", "1000") when "1001",
                      ("0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000") when others;

   w_Intermediate <= unsigned('0' & i_LFSRinput & "000") + unsigned("0000" & i_LFSRinput) when i_learn='1' -- This is multiplication with 9
                     else "0000" & "00000000" & "00000000" & "00000000"; 
   
   w_negTargetIndex <= w_Intermediate(27 downto 24); -- This is the index (0 to 8) among the 9 remaining classes.                                    
   
   w_NEXT1 <=w_elements(to_integer(w_negTargetIndex));   
   
   o_NegTargetClass <=w_regNegTarget;
               
end RTL;
