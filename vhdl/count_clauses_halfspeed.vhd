library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all;
use work.FF.all;  
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
 
entity count_clauses_halfspeed is   
        Port (
             i_clk              : in STD_LOGIC; 
             i_rst              : in STD_LOGIC;
             i_en               : in STD_LOGIC;
             o_cCounterFinished : out STD_LOGIC;
             o_clauseAddress    : out std_logic_vector(NBitsClauseAddr-1 downto 0);
             o_lsb              : out std_logic
            );
end count_clauses_halfspeed;  

architecture rtl of count_clauses_halfspeed is 

    signal w_enablecounter  : std_logic;

    signal w_nxtC : std_logic_vector(NBitsClauseAddr downto 0);
    signal w_regoutC: std_logic_vector(NBitsClauseAddr downto 0);
    
    signal w_valueC : unsigned(NBitsClauseAddr downto 0);
    signal w_increment : unsigned(NBitsClauseAddr downto 0);
    signal w_valueCincremented : unsigned(NBitsClauseAddr downto 0);
 
begin

    w_enablecounter <= i_en or i_rst;

    clauseCOUNTreg: vDFFce generic map(NBitsClauseAddr+1) port map(i_clk, w_enablecounter, w_nxtC, w_regoutC);
    
    w_valueC <= unsigned(w_regoutC);
    w_increment <= (0 => '1', others => '0'); 
    w_valueCincremented <=w_valueC+w_increment;
    
    w_nxtC   <= (others=>'0') when i_rst='1' or (i_en='0') else
                 std_logic_vector(w_valueCincremented) when to_integer(w_valueC) < (2*NClauses-1) else 
                (others=>'0');
    
    o_clauseAddress <= w_regoutC(NBitsClauseAddr downto 1); 
    o_cCounterFinished <= '1' when to_integer(w_valueC) = (2*NClauses-1) else '0';
    o_lsb <= w_regoutC(0); -- Used for write enable to the TA RAMs

end rtl;

