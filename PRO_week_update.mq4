//+------------------------------------------------------------------+
//|                                              PRO_week_update.mq4 |
//|                                                      NikolaevSMR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "NikolaevSMR"
#property link      ""
#property version   "1.00"
#property strict

//количество недель для сбора
int MaxLimit = 1500;

//+------------------------------------------------------------------+
//| Функция возвращает список доступных символов                     |
//+------------------------------------------------------------------+
int SymbolsList(string &Symbols[], bool Selected)
{
   string SymbolsFileName;
   int Offset, SymbolsNumber;
  
   if(Selected) SymbolsFileName = "symbols.sel";
   else         SymbolsFileName = "symbols.raw";
  
// Открываем файл с описанием символов

   int hFile = FileOpenHistory(SymbolsFileName, FILE_BIN|FILE_READ);
   if(hFile < 0) return(-1);

// Определяем количество символов, зарегистрированных в файле

   if(Selected) { SymbolsNumber = (FileSize(hFile) - 4) / 128; Offset = 116;  }
   else         { SymbolsNumber = FileSize(hFile) / 1936;      Offset = 1924; }

   ArrayResize(Symbols, SymbolsNumber);

// Считываем символы из файла

   if(Selected) FileSeek(hFile, 4, SEEK_SET);
  
   for(int i = 0; i < SymbolsNumber; i++)
   {
      Symbols[i] = FileReadString(hFile, 12);
      FileSeek(hFile, Offset, SEEK_CUR);
   }
  
   FileClose(hFile);
  
// Возвращаем количество считанных инструментов

   return(SymbolsNumber);
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
//int start()
  {
   string SymbolsList[];
   // получаем список символов, загруженных в окно "Обзор рынка"
   if(SymbolsList(SymbolsList, true) > 0)
     Print("Первый символ, загруженный в окно \"Обзор рынка\": ", SymbolsList[0]);
   // получаем полный список символов, предоставляемых ДЦ
   if(SymbolsList(SymbolsList, false) > 0)
     Print("Последний символ из списка доступных инструментов: ", SymbolsList[ArraySize(SymbolsList)-1]);
   //создаем файл с настройками для PRO
   int hPRO;
   hPRO = FileOpen("7PRO.set", FILE_CSV|FILE_WRITE, ';');
   int iDigits;
   //циклом перебираем все доступные инструменты
   for(int sc = 0; sc<ArraySize(SymbolsList); sc++)
   {
      //пишем данные для настройки PRO
      FileWrite(hPRO, SymbolsList[sc], TimeToStr(iTime(SymbolsList[sc], PERIOD_W1, 0), TIME_DATE)
         , iOpen(SymbolsList[sc], PERIOD_W1, 0), iHigh(SymbolsList[sc], PERIOD_W1, 0), iLow(SymbolsList[sc], PERIOD_W1, 0)
         , MarketInfo(SymbolsList[sc],MODE_SWAPLONG), MarketInfo(SymbolsList[sc],MODE_SWAPSHORT), MarketInfo(SymbolsList[sc],MODE_SWAPTYPE) );
      iDigits = int(MarketInfo(SymbolsList[sc],MODE_DIGITS ) );
      //собираем волатильность отдельно по каждой валютной паре
      int hV;
      hV = FileOpen(SymbolsList[sc]+"10080.csv", FILE_CSV|FILE_WRITE, ',');
      int iTotalBars = iBars(SymbolsList[sc], PERIOD_W1);
      //сверяемся с лимитом, если достигли, то предупреждаем, необходимо увеличить параметр
      if(iTotalBars>MaxLimit)
      {
         Print("MaxLimit exceeded!!!");
         iTotalBars = MaxLimit;
      }
      for(int i = iTotalBars-1; i >= 0; i--)
      {
         //если от начала недели прошло менее 6 дней, то такую запись не грузим
         if(i == 0 && ((TimeCurrent()-iTime(SymbolsList[sc], PERIOD_W1, i) )/PeriodSeconds(PERIOD_D1)<6) )
            break;
         //сверяем с датой 1970.01.01, если совпадает, то завершаем цикл
         if(TimeToStr(iTime(SymbolsList[sc], PERIOD_W1, i), TIME_DATE)!="1970.01.01")
            FileWrite(hV, TimeToStr(iTime(SymbolsList[sc], PERIOD_W1, i), TIME_DATE), "00:00"
                  , DoubleToStr(iOpen(SymbolsList[sc], PERIOD_W1, i),iDigits)
                  , DoubleToStr(iHigh(SymbolsList[sc], PERIOD_W1, i),iDigits)
                  , DoubleToStr(iLow(SymbolsList[sc], PERIOD_W1, i),iDigits)
                  , DoubleToStr(iClose(SymbolsList[sc], PERIOD_W1, i),iDigits)
                  , DoubleToStr(iVolume(SymbolsList[sc], PERIOD_W1, i),0) );
         else
            continue;
      }
      FileClose(hV);
   } 
   FileClose(hPRO);
  }

//+------------------------------------------------------------------+
