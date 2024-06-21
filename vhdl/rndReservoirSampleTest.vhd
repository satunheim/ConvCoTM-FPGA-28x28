library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;

entity rndReservoirSampleTest is
    Port ( 
            i_LFSRinput       : in unsigned (23 downto 0); --unsigned (23 downto 0);   
            i_ClauseSignal    : in std_logic;
            i_Ncounter        : in std_logic_vector(NBitsPatchAddr-1 downto 0);  -- For the 28x28 MNIST case (with 10x10 window) max B is 361
            i_enable          : in std_logic;
            o_UpdateRreg      : out std_logic
            );
end rndReservoirSampleTest;

architecture RTL of rndReservoirSampleTest is

    signal w_na         : unsigned(NBitsPatchAddr-1 downto 0);
    signal w_xb         : unsigned(23 downto 0);
    signal w_xc         : unsigned(32 downto 0);
    signal w_ga         : unsigned(NBitsPatchAddr-1 downto 0);

begin
    
    w_na <= unsigned(i_Ncounter); 

    w_xb <= i_LFSRinput; 
   
    w_xc <= w_na * w_xb;

    w_ga <= w_xc(32 downto 24); 

    o_UpdateRreg <= '1' when i_ClauseSignal='1' and i_enable='1' and (w_ga="000000000") else '0';

end RTL;
