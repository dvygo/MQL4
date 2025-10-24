//+------------------------------------------------------------------+
//|                                                  control.mq4     |
//|                               Copyright (c) 2025 TTW Markets     |
//|                                  markets.tutortechwiz.com        |
//|                                                                  |
//| This Source Code Form is subject to the terms of the Mozilla    |
//| Public License, v. 2.0. See LICENSE file for details.           |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2025 TTW Markets"
#property link      "markets.tutortechwiz.com"
#property version   "1.00"
#property description "Manual Controls for EA"
#property strict
#property script_show_inputs

//+------------------------------------------------------------------+
//| CONSTANTS - Control Commands                                    |
//+------------------------------------------------------------------+
#define CMD_PAUSE       "PAUSE"
#define CMD_RESUME      "RESUME"
#define CMD_KILL        "KILL"
#define CMD_STATUS      "STATUS"
#define CONTROL_FILE    "control.txt"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input string   Command = CMD_STATUS;    // Command: PAUSE, RESUME, KILL, STATUS

//+------------------------------------------------------------------+
//| Script program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Control script executing: ", Command);
   
   if(Command == CMD_PAUSE)
      PauseEA();
   else if(Command == CMD_RESUME)
      ResumeEA();
   else if(Command == CMD_KILL)
      KillEA();
   else if(Command == CMD_STATUS)
      ShowStatus();
   else
      Print("Unknown command: ", Command);
}

//+------------------------------------------------------------------+
//| Pause EA execution                                              |
//+------------------------------------------------------------------+
void PauseEA()
{
   Print("Pausing EA...");
   WriteControlFile("PAUSED");
   Print("EA paused successfully");
}

//+------------------------------------------------------------------+
//| Resume EA execution                                             |
//+------------------------------------------------------------------+
void ResumeEA()
{
   Print("Resuming EA...");
   WriteControlFile("RUNNING");
   Print("EA resumed successfully");
}

//+------------------------------------------------------------------+
//| Kill EA (emergency stop)                                        |
//+------------------------------------------------------------------+
void KillEA()
{
   Print("EMERGENCY STOP - Killing EA...");
   WriteControlFile("KILLED");
   
   //--- Close all open positions
   CloseAllPositions();
   
   Print("EA killed - all positions closed");
}

//+------------------------------------------------------------------+
//| Show EA status                                                  |
//+------------------------------------------------------------------+
void ShowStatus()
{
   Print("=== TTWMarkets EA Status ===");
   
   string state = ReadControlFile();
   Print("State: ", state);
   
   Print("Open positions: ", OrdersTotal());
   Print("Account balance: ", AccountBalance());
   Print("Account equity: ", AccountEquity());
   Print("Free margin: ", AccountFreeMargin());
}

//+------------------------------------------------------------------+
//| Write control file                                              |
//+------------------------------------------------------------------+
void WriteControlFile(string state)
{
   int handle = FileOpen(CONTROL_FILE, FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(handle != INVALID_HANDLE)
   {
      FileWriteString(handle, state);
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+
//| Read control file                                               |
//+------------------------------------------------------------------+
string ReadControlFile()
{
   string state = "UNKNOWN";
   int handle = FileOpen(CONTROL_FILE, FILE_READ|FILE_TXT|FILE_COMMON);
   
   if(handle != INVALID_HANDLE)
   {
      if(!FileIsEnding(handle))
         state = FileReadString(handle);
      FileClose(handle);
   }
   
   return state;
}

//+------------------------------------------------------------------+
//| Close all open positions                                        |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == OP_BUY)
            OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrRed);
         else if(OrderType() == OP_SELL)
            OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrRed);
      }
   }
}
//+------------------------------------------------------------------+
