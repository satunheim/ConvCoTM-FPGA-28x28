library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.FF.all; 

entity LFSR12t11t10t4t is 
    port (
        clk         : in STD_LOGIC;
        i_rst       : in STD_LOGIC;
        i_en        : in STD_LOGIC;
	    i_seed      : in  std_logic_vector (11 downto 0);
	    o_regout    : out std_logic_vector (11 downto 0)
	   );
end LFSR12t11t10t4t;

architecture RTL of LFSR12t11t10t4t is
    signal w_nxt, w_regout : std_logic_vector (11 downto 0);
begin

    PRBSreg: vDFFce generic map(12) port map(clk, i_en, w_nxt, w_regout);

    w_nxt <= 
       -- (others=>'1') when rst='1' 
       i_seed when i_rst='1'
        -- but the register is flipped to enable a downto std_logic_vector which is better for the
        -- following calculations. In a standard LFSR one starts counting the bits from the left, starting with 1. Below is 
        -- how the conversion is made:
        --  1  2  3  4  5  6  7  8  9 10 11 12  (standard bit convention for LFSR)
        -- 11 10  9  8  7  6  5  4  3  2  1  0  (numbering for a std_logic_vector (17 downto 0))
                
       else (w_regout(0) xor w_regout(1) xor w_regout(2) xor w_regout(8)) & w_regout(11 downto 1);
       -- Corrected 2022-10-30
   
       o_regout <= w_regout;

end RTL;

