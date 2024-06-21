library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  

entity TsetlinAutomata is
    Port (
            i_clk                           : in STD_LOGIC;
            i_rst                           : in STD_LOGIC;
            i_initialize                    : in std_logic;
            i_EnWriteModel                  : in std_logic;
            i_Model_IEbits                  : in std_logic_vector(2*FSize-1 downto 0); 
            i_start                         : in std_logic;
            i_learn                         : in std_logic;
            i_clauseaddr                    : in std_logic_vector(NBitsClauseAddr-1 downto 0);  
            i_write_enable                  : in std_logic;
            i_incr                          : in std_logic_vector(2*FSize-1 downto 0);
            i_decr                          : in std_logic_vector(2*FSize-1 downto 0);
            i_FSMstate                      : in std_logic_vector(SWIDTH-1 downto 0);
            i_TA_high_threshold             : in std_logic_vector(7 downto 0); -- -- Here: UNSIGNED. 
            o_includes_per_clause           : out std_logic_vector(2*FSize-1 downto 0); -- This signal is the "current" state of the TA MSBs. 
            o_includes_per_clause_IE_update : out std_logic_vector(2*FSize-1 downto 0)  
                                          -- This signal is the "next" state of the TAs for the given clause. 
                                          -- It is fed to the IncludeExclude register and stored there.
                                          -- It is also fed to the Training module, during clause/TA updating.
            );
end TsetlinAutomata; 

architecture RTL of TsetlinAutomata is 

    signal w_enRAM              : std_logic; 
    signal w_RAM_write          : std_logic;
    
    signal w_resetvector        :  std_logic_vector(71 downto 0); -- 9 bits in each TA
    signal w_TA_high_threshold  :  signed(8 downto 0);
    signal w_TA_low_threshold   :  signed(8 downto 0); 
    signal w_incrementvector    :  signed(8 downto 0);
    
    signal w_TA_stateN          :  signed(8 downto 0);
    signal w_TA_stateNplus1     :  signed(8 downto 0);
    
    type word_RAM_8TAs_signed is array(33 downto 0) of signed(71 downto 0); 
    signal w_TA                 : word_RAM_8TAs_signed;
    signal w_TB                 : word_RAM_8TAs_signed; -- needed for model load (future implementation).
    
    type word_RAM_8TAs is array(33 downto 0) of std_logic_vector(71 downto 0);   
    signal w_dia                : word_RAM_8TAs;
    signal w_dob                : word_RAM_8TAs;
    
    type MSBarray_8TAas is array(33 downto 0) of std_logic_vector(7 downto 0); 
    signal w_includes_per_clause            : MSBarray_8TAas;
    signal w_includes_per_clause_IE_update  : MSBarray_8TAas;
    
    signal w_addrRAM            : std_logic_vector(NBitsClauseAddr-1 downto 0); 
    signal w_addr_increment     : std_logic_vector(NBitsClauseAddr-1 downto 0); 

begin

  w_resetvector        <= "111111111" & "111111111" & "111111111" & "111111111" & "111111111" & "111111111" & "111111111" & "111111111";        

  w_TA_high_threshold  <= signed('0' & i_TA_high_threshold);
  
  w_TA_low_threshold  <=  "000000000" - w_TA_high_threshold;
  
  w_incrementvector    <= "000000001";
  
  w_TA_stateN          <= "111111111";
  w_TA_stateNplus1     <= "000000000";
  
  w_addr_increment     <= (0 => '1', others => '0');
  
  w_addrRAM <= i_clauseaddr - w_addr_increment when i_EnWriteModel='1'
               else i_clauseaddr;
 
  w_enRAM <= '1' when i_FSMstate=InitializePhase0 or i_FSMstate=InitializeTAsAndLFSRsANDWeights or i_FSMstate=InitializePhase1 
                   or i_FSMstate=Learn_UpdateClausesAndTAsAndWeights1 or i_FSMstate=Learn_UpdateClausesAndTAsAndWeights2 
                   or i_EnWriteModel='1'
              else '0';
              
  w_RAM_write <= i_write_enable or i_EnWriteModel;
  
  ALL_TA: FOR K in 33 downto 0 GENERATE    -- 2*Fsize/8=272/8=34

       x8_TA_block : entity work.TA_RAM_block_singleport(syn1)
             port map( 
                      clk   => i_clk,
                      we    => w_RAM_write, 
                      en    => w_enRAM,  
                      addr  => w_addrRAM,
                      di    => w_dia(K),
                      do    => w_dob(K)
                     );
        
        w_TA(K)(71 downto 63) <=     (signed(w_dob(K)(71 downto 63)) + w_incrementvector) when (i_incr(K*8+7)='1' and signed(w_dob(K)(71 downto 63)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(71 downto 63)) - w_incrementvector) when (i_decr(K*8+7)='1' and signed(w_dob(K)(71 downto 63)) > w_TA_low_threshold)
                                else signed(w_dob(K)(71 downto 63));
        
        w_TA(K)(62 downto 54) <=     (signed(w_dob(K)(62 downto 54)) + w_incrementvector) when (i_incr(K*8+6)='1' and signed(w_dob(K)(62 downto 54)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(62 downto 54)) - w_incrementvector) when (i_decr(K*8+6)='1' and signed(w_dob(K)(62 downto 54)) > w_TA_low_threshold)
                                else signed(w_dob(K)(62 downto 54));
                                
        w_TA(K)(53 downto 45) <=     (signed(w_dob(K)(53 downto 45)) + w_incrementvector) when (i_incr(K*8+5)='1' and signed(w_dob(K)(53 downto 45)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(53 downto 45)) - w_incrementvector) when (i_decr(K*8+5)='1' and signed(w_dob(K)(53 downto 45)) > w_TA_low_threshold)
                                else signed(w_dob(K)(53 downto 45));
        
        w_TA(K)(44 downto 36) <=     (signed(w_dob(K)(44 downto 36)) + w_incrementvector) when (i_incr(K*8+4)='1' and signed(w_dob(K)(44 downto 36)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(44 downto 36)) - w_incrementvector) when (i_decr(K*8+4)='1' and signed(w_dob(K)(44 downto 36)) > w_TA_low_threshold)
                                else signed(w_dob(K)(44 downto 36));
                                
        w_TA(K)(35 downto 27) <=     (signed(w_dob(K)(35 downto 27)) + w_incrementvector) when (i_incr(K*8+3)='1' and signed(w_dob(K)(35 downto 27)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(35 downto 27)) - w_incrementvector) when (i_decr(K*8+3)='1' and signed(w_dob(K)(35 downto 27)) > w_TA_low_threshold)
                                else signed(w_dob(K)(35 downto 27));
        
        w_TA(K)(26 downto 18) <=     (signed(w_dob(K)(26 downto 18)) + w_incrementvector) when (i_incr(K*8+2)='1' and signed(w_dob(K)(26 downto 18)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(26 downto 18)) - w_incrementvector) when (i_decr(K*8+2)='1' and signed(w_dob(K)(26 downto 18)) > w_TA_low_threshold)
                                else signed(w_dob(K)(26 downto 18));
                                
        w_TA(K)(17 downto 9) <=      (signed(w_dob(K)(17 downto 9)) + w_incrementvector) when (i_incr(K*8+1)='1' and signed(w_dob(K)(17 downto 9)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(17 downto 9)) - w_incrementvector) when (i_decr(K*8+1)='1' and signed(w_dob(K)(17 downto 9)) > w_TA_low_threshold)
                                else signed(w_dob(K)(17 downto 9));
                                
        w_TA(K)(8 downto 0) <=       (signed(w_dob(K)(8 downto 0)) + w_incrementvector) when (i_incr(K*8+0)='1' and signed(w_dob(K)(8 downto 0)) < w_TA_high_threshold)
                                else (signed(w_dob(K)(8 downto 0)) - w_incrementvector) when (i_decr(K*8+0)='1' and signed(w_dob(K)(8 downto 0)) > w_TA_low_threshold)
                                else signed(w_dob(K)(8 downto 0));
        
        w_TB(K)(71 downto 63)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+7)='1' else w_TA_stateN;
        w_TB(K)(62 downto 54)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+6)='1' else w_TA_stateN;
        w_TB(K)(53 downto 45)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+5)='1' else w_TA_stateN;
        w_TB(K)(44 downto 36)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+4)='1' else w_TA_stateN;
        w_TB(K)(35 downto 27)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+3)='1' else w_TA_stateN;
        w_TB(K)(26 downto 18)    <= w_TA_stateNplus1 when i_Model_IEbits(K*8+2)='1' else w_TA_stateN;
        w_TB(K)(17 downto 9)     <= w_TA_stateNplus1 when i_Model_IEbits(K*8+1)='1' else w_TA_stateN;
        w_TB(K)(8 downto 0)      <= w_TA_stateNplus1 when i_Model_IEbits(K*8)  ='1' else w_TA_stateN;
        
        w_dia(K) <=w_resetvector when i_rst='1' or i_initialize='1'
               else std_logic_vector(w_TB(K)) when i_EnWriteModel='1' 
               else std_logic_vector(w_TA(K)(71 downto 63)) & std_logic_vector(w_TA(K)(62 downto 54)) & 
                    std_logic_vector(w_TA(K)(53 downto 45)) & std_logic_vector(w_TA(K)(44 downto 36)) &
                    std_logic_vector(w_TA(K)(35 downto 27)) & std_logic_vector(w_TA(K)(26 downto 18)) & 
                    std_logic_vector(w_TA(K)(17 downto 9))  & std_logic_vector(w_TA(K)(8 downto 0));
      
       w_includes_per_clause(K) <= not(w_dob(K)(71) & w_dob(K)(62) & w_dob(K)(53) & w_dob(K)(44) & w_dob(K)(35) & w_dob(K)(26) & w_dob(K)(17) & w_dob(K)(8));
        -- The MSB of each TA is inverted so we get a '1' for those literals that should be included.
        -- 9 state bits per TA
        
       w_includes_per_clause_IE_update(K) <= not(w_TA(K)(71) & w_TA(K)(62) & w_TA(K)(53) & w_TA(K)(44) & w_TA(K)(35) & w_TA(K)(26) & w_TA(K)(17) & w_TA(K)(8));
      
      END GENERATE ALL_TA;
      
      -- The number of bits of this output signal is 34*8=272 which is 2*FSize.     
      
      o_includes_per_clause <= w_includes_per_clause(33)  & w_includes_per_clause(32)  & w_includes_per_clause(31)  & w_includes_per_clause(30) &
                               w_includes_per_clause(29)  & w_includes_per_clause(28)  & w_includes_per_clause(27)  & w_includes_per_clause(26) &
                               w_includes_per_clause(25)  & w_includes_per_clause(24)  & w_includes_per_clause(23)  & w_includes_per_clause(22) &
                               w_includes_per_clause(21)  & w_includes_per_clause(20)  & w_includes_per_clause(19)  & w_includes_per_clause(18) &
                               w_includes_per_clause(17)  & w_includes_per_clause(16)  & w_includes_per_clause(15)  & w_includes_per_clause(14) &
                               w_includes_per_clause(13)  & w_includes_per_clause(12)  & w_includes_per_clause(11)  & w_includes_per_clause(10) &
                               w_includes_per_clause(9)   & w_includes_per_clause(8)   & w_includes_per_clause(7)   & w_includes_per_clause(6) &
                               w_includes_per_clause(5)   & w_includes_per_clause(4)   & w_includes_per_clause(3)   & w_includes_per_clause(2) &
                               w_includes_per_clause(1)   & w_includes_per_clause(0); 
                               -- "MSB of all TAs". For use during Training.
        
        o_includes_per_clause_IE_update <= 
                               w_includes_per_clause_IE_update(33)  & w_includes_per_clause_IE_update(32)  & w_includes_per_clause_IE_update(31)  & w_includes_per_clause_IE_update(30) &
                               w_includes_per_clause_IE_update(29)  & w_includes_per_clause_IE_update(28)  & w_includes_per_clause_IE_update(27)  & w_includes_per_clause_IE_update(26) &
                               w_includes_per_clause_IE_update(25)  & w_includes_per_clause_IE_update(24)  & w_includes_per_clause_IE_update(23)  & w_includes_per_clause_IE_update(22) &
                               w_includes_per_clause_IE_update(21)  & w_includes_per_clause_IE_update(20)  & w_includes_per_clause_IE_update(19)  & w_includes_per_clause_IE_update(18) &
                               w_includes_per_clause_IE_update(17)  & w_includes_per_clause_IE_update(16)  & w_includes_per_clause_IE_update(15)  & w_includes_per_clause_IE_update(14) &
                               w_includes_per_clause_IE_update(13)  & w_includes_per_clause_IE_update(12)  & w_includes_per_clause_IE_update(11)  & w_includes_per_clause_IE_update(10) &
                               w_includes_per_clause_IE_update(9)   & w_includes_per_clause_IE_update(8)   & w_includes_per_clause_IE_update(7)   & w_includes_per_clause_IE_update(6) &
                               w_includes_per_clause_IE_update(5)   & w_includes_per_clause_IE_update(4)   & w_includes_per_clause_IE_update(3)   & w_includes_per_clause_IE_update(2) &
                               w_includes_per_clause_IE_update(1)   & w_includes_per_clause_IE_update(0); 
                               -- "MSB of all TAs". For use during Training.                      
           
end RTL;

