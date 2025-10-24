//+------------------------------------------------------------------+
//|                                     InstrumentResolver.mqh       |
//|                               Copyright (c) 2025 TTW Markets     |
//|                                  markets.tutortechwiz.com        |
//|                                                                  |
//| This Source Code Form is subject to the terms of the Mozilla    |
//| Public License, v. 2.0. See LICENSE file for details.           |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2025 TTW Markets"
#property link      "markets.tutortechwiz.com"
#property strict

//+------------------------------------------------------------------+
//| CONSTANTS - Strike Intervals & Lot Sizes                        |
//+------------------------------------------------------------------+
#define BANKNIFTY_STRIKE    100
#define NIFTY_STRIKE        50
#define FINNIFTY_STRIKE     50
#define MIDCPNIFTY_STRIKE   25

#define BANKNIFTY_LOT       25
#define NIFTY_LOT           50
#define FINNIFTY_LOT        40
#define MIDCPNIFTY_LOT      75

//+------------------------------------------------------------------+
//| Instrument structure                                             |
//+------------------------------------------------------------------+
struct SInstrument
{
   string   symbol;
   string   tradingSymbol;
   datetime expiry;
   double   strike;
   string   optionType;    // "CE" or "PE"
   string   exchange;      // "NFO", "BFO", etc.
   int      lotSize;
};

//+------------------------------------------------------------------+
//| Instrument Resolver Class                                        |
//+------------------------------------------------------------------+
class CInstrumentResolver
{
private:
   SInstrument m_instruments[];
   int         m_count;
   string      m_dataFile;
   datetime    m_lastUpdate;

public:
   CInstrumentResolver() : m_count(0), m_dataFile(""), m_lastUpdate(0) 
      { ArrayResize(m_instruments, 0); }
   ~CInstrumentResolver() { ArrayFree(m_instruments); }
   
   //--- {region} Initialization
   bool Init(string dataFile);
   bool LoadInstruments();
   bool RefreshData();
   //--- {endregion}
   
   //--- {region} Query Functions
   string GetNearestExpiry(string baseSymbol);
   double GetATMStrike(string baseSymbol, double spotPrice);
   string GetOTMStrike(string baseSymbol, double spotPrice, int strikesAway, string optionType);
   string BuildTradingSymbol(string baseSymbol, datetime expiry, double strike, string optionType);
   //--- {endregion}
   
   //--- {region} Utilities
   int GetLotSize(string baseSymbol);
   double GetStrikeInterval(string baseSymbol);
   //--- {endregion}

private:
   double RoundToStrike(double price, double interval);
};

//+------------------------------------------------------------------+
//| Initialize resolver                                              |
//+------------------------------------------------------------------+
bool CInstrumentResolver::Init(string dataFile)
{
   m_dataFile = dataFile;
   
   if(!LoadInstruments())
   {
      Print("ERROR: Failed to load instruments from ", dataFile);
      return false;
   }
   
   Print("Instrument resolver initialized with ", m_count, " instruments");
   return true;
}

//+------------------------------------------------------------------+
//| Load instruments from JSON file                                  |
//+------------------------------------------------------------------+
bool CInstrumentResolver::LoadInstruments()
{
   int handle = FileOpen(m_dataFile, FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot open ", m_dataFile);
      return false;
   }
   
   string json = "";
   while(!FileIsEnding(handle))
      json += FileReadString(handle);
   
   FileClose(handle);
   
   if(StringLen(json) < 3)
   {
      Print("WARNING: Instruments file empty");
      return false;
   }
   
   //--- TODO: Parse JSON and populate m_instruments[]
   m_count = 0;
   m_lastUpdate = TimeCurrent();
   Print("Instruments loaded successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Refresh instrument data                                          |
//+------------------------------------------------------------------+
bool CInstrumentResolver::RefreshData()
{
   Print("Refreshing instruments...");
   return LoadInstruments();
}

//+------------------------------------------------------------------+
//| Get nearest expiry date                                          |
//+------------------------------------------------------------------+
string CInstrumentResolver::GetNearestExpiry(string baseSymbol)
{
   datetime now = TimeCurrent();
   datetime nearest = 0;
   
   for(int i = 0; i < m_count; i++)
   {
      if(m_instruments[i].symbol == baseSymbol && m_instruments[i].expiry > now)
      {
         if(nearest == 0 || m_instruments[i].expiry < nearest)
            nearest = m_instruments[i].expiry;
      }
   }
   
   if(nearest == 0) return "";
   return TimeToString(nearest, TIME_DATE);
}

//+------------------------------------------------------------------+
//| Get ATM strike                                                   |
//+------------------------------------------------------------------+
double CInstrumentResolver::GetATMStrike(string baseSymbol, double spotPrice)
{
   double interval = GetStrikeInterval(baseSymbol);
   if(interval == 0) return 0;
   
   double atmStrike = RoundToStrike(spotPrice, interval);
   Print("ATM Strike for ", baseSymbol, " @ ", spotPrice, " = ", atmStrike);
   return atmStrike;
}

//+------------------------------------------------------------------+
//| Get OTM strike                                                   |
//+------------------------------------------------------------------+
string CInstrumentResolver::GetOTMStrike(string baseSymbol, double spotPrice, 
                                         int strikesAway, string optionType)
{
   double interval = GetStrikeInterval(baseSymbol);
   double atm = GetATMStrike(baseSymbol, spotPrice);
   double otm = 0;
   
   if(optionType == "CE")
      otm = atm + (strikesAway * interval);  // Call OTM: above spot
   else if(optionType == "PE")
      otm = atm - (strikesAway * interval);  // Put OTM: below spot
   
   return DoubleToString(otm, 0);
}

//+------------------------------------------------------------------+
//| Build full trading symbol                                        |
//+------------------------------------------------------------------+
string CInstrumentResolver::BuildTradingSymbol(string baseSymbol, datetime expiry, 
                                               double strike, string optionType)
{
   //--- Format: BANKNIFTY23JUN45000CE
   string year = StringSubstr(TimeToString(expiry, TIME_DATE), 2, 2);
   
   string months[] = {"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"};
   string month = months[TimeMonth(expiry) - 1];
   
   string strikeStr = DoubleToString(strike, 0);
   return baseSymbol + year + month + strikeStr + optionType;
}

//+------------------------------------------------------------------+
//| Get lot size for symbol                                          |
//+------------------------------------------------------------------+
int CInstrumentResolver::GetLotSize(string baseSymbol)
{
   if(baseSymbol == "BANKNIFTY") return BANKNIFTY_LOT;
   if(baseSymbol == "NIFTY") return NIFTY_LOT;
   if(baseSymbol == "FINNIFTY") return FINNIFTY_LOT;
   if(baseSymbol == "MIDCPNIFTY") return MIDCPNIFTY_LOT;
   return 1;
}

//+------------------------------------------------------------------+
//| Get strike interval for symbol                                   |
//+------------------------------------------------------------------+
double CInstrumentResolver::GetStrikeInterval(string baseSymbol)
{
   if(baseSymbol == "BANKNIFTY") return BANKNIFTY_STRIKE;
   if(baseSymbol == "NIFTY") return NIFTY_STRIKE;
   if(baseSymbol == "FINNIFTY") return FINNIFTY_STRIKE;
   if(baseSymbol == "MIDCPNIFTY") return MIDCPNIFTY_STRIKE;
   return 100.0;
}

//+------------------------------------------------------------------+
//| Round price to nearest strike                                    |
//+------------------------------------------------------------------+
double CInstrumentResolver::RoundToStrike(double price, double interval)
{
   return MathRound(price / interval) * interval;
}
//+------------------------------------------------------------------+
