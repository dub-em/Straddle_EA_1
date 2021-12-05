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
#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input double ls = 0.01;
input int thisEAMagicNumber = 1111000;
int interval = 38.5;
input int lotlimit = 100;
int numofmultiples_buy = 0;
int numofmultiples_sell = 0;
double newLot_buy = 0;
double newLot_sell = 0;
int identifier_buy = 0;
int identifier_sell = 0;
double loop = 0;
double mult_fact = 1.58;
double spread = 0.0003;

// Variables used to store the three highest positions for quick reference
double multiplier = 100000;


double first_buy = 0;
double thrd_highestlot_buy = 0;
double sec_highestlot_buy = 0;
double highestlot_buy = 0;


double first_sell = 0;
double thrd_highestlot_sell = 0;
double sec_highestlot_sell = 0;
double highestlot_sell = 0;


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
      numofmultiples_buy = 0;
      //open a buy position
      trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
      first_buy = Ask;
      thrd_highestlot_buy = 0;
      sec_highestlot_buy = 0;
      highestlot_buy = Ask;
      
      //get the details such as opening price and position id from the first opened positions
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            newTicket = PositionGetInteger(POSITION_TICKET);
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp = highestlot_buy + takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      trade.PositionModify(newTicket, 0, newTp);
      
   }else{
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      double firstTP = 0;
      int num_2 = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            firstTP = PositionGetDouble(POSITION_TP);
            num_2 += 1;
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 <= 2)&&((highestlot_buy - interval*_Point) >= Ask)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < spread)
            trade.Buy(lot, NULL, Ask, NULL, firstTP, NULL);
            thrd_highestlot_buy = sec_highestlot_buy;
            sec_highestlot_buy = highestlot_buy;
            highestlot_buy = Ask;
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
               break;
            }   
         }
         double latestLot_buy = 0;
         if (numofmultiples_buy == 0){
            latestLot_buy = PositionGetDouble(POSITION_VOLUME);
            latestLot_buy = NormalizeDouble(latestLot_buy * mult_fact, 2);
         }else{
            latestLot_buy = newLot_buy;
            latestLot_buy = latestLot_buy * mult_fact;
         }
         //open more positions
         if (num_2 > 2){
            if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy < lotlimit)){
               if( (Ask - Bid) < spread)
                  trade.Buy(latestLot_buy, NULL, Ask, NULL, NULL, NULL);
                  thrd_highestlot_buy = sec_highestlot_buy;
                  sec_highestlot_buy = highestlot_buy;
                  highestlot_buy = Ask;
                  /** 
                  call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
                  the argument of the first open price
                  */
                  uniformPointCalculator_buy();
            }else{
               if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy > lotlimit)){
                  if (numofmultiples_buy == 0){
                     newLot_buy = PositionGetDouble(POSITION_VOLUME);
                     newLot_buy = newLot_buy*mult_fact;
                     if ((Ask - Bid) < spread){
                        identifier_buy = numofmultiples_buy+1;
                        loop = MathCeil(newLot_buy/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_buy = newLot_buy - (lotlimit * (i-1));
                              trade.Buy(NormalizeDouble(lastLot_buy, 2), NULL, Ask, NULL, NULL, identifier_buy);
                           }else{
                              trade.Buy(lotlimit, NULL, Ask, NULL, NULL, identifier_buy);
                            }    
                        }
                        thrd_highestlot_buy = sec_highestlot_buy;
                        sec_highestlot_buy = highestlot_buy;
                        highestlot_buy = Ask;
                        numofmultiples_buy += 1;
                        uniformPointCalculator_buy();
                     }
                   }else{
                     if (numofmultiples_buy > 0){
                        newLot_buy = newLot_buy*mult_fact;
                        if ((Ask - Bid) < spread){
                           identifier_buy = numofmultiples_buy+1;
                           loop = MathCeil(newLot_buy/lotlimit);
                           for(int i=1; i<=loop; i++){
                              if(i == loop){
                                 double lastLot_buy = newLot_buy - (lotlimit * (loop-1));
                                 trade.Buy(NormalizeDouble(lastLot_buy, 2), NULL, Ask, NULL, NULL, identifier_buy);
                              }else{
                                 trade.Buy(lotlimit, NULL, Ask, NULL, NULL, identifier_buy);
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
      numofmultiples_sell = 0;
      //open a buy position
      trade.Sell(lot, NULL, Bid, NULL, NULL, NULL);
      first_sell = Bid;
      thrd_highestlot_sell = 0;
      sec_highestlot_sell = 0;
      highestlot_sell = Bid;
      
      //get the details such as opening price and position id from the first opened positions
      double newTp = 0;
      ulong newTicket = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            newTicket = PositionGetInteger(POSITION_TICKET);
            break;
         }   
      }
      //add the take profit defined earlier to the opening price
      newTp = highestlot_sell - takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      trade.PositionModify(newTicket, 0, newTp);  
   }else{
      //get the details such as opening price and position id from the first opened positions so we can modify other positions
      double firstTP = 0;
      int num_2 = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            firstTP = PositionGetDouble(POSITION_TP);
            num_2 += 1;
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 <= 2)&&((highestlot_sell + interval*_Point) <= Bid)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < spread)
            trade.Sell(lot, NULL, Bid, NULL, firstTP, NULL);
            thrd_highestlot_sell = sec_highestlot_sell;
            sec_highestlot_sell = highestlot_sell;
            highestlot_sell = Bid;
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
               break;
            }   
         }
         double latestLot_sell = 0;
         if (numofmultiples_sell == 0){
            latestLot_sell = PositionGetDouble(POSITION_VOLUME);
            latestLot_sell = NormalizeDouble(latestLot_sell * mult_fact, 2);
         }else{
            latestLot_sell = newLot_sell;
            latestLot_sell = latestLot_sell * mult_fact;
         }
         //open more positions
         if (num_2 > 2){
            if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell < lotlimit)){
               if( (Ask - Bid) < spread)
                  trade.Sell(latestLot_sell, NULL, Bid, NULL, NULL, NULL);
                  thrd_highestlot_sell = sec_highestlot_sell;
                  sec_highestlot_sell = highestlot_sell;
                  highestlot_sell = Bid;
                  /** 
                  call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
                  the argument of the first open price
                  */
                  uniformPointCalculator_sell();
            }else{
               if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell > lotlimit)){
                  if (numofmultiples_sell == 0){
                     newLot_sell = PositionGetDouble(POSITION_VOLUME);
                     newLot_sell = newLot_sell*mult_fact;
                     if ((Ask - Bid) < spread){
                        identifier_sell = numofmultiples_sell+1;
                        loop = MathCeil(newLot_sell/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_sell = newLot_sell - (lotlimit * (i-1));
                              trade.Sell(NormalizeDouble(lastLot_sell, 2), NULL, Bid, NULL, NULL, identifier_sell);
                           }else{
                              trade.Sell(lotlimit, NULL, Bid, NULL, NULL, identifier_sell);
                            }
                        }
                        thrd_highestlot_sell = sec_highestlot_sell;
                        sec_highestlot_sell = highestlot_sell;
                        highestlot_sell = Bid;
                        numofmultiples_sell += 1;
                        uniformPointCalculator_sell();
                     }
                   }else{
                     if (numofmultiples_sell > 0){
                        newLot_sell = newLot_sell*mult_fact;
                        if ((Ask - Bid) < spread){
                           identifier_sell = numofmultiples_sell+1;
                           loop = MathCeil(newLot_sell/lotlimit);
                           for(int i=1; i<=loop; i++){
                              if(i == loop){
                                 double lastLot_sell = newLot_sell - (lotlimit * (loop-1));
                                 trade.Sell(NormalizeDouble(lastLot_sell, 2), NULL, Bid, NULL, NULL, identifier_sell);
                              }else{
                                 trade.Sell(lotlimit, NULL, Bid, NULL, NULL, identifier_sell);
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
}   

//defining the function that modifies all the open trades
void uniformPointCalculator_buy(){
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.30681265*(MathAbs(highestlot_buy-sec_highestlot_buy)*multiplier) + 0.01972324*(MathAbs(highestlot_buy-first_buy)*multiplier);  
   nextTPSL = highestlot_buy + nextTPSL*_Point;
   
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
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_sell-thrd_highestlot_sell)*multiplier) + 0.30681265*(MathAbs(highestlot_sell-sec_highestlot_sell)*multiplier) + 0.01972324*(MathAbs(highestlot_sell-first_sell)*multiplier);  
   nextTPSL = highestlot_sell - nextTPSL*_Point;  
   
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
