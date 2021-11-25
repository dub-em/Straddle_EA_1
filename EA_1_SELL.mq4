//+------------------------------------------------------------------+
//|                                               My_First_Robot.mq4 |
//|                                                     The Presence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "The Presence"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
datetime globalbartime;
input double ls = 0.01;

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
   /**
   double l_Size = (AccountInfoDouble(ACCOUNT_BALANCE)*0.02)/150000;
   if(l_Size < 0.01){
      l_Size = 0.01;
   }else{
      l_Size = NormalizeDouble(l_Size, 2);
   }
   //set some parameters to be used later
   */
   int takeProfit = 50; // 5 pips in pippettes
   double lot = ls;
   
   int num = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--){
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() == OP_SELL){
         num += 1;
      } 
   } 
   
   //check if there are no open positions currently
   if(num == 0){
   
      //open a buy position
      OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0);
      
      //get the details such as opening price and position id from the first opened positions 
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= OrdersTotal()-1; i++){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderType() == OP_SELL){
            newTp = OrderOpenPrice();
            newTicket = OrderTicket();
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp -= takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      OrderModify(newTicket, NULL, NULL, newTp, NULL);
      
   }else{  
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      int num_2 = 0;
      double firstOpenPrice = 0;
      double currentPrice = 0;
      double firstTP = 0;
      for(int i = OrdersTotal()-1; i >= 0; i--){ 
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderType() == OP_SELL){
            num_2 += 1;
            firstOpenPrice = OrderOpenPrice();
            currentPrice = OrderClosePrice();
            firstTP = OrderTakeProfit();
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 == 1)&&((firstOpenPrice + 60*_Point) <= currentPrice)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < 0.0003){
            OrderSend(_Symbol, OP_SELL, lot, Bid, 50, 0, 0);
            for(int i = OrdersTotal()-1; i >= 0; i--){ 
               OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
               if(OrderType() == OP_SELL)break;   
            }
            int newTicket = OrderTicket();
            OrderModify(newTicket, NULL, NULL, firstTP, NULL);
         }
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         double currentPrice_2 = 0;
         double openPrice = 0;
         for(int i = OrdersTotal()-1; i >= 0; i--){ 
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if(OrderType() == OP_SELL){
               currentPrice_2 = OrderClosePrice();
               openPrice = OrderOpenPrice();
               break;
            }   
         }
         if(((openPrice + 60*_Point) <= currentPrice_2)){
            double latestLot = OrderLots();
            //open more positions
            latestLot = NormalizeDouble(latestLot * 1.6, 2);
            if((Ask - Bid) < 0.0003){
               OrderSend(_Symbol, OP_SELL, latestLot, Bid, 50, 0, 0);
               /** 
               call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price
               */
               uniformPointCalculator_sell();
            }
         }       
       }    
   }   
}

//defining the function that modifies all the open trades
void uniformPointCalculator_sell(){
   int count = 0;
   double nextTPSL = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--){ 
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() == OP_SELL){
         nextTPSL = OrderOpenPrice();
         count += 1;
      }
      if(count == 3)break;   
   } 
   nextTPSL = nextTPSL - 5*_Point;
   //loop through all positions that are currently open
   for(int i = OrdersTotal()-1; i >= 0; i--){
      /**
         get the details from the current position such as opening price, lot size, and position id 
         so we can modify it
      */
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() == OP_BUY){
         int posTicket = OrderTicket();
         OrderModify(posTicket, NULL, NULL, nextTPSL, NULL);
      }else if(OrderType() == OP_SELL){
         int posTicket = OrderTicket();
         OrderModify(posTicket, NULL, NULL, nextTPSL, NULL);
      }        
   }    
}