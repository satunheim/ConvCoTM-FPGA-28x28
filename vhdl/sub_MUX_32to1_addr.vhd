library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
--use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
--use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;
 
entity sub_MUX_32to1_addr is  
    Port (
          i_addrFromReg     : in array32ofPatchAddresses; 
          i_sel             : in std_logic_vector(4 downto 0);
          o_MuxOut          : out std_logic_vector(8 downto 0) 
          );
end sub_MUX_32to1_addr;

architecture RTL of sub_MUX_32to1_addr is

begin

    with i_sel select
        o_MuxOut <=  i_addrFromReg(0)  when "00000",
                     i_addrFromReg(1)  when "00001",
                     i_addrFromReg(2)  when "00010",
                     i_addrFromReg(3)  when "00011",
                     i_addrFromReg(4)  when "00100",
                     i_addrFromReg(5)  when "00101",
                     i_addrFromReg(6)  when "00110",
                     i_addrFromReg(7)  when "00111",
                     i_addrFromReg(8)  when "01000",
                     i_addrFromReg(9)  when "01001",
                     i_addrFromReg(10) when "01010",
                     i_addrFromReg(11) when "01011",
                     i_addrFromReg(12) when "01100",
                     i_addrFromReg(13) when "01101",
                     i_addrFromReg(14) when "01110",
                     i_addrFromReg(15) when "01111",
                     i_addrFromReg(16) when "10000",
                     i_addrFromReg(17) when "10001",
                     i_addrFromReg(18) when "10010",
                     i_addrFromReg(19) when "10011",
                     i_addrFromReg(20) when "10100",
                     i_addrFromReg(21) when "10101",
                     i_addrFromReg(22) when "10110",
                     i_addrFromReg(23) when "10111",
                     i_addrFromReg(24) when "11000",
                     i_addrFromReg(25) when "11001",
                     i_addrFromReg(26) when "11010",
                     i_addrFromReg(27) when "11011",
                     i_addrFromReg(28) when "11100",
                     i_addrFromReg(29) when "11101",
                     i_addrFromReg(30) when "11110",
                     i_addrFromReg(31) when "11111",
                     (others => '0') when others;

end RTL;
