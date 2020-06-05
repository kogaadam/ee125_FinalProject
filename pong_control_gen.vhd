library ieee;
use ieee.std_logic_1164.all;

entity pong_control_gen is
	generic (
		H_LOW: natural;  --time for how long Hsync is low
		HBP: natural;	  --horizontal back porch
		H_HIGH: natural; --active horizontal display interval
		HFP: natural;	  --horizontal front porch
		V_LOW: natural;  --time for long how Vsync is low
		VBP: natural;	  --vertical back porch
		V_HIGH: natural; --active vertical display interval
		VFP: natural);   --vertical front porch
	port (
		clk: in std_logic;		 --internal 50 MHz clock
		clk_vga, 					 --how often each VGA display pixel updates
		Hsync, 						 --determines when a new line should start
		Vsync, 						 --determines when a new frame should start
		dena, 						 --enable RGB output
		Hactive, 					 --indicates active horizontal display
		Vactive: out std_logic); --indicates active vertical display
end entity;


architecture structural of pong_control_gen is

	signal clk_vga_mirror: std_logic; --signal to mirror vga clock output
	signal Hsync_mirror: std_logic;	 --signal to mirror Hsync output
	
begin
	
	-- Create VGA clock
	process(clk)
	begin
		if rising_edge(clk) then
			clk_vga <= not clk_vga;
		end if;
	end process;
	
	clk_vga_mirror <= clk_vga;
	
	-- Create control signals
	process(clk_vga_mirror)
		variable Hcount: natural range 0 to H_LOW + HBP + H_HIGH + HFP;
	begin
		if rising_edge(clk_vga_mirror) then
			Hcount := Hcount + 1;
			if Hcount = H_LOW then
				Hsync <= '1';
			elsif Hcount = H_LOW + HBP then
				Hactive <= '1';
			elsif Hcount = H_LOW + HBP + H_HIGH then
				Hactive <= '0';
			elsif Hcount = H_LOW + HBP + H_HIGH + HFP then
				Hsync <= '0';
				Hcount := 0;
			end if;
		end if;
	end process;
	
	Hsync_mirror <= Hsync;
	
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
	
	dena <= Hactive and Vactive; --Only output to the screen when in both
										  --    active intervals

end architecture;
	
	