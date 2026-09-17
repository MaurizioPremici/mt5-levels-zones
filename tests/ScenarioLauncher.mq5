#property strict
// Creates a dedicated, synthetic, non-tradable symbol and chart. No account APIs.
void OnStart()
{
   string symbol="__LZ_QA_SCENARIO";
   if(!SymbolInfoInteger(symbol,SYMBOL_CUSTOM) && !CustomSymbolCreate(symbol,"LevelsZones QA")){Print("Cannot create QA symbol ",GetLastError());return;}
   CustomSymbolSetInteger(symbol,SYMBOL_DIGITS,5);CustomSymbolSetDouble(symbol,SYMBOL_POINT,0.00001);
   CustomSymbolSetDouble(symbol,SYMBOL_TRADE_TICK_SIZE,0.00001);CustomSymbolSetInteger(symbol,SYMBOL_TRADE_MODE,SYMBOL_TRADE_MODE_DISABLED);
   MqlRates rates[];ArrayResize(rates,200);datetime start=TimeCurrent()-200*60;
   for(int i=0;i<200;i++){rates[i].time=start+i*60;rates[i].open=1.14600+i*0.000006;rates[i].close=rates[i].open+0.00001;rates[i].high=rates[i].close+0.00005;rates[i].low=rates[i].open-0.00004;rates[i].tick_volume=10;}
   CustomRatesUpdate(symbol,rates);SymbolSelect(symbol,true);
   long chart=0;for(long c=ChartFirst();c>=0;c=ChartNext(c))if(ChartSymbol(c)==symbol){chart=c;break;}
   if(chart==0)chart=ChartOpen(symbol,PERIOD_M1);if(chart==0){Print("Cannot open QA chart");return;}
   ChartSetInteger(chart,CHART_BRING_TO_TOP,true);
   ResetLastError();bool ok=ChartApplyTemplate(chart,"LZScenarioQA.tpl");int error=GetLastError();
   int f=FileOpen("LZ_launcher_result.txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(f!=INVALID_HANDLE){FileWriteString(f,"chart="+IntegerToString(chart)+" template="+(ok?"true":"false")+" error="+IntegerToString(error));FileClose(f);}
}
