#property strict
// Run on a chart without another script. Uses only a separate temporary chart.
// Fixtures must contain no expert/script and only the LevelsZones indicator.
int passed=0,failed=0;
string report="";
void Check(bool ok,string label){report+=(ok?"PASS ":"FAIL ")+label+"\r\n";if(ok)passed++;else failed++;}
bool Active(long chart){
 double lock=GlobalVariableGet("LZ_ACTIVE_"+IntegerToString(chart));
 int title=ObjectFind(chart,"LZ_UI_TITLE"),button=ObjectFind(chart,"LZ_UI_OPEN");
 report+="STATE lock="+DoubleToString(lock,0)+" title="+IntegerToString(title)+" open="+IntegerToString(button)+" legacy="+IntegerToString(ObjectFind(chart,"LZ_INSTANCE"))+" indicators="+IntegerToString(ChartIndicatorsTotal(chart,0))+"\r\n";
 return lock==1.0 && (title>=0 || button>=0);
}
void WaitPanel(long chart){
 Sleep(1200);
 for(int i=0;i<100&&!IsStopped();i++){
  if(GlobalVariableGet("LZ_ACTIVE_"+IntegerToString(chart))==1.0 && (ObjectFind(chart,"LZ_UI_TITLE")>=0||ObjectFind(chart,"LZ_UI_OPEN")>=0))return;
  Sleep(100);
 }
}
void OnStart(){
 long owner=ChartID(),c=ChartOpen(_Symbol,PERIOD_M15);
 if(c==0){Print("Template test chart could not be created");return;}
 ChartSetInteger(c,CHART_BRING_TO_TOP,true);Sleep(500);
 if(StringLen(ChartGetString(c,CHART_EXPERT_NAME))>0 || StringLen(ChartGetString(c,CHART_SCRIPT_NAME))>0) {ChartClose(c);Print("Unexpected program on temporary chart");return;}
 Check(ChartApplyTemplate(c,"LZLegacyOld.tpl"),"Queue legacy build fixture");Sleep(1200);
 Check(ObjectFind(c,"LZ_INSTANCE")>=0 && ObjectFind(c,"LZ_UI_TITLE")<0,"Old build reproduces stale-marker initialization failure");
 Check(ChartApplyTemplate(c,"LZLegacy.tpl"),"Queue repaired build fixture");WaitPanel(c);
 Check(Active(c) && ObjectFind(c,"LZ_INSTANCE")<0,"Restored legacy marker no longer blocks startup");
 Check(ObjectFind(c,"LZ_UI_STALE")<0 && ObjectFind(c,"LZ_TEST_USER_OBJECT")>=0,"Only stale plugin visuals are removed");
 Check(ChartApplyTemplate(c,"LZLegacy.tpl"),"Reapply the same template");WaitPanel(c);
 Check(Active(c),"Panel survives template reapplication");
 Check(ChartSetSymbolPeriod(c,_Symbol,PERIOD_H1),"Change temporary chart timeframe");WaitPanel(c);
 Check(Active(c),"Panel restarts after timeframe change");
 Check(ChartApplyTemplate(c,"LZDuplicate.tpl"),"Queue duplicate-indicator fixture");WaitPanel(c);
 int count=0;for(int i=0;i<ChartIndicatorsTotal(c,0);i++)if(ChartIndicatorName(c,0,i)=="Levels and Zones")count++;
 Check(Active(c)&&count==1,"Duplicate instance rejected without deleting the active panel");
 Check(ChartApplyTemplate(c,"LZClean.tpl"),"Apply a template without the indicator");Sleep(1200);
 Check(!Active(c) && GlobalVariableGet("LZ_ACTIVE_"+IntegerToString(c))==0.0,"Unloading releases the runtime lock");
 Check(ChartApplyTemplate(c,"LZLegacy.tpl"),"Restore the plugin template");WaitPanel(c);
 Check(Active(c),"Plugin can be loaded again after removal");
 if(failed==0)ChartClose(c);ChartSetInteger(owner,CHART_BRING_TO_TOP,true);
 report+="RESULT "+IntegerToString(passed)+" passed, "+IntegerToString(failed)+" failed\r\n";
 int f=FileOpen("LZ_template_test_results.txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
 if(f!=INVALID_HANDLE){FileWriteString(f,report);FileClose(f);}Print(report);
}
