library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
--use IEEE.std_logic_misc.all; 
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;
   
entity Synchronizer is 
    Port (
         clk       : in  std_logic;
         i_signal  : in  STD_LOGIC_VECTOR(7 downto 0);
         o_sync    : out STD_LOGIC_VECTOR(7 downto 0)
           );
end Synchronizer;

architecture rtl of Synchronizer is 

    signal w_interm1 : STD_LOGIC_VECTOR(7 downto 0);
    signal w_sync    : STD_LOGIC_VECTOR(7 downto 0);
    
begin
    
        REG0 : vDFF generic map(8) port map(clk, i_signal, w_interm1);
        REG2 : vDFF generic map(8) port map(clk, w_interm1, w_sync);

    o_sync <= w_sync;
    
end rtl;
