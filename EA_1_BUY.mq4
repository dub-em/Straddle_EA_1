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
input int magic_num = 001; 
int interval = 39;
input int lotlimit = 100;
int numofmultiples_buy = 0;
double newLot_buy = 0;
int identifier_buy = 0;
double loop = 0;
double mult_fact = 1.58;
double spread = 0.0003;
int num_firstlot = 1;

// Variables used to store the three highest positions for quick reference
double multiplier = 100000;

double first_buy = 0;
double thrd_highestlot_buy = 0;
double sec_highestlot_buy = 0;
double highestlot_buy = 0;

//run this function each time the price changes on the chart.
void OnTick(){
   datetime rightbartime = iTime(_Symbol,_Period, 0);
   if(rightbartime != globalbartime){
      //if there is a new bar run the main function
      onBar_buy();
      globalbartime = rightbartime;
   } 
}

//the function containing all the logic
void onBar_buy(){
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
      numofmultiples_buy = 0;
      //open a buy position
      OrderSend(_Symbol, OP_BUY, lot, Ask, 50, 0, 0, NULL, magic_num);
      first_buy = Ask;
      thrd_highestlot_buy = 0;
      sec_highestlot_buy = 0;
      highestlot_buy = Ask;
      
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
      newTp = highestlot_buy + takeProfit*_Point;
      
      //modiify the first opened positions take profit and stop loss
      OrderModify(newTicket, NULL, NULL, newTp, NULL);
      
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
      if((num_2 <= num_firstlot)&&((highestlot_buy - interval*_Point) >= Ask)){
         //call the function and pass the following arguments into it
         if((Ask - Bid) < spread){
            OrderSend(_Symbol, OP_BUY, lot, Ask, 50, 0, 0, NULL, magic_num);
            thrd_highestlot_buy = sec_highestlot_buy;
            sec_highestlot_buy = highestlot_buy;
            highestlot_buy = Ask;
            for(int i = OrdersTotal()-1; i >= 0; i--){ 
               OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
               if(OrderMagicNumber() == magic_num)break;   
            }
            int newTicket = OrderTicket();
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
         double latestLot_buy = 0;
         if (numofmultiples_buy == 0){
            latestLot_buy = OrderLots();
            latestLot_buy = NormalizeDouble(latestLot_buy * mult_fact, 2);
         }else{
            latestLot_buy = newLot_buy * mult_fact;
          }
         if(num_2 > num_firstlot){
            if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy < lotlimit)){
               if((Ask - Bid) < spread)
                  OrderSend(_Symbol, OP_BUY, latestLot_buy, Ask, 50, 0, 0, NULL, magic_num);
                  thrd_highestlot_buy = sec_highestlot_buy;
                  sec_highestlot_buy = highestlot_buy;
                  highestlot_buy = Ask;
                  /** call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
                  the argument of the first open price*/
                  uniformPointCalculator_buy();
            }else{
               if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy > lotlimit)){
                  if (numofmultiples_buy == 0){
                     if ((Ask - Bid) < spread){
                        newLot_buy = OrderLots();
                        newLot_buy = newLot_buy*mult_fact;
                        identifier_buy = numofmultiples_buy+1;
                        loop = MathCeil(newLot_buy/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_buy = newLot_buy - (lotlimit * (i-1));
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
                   }else{
                     if (numofmultiples_buy > 0){
                        if ((Ask - Bid) < spread){
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
}

//defining the function that modifies all the open trades
void uniformPointCalculator_buy(){
   double nextTPSL = 56.231777683731956 + 0.3434495*(MathAbs(highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.03663685*(MathAbs(sec_highestlot_buy-thrd_highestlot_buy)*multiplier) + 0.30681265*(MathAbs(highestlot_buy-sec_highestlot_buy)*multiplier) + 0.01972324*(MathAbs(highestlot_buy-first_buy)*multiplier);  
   nextTPSL = highestlot_buy + nextTPSL*_Point;
   
   //loop through all positions that are currently open
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