# <center>EDA实验1实验报告</center>

## 一、实验目的

- 实践基于 FPGA 设计和实现组合逻辑电路的流程和方法；
- 学习一种硬件描述语言；
- 熟悉利用 FPGA 平台进行设计验证的方法。



## 二、实验内容

* 基于实验套件中的 FPGA 开发板，实现简易计算器，具有加、减和乘的功能；
* 修改设计，以16进制显示运算数A，以10进制显示运算数；
* 功能拓展，以16进制同时显示运算数A、B，并以10进制显示运算数, 并扫描显示。



## 三、实验设计思路

* 设计加法器、减法器和乘法器模块，实现相应的运算；
* 实现数据选择，选择出相应的计算结果；
* 对计算结果进行输出（10进制和16进制）。



## 四、各模块实现方法

* 加、减、乘运算器（add, sub, mul）

```verilog
//以下分别为加法、减法和乘法模块
//输出的计算数值为res, 数值的符号为s
module add(input [3:0] a,b,
	   	   output [7:0] res,
	       output s);
assign res = a + b;
assign s = 1'b0;
endmodule

module sub(input [3:0] a,b,
		   output [7:0] res,
		   output s);
assign res = (b > a) ?(b-a):(a-b);
assign s = (b > a);
endmodule

module mul(input [3:0] a, b,
		   output[7:0] res,
		   output s);
assign res = a * b;
assign s = 1'b0;
endmodule
```



* 16进制(showNum16)数据显示模块：

```verilog
module showNum16(input [7:0] num,//计算出的数值
				 input [3:0] a, b,//计算数
                 input [1:0] whichLed,//控制亮起的灯管
				 output [3:0] idOfLed, //选择亮起的灯管
				 output add,//10进制所需额外的灯管， 本模块中被置为1（熄灭）
				 output [6:0] segDetail);//亮起灯管的哪些部位
wire [3:0] numHigh, numLow;
assign numHigh = num [7:4];
assign numLow = num [3:0];

reg [3:0] numShowing;
reg [3:0] tmpIdOfLed;
reg [6:0] tmpsegDetail;
reg [11:0] curclk;
reg ADD;
assign add = ADD;
assign idOfLed = tmpIdOfLed;
assign segDetail = tmpsegDetail;

//判断选择的位数和数字
always @(whichLed)
begin
		ADD = 1'b1;
		case(whichLed)
			2'b11: begin tmpIdOfLed <= 4'b1110;numShowing <= numLow; end//显示低位
			2'b10: begin tmpIdOfLed <= 4'b1101;numShowing <= numHigh; end//显示高位
			2'b01: begin tmpIdOfLed <= 4'b1011; numShowing <= b; end//	
			2'b00: begin tmpIdOfLed <= 4'b0111; numShowing <= a; end // 
		endcase
end


//单个灯管如何点亮
always @(numShowing)
begin
	case(numShowing)
		4'b0000: tmpsegDetail <= 7'b1000000; 	//0
		4'b0001: tmpsegDetail <= 7'b1111001; 	//1
		4'b0010: tmpsegDetail <= 7'b0100100; 	//2
		4'b0011: tmpsegDetail <= 7'b0110000; 	//3
		4'b0100: tmpsegDetail <= 7'b0011001; 	//4
		4'b0101: tmpsegDetail <= 7'b0010010; 	//5
		4'b0110: tmpsegDetail <= 7'b0000010; 	//6
		4'b0111: tmpsegDetail <= 7'b1011000; 	//7
		4'b1000: tmpsegDetail <= 7'b0000000; 	//8
		4'b1001: tmpsegDetail <= 7'b0010000; 	//9
		4'b1010: tmpsegDetail <= 7'b0001000; 	//A
		4'b1011: tmpsegDetail <= 7'b0000011; 	//b
		4'b1100: tmpsegDetail <= 7'b1000110; 	//C
		4'b1101: tmpsegDetail <= 7'b0100001; 	//d
		4'b1110: tmpsegDetail <= 7'b0000110; 	//E
		4'b1111: tmpsegDetail <= 7'b0001110; 	//F	
	endcase
end

endmodule

//十进制的数据显示模块,
//模块的输入输出参数同十六进制的
module showNum10(input clk,
				 input [7:0] num,
                 input [3:0] a, b,
				 output [3:0] idOfLed,
				 output addLed,
				 output [6:0] segDetail);
//将运算结果转化为十进制
wire [3:0] hundred, decade, unit;
assign unit = num % 10;
assign decade = (num/10) % 10;
assign hundred = num / 100;


reg [3:0] numShowing;
reg [3:0] tmpIdOfLed;
reg [6:0] tmpsegDetail;
reg [11:0] curclk;
reg ADDLED;
assign idOfLed = tmpIdOfLed;
assign segDetail = tmpsegDetail;
assign addLed = ADDLED;

always@ (posedge clk)
begin
	curclk <= curclk + 1'b1;
end

//判断选择的位数和数字
always @(hundred or decade or unit or a or b or curclk[10:10])
begin
		case(curclk[11:9])
            ////显示个位
			3'b000:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1110;numShowing <= unit; end
			3'b001:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1110;numShowing <= unit; end
             //显示十位
			3'b010:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1101;numShowing <= decade; end
			3'b011:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1101;numShowing <= decade; end
            //显示百位
			3'b100:begin ADDLED = 1'b0; tmpIdOfLed <= 4'b1111; numShowing <= hundred; end 
			3'b101:begin ADDLED = 1'b0; tmpIdOfLed <= 4'b1111; numShowing <= hundred; end
            //b 
			3'b110:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b0111; numShowing <= a; end 
            //a
			3'b111:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1011; numShowing <= b; end
		endcase
end


//单个灯管如何点亮
always @(numShowing)
begin
	case(numShowing)
		4'b0000: tmpsegDetail <= 7'b1000000; 	//0
		4'b0001: tmpsegDetail <= 7'b1111001; 	//1
		4'b0010: tmpsegDetail <= 7'b0100100; 	//2
		4'b0011: tmpsegDetail <= 7'b0110000; 	//3
		4'b0100: tmpsegDetail <= 7'b0011001; 	//4
		4'b0101: tmpsegDetail <= 7'b0010010; 	//5
		4'b0110: tmpsegDetail <= 7'b0000010; 	//6
		4'b0111: tmpsegDetail <= 7'b1011000; 	//7
		4'b1000: tmpsegDetail <= 7'b0000000; 	//8
		4'b1001: tmpsegDetail <= 7'b0010000; 	//9
		4'b1010: tmpsegDetail <= 7'b0001000; 	//A
		4'b1011: tmpsegDetail <= 7'b0000011; 	//b
		4'b1100: tmpsegDetail <= 7'b1000110; 	//C
		4'b1101: tmpsegDetail <= 7'b0100001; 	//d
		4'b1110: tmpsegDetail <= 7'b0000110; 	//E
		4'b1111: tmpsegDetail <= 7'b0001110; 	//F	
	endcase
end
endmodule
```



* 10进制(showNum10)数据显示模块：
  * 拓展功能1：数码管循环扫描显示。
  * 拓展功能2：同时显示了运算数a, b。

```verilog
module showNum10(input clk,
				 input [7:0] num,
				 input [3:0] a, b,
				 output [3:0] idOfLed,
				 output addLed,
				 output [6:0] segDetail);
wire [3:0] hundred, decade, unit;
assign unit = num % 10;
assign decade = (num/10) % 10;
assign hundred = num / 100;


reg [3:0] numShowing;
reg [3:0] tmpIdOfLed;
reg [6:0] tmpsegDetail;
reg [11:0] curclk;
reg ADDLED;
assign idOfLed = tmpIdOfLed;
assign segDetail = tmpsegDetail;
assign addLed = ADDLED;

always@ (posedge clk)
begin
	curclk <= curclk + 1'b1;
end

//判断选择的位数和数字
always @(hundred or decade or unit or a or b or curclk[10:10])
begin
		case(curclk[11:9])
            //显示个位
			3'b000:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1110;numShowing <= unit; end
			3'b001:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1110;numShowing <= unit; end
            //显示十位
			3'b010:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1101;numShowing <= decade; end
			3'b011:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1101;numShowing <= decade; end
            //显示百位
			3'b100:begin ADDLED = 1'b0; tmpIdOfLed <= 4'b1111; numShowing <= hundred; end 
			3'b101:begin ADDLED = 1'b0; tmpIdOfLed <= 4'b1111; numShowing <= hundred; end 
            //显示a
			3'b110:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b0111; numShowing <= a; end 
            //显示b
			3'b111:begin ADDLED = 1'b1; tmpIdOfLed <= 4'b1011; numShowing <= b; end
		endcase
end


//单个灯管如何点亮
always @(numShowing)
begin
	case(numShowing)
		4'b0000: tmpsegDetail <= 7'b1000000; 	//0
		4'b0001: tmpsegDetail <= 7'b1111001; 	//1
		4'b0010: tmpsegDetail <= 7'b0100100; 	//2
		4'b0011: tmpsegDetail <= 7'b0110000; 	//3
		4'b0100: tmpsegDetail <= 7'b0011001; 	//4
		4'b0101: tmpsegDetail <= 7'b0010010; 	//5
		4'b0110: tmpsegDetail <= 7'b0000010; 	//6
		4'b0111: tmpsegDetail <= 7'b1011000; 	//7
		4'b1000: tmpsegDetail <= 7'b0000000; 	//8
		4'b1001: tmpsegDetail <= 7'b0010000; 	//9
		4'b1010: tmpsegDetail <= 7'b0001000; 	//A
		4'b1011: tmpsegDetail <= 7'b0000011; 	//b
		4'b1100: tmpsegDetail <= 7'b1000110; 	//C
		4'b1101: tmpsegDetail <= 7'b0100001; 	//d
		4'b1110: tmpsegDetail <= 7'b0000110; 	//E
		4'b1111: tmpsegDetail <= 7'b0001110; 	//F	
	endcase
end

endmodule
```



* 主函数（eda1)，其中包含了数据选择部分

```verilog
module eda1(input clk,
		    input [3:0] a,b,
			input [1:0] f,//选择加减乘0运算
			output [3:0] led,//亮起的灯管
			output [6:0] seg,//亮起部位
			output hundred,
			output s); //正负号

//进行相应的加减乘运算
wire [7:0] addRes, subRes, mulRes;
reg [7:0] Res;
wire [3:0] LED;
wire [6:0] SEG;
wire addS, subS, mulS, HUNDRED;
reg S;
assign s = S;
assign led = LED;
assign seg = SEG;
assign hundred = HUNDRED;

add myAdd(a, b, addRes, addS);
sub mySub(a, b, subRes, subS);
mul myMul(a, b, mulRes, mulS);

//数据选择部分，四选一数据选择器
always @(f)
begin
	case(f)
		2'b11: begin S = 1'b0;Res = 8'b00000000; end
		2'b01: begin S = addS;Res = addRes; end
		2'b10: begin S = subS;Res = subRes; end
		2'b00: begin S = mulS;Res = mulRes; end
	endcase
end

//根据需要选择显示十六进制抑或是十进制
//showNum16(clk, Res, a, b, LED, HUNDRED, SEG); 
showNum10(clk,Res, a, b, LED, HUNDRED, SEG); 
endmodule
```



## 五、问题及解决方案

### 思路上的问题

​	起初没有建立起模块化的思维，简单地将模块理解为函数，导致了程序的编译错误。

​	解决：建立起了硬件的思维，每个模块是实打实存在的，有别于软件程序设计中的函数。



### 实际操作中遇到的问题

​	时钟信号错误，只能显示一根灯管，无法达到循环显示的需求。

​	解决：发现了clk输入引脚错误，应当选择PIN_152引脚。