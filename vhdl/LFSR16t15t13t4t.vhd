library IEEE;
use IEEE.STD_LOGIC_1164.ALL;   
use work.FF.all; 

entity LFSR16t15t13t4t is 
    port (
        clk         : in STD_LOGIC;
        i_rst       : in STD_LOGIC;
        i_en        : in STD_LOGIC;
	    i_seed      : in  std_logic_vector (15 downto 0);
	    o_regout    : out std_logic_vector (15 downto 0)
	   );  
end LFSR16t15t13t4t;

architecture RTL of LFSR16t15t13t4t is

    signal w_nxt    : std_logic_vector (15 downto 0);
    signal w_regout : std_logic_vector (15 downto 0);

begin 

    PRBSreg: vDFFce generic map(16) port map(clk, i_en, w_nxt, w_regout);

    w_nxt <= 
             i_seed when i_rst='1'
       else (w_regout(0) xor w_regout(1) xor w_regout(3) xor w_regout(12)) & w_regout(15 downto 1);
        -- the register is flipped to enable a downto std_logic_vector which is better for the
        -- following calculations. In a standard LFSR one starts counting the bits from the left, starting with 1. Below is 
        -- how the conversion is made:
        --  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16  (standard bit convention for LFSR)
        -- 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0  (numbering for a std_logic_vector (17 downto 0))
        
       o_regout <= w_regout;

end RTL;

