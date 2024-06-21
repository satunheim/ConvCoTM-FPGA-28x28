library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;

entity BCounter is
    Port ( i_clk                    : in std_logic;
           i_rst                    : in STD_LOGIC;
           i_resetBounter           : in std_logic;
           
           o_BxCounterValue         : out std_logic_vector(4 downto 0); 
           o_ByCounterValue         : out std_logic_vector(4 downto 0);

           o_LoadNewRow             : out STD_LOGIC;
           o_EndOfPatches           : out STD_LOGIC; 
           o_PatchAddress           : out std_logic_vector(NBitsPatchAddr-1 downto 0) 
           ); 
end BCounter;   

architecture rtl of BCounter is 

    signal nxtBx, regoutBx, nxtBy, regoutBy : std_logic_vector(4 downto 0);
    
    signal BxValue, BxValueIncr             : unsigned(4 downto 0);
    signal ByValue, ByValueIncr             : unsigned(4 downto 0);
    signal incrementvector                  : unsigned(4 downto 0);
    
    signal PatchAdr                         : Integer;

begin  

    BXCOUNT: vDFF generic map(5) port map(I_clk, nxtBx, regoutBx);
    
    BYCOUNT: vDFF generic map(5) port map(i_clk, nxtBy, regoutBy);
    
    BxValue <= unsigned(regoutBx);
    ByValue <= unsigned(regoutBy);
    
    incrementvector <= (0 => '1', others => '0');
    BxValueIncr <= BxValue + incrementvector;
    ByValueIncr <= ByValue + incrementvector;
    
    nxtBx   <=   (others=>'0') when (i_rst='1' or i_resetBounter='1') else
                 std_logic_vector(BxValueIncr) when to_integer(BxValue) < (Bx-1) else 
                 (others=>'0');
                
    nxtBy <=    (others=>'0') when (i_rst='1' or i_resetBounter='1' or (PatchAdr=B-1)) else
                std_logic_vector(ByValueIncr) when ((to_integer(ByValue) < (By-1)) and (to_integer(BxValue)=(Bx-1)) ) else 
                regoutBy;
                    
    PatchAdr <= to_integer(ByValue)*By+to_integer(BxValue);
         
    o_PatchAddress <= std_logic_vector(to_unsigned(PatchAdr, o_PatchAddress'length));
    
    o_BxCounterValue <= regoutBx;
    o_ByCounterValue <= regoutBy;
    
    o_LoadNewRow <=  '1' when to_integer(BxValue)=Bx-1 else '0'; 
    o_EndOfPatches <='1' when (PatchAdr = By*Bx-1) else '0'; 

end rtl;

