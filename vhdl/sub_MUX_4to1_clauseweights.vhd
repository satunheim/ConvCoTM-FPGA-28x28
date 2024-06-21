library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
--use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
--use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;
 
entity sub_MUX_4to1_clauseweights is  
    Port (
          i_clauseWeights   : in array4ofClauseWeights; 
          i_sel             : in std_logic_vector(1 downto 0); -- in std_logic_vector(2 downto 0);
          o_MuxOut          : out signed(NBitsIW-1 downto 0) 
          );
end sub_MUX_4to1_clauseweights;

architecture RTL of sub_MUX_4to1_clauseweights is

begin

    with i_sel select
        o_MuxOut <=  i_clauseWeights(0)  when "00",
                     i_clauseWeights(1)  when "01",
                     i_clauseWeights(2)  when "10",
                     i_clauseWeights(3)  when "11",
                     (others => '0') when others;

--    with i_sel select
--        o_MuxOut <=  i_clauseWeights(0)  when "0000",
--                     i_clauseWeights(1)  when "0001",
--                     i_clauseWeights(2)  when "0010",
--                     i_clauseWeights(3)  when "0011",
--                     (others => '0') when others;

end RTL;
