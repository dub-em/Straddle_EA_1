//+------------------------------------------------------------------+
//|                                               My_First_Robot.mq4 |
//|                                                     The Presence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "The Presence"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

datetime globalbartime; //declares the variable globaltime that is assigned the time value of the current candle at the start of the EA execution.
input double ls = 0.01; //decalres the starting lotsize, which is an input.
input int magic_num = 001; //declares a distinct magic number for all trades executed by a unique instance of the EA.
input int interval = 39; //declares the interval between consecutive trades.
input int lotlimit = 100; //declares the lotlimit of the account being traded on (dependent on the Broker).
input double mult_fact = 1.58;
int numofmultiples_buy = 0;
double newLot_buy = 0;
int identifier_buy = 0;
double loop = 0;
int num_firstlot = 1; //declares the number of subsequent positions after the first position initiated with the starting lot.

// Variables used to store the three highest positions for quick reference
double multiplier = 100000;

double first_buy = 0;
double thrd_highestlot_buy = 0;
double sec_highestlot_buy = 0;
double highestlot_buy = 0;

//Run this function each time the price changes on the chart.
void OnTick(){
   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //If there is a new bar run the main function
      onBar_buy();
      /*Assign the new bar datetime (rightbartime) to the globalbartime to rerun the onBar comparison, so as to indicate a new bar,
      when these two variables aren't the same*/
      globalbartime = rightbartime;
   } 
}

//The function containing all the logic
void onBar_buy(){
   int takeProfit = 40; // 4 pips in pippettes
   double lot = ls; //Assigns the starting lot size.
   
   //Loops through all the open orders with the magic number unique to the instance of the EA, to count all open trades.
   int num = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber() == magic_num){
         num += 1;
      } 
   }
    
   //Check if there are no open positions currently
   if(num == 0){
      numofmultiples_buy = 0;
      //Open a buy position
      OrderSend(_Symbol, OP_BUY, lot, Ask, 50, 0, 0, NULL, magic_num);
      
      //Stores the positions in the predefined variables for later updating and referencing in the uniform TP calculator.
      first_buy = Ask;
      thrd_highestlot_buy = 0;
      sec_highestlot_buy = 0;
      highestlot_buy = Ask;
      
      //Get the details such as opening price and position ID from the first opened position to use and set it's TP.
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= OrdersTotal()-1; i++){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            newTicket = OrderTicket();
            break;
         }   
      }
      //Add the take profit defined earlier to the opening price
      newTp = highestlot_buy + takeProfit*_Point;
      
      //Modiify the first opened positions take profit and stop loss
      if (Ask > newTp){
         //If market rapidly speeds past our expected TP before we can set it, then we can close the order manually.
         OrderClose(newTicket, lot, Ask, 50);
      }else{
         //If market is still below our expected TP, then we can modify the position and set our TP.
         OrderModify(newTicket, NULL, NULL, newTp, NULL);
      }  
   }else{ 
      /*Get the details such as opening price and position ID and TP from the first opened positions so we can modify
      the second position with the initial lot size*/
      double firstTP = 0;
      int num_2 = 0;
      for(int i = OrdersTotal()-1; i >= 0; i--){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            firstTP = OrderTakeProfit();
            num_2 += 1;
         }   
      }
      
      /*Check if trades open is only one then call the function to open the second position, after the gap between the current
      price and the last open price is more than the specified interval*/
      if((num_2 <= num_firstlot)&&((highestlot_buy - interval*_Point) >= Ask)){
         OrderSend(_Symbol, OP_BUY, lot, Ask, 50, 0, 0, NULL, magic_num);
         
         //Updates the predefined variable for later reference in the uniform TP calculator. This happens after every open position.
         thrd_highestlot_buy = sec_highestlot_buy;
         sec_highestlot_buy = highestlot_buy;
         highestlot_buy = Ask;
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderMagicNumber() == magic_num)break;   
         }
         int newTicket = OrderTicket();
         //Modiify the second opened positions take profit and stop loss.
         if (Ask > firstTP){
            OrderClose(newTicket, lot, Ask, 50);
         }else{
            OrderModify(newTicket, NULL, NULL, firstTP, NULL);
         }
      }else{
         //Check if trades open is greater than or equals to two, then call the function to open subsequent positions.
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderMagicNumber() == magic_num){
               break;
            }   
         }
         
         //Gets the lotsize of the last opened position and applies the multiplification factor
         double latestLot_buy = 0;
         
         //Checks if the lotsizes have exceeded the lotlimit and multiple trades have been opened before to maintain the hedging.
         if (numofmultiples_buy == 0){
            latestLot_buy = OrderLots();
            latestLot_buy = NormalizeDouble(latestLot_buy * mult_fact, 2);
         }else{
            latestLot_buy = newLot_buy * mult_fact;
         }
         if(num_2 > num_firstlot){
            /*Checks if the lotsizes have exceeded the lotlimit to know whether to use regular lotsizes or resort to opening
            multiple positions to maintain the hedging*/
            if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy < lotlimit)){
               OrderSend(_Symbol, OP_BUY, latestLot_buy, Ask, 50, 0, 0, NULL, magic_num);
               thrd_highestlot_buy = sec_highestlot_buy;
               sec_highestlot_buy = highestlot_buy;
               highestlot_buy = Ask;
               
               /*Call the function that will be used to modify all the positions and adjust the stop loss / take profit.
               This function is commenced after the third position is opened*/
               uniformPointCalculator_buy();
            }else{
               if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy > lotlimit)){
                  //Mulitple positions are opened to maintain the hedging after the lotlimit has been exhausted.
                  
                  if (numofmultiples_buy == 0){
                     //If no other multiple positions have been opened before, then this is execute to start the process.
                     newLot_buy = OrderLots();
                     newLot_buy = newLot_buy*mult_fact;
                     identifier_buy = numofmultiples_buy+1;
                     loop = MathCeil(newLot_buy/lotlimit); //Divided the current lot by the lotlimit to get the number of times to loop.
                     for(int i=1; i<=loop; i++){
                        if(i == loop){
                           /*After current lot has been divided by the lotlimit and the loop is on the last iteration,
                           the last position is opened with a lot of the remainder of the division*/
                           double lastLot_buy = newLot_buy - (lotlimit * (i-1));
                           OrderSend(_Symbol, OP_BUY, NormalizeDouble(lastLot_buy, 2), Ask, 50, 0, 0, identifier_buy, magic_num);
                        }else{
                           /*After current lot has been divided by the lotlimit, the lotlimit is used to open multiple position
                           till the loop is on it's last iteration.*/
                           OrderSend(_Symbol, OP_BUY, lotlimit, Ask, 50, 0, 0, identifier_buy, magic_num);
                        }    
                     }
                     thrd_highestlot_buy = sec_highestlot_buy;
                     sec_highestlot_buy = highestlot_buy;
                     highestlot_buy = Ask;
                     numofmultiples_buy += 1;
                     uniformPointCalculator_buy();
                   }else{
                     if (numofmultiples_buy > 0){
                        newLot_buy = newLot_buy*mult_fact;
                        identifier_buy = numofmultiples_buy+1;
                        loop = MathCeil(newLot_buy/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_buy = newLot_buy - (lotlimit * (loop-1));
                              OrderSend(_Symbol, OP_BUY, NormalizeDouble(lastLot_buy, 2), Ask, 50, 0, 0, identifier_buy, magic_num);
                           }else{
                              OrderSend(_Symbol, OP_BUY, lotlimit, Ask, 50, 0, 0, identifier_buy, magic_num);
                           }
                        }
                        thrd_highestlot_buy = sec_highestlot_buy;
                        sec_highestlot_buy = highestlot_buy;
                        highestlot_buy = Ask;
                        numofmultiples_buy += 1;
                        uniformPointCalculator_buy();
                    }
                 }
              }    
           }
         }     
      }
   }
}

//Defining the function that modifies all the open trades
void uniformPointCalculator_buy(){
   /*This model is used to calculate where to put the TP for all positions after open positions exceed 2.
   It is dependent on the highest, second highest, third highest and first position*/
   
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.30681265*(MathAbs(highestlot_buy-sec_highestlot_buy)*multiplier) + 0.01972324*(MathAbs(highestlot_buy-first_buy)*multiplier);  
   nextTPSL = highestlot_buy + nextTPSL*_Point;
   nextTPSL = bestTp_buy(nextTPSL); //Adjusts the uniform TP incase the current one will result in loss.
   
   //Loop through all positions that are currently open
   if (Ask > nextTPSL){
      //If market rapidly speeds past our expected TP before we can set it, then we can close all open orders manually.
      
      for(int i = OrdersTotal()-1; i >= 0; i--){
         /*Get the details from the current position such as opening price, lot size, and position id 
         so we can modify it*/
            
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            int posTicket = OrderTicket();
            double close_lot = OrderLots();
            OrderClose(posTicket, close_lot, Ask, 50);
         }        
      }
   }else{
      for(int i = OrdersTotal()-1; i >= 0; i--){
         /*Get the details from the current position such as opening price, lot size, and position id 
         so we can modify it*/
            
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            int posTicket = OrderTicket();
            OrderModify(posTicket, NULL, NULL, nextTPSL, NULL);
         }        
      }   
   }    
}

//Adjusts the uniform TP incase the current one will result in loss.
double bestTp_buy(double currentTp){
   double add = 0;
   double finalAmountAtClose = 0;
   do{
      currentTp = NormalizeDouble((currentTp + (add)*_Point), 5);
      for(int i = OrdersTotal()-1; i >= 0; i--){
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            finalAmountAtClose += ((currentTp - OrderOpenPrice())*10000) * (OrderLots()*10);
         }
      }
      add += 50;
   }while(finalAmountAtClose < 1 && !IsStopped());
   return currentTp;
}