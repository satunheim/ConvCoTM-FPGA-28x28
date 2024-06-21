library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all; 
use work.FF.all; 
use work.SETTINGS_ConvCoTM.all;      
   
entity counter_eval is    
    Port ( i_clk                    : in STD_LOGIC; 
           i_rst                    : in STD_LOGIC; 
           i_en                     : in STD_LOGIC; 
           i_learn                  : in STD_LOGIC; 
           o_enable_adders          : out STD_LOGIC;
           o_sample_actual_class    : out std_logic;
           o_sample_predicted_class : out std_logic
           );
end counter_eval;


architecture rtl of counter_eval is

    constant Ecounterbits: Integer := 5;	

    signal w_nxtE               : std_logic_vector(Ecounterbits-1 downto 0); 
    signal w_regoutE            : std_logic_vector(Ecounterbits-1 downto 0); 
    
    signal w_valueE             : unsigned(Ecounterbits-1 downto 0);
    signal w_incrementE         : unsigned(Ecounterbits-1 downto 0);
    signal w_valueEincremented  : unsigned(Ecounterbits-1 downto 0);

    signal w_CountT1            : std_logic_vector(Ecounterbits-1 downto 0); 
    signal w_CountT2            : std_logic_vector(Ecounterbits-1 downto 0); 
    signal w_CountT3            : std_logic_vector(Ecounterbits-1 downto 0); 
    signal w_CountT4            : std_logic_vector(Ecounterbits-1 downto 0); 
    
    signal w_us_CountT2         : unsigned(Ecounterbits-1 downto 0);
    signal w_us_CountT4         : unsigned(Ecounterbits-1 downto 0);

begin
    
    EvalCounter: vDFF generic map(Ecounterbits) port map(i_clk, w_nxtE, w_regoutE);
    
    w_valueE<=unsigned(w_regoutE);
    w_incrementE <= (0 => '1', others => '0');
    w_valueEincremented <= w_valueE + w_incrementE;
            
    w_nxtE <=  (others=>'0') when i_rst='1' 
                             else std_logic_vector(w_valueEincremented);

    w_CountT1 <= std_logic_vector(to_unsigned(0, w_CountT1'length)); 
    
    w_us_CountT2 <= to_unsigned(c_AdderPipelineStages, w_us_CountT2'length); 
    w_CountT2 <= std_logic_vector(w_us_CountT2);      
    
    w_CountT3 <= std_logic_vector(to_unsigned(0, w_CountT3'length));  
    
    w_us_CountT4 <= to_unsigned(c_AdderPipelineStages+0, w_us_CountT4'length); 
                                                                             
    w_CountT4 <= std_logic_vector(w_us_CountT4);  
    
    o_enable_adders          <= '1' when w_valueE <= w_us_CountT2 and i_en='1' and i_learn='0'
                                else '1' when w_valueE <= w_us_CountT4 and i_en='1' and i_learn='1'
                                else '0';
    
    o_sample_actual_class    <= '1' when w_regoutE=w_CountT1 and i_en='1' and i_learn='0' 
                                else '1' when w_regoutE=w_CountT3 and i_en='1' and i_learn='1' 
                                else '0';
    
    o_sample_predicted_class <= '1' when w_regoutE=w_CountT2 and i_en='1' and i_learn='0' 
                                else '1' when w_regoutE=w_CountT4 and i_en='1' and i_learn='1' 
                                else '0';

end rtl;
