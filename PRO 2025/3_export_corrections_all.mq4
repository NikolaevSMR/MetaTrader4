//+------------------------------------------------------------------+
//|                                     3_export_corrections_all.mq4 |
//|                                                      NikolaevSMR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "NikolaevSMR"
#property version   "1.0"
#property strict
bool bDebug=true; //отладка
//параметры для источника данных
string sDirName="PRO 2025"; //имя каталога
string sFileName=sDirName+"\\"+"tickers.set"; //имя файла
string sFileNameRes=sDirName+"\\"+"levels.set"; //имя файла
//параметры для визуализации
string sTemplateName="PRO 2025.tpl";
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
long lCurChart;
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
   int rn=0;
   int size=0;
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
   const ulong lMainChart = ChartFirst();
   if(bDebug) Print("Определено начало недели: "+dtWeekStart);
   //читаем файл с настройками для PRO
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
/*         if(sTicket!="")
           {
            //затем зачитываем параметры инструмента в определенном порядке
            if(!FileIsLineEnding(hPRO)) dCorrectLevel=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dtCorrectTime=StringToTime(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iVolatility=StringToInteger(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dLevel1=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iTake1=StringToInteger(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) dLevel2=StringToDouble(FileReadString(hPRO));
            if(!FileIsLineEnding(hPRO)) iTake2=StringToInteger(FileReadString(hPRO));
            }*/
         if(sTicket=="")//если инструмент не определен, переходим на начало цикла
           {
            if(bDebug) Print("Инструмент не определен");
            continue;
            }
         //увеличиваем массив на 1 и записываем текущую позицию
         ArrayResize(aLevels,ArraySize(aLevels)+1);
         rn=ArraySize(aLevels)-1;
         aLevels[rn].ticket=sTicket;
         /*aLevels[rn].correct_level=dCorrectLevel;
         aLevels[rn].correct_time=dtCorrectTime;
         aLevels[rn].volatility=iVolatility;
         aLevels[rn].level1=dLevel1;
         aLevels[rn].take1=iTake1;
         aLevels[rn].level2=dLevel2;
         aLevels[rn].take2=iTake2;*/
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

   //перебираем все вкладки и обогащаем массив ID графика
   lCurChart = ChartFirst();
   while(lCurChart>=0)//перебираем все вкладки, если следующего графика нет, значит мы в конце списка, останавливаем цикл
     {
      if(bDebug) Print("selected " + ChartSymbol(lCurChart));
      //Print(sTicket+"#"+ObjectFind(lCurChart,"PRO_label"));
      //ищем метку с определенным названием
      if(ObjectFind(lCurChart,"PRO_Label")==0)
        {
         if(bDebug) Print(ChartSymbol(lCurChart),": найдена метка. Период графика: ", ChartPeriod(lCurChart),", ID номер: ",lCurChart);
         for(i=0;i<ArraySize(aLevels);i++)
           {
            if(ChartSymbol(lCurChart)==aLevels[i].ticket)
              {
               aLevels[i].chartid=lCurChart;
               Print(ChartSymbol(lCurChart),": ChartId сохранен");
               }
            }
         }
      else
        {
         if(bDebug) Print(ChartSymbol(lCurChart),": метка не найдена. ID номер: ",lCurChart);
         }
      lCurChart=ChartNext(lCurChart); // сохраняем номер следующего графика по списку
      }
   Print("Размер массива: " + ArraySize(aLevels));
   //проходим по всем инструментам
   for(i=0;i<ArraySize(aLevels);i++)
     {
      Print(aLevels[i].ticket + ": значение ChartId="+aLevels[i].chartid);
      
      if(aLevels[i].chartid>0)//график определен
        {
         //сохраняем параметры коррекции
         if(ObjectGetDouble(aLevels[i].chartid,sTrendLineName,OBJPROP_PRICE1,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))==ObjectGetDouble(aLevels[i].chartid,sTrendLineName,OBJPROP_PRICE2,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS))))
            aLevels[i].correct_level=0;
         else
            aLevels[i].correct_level=ObjectGetDouble(aLevels[i].chartid,sTrendLineName,OBJPROP_PRICE2,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
         aLevels[i].correct_time=ObjectGetInteger(aLevels[i].chartid,sTrendLineName,OBJPROP_TIME,1);
         }
      else
         Print(aLevels[i].ticket + ": пропущен, график не соответствует требованиям");


      }
   hPRO = FileOpen(sFileNameRes, FILE_CSV|FILE_WRITE, ';');
   if(hPRO!=INVALID_HANDLE)
     {if(bDebug) PrintFormat("%s file is available for writing",sFileNameRes);
      //перебираем файл пока есть строки
      for(rn=0;rn<ArraySize(aLevels);rn++)
        {
         FileWrite(hPRO,aLevels[rn].ticket, DoubleToStr(aLevels[rn].correct_level,int(MarketInfo(aLevels[rn].ticket,MODE_DIGITS)))
            , TimeToStr(aLevels[rn].correct_time,TIME_DATE)+" "+TimeToStr(aLevels[rn].correct_time,TIME_MINUTES)
            , ""//IntegerToString(aLevels[rn].volatility)
            , ""//DoubleToStr(aLevels[rn].level1,int(MarketInfo(aLevels[rn].ticket,MODE_DIGITS)))
            , ""//IntegerToString(aLevels[rn].take1)
            , ""//DoubleToStr(aLevels[rn].level2,int(MarketInfo(aLevels[rn].ticket,MODE_DIGITS)))
            , ""//IntegerToString(aLevels[rn].take2)
            );
         }
      }
   FileClose(hPRO);
   Print("Файл " + sFileNameRes + " сформирован");
  }
//+------------------------------------------------------------------+
