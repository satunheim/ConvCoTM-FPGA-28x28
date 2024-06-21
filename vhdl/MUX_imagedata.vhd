library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all; 
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
  
entity MUX_imagedata is      
    port (  
        i_select             : in std_logic;
        
        i_ImagevectorRow0A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow1A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow2A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow3A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow4A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow5A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow6A   : in std_logic_vector(ImageSize-1 downto 0);  
        i_ImagevectorRow7A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow8A   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow9A   : in std_logic_vector(ImageSize-1 downto 0);  
        i_ImagevectorRow10A  : in std_logic_vector(ImageSize-1 downto 0);  -- The 11th row. 
        i_ImageLabelA        : in std_logic_vector(3 downto 0);
        
        i_ImagevectorRow0B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow1B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow2B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow3B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow4B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow5B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow6B   : in std_logic_vector(ImageSize-1 downto 0);  
        i_ImagevectorRow7B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow8B   : in std_logic_vector(ImageSize-1 downto 0); 
        i_ImagevectorRow9B   : in std_logic_vector(ImageSize-1 downto 0);  
        i_ImagevectorRow10B  : in std_logic_vector(ImageSize-1 downto 0);  -- The 11th row. 
        i_ImageLabelB        : in std_logic_vector(3 downto 0);    
        
        o_ImagevectorRow0   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow1   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow2   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow3   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow4   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow5   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow6   : out std_logic_vector(ImageSize-1 downto 0);  
        o_ImagevectorRow7   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow8   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow9   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow10  : out std_logic_vector(ImageSize-1 downto 0);  -- The 11th row. Controlled by i_ByCounterValue.
        o_ImageLabel        : out std_logic_vector(3 downto 0)     
          
        );    
                                
end MUX_imagedata;

architecture rtl of MUX_imagedata is

begin
 
    o_ImagevectorRow0 <= i_ImagevectorRow0A when i_select='0' else i_ImagevectorRow0B;
    o_ImagevectorRow1 <= i_ImagevectorRow1A when i_select='0' else i_ImagevectorRow1B;
    o_ImagevectorRow2 <= i_ImagevectorRow2A when i_select='0' else i_ImagevectorRow2B;
    o_ImagevectorRow3 <= i_ImagevectorRow3A when i_select='0' else i_ImagevectorRow3B;
    o_ImagevectorRow4 <= i_ImagevectorRow4A when i_select='0' else i_ImagevectorRow4B;
    o_ImagevectorRow5 <= i_ImagevectorRow5A when i_select='0' else i_ImagevectorRow5B;
    o_ImagevectorRow6 <= i_ImagevectorRow6A when i_select='0' else i_ImagevectorRow6B;
    o_ImagevectorRow7 <= i_ImagevectorRow7A when i_select='0' else i_ImagevectorRow7B;
    o_ImagevectorRow8 <= i_ImagevectorRow8A when i_select='0' else i_ImagevectorRow8B;
    o_ImagevectorRow9 <= i_ImagevectorRow9A when i_select='0' else i_ImagevectorRow9B; 
    o_ImagevectorRow10 <= i_ImagevectorRow10A when i_select='0' else i_ImagevectorRow10B;    
    o_ImageLabel <= i_ImageLabelA when i_select='0' else i_ImageLabelB;   
                                              
end rtl;

