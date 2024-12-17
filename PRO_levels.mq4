//+------------------------------------------------------------------+
//|                                                   PRO_levels.mq4 |
//|                                                      NikolaevSMR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "NikolaevSMR"
#property link      ""
#property version   "1.00"
#property strict
string iFileName="PRO_levels.set"; // file name
string iDirName="calc"; // directory name
bool bDebug=true;
//--- входные параметры скрипта
string sVLineName="PRO_Week"; // Имя линии
string sVolatName="PRO_Volatility";
string sVolatLabelName="PRO_Volatility_Value";
string sLine1Name="PRO_Line1"; // Имя линии
string sLine2Name="PRO_Line2"; // Имя линии
string sTake1Name="PRO_Take1";
string sTake2Name="PRO_Take2";
bool bLong=true; //по-умолчанию считаем, что сделки лонговые
ENUM_LINE_STYLE eVLineStyle=STYLE_DOT; // Стиль линии
ENUM_LINE_STYLE eHLineStyle=STYLE_SOLID; // Стиль линии
color cLineColor=clrRed; // Цвет линии
color cRectColor=clrGold; // Цвет прямоугольника
int iLineWidth=1; // Толщина линии
bool bBack=false; // Линия на заднем плане
bool bSelection=false; // Выделить для перемещений
bool bHidden=false; // Скрыт в списке объектов



//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   int i=0;
   string sTicket;
   int iVolatility;
   double dLevel1;
   double dLevel2;
   int iTake1;
   int iTake2;
   datetime dtWeekStart =iTime(NULL,PERIOD_W1,0);

   //читаем файл с настройками для PRO
   int hPRO;
   hPRO = FileOpen(iDirName+"\\"+iFileName, FILE_CSV|FILE_READ, ';');
   if(hPRO!=INVALID_HANDLE)
     {if(bDebug) PrintFormat("%s file is available for reading",iFileName);
      if(bDebug) PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //перебираем файл пока есть строки
      while(!FileIsEnding(hPRO))
        {//сначала получаем инструмент
         sTicket=FileReadString(hPRO);
         i=2;
         //затем зачитываем параметры инструмента
         while(!FileIsLineEnding(hPRO))
           {
            if(i==2) iVolatility=StringToInteger(FileReadString(hPRO));
            if(i==3) dLevel1=StringToDouble(FileReadString(hPRO));
            if(i==4) iTake1=StringToInteger(FileReadString(hPRO));
            if(i==5) dLevel2=StringToDouble(FileReadString(hPRO));
            if(i==6) iTake2=StringToInteger(FileReadString(hPRO));
            i++;
           }
         //сравниваем инструмент с текущим
         if(ChartSymbol()==sTicket)
           {
            //определяем направление работы
            if(iOpen(sTicket,PERIOD_W1,0)<dLevel1) bLong=false;
            if(bDebug) Print("Определен long? "+bLong);
            if(bDebug) Print("проверяем, созданы ли объекты и если нужно удаляем");
            if(!ObjectFind(0,sVLineName) ) ObjectDelete(0,sVLineName);
            if(!ObjectFind(0,sLine1Name) ) ObjectDelete(0,sLine1Name);
            if(!ObjectFind(0,sLine2Name) ) ObjectDelete(0,sLine2Name);
            
            if(bDebug) Print("рисуем линии");
            //создаем вертикальную линию
            if(ObjectCreate(0,sVLineName,OBJ_VLINE,0, dtWeekStart,0) )
              {
               ObjectSet(sVLineName, OBJPROP_STYLE, eVLineStyle);
               ObjectSet(sVLineName, OBJPROP_COLOR, clrDarkGray);
               ObjectSet(sVLineName, OBJPROP_WIDTH, 1);
               ObjectSet(sVLineName, OBJPROP_BACK, bBack);
               ObjectSet(sVLineName, OBJPROP_SELECTED, bSelection);
               ObjectSet(sVLineName, OBJPROP_HIDDEN, bHidden);
               }
            else Print("не удалось создать вертикальную линию!");

            //создаем горизонтальную линию
            if(ObjectCreate(0,sLine1Name,OBJ_HLINE,0,0,dLevel1))
              {
               ObjectSet(sLine1Name, OBJPROP_STYLE, eHLineStyle);
               ObjectSet(sLine1Name, OBJPROP_COLOR, cLineColor);
               ObjectSet(sLine1Name, OBJPROP_WIDTH, iLineWidth);
               ObjectSet(sLine1Name, OBJPROP_BACK, bBack);
               ObjectSet(sLine1Name, OBJPROP_SELECTED, bSelection);
               ObjectSet(sLine1Name, OBJPROP_HIDDEN, bHidden);
               }
            else Print("не удалось создать горизонтальную линию!");
            if(ObjectCreate(0,sLine2Name,OBJ_HLINE,0,0,dLevel2))
              {
               ObjectSet(sLine2Name, OBJPROP_STYLE, eHLineStyle);
               ObjectSet(sLine2Name, OBJPROP_COLOR, cLineColor);
               ObjectSet(sLine2Name, OBJPROP_WIDTH, iLineWidth);
               ObjectSet(sLine2Name, OBJPROP_BACK, bBack);
               ObjectSet(sLine2Name, OBJPROP_SELECTED, bSelection);
               ObjectSet(sLine2Name, OBJPROP_HIDDEN, bHidden);
               }
            else Print("не удалось создать горизонтальную линию!");

            //рисуем прямоугольники
            if(!ObjectFind(0,sVolatName) ) ObjectDelete(0,sVolatName);
            if(!ObjectFind(0,sVolatLabelName) ) ObjectDelete(0,sVolatLabelName);
            if(!ObjectFind(0,sTake1Name) ) ObjectDelete(0,sTake1Name);
            if(!ObjectFind(0,sTake2Name) ) ObjectDelete(0,sTake2Name);
            //волатильность
            if(bLong)
              {
               if(ObjectCreate(0,sVolatName, OBJ_RECTANGLE, 0, iTime(sTicket,PERIOD_W1,0), iHigh(sTicket,PERIOD_W1,0), iTime(sTicket,PERIOD_W1,0)+36*60*60, iHigh(sTicket,PERIOD_W1,0)+iVolatility/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sVolatName, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
               if(ObjectCreate(0,sVolatLabelName,OBJ_TEXT,0,iTime(sTicket,PERIOD_W1,0)+29*60*60,iHigh(sTicket,PERIOD_W1,0)+iVolatility/2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))))
                 {
                  ObjectSet(sVolatLabelName, OBJPROP_COLOR, clrGray);
                  ObjectSetString(0,sVolatLabelName, OBJPROP_TEXT, iVolatility);
                  ObjectSetString(0,sVolatLabelName, OBJPROP_TOOLTIP, "Volatility = "+iVolatility);
                  }
               else Print("не удалось создать текстовую метку!");
               }
            else
              {
               if(ObjectCreate(0,sVolatName, OBJ_RECTANGLE, 0, iTime(sTicket,PERIOD_W1,0), iLow(sTicket,PERIOD_W1,0), iTime(sTicket,PERIOD_W1,0)+36*60*60, iLow(sTicket,PERIOD_W1,0)-iVolatility/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sVolatName, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
               if(ObjectCreate(0,sVolatLabelName,OBJ_TEXT,0,iTime(sTicket,PERIOD_W1,0)+29*60*60,iLow(sTicket,PERIOD_W1,0)-iVolatility/2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))))
                 {
                  ObjectSet(sVolatLabelName, OBJPROP_COLOR, clrGray);
                  ObjectSetString(0,sVolatLabelName, OBJPROP_TEXT, iVolatility);
                  ObjectSetString(0,sVolatLabelName, OBJPROP_TOOLTIP, "Volatility = "+iVolatility);
                  }
               else Print("не удалось создать текстовую метку!");
               }
            //первый тейк
            if(bLong)
               if(ObjectCreate(0,sTake1Name, OBJ_RECTANGLE, 0, TimeCurrent()+24*60*60, dLevel1, TimeCurrent()+32*60*60, dLevel1+iTake1/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sTake1Name, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
            else
               if(ObjectCreate(0,sTake1Name, OBJ_RECTANGLE, 0, TimeCurrent()+24*60*60, dLevel1, TimeCurrent()+32*60*60, dLevel1-iTake1/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sTake1Name, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
            //второй тейк
            if(bLong)
               if(ObjectCreate(0,sTake2Name, OBJ_RECTANGLE, 0, TimeCurrent()+36*60*60, dLevel2, TimeCurrent()+44*60*60, dLevel2+iTake2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sTake2Name, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
            else
               if(ObjectCreate(0,sTake2Name, OBJ_RECTANGLE, 0, TimeCurrent()+36*60*60, dLevel2, TimeCurrent()+44*60*60, dLevel2-iTake2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)))) )
                 {
                  ObjectSet(sTake2Name, OBJPROP_COLOR, cRectColor);
                  }
               else Print("не удалось создать прямоугольник!");
            if(bDebug) Print("инструмент обработан");
            }
         else
            if(bDebug) Print(sTicket+" пропущен");
         }
      //--- close the file
      FileClose(hPRO);
      if(bDebug) PrintFormat("Data is read, %s file is closed",iFileName);
     }
   else
      PrintFormat("Failed to open %s file, Error code = %d",iFileName,GetLastError());
  }
//+------------------------------------------------------------------+
