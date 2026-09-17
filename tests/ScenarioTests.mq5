#property strict
#property indicator_chart_window
#property indicator_plots 0
#property indicator_buffers 0
// Integration fixture: refuses to run on a real symbol. Includes the production
// indicator so button handlers, store, renderer and UI are exercised together.
#define OnInit PluginOnInit
#define OnTimer PluginOnTimer
#include "../src/LevelsZones.mq5"
#undef OnInit
#undef OnTimer
#define OnStart CoreTests
#include "LevelTests.mq5"
#undef OnStart
int qa_passed=0,qa_failed=0;
string qa_report="";
bool qa_done=false;
void Assert(const bool ok,const string label)
{qa_report+=(ok?"PASS ":"FAIL ")+label+"\r\n";if(ok)qa_passed++;else qa_failed++;}
string Caption(const string name){return ObjectGetString(0,UI(name),OBJPROP_TEXT);}
void Click(const string name){long l=0;double d=0;string s=UI(name);OnChartEvent(CHARTEVENT_OBJECT_CLICK,l,d,s);}
void Edit(const string name,const string value){ObjectSetString(0,UI(name),OBJPROP_TEXT,value);long l=0;double d=0;string s=UI(name);OnChartEvent(CHARTEVENT_OBJECT_ENDEDIT,l,d,s);}
bool TipsContain(const string text)
{for(int i=0;i<ObjectsTotal(0);i++){string name=ObjectName(0,i);if(StringFind(name,"LZ_TAG_")==0&&StringFind(ObjectGetString(0,name,OBJPROP_TOOLTIP),text)>=0)return true;}return false;}
void WaitSell()
{
   DefaultScenario(draft_scenario,_Symbol);DefaultLevels(draft);draft_scenario.direction="WAIT -> SELL";draft_scenario.overall_status="WAITING_BREAKOUT";
   draft_scenario.snapshot_id="A";draft_scenario.latest_snapshot_id="A";draft_scenario.source="Codex";
   draft_scenario.activation_condition="M5 close < 1.14715\n-> retest from below 1.14715-1.14725\n-> rejection\n-> new M5 close < 1.14715";
   for(int i=0;i<9;i++)draft[i].timeframe="M5";
   draft[1].from="1.14715";draft[1].state="WAITING_BREAKOUT";
   draft[2].from="1.14715";draft[2].to="1.14725";draft[2].state="WAITING_RETEST";
   draft[5].from="1.14803";draft[5].to="1.14809";draft[5].value_type="ZONE";draft[5].timeframe="M5/M15";
   draft[7].from="1.14700";draft[8].from="1.14675";draft[7].state="CONDITIONAL";draft[8].state="CONDITIONAL";
   first_row=0;expanded=-1;details_open=false;panel_hidden=false;panel_collapsed=false;BuildPanel();
}
int OnInit()
{
   if(_Symbol!="__LZ_QA_SCENARIO" || !SymbolInfoInteger(_Symbol,SYMBOL_CUSTOM))return INIT_FAILED;
   return PluginOnInit();
}
void OnTimer()
{
   if(qa_done)return;qa_done=true;
   ChartSetInteger(0,CHART_SCALEFIX,true);ChartSetDouble(0,CHART_FIXED_MIN,1.14500);ChartSetDouble(0,CHART_FIXED_MAX,1.14900);ChartRedraw();
   CoreTests();Assert(failed==0,"Core price/store regression suite");
   panel_x=0;panel_y=PX(12); // Exercise compact labels with the panel against the left edge.
   WaitSell();Click("APPLY");
   int active=0;for(int i=0;i<ArraySize(levels);i++)if(ActiveLevel(i))active++;
   Assert(status==""&&active==5&&levels[0].from==""&&levels[6].from=="","1 WAIT SELL applies only five defined fields; Entry and SL stay empty");
   Assert(levels[2].value_type=="ZONE"&&levels[5].value_type=="ZONE"&&canvas_ready,"1 Retest and Resistance rendered as zones");
   Assert(Caption("OVERALL")=="WAITING_BREAKOUT"&&TipsContain("WAITING_BREAKOUT")&&TipsContain("M5/M15"),"1 Overall status, timeframe and state labels visible | "+Caption("OVERALL")+" | min="+DoubleToString(view_min,5)+" max="+DoubleToString(view_max,5));
   Assert(drawing.PixelGet(10,PriceY(1.14720))!=0,"1 Retest band has visible fill pixels");
   ChartScreenShot(0,"LevelsZones\\qa-wait-sell.png",(uint)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),(uint)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS));
   string original=levels[1].from;Click("STATE_1");SelectMenu("BREAKOUT_CONFIRMED");Click("OVERALL");SelectMenu("WAITING_RETEST");Click("APPLY");
   Assert(levels[1].from==original&&levels[1].state=="BREAKOUT_CONFIRMED"&&Caption("OVERALL")=="WAITING_RETEST","2 State change keeps the breakout price");
   Assert(TipsContain("BREAKOUT_CONFIRMED")&&(color)ObjectGetInteger(0,UI("STATE_1"),OBJPROP_COLOR)==StateColor("BREAKOUT_CONFIRMED"),"2 Chart label and row badge change");
   Click("MODE");Assert(confirm_action=="MODE","3 Mode replacement requires confirmation");Click("CONFIRM_YES");
   draft[0].from="1.14624";draft[4].from="1.14570";draft[6].from="1.14730";draft[7].from="1.14745";draft_scenario.decision="LASCIA";BuildPanel();Click("APPLY");
   Assert(g_scenario.mode=="OPEN_POSITION"&&g_scenario.direction=="LONG"&&levels[3].from==""&&levels[4].from=="1.14570","3 Current SL remains empty; management SL is separate");
   Assert(levels[5].semantic_type=="TP_CURRENT"&&levels[6].semantic_type=="TP1_MANAGEMENT"&&levels[7].semantic_type=="TP2_MANAGEMENT"&&Caption("DECISION")=="LASCIA","3 Current and proposed TP, direction and manual decision distinct");
   ChartScreenShot(0,"LevelsZones\\qa-open-position.png",(uint)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),(uint)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS));
   WaitSell();Click("APPLY");Click("DETAILS");Edit("SNAPSHOT","B");Click("APPLY");
   Assert(g_scenario.snapshot_id=="A"&&g_scenario.latest_snapshot_id=="B"&&StaleScenario(g_scenario)&&StringFind(Caption("PROVENANCE"),"OLD SNAPSHOT")>=0&&TipsContain("OLD SNAPSHOT"),"4 New snapshot leaves A prices explicitly OLD SNAPSHOT");
   ScenarioState imported;Level imported_rows[];string error;
   string json="{\"symbol\":\""+_Symbol+"\",\"snapshot_id\":\"B\",\"direction\":\"WAIT -> SELL\",\"fields\":[{\"id\":2,\"name\":\"Breakout Level\",\"semantic_type\":\"BREAKOUT\",\"value_type\":\"LEVEL\",\"from_price\":\"1.14690\"}]}";
   bool imported_ok=ParseScenarioJSON(json,_Symbol,5,imported,imported_rows,error);
   Assert(imported_ok&&ArraySize(imported_rows)==1&&imported.snapshot_id=="B","4 Full B import contains no A-only prices | "+error);
   pending_scenario=imported;CopyLevels(pending_import,imported_rows);confirm_action="IMPORT";ConfirmAction();Click("APPLY");
   Assert(ArraySize(levels)==1&&levels[0].from=="1.14690"&&!StaleScenario(g_scenario),"4 Applying B replaces the previous scenario without carrying Entry or SL");
   WaitSell();Click("APPLY");long before=g_revision;draft[2].from="1.14800";draft[2].to="1.14700";BuildPanel();Click("APPLY");
   Assert(StringFind(status,"From must")>=0&&g_revision==before&&levels[2].from=="1.14715","5 Reversed zone rejected atomically; saved and drawn prices unchanged");
   Click("RELOAD");Assert(draft[2].from=="1.14715","6 Load last scenario restores applied data");
   ObjectCreate(0,"LZ_QA_UNRELATED",OBJ_HLINE,0,0,1.1455);
   Click("CLEAR");Assert(confirm_action=="CLEAR"&&HasPrices(levels),"6 Clear waits for confirmation");Click("CONFIRM_NO");Assert(HasPrices(levels),"6 Cancel clear preserves prices");
   Click("CLEAR");Click("CONFIRM_YES");Assert(!HasPrices(levels)&&ObjectsTotal(0,0,OBJ_BUTTON)>0&&ObjectFind(0,"LZ_QA_UNRELATED")>=0&&!TipsContain("Breakout"),"6 Confirm clear removes plugin levels only");
   ObjectDelete(0,"LZ_QA_UNRELATED");
   WaitSell();Click("APPLY");Edit("TF_1","M5/M15");SaveDraftIfChanged();Level recover[];ScenarioState rm;long base;
   Assert(ReadScenarioFile(DataFile(_Symbol)+".draft",_Symbol,5,recover,rm,base,false)&&recover[1].timeframe=="M5/M15"&&base==g_revision,"Draft autosave preserves unapplied metadata with base revision");
   Edit("TF_1","M5");Assert(!FileIsExist(DataFile(_Symbol)+".draft"),"Reverting an edit removes its obsolete recovery draft");
   Click("RELOAD");Click("LOCK_1");Click("APPLY");int mode=0;int hit=HitLevel(20,PriceY(1.14715),mode);Assert(hit>=0&&!levels[hit].locked,"Unlocked chart line can be selected for dragging");
   Click("VIS_1");Click("APPLY");Assert(!ActiveLevel(1)&&levels[1].from=="1.14715","Visibility hides drawing without deleting price");
   Click("SET_2");Click("TYPE_2");SelectMenu("LEVEL");Assert(draft[2].value_type=="ZONE"&&StringFind(status,"Clear To")>=0,"Type change cannot silently delete a zone endpoint");
   string invalid="{\"symbol\":\"WRONG\",\"snapshot_id\":\"C\",\"fields\":[]}";
   Assert(!ParseScenarioJSON(invalid,_Symbol,5,imported,imported_rows,error),"Import rejects another pair");
   Assert(!ParseScenarioJSON("{\"symbol\":\"A\",\"symbol\":\"B\"}",_Symbol,5,imported,imported_rows,error),"Import rejects duplicate keys");
   invalid="{\"symbol\":\""+_Symbol+"\",\"snapshot_id\":\"B\",\"fields\":[{\"name\":\"x\",\"semantic_type\":\"CUSTOM\",\"value_type\":\"LEVEL\",\"visible\":\"false\"}]}";
   Assert(!ParseScenarioJSON(invalid,_Symbol,5,imported,imported_rows,error),"Import rejects text instead of boolean");
   WaitSell();draft_scenario.direction="SELL";draft[0].from="1.14710";draft[6].from="1.14800";BuildPanel();Assert(CommitDraft(),"Complete SELL order of levels accepted");
   draft_scenario.direction="BUY";BuildPanel();Assert(!CommitDraft(),"Inconsistent complete BUY rejected");
   // A legacy v1 file migrates without losing values, colors or visibility.
   string legacy_sym="__LZ_QA_LEGACY",legacy_path=DataFile(legacy_sym);Level legacy[];DefaultLevels(legacy);
   legacy[1].name="Breakout Price";legacy[1].from="1.14715";legacy[2].from="1.14715";legacy[2].to="1.14725";
   int old=FileOpen(legacy_path,FILE_WRITE|FILE_BIN|FILE_UNICODE);FileWriteInteger(old,STORE_MAGIC);WriteText(old,legacy_sym);FileWriteLong(old,4);FileWriteInteger(old,9);
   for(int i=0;i<9;i++){FileWriteInteger(old,legacy[i].key);WriteText(old,legacy[i].name);WriteText(old,legacy[i].from);WriteText(old,legacy[i].to);FileWriteInteger(old,(int)legacy[i].stroke);FileWriteInteger(old,(int)legacy[i].fill);FileWriteInteger(old,legacy[i].width);FileWriteInteger(old,legacy[i].transparency);FileWriteInteger(old,3);}
   FileWriteInteger(old,STORE_END);FileClose(old);long legacy_rev=0;ScenarioState legacy_meta;Level migrated[];
   Assert(LoadScenario(legacy_sym,5,migrated,legacy_meta,legacy_rev,error)&&legacy_rev==4&&migrated[1].name=="Breakout Level"&&migrated[1].from=="1.14715"&&migrated[2].to=="1.14725"&&migrated[7].target_index==1,"Legacy v1 store migrates prices, zones and TP roles");
   Assert(SaveScenario(legacy_sym,5,migrated,legacy_meta,legacy_rev,legacy_rev,error),"Migrated scenario writes the new atomic format");
   FileDelete(legacy_path);FileDelete(legacy_path+".bak");FileDelete(legacy_path+".lock");
   string import_fixture="LevelsZones\\qa-import.json";int jf=FileOpen(import_fixture,FILE_WRITE|FILE_TXT|FILE_ANSI,0,CP_UTF8);FileWriteString(jf,json);FileClose(jf);
   Assert(ImportScenarioFile(import_fixture,_Symbol,5,imported,imported_rows,error),"UTF-8 JSON file import validates the full replacement");FileDelete(import_fixture);
   WaitSell();Click("APPLY");status="QA: "+IntegerToString(qa_passed)+" passed, "+IntegerToString(qa_failed)+" failed";StatusLine();
   qa_report+="RESULT "+IntegerToString(qa_passed)+" passed, "+IntegerToString(qa_failed)+" failed\r\n";
   int h=FileOpen("LZ_scenario_test_results.txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);if(h!=INVALID_HANDLE){FileWriteString(h,qa_report);FileClose(h);}Print(qa_report);
   EventKillTimer();
}
