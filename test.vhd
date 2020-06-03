library ieee;
use ieee.std_logic_1164.all;

entity test is

	generic (
		H_LOW: natural := 96;
		HBP: natural := 48;
		H_HIGH: natural := 640;
		HFP: natural := 16;
		V_LOW: natural := 2;
		VBP: natural := 33;
		V_HIGH: natural := 480;
		VFP: natural := 10);
		
	port (
		clk: in std_logic; -- 50MHz system clock
		R_switch, G_switch, B_switch: in std_logic;
		Hsync, Vsync: out std_logic;
		R, G, B: out std_logic_vector(3 downto 0));
		
end entity;

architecture rtl of test is
	signal Hactive, Vactive, dena, clk_vga, Hsync_mirror: std_logic;
begin
	
	Hsync <= Hsync_mirror;
	
	-- Create VGA clock
	process(clk)
	begin
		if rising_edge(clk) then
			clk_vga <= not clk_vga;
		end if;
	end process;
	
	-- Create control signals
	process(clk_vga)
		variable Hcount: natural range 0 to H_LOW + HBP + H_HIGH + HFP;
	begin
		if rising_edge(clk_vga) then
			Hcount := Hcount + 1;
			if Hcount = H_LOW then
				Hsync_mirror <= '1';
			elsif Hcount = H_LOW + HBP then
				Hactive <= '1';
			elsif Hcount = H_LOW + HBP + H_HIGH then
				Hactive <= '0';
			elsif Hcount = H_LOW + HBP + H_HIGH + HFP then
				Hsync_mirror <= '0';
				Hcount := 0;
			end if;
		end if;
	end process;
	
	process(Hsync_mirror)
		variable Vcount: natural range 0 to V_LOW + VBP + V_HIGH + VFP;
	begin
		if rising_edge(Hsync_mirror) then
			Vcount := Vcount + 1;
			if Vcount = V_LOW then
				Vsync <= '1';
			elsif Vcount = V_LOW + VBP then
				Vactive <= '1';
			elsif Vcount = V_LOW + VBP + V_HIGH then
				Vactive <= '0';
			elsif Vcount = V_LOW + VBP + V_HIGH + VFP then
				Vsync <= '0';
				Vcount := 0;
			end if;
		end if;
	end process;
	
	dena <= Hactive and Vactive;
	
	-- Image creation
	process(all)
		variable line_count: natural range 0 to V_HIGH;
	begin
		if rising_edge(Hsync_mirror) then
			if Vactive then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		if dena then
			R <= (others => '1');
			G <= (others => '0');
			B <= (others => '0');
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;
	end process;
	
end architecture;
			
				
					
	
	
			
			
	