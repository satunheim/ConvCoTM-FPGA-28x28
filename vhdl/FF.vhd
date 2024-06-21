library ieee;
package ff is
            use ieee.std_logic_1164.all;
            component vDFF is -- multi-bit D flip-flop
                        generic( n: integer := 1); -- width
                        port( clk: in std_logic;
                                    D: in std_logic_vector( n-1 downto 0);
                                    Q: out std_logic_vector( n-1 downto 0));
            end component;

            component sDFF is -- single-bit D flip-flop
                        port( clk, D: in std_logic;
                              Q: out std_logic);
            end component;


            component vDFFce is -- multi-bit D flip-flop with clock enable
                        generic( n: integer := 1); -- width
                        port( clk, clk_en : in std_logic;
                                    D: in std_logic_vector( n-1 downto 0);
                                    Q: out std_logic_vector( n-1 downto 0));
            end component;


            component sDFFce is -- single-bit D flip-flop
                        port( clk, clk_en, D: in std_logic;
                              Q: out std_logic);
            end component;

end package;

--------
library ieee;
use ieee.std_logic_1164.all;
 
entity vDFF is
	generic( n: integer := 1); 
	port( clk: in std_logic; 
	D: in std_logic_vector( n-1 downto 0);
        Q: out std_logic_vector( n-1 downto 0));
end vDFF;
 
architecture impl of vDFF is
	begin
            process(clk) begin
                        if rising_edge(clk) then
                                    Q <= D;
                        end if;
            end process;
end impl;


----
library ieee;
use ieee.std_logic_1164.all; 
  
entity vDFFce is
	generic( n: integer := 1); 
	port(  clk, clk_en : in std_logic; 
	       D: in std_logic_vector( n-1 downto 0);
           Q: out std_logic_vector( n-1 downto 0));
end vDFFce;
  
architecture impl of vDFFce is
	begin
        process(clk) 
            begin
               if rising_edge(clk) then 
                    if (clk_en = '1') then Q <= D;
                    end if; 
                end if;
         end process;
end impl;

----
library ieee;
use ieee.std_logic_1164.all;

entity sDFF is
	port( clk, D : in std_logic;        
              Q: out std_logic);
end sDFF;
 
architecture impl of sDFF is
	begin
            process(clk) begin
                        if rising_edge(clk) then
                                    Q <= D;
                        end if;
            end process;
end impl;    

----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity sDFFce is
	port( clk, clk_en, D : in std_logic;        
              Q: out std_logic);
end sDFFce;
 
architecture impl of sDFFce is
	begin
process(clk) 
            begin
               if rising_edge(clk) then 
                    if (clk_en = '1') then Q <= D;
                    end if; 
                end if;
         end process;
end impl; 

                   