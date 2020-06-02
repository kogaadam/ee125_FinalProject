library ieee;
use ieee.std_logic_1164.all;

entity vga_pong is
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
		clk_vga: out std_logic;
		R_switch, G_switch, B_switch: in std_logic;
		Hsync, Vsync: out std_logic;
		R, G, B: out std_logic_vector(3 downto 0);
		BLANKn, SYNCn: out std_logic);
end entity;

architecture structural of vga_pong is
	signal Hactive, Vactive, dena: std_logic;
	signal Hsync_sig, Vsync_sig: std_logic;

	component pong_control_gen is
		--generic(
			--H_LOW: natural;
			--HBP: natural;
			--H_HIGH: natural;
			--HFP: natural;
			--V_LOW: natural;
			--VBP: natural;
			--V_HIGH: natural;
			--VFP: natural);
		port (
			sys_clk: in std_logic;
			vga_clk: out std_logic;
			h_active, v_active, d_ena: out std_logic;
			h_sync, v_sync: out std_logic;
			blank_n, sync_n: out std_logic);
	end component;
	
	component pong_image_gen is
		--generic(
			--H_HIGH: natural;
			--V_HIGH: natural);
		port (
			h_sync, v_sync: in std_logic;
			h_active, v_active, d_ena: in std_logic;
			r_switch, g_switch, b_switch: in std_logic;
			r, g, b: out std_logic_vector(3 downto 0));
	end component;
	
begin

	control_gen: pong_control_gen
		--generic map (H_LOW, HBP, H_HIGH, HFP, V_LOW, VBP, V_HIGH, VFP)
		port map (clk, clk_vga, Hactive, Vactive, dena, Hsync, Vsync, BLANKn, SYNCn);
	
	image_gen: pong_image_gen
		--generic map (H_HIGH, V_HIGH)
		port map (Hsync_sig, Vsync_sig, Hactive, Vactive, dena, R_switch, G_switch, B_switch, R, G, B);

end architecture;