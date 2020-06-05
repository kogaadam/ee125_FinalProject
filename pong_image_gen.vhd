library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library lpm;
use lpm.lpm_components.all;

entity pong_image_gen is
		generic (
			H_HIGH: natural;
			V_HIGH: natural);
		port (
			clk_vga, rst, Hactive, Vactive, dena, Hsync: in std_logic;
			left_button, right_button: in std_logic;
			R, G, B: out std_logic_vector(3 downto 0));
end entity;

	
architecture structural of pong_image_gen is

	signal rect_clock_sig, game_over: std_logic;
	signal rect_center: natural := 320;
	signal ball_center_x: natural := 320;
	signal ball_center_y: natural := 435;
	signal angle: natural := 45;
	signal speed: natural;
	
	signal address: std_logic_vector(16 downto 0);
	signal intensity: std_logic_vector(11 downto 0);
	
	--type type_2D is array (639 downto 0, 479 downto 0) of std_logic_vector(11 downto 0);
	--signal image_array: type_2D;

begin

	myrom: lpm_rom
		generic map (
			lpm_widthad => 17, --address width
			lpm_outdata => "UNREGISTERED",
			lpm_address_control => "REGISTERED",
			lpm_file => "game_over.mif", --data file
			lpm_width => 12) --data width
		port map (
			inclock=>NOT clk_vga, address=>address, q=>intensity);

	process(clk_vga)
		variable counter: natural;
		variable rect_clock: std_logic;
	begin
		if rising_edge(clk_vga) then
			counter := counter + 1;
			if counter = 250000 then
				counter := 0;
				rect_clock := not rect_clock;
			end if;
		end if;
		rect_clock_sig <= rect_clock;
	end process;
	
	process(rect_clock_sig, rst)
	begin
		if not rst then
			rect_center <= 320;
			ball_center_x <= 320;
			ball_center_y <= 435;
			angle <= 45;
			game_over <= '0';
	
		elsif rising_edge(rect_clock_sig) then
			
			if not left_button and right_button then
				if rect_center = 0 then
					rect_center <= H_HIGH;
				else
					rect_center <= rect_center - 5;
				end if;
			elsif not right_button and left_button then
				if rect_center = H_HIGH then
					rect_center <= 0;
				else
					rect_center <= rect_center + 5;
				end if;
			end if;
			
			if angle >= 0 and angle < 90 then
				if ball_center_x = H_HIGH - 5 then
					angle <= 135;
				elsif ball_center_y = 5 then
					angle <= 315;
				else
					ball_center_x <= ball_center_x + 5;
					ball_center_y <= ball_center_y - 5;
				end if;
			elsif angle >= 90 and angle < 180 then
				if ball_center_x = 5 then
					angle <= 45;
				elsif ball_center_y = 5 then
					angle <= 225;
				else
					ball_center_x <= ball_center_x - 5;
					ball_center_y <= ball_center_y - 5;
				end if;
			elsif angle >= 180 and angle < 270 then
				if ball_center_x = 5 then
					angle <= 315;
				elsif ball_center_y = 435 and
						ball_center_x > rect_center - 40 - 6 and ball_center_x < rect_center + 40 + 6 then
					angle <= 135;
				elsif ball_center_y > 435 then
					game_over <= '1';
				else
					ball_center_x <= ball_center_x - 5;
					ball_center_y <= ball_center_y + 5;
				end if;
			else
				if ball_center_x = H_HIGH - 5 then
					angle <= 225;
				elsif ball_center_y = 435 and
						ball_center_x > rect_center - 40 - 6 and ball_center_x < rect_center + 40 + 6 then
					angle <= 45;
				elsif ball_center_y > 435 then
					game_over <= '1';
				else
					ball_center_x <= ball_center_x + 5;
					ball_center_y <= ball_center_y + 5;
				end if;
			end if;
			
		end if;
		
	end process;
	
	-- Image creation
	process(all)
		variable line_count: natural range 0 to V_HIGH;
		variable col_count: natural range 0 to H_HIGH;
		variable mif_count: natural;
		variable rgb: std_logic_vector(11 downto 0);
	begin
				
		if rising_edge(Hsync) then
			if Vactive then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		
		if rising_edge(clk_vga) then
			if Hactive then
				col_count := col_count + 1;
			else
				col_count := 0;
			end if;
		end if;
		
		if dena and not game_over then
			-- Position of ball
			if line_count > ball_center_y - 5 and line_count < ball_center_y + 5
				and col_count = ball_center_x then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');

			elsif line_count = ball_center_y and
					col_count > ball_center_x - 5 and col_count < ball_center_x + 5 then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
					
			-- Postion of rectangle
			elsif line_count > 440 and line_count < 460 and
					col_count > rect_center - 40 and col_count < rect_center + 40 then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;

		elsif dena and game_over then
			if line_count = 140 then
				mif_count := col_count;
			elsif line_count < 140 then
				mif_count := 200000;
			else
				mif_count := ((line_count - 140) * 640) + col_count;
			end if;
			
			if mif_count < 128000 then
				address <= std_logic_vector(to_unsigned(mif_count,17));
				B <= intensity(11 downto 8);
				G <= intensity(7 downto 4);
				R <= intensity(3 downto 0);
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;
	
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;
		
	end process;
	
end architecture;