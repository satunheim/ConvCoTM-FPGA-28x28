library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;      
   
entity Pcounter is    
    Port ( i_clk              : in STD_LOGIC; 
           i_rst              : in STD_LOGIC; 
           i_en               : in STD_LOGIC; 
           i_start            : in STD_LOGIC;
           i_learn            : in STD_LOGIC; 
           o_PcounterFinished : out STD_LOGIC
           );
end Pcounter;


architecture rtl of Pcounter is

    signal w_nxtP       : std_logic_vector(Pcounterbits-1 downto 0);
    signal w_regoutP    : std_logic_vector(Pcounterbits-1 downto 0);   
    signal w_valueP     : unsigned(Pcounterbits-1 downto 0);
    signal w_incrementP : unsigned(Pcounterbits-1 downto 0);
    signal w_valuePincremented : unsigned(Pcounterbits-1 downto 0);
    signal w_CountT1    : std_logic_vector(Pcounterbits-1 downto 0);

begin
    
        ModulePcounter: vDFFce generic map(Pcounterbits) port map(i_clk, i_en, w_nxtP, w_regoutP);
        
        w_valueP<=unsigned(w_regoutP);
        w_incrementP <= (0 => '1', others => '0');
        w_valuePincremented <= w_valueP + w_incrementP;
                
        w_nxtP <=  (others=>'0') when i_rst='1' or i_start='0' 
                                 else std_logic_vector(w_valuePincremented);

        w_CountT1 <= std_logic_vector(to_unsigned(Bx*By-1, w_CountT1'length));  

    
        o_PCounterFinished <= '1' when w_regoutP=w_CountT1 
                                   else '0';    

end rtl;
