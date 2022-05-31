module traffic_light(seg, SEL, mul_out, sec_10, sec_1, dir, led, clk, rst);

	input clk, rst;
	// sec_10: 十位數；sec_1: 個位數
	output SEL, mul_out, sec_10, sec_1, dir, led;
	output [7:0] seg;
	reg [2:0] SEL; // 七段顯示器的COM選擇腳位
	reg [3:0] mul_out;
	reg [1:0] sec_10;
	reg [3:0] sec_1, dir;	
	reg [11:0] led;
	
	reg [7:0] cnt; // counter for frequency divider		
	reg count; // 當除頻器觸發後，counter++
	
	reg switch; // 用來在兩個紅綠燈之間切換	

	always @ (posedge clk or negedge rst) begin	// 除頻器
		if (!rst) begin		
			cnt <= 0;
			SEL <= 0;			
		end
		else begin		
			if (cnt == 150) begin	// 每過150個cycle，秒數(count)加一
				cnt <= 0;
				count <= 1;
			end
			else begin			
				cnt <= cnt + 1;
				count <= 0;
			end
			
			if (SEL == 7) // 每個cycle切換到不同七段顯示器
				SEL <= 0;
			else
				SEL <= SEL + 1;
				
			if (SEL == 1 || SEL == 5) // 顯示十位數
				mul_out <= sec_10;
			else if (SEL == 0 || SEL == 4) // 顯示個位數
				mul_out <= sec_1;
			else
				mul_out <= dir; // 顯示方向
				
			if ((sec_10 == 4'b0000) && (sec_1 < 4'b0011)) // 少於0分2秒時，顯示黃燈
				if (switch == 0) // 兩個紅綠燈互相切換
					led <= 12'b010111111100;
				else // 兩個紅綠燈互相切換
					led <= 12'b100111111010;
			else
				if (switch == 0) // 兩個紅綠燈互相切換
					led <= 12'b001111111100;
				else // 兩個紅綠燈互相切換
					led <= 12'b100111111001;
		end
	end 
			
	always @ (posedge count) begin	
		if (sec_1 == 4'b0000) begin		
			sec_1 <= 9;
			if (sec_10 == 4'b0000) begin			
				sec_10 <= 1;
				
				// 當紅綠燈倒數完，互相交換
				switch <= switch + 1; 
				if (dir == 10) // 10和11用來顯示方向
					dir <= 11;
				else
					dir <= 10;
			end
			else
				sec_10 <= 0;
		end
		else begin
			sec_1 <= sec_1 - 1;
		end
	end

	assign seg = (mul_out == 4'b0000) ? 8'b11111100:
					 (mul_out == 4'b0001) ? 8'b01100000:
					 (mul_out == 4'b0010) ? 8'b11011010:
					 (mul_out == 4'b0011) ? 8'b11110010:
					 (mul_out == 4'b0100) ? 8'b01100110:
					 (mul_out == 4'b0101) ? 8'b10110110:
					 (mul_out == 4'b0110) ? 8'b10111110:
					 (mul_out == 4'b0111) ? 8'b11100000:
					 (mul_out == 4'b1000) ? 8'b11111110:
					 (mul_out == 4'b1001) ? 8'b11110110:
					 (mul_out == 4'b1010) ? 8'b00010010:
					 (mul_out == 4'b1011) ? 8'b00101000:
					                        8'b10011110;
endmodule
