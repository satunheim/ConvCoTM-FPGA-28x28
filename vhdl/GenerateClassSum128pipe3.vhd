library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all;  
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
 
entity GenerateClassSum128pipe3 is  
    Port (
          i_clk                 : in STD_LOGIC;
          i_rst                 : in STD_LOGIC;
          i_adderEnable         : in STD_LOGIC;
          i_sample_predict      : in std_logic;
          i_clauseWeights       : in clause_weights;
          i_inputsFromClauses   : in STD_LOGIC_VECTOR (NClauses-1 downto 0); 
          i_MainFSMstate        : in std_logic_vector(SWIDTH-1 downto 0);
          
	      o_sum                 : out signed(NBsum-1 downto 0);
	      o_sum_stored          : out signed(NBsum-1 downto 0)
	      ); 
end GenerateClassSum128pipe3;


--------------------------------------------------------------------------------------------------------------------------------
architecture rtl of GenerateClassSum128pipe3 is
    
    type modifiedweights is array(0 to NClauses-1) of signed(NBsum-1 downto 0);
    
    signal w_weightsIncluded    : modifiedweights;

    type FirstReg is array (0 to 63) of signed(NBsum-1 downto 0);
    type SecondReg is array (0 to 31) of std_logic_vector(NBsum-1 downto 0);
    type ThirdReg is array (0 to 15) of signed(NBsum-1 downto 0); 
    type FourthReg is array (0 to 7) of std_logic_vector(NBsum-1 downto 0);
    type FifthReg is array (0 to 3) of signed(NBsum-1 downto 0); 
    type SixtReg is array (0 to 1) of signed(NBsum-1 downto 0); 
    
    signal w_sumtWeights1stage  : FirstReg;
    
    signal nxtA2reg, A2reg : SecondReg;
    signal A3reg : ThirdReg;
    signal nxtA4reg, A4reg : FourthReg;
    signal A5reg : FifthReg;
    signal A6reg : SixtReg;
    signal nxtA7reg, A7reg : std_logic_vector(NBsum-1 downto 0); 
    
    signal w_en_store_reg : std_logic;
    
    signal w_nxtSreg      : std_logic_vector(NBsum-1 downto 0); 
    signal w_Sreg         : std_logic_vector(NBsum-1 downto 0); 
    
begin
   
       -- Include all ClauseWeights where the corresponding Clause output (ClauseC) is '1'. Set to '0 otherwise.
       -- Sign extension is applied.
    Choose1: FOR k in 0 to NClauses-1 GENERATE
          w_weightsIncluded(k) <= ((NBsum-NBitsIW downto 0 => i_clauseWeights(k)(NBitsIW-1)) & i_clauseWeights(k)(NBitsIW-2 downto 0)) when (i_inputsFromClauses(k)='1' and i_adderEnable='1') else (others => '0');
    end GENERATE Choose1; 
    
    --128 numbers to add): 
    A1: FOR k in 0 to 63 GENERATE     
        w_sumtWeights1stage(k) <= w_weightsIncluded(2*k)+w_weightsIncluded(2*k+1);                                                                                                
    end GENERATE A1;
    
    -- Second level of reduction-tree (64 numbers to add): 
    A2: FOR k in 0 to 31 GENERATE                                                                          
        nxtA2reg(k) <=   --(others=>'0') when i_rst='1' else 
                          std_logic_vector(w_sumtWeights1stage(2*k)+w_sumtWeights1stage(2*k+1));            
        A2register: vDFF generic map(NBsum) port map(i_clk, nxtA2reg(k), A2reg(k));                                      
    end GENERATE A2;
    
    -- Third level of reduction-tree (32 numbers to add): 
    A3: FOR k in 0 to 15 GENERATE                                                                             
        A3reg(k) <= signed(A2reg(2*k))+ signed(A2reg(2*k+1));                                       
    end GENERATE A3;
    
    -- Fourth level of reduction-tree (16 numbers to add): 
    A4: FOR k in 0 to 7 GENERATE                                                                         
        nxtA4reg(k) <=  std_logic_vector(signed(A3reg(2*k))+ signed(A3reg(2*k+1)));                  
        A4register: vDFF generic map(NBsum) port map(i_clk, nxtA4reg(k), A4reg(k));                                  
    end GENERATE A4;
    
    -- Fifth level of reduction-tree (8 numbers to add): 
    A5: FOR k in 0 to 3 GENERATE                                                                         
        A5reg(k) <= signed(A4reg(2*k))+ signed(A4reg(2*k+1));                    
    end GENERATE A5;
    
     -- Sixt level of reduction-tree (4 numbers to add): 
    A6: FOR k in 0 to 1 GENERATE                                                                         
        A6reg(k) <= signed(A5reg(2*k))+ signed(A5reg(2*k+1));                    
    end GENERATE A6;
    
     -- Seventh and FINAL level of reduction-tree (2 numbers to add):                                                                         
        nxtA7reg <= std_logic_vector(signed(A6reg(0))+ signed(A6reg(1)));       
        A7register: vDFF generic map(NBsum) port map(i_clk, nxtA7reg, A7reg);
        
        reg_store_sum: vDFFce generic map(NBsum) port map(i_clk, w_en_store_reg, w_nxtSreg, w_Sreg);
        w_nxtSreg <=   (others=>'0') when i_rst='1' else 
                          A7reg;

        w_en_store_reg <='1' when (i_sample_predict='1' or i_rst='1') else '0';
    
    o_sum <=signed(A7reg);

    o_sum_stored <= signed(w_Sreg);

end rtl;
