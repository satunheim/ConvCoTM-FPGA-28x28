library ieee;
use IEEE.STD_LOGIC_1164.ALL;

package FSM_Moving_Window_definitions_28x28 is

    constant SWIDTH_Moving_Window: Integer := 20; 
    -- (=(28-10)/1 +1 = 18+1=19=Bx
    -- We need one more state than Bx!? I.e. 20 (numbered from 0 to 19)
    
    -- The states are one-hot encoded:
    constant MWstate0     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00000001";
    constant MWstate1     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00000010";
    constant MWstate2     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00000100";
    constant MWstate3     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00001000";
    constant MWstate4     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00010000";
    constant MWstate5     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "00100000";
    constant MWstate6     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "01000000";
    constant MWstate7     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000000" & "10000000";
    constant MWstate8     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000001" & "00000000";
    constant MWstate9     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000010" & "00000000";
    constant MWstate10    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00000100" & "00000000";
    constant MWstate11    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00001000" & "00000000";
    constant MWstate12    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00010000" & "00000000";
    constant MWstate13    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "00100000" & "00000000";
    constant MWstate14    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "01000000" & "00000000";
    constant MWstate15    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000" & "10000000" & "00000000";
    constant MWstate16    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0001" & "00000000" & "00000000";
    constant MWstate17    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0010" & "00000000" & "00000000";
    constant MWstate18    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0100" & "00000000" & "00000000";
    constant MWstate19    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "1000" & "00000000" & "00000000";
   
end package;

-- ********************************************************************************

library ieee;
use IEEE.STD_LOGIC_1164.ALL;

package FSM_Moving_Window_definitions_32x32 is

    constant SWIDTH_Moving_Window: Integer := 30; 
    -- (=(32-3)/1 +1 = 29+1=30
    -- We need one more state than Bx!? I.e. 31 (numbered from 0 to 30)
    
    -- The states are one-hot encoded:
    constant MWstate0     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00000001";
    constant MWstate1     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00000010";
    constant MWstate2     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00000100";
    constant MWstate3     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00001000";
    constant MWstate4     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00010000";
    constant MWstate5     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "00100000";
    constant MWstate6     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "01000000";
    constant MWstate7     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000000" & "10000000";
    constant MWstate8     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000001" & "00000000";
    constant MWstate9     : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000010" & "00000000";
    constant MWstate10    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00000100" & "00000000";
    constant MWstate11    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00001000" & "00000000";
    constant MWstate12    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00010000" & "00000000";
    constant MWstate13    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "00100000" & "00000000";
    constant MWstate14    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "01000000" & "00000000";
    constant MWstate15    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000000" & "10000000" & "00000000";
    constant MWstate16    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000001" & "00000000" & "00000000";
    constant MWstate17    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000010" & "00000000" & "00000000";
    constant MWstate18    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00000100" & "00000000" & "00000000";
    constant MWstate19    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00001000" & "00000000" & "00000000";
    constant MWstate20    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00010000" & "00000000" & "00000000";
    constant MWstate21    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "00100000" & "00000000" & "00000000";
    constant MWstate22    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "01000000" & "00000000" & "00000000";
    constant MWstate23    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000000" & "10000000" & "00000000" & "00000000";
    constant MWstate24    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000001" & "00000000" & "00000000" & "00000000";
    constant MWstate25    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000010" & "00000000" & "00000000" & "00000000";
    constant MWstate26    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0000100" & "00000000" & "00000000" & "00000000";      
    constant MWstate27    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0001000" & "00000000" & "00000000" & "00000000";
    constant MWstate28    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0010000" & "00000000" & "00000000" & "00000000";
    constant MWstate29    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "0100000" & "00000000" & "00000000" & "00000000";  
    constant MWstate30    : std_logic_vector(SWIDTH_Moving_Window-1 downto 0)   := "1000000" & "00000000" & "00000000" & "00000000";
   
end package;