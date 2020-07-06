//+------------------------------------------------------------------+
//|                                                 ThreeBarPlay.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
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
//| trading mechanics is the same as BUYSTOCK/SELLSTOCK scripts                                                                  |
//+------------------------------------------------------------------+
int numOfTrades=0;
int takeprofit=100;
int stoploss=100;
void trade(bool buy, int sl)
  {
   numOfTrades++;
   if(buy)
     {
      int pips=sl;
      double risk=AccountBalance()*0.02/1.3;
      double shares = (int)(risk / pips * 100);
      double maxShares = (int)(AccountFreeMargin()/1.3 * 14.8 / (Ask));
      if((MarketInfo(_Symbol,17))<0.01)//if forex
        {
         maxShares/=100;
         shares/=100;
        }
      if(shares>(MarketInfo(_Symbol,MODE_MAXLOT)))
        {
         shares=MarketInfo(_Symbol,MODE_MAXLOT);
        }
      if(maxShares < shares)
        {
         shares = maxShares;
         pips=(int)(risk/shares*100);
        }

      Alert("Buy ",shares," shares of ", _Symbol);
      double x=Ask;
      double y=shares*3/4;
      double z=shares/4;
      int pipstostoploss=pips;
      int takeprofit2= pips*2;
      int takeprofit1= pips;
      int order0=OrderSend(
                    _Symbol,//currencyPair
                    OP_BUY,//buy
                    y,//howmuch*SYMBOL_VOLUME_MIN
                    x,//price
                    3,//tolerance
                    x-pipstostoploss*_Point, //stoploss
                    x+takeprofit1*_Point,//takeprofit
                    NULL,//comment
                    0,//magic number
                    0,//expiration
                    CLR_NONE//color of arrow
                 );
      int order1=OrderSend(
                    _Symbol,//currencyPair
                    OP_BUY,//buy
                    z,//howmuch*SYMBOL_VOLUME_MIN
                    x,//price
                    3,//tolerance
                    x-pipstostoploss*_Point, //stoploss
                    x+takeprofit2*_Point,//takeprofit
                    NULL,//comment
                    0,//magic number
                    0,//expiration
                    CLR_NONE//color of arrow
                 );
     }
   else
      if(!buy)
        {
         int pips=sl;
         double risk=AccountBalance()*0.02/1.3;
         double shares = (int)(risk / pips * 100);
         double maxShares = (int)(AccountFreeMargin()/1.3 * 14.8 / (Bid));
         if((MarketInfo(_Symbol,17))<0.01)//if forex
           {
            maxShares/=100;
            shares/=100;
           }
         if(shares>(MarketInfo(_Symbol,MODE_MAXLOT)))
           {
            shares=MarketInfo(_Symbol,MODE_MAXLOT);
           }
         if(maxShares < shares)
           {
            shares = maxShares;
            pips=(int)(risk/shares*100);
           }

         Alert("Sell ",shares," shares of ", _Symbol);
         double x=Bid;
         double y=shares*3/4;
         double z=shares/4;
         int pipstostoploss=pips;
         int takeprofit2= pips*2;
         int takeprofit1= pips;

         int order0=OrderSend(
                       _Symbol,//currencyPair
                       OP_SELL,//sell
                       y,//howmuch*SYMBOL_VOLUME_MIN
                       x,//price
                       3,//tolerance
                       x+pipstostoploss*_Point, //stoploss
                       x-takeprofit1*_Point,//takeprofit
                       NULL,//comment
                       0,//magic number
                       0,//expiration
                       CLR_NONE//color of arrow
                    );
         int order1=OrderSend(
                       _Symbol,//currencyPair
                       OP_SELL,//sell
                       z,//howmuch*SYMBOL_VOLUME_MIN
                       x,//price
                       3,//tolerance
                       x+pipstostoploss*_Point, //stoploss
                       x-takeprofit2*_Point,//takeprofit
                       NULL,//comment
                       0,//magic number
                       0,//expiration
                       CLR_NONE//color of arrow
                    );
        }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
double height;
bool traded=false;
void OnTick()
  {
//find average size of candlesticks
   int numOfCandles=200;
   double total=0;
   for(int i=0; i<numOfCandles; i++)
     {
      total+=(MathAbs(Open[i]-Close[i]));
     }
   double average=(int)((total/numOfCandles)/_Point);
//delete all trades with second candle doji
   bool doji=false;
   bool hammer =false;
   bool star=false;
   double high=High[1];
   double low=Low[1];
   double open=Open[1];
   double close=Close[1];
   double body=open-close;
   double top=0;
   double bot=0;
   double topratio,botratio;
   if(body>0)
     {
      top=high-close;
      bot=open-low;
     }
   else
      if(body<0)
        {
         top=high-open;
         bot=close-low;
        }
   if(body!=0)
     {
      topratio=top/(MathAbs(body));
      botratio=bot/(MathAbs(body));
     }
   else
     {
      //if body is 0
      topratio=0;
      botratio=0;
     }
   double dojiratio=1.5;
   if((botratio>=dojiratio)&&(topratio>=dojiratio)&&(botratio>=(dojiratio+2))&&(topratio>=(dojiratio+2)))
     {
      doji=true;
     }
   else
      if((botratio>=dojiratio)&&(botratio>=(dojiratio+2)))
        {
         hammer=true;
        }
      else
         if((topratio>=(dojiratio+2))&&(topratio>=dojiratio))
           {
            star=true;
           }
   /*
      calculations:
      if spread<=16, then look for plays
      ignition is any bar [a certain number] times or more than spread
      correction is if second bar is less than 1 quarter ignition in op direction
      enter trade when bid passes the ignition close
      stoploss will be at ignition's open+spread
   */
//init variables
   double MFI=iMFI(_Symbol,_Period,14,0);
   int spread=SYMBOL_SPREAD;
   double goldenNum=2;
   double goldenNum2=2.5;
   bool bull=false;
   bool bear=false;
   bool ignition=false;
   bool correction=false;
   bool confirmation=false;
   bool rejection=false;
   int height2=(int)((Close[2]-Open[2])/_Point);
   int height1=(int)((Close[1]-Open[1])/_Point);
//one trade per 3barcombo
   if(height!=Close[1])
     {
      traded=false;
     }
//ignition : any bar [a certain number] times or more than average candle
   if(height2>=(goldenNum*average))
     {
      ignition=true;
      //bull
      bull=true;
      bear=false;
     }
   if(height2<=(goldenNum*-1*average))
     {
      ignition=true;
      bear=true;
      bull=false;
      height2*=-1;
     }
//correction : second bar is less than [a second certain number] times of ignition in op direction

   if(bull && (height1<0) && (height1>=((-1)*height2/goldenNum2)))
     {
      if(!doji && !star)
        {
         correction=true;
        }
     }
   else
      if((bear &&(height1>0) && (height1<=(height2/goldenNum2))))
        {
         if(!doji && !hammer)
           {
            correction=true;
           }
        }
//confirmation : when the price passes the ignition close
   if(((bull)&&(Ask>=(Close[2]+(spread*_Point))))||((bear)&&(Bid<=(Close[2]-(spread*_Point)))))
     {
      if(correction)
        {
         confirmation=true;
        }
     }
   else
     {
      if(((bull)&&(Bid<=(Close[1]-(1.5*spread*_Point))))||((bear)&&(Ask>=(Close[1]+(1.5*spread*_Point)))))
        {
         if((bull==true)&&(bear==false)&&(star||doji))
           {
            rejection=true;
            bear=true;
            bull=false;
           }
         else
            if((bear==true)&&(bull==false)&&(hammer||doji))
              {
               rejection=true;
               bull=true;
               bear=false;
              }
        }
     }

//make trade if all true
//trading format "trade(bool buy,int pipstostoploss));"
   if(ignition && correction && confirmation && bull && !traded)
     {
     //buy after confirmation
      stoploss=height2+(2*spread);
      takeprofit=stoploss;
      trade(true,stoploss);
      traded=true;
     }
   else
      if(ignition && correction && confirmation && bear && !traded)
        {
        //sell after confirmation
         stoploss=height2+(2*spread);
         takeprofit=stoploss;
         trade(false,stoploss);
         traded=true;
        }
      else
         if(!traded && ignition && bull && rejection)
           {
           //buy after rejection
            stoploss=height2;
            takeprofit=stoploss;
            trade(true,stoploss);
            traded=true;
           }
         else
            if(!traded && ignition && bear && rejection)
              {
              //sell after rejection
               stoploss=height2;
               takeprofit=stoploss;
               trade(false,stoploss);
               traded=true;
              }
   Comment(
      "balance :  ",AccountBalance(),"\n",
      "traded :  ",traded,"\n",
      "spread :  ",spread,"\n",
      "average candle:",average,"\n",
      "ignition : ",ignition,"\n",
      "correction : ",correction,"\n",
      "confirmation: ",confirmation,"\n",
      numOfTrades," trades "
   );
   height=Close[1];
//if there is a trade open, make a trailing stop while profitable by 20+ pips
   if(OrdersTotal()>0)
     {
      for(int i=OrdersTotal(); i>=0; i--)
        {
         int pips=(int)(takeprofit);
         //select an order
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            //make sure its the right currency pair
            if(OrderSymbol()==_Symbol)
              {
               //check if buy or sell
               if(OrderType()==OP_BUY)
                 {
                  if((Bid>(OrderOpenPrice()+pips*_Point))&&(OrderStopLoss()<OrderOpenPrice()) && (OrderStopLoss()<Ask-pips*_Point))
                    {
                     bool evenbuy=OrderModify(OrderTicket(),OrderOpenPrice(),Ask-pips*_Point,OrderTakeProfit(),0);
                    }
                 }
               else
                  if(OrderType()==OP_SELL)
                    {
                     if((Ask<(OrderOpenPrice()-pips*_Point))&&(OrderStopLoss()>OrderOpenPrice()) && (OrderStopLoss()>Bid+pips*_Point))
                       {
                        bool evensell=OrderModify(OrderTicket(),OrderOpenPrice(),Bid+pips*_Point,OrderTakeProfit(),0);
                       }
                    }

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
