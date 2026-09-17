// Levels and Zones - drawing-only indicator, inspired by the supplied GUI reference.
#property strict
#property version "1.03"
#property description "Draw horizontal lines and zones. Save and sync by symbol."
#property indicator_chart_window
#property indicator_plots 0
#property indicator_buffers 0
#include "LevelModel.mqh"
#include "LevelStore.mqh"
input double PanelScale=1.0; // Panel scale (0.75 - 1.75)
#define SYNC_EVENT 17051
Level levels[],draft[],drag_before[];
long g_revision=0,seen_revision=0;
string status="";
string instance_lock="";
int panel_x=20,panel_y=12,panel_h=0,first_row=0,expanded=-1;
bool panel_hidden=false,panel_collapsed=false,initialized=false;
double scale=1, font_scale=1;
int PX(const int n) { return (int)MathRound(n*scale); }
int DP(const int n) { return (int)MathRound(n*scale/font_scale); }
#include "LevelRenderer.mqh"
#include "LevelPanel.mqh"
bool old_mouse_move=false,old_scroll=true,old_foreground=false,scroll_captured=false;
bool left_down=false,editing=false;
int drag_kind=0,drag_index=-1,drag_x=0,drag_y=0,origin_x=0,origin_y=0;
int drag_limit_x=0,drag_limit_y=0;
ulong last_panel_frame=0;
double drag_a=0,drag_b=0,drag_step=0;
uint timer_count=0;
string ViewPath() { return "LevelsZones\\view_"+IntegerToString(ChartID())+"_"+SymbolKey(_Symbol)+".bin"; }
void SaveView()
{
   FolderCreate("LevelsZones"); int f=FileOpen(ViewPath(),FILE_WRITE|FILE_BIN);
   if(f==INVALID_HANDLE) return;
   FileWriteInteger(f,panel_x); FileWriteInteger(f,panel_y);
   FileWriteInteger(f,panel_collapsed?1:0); FileWriteInteger(f,panel_hidden?1:0); FileClose(f);
}
void LoadView()
{
   int f=FileOpen(ViewPath(),FILE_READ|FILE_BIN);
   if(f==INVALID_HANDLE) return;
   if(FileSize(f)==16)
   {
      panel_x=FileReadInteger(f); panel_y=FileReadInteger(f);
      panel_collapsed=FileReadInteger(f)!=0; panel_hidden=FileReadInteger(f)!=0;
   }
   FileClose(f);
}
void CaptureScroll(const bool capture)
{
   if(capture==scroll_captured) return;
   ChartSetInteger(0,CHART_MOUSE_SCROLL,capture?false:old_scroll); scroll_captured=capture;
}
void NotifyCharts(const bool cleared=false)
{
   for(long id=ChartFirst();id>=0;id=ChartNext(id))
      if(id!=ChartID() && ChartSymbol(id)==_Symbol) EventChartCustom(id,SYNC_EVENT,g_revision,cleared?1.0:0.0,_Symbol);
}
bool CommitDraft()
{
   SyncInputs(); Level normalized[]; CopyLevels(normalized,draft);
   for(int i=0;i<ArraySize(normalized);i++)
   {
      string error;
      if(!ValidateLevel(normalized[i],_Digits,error))
      {
         status=normalized[i].name+": "+error; first_row=i; expanded=-1;
         BuildPanel(); return false;
      }
   }
   long next=g_revision;
   if(!SaveLevels(_Symbol,_Digits,normalized,g_revision,next,status)) { StatusLine(); return false; }
   g_revision=next; seen_revision=next; CopyLevels(levels,normalized); CopyLevels(draft,normalized);
   status=""; editing=false; BuildPanel(); RenderLevels(); SaveView(); NotifyCharts(); return true;
}
bool ClearAllPrices()
{
   SyncInputs(); Level cleared[]; CopyLevels(cleared,draft);
   for(int i=0;i<ArraySize(cleared);i++)
   {
      cleared[i].from=""; cleared[i].to="";
      string error;
      if(!ValidateLevel(cleared[i],_Digits,error))
      { status=cleared[i].name+": "+error; StatusLine(); return false; }
   }
   long next=g_revision;
   if(!SaveLevels(_Symbol,_Digits,cleared,g_revision,next,status)) { StatusLine(); return false; }
   g_revision=next; seen_revision=next;
   CopyLevels(levels,cleared); CopyLevels(draft,cleared);
   editing=false; palette_row=-1; expanded=-1;
   status="All prices cleared | "+_Symbol;
   BuildPanel(); RenderLevels(); SaveView(); NotifyCharts(true); return true;
}
void ReloadSaved(const bool discard)
{
   if(drag_kind!=0) return;
   Level loaded[]; long next=0; string error;
   if(!LoadLevels(_Symbol,_Digits,loaded,next,error)) { status=error; StatusLine(); return; }
   if(!discard && next==seen_revision) return;
   SyncInputs();
   bool dirty=Dirty() || editing;
   seen_revision=next;
   if(!discard && dirty)
   {
      CopyLevels(levels,loaded);
      status="Another chart updated: Reload before applying";
      StatusLine(); RenderLevels(); return;
   }
   CopyLevels(levels,loaded); CopyLevels(draft,loaded); g_revision=next;
   status=""; editing=false; palette_row=-1;
   if(expanded>=ArraySize(draft)) expanded=-1;
   BuildPanel(); RenderLevels();
}
void AddField()
{
   if(ArraySize(draft)>=LZ_MAX) { status="Maximum of 128 fields reached"; StatusLine(); return; }
   int n=ArraySize(draft),key=LZ_BASE;
   for(int i=0;i<n;i++) key=MathMax(key,draft[i].key);
   ArrayResize(draft,n+1);
   draft[n].key=key+1; draft[n].name="Level "+IntegerToString(n-LZ_BASE+1);
   draft[n].from=""; draft[n].to=""; draft[n].stroke=C'255,218,26'; draft[n].fill=draft[n].stroke;
   draft[n].width=1; draft[n].transparency=80; draft[n].visible=true; draft[n].locked=true;
   draft[n].custom=true; draft[n].dashed=false; first_row=n; expanded=-1;
}
void DeleteField(const int index)
{
   if(index<LZ_BASE || index>=ArraySize(draft)) return;
   int n=ArraySize(draft);
   for(int i=index;i<n-1;i++) draft[i]=draft[i+1];
   ArrayResize(draft,n-1); expanded=-1;
}
void SetPaletteColor(const color c)
{
   if(palette_row<0 || palette_row>=ArraySize(draft)) return;
   if(palette_fill) draft[palette_row].fill=c; else draft[palette_row].stroke=c;
   palette_row=-1; status=""; BuildPanel();
}
void ButtonClick(const string name)
{
   SyncInputs(); editing=false;
   if(palette_row>=0)
   {
      if(name==UI("PAL_CANCEL")) { palette_row=-1; BuildPanel(); return; }
      if(name==UI("PAL_OK"))
      {
         color c;
         if(ParseHex(ObjectGetString(0,UI("PAL_HEX"),OBJPROP_TEXT),c)) SetPaletteColor(c);
         else { status="Invalid HEX color; example: #1F86FF"; StatusLine(); }
         return;
      }
      for(int p=0;p<ArraySize(palette);p++) if(name==UI("PAL_"+IntegerToString(p))) { SetPaletteColor(palette[p]); return; }
      return;
   }
   status="";
   if(name==UI("OPEN")) panel_hidden=false;
   else if(name==UI("MIN")) panel_collapsed=!panel_collapsed;
   else if(name==UI("CLOSE")) panel_hidden=true;
   else if(name==UI("CLEAR")) { ClearAllPrices(); return; }
   else if(name==UI("APPLY")) { CommitDraft(); return; }
   else if(name==UI("RELOAD")) { ReloadSaved(true); return; }
   else if(name==UI("ADD")) AddField();
   else if(name==UI("UP")) first_row=MathMax(0,first_row-1);
   else if(name==UI("DOWN")) first_row=MathMin(ArraySize(draft)-1,first_row+1);
   else
   {
      int i=ControlIndex(name,"SET");
      if(i>=0) { expanded=expanded==i?-1:i; if(expanded>=0) first_row=i; }
      else if((i=ControlIndex(name,"VIS"))>=0) draft[i].visible=!draft[i].visible;
      else if((i=ControlIndex(name,"LOCK"))>=0) draft[i].locked=!draft[i].locked;
      else if((i=ControlIndex(name,"WIDTH"))>=0) draft[i].width=draft[i].width%5+1;
      else if((i=ControlIndex(name,"STYLE"))>=0) draft[i].dashed=!draft[i].dashed;
      else if((i=ControlIndex(name,"DEL"))>=0) DeleteField(i);
      else if((i=ControlIndex(name,"COLOR"))>=0 || (i=ControlIndex(name,"SCOLOR"))>=0) { palette_row=i; palette_fill=false; }
      else if((i=ControlIndex(name,"FILL"))>=0) { palette_row=i; palette_fill=true; }
      else return;
   }
   BuildPanel(); RenderLevels(); SaveView();
}
void UpdateSlider(const int x)
{
   if(expanded<0 || expanded>=ArraySize(draft)) return;
   draft[expanded].transparency=IClamp((int)MathRound(100.0*(x-panel_x-PX(166))/PX(255)),0,100);
   int fill=PX((int)MathRound(255.0*draft[expanded].transparency/100));
   ObjectSetInteger(0,UI("SLIDER_FILL"),OBJPROP_XSIZE,MathMax(1,fill));
   ObjectSetInteger(0,UI("SLIDER_KNOB"),OBJPROP_XDISTANCE,panel_x+PX(162)+fill);
   ObjectSetString(0,UI("TRANS_VALUE"),OBJPROP_TEXT,IntegerToString(draft[expanded].transparency)+"%");
   StatusLine(); ChartRedraw();
}
void DragLevel(const int y)
{
   double delta=(drag_y-y)*drag_step;
   double a=drag_a,b=drag_b,unit=MathPow(10,-_Digits);
   if(drag_kind==3)
   {
      delta=MathMax(delta,unit-a); a+=delta; b+=delta;
   }
   else if(drag_kind==1) a=MathMax(unit,MathMin(drag_a+delta,drag_b>0?drag_b-unit:1e12));
   else if(drag_kind==2) b=MathMax(drag_a+unit,drag_b+delta);
   levels[drag_index].from=DoubleToString(NormalizeDouble(a,_Digits),_Digits);
   if(b>0) levels[drag_index].to=DoubleToString(NormalizeDouble(b,_Digits),_Digits);
   string k=IntegerToString(drag_index);
   ObjectSetString(0,UI("FROM_"+k),OBJPROP_TEXT,levels[drag_index].from);
   ObjectSetString(0,UI("TO_"+k),OBJPROP_TEXT,levels[drag_index].to);
   RenderLevels();
}
void FinishDrag()
{
   int kind=drag_kind; drag_kind=0;
   if(kind>=1 && kind<=3)
   {
      CopyLevels(draft,levels);
      long next=g_revision; string error;
      if(SaveLevels(_Symbol,_Digits,levels,g_revision,next,error))
      { g_revision=next; seen_revision=next; status=""; NotifyCharts(); }
      else
      { CopyLevels(levels,drag_before); CopyLevels(draft,drag_before); status=error; }
      drag_index=-1; BuildPanel(); RenderLevels();
   }
   if(kind==10) { SaveView(); BuildPanel(); RenderLevels(); }
   if(kind==11) { BuildPanel(); }
}
void MovePanel(const int x,const int y,const bool force=false)
{
   ulong now=GetTickCount64();
   if(!force && now-last_panel_frame<33) return;
   int nx=IClamp(origin_x+x-drag_x,0,drag_limit_x);
   int ny=IClamp(origin_y+y-drag_y,0,drag_limit_y);
   if(nx==panel_x && ny==panel_y) return;
   int dy=ny-panel_y;
   for(int j=0;j<ArraySize(panel_controls);j++)
   {
      ObjectSetInteger(0,panel_controls[j].name,OBJPROP_XDISTANCE,nx+panel_controls[j].x);
      ObjectSetInteger(0,panel_controls[j].name,OBJPROP_YDISTANCE,ny+panel_controls[j].y);
   }
   panel_x=nx; panel_y=ny; if(settings_y>=0) settings_y+=dy;
   ChartRedraw(); last_panel_frame=GetTickCount64();
}
void MouseMove(const int x,const int y,const bool down)
{
   if(drag_kind!=0)
   {
      if(down)
      {
         if(drag_kind==10)
         {
            MovePanel(x,y);
         }
         else if(drag_kind==11) UpdateSlider(x);
         else DragLevel(y);
      }
      else
      {
         if(drag_kind==10) MovePanel(x,y,true);
         FinishDrag();
      }
      left_down=down; return;
   }
   bool inside=InPanel(x,y);
   int mode=0,hit=inside?-1:HitLevel(x,y,mode);
   CaptureScroll(inside || hit>=0);
   if(down && !left_down)
   {
      if(inside)
      {
         if(palette_row<0 && y<panel_y+PX(44) && x<panel_x+PX(435))
         {
            SyncInputs(); drag_kind=10; drag_x=x; drag_y=y; origin_x=panel_x; origin_y=panel_y;
            drag_limit_x=MathMax(0,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-PX(520));
            drag_limit_y=MathMax(0,(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0)-panel_h);
            last_panel_frame=0;
         }
         else if(palette_row<0 && settings_y>=0 && expanded>=0 && !EmptyPrice(draft[expanded].to) &&
                 y>=settings_y+PX(125) && y<=settings_y+PX(150) && x>=panel_x+PX(157) && x<=panel_x+PX(432))
         { SyncInputs(); drag_kind=11; UpdateSlider(x); }
      }
      else if(hit>=0)
      {
         SyncInputs();
         if(Dirty()) { status="Apply or reload the draft before dragging"; StatusLine(); }
         else
         {
            drag_kind=mode; drag_index=hit; drag_y=y;
            drag_a=StringToDouble(levels[hit].from); drag_b=StringToDouble(levels[hit].to);
            drag_step=YPrice(0)-YPrice(1); CopyLevels(drag_before,levels);
         }
      }
   }
   left_down=down;
}
int OnInit()
{
   // Chart objects are serialized into templates; they cannot prove an instance is alive.
   // This session-only lock is not part of templates and is released after teardown.
   instance_lock="LZ_ACTIVE_"+IntegerToString(ChartID());
   if((!GlobalVariableCheck(instance_lock) && !GlobalVariableTemp(instance_lock)) ||
      !GlobalVariableSetOnCondition(instance_lock,1.0,0.0))
   { Print("Levels and Zones: another instance is active, or the chart lock is unavailable."); return INIT_FAILED; }
   // Discard only this tool's restored visuals. Prices are loaded from the symbol store.
   ObjectDelete(0,"LZ_INSTANCE"); ObjectsDeleteAll(0,"LZ_UI_"); ObjectsDeleteAll(0,"LZ_TAG_");
   ObjectDelete(0,"LZ_CANVAS"); ObjectDelete(0,"LZ_HOVER");
   initialized=true; font_scale=MathMax(0.75,MathMin(1.75,PanelScale));
   scale=font_scale*MathMax(1.0,(double)TerminalInfoInteger(TERMINAL_SCREEN_DPI)/96.0);
   IndicatorSetString(INDICATOR_SHORTNAME,"Levels and Zones");
   old_mouse_move=(bool)ChartGetInteger(0,CHART_EVENT_MOUSE_MOVE);
   old_scroll=(bool)ChartGetInteger(0,CHART_MOUSE_SCROLL);
   old_foreground=(bool)ChartGetInteger(0,CHART_FOREGROUND);
   ChartSetInteger(0,CHART_FOREGROUND,false);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   if(!LoadLevels(_Symbol,_Digits,levels,g_revision,status)) { DefaultLevels(levels); g_revision=0; }
   seen_revision=g_revision; CopyLevels(draft,levels);
   panel_x=MathMax(0,(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-PX(532)); panel_y=PX(12); LoadView();
   // Canvas first so UI objects remain in front even after a chart refresh.
   RenderLevels(); BuildPanel(); RenderLevels();
   if(!EventSetMillisecondTimer(250)) { status="Timer unavailable"; StatusLine(); return INIT_FAILED; }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason)
{
   if(!initialized) return;
   EventKillTimer(); SaveView(); CaptureScroll(false);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,old_mouse_move);
   ChartSetInteger(0,CHART_FOREGROUND,old_foreground);
   DestroyDrawing(); ObjectsDeleteAll(0,"LZ_UI_"); ObjectDelete(0,"LZ_INSTANCE"); ChartRedraw();
   GlobalVariableSetOnCondition(instance_lock,0.0,1.0); initialized=false;
}
void OnTimer()
{
   if(!initialized || drag_kind!=0) return;
   if(++timer_count%4==0) ReloadSaved(false);
   int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS)-72,h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   double lo=ChartGetDouble(0,CHART_PRICE_MIN,0),hi=ChartGetDouble(0,CHART_PRICE_MAX,0);
   if(w!=plot_w || h!=plot_h || lo!=view_min || hi!=view_max) RenderLevels();
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(!initialized) return;
   if(id==CHARTEVENT_MOUSE_MOVE) { MouseMove((int)lparam,(int)dparam,((uint)StringToInteger(sparam)&1)!=0); return; }
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam,"LZ_UI_")!=0) return;
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      if(ControlIndex(sparam,"NAME")>=0 || ControlIndex(sparam,"FROM")>=0 || ControlIndex(sparam,"TO")>=0 || sparam==UI("PAL_HEX"))
      { editing=true; return; }
      if(StringFind(sparam,"LZ_UI_")==0) ButtonClick(sparam);
      return;
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT && StringFind(sparam,"LZ_UI_")==0)
   { SyncInputs(); editing=false; status=""; StatusLine(); return; }
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      if(drag_kind!=0) return;
      SyncInputs(); BuildPanel(); RenderLevels(); return;
   }
   if(id==CHARTEVENT_CUSTOM+SYNC_EVENT && sparam==_Symbol) { ReloadSaved(dparam==1.0); return; }
   if(id==CHARTEVENT_KEYDOWN && lparam==27 && drag_kind!=0)
   {
      if(drag_kind>=1 && drag_kind<=3) { CopyLevels(levels,drag_before); CopyLevels(draft,drag_before); }
      if(drag_kind==10) { panel_x=origin_x; panel_y=origin_y; }
      drag_kind=0; left_down=false; CaptureScroll(false); BuildPanel(); RenderLevels();
   }
}
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
{
   return rates_total;
}
