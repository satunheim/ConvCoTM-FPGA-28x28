library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.FF.all;
  
entity LFSR9 is
    port (
        clk         : in STD_LOGIC;
        i_rst       : in STD_LOGIC;
        i_en        : in STD_LOGIC;
	    i_seed      : in  std_logic_vector (8 downto 0);
	    o_regout    : out std_logic_vector (8 downto 0)
	   );   
end LFSR9;

architecture RTL of LFSR9 is
    signal w_nxt, w_regout : std_logic_vector (8 downto 0);
begin

    PRBSreg: vDFFce generic map(9) port map(clk, i_en, w_nxt, w_regout);

    w_nxt <= 
       -- (others=>'1') when rst='1' 
       i_seed when i_rst='1'
        -- 2022-10-30 : polynomial: x^9+x^5+1
        -- The register is flipped to enable a downto std_logic_vector which is better for the
        -- following calculations. In a standard LFSR one starts counting the bits from the left, starting with 1. Below is 
        -- how the conversion is made:
        --  1  2  3  4  5  6  7  8  9  (standard bit convention for LFSR)
        --  8  7  6  5  4  3  2  1  0  (numbering for a std_logic_vector (7 downto 0))
                
       else (w_regout(0) xor w_regout(4)) & w_regout(8 downto 1);
   
       o_regout <= w_regout;

end RTL;
