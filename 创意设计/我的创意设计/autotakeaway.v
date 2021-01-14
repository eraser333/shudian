module autotakeaway(input clk,
					input reset,getinfo,
					input [1:0] func,
					input [1:0] whichbox,
					input [3:0] key,
					output reg waitled, overloadled, nofoodled, keyerrorled, pushled, popled);

//定义5个基本状态
parameter WAIT = 3'b000;
parameter PUSH = 3'b001;
parameter POP = 3'b100;
parameter OVERLOAD = 3'b111;
parameter NOFOOD = 3'b110;

reg [2:0] curstate, nextstate;//状态
reg [2:0] size; //当前占用了几个储物柜 （0~4）
reg [3:0] isuse; //显示柜子的状态， 是否被占用
reg [15:0] boxkey; //存放4个柜子的开箱密码
reg [2:0] i,j;
reg flag;
reg iscorrect;

wire iscorrect_wire;
wire [3:0] cmpkey_wire;

//先数据选择,再进行数
select4_1(boxkey[3:0], boxkey[7:4], boxkey[11:8], boxkey[15:12],i, cmpkey_wire);
compare(cmpkey_wire, key, iscorrect_wire);

always@(posedge clk or posedge reset)
begin 
	if(reset)
		curstate <= WAIT;
	else
		curstate <= nextstate;
end

always@ (curstate)
begin 
	case(curstate)
		WAIT:
			begin 	
				case(func)
					2'b01://试图存入外卖
						begin
							if(size < 4)
								begin
									size = size + 1;
									nextstate <= PUSH;
								end
							else
								nextstate <= OVERLOAD;
						end
					2'b10://试图取走外卖
						begin
							if(size > 0)
								nextstate <= POP;
							else
								nextstate <= NOFOOD;
						end
					default:
						nextstate <= WAIT;
				endcase
				
				waitled = 1;
				overloadled = 0;
				nofoodled = 0;
				keyerrorled = 0;
				pushled = 0;
				popled = 0;
			end
		
		PUSH://存入外卖
			begin
				//选取出一个空柜子
				for(i = 0; i <= 3 && flag == 0; i = i+1)
					begin
						if(isuse[i] == 0)
							flag = 1;
						else
							flag = 0;
					end
				flag = 0;
				
				//设置密码
				for(j = 0; j <= 3; j = j+1)
					boxkey[j+i*4] = key[j]; 
				
				//标记该箱子被占用
				isuse[i] = 1;
				
				i = 0;
				j = 0;
				
				nextstate <= WAIT;
				
				waitled = 0;
				overloadled = 0;
				nofoodled = 0;
				keyerrorled = 0;
				pushled = 1;
				popled = 0;
				
			end

		POP://提取外卖
			begin 
				if(iscorrect_wire == 1)//输入的密码正确
					begin
						nextstate <= WAIT;
						size = size - 1;
						isuse[i] = 0;
						keyerrorled = 0;
					end
				else //输入密码错误
					begin 
						if(getinfo == 1)
							nextstate <= WAIT;
						else 
							nextstate <= POP;
						
						keyerrorled = 1;
					end
					
				waitled = 0;
				overloadled = 0;
				nofoodled = 0;
				pushled = 0;
				popled = 1;
			end
			
		OVERLOAD:
			begin
				if(getinfo)
					nextstate <= WAIT;
				else
					nextstate <= OVERLOAD;
					
				waitled = 0;
				overloadled = 1;
				nofoodled = 0;
				keyerrorled = 0;
				pushled = 0;
				popled = 0;
			end
			
		NOFOOD:
			begin
				if(getinfo)
					nextstate <= WAIT;
				else
					nextstate <= NOFOOD;
					
				waitled = 0;
				overloadled = 0;
				nofoodled = 1;
				keyerrorled = 0;
				pushled = 0;
				popled = 0;
			end		
		
		default:
			nextstate <= WAIT;
		
	endcase			
end

endmodule

		
		
		
		
		
		
		