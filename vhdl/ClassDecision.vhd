library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
-- use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;  
 
entity ClassDecision is
    Port (
          i_classSum0 : in signed(NBsum-1 downto 0);
          i_classSum1 : in signed(NBsum-1 downto 0);
          i_classSum2 : in signed(NBsum-1 downto 0);
          i_classSum3 : in signed(NBsum-1 downto 0);
          i_classSum4 : in signed(NBsum-1 downto 0);
          i_classSum5 : in signed(NBsum-1 downto 0);
          i_classSum6 : in signed(NBsum-1 downto 0);
          i_classSum7 : in signed(NBsum-1 downto 0);
          i_classSum8 : in signed(NBsum-1 downto 0);
          i_classSum9 : in signed(NBsum-1 downto 0); 
          
	      o_classPredict : out unsigned(3 downto 0)
	      
	      ); 
	      
end ClassDecision; 

architecture rtl2 of ClassDecision is 
    
    signal w_argmax0, w_argmax1, w_argmax2, w_argmax3, w_argmax4, w_argmax5, w_argmax6, w_argmax7, w_argmax8 : unsigned(3 downto 0);
    signal w_compout0, w_compout1, w_compout2, w_compout3, w_compout4, w_compout5, w_compout6, w_compout7, w_compout8  : std_logic;
    signal w_max0, w_max1, w_max2, w_max3, w_max4, w_max5, w_max6, w_max7, w_max8 : signed(NBsum-1 downto 0);
     
begin 
    -- First layer of comparators and argmax functionality:
    w_compout0 <='1' when i_classSum1 > i_classSum0 else '0';
    w_argmax0 <= "0001" when w_compout0='1' else "0000";
    w_max0 <= i_classSum1 when w_compout0='1' else i_classSum0;
    
    w_compout1 <='1' when i_classSum3 > i_classSum2 else '0';
    w_argmax1 <= "0011" when w_compout1='1' else "0010";
    w_max1 <= i_classSum3 when w_compout1='1' else i_classSum2;
    
    w_compout2 <='1' when i_classSum5 > i_classSum4 else '0';
    w_argmax2 <= "0101" when w_compout2='1' else "0100";
    w_max2 <= i_classSum5 when w_compout2='1' else i_classSum4;

    w_compout3 <='1' when i_classSum7 > i_classSum6 else '0';
    w_argmax3 <= "0111" when w_compout3='1' else "0110";
    w_max3 <= i_classSum7 when w_compout3='1' else i_classSum6;
    
    w_compout4 <='1' when i_classSum9 > i_classSum8 else '0';
    w_argmax4 <= "1001" when w_compout4='1' else "1000";
    w_max4 <= i_classSum9 when w_compout4='1' else i_classSum8;
    
    -- Second layer of comparators and argmax functionality:
    w_compout5 <='1' when w_max1 > w_max0 else '0';
    w_argmax5 <= w_argmax1 when w_compout5='1' else w_argmax0;
    w_max5 <= w_max1 when w_compout5='1' else w_max0;

    w_compout6 <='1' when w_max3 > w_max2 else '0';
    w_argmax6 <= w_argmax3 when w_compout6='1' else w_argmax2;
    w_max6 <= w_max3 when w_compout6='1' else w_max2;
    
    -- Third layer of comparators and argmax functionality:
    w_compout7 <='1' when w_max6 > w_max5 else '0';
    w_argmax7 <= w_argmax6 when w_compout7='1' else w_argmax5;
    w_max7 <= w_max6 when w_compout7='1' else w_max5;

    -- Fourth layer of comparators and argmax functionality:
    w_compout8 <='1' when w_max4 > w_max7 else '0';
    w_argmax8 <= w_argmax4 when w_compout8='1' else w_argmax7;
    w_max8 <= w_max4 when w_compout8='1' else w_max7;        
    
    o_classPredict <= w_argmax8; 

end rtl2;