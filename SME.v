`timescale 1ns/10ps
module SME ( clk, reset, case_insensitive, pattern_no, match_addr, valid, finish, T_data, T_addr, P_data, P_addr);
input         clk;
input         reset;
input         case_insensitive;
output [3:0]  pattern_no;
output [11:0] match_addr;
output        valid;
output        finish;
input  [7:0]  T_data;
output [11:0] T_addr;
input  [7:0]  P_data;
output [6:0]  P_addr;


reg [7:0]   T_data_real_r,T_data_real_w,P_data_real_r,P_data_real_w;

reg [2:0] 	state_w,state_r;
reg [7:0] 	counter_pattern_w,counter_pattern_r;
reg [3:0] 	pre_counter_last_pattern_w,pre_counter_last_pattern_r;
reg [3:0] 	counter_last_pattern_w,counter_last_pattern_r;
reg [11:0]	counter_text_w,counter_text_r;
reg [7:0] 	pattern_w[15:0],pattern_r[15:0];
reg     	flag_w[15:0],flag_r[15:0];
reg        	is_optional_w[15:0],is_optional_r[15:0];
reg [2:0]	shift_w[15:0],shift_r[15:0];
reg 		last_optional_w,last_optional_r;

reg 		finish_w,finish_r;
reg 		valid_w,valid_r;
reg [11:0]	match_addr_w,match_addr_r;
reg [3:0]  	pattern_no_w,pattern_no_r;

integer i;

assign T_addr=counter_text_r;
assign P_addr=counter_pattern_r;
assign match_addr=match_addr_r;
assign valid=valid_r;
assign pattern_no=pattern_no_r;
assign finish=finish_r;

always@(*)begin
	if (case_insensitive && T_data>=8'h41 && T_data<8'h5A)begin
		T_data_real_w=T_data+8'd32;
	end
	else begin
		T_data_real_w=T_data;
	end
	if (case_insensitive && P_data>=8'h41 && P_data<8'h5A)begin
		P_data_real_w=P_data+8'd32;
	end
	else begin
		P_data_real_w=P_data;
	end
end

always@(*)begin
	if (state_r==0)begin
		state_w=1;
	end
	else if (state_r==1 && P_data==0)begin
		state_w=2;
	end
	else if (state_r==2)begin
		state_w=3;
	end
	else if (state_r==3 && T_data==8'b00)begin
		state_w=0;
	end
	else begin
		state_w=state_r;
	end
end

always@(*)begin
	if (state_r==0 || state_r==1)begin
		counter_pattern_w=counter_pattern_r+1;
	end
	else if (state_r==2) begin
		counter_pattern_w=counter_pattern_r;
	end
	else if (state_r==3 && T_data==8'b00)begin
		counter_pattern_w=counter_pattern_r-1;
	end
	else begin
		counter_pattern_w=counter_pattern_r;
	end
end

always@(*)begin
	if (state_r==1)begin
		if (P_data==8'h3F)begin
			pre_counter_last_pattern_w=pre_counter_last_pattern_r;
		end
		else if (P_data==0)begin
			if (last_optional_r) begin
				pre_counter_last_pattern_w=pre_counter_last_pattern_r;
			end
			else begin
				pre_counter_last_pattern_w=pre_counter_last_pattern_r-1;
			end
		end 
		else begin
			pre_counter_last_pattern_w=pre_counter_last_pattern_r+1;
		end
	end
	else if (state_r==3 && T_data==8'b00)begin
		pre_counter_last_pattern_w=0;
	end
	else begin
		pre_counter_last_pattern_w=pre_counter_last_pattern_r;
	end

	counter_last_pattern_w=pre_counter_last_pattern_r;
end

always@(*)begin
	for(i=0;i<16;i=i+1)begin
		pattern_w[i]=pattern_r[i];
	end
	if (state_r==1 || state_r==2)begin 
		if (P_data_real_r==8'h5E || P_data_real_r==8'h24)begin
			pattern_w[counter_last_pattern_r]=8'h0A;
		end
		else if(P_data_real_r==8'h00)begin
			pattern_w[counter_last_pattern_r]=8'h01;
		end
		else begin
			pattern_w[counter_last_pattern_r]=P_data_real_r;
		end
		
	end
end

always@(*)begin
	for(i=0;i<16;i=i+1)begin
		is_optional_w[i]=is_optional_r[i];
	end
	if ((state_r==1 || state_r==2) && P_data_real_r==8'h3F)begin 
		is_optional_w[counter_last_pattern_r-1]=1;
	end
	else if (state_r==3 && T_data==8'b00)begin
		for(i=0;i<16;i=i+1)begin
			is_optional_w[i]=0;
		end
	end
end

always@(*)begin
	if (state_r==0)begin
		counter_text_w=0;
	end
	else if (state_r==2 || state_r==3)begin 
		counter_text_w=counter_text_r+1;
	end	
	else begin
		counter_text_w=counter_text_r;
	end
end

always@(*)begin
	if (state_r==3) begin
		
		flag_w[0]= (T_data_real_r==pattern_r[0] || (pattern_r[0]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[0]==8'h01)); //
		flag_w[1]= (T_data_real_r==pattern_r[1] || (pattern_r[1]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[1]==8'h01)) && 
																	(flag_r[0] || is_optional_r[0]);
		flag_w[2]= (T_data_real_r==pattern_r[2] || (pattern_r[2]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[2]==8'h01)) && 
																	(flag_r[1] || 
																	(is_optional_r[1] && flag_r[0]) || 
																	(is_optional_r[1] && is_optional_r[0]));  
		
		for(i=3;i<16;i=i+1)begin
			flag_w[i]= (T_data_real_r==pattern_r[i] || (pattern_r[i]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[i]==8'h01)) && 
																		(flag_r[i-1] || 
																		(is_optional_r[i-1] && flag_r[i-2]) || 
																		(is_optional_r[i-1] && is_optional_r[i-2] && flag_r[i-3]));
		end
		
	end
	else begin
		for(i=0;i<16;i=i+1)begin
			flag_w[i]=flag_r[i];
		end
	end
end

always@(*)begin
	
	if (pattern_r[0]==8'h0A)begin
		shift_w[0]=1;
	end
	else begin
		shift_w[0]=0;
	end
	
	
	if ((T_data_real_r==pattern_r[1] || (pattern_r[1]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[1]==8'h01)) && 
	(!flag_r[0] && is_optional_r[0])) begin
		shift_w[1]=0+1;
	end
	else begin
		shift_w[1]=shift_r[0];
	end
	
	if ((T_data_real_r==pattern_r[2] || (pattern_r[2]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[2]==8'h01)) && 
	(!flag_r[1] && flag_r[0] && is_optional_r[1])) begin
		shift_w[2]=shift_r[0]+1;
	end
	else if ((T_data_real_r==pattern_r[2] || (pattern_r[2]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[2]==8'h01)) && 
	(!flag_r[1] && !flag_r[0] && is_optional_r[1] && is_optional_r[0])) begin
		shift_w[2]=0+2;
	end
	else begin
		shift_w[2]=shift_r[1];
	end
	
	for(i=3;i<16;i=i+1)begin
		if ((T_data_real_r==pattern_r[i] || (pattern_r[i]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[i]==8'h01)) && 
		(!flag_r[i-1] && flag_r[i-2] && is_optional_r[i-1])) begin
			shift_w[i]=shift_r[i-2]+1;
		end
		else if ((T_data_real_r==pattern_r[i] || (pattern_r[i]==8'h2E && T_data_real_r!=8'h0A) || (pattern_r[i]==8'h01)) && 
		(!flag_r[i-1] && !flag_r[i-2] && flag_r[i-3] && is_optional_r[i-1] && is_optional_r[i-2])) begin
			shift_w[i]=shift_r[i-3]+2;
		end
		else begin
			shift_w[i]=shift_r[i-1];
		end
	end
end

always@(*)begin
	if (state_r==3 && flag_r[counter_last_pattern_r]==1)begin
		valid_w=1;
		match_addr_w = counter_text_r-counter_last_pattern_r+shift_r[counter_last_pattern_r]-3;
	end
	else begin
		match_addr_w=match_addr_r;
		valid_w=0;
	end
	
end

always@(*)begin
	if (state_r==3 && T_data==8'b00)begin
		pattern_no_w=pattern_no_r+1;
	end
	else begin
		pattern_no_w=pattern_no_r;
	end
end

always@(*)begin
	if (state_r==2 && counter_last_pattern_r==0)begin
		finish_w=1;
	end
	else begin
		finish_w=0;
	end
end

always@(*)begin
	if (P_data==8'h3F)begin
		last_optional_w=1;
	end
	else begin
		last_optional_w=0;
	end
end

/*
always@(*)begin

	
	counter_pattern_w=counter_pattern_r;
	counter_last_pattern_w=counter_last_pattern_r;
	counter_text_w=counter_text_r;
	match_addr_w=match_addr_r;
	valid_w=0;
	for(i=0;i<16;i=i+1)begin
		pattern_w[i]=pattern_r[i];
		flag_w[i]=flag_r[i];
	end
	
	if (state_r==0)begin
		counter_pattern_w=counter_pattern_r+1;
		counter_text_w=0;
		state_w=1;
	end
	else if (state_r==1)begin 	
		pattern_w[counter_last_pattern_r]=P_data;
		counter_pattern_w=counter_pattern_r+1;
		counter_last_pattern_w=counter_last_pattern_r+1;
		if (P_data==0)begin
			state_w=2;
			counter_last_pattern_w=counter_last_pattern_r-1;
			counter_text_w=counter_text_r+1;
			for(i=0;i<16;i=i+1)begin
				flag_w[i]=0;
			end
		end
	end
	else if (state_r==2)begin
		counter_text_w=counter_text_r+1;
		flag_w[0]=(T_data==pattern_r[0]);
		for(i=1;i<16;i=i+1)begin
			flag_w[i]=(T_data==pattern_r[i])&flag_r[i-1];
		end
		if (flag_r[counter_last_pattern_r]==1)begin
			match_addr_w=counter_text_r-counter_last_pattern_r-2;
			valid_w=1;
		end
	end	
	
	
end
*/
always@(posedge clk or posedge reset)begin
	if (reset)begin
		state_r<=0;
		counter_pattern_r<=0;
		counter_last_pattern_r<=0;
		pre_counter_last_pattern_r<=0;
		counter_text_r<=0;
		match_addr_r<=0;
		valid_r<=0;
		pattern_no_r<=0;
		finish_r<=0;
		last_optional_r<=0;
		T_data_real_r<=0;
		P_data_real_r<=0;
		for(i=0;i<16;i=i+1)begin
			pattern_r[i]<=0;
			flag_r[i]<=0;
			is_optional_r[i]<=0;
			shift_r[i]<=0;
		end
	end
	else begin
		state_r<=state_w;
		counter_pattern_r<=counter_pattern_w;
		counter_last_pattern_r<=counter_last_pattern_w;
		pre_counter_last_pattern_r<=pre_counter_last_pattern_w;
		counter_text_r<=counter_text_w;
		match_addr_r<=match_addr_w;
		valid_r<=valid_w;
		pattern_no_r<=pattern_no_w;
		finish_r<=finish_w;
		last_optional_r<=last_optional_w;
		T_data_real_r<=T_data_real_w;
		P_data_real_r<=P_data_real_w;
		for(i=0;i<16;i=i+1)begin
			pattern_r[i]<=pattern_w[i];
			flag_r[i]<=flag_w[i];
			is_optional_r[i]<=is_optional_w[i];
			shift_r[i]<=shift_w[i];
		end
	end
end

endmodule
