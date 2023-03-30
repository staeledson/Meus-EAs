//+------------------------------------------------------------------+
//|                                         BOT calculando lotes.mq4 |
//|                                Copyright 2021, [Dev]Stael Edson. |
//|                          https://www.linkedin.com/in/staeledson/ |
//+------------------------------------------------------------------+
#property copyright "2021, [Dev]Stael Edson."
#property link "https://www.linkedin.com/in/staeledson/"
#property description "Bot que calcula tamanho de Lot ideal"
//#include <stdlib.mqh>

#define MAGICMA 20131111
//--- Inputs
input double StopLossPoints = 60;
input double TakeProfitPercent = 1;
input double DailyStopLossLimit = 1;
input double DailyTakeProfitLimit = 1;
input double MaximumRisk = 0.02;
input int MovingFastPeriod = 50;
input int MovingLongPeriod = 200;
input int MovingShift = 6;
extern bool UsarBE = true;

int BEPoint = StopLossPoints*0.70;

bool trava = true;

double saldoInicialDaConta = 0;
double metaTakeDiario = 0;
double stopDiario = 0;
double limiteMetaTakeDiario = 0;
double limiteStopDiario = 0;
double resultadoAtual = 0;
double stopLoss = 0;
double takeProfit = 0;
double lotIdeal = 0.01;
double saldoAtualizado = 0;
double saldoAntesDaOP = 0;
double acumulado = 0;

//-----------------------------------
void OnInit(void)
{
  SetInitialBalance();
}
//-----------------------------------

//+------------------------------------------------------------------+
//|  Função para setar as configurações iniciais de metas do BOT.    |
//+------------------------------------------------------------------+

void SetInitialBalance(void)
{
  saldoInicialDaConta = AccountBalance();
  metaTakeDiario = NormalizeDouble((saldoInicialDaConta * DailyTakeProfitLimit * 0.01), 2);
  stopDiario = NormalizeDouble((saldoInicialDaConta * DailyStopLossLimit * 0.01), 2);
  limiteMetaTakeDiario = NormalizeDouble((saldoInicialDaConta + metaTakeDiario), 2);
  limiteStopDiario = NormalizeDouble((saldoInicialDaConta - stopDiario), 2);
  saldoAntesDaOP = saldoInicialDaConta;
  trava = false;

  // Prints de informação relativa as metas iniciais do BOT.
  Print("Limite de TakeProfit: $", metaTakeDiario, " Trava de Take aos: $", limiteMetaTakeDiario);
  Print("Limite de StopLoss: $", stopDiario, " Trava de Stop aos: $", limiteStopDiario);
  Print("Saldo Inicial da Conta: $", saldoInicialDaConta);
  Print("Setando Metas do Robo: ");
}

double ShowBalance()
{
  if (AccountBalance() >= saldoInicialDaConta)
    return NormalizeDouble( (AccountBalance() - saldoInicialDaConta), 2 );
  if (AccountBalance() < saldoInicialDaConta)
    return NormalizeDouble( -(saldoInicialDaConta - AccountBalance()),2);
  return 0;
}

//+----------------------------------------------------------------------------------------+
//|  Função para monitorar os limites de Stop e Take diários e travar as operações do BOT. |
//+----------------------------------------------------------------------------------------+

bool CheckLimits()
{
  if (AccountBalance() >= limiteMetaTakeDiario)
  {
    Print("Take Limit Atingido! Lucro de: $ ", (AccountBalance() - saldoInicialDaConta));
    trava = true;
    return false;
  }
  if (AccountBalance() <= limiteStopDiario)
  {
    Print("Stop Limit atingido! perca de: $ ", (-(saldoInicialDaConta - AccountBalance())));
    trava = true;
    return false;
  }
  trava = false;
  return true;
}

//+------------------------------------------------------------------+
//|  Função para identificar o candle.                               |
//+------------------------------------------------------------------+

string isGreen(int candle)
{
  if (Open[candle] > Close[candle])
    return "red";
  if (Open[candle] < Close[candle])
    return "green";
  return "doji";
}
//+------------------------------------------------------------------+
//| Função para checar e atualizar o resultado de cada operação.     |
//+------------------------------------------------------------------+

void checkOpResult()
{
  saldoAtualizado = NormalizeDouble(AccountBalance(), 2);
  double resultadoUltimaOp = NormalizeDouble((AccountBalance() - saldoAntesDaOP), 2);
  Print("Resultado da Ultima Operacao: $", NormalizeDouble((AccountBalance() - saldoAntesDaOP), 2));

  acumulado += resultadoUltimaOp;
  Print("Resultado atual diário: $", ShowBalance());
  Print("Acumulado: $", acumulado);

  // Se o montando acumulado for positivo, ou seja, se recuperou as operações perdidas e está no lucro, zera o acumulado.
  if (acumulado > 0)
  {
    acumulado = 0;
    Print("Saldo acumulado Positivo, resetando acumulado: $", acumulado);
  }
}

//+------------------------------------------------------------------+
//| Função para calcular a quantidade ideal do Lot a ser executado.  |
//+------------------------------------------------------------------+

double CalculateLots()
{
  checkOpResult();
  if (acumulado < -5)
  {
    lotIdeal = MathAbs(NormalizeDouble((acumulado / StopLossPoints), 2));
    Print("Lot ideal:   = ", lotIdeal);
    if (lotIdeal < 0.01)
      return 0.01;
    return lotIdeal;
  }

  if (acumulado >= -5)
  {
    lotIdeal = MathAbs(NormalizeDouble((metaTakeDiario / 4 / StopLossPoints), 2));
    Print("Lot ideal:   = ", lotIdeal);
    if (lotIdeal < 0.01)
      return 0.01;
    return lotIdeal;
  }
  lotIdeal = 0.01;
  return lotIdeal;
}

//+------------------------------------------------------------------+
//| Função para normalizar os pontos de  stop e take;                |
//+------------------------------------------------------------------+

void CalculateStopAndTake(string opType)
{
  if (opType == "sell")
  {
    stopLoss = NormalizeDouble(Bid + StopLossPoints * Point, Digits);
    takeProfit = NormalizeDouble(Bid - StopLossPoints * TakeProfitPercent * Point, Digits);
    return;
  }
  if (opType == "call")
  {
    stopLoss = NormalizeDouble(Ask - StopLossPoints * Point, Digits);
    takeProfit = NormalizeDouble(Ask + StopLossPoints * TakeProfitPercent * Point, Digits);
    return;
  }
}

//void CalculateStopAndTake(string opType)
//{
//  if (opType == "sell")
//  {
//    stopLoss = NormalizeDouble(Bid + StopLossPoints * Point, Digits);
//    takeProfit = NormalizeDouble(Ask - StopLossPoints * TakeProfitPercent * Point, Digits);
//    return;
//  }
//  if (opType == "call")
//  {
//    stopLoss = NormalizeDouble(Ask - StopLossPoints * Point, Digits);
//    takeProfit = NormalizeDouble(Bid + StopLossPoints * TakeProfitPercent * Point, Digits);
//    return;
//  }
//}

//+------------------------------------------------------------------+
//| Função de ordens diretas, para teste do BOT.                     |
//+------------------------------------------------------------------+

void directOrder(string orderType)
{
  int res;
  if (orderType == "sell")
  {
    CalculateStopAndTake("sell");
    res = OrderSend(Symbol(), OP_SELL, CalculateLots(), Bid, 3, stopLoss, takeProfit, "", MAGICMA, 0, Red);
    saldoAntesDaOP = NormalizeDouble(AccountBalance(), 2);
    return;
  }

  if (orderType == "call")
  {
    CalculateStopAndTake("call");
    res = OrderSend(Symbol(), OP_BUY, CalculateLots(), Ask, 3, stopLoss, takeProfit, "", MAGICMA, 0, Blue);
    saldoAntesDaOP = NormalizeDouble(AccountBalance(), 2);
    return;
  }
}

//+------------------------------------------------------------------+
//| CalculateCurrentOrders function                                  |
//+------------------------------------------------------------------+

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

//+---------------------------------------------------------------------------+
//| CalculateCurrentOrders Função para monitorar as oportunidades de entrada  |
//+---------------------------------------------------------------------------+

void CheckForOpen()
{
  if (trava == true) return;

  double maFast;
  double maLong;

  //--- go trading only for first tiks of new bar
  if (Volume[0] > 1)
    return;
  //--- checkando resultado atual:
  if (CheckLimits() == false)
    return;
  //--- get Moving Average
  maFast = iMA(NULL, 0, MovingFastPeriod, 1, MODE_SMA, PRICE_CLOSE, 0);
  // Print("maFast:  = ",maFast);
  maLong = iMA(NULL, 0, MovingLongPeriod, 1, MODE_SMA, PRICE_CLOSE, 0);
  // Print("maLong:  = ",maLong);
  //--- get minimum stop level
  // double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
  // Print("Minimum Stop Level=",minstoplevel," points");
  // CheckLots();
  double price = Ask;
  
  //if(maFast < maLong) directOrder("sell");
  //if(maFast > maLong) directOrder("call");

  //--- sell conditions
  if((maFast < maLong) && (isGreen(1) == "green") && (isGreen(2) == "green") )
  {
     directOrder("sell");
     return;
  }

  //--- buy conditions
  if((maFast > maLong) && (isGreen(1) == "red") && (isGreen(2) == "red") )
  {
     directOrder("call");
     return;
  }
 //---
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
  //--- check for history and trading
  if (Bars < 100 || IsTradeAllowed() == false)
    return;
  //--- Chama função para verificar se necessita mover stop para breaking even.
  if(UsarBE)
   Break_Even();
   
  //--- calculate open orders by current symbol
  if (CalculateCurrentOrders(Symbol()) == 0)
    CheckForOpen();
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Função para monitorar momento de acionar o Breaking Even         |
//+------------------------------------------------------------------+

void Break_Even()
{
 bool m;
 for (int i= OrdersTotal()-1; i>=0;i--)
   {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES))
         {
          if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA)
              {
               if(OrderType() == OP_BUY)
                 {
                  if(OrderOpenPrice() <= (Bid - (BEPoint)*_Point) && OrderOpenPrice() > OrderStopLoss())
                     {
                     m = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Yellow);
                     return;
                     }
                 }
               if(OrderType() == OP_SELL)
                  {
                   if(OrderOpenPrice() >= (Ask + (BEPoint)*_Point) && (OrderOpenPrice() < OrderStopLoss() || OrderStopLoss() == 0))
                     {
                     m = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Yellow);
                     return;
                     }
                  }
              }
         }     
   }
}

//+------------------------------------------------------------------+