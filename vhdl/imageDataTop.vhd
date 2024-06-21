library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all; 
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
  
entity imageDataTop is      
    port (
         -- AXI INTERFACE:
         
         axi_clk            : in std_logic; 
         axi_reset_n        : in std_logic; 
         
         -- Slave interface:
         i_data_valid       : in std_logic;
         i_data             : in std_logic_vector(7 downto 0);
         o_data_ready       : out std_logic; 
         
         -- Interrupt:
         o_intr             : out std_logic; 

         -- Other signals:         
         i_image_buffer_reset   : in std_logic;
         i_start                : in std_logic;  
         i_ByCounterValue       : in std_logic_vector(4 downto 0);
         i_MainFSMstate         : in std_logic_vector(SWIDTH-1 downto 0);   
         
         --------------------------------  
         -- Output signals to PatchGenerator:
                           
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
                                
end imageDataTop;
architecture rtl of imageDataTop is 

    signal w_rst : std_logic;
    
begin
    
    w_rst <=not(axi_reset_n) or i_image_buffer_reset;
    
    Module_IMAGEDATACONTROL: entity work.imagedatacontrol(rtl)     
        port map (
            i_clk               => axi_clk,
            i_rst               => w_rst,
            i_start             => i_start,
            i_MainFSMstate      => i_MainFSMstate,
            i_ByCounterValue    => i_ByCounterValue,
                     
            i_image_data        => i_data,
            i_imagedata_valid   => i_data_valid,
            
            o_data_ready        => o_data_ready,
            
            o_ImagevectorRow0   => o_ImagevectorRow0,
            o_ImagevectorRow1   => o_ImagevectorRow1,
            o_ImagevectorRow2   => o_ImagevectorRow2,
            o_ImagevectorRow3   => o_ImagevectorRow3,
            o_ImagevectorRow4   => o_ImagevectorRow4,
            o_ImagevectorRow5   => o_ImagevectorRow5,
            o_ImagevectorRow6   => o_ImagevectorRow6, 
            o_ImagevectorRow7   => o_ImagevectorRow7,
            o_ImagevectorRow8   => o_ImagevectorRow8,
            o_ImagevectorRow9   => o_ImagevectorRow9,
            o_ImagevectorRow10  => o_ImagevectorRow10,
            o_ImageLabel        => o_ImageLabel,

            o_intr              => o_intr                      
            );   
                                              
end rtl;