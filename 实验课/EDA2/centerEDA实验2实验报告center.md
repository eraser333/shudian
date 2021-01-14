# <center>EDA实验2实验报告</center>

[toc]

## 一、实验目的

1. 实践基于 HDL 设计和实现时序逻辑电路的流程和方法；
2. 掌握用 HDL 实现有限状态机的方法；
3. 实践利用 FPGA 解决实际问题的方法。  



## 二、实验内容

### 自动售货机功能要求

* 可接受 5 角、 1 元和 5 元的投币，每次购买允许投入多种不同币值的钱币； 用 3只数码管显示当前投币金额，如 055 表示已投币 5.5 元； （3 只数码管的循环扫描显示）
* 可售出价格分别为 1.5 元和 2.5 元的商品，假设用户每次购买时只选择单件、 一种商品； 允许用户多次购买商品，每次购买后，可以进行补充投币；
* 选择购买商品后，如果投币金额不足，则提醒；否则，售出相应的商品，并提醒用户取走商品；
* 若用户选择退币， 则退回余下的钱，并提醒用户取钱。  



## 三、实验设计思路

* 消抖文件以实现正确的输入。

* 采用3只数码管实现循环扫描显示。（同EDA１中的实现）

* 状态机以实现自动售货机的投币、售出、退币和清零功能。（思路如下图1, 软件中画出的状态集机示意图如图二）

  ​	本题的核心在于状态机的建立。初始的状态设置为WAIT状态。

  * WAIT状态可以接受投币，投币的过程仍处于WAIT状态。当用户选择进行购买操作，根据所剩余额和购买食物的价格进行比较，若余额充足则转入FOOD状态，否则进入NOTENOUGH状态。若选择退币则进入REFUND状态。
  * FOOD状态表示购买成功，当用户按下取得货物的按钮，状态转回WAIT状态，否则保持FOOD状态不变。
  * NOTENOUGH状态表示用户金融不足，当用户按下收到信号的按钮，状态转回WAIT状态，否则保持NOTENOUGH不变。
  * REFUND状态表示用户申请退币，当用户按下收到退币按钮则状态转回到WAIT状态，否则保持REFUND状态不变。

![avatar](D:\桌面\数电\实验课\EDA2\1.jpg)

![Cache_-20200edec691e9d.](D:\桌面\数电\实验课\EDA2\Cache_-20200edec691e9d..jpg)

## 四、各模块实现方式

* 消抖模块（将输入的信号稳定化，避免抖动出现影响实验结果）。

  ```verilog
  module debounce(clk,key_i,key_o);
      input clk;		//时钟
      input key_i;	//按键输入
      output key_o;	//按键输出
  
      parameter NUMBER = 23'd10_000_000;	
      parameter NBITS = 23;				
      									
      reg [NBITS-1:0] count;//计数
      reg key_o_temp;	//按键输出
  
      reg key_m;	//缓存上一时刻的按键信号			
  	reg key_i_t1,key_i_t2;
  
      assign key_o = key_o_temp;
  	
      always @ (posedge clk) begin		
  		key_i_t1 <= key_i;			
  		key_i_t2 <= key_i_t1;//更新输入信号
  	end
  
      always @ (posedge clk) begin
          //如果上一时刻和当前时刻信号不一致，则更新信号
          if (key_m!=key_i_t2) begin		
              key_m <= key_i_t2;
              count <= 0;	//计数归零
          end
          //如果计数到达最大值，即长时间维持同一按键信号，是有效输入而不是微小抖动
          else if (count == NUMBER) begin	
              key_o_temp <= key_m;		//输出
          end
          else count <= count+1;			//记录上一个信号的持续时间
      end
  endmodule
  ```

  

* 数字显示模块（10进制，循环扫描实现）

  ```verilog
  //具体实现同EDA1
  module showNum10(input clk, //时钟信号
                   input [9:0] num, //计算出的金额
                   output [2:0] idOfLed, //选择亮起的灯管
                   output [6:0] segDetail); //亮起的具体部位
  
  //计算个位十位百位
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
  
  always@ (posedge clk)
  begin
  	curclk <= curclk + 1'b1;
  end
  
  //判断选择的位数和数字
  always @(hundred or decade or unit or curclk[10:10])
  begin
  		case(curclk[11:10])
  			2'b00:begin  tmpIdOfLed <= 3'b110;numShowing <= unit; end//显个位
  			2'b01:begin  tmpIdOfLed <= 3'b101;numShowing <= decade; end//显十位
  			default: begin tmpIdOfLed <= 3'b011; numShowing <= hundred; end //显百位
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



* 主模块（三段状态机的实现）

  * 第一段为时序逻辑，采用同步时序描述状态转移；
  * 第二段采用组合逻辑判断状态转移条件，描述状态转移规律； 
  * 第三段描述状态输出。

  ```verilog
  module eda2(input clk,
  				input reset, getKey,
  				input [5:0] sw,
  				output [2:0] showMoney,
  				output [6:0] dig,
  				output reg foodLed, coinLed, notEnoughLed, errorLed);
  
  //去抖
  wire getKeyOut;
  wire [5:0] swOut;
  debounce db(clk, getKey, getKeyOut);
  debounce db0(clk,sw[0],swOut[0]);
  debounce db1(clk,sw[1],swOut[1]);
  debounce db2(clk,sw[2],swOut[2]);
  debounce db3(clk,sw[3],swOut[3]);
  debounce db4(clk,sw[4],swOut[4]);
  debounce db5(clk,sw[5],swOut[5]);
  assign swOut={swOut[5],swOut[4],swOut[3],swOut[2],swOut[1],swOut[0]};
  
  reg [9:0] money;
  reg isCoin, isBuy;
      
  //定义四个基本状态 WAIT、FOOD、NOTENOUGH、REFUND
  parameter WAIT = 2'b00;
  parameter FOOD = 2'b01;
  parameter NOTENOUGH = 2'b10;
  parameter REFUND = 2'b11;
  
  //当前的状态
  reg [1:0] curState, nextState;
  
  //第一段：同步时序描述状态转移；
  always@ (posedge clk or negedge reset)
  begin 
  	if(!reset)
  		curState <= WAIT;
  	else
  		curState <= nextState;
  end
  
  //第二段：组合逻辑判断状态转移条件，描述状态转移规律； 
  always@ (curState)
  begin 
  		case(curState)
          //在wait状态里
  		WAIT:
  		begin
  			case(swOut)
              //投币，继续保持状态
  			6'b000001:
  				nextState = WAIT;
  			6'b000010:
  				nextState = WAIT;
  			6'b000100:
  				nextState = WAIT;
                  
              //购买食物，根据金额选择进入FOOD or NOTENOUGH
  			6'b001000:
  				begin
  					if(money>=15)
  						nextState<=FOOD;
  					else 
  						nextState<=NOTENOUGH;
  				end
  			6'b010000:
  				begin
  					if(money>=25)
  						nextState<=FOOD;
  					else 
  						nextState<=NOTENOUGH;
  				end
                  
              //退款， 进入REFUND状态
  			6'b100000:
  				nextState<=REFUND;
                
  			6'b000000:
  				nextState<=WAIT;
  			default: 
  				nextState <= curState;
  			endcase
  		end 
  		
          //FOOD、NOTENOUGH、REFUND发出的信号被接受后转入WAIT状态，否则保持原状态
  		FOOD:	
  		begin
  			if(!getKeyOut) 
  				nextState <= WAIT;
  			else 
  				nextState <= FOOD;
  		end
  		    
  		NOTENOUGH:
  		begin
  			if(!getKeyOut)
  				nextState <= WAIT; 
  			else 
  				nextState <= NOTENOUGH;
  		end 
  		
  		REFUND:
  		begin
  			if(!getKeyOut)
  				nextState <= WAIT; 
  			else 
  				nextState <= REFUND;
  		end
  	   endcase
  end				
  	
  //第三段描述状态输出。	
  always@ (posedge clk or negedge reset)
  begin
  	if(!reset)
  		money <= 0;
  	
  	else
  	begin 
  		case(nextState)
  		WAIT:
  		begin
              //指示灯全灭
  			isBuy = 0;
  			foodLed <= 0;
  			coinLed <= 0;
  			notEnoughLed <= 0;
  			errorLed <= 0;
   			
              //进行相应的数值计算
  			case(swOut)
  			6'b000001://投入5角
  			begin
  				if(!isCoin)
  					money <= money + 5;
  				isCoin = 1;
  			end
  			6'b000010://投入10角
  			begin
  				if(!isCoin)
  					money <= money + 10;
  				isCoin = 1;
  			end
  			6'b000100://投入50角
  			begin
  				if(!isCoin)
  					money <= money + 50;
  				isCoin = 1;
  			end
  			6'b001000,
  			6'b010000,
  			6'b100000:
  				money <= money;
  			6'b000000:
  				isCoin=0;
  			default:
  			begin
  				isCoin<=1;
  				errorLed<=1;
  				coinLed<=0;
  				foodLed<=0;
  				notEnoughLed<=0;
  			end
  			endcase
  		end
  		
  		FOOD:
  		begin
              //指示灯工作
  			foodLed <= 1;
  			notEnoughLed <= 0;
  			coinLed <= 0;
  			errorLed <= 0;
  			case(swOut)
  				6'b001000://购买15角食物
  				begin 
  					if(money >= 15 && !isBuy)
  						money <= money - 15;
  					isBuy = 1;
  				end
  				6'b010000://购买25角食物
  				begin
  					if(money >= 25 && !isBuy)
  						money <= money - 25;
  					isBuy = 1;
  				end
  				default:
  					money <= money;
  				endcase
  		end
  		
  		NOTENOUGH:
  		begin//指示灯工作
  			foodLed <= 0;
  			notEnoughLed <= 1;
  			coinLed <= 0;
  			errorLed <= 0;
  		end
  			
  		REFUND:
  		begin//指示灯工作，且金额归0
  			foodLed <= 0;
  			notEnoughLed <= 0;
  			coinLed <= 1;
  			errorLed <= 0;
  			money = 0;
  		end 
  		
  		endcase
  	end
  end
      
  //显示10进制金额
  showNum10(clk, money, showMoney, dig);	
  endmodule
  ```

  

## 五、主要问题以及解决方案

### 思路问题

​	缺少状态机和时序电路设计的概念，试图使用组合逻辑电路，虽然可以，但是未达到课程学习要求。

​	解决：对状态机加深了理解。

### 实际操作的问题

1. 遇到了老师课件上提到过的分支不完全的case语句问题，电路产生了意想不到的变化。

   解决：补全case语句。

2. 将状态机从一段转为三段的时候出现了逻辑错误。一段时购买食物可以紧接着出现判断的语句写，但是三段时必须将购买食物减少金额必须在第三段FOOD状态里进行。

