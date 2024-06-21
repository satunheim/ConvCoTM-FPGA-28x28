library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;  
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;  
use work.FF.all;

entity Model_pretrained is 
    Port ( 
            i_clk                : in STD_LOGIC; 
            i_rst                : in STD_LOGIC; 
            i_EnModelLoad        : in std_logic;
            i_EnRAM_ModelLoad    : in std_logic;
            i_clauseAddress      : in std_logic_vector(NBitsClauseAddr-1 downto 0);

            --
            o_update             : out std_logic_vector(NClauses-1 downto 0);
            o_Model_IEbits       : out std_logic_vector(2*FSize-1 downto 0);
            o_ModelWeightClass0  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass1  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass2  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass3  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass4  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass5  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass6  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass7  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass8  : out std_logic_vector(NBitsIW-1 downto 0);
            o_ModelWeightClass9  : out std_logic_vector(NBitsIW-1 downto 0)
            );    
end Model_pretrained; 

architecture behavioral of Model_pretrained is 

   -- The "behavioral" architecture is intended as a placeholder for future implementation of a load/write model function.

   signal w_Model_IEbits       : std_logic_vector(2*FSize-1 downto 0);
   
   signal w_ModelWeightClass0  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass1  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass2  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass3  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass4  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass5  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass6  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass7  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass8  : std_logic_vector(NBitsIW-1 downto 0);
   signal w_ModelWeightClass9  : std_logic_vector(NBitsIW-1 downto 0);   

begin

   w_Model_IEbits       <= (0 => '1', others =>'0');
   
   w_ModelWeightClass0  <= (0 => '1', others =>'0');
   w_ModelWeightClass1  <= (0 => '1', others =>'0');
   w_ModelWeightClass2  <= (0 => '1', others =>'0');
   w_ModelWeightClass3  <= (0 => '1', others =>'0');
   w_ModelWeightClass4  <= (0 => '1', others =>'0');
   w_ModelWeightClass5  <= (0 => '1', others =>'0');
   w_ModelWeightClass6  <= (0 => '1', others =>'0');
   w_ModelWeightClass7  <= (0 => '1', others =>'0');
   w_ModelWeightClass8  <= (0 => '1', others =>'0');
   w_ModelWeightClass9  <= (0 => '1', others =>'0');

    o_Model_IEbits <= w_Model_IEbits;
    
    o_ModelWeightClass0 <= w_ModelWeightClass0;
    o_ModelWeightClass1 <= w_ModelWeightClass1;
    o_ModelWeightClass2 <= w_ModelWeightClass2;
    o_ModelWeightClass3 <= w_ModelWeightClass3;
    o_ModelWeightClass4 <= w_ModelWeightClass4;
    o_ModelWeightClass5 <= w_ModelWeightClass5;
    o_ModelWeightClass6 <= w_ModelWeightClass6;
    o_ModelWeightClass7 <= w_ModelWeightClass7;
    o_ModelWeightClass8 <= w_ModelWeightClass8;
    o_ModelWeightClass9 <= w_ModelWeightClass9;

end behavioral; 
