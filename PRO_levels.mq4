//+------------------------------------------------------------------+
//|                                                   PRO_levels.mq4 |
//|                                                      NikolaevSMR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "NikolaevSMR"
#property link      ""
#property version   "1.1"
#property strict
bool bDebug=false; //отладка
//параметры для источника данных
string iDirName="calc"; //имя каталога
string iFileName=iDirName+"\\"+"PRO_levels.set"; //имя файла
//string iFileName="PRO_levels.set"; //имя файла
//параметры для визуализации
string sVLineName="PRO_Week"; //Имя вертикальной линии
string sVolatName="PRO_Volatility"; //Имя прямоугольника волатильности
string sVolatLabelName="PRO_Volatility_Value"; //Имя метки волатильности
string sLine1Name="PRO_Line1"; // Имя горизонтальной линии 1й уровень
string sLine2Name="PRO_Line2"; // Имя горизонтальной линии 2й уровень
string sTake1Name="PRO_Take1"; // Имя прямоугольника 1й тейк
string sTake2Name="PRO_Take2"; // Имя прямоугольника 2й тейк
bool bLong=true; //по-умолчанию считаем, что сделки лонговые
ENUM_LINE_STYLE eVLineStyle=STYLE_DOT; // Стиль вертикальной линии
ENUM_LINE_STYLE eHLineStyle=STYLE_SOLID; // Стиль горизонтальной линии
color cLineColor=clrRed; // Цвет горизонтальной линии
color cRectColor=clrGold; // Цвет прямоугольника
color cLabelColor=clrGray; // Цвет текстовой надписи
int iHLineWidth=1; // Толщина горизонтальной линии
bool bBack=false; // Линия на заднем плане
bool bSelection=false; // Выделить для перемещений
bool bHidden=false; // Скрыт в списке объектов

//+------------------------------------------------------------------+
//+ функция создания объектов
//+------------------------------------------------------------------+
int fObjectCreate(string sObjectName, ENUM_OBJECT eObjectType, datetime dtDateStart, double dPrice, datetime dtDateEnd, double dPrice2, ENUM_LINE_STYLE eObjectStyle, color clrColor, int iWidth)
  {
   if(bDebug) Print("проверяем, создан ли объект и если нужно удаляем");
   if(!ObjectFind(0,sObjectName) ) ObjectDelete(0,sObjectName);
   if(bDebug) Print("создаем объект с типом "+eObjectType);
   if(ObjectCreate(0,sObjectName,eObjectType,0, dtDateStart, dPrice, dtDateEnd, dPrice2) )
     {
      //задаем параметры объекта
      ObjectSet(sObjectName, OBJPROP_STYLE, eObjectStyle);
      ObjectSet(sObjectName, OBJPROP_COLOR, clrColor);
      ObjectSet(sObjectName, OBJPROP_WIDTH, iWidth);
      ObjectSet(sObjectName, OBJPROP_BACK, bBack);
      ObjectSet(sObjectName, OBJPROP_SELECTED, bSelection);
      ObjectSet(sObjectName, OBJPROP_HIDDEN, bHidden);
      ObjectSet(sObjectName, OBJPROP_FILL, true);
      if(bDebug) Print("создается объект с типом "+EnumToString(eObjectType) ); 
      }
   else Print("не удалось создать объект с параметрами: "+sObjectName+", "+EnumToString(eObjectType) );
   return GetLastError();
   }
//+------------------------------------------------------------------+
//+ функция создания текстовых меток
//+------------------------------------------------------------------+
int fLabelCreate(string sObjectName, datetime dtDateStart, double dPrice, color clrColor, string sText, string sTooltip)
  {
   if(bDebug) Print("проверяем, создана ли текстовая метка и если нужно удаляем");
   if(!ObjectFind(0,sObjectName) ) ObjectDelete(0,sObjectName);
   if(bDebug) Print("создаем текстовую метку");
   if(ObjectCreate(0,sObjectName,OBJ_TEXT,0, dtDateStart, dPrice) )
     {
      //задаем параметры объекта
      ObjectSet(sObjectName, OBJPROP_COLOR, clrColor);
      ObjectSetString(0,sObjectName, OBJPROP_TEXT, sText);
      ObjectSetString(0,sObjectName, OBJPROP_TOOLTIP, sTooltip);
      if(bDebug) Print("создается текстовая метка"); 
      }
   else Print("не удалось создать текстовую метку: "+sObjectName);
   return GetLastError();
   }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   //определяем основные переменные
   int i=0;
   string sTicket;
   int iVolatility=0;
   double dLevel1=0;
   double dLevel2=0;
   int iTake1=0;
   int iTake2=0;
   datetime dtStartDate;
   datetime dtEndDate;
   double dPrice1;
   double dPrice2;
   datetime dtWeekStart =iTime(NULL,PERIOD_W1,0);
   if(bDebug) Print("Определено начало недели: "+dtWeekStart);
   //читаем файл с настройками для PRO
   int hPRO;
   hPRO = FileOpen(iFileName, FILE_CSV|FILE_READ, ';');
   if(hPRO!=INVALID_HANDLE)
     {if(bDebug) PrintFormat("%s file is available for reading",iFileName);
      if(bDebug) PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //перебираем файл пока есть строки
      while(!FileIsEnding(hPRO))
        {//сначала получаем инструмент
         sTicket=FileReadString(hPRO);
         i=2;
         //затем зачитываем параметры инструмента в определенном порядке
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
            //создаем линии
            if(fObjectCreate(sVLineName, OBJ_VLINE, dtWeekStart, 0,0,0,eVLineStyle, clrDarkGray, 1)>0) Print("Ошибка создания объекта");
            if(fObjectCreate(sLine1Name, OBJ_HLINE, 0, dLevel1,0,0, eHLineStyle, cLineColor, iHLineWidth)>0) Print("Ошибка создания объекта");
            if(fObjectCreate(sLine2Name, OBJ_HLINE, 0, dLevel2,0,0, eHLineStyle, cLineColor, iHLineWidth)>0) Print("Ошибка создания объекта");
            //создаем прямоугольники
            if(!ObjectFind(0,sVolatLabelName) ) ObjectDelete(0,sVolatLabelName);
            if(!ObjectFind(0,sTake1Name) ) ObjectDelete(0,sTake1Name);
            if(!ObjectFind(0,sTake2Name) ) ObjectDelete(0,sTake2Name);
            
            //волатильность
            dtStartDate = iTime(sTicket,PERIOD_W1,0);
            if(bLong)
              {
               dtEndDate = iTime(sTicket,PERIOD_W1,0)+36*60*60;
               dPrice1 = iHigh(sTicket,PERIOD_W1,0);
               dPrice2 = iHigh(sTicket,PERIOD_W1,0)+iVolatility/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
               }
            else
              {
               dtEndDate = iTime(sTicket,PERIOD_W1,0)+36*60*60;
               dPrice1 = iLow(sTicket,PERIOD_W1,0);
               dPrice2 = iLow(sTicket,PERIOD_W1,0)-iVolatility/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
               }
            if(fObjectCreate(sVolatName,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0)>0) Print("Ошибка создания объекта");
            
            //метка с волатильностью
            dtStartDate = iTime(sTicket,PERIOD_W1,0)+29*60*60;
            if(bLong)
               dPrice1 = iHigh(sTicket,PERIOD_W1,0)+iVolatility/2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            else
               dPrice1 = iLow(sTicket,PERIOD_W1,0)-iVolatility/2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            if(fLabelCreate(sVolatLabelName, dtStartDate,dPrice1,cLabelColor,iVolatility,"Volatility = "+iVolatility)>0) Print("Ошибка создания метки");

            //первый тейк
            dtStartDate = TimeCurrent()+24*60*60;
            dtEndDate = TimeCurrent()+32*60*60;
            dPrice1 = dLevel1;
            if(bLong)
               dPrice2 = dLevel1+iTake1/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            else
               dPrice2 = dLevel1-iTake1/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            if(fObjectCreate(sTake1Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0)>0) Print("Ошибка создания объекта");

            //второй тейк
            dtStartDate = TimeCurrent()+36*60*60;
            dtEndDate = TimeCurrent()+44*60*60;
            dPrice1 = dLevel2;
            if(bLong)
               dPrice2 = dLevel2+iTake2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            else
               dPrice2 = dLevel2-iTake2/MathPow(10,int(MarketInfo(sTicket,MODE_DIGITS)));
            if(fObjectCreate(sTake2Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0)>0) Print("Ошибка создания объекта");

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
