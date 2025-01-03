//+------------------------------------------------------------------+
//|                                             1_import_tickets.mq4 |
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
   //перебираем все вкладки и обогащаем массив ID графика
   lCurChart = ChartFirst();
   while(lCurChart>=0)//перебираем все вкладки, если следующего графика нет, значит мы в конце списка, останавливаем цикл
     {
      if(bDebug) Print("selected " + ChartSymbol(lCurChart));
      //Print(sTicket+"#"+ObjectFind(lCurChart, sLabelName));
      //ищем метку с определенным названием
      if(ObjectFind(lCurChart, sLabelName)==0)
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
   //проходим по всем инструментам
   for(i=0;i<ArraySize(aLevels);i++)
     {
      Print(aLevels[i].ticket + ": значение ChartId="+aLevels[i].chartid);
      
      if(aLevels[i].chartid=="0")//график не нашелся, создаем новое окно
        {
         lCurChart = ChartOpen(aLevels[i].ticket,PERIOD_H1);
         while(lCurChart == 0 || lCurChart == -1)//обрабатываем проблемы при открытии
           {
            if(lCurChart == 0) Print(aLevels[i].ticket + ": Ошибка открытия графика ",_LastError,", ожидание открытия...");
            else
               Print(aLevels[i].ticket + ": График в процессе открытия...");
            Sleep(500);
            lCurChart=ChartNext(lMainChart);
            }
         Print(aLevels[i].ticket + ": график сформирован. ID: " + lCurChart);
         //применяем шаблон, через задержку, чтобы успел отрисоваться
         Sleep(500);
         if(FileIsExist(sTemplateName) )
            Print(aLevels[i].ticket + ": Проверка доступности шаблона: " + sTemplateName + " найден");
         else
            Print(aLevels[i].ticket + ": Проверка доступности шаблона: " + sTemplateName + " не найден");
         if(ChartApplyTemplate(lCurChart,sTemplateName) )
            Print(aLevels[i].ticket + ": Шаблон применен успешно");
         else
            Print(aLevels[i].ticket + ": применить шаблон не удалось: " + GetLastError() );
         ChartNavigate(lCurChart,CHART_END,0);
         ChartRedraw(lCurChart);
         //сохраняем значение в массив
         aLevels[i].chartid=lCurChart;
         }
      else
         Print(aLevels[i].ticket + ": пропущен, график уже есть");

      //удаляем неактуальные объекты
      if(!ObjectFind(aLevels[i].chartid,sLine1Name) ) ObjectDelete(aLevels[i].chartid,sLine1Name);
      if(!ObjectFind(aLevels[i].chartid,sLine2Name) ) ObjectDelete(aLevels[i].chartid,sLine2Name);
      if(!ObjectFind(aLevels[i].chartid,sTake1Name) ) ObjectDelete(aLevels[i].chartid,sTake1Name);
      if(!ObjectFind(aLevels[i].chartid,sTake2Name) ) ObjectDelete(aLevels[i].chartid,sTake2Name);

      //определяем направление работы
      Print(DoubleToStr(iOpen(aLevels[i].ticket,PERIOD_W1,0),int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))+" > "+DoubleToStr(iOpen(aLevels[i].ticket,PERIOD_H1,0)));
      bLong=iOpen(aLevels[i].ticket,PERIOD_W1,0)>iOpen(aLevels[i].ticket,PERIOD_H1,0);
      if(bDebug) Print(aLevels[i].ticket + ": Определен long? "+bLong);

      Print("Обновляем метку PRO_Label");
      //добавляем метки-флаг, что именно в нем и нужно искать актуальные данные
      dtStartDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1);
      dPrice1 = iHigh(aLevels[i].ticket,PERIOD_W1,0)+0.75*aLevels[i].volatility/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      res=fLabelCreate(aLevels[i].chartid, sLabelName, dtStartDate,dPrice1,cLabelColor,"!Обновлено " + TimeToStr(TimeCurrent(),TIME_DATE) + " " + TimeToString(TimeCurrent(),TIME_SECONDS),"");
      if(res>0) Print(aLevels[i].ticket + ": PRO_Label: Ошибка "+IntegerToString(res));
      //обновляем вертикальную линию-отсечку недели
      res=fObjectCreate(aLevels[i].chartid,sVLineName, OBJ_VLINE, dtWeekStart, 0,0,0,eVLineStyle, clrDarkGray, 1, bSelection);
      if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sVLineName+", "+EnumToString(OBJ_VLINE)+", ошибка "+IntegerToString(res));

/*      //волатильность
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
      res=fObjectCreate(aLevels[i].chartid,sVolatName,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection);
      if(res>0) Print(aLevels[i].ticket + ": не удалось создать объект с параметрами: "+sVolatName+", "+EnumToString(OBJ_RECTANGLE)+", ошибка "+IntegerToString(res));
      
      //метка с волатильностью
      dtStartDate = iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1)+6*60*60;
      if(bLong)
         dPrice1 = iHigh(aLevels[i].ticket,PERIOD_W1,0)+aLevels[i].volatility/2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice1 = iLow(aLevels[i].ticket,PERIOD_W1,0)-aLevels[i].volatility/2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fLabelCreate(aLevels[i].chartid,sVolatLabelName, dtStartDate,dPrice1,cLabelColor,aLevels[i].volatility,"Volatility = "+aLevels[i].volatility)>0) Print("Ошибка "+GetLastError());
*/

      //трендовая линия
      /*if(ObjectFind(aLevels[i].chartid,sTrendLineName)==0)
         Print(aLevels[i].ticket + ": PRO_TrendLine level = "+DoubleToStr(ObjectGetDouble(aLevels[i].chartid,sTrendLineName,OBJPROP_PRICE2,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))));
      else
        {*/
         dtStartDate=iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart));
         dtEndDate=iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1)+24*60*60;
         dPrice1=iOpen(aLevels[i].ticket,PERIOD_W1,0);
/*         if(aLevels[i].correct_level>0)
            dPrice2=aLevels[i].correct_level;
         else*/
            dPrice2=iOpen(aLevels[i].ticket,PERIOD_W1,0);
         res=fObjectCreate(aLevels[i].chartid, sTrendLineName, OBJ_TREND, dtStartDate, dPrice1,dtEndDate,dPrice2, eHLineStyle, cLineColor, 2, true);
         if(res>0) Print(aLevels[i].ticket + ": " + sTrendLineName + ": Ошибка "+IntegerToString(res));

      //создаем линии
//      if(fObjectCreate(aLevels[i].chartid,sVLineName, OBJ_VLINE, dtWeekStart, 0,0,0,eVLineStyle, clrDarkGray, 1, bSelection)>0) Print("Ошибка "+GetLastError());

//         if(fObjectCreate(aLevels[i].chartid,sLine1Name, OBJ_HLINE, 0, aLevels[i].level1,0,0, eHLineStyle, cLineColor, iHLineWidth, bSelection)>0) Print("Ошибка "+GetLastError());
//         if(fObjectCreate(aLevels[i].chartid,sLine2Name, OBJ_HLINE, 0, aLevels[i].level2,0,0, eHLineStyle, cLineColor, iHLineWidth, bSelection)>0) Print("Ошибка "+GetLastError());
/*
      //трендовая линия - не перерисовывается если уже нанесена на график
      if(ObjectFind(aLevels[i].chartid,sTrendLineName))
         Print(aLevels[i].ticket + ": PRO_Trendline level = "+DoubleToStr(ObjectGetDouble(aLevels[i].chartid, sTrendLineName,OBJPROP_PRICE2,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)))));
      else
        {
         dtStartDate=iTime(aLevels[i].ticket,PERIOD_H1,iBarShift(aLevels[i].ticket,PERIOD_H1,dtWeekStart)-1);
         if(aLevels[i].correct_level>0)
            dPrice2=aLevels[i].correct_level;
         else
            if(bLong)
               dPrice2=iHigh(aLevels[i].ticket,PERIOD_W1,0);
            else
               dPrice2=iLow(aLevels[i].ticket,PERIOD_W1,0);
         Print("testing datetime: " + aLevels[i].correct_time);
         if(aLevels[i].correct_time>0)
            dtEndDate=aLevels[i].correct_time;
         else
            dtEndDate=iTime(aLevels[i].ticket,PERIOD_W1,0)+36*60*60;
         if(fObjectCreate(aLevels[i].chartid, sTrendLineName, OBJ_TREND, dtStartDate, iOpen(aLevels[i].ticket,PERIOD_W1,0),dtEndDate,dPrice2, eHLineStyle, cLineColor, 2, true)>0) Print("Ошибка "+GetLastError());
         }
      

      //первый тейк
      dtStartDate = TimeCurrent()+24*60*60;
      dtEndDate = TimeCurrent()+32*60*60;
      dPrice1 = aLevels[i].level1;
      if(bLong)
         dPrice2 = aLevels[i].level1+aLevels[i].take1/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice2 = aLevels[i].level1-aLevels[i].take1/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fObjectCreate(aLevels[i].chartid,sTake1Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection)>0) Print("Ошибка "+GetLastError());

      //второй тейк
      dtStartDate = TimeCurrent()+36*60*60;
      dtEndDate = TimeCurrent()+44*60*60;
      dPrice1 = aLevels[i].level2;
      if(bLong)
         dPrice2 = aLevels[i].level2+aLevels[i].take2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      else
         dPrice2 = aLevels[i].level2-aLevels[i].take2/MathPow(10,int(MarketInfo(aLevels[i].ticket,MODE_DIGITS)));
      if(fObjectCreate(aLevels[i].chartid,sTake2Name,OBJ_RECTANGLE,dtStartDate,dPrice1,dtEndDate,dPrice2,0,cRectColor,0, bSelection)>0) Print("Ошибка "+GetLastError());
*/
      }

  }
//+------------------------------------------------------------------+
