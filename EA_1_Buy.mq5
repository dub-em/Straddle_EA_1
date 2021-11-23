//+------------------------------------------------------------------+
//|                                             My First Robot_2.mq5 |
//|                                     Copyright 2021, The Presence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, The Presence"
#property link      "https://www.mql5.com"
#property version   "1.00"
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
// BUY EXPERT ADVISER
#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input double ls = 0.01;

//run this function each time the price changes on the chart.
void OnTick(){

   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //if there is a new bar run the main function
      onBar();
      globalbartime = rightbartime;
   } 
}

//the function containing all the logic
void onBar(){

   //get the bid and ask price
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
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
   
   //check if there are no open positions currently
   if(PositionsTotal() == 0){
   
      //open a buy position
      trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
      
      //get the details such as opening price and position id from the first opened positions 
      string sym = PositionGetSymbol(0);
      double newTp = PositionGetDouble(POSITION_PRICE_OPEN);
      ulong newTicket = PositionGetInteger(POSITION_TICKET);
      
      //add the take profit defined earlier to the opening price
      newTp += takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      trade.PositionModify(newTicket, 0, newTp);
      
   }else{
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      string firstSymbol = PositionGetSymbol(0);
      double firstOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      
      // check if trades open is only one then call the function to open the second position
      if((PositionsTotal() == 1)&&((firstOpenPrice - 60*_Point) >= currentPrice)){
         double firstTP = PositionGetDouble(POSITION_TP);
         //call the function and pass the following arguments into it
         if( (Ask - Bid) < 0.0003)
            trade.Buy(lot, NULL, Ask, NULL, firstTP, NULL);
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         string symbols = PositionGetSymbol(PositionsTotal()-1);
         double currentPrice_2 = PositionGetDouble(POSITION_PRICE_CURRENT);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         if((PositionsTotal() >= 2) && ((openPrice - 60*_Point) >= currentPrice_2)){
            double latestLot = PositionGetDouble(POSITION_VOLUME);
            //open more positions
            latestLot = NormalizeDouble(latestLot * 1.6, 2);
            if( (Ask - Bid) < 0.0003)
               trade.Buy(latestLot, NULL, Ask, NULL, NULL, NULL);
               /** 
               call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price
               */
               uniformPointCalculator();
         }       
       }    
   }   
}

//defining the function that modifies all the open trades
void uniformPointCalculator(){
   string symbolc = PositionGetSymbol(PositionsTotal() - 3);
   double nextTPSL = PositionGetDouble(POSITION_PRICE_OPEN);
   nextTPSL = nextTPSL + 5*_Point;
   //loop through all positions that are currently open
   for(int i = PositionsTotal()-1; i >= 0; i--){
      /**
         get the details from the current position such as opening price, lot size, and position id 
         so we can modify it
      */
      string symbols = PositionGetSymbol(i);
      if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         trade.PositionModify(posTicket, 0, nextTPSL);
      }else if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         trade.PositionModify(posTicket, 0, nextTPSL);
      }        
   }    
}