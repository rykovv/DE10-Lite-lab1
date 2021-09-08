`define CTR_BITS 	8
`define CTR_MAXVAL	99
`define SS_IBITS	4
`define SS_OBITS	8


module addit(
	input wire i_CLOCK_50, i_rst,
	input wire [1:0] i_EN,
	output reg [9:0] o_LEDR,
	output wire [(6*`SS_OBITS)-1:0] o_HEX
);

	wire slow_clock;
	wire [`CTR_BITS-1:0] ctr0;
	wire [`CTR_BITS-1:0] ctr1;
	reg  [`CTR_BITS-1:0] sum;
	wire [`SS_IBITS-1:0] ctr_one0;
	wire [`SS_IBITS-1:0] ctr_ten0;
	wire [`SS_IBITS-1:0] ctr_one1;
	wire [`SS_IBITS-1:0] ctr_ten1;
	wire [`SS_IBITS-1:0] sum_one;
	wire [`SS_IBITS-1:0] sum_ten;
	
	clock_divider u0 (.i_rst(i_rst), .i_fast_clock(i_CLOCK_50), .o_slow_clock(slow_clock));
	
	ctr c0 (.i_clk(slow_clock), .i_rst(i_rst), .i_en(i_EN[0]), .o_ctr(ctr0)); 
	ctr c1 (.i_clk(slow_clock), .i_rst(i_rst), .i_en(i_EN[1]), .o_ctr(ctr1));
	
	eight_bit_binary_to_decimal ibbd0 (.i_binary(ctr0), .one(ctr_one0), .ten(ctr_ten0));
	eight_bit_binary_to_decimal ibbd1 (.i_binary(ctr1), .one(ctr_one1), .ten(ctr_ten1));
	eight_bit_binary_to_decimal ibbd2 (.i_binary(sum), .one(sum_one), .ten(sum_ten));
	
	seven_segment ss0 (.i_binary(ctr_ten0), .o_ss(o_HEX[`SS_OBITS*5+:`SS_OBITS]));
	seven_segment ss1 (.i_binary(ctr_one0), .o_ss(o_HEX[`SS_OBITS*4+:`SS_OBITS]));
	seven_segment ss2 (.i_binary(ctr_ten1), .o_ss(o_HEX[`SS_OBITS*3+:`SS_OBITS]));
	seven_segment ss3 (.i_binary(ctr_one1), .o_ss(o_HEX[`SS_OBITS*2+:`SS_OBITS]));
	seven_segment ss4 (.i_binary(sum_ten),  .o_ss(o_HEX[`SS_OBITS*1+:`SS_OBITS]));
	seven_segment ss5 (.i_binary(sum_one),  .o_ss(o_HEX[0+:`SS_OBITS]));
	
	
	always @(posedge slow_clock)
	begin
		sum = ctr0 + ctr1;
		
		if (sum > `CTR_MAXVAL) begin
			sum <= sum / 10;
			o_LEDR <= {10{1'b1}};
		end else
			o_LEDR <= 0;
	end
	
endmodule

module clock_divider(
	input wire i_rst,
	input wire i_fast_clock,
	output wire o_slow_clock
);
	// Output frequency should be 2Hz
	// Let the divider be x, then it should be:
	//   50MHz/x = 2Hz -> x = 50MHz/2Hz = 25*10^6
	//   log2(25*10^6) = 24.57
	//   COUNTER_SIZE = 23 -> 0.16s -> ~6Hz
	//   COUNTER_SIZE = 24 -> 0.33s -> ~3hz <-------- best approximation
	//   COUNTER_SIZE = 25 -> 0.67s -> ~1.5Hz
	parameter COUNTER_SIZE = 24;
	parameter COUNTER_MAX_COUNT = (2 ** COUNTER_SIZE) - 1;

	reg [COUNTER_SIZE-1:0] count;

	always @ (posedge i_fast_clock or negedge i_rst)
	begin
		if (!i_rst)
			count <= 0;
		else
			if(count == COUNTER_MAX_COUNT)
				count <= 0;
			else
				count <= count + 1'b1;
	end

	assign o_slow_clock = count[COUNTER_SIZE-1];

endmodule

module ctr (
	input wire i_clk, i_en, i_rst,
	output reg [`CTR_BITS-1:0] o_ctr
);

	always @(posedge i_clk or negedge i_rst)
	begin
		if (!i_rst)
			o_ctr <= 0;
		else
			if (i_en)
				if (o_ctr == `CTR_MAXVAL)
					o_ctr <= 0;
				else
					o_ctr <= o_ctr + 1;
			else
				o_ctr <= o_ctr;
	end		

endmodule


module eight_bit_binary_to_decimal(
	input wire 	[`CTR_BITS-1:0] i_binary,
	output wire [`SS_IBITS-1:0] one,
	output wire [`SS_IBITS-1:0] ten
);

	assign one = i_binary % 10;
	assign ten = i_binary / 10;

endmodule


module seven_segment(
	input wire [`SS_IBITS-1:0] i_binary,
	output reg [`SS_OBITS-1:0] o_ss
);

	always @(*)
	begin
		case (i_binary)
			0 : o_ss = 8'b1100_0000;//o_ss = 8'b0011_1111;
			1 : o_ss = 8'b1111_1001;//8'b0000_0110;
			2 : o_ss = 8'b1010_0100;//8'b0101_1011;
			3 : o_ss = 8'b1011_0000;//8'b0100_1111;
			4 : o_ss = 8'b1001_1001;//8'b0110_0011;
			5 : o_ss = 8'b1001_0010;//8'b0110_1101;
			6 : o_ss = 8'b1000_0010;//8'b0111_1101;
			7 : o_ss = 8'b1111_1000;//8'b0000_0111;
			8 : o_ss = 8'b1000_0000;//8'b0111_1111;
			9 : o_ss = 8'b1001_0000;//8'b0110_1111;
			default : o_ss = 8'b0111_1111;//8'b1000_0000;
		endcase
	end

endmodule
