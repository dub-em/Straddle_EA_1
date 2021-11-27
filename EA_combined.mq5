#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input double ls = 0.01;
input int thisEAMagicNumber = 1111000;

//run this function each time the price changes on the chart.
void OnTick(){
   
   trade.SetExpertMagicNumber(thisEAMagicNumber);
   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //if there is a new bar run the main function
      onBar_buy();
      onBar_sell();
      globalbartime = rightbartime;
   } 
}

//the function containing all the logic
void onBar_buy(){
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
   int takeProfit = 40; // 4 pips in pippettes
   double lot = ls; 
   
   //loops through all the open positions (buy and sell) to check the total number of position to a type of order
   int num = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         num += 1;
      }
   }
   //check if there are no open positions currently 
   if(num == 0){
      //open a buy position
      trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
      
      //get the details such as opening price and position id from the first opened positions
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY){
            newTp = PositionGetDouble(POSITION_PRICE_OPEN);
            newTicket = PositionGetInteger(POSITION_TICKET);
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp += takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      trade.PositionModify(newTicket, 0, newTp);
      
   }else{
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      int num_2 = 0;
      double firstOpenPrice = 0;
      double currentPrice = 0;
      double firstTP = 0;
      for(int i = PositionsTotal()-1; i >= 0; i--){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            num_2 += 1;
            firstOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            firstTP = PositionGetDouble(POSITION_TP);
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 == 1)&&((firstOpenPrice - 50*_Point) >= currentPrice)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < 0.0005)
            trade.Buy(lot, NULL, Ask, NULL, firstTP, NULL);
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         double currentPrice_2 = 0;
         double openPrice = 0;
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY){
               currentPrice_2 = PositionGetDouble(POSITION_PRICE_CURRENT);
               openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               break;
            }   
         }
         if(((openPrice - 50*_Point) >= currentPrice_2)){
            double latestLot = PositionGetDouble(POSITION_VOLUME);
            //open more positions
            latestLot = NormalizeDouble(latestLot * 1.6, 2);
            if( (Ask - Bid) < 0.0005)
               trade.Buy(latestLot, NULL, Ask, NULL, NULL, NULL);
               /** 
               call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price
               */
               uniformPointCalculator_buy();
         }       
       }    
   }   
}

void onBar_sell(){

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
   int takeProfit = 40; // 4 pips in pippettes
   double lot = ls; 
   
   //loops through all the open positions (buy and sell) to check the total number of position to a type of order
   int num = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         num += 1;
      } 
   }
   //check if there are no open positions currently 
   if(num == 0){
   
      //open a buy position
      trade.Sell(lot, NULL, Bid, NULL, NULL, NULL);
      
      //get the details such as opening price and position id from the first opened positions
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            newTp = PositionGetDouble(POSITION_PRICE_OPEN);
            newTicket = PositionGetInteger(POSITION_TICKET);
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp -= takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      trade.PositionModify(newTicket, 0, newTp);
      
   }else{
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      int num_2 = 0;
      double firstOpenPrice = 0;
      double currentPrice = 0;
      double firstTP = 0;
      for(int i = PositionsTotal()-1; i >= 0; i--){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            num_2 += 1;
            firstOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            firstTP = PositionGetDouble(POSITION_TP);
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 == 1)&&((firstOpenPrice + 50*_Point) <= currentPrice)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < 0.0005)
            trade.Sell(lot, NULL, Bid, NULL, firstTP, NULL);
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         double currentPrice_2 = 0;
         double openPrice = 0;
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
               currentPrice_2 = PositionGetDouble(POSITION_PRICE_CURRENT);
               openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
               break;
            }   
         }
         if(((openPrice + 50*_Point) <= currentPrice_2)){
            double latestLot = PositionGetDouble(POSITION_VOLUME);
            //open more positions
            latestLot = NormalizeDouble(latestLot * 1.6, 2);
            if( (Ask - Bid) < 0.0005)
               trade.Sell(latestLot, NULL, Bid, NULL, NULL, NULL);
               /** 
               call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price
               */
               uniformPointCalculator_sell();
         }       
       }    
   }   
}

//defining the function that modifies all the open trades
void uniformPointCalculator_buy(){
   int count = 0;
   double nextTPSL = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){ 
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         nextTPSL = PositionGetDouble(POSITION_PRICE_OPEN);
         count += 1;
      }
      if(count == 3)break;   
   }
   nextTPSL = nextTPSL + 10*_Point;
   //loop through all positions that are currently open
   for(int i = PositionsTotal()-1; i >= 0; i--){
      //get the details from the current position such as opening price, lot size, and position id 
      //so we can modify it
      string symbols = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         trade.PositionModify(posTicket, 0, nextTPSL);
      }        
   }    
}

//defining the function that modifies all the open trades
void uniformPointCalculator_sell(){
   int count = 0;
   double nextTPSL = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){ 
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         nextTPSL = PositionGetDouble(POSITION_PRICE_OPEN);
         count += 1;
      }
      if(count == 3)break;   
   }
   nextTPSL = nextTPSL - 10*_Point;
   //loop through all positions that are currently open
   for(int i = PositionsTotal()-1; i >= 0; i--){
      //get the details from the current position such as opening price, lot size, and position id 
      //so we can modify it
      string symbols = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         trade.PositionModify(posTicket, 0, nextTPSL);
      }        
   }    
}