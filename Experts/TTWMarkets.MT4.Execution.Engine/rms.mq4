//+------------------------------------------------------------------+
//|                                                      rms.mq4     |
//|                               Copyright (c) 2025 TTW Markets     |
//|                                  markets.tutortechwiz.com        |
//|                                                                  |
//| This Source Code Form is subject to the terms of the Mozilla    |
//| Public License, v. 2.0. See LICENSE file for details.           |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2025 TTW Markets"
#property link      "markets.tutortechwiz.com"
#property version   "1.00"
#property description "Risk Management System"
#property strict
#property script_show_inputs

//+------------------------------------------------------------------+
//| CONSTANTS - RMS Limits                                           |
//+------------------------------------------------------------------+
#define RMS_MAX_DAILY_LOSS      50000    // Max daily loss in INR
#define RMS_MAX_POSITION_SIZE   100      // Max position size
#define RMS_MAX_ORDERS_PER_DAY  50       // Max orders per day

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input double   MaxDailyLoss       = RMS_MAX_DAILY_LOSS;
input double   MaxPositionSize    = RMS_MAX_POSITION_SIZE;
input int      MaxOrdersPerDay    = RMS_MAX_ORDERS_PER_DAY;
input string   ConfigFile         = "rms.ini";

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
double   g_dailyPnL = 0.0;
int      g_orderCount = 0;
datetime g_lastReset = 0;

//+------------------------------------------------------------------+
//| Script program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("RMS Check starting...");
   
   LoadConfig();
   ResetIfNewDay();
   CalculateDailyPnL();
   
   Print("Daily PnL: ", g_dailyPnL);
   Print("Order Count: ", g_orderCount, "/", MaxOrdersPerDay);
   
   if(CheckRMSViolation())
      Print("RMS VIOLATION DETECTED!");
   else
      Print("RMS: All checks passed");
}

//+------------------------------------------------------------------+
//| Load RMS configuration                                           |
//+------------------------------------------------------------------+
void LoadConfig()
{
   int handle = FileOpen(ConfigFile, FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle != INVALID_HANDLE)
   {
      //--- TODO: Parse config file
      FileClose(handle);
      Print("RMS config loaded");
   }
}

//+------------------------------------------------------------------+
//| Reset counters if new day                                       |
//+------------------------------------------------------------------+
void ResetIfNewDay()
{
   datetime today = iTime(NULL, PERIOD_D1, 0);
   
   if(g_lastReset != today)
   {
      g_dailyPnL = 0.0;
      g_orderCount = 0;
      g_lastReset = today;
      Print("RMS counters reset for new day");
   }
}

//+------------------------------------------------------------------+
//| Calculate daily PnL                                              |
//+------------------------------------------------------------------+
void CalculateDailyPnL()
{
   g_dailyPnL = 0.0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         g_dailyPnL += OrderProfit() + OrderSwap() + OrderCommission();
   }
}

//+------------------------------------------------------------------+
//| Check for RMS violations                                        |
//+------------------------------------------------------------------+
bool CheckRMSViolation()
{
   //--- Check daily loss limit
   if(g_dailyPnL < -MaxDailyLoss)
   {
      Print("RMS VIOLATION: Daily loss limit breached (", g_dailyPnL, ")");
      return true;
   }
   
   //--- Check order count limit
   if(g_orderCount >= MaxOrdersPerDay)
   {
      Print("RMS VIOLATION: Order count limit reached");
      return true;
   }
   
   return false;
}
//+------------------------------------------------------------------+
