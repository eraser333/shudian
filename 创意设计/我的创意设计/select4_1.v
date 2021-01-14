module select4_1(input [3:0] key0,
					  input [3:0] key1,
					  input [3:0] key2,
					  input [3:0] key3,
					  input [2:0] num,
					  output reg [3:0] reskey);

always@(num)
begin 
	case(num)
	3'b000:
		reskey = key0;
	3'b001:
		reskey = key1;
	3'b010:
		reskey = key2;
	3'b011:
		reskey = key3;
	default:
		reskey = reskey;
	endcase
end

endmodule