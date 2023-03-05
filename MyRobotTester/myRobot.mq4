//+------------------------------------------------------------------+
//|                                            Meu Robo em teste.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"
#include <stdlib.mqh>

#define MAGICMA  20131111
//--- Inputs
//input double Lots          =0.1;
input double StopLossPoints = 100;
input double TakeProfitPercent = 1;
input double DailyStopLossLimit = 3;
input double DailyTakeProfitLimit = 1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    MovingFastPeriod  =50;
input int    MovingLongPeriod  =200;
input int    MovingShift   =6;
double saldoInicialDaConta = 0;
double metaTakeDiario = 0;
double stopDiario = 0;
double limiteMetaTakeDiario = 0;
double limiteStopDiario = 0;
double resultadoAtual = 0;
double lots = 0.01;
int dia = 0;
bool trava = true;

//-----------------------------------
void OnInit(void)
  {
   //dia = Day();
   SetBalance();
  }
//-----------------------------------

void SetBalance(void)
  {
   //dia = Day();
   //trava = false;
   saldoInicialDaConta = AccountBalance();
   Print("Setando o novo Balanço:   = ",saldoInicialDaConta);
   metaTakeDiario = saldoInicialDaConta * DailyTakeProfitLimit * 0.01;
   stopDiario = saldoInicialDaConta * DailyStopLossLimit  *0.01;
   limiteMetaTakeDiario = saldoInicialDaConta + metaTakeDiario;
   limiteStopDiario = saldoInicialDaConta - stopDiario;
  }


bool CheckLimits()
   {
   if(AccountBalance() >= saldoInicialDaConta) resultadoAtual = AccountBalance()- saldoInicialDaConta;
   if(AccountBalance() < saldoInicialDaConta) resultadoAtual = -(saldoInicialDaConta - AccountBalance());
   Print("saldoInicialDaConta:  = ",saldoInicialDaConta);
   Print("AccountBalance:  = ",AccountBalance());
   Print("Resultado atual:  = ",resultadoAtual);
   if(AccountBalance() >= limiteMetaTakeDiario) {
      Print("Take Limit Atingido! Lucro de:  = ",resultadoAtual);
      //SetBalance();
      //trava = true;
      return false;
   }
   if(AccountBalance() <= limiteStopDiario) {
      Print("Stop Limit atingido! perca de:   = ",resultadoAtual);
      //SetBalance();
      //trava = true;
      return false;
   }
   return true;
   }

double CalculateLots()
   {
   if (resultadoAtual < 0)
      {
      lots =MathAbs( NormalizeDouble ( (resultadoAtual / StopLossPoints), 2) );
      Print("Lot ideal:   = ",lots);
      if(lots < 0.01) return 0.01;
      return lots;
      }
   if (resultadoAtual >= 0)
      {
      SetBalance();
      lots = 0.03;
      return lots;
      }
   return lots;
   }

int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
  
void CheckForOpen()
  {
   double maFast;
   double maLong;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- checkando resultado atual:
   if(CheckLimits() == false) return;
//--- get Moving Average 
   maFast=iMA(NULL,0,MovingFastPeriod,1,MODE_SMA,PRICE_CLOSE,0);
   Print("maFast:  = ",maFast);
   maLong=iMA(NULL,0,MovingLongPeriod,1,MODE_SMA,PRICE_CLOSE,0);
   Print("maLong:  = ",maLong);
   //--- get minimum stop level
   //double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   //Print("Minimum Stop Level=",minstoplevel," points");
   //CheckLots();
   double price=Ask;
//--- calculated SL and TP prices must be normalized
   double stoploss=NormalizeDouble(Bid-StopLossPoints*Point,Digits);
   double takeprofit=NormalizeDouble(Bid+StopLossPoints*TakeProfitPercent*Point,Digits);
   
//--- sell conditions
   if(maFast < maLong)
   {
      res=OrderSend(Symbol(),OP_SELL,CalculateLots(),Bid,3,stoploss,takeprofit,"",MAGICMA,0,Red);
      return;
   }
   
//--- buy conditions
   if(maFast > maLong)
   {
      res=OrderSend(Symbol(),OP_BUY,CalculateLots(),Ask,3,stoploss,takeprofit,"",MAGICMA,0,Blue);
      return;
   }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+

//void CheckForClose()
//  {
//  double ma;
//--- go trading only for first tiks of new bar
//   if(Volume[0]>1) return;
//--- get Moving Average 
//   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
//   for(int i=0;i<OrdersTotal();i++)
//     {
//     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
//      //--- check order type 
//      if(OrderType()==OP_BUY)
//        {
//
//          if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
//             Print("OrderClose error ",GetLastError());
//         break;
//        }
//      if(OrderType()==OP_SELL)
//        {
//
//           if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
//              Print("OrderClose error ",GetLastError());
//         break;
//        }
//     }
//---
// }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
  if(dia != Day()){
  }
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   //else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
