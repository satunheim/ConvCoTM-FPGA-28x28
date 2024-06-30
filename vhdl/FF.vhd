-- Copyright (C) Tor M. Aamodt, UBC
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- Ensure your CAD synthesis tool/compiler is configured for VHDL-2008.

/*******************************************************************************
Copyright (c) 2012, Stanford University
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
  must display the following acknowledgement:
  This product includes software developed at Stanford University.
4. Neither the name of Stanford Univerity nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY STANFORD UNIVERSITY ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

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

                   