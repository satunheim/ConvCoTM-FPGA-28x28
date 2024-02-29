library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;        
use work.MainFSMDefinitions.all;  
 
entity LED_control is 
    Port (FSMstate : in std_logic_vector(SWIDTH-1 downto 0);
          LED1_InitialState : out std_logic;
          LED2_FinishedInf : out std_logic;
          LED3_FinishedLearn : out std_logic
          );
end LED_control;

architecture Behavioral of LED_control is


begin

    LED1_InitialState <= '1' when FSMstate = InitialState else '0';
    LED2_FinishedInf <= '1' when FSMstate = FinishedInf else '0';
    LED3_FinishedLearn <= '1' when FSMstate = FinishedLearn else '0';

end Behavioral;