module clock_24hr(clk, rst, 
						SEL, out, 
						cnt_hr_tens, cnt_hr_digs, 
						cnt_min_tens, cnt_min_digs, 
						cnt_sec_tens, cnt_sec_digs, 
						mul_out);

	input clk, rst;
	
	output reg [2:0] SEL; // 七段顯示器的COM選擇腳位
	output reg [7:0] out; // 七段顯示器的輸出腳位
	
	// 各個位數的counter，紀錄實際上的數字。
	output reg [3:0] cnt_hr_tens, cnt_hr_digs, 
							cnt_min_tens, cnt_min_digs,
							cnt_sec_tens, cnt_sec_digs,
							mul_out;	
	// mul_out 只是方便在模擬時方便觀察output是否正確。
	
	// 用來存放decoder的output
	// (decoder將時鐘各個位數轉換為七段顯示器binary code)
	reg [7:0] hr_tens, hr_digs, 
					min_tens, min_digs, 
					sec_tens, sec_digs;	
	reg [2:0] sel; 
	// cnt為除頻器所用，每過十個cnt(clock)，則second的個位數加一。
	reg [5:0] cnt; 
	
	// 將input轉換為七段顯示器輸出腳位形式(a, b, ..., g & dp)
	function [7:0] decoder; 
		input [3:0] count;
		begin
			case (count) 
				0: decoder = 8'b11111100;
				1: decoder = 8'b01100000;
				2: decoder = 8'b11011010;
				3: decoder = 8'b11110010;
				4: decoder = 8'b01100110;			
				5: decoder = 8'b10110110;
				6: decoder = 8'b10111110;
				7: decoder = 8'b11100000;
				8: decoder = 8'b11111110;
				9: decoder = 8'b11110110;
				default: decoder = 8'b10011110; // set default to 'E'
			endcase	
		end
	endfunction 	
	
	initial begin
		cnt_hr_tens = 0;
		cnt_hr_digs = 0;
		cnt_min_tens = 0;
		cnt_min_digs = 0;
		cnt_sec_tens = 0;
		cnt_sec_digs = 0;		
		sel = 0;
		cnt = 0;
	end
		
	always @ (posedge clk, negedge rst) begin
		if (rst == 0) begin
			cnt_hr_tens = 0;
			cnt_hr_digs = 0;
			cnt_min_tens = 0;
			cnt_min_digs = 0;			
			cnt_sec_tens = 0;
			cnt_sec_digs = 0;			
			sel = 0;
			cnt = 0;
		end		
		else begin
			cnt <= cnt + 1;
			// 60_divider, cnt_sec_digs(個位數) + 1 every 60 cycle.				
			if (cnt == 59) begin  // 由於有六個七段顯示器，
				cnt <= 0;          // 因此每60個cycle再將秒數的個位數+1，
				cnt_sec_digs <= cnt_sec_digs + 1; // 可以使各個位數的顯示較明確一些。
				if (cnt_sec_digs == 9) begin
					cnt_sec_tens <= cnt_sec_tens + 1;
					cnt_sec_digs <= 0;
					if (cnt_sec_tens == 5) begin
						cnt_min_digs <= cnt_min_digs + 1;
						cnt_sec_tens <= 0;
						if (cnt_min_digs == 9) begin
							cnt_min_tens <= cnt_min_tens + 1;
							cnt_min_digs <= 0;
							if (cnt_min_tens == 5) begin
								cnt_hr_digs <= cnt_hr_digs + 1;
								cnt_min_tens <= 0;
								if (cnt_hr_tens == 2 && cnt_hr_digs == 3) begin
									cnt_hr_tens <= 0;
									cnt_hr_digs <= 0;			
								end
								else if (cnt_hr_tens != 2 && cnt_hr_digs == 9) begin
									cnt_hr_digs <= 0;								
								end							
							end
						end
					end
				end
			end			
			
			sel = sel + 1;  // 每個cycle都切換到下一位數的七段顯示器
			if(sel == 6) begin
				sel = 0;
			end			
			case (sel) 
				0: SEL = 3'b000; // 七段顯示器中second的個位數
				1: SEL = 3'b001; // second的十位數
				2: SEL = 3'b010; // minute的個位數
				3: SEL = 3'b011; // minute的十位數
				4: SEL = 3'b100; // hour的個位數
				5: SEL = 3'b101; // hour的十位數
				default: SEL = 3'b000;
			endcase
			
			// call function "decoder",
			// decode binary number to 7-segment-display bit.
			sec_digs = decoder(cnt_sec_digs);  
			sec_tens = decoder(cnt_sec_tens);  
			min_digs = decoder(cnt_min_digs);
			min_tens = decoder(cnt_min_tens);
			hr_digs = decoder(cnt_hr_digs);
			hr_tens = decoder(cnt_hr_tens);
			case (SEL) // 每個cycle都切換一次七段顯示器
				3'b000: begin
					out = sec_digs; 
					mul_out = cnt_sec_digs; 
				end
				3'b001: begin
					out = sec_tens;
					mul_out = cnt_sec_tens; 
				end
				3'b010: begin 
					out = min_digs;
					mul_out = cnt_min_digs; 
				end
				3'b011: begin 
					out = min_tens;
					mul_out = cnt_min_tens; 
				end
				3'b100: begin 
					out = hr_digs;
					mul_out = cnt_hr_digs; 
				end
				3'b101: begin
					out = hr_tens;
					mul_out = cnt_hr_tens; 
				end
				default: begin
					out = 8'b10011110; // default顯示'E'
					mul_out = 0; 
				end
			endcase
		end
	end
endmodule