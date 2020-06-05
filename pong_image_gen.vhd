library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.subprograms_pkg.all;
Library lpm;
use lpm.lpm_components.all;

entity pong_image_gen is
		generic (
			H_HIGH: natural;  --active horizontal display interval
			V_HIGH: natural); --active vertical display interval
		port (
			clk_vga, 				--clock to determine how often to update pixel values
			rst,						--reset game state
			Hactive, Vactive, 	--horizontal and vertical active display intervals
			dena, 					--enable RGB output
			Hsync: in std_logic;	--determines when a new line should start
			left_button, right_button: in std_logic;    --buttons to control bar movement
			ssd2, ssd1, ssd0: out std_logic_vector;     --SSDs to display score
			R, G, B: out std_logic_vector(3 downto 0)); --RGB pixel output values
end entity;

	
architecture structural of pong_image_gen is

	constant INIT_SPEED: natural := 250000;
	constant INIT_RECT_CENTER: natural := 320;
	constant INIT_BALL_Y_CENTER: natural := 435;
	constant RECT_Y_CENTER: natural := 450;
	constant RECT_HEIGHT: natural := 20;
	constant RECT_WIDTH: natural := 80;
	constant UP_LEFT: natural := 135;
	constant UP_RIGHT: natural := 45;
	constant DOWN_LEFT: natural := 225;
	constant DOWN_RIGHT: natural := 315;
	constant SPEED_CHANGE: natural := 5000; --how much to increase the speed by
	constant BALL_WIDTH: natural := 5; --technically the ball radius but distance to
												  --    object for which a collision is determined
	constant BAR_COLLISION_OFFSET: natural := 46; --number of pixels on either side of the
																 --    bar center for which a collision
																 --    is allowed
	constant TOP_GAME_OVER_IMAGE: natural := 140; --top of game over image
	constant GAME_OVER_IMAGE_PIXELS: natural := 128000; --number of pixels in the game over
																		 --    image
	constant ADDR_WIDTH: natural := 17; --width of image file line addresses
	constant INTENSITY_WIDTH: natural := 4; --width of pixel values in image file

	signal rect_clock_sig, 		  --mirror signal for how often user input is
										  --    dealt with
			 game_over: std_logic; --flag to indicate the user lost
	signal rect_center: natural := INIT_RECT_CENTER;     --center coordinate of bar
	signal ball_center_x: natural := INIT_RECT_CENTER;   --center x coordinate of ball
	signal ball_center_y: natural := INIT_BALL_Y_CENTER; --center y coordinate of ball
	signal angle: natural := UP_RIGHT;   --angle for ball direction
	signal speed: natural := INIT_SPEED; --speed of ball (clock counter value, so the
													 --    smaller this value the faster the speed)
	signal score: natural := 0;			 --user score for number of times they hit the
													 --    ball back

	-- address for data value in image file
	signal address: std_logic_vector(ADDR_WIDTH-1 downto 0);
	-- intensity (pixel value) for data value in image file
	signal intensity: std_logic_vector(INTENSITY_WIDTH-1 downto 0);
begin

	-- Instantiate the ROM - this is accessing the memory within the FPGA device itself
	myrom: lpm_rom
		generic map (
			lpm_widthad => ADDR_WIDTH, --address width
			lpm_outdata => "UNREGISTERED",
			lpm_address_control => "REGISTERED",
			lpm_file => "game_over.mif", --data file
			lpm_width => INTENSITY_WIDTH) --data width
		port map (
			-- Get the pixel intensity using its corresponding address
			inclock=>NOT clk_vga, address=>address, q=>intensity);

	process(clk_vga)
		-- speed counter to create clock that updates object movement
		variable counter: natural;
		-- clock for updating object movement
		variable rect_clock: std_logic;
	begin
		if rising_edge(clk_vga) then
			counter := counter + 1;
			if counter = speed then
				counter := 0;
				rect_clock := not rect_clock;
			end if;
		end if;
		rect_clock_sig <= rect_clock;
	end process;
	
	-- Coordinate update process
	--     - Deals with game reset
	--		 - Moves the bar based on user left/right input, wraps bar around
	--		   it is moved past the edges
	--		 - Moves the ball
	-- 	 - Deals with ball collisions with the bar and the walls
	--		 - Deals with the user losing the game
	process(rect_clock_sig, rst)
	begin
		-- Reset game values and bar/ball coordinates
		if not rst then
			rect_center <= INIT_RECT_CENTER;
			ball_center_x <= INIT_RECT_CENTER;
			ball_center_y <= INIT_BALL_Y_CENTER;
			angle <= UP_RIGHT;
			speed <= INIT_SPEED;
			score <= 0;
			game_over <= '0';
	
		elsif rising_edge(rect_clock_sig) then
			
			-- Depending on which left/right button is pressed, the bar is moved in
			--     that direction. If the bar moves until its center is at the wall,
			--     then its position gets wrapped to the other side
			-- User presses the left button (active low)
			if not left_button and right_button then
				if rect_center = 0 then
					rect_center <= H_HIGH;
				else
					rect_center <= rect_center - BALL_WIDTH;
				end if;
			-- User presses the right button (active low)
			elsif not right_button and left_button then
				if rect_center = H_HIGH then
					rect_center <= 0;
				else
					rect_center <= rect_center + BALL_WIDTH;
				end if;
			end if;
			
			-- Change the ball angle appropriately depending on the direction the
			--     ball is going and which wall it hits
			-- If moving up and to the right
			if angle >= 0 and angle < 90 then
				-- Ball hits the right wall
				if ball_center_x = H_HIGH - BALL_WIDTH then
					angle <= UP_LEFT;
				-- Ball hits the top wall
				elsif ball_center_y = BALL_WIDTH then
					angle <= DOWN_RIGHT;
				else
					ball_center_x <= ball_center_x + BALL_WIDTH;
					ball_center_y <= ball_center_y - BALL_WIDTH;
				end if;
			-- If moving up and to the left
			elsif angle >= 90 and angle < 180 then
				-- Ball hits the left wall
				if ball_center_x = BALL_WIDTH then
					angle <= UP_RIGHT;
				-- Ball hits the top wall
				elsif ball_center_y = BALL_WIDTH then
					angle <= DOWN_LEFT;
				else
					ball_center_x <= ball_center_x - BALL_WIDTH;
					ball_center_y <= ball_center_y - BALL_WIDTH;
				end if;
			-- If moving down and to the left
			elsif angle >= 180 and angle < 270 then
				-- Ball hits the left wall
				if ball_center_x = BALL_WIDTH then
					angle <= DOWN_RIGHT;
				-- Ball hits the bar
				elsif ball_center_y = INIT_BALL_Y_CENTER and
						ball_center_x > rect_center - BAR_COLLISION_OFFSET and 
						ball_center_x < rect_center + BAR_COLLISION_OFFSET then
					angle <= UP_LEFT;
					speed <= speed - SPEED_CHANGE; -- speed is increased
					score <= score + 1; -- user score is incremented
				-- Ball misses the bar - game over
				elsif ball_center_y > INIT_BALL_Y_CENTER then
					game_over <= '1';
				else
					ball_center_x <= ball_center_x - BALL_WIDTH;
					ball_center_y <= ball_center_y + BALL_WIDTH;
				end if;
			-- If moving down and to the right
			else
				-- Ball hits the right wall
				if ball_center_x = H_HIGH - BALL_WIDTH then
					angle <= DOWN_LEFT;
				-- Ball hits the bar
				elsif ball_center_y = INIT_BALL_Y_CENTER and
						ball_center_x > rect_center - BAR_COLLISION_OFFSET and 
						ball_center_x < rect_center + BAR_COLLISION_OFFSET then
					angle <= UP_RIGHT;
					speed <= speed - SPEED_CHANGE; -- speed is increased
					score <= score + 1; -- user score is incremented
				-- Ball misses the bar - game over
				elsif ball_center_y > INIT_BALL_Y_CENTER then
					game_over <= '1';
				else
					ball_center_x <= ball_center_x + BALL_WIDTH;
					ball_center_y <= ball_center_y + BALL_WIDTH;
				end if;
			end if;	
		end if;
	end process;
	
	-- Update the SSDs with the user's score
	-- Calculate the correct SSD values for the hundreds, tens, and ones digits
	process(score)
		variable hund, tens, ones: natural;
	begin
		hund := score / 100;
		tens := (score - (100 * hund)) / 10;
		ones := (score - (100 * hund) - (10 * tens));
		ssd2 <= slv_to_ssd(std_logic_vector(to_unsigned(hund, 4)));
		ssd1 <= slv_to_ssd(std_logic_vector(to_unsigned(tens, 4)));
		ssd0 <= slv_to_ssd(std_logic_vector(to_unsigned(ones, 4)));
	end process;
	
	-- Image creation
	--     - Updates the line and column counts
	--		 - Draws the ball and bar
	--		 - Draws the game over image if game over
	process(all)
		variable line_count: natural range 0 to V_HIGH; -- current row being updated
		variable col_count: natural range 0 to H_HIGH;  -- current column being updated
		variable mif_count: natural; -- current pixel being updated
											  -- (used to count through each pixel value in the MIF
											  -- image file)
	begin
		
		-- Update the line count (which row we are on)
		if rising_edge(Hsync) then
			if Vactive then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		
		-- Update the column count
		if rising_edge(clk_vga) then
			if Hactive then
				col_count := col_count + 1;
			else
				col_count := 0;
			end if;
		end if;
		
		-- Game isn't over and display is enabled, so display the objects
		if dena and not game_over then
		
			-- Draw the ball
			if line_count > ball_center_y - BALL_WIDTH and 
				line_count < ball_center_y + BALL_WIDTH and
				col_count = ball_center_x then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
			elsif line_count = ball_center_y and
					col_count > ball_center_x - BALL_WIDTH and 
					col_count < ball_center_x + BALL_WIDTH then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
					
			-- Draw the rectangle
			elsif line_count > RECT_Y_CENTER - RECT_HEIGHT/2 and 
					line_count < RECT_Y_CENTER + RECT_HEIGHT/2 and
					col_count > rect_center - RECT_WIDTH/2 and 
					col_count < rect_center + RECT_WIDTH/2 then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;

		-- Display is enabled and game is over so draw the game over image
		elsif dena and game_over then
			-- Set the appropriate address for the pixel location in the image file
			-- The image we are displaying is shifted vertically to the middle of the screen
			if line_count = TOP_GAME_OVER_IMAGE then
				mif_count := col_count;
			elsif line_count < TOP_GAME_OVER_IMAGE then
				mif_count := GAME_OVER_IMAGE_PIXELS; -- Set an out of bounds value so nothing
																 -- will be displayed
			else
				mif_count := ((line_count - TOP_GAME_OVER_IMAGE) * H_HIGH) + col_count;
			end if;
			
			-- If we are in the area we want to display the image then set the address for
			--     where we want to find the pixel intensity in the image file
			if mif_count < GAME_OVER_IMAGE_PIXELS then
				address <= std_logic_vector(to_unsigned(mif_count,ADDR_WIDTH));
				R <= intensity(3 downto 0);
				G <= (others => '0');
				B <= (others => '0');
			-- If not in that area display black
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;
	
		-- Display black when the display is not enabled
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;
		
	end process;
end architecture;