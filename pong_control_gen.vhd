library ieee;
use ieee.std_logic_1164.all;

entity pong_control_gen is
	generic(
		H_LOW: natural;
		HBP: natural;
		H_HIGH: natural;
		HFP: natural;
		V_LOW: natural;
		VBP: natural;
		V_HIGH: natural;
		VFP: natural);
	port (
		sys_clk: in std_logic;
		h_active, v_active, d_ena: out std_logic;
		h_sync, v_sync: out std_logic);
end entity;

architecture structural of pong_control_gen is
	signal clk_vga, Hsync_sig, Vsync_sig: std_logic;
begin
	
	-- Create VGA clock (50MHz -> 25 MHz)
	process (sys_clk)
	begin
		if rising_edge(sys_clk) then
			clk_vga <= not clk_vga;
		end if;
	end process;
	
	-- Create horizontal signals
	process(clk_vga)
		variable Hcount: natural range 0 to H_LOW + HBP + H_HIGH + HFP;
	begin
		if rising_edge(clk_vga) then
			Hcount := Hcount + 1;
			if Hcount = H_LOW then
				Hsync_sig <= '1';
			elsif Hcount = H_LOW + HBP then
				h_active <= '1';
			elsif Hcount = H_LOW + HBP + H_HIGH then
				h_active <= '0';
			elsif Hcount = H_LOW + HBP + H_HIGH + HFP then
				Hsync_sig <= '0';
				Hcount := 0;
			end if;
		end if;
	end process;

	-- Create horizontal signals
	process(Hsync_sig)
		variable Vcount: natural range 0 to V_LOW + VBP + V_HIGH + VFP;
	begin
		if rising_edge(Hsync_sig) then
			Vcount := Vcount + 1;
			if Vcount = V_LOW then
				Vsync_sig <= '1';
			elsif Vcount = V_LOW + VBP then
				v_active <= '1';
			elsif Vcount = V_LOW + VBP + V_HIGH then
				v_active <= '0';
			elsif Vcount = V_LOW + VBP + V_HIGH + VFP then
				Vsync_sig <= '0';
				Vcount := 0;
			end if;
		end if;
	end process;
	
	-- Enable display
	d_ena <= h_active and v_active;
	h_sync <= Hsync_sig;
	v_sync <= Vsync_sig;
	
end architecture;