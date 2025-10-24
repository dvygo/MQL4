//+------------------------------------------------------------------+
//|                                              Logger.mqh          |
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
//| CONSTANTS - Log Levels                                           |
//+------------------------------------------------------------------+
#define LOG_DEBUG    0
#define LOG_INFO     1
#define LOG_WARN     2
#define LOG_ERROR    3

//+------------------------------------------------------------------+
//| Logger Class                                                     |
//+------------------------------------------------------------------+
class CLogger
{
private:
   string   m_logFile;
   int      m_handle;
   bool     m_initialized;
   int      m_minLevel;
   long     m_maxSize;

public:
   CLogger() : m_logFile(""), m_handle(INVALID_HANDLE), m_initialized(false),
               m_minLevel(LOG_INFO), m_maxSize(10485760) {}  // 10MB default
   ~CLogger() { Close(); }
   
   //--- {region} Initialization
   bool Init(string logFile);
   void Close();
   bool IsInitialized() const { return m_initialized; }
   //--- {endregion}
   
   //--- {region} Logging Methods
   void Log(string message, int level=LOG_INFO);
   void Debug(string message)   { Log(message, LOG_DEBUG); }
   void Info(string message)    { Log(message, LOG_INFO); }
   void Warning(string message) { Log(message, LOG_WARN); }
   void Error(string message)   { Log(message, LOG_ERROR); }
   //--- {endregion}
   
   //--- {region} Trade Logging
   void LogTrade(string orderID, string symbol, string action, double qty, double price, string status);
   void LogSignal(string symbol, string signalType, string details);
   void LogRMS(string message, bool isViolation);
   //--- {endregion}

private:
   string GetLevelStr(int level);
   string GetTimestamp();
   void WriteToFile(string text);
};

//+------------------------------------------------------------------+
//| Initialize logger                                                |
//+------------------------------------------------------------------+
bool CLogger::Init(string logFile)
{
   if(m_initialized) return true;
   
   m_logFile = logFile;
   m_handle = FileOpen(m_logFile, FILE_WRITE|FILE_READ|FILE_TXT|FILE_COMMON);
   
   if(m_handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to open log: ", m_logFile, " Error: ", GetLastError());
      return false;
   }
   
   FileSeek(m_handle, 0, SEEK_END);
   m_initialized = true;
   Log("Logger initialized", LOG_INFO);
   return true;
}

//+------------------------------------------------------------------+
//| Close logger                                                     |
//+------------------------------------------------------------------+
void CLogger::Close()
{
   if(!m_initialized) return;
   
   Log("Logger shutting down", LOG_INFO);
   
   if(m_handle != INVALID_HANDLE)
   {
      FileClose(m_handle);
      m_handle = INVALID_HANDLE;
   }
   
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Main log function                                                |
//+------------------------------------------------------------------+
void CLogger::Log(string message, int level=LOG_INFO)
{
   if(level < m_minLevel) return;
   
   string entry = "[" + GetTimestamp() + "] [" + GetLevelStr(level) + "] " + message;
   Print(entry);
   
   if(m_initialized)
   {
      WriteToFile(entry);
   }
}

//+------------------------------------------------------------------+
//| Log trade activity                                               |
//+------------------------------------------------------------------+
void CLogger::LogTrade(string orderID, string symbol, string action, 
                       double qty, double price, string status)
{
   string msg = StringFormat("TRADE | ID:%s | %s | %s | Qty:%.2f | Price:%.2f | %s",
                             orderID, symbol, action, qty, price, status);
   Log(msg, LOG_INFO);
}

//+------------------------------------------------------------------+
//| Log trading signal                                               |
//+------------------------------------------------------------------+
void CLogger::LogSignal(string symbol, string signalType, string details)
{
   string msg = StringFormat("SIGNAL | %s | %s | %s", symbol, signalType, details);
   Log(msg, LOG_INFO);
}

//+------------------------------------------------------------------+
//| Log RMS event                                                    |
//+------------------------------------------------------------------+
void CLogger::LogRMS(string message, bool isViolation)
{
   int level = isViolation ? LOG_WARN : LOG_INFO;
   string prefix = isViolation ? "RMS VIOLATION | " : "RMS | ";
   Log(prefix + message, level);
}

//+------------------------------------------------------------------+
//| Get log level as string                                          |
//+------------------------------------------------------------------+
string CLogger::GetLevelStr(int level)
{
   switch(level)
   {
      case LOG_DEBUG: return "DEBUG";
      case LOG_INFO:  return "INFO";
      case LOG_WARN:  return "WARN";
      case LOG_ERROR: return "ERROR";
      default:        return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Get timestamp                                                    |
//+------------------------------------------------------------------+
string CLogger::GetTimestamp()
{
   return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Write to file                                                    |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(string text)
{
   if(m_handle == INVALID_HANDLE) return;
   FileWriteString(m_handle, text + "\n");
   FileFlush(m_handle);
}
//+------------------------------------------------------------------+
