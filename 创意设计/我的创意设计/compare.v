module compare(input [3:0] num1,
					input [3:0] num2,
					output reg res);

always@(num1 or num2)
begin
	if(num1 == num2)
		res = 1;
	else
		res = 0;
end

endmodule