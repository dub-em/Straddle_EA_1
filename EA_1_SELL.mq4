//+------------------------------------------------------------------+
//|                                               My_First_Robot.mq4 |
//|                                                     The Presence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "The Presence"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

datetime globalbartime;
input double ls = 0.01;
input int magic_num = 002; 
input int interval = 39;
input int lotlimit = 100;
int numofmultiples_sell = 0;
double newLot_sell = 0;
int identifier_sell = 0;
double loop = 0;
double mult_fact = 1.58;
double spread = 0.0003;
int num_firstlot = 1;

// Variables used to store the three highest positions for quick reference
double multiplier = 100000;

double first_sell = 0;
double thrd_highestlot_sell = 0;
double sec_highestlot_sell = 0;
double highestlot_sell = 0;

//run this function each time the price changes on the chart.
void OnTick(){
   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //if there is a new bar run the main function
      onBar_sell();
      globalbartime = rightbartime;
   } 
}

//the function containing all the logic
void onBar_sell(){
   int takeProfit = 40; // 4 pips in pippettes
   double lot = ls;
   
   int num = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber() == magic_num){
         num += 1;
      } 
   } 
   //check if there are no open positions currently
   if(num == 0){
      numofmultiples_sell = 0;
      //open a buy position
      OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0, NULL, magic_num);
      first_sell = Bid;
      thrd_highestlot_sell = 0;
      sec_highestlot_sell = 0;
      highestlot_sell = Bid;
      
      //get the details such as opening price and position id from the first opened positions 
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= OrdersTotal()-1; i++){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            newTicket = OrderTicket();
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp = highestlot_sell - takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      if (Bid < newTp){
         OrderClose(newTicket, lot, Bid, 50);
      }else{
         OrderModify(newTicket, NULL, NULL, newTp, NULL);
      }
      
   }else{  
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      double firstTP = 0;
      int num_2 = 0;
      for(int i = OrdersTotal()-1; i >= 0; i--){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            firstTP = OrderTakeProfit();
            num_2 += 1;
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 <= num_firstlot)&&((highestlot_sell + interval*_Point) <= Bid)){
         //call the function and pass the following arguments into it
         OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0, NULL, magic_num);
         thrd_highestlot_sell = sec_highestlot_sell;
         sec_highestlot_sell = highestlot_sell;
         highestlot_sell = Bid;
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderMagicNumber() == magic_num)break;   
         }
         int newTicket = OrderTicket();
         if (Bid < firstTP){
            OrderClose(newTicket, lot, Bid, 50);
         }else{
            OrderModify(newTicket, NULL, NULL, firstTP, NULL);
         }
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderMagicNumber() == magic_num){
               break;
            }   
         }
         double latestLot_sell = 0;
         if (numofmultiples_sell == 0){
            latestLot_sell = OrderLots();
            latestLot_sell = NormalizeDouble(latestLot_sell * mult_fact, 2);
         }else{
            latestLot_sell = newLot_sell * mult_fact;
          }
         if(num_2 > num_firstlot){
            if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell < lotlimit)){
               OrderSend(_Symbol, OP_SELL, latestLot_sell, Bid, 50, 0, 0, NULL, magic_num);
               thrd_highestlot_sell = sec_highestlot_sell;
               sec_highestlot_sell = highestlot_sell;
               highestlot_sell = Bid;
               /** call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price*/
               uniformPointCalculator_sell();
            }else{
               if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell > lotlimit)){
                  if (numofmultiples_sell == 0){
                     newLot_sell = OrderLots();
                     newLot_sell = newLot_sell*mult_fact;
                     identifier_sell = numofmultiples_sell+1;
                     loop = MathCeil(newLot_sell/lotlimit);
                     for(int i=1; i<=loop; i++){
                        if(i == loop){
                           double lastLot_sell = newLot_sell - (lotlimit * (i-1));
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

//defining the function that modifies all the open trades
void uniformPointCalculator_sell(){
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.30681265*(MathAbs(highestlot_sell-sec_highestlot_sell)*multiplier) + 0.01972324*(MathAbs(highestlot_sell-first_sell)*multiplier);  
   nextTPSL = highestlot_sell - nextTPSL*_Point;
   
   //loop through all positions that are currently open
   if (Bid < nextTPSL){
      for(int i = OrdersTotal()-1; i >= 0; i--){
         /**get the details from the current position such as opening price, lot size, and position id 
            so we can modify it*/
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            int posTicket = OrderTicket();
            double close_lot = OrderLots();
            OrderClose(posTicket, close_lot, Bid, 50);
         }        
      }
   }else{
      for(int i = OrdersTotal()-1; i >= 0; i--){
         /**get the details from the current position such as opening price, lot size, and position id 
            so we can modify it*/
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderMagicNumber() == magic_num){
            int posTicket = OrderTicket();
            OrderModify(posTicket, NULL, NULL, nextTPSL, NULL);
         }        
      }   
   }    
}