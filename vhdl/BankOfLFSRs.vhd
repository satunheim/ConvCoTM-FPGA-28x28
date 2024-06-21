library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
 
entity BankOfLFSRs is
    Port (
         clk                : in STD_LOGIC;
         i_rst              : in STD_LOGIC;
         i_en               : in STD_LOGIC;
         i_isTarget         : in STD_LOGIC; -- 1 means "is Target", 0 means "Negative target"
                              -- As we do not train Target and Negative Target in parallel, it is not critical to have different seeding based on
                              -- what class is trained. This input can be kept, but can be hardwired to '0' externally at a higher hierarchy level. 
         i_lengthLFSRs      : in std_logic_vector(2 downto 0);
         o_regout           : out LFSRrandomnumbers
        );  
end BankOfLFSRs;

architecture RTL of BankOfLFSRs is

    type LFSRrandomnumbers24 is array (0 to NLFSRs-1) of std_logic_vector(23 downto 0); 
    type LFSRrandomnumbers16 is array (0 to NLFSRs-1) of std_logic_vector(15 downto 0); 
    type LFSRrandomnumbers14 is array (0 to NLFSRs-1) of std_logic_vector(13 downto 0); 
    type LFSRrandomnumbers12 is array (0 to NLFSRs-1) of std_logic_vector(11 downto 0); 
    type LFSRrandomnumbers10 is array (0 to NLFSRs-1) of std_logic_vector(9 downto 0); 
    type LFSRrandomnumbers9  is array (0 to NLFSRs-1) of std_logic_vector(8 downto 0);
    type LFSRrandomnumbers8  is array (0 to NLFSRs-1) of std_logic_vector(7 downto 0);   
    type LFSRrandomnumbers7  is array (0 to NLFSRs-1) of std_logic_vector(6 downto 0);
    
    signal w_seed24, w_regout24 : LFSRrandomnumbers24;
    signal w_seed16, w_regout16 : LFSRrandomnumbers16; 
    signal w_seed14, w_regout14 : LFSRrandomnumbers14;
    signal w_seed12, w_regout12 : LFSRrandomnumbers12;
    signal w_seed10, w_regout10 : LFSRrandomnumbers10;
    signal w_seed9,  w_regout9  : LFSRrandomnumbers9;
    signal w_seed8,  w_regout8  : LFSRrandomnumbers8;
    signal w_seed7,  w_regout7  : LFSRrandomnumbers7;

    signal w_selectLFSR : std_logic_vector(3 downto 0);
    
    signal w_en16       : std_logic;
    signal w_en24       : std_logic;
    
    signal w_en12, w_en10, w_en8 : std_logic;
    signal w_en14, w_en7, w_en9 : std_logic;
    
    signal w_a, w_b : std_logic;

    type tempforLFSRseed is array (0 to NLFSRs-1) of std_logic_vector(9 downto 0); 
    signal w_temp1    : tempforLFSRseed;

begin

    w_en16 <= '1' when i_lengthLFSRs="000" and i_en='1' else '0'; 
    w_en24 <= '1' when i_lengthLFSRs="001" and i_en='1' else '0'; 
    w_en14 <= '1' when i_lengthLFSRs="010" and i_en='1' else '0';
    w_en12 <= '1' when i_lengthLFSRs="011" and i_en='1' else '0';
    w_en10 <= '1' when i_lengthLFSRs="100" and i_en='1' else '0';
    w_en9  <= '1' when i_lengthLFSRs="101" and i_en='1' else '0';
    w_en8  <= '1' when i_lengthLFSRs="110" and i_en='1' else '0';
    w_en7  <= '1' when i_lengthLFSRs="111" and i_en='1' else '0';

    w_a <= i_isTarget;
    w_b <= not(i_isTarget);
       
    GEN_LFSRBANK: FOR K in 0 to NLFSRs-1 GENERATE    
        
        w_temp1(K) <= std_logic_vector(to_unsigned(K,10));
        
        w_seed16(K) <=  "010" & w_temp1(K)(9 downto 0) & "101";
        SingleLFSR16 : entity work.LFSR16t15t13t4t(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en16, 
                          i_seed    => w_seed16(K), 
                          o_regout  => w_regout16(K)
                          );

        w_seed14(K) <= "01" & w_temp1(K)(9 downto 0) & "01";
        SingleLFSR14 : entity work.LFSR14t13t12t2t(RTL)
         port map (
                  clk       => clk, 
                  i_rst     => i_rst, 
                  i_en      => w_en14, 
                  i_seed    => w_seed14(K), 
                  o_regout  => w_regout14(K)
                  );
        
        w_seed12(K) <= w_temp1(K)(9 downto 0) & "01";
        SingleLFSR12 : entity work.LFSR12t11t10t4t(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en12, 
                          i_seed    => w_seed12(K), 
                          o_regout  => w_regout12(K)
                          );

        w_seed10(K) <= w_temp1(K)(8 downto 0) & '1';
        SingleLFSR10 : entity work.LFSR10t7t(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en10, 
                          i_seed    => w_seed10(K), 
                          o_regout  => w_regout10(K)
                          );

        w_seed9(K) <= w_temp1(K)(7 downto 0) & '1';
        SingleLFSR9 : entity work.LFSR9(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en9, 
                          i_seed    => w_seed9(K), 
                          o_regout  => w_regout9(K)
                          );

        w_seed8(K) <= w_temp1(K)(6 downto 0) & '1';
        SingleLFSR8 : entity work.LFSR8t6t5t4t(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en8, 
                          i_seed    => w_seed8(K), 
                          o_regout  => w_regout8(K)
                          );
        
        w_seed7(K) <=  w_temp1(K)(5 downto 0) & '1';
        SingleLFSR7 : entity work.LFSR7(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en7, 
                          i_seed    => w_seed7(K), 
                          o_regout  => w_regout7(K)
                          );

    
        w_seed24(K) <= "01" & w_temp1(K)(9 downto 0) & "10" & w_temp1(K)(9 downto 0);
        
        SingleLFSR24 : entity work.LFSR24t23t22t17t(RTL)
                 port map (
                          clk       => clk, 
                          i_rst     => i_rst, 
                          i_en      => w_en24, 
                          i_seed    => w_seed24(K), 
                          o_regout  => w_regout24(K)
                          );
        
        
        with i_lengthLFSRs select
        o_regout(K) <= 
                    w_regout16(K) & "00000000" when "000", 
                    w_regout24(K) when "001",
                    w_regout14(K) & "00000000" & "00" when "010",
                    w_regout12(K) & "00000000" & "0000" when "011",
                    w_regout10(K) & "00000000" & "000000" when "100",
                    w_regout9(K)  & "00000000" & "0000000" when "101",
                    w_regout8(K)  & "00000000" & "00000000" when "110",
                    w_regout7(K)  & "00000000" & "000000000" when "111",
                    "00000000" & "00000000" & "00000000" when others; 

    END GENERATE GEN_LFSRBANK;

end RTL;
