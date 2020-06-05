library ieee;
use ieee.std_logic_1164.all;

entity pong_image_gen is
		generic (
			V_HIGH: natural);
		port (
			clk_vga, Vactive, dena, Hsync: in std_logic;
			R, G, B: out std_logic_vector(3 downto 0));
end entity;


	
architecture structural of pong_image_gen is	
begin
	
	-- Image creation
	process(all)
		variable line_count: natural range 0 to V_HIGH;
	begin
		if rising_edge(Hsync) then
			if Vactive then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		if dena then
			R <= (others => '0');
			G <= (others => '1');
			B <= (others => '0');
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;
	end process;
	
end architecture;