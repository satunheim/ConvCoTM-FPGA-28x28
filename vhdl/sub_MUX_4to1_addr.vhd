library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
--use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
--use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;
 
entity sub_MUX_4to1_addr is  
    Port (
          i_addrFromReg     : in array4ofPatchAddresses; 
          i_sel             : in std_logic_vector(1 downto 0); -- std_logic_vector(3 downto 0);
          o_MuxOut          : out std_logic_vector(8 downto 0) 
          );
end sub_MUX_4to1_addr;

architecture RTL of sub_MUX_4to1_addr is

begin

    with i_sel select
        o_MuxOut <=  i_addrFromReg(0)  when "00",
                     i_addrFromReg(1)  when "01",
                     i_addrFromReg(2)  when "10",
                     i_addrFromReg(3)  when "11",
                     (others => '0') when others;

end RTL;