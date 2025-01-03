//+------------------------------------------------------------------+
//|                                          4_import_levels_one.mq4 |
//|                                                      NikolaevSMR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "NikolaevSMR"
#property version   "1.0"
#property strict
bool bDebug=false; //отладка
//параметры для источника данных
string sDirName="PRO 2025"; //имя каталога
string sFileName=sDirName+"\\"+"levels.set"; //имя файла
//string iFileName="PRO_levels.set"; //имя файла
//параметры для визуализации
string sLabelName="PRO_Label"; //Имя сигнальной метки
string sVLineName="PRO_Week"; //Имя вертикальной линии
string sTrendLineName="PRO_TrendLine"; //Имя трендовой линии
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
struct levels
  {
   string ticket;
   double correct_level;
   datetime correct_time;
   int volatility;
   double level1;
   double level2;
   int take1;
   int take2;
   ulong chartid;
   };

//+------------------------------------------------------------------+
//+ функция создания объектов
//+------------------------------------------------------------------+
int fObjectCreate(long lChart, string sObjectName, ENUM_OBJECT eObjectType, datetime dtDateStart, double dPrice, datetime dtDateEnd, double dPrice2, ENUM_LINE_STYLE eObjectStyle, color clrColor, int iWidth, bool bSelected)
  {
   if(!ObjectFind(lChart,sObjectName) ) ObjectDelete(lChart,sObjectName);
   if(ObjectCreate(lChart,sObjectName,eObjectType,0, dtDateStart, dPrice, dtDateEnd, dPrice2) )
     {
      //задаем параметры объекта
      ObjectSetInteger(lChart,sObjectName, OBJPROP_STYLE, eObjectStyle);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_COLOR, clrColor);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_WIDTH, iWidth);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_BACK, false/*bBack*/);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_SELECTED, bSelected);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_HIDDEN, false/*bHidden*/);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_FILL, true);
      ObjectSetInteger(lChart,sObjectName, OBJPROP_RAY, false);
      }
   return GetLastError();
   }
//+------------------------------------------------------------------+
//+ функция создания текстовых меток
//+------------------------------------------------------------------+
int fLabelCreate(long lChart, string sObjectName, datetime dtDateStart, double dPrice, color clrColor, string sText, string sTooltip)
  {
   if(!ObjectFind(lChart,sObjectName) ) ObjectDelete(lChart,sObjectName);
   if(ObjectCreate(lChart,sObjectName,OBJ_TEXT,0, dtDateStart, dPrice) )
     {
      //задаем параметры объекта
      ObjectSetInteger(lChart,sObjectName, OBJPROP_COLOR, clrColor);
      ObjectSetString(lChart,sObjectName, OBJPROP_TEXT, sText);
      ObjectSetString(lChart,sObjectName, OBJPROP_TOOLTIP, sTooltip);
      }
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
   int rn;
   int size;
   int res;
   string sTicket;
   double dCorrectLevel;
   datetime dtCorrectTime;//yyyy.mm.dd hh:mi
   int iVolatility=0;
   double dLevel1=0;
   double dLevel2=0;
   int iTake1=0;
   int iTake2=0;
   datetime dtStartDate;
   datetime dtEndDate;
   double dPrice1;
   double dPrice2;
   levels aLevels[];
   datetime dtWeekStart =iTime(NULL,PERIOD_W1,0);
   if(bDebug) Print("Определено начало недели: "+dtWeekStart);
   //читаем файл с настройками для PRO
   int hPRO;
   hPRO = FileOpen(sFileName, FILE_CSV|FILE_READ, ';');
   if(hPRO!=INVALID_HANDLE)
     {if(bDebug) PrintFormat("%s file is available for reading",sFileName);
      if(bDebug) PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //перебираем файл пока есть строки
      while(!FileIsEnding(hPRO))
        {//сначала получаем инструмент
         sTicket=FileReadString(hPRO);
         if(sTicket!="")
           {
            //затем зачитываем параметры инструмента в определенном порядке
            if(!FileIsLineEnding(hPRO)) dCorrectLevel=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dtCorrectTime=StringToTime(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iVolatility=StringToInteger(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dLevel1=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iTake1=StringToInteger(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dLevel2=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iTake2=StringToInteger(FileReadString(hPRO));
            }
         if(sTicket=="")//если инструмент не определен, переходим на начало цикла
           {
            if(bDebug) Print("Инструмент не определен");
            continue;
            }
         //увеличиваем массив на 1 и записываем текущую позицию
         ArrayResize(aLevels,ArraySize(aLevels)+1);
         rn=ArraySize(aLevels)-1;
         aLevels[rn].ticket=sTicket;
         aLevels[rn].correct_level=dCorrectLevel;
         aLevels[rn].correct_time=dtCorrectTime;
         aLevels[rn].volatility=iVolatility;
         aLevels[rn].level1=dLevel1;
         aLevels[rn].take1=iTake1;
         aLevels[rn].level2=dLevel2;
         aLevels[rn].take2=iTake2;
         size = ArraySize(aLevels);
         //if(bDebug) Print(aLevels[rn].ticket, ": Volatility = ", aLevels[rn].volatility + ". Total array size = ", size);
         if(bDebug) Print(aLevels[rn].ticket + ": инструмент обработан");
         }
      //--- close the file
      FileClose(hPRO);
      if(bDebug) PrintFormat("Data is read, %s file is closed",sFileName);
     }
   else
      PrintFormat("Failed to open %s file, Error code = %d",sFileName,GetLastError());

   //проходим по всем инструментам
   for(i=0;i<ArraySize(aLevels);i++)
     {
      //сравниваем инструмент с текущим
      if(ChartSymbol()==aLevels[i].ticket)
        {

         //создаем линии
         res=fObjectCreate(0,sVLineName, OBJ_VLINE, dtWeekStart, 0,0,0,eVLineStyle, clrDarkGray, 1, bSelection);
         if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sVLineName+", ошибка "+IntegerToString(res));
         res=fObjectCreate(0,sLine1Name, OBJ_HLINE, 0, aLevels[i].level1,0,0, eHLineStyle, cLineColor, iHLineWidth, bSelection);
         if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sLine1Name+", ошибка "+IntegerToString(res));
         res=fObjectCreate(0,sLine2Name, OBJ_HLINE, 0, aLevels[i].level2,0,0, eHLineStyle, cLineColor, iHLineWidth, bSelection);
         if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sLine2Name+", ошибка "+IntegerToString(res));
            
      //определяем направление работы
      Print(DoubleToStr(iOpen(aLevels[i].ticket,PERIOD_W1,0),int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))+" > "+DoubleToStr(iOpen(aLevels[i].ticket,PERIOD_H1,0)));
      bLong=iOpen(aLevels[i].ticket,PERIOD_W1,0)>iOpen(aLevels[i].ticket,PERIOD_H1,0);
      if(bDebug) Print(aLevels[i].ticket + ": Определен long? "+bLong);

      Print("Обновляем метку PRO_Label");
      //добавляем метки-флаг, что именно в нем и нужно искать актуальные данные
      dtStartDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1);
      dPrice1 = iHigh(aLevels[i].ticket,PERIOD_W1,0)+0.75*aLevels[i].volatility/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      res=fLabelCreate(0, sLabelName, dtStartDate,dPrice1,cLabelColor,"!Обновлено " + TimeToStr(TimeCurrent(),TIME_DATE) + " " + TimeToString(TimeCurrent(),TIME_SECONDS),"");
      if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sLabelName+", ошибка "+IntegerToString(res));

      //волатильность
      dtStartDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart));
      dtEndDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1)+12*60*60;
      if(bLong)
        {
         dPrice1 = iHigh(aLevels[i].ticket,PERIOD_W1,0);
         dPrice2 = iHigh(aLevels[i].ticket,PERIOD_W1,0)+aLevels[i].volatility/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
         }
      else
        {
         dPrice1 = iLow(aLevels[i].ticket,PERIOD_W1,0);
         dPrice2 = iLow(aLevels[i].ticket,PERIOD_W1,0)-aLevels[i].volatility/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
         }
      res=fObjectCreate(0,sVolatName,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection);
      if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sVolatName+", "+EnumToString(OBJ_RECTANGLE)+", ошибка "+IntegerToString(res));

      //метка с волатильностью
      dtStartDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1)+6*60*60;
      if(bLong)
         dPrice1 = iHigh(aLevels[i].ticket,PERIOD_W1,0)+aLevels[i].volatility/2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice1 = iLow(aLevels[i].ticket,PERIOD_W1,0)-aLevels[i].volatility/2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fLabelCreate(0,sVolatLabelName, dtStartDate,dPrice1,cLabelColor,aLevels[i].volatility,"Volatility = "+aLevels[i].volatility)>0) Print("Ошибка "+GetLastError());


      //трендовая линия
      /*if(ObjectFind(0,sTrendLineName)==0)
         Print(aLevels[i].ticket + ": PRO_TrendLine level = "+DoubleToStr(ObjectGetDouble(0,sTrendLineName,OBJPROP_PRICE2,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))));
      else
        {*/
         dtStartDate=iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart));
         dtEndDate=aLevels[i].correct_time;
         dPrice1=iOpen(aLevels[i].ticket,PERIOD_W1,0);
/*         if(aLevels[i].correct_level>0)
            dPrice2=aLevels[i].correct_level;
         else*/
            dPrice2=aLevels[i].correct_level;
         res=fObjectCreate(0, sTrendLineName, OBJ_TREND, dtStartDate, dPrice1,dtEndDate,dPrice2, eHLineStyle, cLineColor, 2, true);
         if(res>0) Print(aLevels[i].ticket + ": " + sTrendLineName + ": Ошибка "+IntegerToString(res));


      //первый тейк
      dtStartDate = TimeCurrent()+24*60*60;
      dtEndDate = TimeCurrent()+32*60*60;
      dPrice1 = aLevels[i].level1;
      if(bLong)
         dPrice2 = aLevels[i].level1+aLevels[i].take1/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice2 = aLevels[i].level1-aLevels[i].take1/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fObjectCreate(0,sTake1Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection)>0) Print("Ошибка "+GetLastError());

      //второй тейк
      dtStartDate = TimeCurrent()+36*60*60;
      dtEndDate = TimeCurrent()+44*60*60;
      dPrice1 = aLevels[i].level2;
      if(bLong)
         dPrice2 = aLevels[i].level2+aLevels[i].take2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice2 = aLevels[i].level2-aLevels[i].take2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fObjectCreate(0,sTake2Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection)>0) Print("Ошибка "+GetLastError());

            if(bDebug) Print("инструмент обработан");
            }
         else
            if(bDebug) Print(aLevels[i].ticket+" пропущен");
         }
  }
//+------------------------------------------------------------------+
