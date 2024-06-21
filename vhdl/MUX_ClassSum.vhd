library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all; 

entity MUX_ClassSum is
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

          i_ClassSelect: in std_logic_vector(3 downto 0);  
          i_learn : in std_logic; 
          
          o_MuxOut : out signed(NBsum-1 downto 0)
          );
end MUX_ClassSum;

architecture RTL of MUX_ClassSum is
 
begin

    with i_ClassSelect & i_learn select
      o_MuxOut <=  i_classSum0 when "0000" & "1",
                   i_classSum1 when "0001" & "1",
                   i_classSum2 when "0010" & "1",
                   i_classSum3 when "0011" & "1",
                   i_classSum4 when "0100" & "1",
                   i_classSum5 when "0101" & "1",
                   i_classSum6 when "0110" & "1",
                   i_classSum7 when "0111" & "1",
                   i_classSum8 when "1000" & "1",
                   i_classSum9 when "1001" & "1",
                   (others => '1') when others;

end RTL;
