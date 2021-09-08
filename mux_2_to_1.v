module mux_2_to_1 (
	input  [9:0] SW,
	output [9:0] LEDR
);

	wire [2:0] X, Y, M;

	assign S = SW[9];
	assign X = SW[2:0];
	assign Y = SW[5:3];

	assign LEDR[9] = S;
	assign LEDR[2:0] = X;
	assign LEDR[5:3] = Y;

	assign LEDR[8:6] = M;

	assign M = S ? Y : X;

endmodule