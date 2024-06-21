library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;        
use work.MainFSMDefinitions.all;     
 
entity LED_control is 
    Port (
        i_FSMstate                  : in std_logic_vector(SWIDTH-1 downto 0);
        o_LED1_InitialState         : out std_logic;
        o_LED2_FinishedInf          : out std_logic;
        o_LED3_FinishedLearn        : out std_logic;
        
        o_statereg                  : out std_logic_vector(7 downto 0)
        );
end LED_control;

architecture rtl of LED_control is

begin

    o_LED1_InitialState         <= '1' when i_FSMstate = InitialState else '0';
    o_LED2_FinishedInf          <= '1' when i_FSMstate = keepClassDecision else '0';
    o_LED3_FinishedLearn        <= '1' when i_FSMstate = FinishedTraining else '0';

    o_statereg(0) <= '1' when i_FSMstate = InitialState else '0';
    o_statereg(1) <= '1' when i_FSMstate = keepClassDecision else '0';
    o_statereg(2) <= '1' when i_FSMstate = FinishedTraining else '0';
    o_statereg(3) <= '1' when i_FSMstate = FinishedInitialize else '0';
    o_statereg(4) <= '1' when i_FSMstate = FinishedLoadMODEL else '0';

    o_statereg(5) <= '0';
    o_statereg(6) <= '0'; 
    o_statereg(7) <= '0'; 

end rtl;