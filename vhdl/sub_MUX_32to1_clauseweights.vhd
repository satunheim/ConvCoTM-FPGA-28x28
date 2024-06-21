library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
--use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
--use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;
 
entity sub_MUX_32to1_clauseweights is  
    Port (
          i_clauseWeights   : in array32ofClauseWeights; 
          i_sel             : in std_logic_vector(4 downto 0);
          o_MuxOut          : out signed(NBitsIW-1 downto 0) 
          );
end sub_MUX_32to1_clauseweights;

architecture RTL of sub_MUX_32to1_clauseweights is

begin

    with i_sel select
        o_MuxOut <=  i_clauseWeights(0)  when "00000",
                     i_clauseWeights(1)  when "00001",
                     i_clauseWeights(2)  when "00010",
                     i_clauseWeights(3)  when "00011",
                     i_clauseWeights(4)  when "00100",
                     i_clauseWeights(5)  when "00101",
                     i_clauseWeights(6)  when "00110",
                     i_clauseWeights(7)  when "00111",
                     i_clauseWeights(8)  when "01000",
                     i_clauseWeights(9)  when "01001",
                     i_clauseWeights(10) when "01010",
                     i_clauseWeights(11) when "01011",
                     i_clauseWeights(12) when "01100",
                     i_clauseWeights(13) when "01101",
                     i_clauseWeights(14) when "01110",
                     i_clauseWeights(15) when "01111",
                     i_clauseWeights(16) when "10000",
                     i_clauseWeights(17) when "10001",
                     i_clauseWeights(18) when "10010",
                     i_clauseWeights(19) when "10011",
                     i_clauseWeights(20) when "10100",
                     i_clauseWeights(21) when "10101",
                     i_clauseWeights(22) when "10110",
                     i_clauseWeights(23) when "10111",
                     i_clauseWeights(24) when "11000",
                     i_clauseWeights(25) when "11001",
                     i_clauseWeights(26) when "11010",
                     i_clauseWeights(27) when "11011",
                     i_clauseWeights(28) when "11100",
                     i_clauseWeights(29) when "11101",
                     i_clauseWeights(30) when "11110",
                     i_clauseWeights(31) when "11111",
                     (others => '0') when others;

end RTL;
