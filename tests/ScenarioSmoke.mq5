#property strict
// Reload checks use only the synthetic symbol created by ScenarioLauncher.
int good=0,bad=0;string output="";
void Verify(bool ok,string label){output+=(ok?"PASS ":"FAIL ")+label+"\r\n";if(ok)good++;else bad++;}
bool Ready(long c)
{
   Sleep(500);
   for(int i=0;i<100&&!IsStopped();i++)
   {
      if(GlobalVariableGet("LZ_ACTIVE_"+IntegerToString(c))==1.0 && (ObjectFind(c,"LZ_UI_TITLE")>=0||ObjectFind(c,"LZ_UI_OPEN")>=0))return true;
      Sleep(100);
   }return false;
}
void OnStart()
{
   string sym="__LZ_QA_SCENARIO";long owner=ChartID(),c=0;
   for(long i=ChartFirst();i>=0;i=ChartNext(i))if(i!=owner&&ChartSymbol(i)==sym){c=i;break;}
   if(c==0)c=ChartOpen(sym,PERIOD_M1);
   if(c==0)return;
   Verify(ChartApplyTemplate(c,"LZScenarioProduction.tpl")&&Ready(c),"Installed production indicator loads saved scenario");
   Verify(ChartApplyTemplate(c,"LZScenarioProduction.tpl")&&Ready(c),"Production panel survives template reapplication");
   Verify(ChartSetSymbolPeriod(c,sym,PERIOD_H1)&&Ready(c),"Production panel survives timeframe change");
   Verify(ChartSetSymbolPeriod(c,sym,PERIOD_M1)&&Ready(c),"Production panel returns to original timeframe");
   int indicators=0;for(int i=0;i<ChartIndicatorsTotal(c,0);i++)if(ChartIndicatorName(c,0,i)=="Levels and Zones")indicators++;
   Verify(indicators==1,"One production instance remains attached");
   output+="RESULT "+IntegerToString(good)+" passed, "+IntegerToString(bad)+" failed\r\n";
   int f=FileOpen("LZ_smoke_test_results.txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);if(f!=INVALID_HANDLE){FileWriteString(f,output);FileClose(f);}Print(output);
   ChartSetInteger(c,CHART_BRING_TO_TOP,true);
   if(ChartSymbol(owner)==sym&&owner!=c)ChartClose(owner);
}
