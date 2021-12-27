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
input int magic_num = 002; //declares a distinct magic number for all trades executed by a unique instance of the EA.
input int interval = 39; //declares the interval between consecutive trades.
input int lotlimit = 100; //declares the lotlimit of the account being traded on (dependent on the Broker).
int numofmultiples_sell = 0;
double newLot_sell = 0;
int identifier_sell = 0;
double loop = 0;
double mult_fact = 1.58;
int num_firstlot = 1; //declares the number of subsequent positions after the first position initiated with the starting lot.

// Variables used to store the three highest positions and the first position for quick reference.
double multiplier = 100000;

double first_sell = 0;
double thrd_highestlot_sell = 0;
double sec_highestlot_sell = 0;
double highestlot_sell = 0;

//Run this function each time the price changes on the chart.
void OnTick(){
   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //If there is a new bar run the main function
      onBar_sell();
      /*Assign the new bar datetime (rightbartime) to the globalbartime to rerun the onBar comparison, so as to indicate a new bar,
      when these two variables aren't the same*/
      globalbartime = rightbartime; 
   } 
}

//The function containing all the logic
void onBar_sell(){
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
      numofmultiples_sell = 0;
      //Open a buy position
      OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0, NULL, magic_num);
      
      //Stores the positions in the predefined variables for later updating and referencing in the uniform TP calculator.
      first_sell = Bid;
      thrd_highestlot_sell = 0;
      sec_highestlot_sell = 0;
      highestlot_sell = Bid;
      
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
      newTp = highestlot_sell - takeProfit*_Point;
      
      //Modiify the first opened positions take profit and stop loss
      if (Bid < newTp){
         //If market rapidly speeds past our expected TP before we can set it, then we can close the order manually.
         OrderClose(newTicket, lot, Bid, 50);
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
      if((num_2 <= num_firstlot)&&((highestlot_sell + interval*_Point) <= Bid)){
         OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0, NULL, magic_num);
         
         //Updates the predefined variable for later reference in the uniform TP calculator. This happens after every open position.
         thrd_highestlot_sell = sec_highestlot_sell;
         sec_highestlot_sell = highestlot_sell;
         highestlot_sell = Bid;
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderMagicNumber() == magic_num)break;   
         }
         int newTicket = OrderTicket();
         //Modiify the second opened positions take profit and stop loss.
         if (Bid < firstTP){
            OrderClose(newTicket, lot, Bid, 50);
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
         double latestLot_sell = 0;
         
         //Checks if the lotsizes have exceeded the lotlimit and multiple trades have been opened before to maintain the hedging.
         if (numofmultiples_sell == 0){
            latestLot_sell = OrderLots();
            latestLot_sell = NormalizeDouble(latestLot_sell * mult_fact, 2);
         }else{
            latestLot_sell = newLot_sell * mult_fact;
         }
         if(num_2 > num_firstlot){
            /*Checks if the lotsizes have exceeded the lotlimit to know whether to use regular lotsizes or resort to opening
            multiple positions to maintain the hedging*/
            if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell < lotlimit)){
               OrderSend(_Symbol, OP_SELL, latestLot_sell, Bid, 50, 0, 0, NULL, magic_num);
               thrd_highestlot_sell = sec_highestlot_sell;
               sec_highestlot_sell = highestlot_sell;
               highestlot_sell = Bid;
               
               /*Call the function that will be used to modify all the positions and adjust the stop loss / take profit.
               This function is commenced after the third position is opened*/
               uniformPointCalculator_sell();
            }else{
               if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell > lotlimit)){
                  //Mulitple positions are opened to maintain the hedging after the lotlimit has been exhausted.
                  
                  if (numofmultiples_sell == 0){
                     //If no other multiple positions have been opened before, then this is execute to start the process.
                     newLot_sell = OrderLots();
                     newLot_sell = newLot_sell*mult_fact;
                     identifier_sell = numofmultiples_sell+1;
                     loop = MathCeil(newLot_sell/lotlimit); //Divided the current lot by the lotlimit to get the number of times to loop.
                     for(int i=1; i<=loop; i++){
                        if(i == loop){
                           /*After current lot has been divided by the lotlimit and the loop is on the last iteration,
                           the last position is opened with a lot of the remainder of the division*/ 
                           double lastLot_sell = newLot_sell - (lotlimit * (i-1));
                           OrderSend(_Symbol, OP_SELL, NormalizeDouble(lastLot_sell, 2), Bid, 50, 0, 0, identifier_sell, magic_num);
                        }else{
                           /*After current lot has been divided by the lotlimit, the lotlimit is used to open multiple position
                           till the loop is on it's last iteration.*/ 
                           OrderSend(_Symbol, OP_SELL, lotlimit, Bid, 50, 0, 0, identifier_sell, magic_num);
                        }    
                     }
                     thrd_highestlot_sell = sec_highestlot_sell;
                     sec_highestlot_sell = highestlot_sell;
                     highestlot_sell = Bid;
                     numofmultiples_sell += 1;
                     uniformPointCalculator_sell();
                   }else{
                     if (numofmultiples_sell > 0){
                        newLot_sell = newLot_sell*mult_fact;
                        identifier_sell = numofmultiples_sell+1;
                        loop = MathCeil(newLot_sell/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_sell = newLot_sell - (lotlimit * (loop-1));
                              OrderSend(_Symbol, OP_SELL, NormalizeDouble(lastLot_sell, 2), Bid, 50, 0, 0, identifier_sell, magic_num);
                           }else{
                              OrderSend(_Symbol, OP_SELL, lotlimit, Bid, 50, 0, 0, identifier_sell, magic_num);
                           }
                        }
                        thrd_highestlot_sell = sec_highestlot_sell;
                        sec_highestlot_sell = highestlot_sell;
                        highestlot_sell = Bid;
                        numofmultiples_sell += 1;
                        uniformPointCalculator_sell();
                    }
                 }
              }    
           }
         }     
      }
   }
}

//Defining the function that modifies all the open trades
void uniformPointCalculator_sell(){
   /*This model is used to calculate where to put the TP for all positions after open positions exceed 2.
   It is dependent on the highest, second highest, third highest and first position*/
   
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.30681265*(MathAbs(highestlot_sell-sec_highestlot_sell)*multiplier) + 0.01972324*(MathAbs(highestlot_sell-first_sell)*multiplier);  
   nextTPSL = highestlot_sell - nextTPSL*_Point;
   
   //Loop through all positions that are currently open
   if (Bid < nextTPSL){
      //If market rapidly speeds past our expected TP before we can set it, then we can close all open orders manually.
      
      for(int i = OrdersTotal()-1; i >= 0; i--){
         /*Get the details from the current position such as opening price, lot size, and position id 
         so we can close it*/
         
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            int posTicket = OrderTicket();
            double close_lot = OrderLots();
            OrderClose(posTicket, close_lot, Bid, 50);
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