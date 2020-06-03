library ieee;
use ieee.std_logic_1164.all;

entity pong_top_level is

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
		clk: in std_logic;
		Hsync, Vsync: out std_logic;
		R, G, B: out std_logic_vector(3 downto 0));
		
end entity;

architecture structural of pong_top_level is
	
	-- intermediates
	signal clk_vga, dena, Hactive, Vactive, Hsync_mirror: std_logic;
	
	-- control component declaration
	component pong_control_gen is
		generic (
			H_LOW: natural;
			HBP: natural;
			H_HIGH: natural;
			HFP: natural;
			V_LOW: natural;
			VBP: natural;
			V_HIGH: natural;
			VFP: natural);
		port (
			clk: in std_logic;
			clk_vga, Hsync, Vsync, dena, Hactive, Vactive: out std_logic);
	end component;
	
	-- image gen component declaration
	component pong_image_gen is
		generic (
			V_HIGH: natural);
		port (
			clk_vga, Vactive, dena, Hsync: in std_logic;
			R, G, B: out std_logic_vector(3 downto 0));
	end component;
			
begin
	
	-- control component instantiation
	control_gen: pong_control_gen
		generic map (H_LOW, HBP, H_HIGH, HFP, V_LOW, VBP, V_HIGH, VFP)
		port map (clk, clk_vga, Hsync, Vsync, dena, Hactive, Vactive);
	
	Hsync_mirror <= Hsync;
	
	-- image gen component instantiation
	image_gen: pong_image_gen
		generic map (V_HIGH)
		port map (clk_vga, Vactive, dena, Hsync_mirror, R, G, B);
	
end architecture;