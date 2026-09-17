#ifndef LEVEL_PANEL_MQH
#define LEVEL_PANEL_MQH
color C_PANEL=C'15,22,29',C_HEADER=C'17,25,34',C_ROW=C'18,27,35',C_SETTINGS=C'25,36,47';
color C_BORDER=C'46,61,77',C_TEXT=C'226,233,241',C_MUTED=C'137,153,169',C_INPUT=C'12,20,28',C_BLUE=C'31,134,255';
bool details_open=false;
int activation_first=0;
string import_path="LevelsZones\\scenario.json",menu_target="",menu_options[];
int menu_first=0;
int settings_y=-1,last_shown=0,palette_row=-1;
bool palette_fill=false;
// Cache positions as controls are built. Dragging never reads them back from MT5.
struct PanelControl { string name; int x,y; };
PanelControl panel_controls[];
color palette[]={C'130,73,255',C'170,185,199',C'31,134,255',C'255,126,18',C'43,205,95',C'255,67,74',C'255,218,26',C'39,169,255',clrWhite,clrMagenta,clrTeal,clrPink,clrOrange,clrGold,clrLime,clrSilver};
string UI(const string s) { return "LZ_UI_"+s; }
void Place(const string id,const int x,const int y,const int w,const int h,const int z)
{
   int n=ArraySize(panel_controls); ArrayResize(panel_controls,n+1,256);
   panel_controls[n].name=id; panel_controls[n].x=x-panel_x; panel_controls[n].y=y-panel_y;
   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   if(w>0) ObjectSetInteger(0,id,OBJPROP_XSIZE,w);
   if(h>0) ObjectSetInteger(0,id,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,id,OBJPROP_BACK,false); ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true); ObjectSetInteger(0,id,OBJPROP_ZORDER,z);
}
void Box(const string name,const int x,const int y,const int w,const int h,const color bg,const color border,const int z=100)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0); Place(id,x,y,w,h,z);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,id,OBJPROP_COLOR,border);
   ObjectSetInteger(0,id,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetString(0,id,OBJPROP_TOOLTIP,"\n");
}
void Txt(const string name,const string text,const int x,const int y,const int font=9,const color clr=clrNONE)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_LABEL,0,0,0); Place(id,x,y,0,0,110);
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clr==clrNONE?C_TEXT:clr);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,(int)MathRound(font*font_scale)));
   ObjectSetString(0,id,OBJPROP_FONT,"Arial"); ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_TOOLTIP,"\n");
}
void Btn(const string name,const string text,const int x,const int y,const int w,const int h,const color bg,const color fg,const string tip="",const int z=130)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_BUTTON,0,0,0); Place(id,x,y,w,h,z);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,id,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,C_BORDER); ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,(int)MathRound(9*font_scale)));
   ObjectSetInteger(0,id,OBJPROP_STATE,false); ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetString(0,id,OBJPROP_TEXT,text); ObjectSetString(0,id,OBJPROP_TOOLTIP,tip==""?text:tip);
}
void Input(const string name,const string value,const int x,const int y,const int w,const bool center=false,const int z=140)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_EDIT,0,0,0); Place(id,x,y,w,PX(26),z);
   ObjectSetString(0,id,OBJPROP_TEXT,value); ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,(int)MathRound(9*font_scale))); ObjectSetInteger(0,id,OBJPROP_COLOR,C_TEXT);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,C_INPUT); ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,C_BORDER);
   ObjectSetInteger(0,id,OBJPROP_READONLY,false); ObjectSetInteger(0,id,OBJPROP_ALIGN,center?ALIGN_CENTER:ALIGN_LEFT);
}
void SyncInputs()
{
   for(int i=first_row;i<last_shown && i<ArraySize(draft);i++)
   {
      string k=IntegerToString(i),id=UI("NAME_"+k);
      if(ObjectFind(0,id)>=0) draft[i].name=ObjectGetString(0,id,OBJPROP_TEXT);
      id=UI("FROM_"+k); if(ObjectFind(0,id)>=0) draft[i].from=ObjectGetString(0,id,OBJPROP_TEXT);
      id=UI("TO_"+k); if(ObjectFind(0,id)>=0 && draft[i].value_type=="ZONE") draft[i].to=ObjectGetString(0,id,OBJPROP_TEXT);
      id=UI("TF_"+k); if(ObjectFind(0,id)>=0) draft[i].timeframe=Trim(ObjectGetString(0,id,OBJPROP_TEXT));
   }
   if(ObjectFind(0,UI("TRIGGER"))>=0) draft_scenario.trigger_tf=Trim(ObjectGetString(0,UI("TRIGGER"),OBJPROP_TEXT));
   if(details_open && ObjectFind(0,UI("SNAPSHOT"))>=0)
   {
      draft_scenario.latest_snapshot_id=Trim(ObjectGetString(0,UI("SNAPSHOT"),OBJPROP_TEXT));
      draft_scenario.source=Trim(ObjectGetString(0,UI("SOURCE"),OBJPROP_TEXT));
      draft_scenario.generated_at=Trim(ObjectGetString(0,UI("GENERATED"),OBJPROP_TEXT));
      import_path=Trim(ObjectGetString(0,UI("IMPORT_PATH"),OBJPROP_TEXT));
   }
   if(ObjectFind(0,UI("ACT_0"))>=0)
   {
      string lines[];int n=StringSplit(draft_scenario.activation_condition,'\n',lines);
      if(n<activation_first+3){ArrayResize(lines,activation_first+3);n=activation_first+3;}
      for(int j=0;j<3;j++)lines[activation_first+j]=ObjectGetString(0,UI("ACT_"+IntegerToString(j)),OBJPROP_TEXT);
      string text="";for(int j=0;j<n;j++)text+=(j>0?"\n":"")+lines[j];
      while(StringLen(text)>0 && StringSubstr(text,StringLen(text)-1)=="\n")text=StringSubstr(text,0,StringLen(text)-1);
      draft_scenario.activation_condition=text;
   }
}
bool Dirty() { return !SameLevels(draft,levels) || !SameScenario(draft_scenario,g_scenario); }
void StatusLine()
{
   string text=status;
   if(text=="") text=Dirty()?"Draft autosaved | Apply to draw":"Saved  |  "+_Symbol;
   ObjectSetString(0,UI("STATUS"),OBJPROP_TEXT,StringLen(text)>69?StringSubstr(text,0,66)+"...":text);
   ObjectSetString(0,UI("STATUS"),OBJPROP_TOOLTIP,text);
   ObjectSetInteger(0,UI("STATUS"),OBJPROP_COLOR,status!=""?C'255,187,75':C_MUTED);
}
color StateColor(const string state)
{
   if(state=="FAILED"||state=="INVALIDATED")return C'209,124,128';
   if(StringFind(state,"CONFIRMED")>=0||state=="READY"||state=="ENTRY_READY")return C'124,189,150';
   if(state=="ACTIVE"||state=="FILLED")return C'111,184,210';
   return C_MUTED;
}
void OpenMenu(const string target,const string options)
{ menu_target=target;menu_first=0;StringSplit(options,'|',menu_options); }
int SettingsH(const int i) { return PX(170); }
void DrawSettings(const int i,const int y)
{
   string k=IntegerToString(i);settings_y=-1;
   Box("SET_BG",panel_x+PX(12),y,PX(PANEL_W-24),SettingsH(i),C_SETTINGS,C_BORDER);
   Btn("TYPE_"+k,draft[i].value_type,panel_x+PX(24),y+PX(8),PX(94),PX(26),C_INPUT,C_TEXT,"Select Level or Zone");
   Txt("SET_ID","ID "+IntegerToString(draft[i].key)+"  |  "+draft[i].semantic_type,panel_x+PX(132),y+PX(15),8,C_MUTED);
   if(draft[i].semantic_type=="TP")Btn("TARGET_"+k,"Target "+IntegerToString(draft[i].target_index),panel_x+PX(560),y+PX(43),PX(122),PX(26),C_INPUT,C_TEXT,"TP number used in validation");
   Txt("SET_HELP","Edit name and TF in the row above",panel_x+PX(416),y+PX(15),8,C_MUTED);
   Btn("SCOLOR_"+k,"Color",panel_x+PX(24),y+PX(43),PX(66),PX(26),draft[i].stroke,clrBlack,"Line / border color");
   Btn("WIDTH_"+k,"Width "+IntegerToString(draft[i].width),panel_x+PX(104),y+PX(43),PX(92),PX(26),C_INPUT,C_TEXT);
   Btn("STYLE_"+k,draft[i].dashed?"Dashed":"Solid",panel_x+PX(208),y+PX(43),PX(94),PX(26),C_INPUT,C_TEXT);
   Btn("LABEL_"+k,draft[i].show_label?"Label ON":"Label OFF",panel_x+PX(316),y+PX(43),PX(106),PX(26),C_INPUT,C_TEXT);
   Btn("POSITION_"+k,draft[i].label_position,panel_x+PX(434),y+PX(43),PX(98),PX(26),C_INPUT,C_TEXT,"Label position");
   Btn("SSTATE_"+k,draft[i].state,panel_x+PX(24),y+PX(80),PX(210),PX(26),C_INPUT,StateColor(draft[i].state),"Manual state only");
   if(draft[i].value_type=="ZONE")
   {
      Btn("FILL_"+k,"Fill",panel_x+PX(250),y+PX(80),PX(64),PX(26),draft[i].fill,clrBlack);
      Btn("OPACITY_"+k,"Fill "+IntegerToString(100-draft[i].transparency)+"%",panel_x+PX(328),y+PX(80),PX(116),PX(26),C_INPUT,C_TEXT,"Fill opacity: 0 to 100%");
      Btn("BORDER_"+k,"Border "+IntegerToString(draft[i].border_opacity)+"%",panel_x+PX(458),y+PX(80),PX(122),PX(26),C_INPUT,C_TEXT,"Border opacity: 0 to 100%");
   }
   Btn("MOVEUP_"+k,"Move up",panel_x+PX(24),y+PX(124),PX(94),PX(26),C_INPUT,C_TEXT,"Reorder this field");
   Btn("MOVEDOWN_"+k,"Move down",panel_x+PX(130),y+PX(124),PX(100),PX(26),C_INPUT,C_TEXT,"Reorder this field");
   Btn("DEL_"+k,"Delete row",panel_x+PX(250),y+PX(124),PX(112),PX(26),C_INPUT,C'209,124,128');
   Txt("SET_HINT","Zone: From <= To. Blank values remain undefined.",panel_x+PX(378),y+PX(132),8,C_MUTED);
}
void DrawRow(const int i,const int y)
{
   string k=IntegerToString(i);color bg=i%2==0?C_ROW:C'20,29,38';
   Box("ROW_"+k,panel_x+PX(10),y,PX(PANEL_W-20),PX(33),bg,C'36,49,63');
   Box("ACCENT_"+k,panel_x+PX(12),y+PX(7),PX(4),PX(20),draft[i].stroke,draft[i].stroke);
   Input("NAME_"+k,draft[i].name,panel_x+PX(21),y+PX(4),PX(137));
   Input("FROM_"+k,draft[i].from,panel_x+PX(162),y+PX(4),PX(83),true);
   Input("TO_"+k,draft[i].to,panel_x+PX(249),y+PX(4),PX(83),true);
   if(draft[i].value_type=="LEVEL") {ObjectSetInteger(0,UI("TO_"+k),OBJPROP_READONLY,true);ObjectSetInteger(0,UI("TO_"+k),OBJPROP_BGCOLOR,bg);ObjectSetString(0,UI("TO_"+k),OBJPROP_TOOLTIP,"Level: To is disabled. Change Type in settings for a zone.");}
   Input("TF_"+k,draft[i].timeframe,panel_x+PX(336),y+PX(4),PX(63),true);
   Btn("STATE_"+k,draft[i].state,panel_x+PX(403),y+PX(4),PX(154),PX(26),C_INPUT,StateColor(draft[i].state),draft[i].state+" | Manual state");
   Btn("COLOR_"+k,"",panel_x+PX(565),y+PX(6),PX(25),PX(23),draft[i].stroke,C_TEXT,"Line / border color");
   Btn("VIS_"+k,draft[i].visible?"ON":"OFF",panel_x+PX(596),y+PX(4),PX(34),PX(26),bg,draft[i].visible?C_TEXT:C_MUTED);
   Btn("LOCK_"+k,draft[i].locked?"L":"U",panel_x+PX(634),y+PX(4),PX(27),PX(26),bg,draft[i].locked?C_TEXT:C_BLUE,"Prevent chart dragging; panel edits remain allowed");
   Btn("SET_"+k,expanded==i?"^":"...",panel_x+PX(666),y+PX(4),PX(39),PX(26),bg,C_TEXT,"Field settings");
}
void DrawScenarioHeader(const int y)
{
   Txt("DIRECTION_LABEL",draft_scenario.mode=="SETUP"?"Scenario":"Direction",panel_x+PX(14),y+PX(8),8,C_MUTED);
   Btn("DIRECTION",draft_scenario.direction,panel_x+PX(82),y+PX(2),PX(136),PX(26),C_INPUT,C_TEXT);
   Btn("MODE",draft_scenario.mode,panel_x+PX(230),y+PX(2),PX(148),PX(26),C_INPUT,C_TEXT,"Changing mode starts an empty scenario after confirmation");
   Txt("TRIGGER_LABEL","Trigger TF",panel_x+PX(390),y+PX(8),8,C_MUTED);
   Input("TRIGGER",draft_scenario.trigger_tf,panel_x+PX(459),y+PX(2),PX(59),true);
   Btn("DETAILS",details_open?"Back to levels":"Scenario / Import",panel_x+PX(535),y+PX(2),PX(170),PX(26),C_ROW,C_TEXT);
   Txt("GENERAL_LABEL","Status",panel_x+PX(14),y+PX(42),8,C_MUTED);
   Btn("OVERALL",draft_scenario.overall_status,panel_x+PX(82),y+PX(36),PX(225),PX(26),C_INPUT,StateColor(draft_scenario.overall_status));
   if(draft_scenario.mode=="OPEN_POSITION") Btn("DECISION",draft_scenario.decision,panel_x+PX(319),y+PX(36),PX(198),PX(26),C_INPUT,C_TEXT,"Manual decision; does not execute it");
   if(draft_scenario.mode=="OPEN_POSITION")
   {
      string open="--",bid="--",ask="--";
      for(int i=0;i<ArraySize(draft);i++)
      {
         string value=EmptyPrice(draft[i].from)?"--":draft[i].from;
         if(draft[i].semantic_type=="OPEN_PRICE")open=value;
         if(draft[i].semantic_type=="CURRENT_BID")bid=value;
         if(draft[i].semantic_type=="CURRENT_ASK")ask=value;
      }
      Txt("POSITION_QUOTES","Open: "+open+"    Bid: "+bid+"    Ask: "+ask+"  |  supplied values",panel_x+PX(14),y+PX(74),8,C_MUTED);
   }
   string provenance=StaleScenario(draft_scenario)?"OLD SNAPSHOT | "+draft_scenario.snapshot_id+" -> "+draft_scenario.latest_snapshot_id:"Snapshot: "+(draft_scenario.snapshot_id==""?"not assigned":draft_scenario.snapshot_id)+" | "+draft_scenario.source;
   Txt("PROVENANCE",StringLen(provenance)>98?StringSubstr(provenance,0,95)+"...":provenance,panel_x+PX(14),y+PX(draft_scenario.mode=="OPEN_POSITION"?98:74),8,StaleScenario(draft_scenario)?C'235,175,90':C_MUTED);
   ObjectSetString(0,UI("PROVENANCE"),OBJPROP_TOOLTIP,provenance);
}
void DrawDetails(const int y)
{
   Txt("DETAIL_TITLE","Snapshot provenance",panel_x+PX(20),y+PX(12),11);
   Txt("BOUND","Levels belong to: "+(draft_scenario.snapshot_id==""?"unassigned":draft_scenario.snapshot_id),panel_x+PX(20),y+PX(44),9,C_MUTED);
   Txt("SNAP_LABEL","Latest snapshot",panel_x+PX(20),y+PX(81),9);
   Input("SNAPSHOT",draft_scenario.latest_snapshot_id,panel_x+PX(154),y+PX(73),PX(354));
   Btn("BIND","Use for these levels",panel_x+PX(PANEL_W),y+PX(73),PX(181),PX(26),C_ROW,C_TEXT,"Explicitly attribute the current levels to this snapshot");
   Txt("SOURCE_LABEL","Source",panel_x+PX(20),y+PX(118),9);
   Input("SOURCE",draft_scenario.source,panel_x+PX(154),y+PX(110),PX(182));
   Txt("GENERATED_LABEL","Generated at",panel_x+PX(350),y+PX(118),9);
   Input("GENERATED",draft_scenario.generated_at,panel_x+PX(450),y+PX(110),PX(250));
   Txt("IMPORT_LABEL","JSON in MQL5/Files",panel_x+PX(20),y+PX(158),9);
   Input("IMPORT_PATH",import_path,panel_x+PX(188),y+PX(150),PX(385));
   Btn("IMPORT","Import",panel_x+PX(587),y+PX(150),PX(113),PX(26),C_BLUE,clrWhite);
   Txt("IMPORT_HELP","Import replaces all fields in the draft. Review, then Apply to draw.",panel_x+PX(20),y+PX(190),9,C_MUTED);
   Txt("SNAP_HELP","Changing Latest snapshot alone keeps the original provenance and marks OLD SNAPSHOT.",panel_x+PX(20),y+PX(219),8,C_MUTED);
   Txt("MANUAL_HELP","State, direction, decision and conditions are manual. No condition is evaluated.",panel_x+PX(20),y+PX(248),8,C_MUTED);
}
void DrawMenu()
{
   if(confirm_action!="")
   {
      int x=panel_x+PX(24),y=panel_y+PX(160);
      Box("CONFIRM_BG",x,y,PX(672),PX(136),C_HEADER,C_BLUE,400);
      Txt("CONFIRM_TEXT",confirm_text,x+PX(14),y+PX(20),9);
      Btn("CONFIRM_YES","Confirm",x+PX(384),y+PX(82),PX(124),PX(32),C_BLUE,clrWhite,"Confirm action",450);
      Btn("CONFIRM_NO","Cancel",x+PX(526),y+PX(82),PX(124),PX(32),C_ROW,C_TEXT,"Keep current data",450);
      return;
   }
   if(menu_target=="")return;
   int x=panel_x+PX(235),y=panel_y+PX(120),n=ArraySize(menu_options);
   Box("MENU_BG",x,y,PX(360),PX(334),C_HEADER,C_BLUE,400);
   for(int j=0;j<8 && menu_first+j<n;j++)Btn("MENU_"+IntegerToString(menu_first+j),menu_options[menu_first+j],x+PX(12),y+PX(12+j*34),PX(336),PX(29),C_INPUT,C_TEXT,"Select",450);
   Btn("MENU_PREV","Previous",x+PX(12),y+PX(294),PX(98),PX(28),C_ROW,C_TEXT,"Previous options",450);
   Btn("MENU_NEXT","Next",x+PX(122),y+PX(294),PX(98),PX(28),C_ROW,C_TEXT,"Next options",450);
   Btn("MENU_CANCEL","Cancel",x+PX(232),y+PX(294),PX(116),PX(28),C_ROW,C_TEXT,"Close",450);
}
void DrawPalette()
{
   if(palette_row<0 || palette_row>=ArraySize(draft)) return;
   int x=panel_x+PX(76),y=panel_y+PX(90);
   Box("PAL_BG",x,y,PX(370),PX(176),C_HEADER,C_BLUE,300);
   Txt("PAL_TITLE",palette_fill?"Fill color":"Line / border color",x+PX(12),y+PX(10),10);
   for(int i=0;i<ArraySize(palette);i++)
      Btn("PAL_"+IntegerToString(i),"",x+PX(12+(i%8)*43),y+PX(39+(i/8)*35),PX(33),PX(27),palette[i],C_TEXT,HexColor(palette[i]),330);
   Txt("PAL_HEX_LABEL","HEX",x+PX(12),y+PX(124),9);
   Input("PAL_HEX",HexColor(palette_fill?draft[palette_row].fill:draft[palette_row].stroke),x+PX(50),y+PX(117),PX(116),true,340);
   Btn("PAL_OK","OK",x+PX(184),y+PX(116),PX(65),PX(29),C_BLUE,clrWhite,"Apply HEX color",350);
   Btn("PAL_CANCEL","Cancel",x+PX(260),y+PX(116),PX(94),PX(29),C_INPUT,C_TEXT,"Close color picker",350);
}
void BuildPanel()
{
   ObjectsDeleteAll(0,"LZ_UI_");ArrayResize(panel_controls,0);settings_y=-1;
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   panel_x=IClamp(panel_x,0,MathMax(0,cw-PX(PANEL_W)));
   int extra=draft_scenario.mode=="OPEN_POSITION"?24:0;
   int count=ArraySize(draft),wanted=PX(48+100+extra+28+206)+MathMax(1,count)*PX(34)+(expanded>=0&&expanded<count?SettingsH(expanded)+PX(6):0);
   if(details_open)wanted=PX(48+100+extra+300+206);
   panel_h=panel_collapsed?PX(44):MathMin(wanted,MathMax(PX(540),ch-PX(24)));
   panel_y=IClamp(panel_y,0,MathMax(0,ch-panel_h));last_shown=first_row;
   if(panel_hidden){Btn("OPEN","Levels and Zones",MathMax(0,cw-PX(150)),PX(12),PX(138),PX(32),C_HEADER,C_TEXT,"Open panel");return;}
   Box("BG",panel_x,panel_y,PX(PANEL_W),panel_h,C_PANEL,C_BORDER);
   Box("HEADER",panel_x,panel_y,PX(PANEL_W),PX(44),C_HEADER,C_BORDER);
   Txt("TITLE","::  Levels and Zones",panel_x+PX(14),panel_y+PX(12),12);
   Txt("SYMBOL",_Symbol,panel_x+PX(500),panel_y+PX(14),10);
   Btn("MIN",panel_collapsed?"+":"-",panel_x+PX(PANEL_W-76),panel_y+PX(8),PX(28),PX(27),C_HEADER,C_MUTED,"Collapse / expand panel");
   Btn("CLOSE","x",panel_x+PX(PANEL_W-40),panel_y+PX(8),PX(27),PX(27),C_HEADER,C_MUTED,"Hide panel and keep drawings");
   if(panel_collapsed)return;
   DrawScenarioHeader(panel_y+PX(48));
   int y=panel_y+PX(148+extra),footer=panel_y+panel_h-PX(206);
   if(details_open)DrawDetails(y);
   else
   {
      string cols[]={"Name","Price / From","To","TF","State","Color","Vis","Lock","..."};int xs[]={21,162,275,347,411,562,598,633,674};
      for(int j=0;j<9;j++)Txt("COL_"+IntegerToString(j),cols[j],panel_x+PX(xs[j]),y+PX(7),8,C_MUTED);
      y+=PX(28);first_row=IClamp(first_row,0,MathMax(0,count-1));last_shown=first_row;
      for(int i=first_row;i<count;i++)
      {
         int h=PX(34)+(expanded==i?SettingsH(i)+PX(6):0);if(y+h>footer)break;
         DrawRow(i,y);y+=PX(34);last_shown=i+1;
         if(expanded==i){DrawSettings(i,y);y+=SettingsH(i)+PX(6);}
      }
   }
   Box("FOOTER",panel_x,footer,PX(PANEL_W),PX(206),C_PANEL,C_BORDER);
   Txt("ACT_LABEL","Activation condition (description only)",panel_x+PX(14),footer+PX(7),9,C_MUTED);
   Btn("ACT_UP","^",panel_x+PX(647),footer+PX(3),PX(27),PX(23),C_ROW,C_TEXT,"Previous condition line");
   Btn("ACT_DOWN","v",panel_x+PX(679),footer+PX(3),PX(27),PX(23),C_ROW,C_TEXT,"Next condition line; add more lines");
   string lines[];int n=StringSplit(draft_scenario.activation_condition,'\n',lines);
   for(int j=0;j<3;j++)Input("ACT_"+IntegerToString(j),activation_first+j<n?lines[activation_first+j]:"",panel_x+PX(14),footer+PX(31+j*27),PX(692));
   Btn("ADD","+ Add field",panel_x+PX(14),footer+PX(119),PX(126),PX(28),C_ROW,C_TEXT);
   Btn("UP","Up",panel_x+PX(151),footer+PX(119),PX(40),PX(28),C_ROW,C_MUTED,"Scroll rows up");
   Btn("DOWN","Down",panel_x+PX(195),footer+PX(119),PX(49),PX(28),C_ROW,C_MUTED,"Scroll rows down");
   Btn("RELOAD","Load last scenario",panel_x+PX(258),footer+PX(119),PX(166),PX(28),C_ROW,C_TEXT,"Discard draft and load the last applied scenario");
   Btn("CLEAR","Clear all",panel_x+PX(438),footer+PX(119),PX(116),PX(28),C_ROW,C_TEXT,"Clear prices and this indicator's drawings after confirmation");
   Btn("APPLY","Apply",panel_x+PX(568),footer+PX(119),PX(138),PX(37),C_BLUE,clrWhite,"Validate, draw, save and sync this symbol");
   Txt("COUNT",IntegerToString(count)+" fields | rows "+IntegerToString(count==0?0:first_row+1)+"-"+IntegerToString(last_shown)+" | condition lines "+IntegerToString(activation_first+1)+"-"+IntegerToString(activation_first+3),panel_x+PX(15),footer+PX(160),8,C_MUTED);
   Txt("STATUS","",panel_x+PX(15),footer+PX(184),8,C_MUTED);StatusLine();DrawPalette();DrawMenu();ChartRedraw();
}
bool InPanel(const int x,const int y)
{
   if(panel_hidden) return false;
   return x>=panel_x && x<=panel_x+PX(PANEL_W) && y>=panel_y && y<=panel_y+panel_h;
}
int ControlIndex(const string name,const string prefix)
{
   string full=UI(prefix+"_"); if(StringFind(name,full)!=0) return -1;
   string tail=StringSubstr(name,StringLen(full));
   if(tail=="") return -1;
   for(int j=0;j<StringLen(tail);j++) if(StringGetCharacter(tail,j)<'0' || StringGetCharacter(tail,j)>'9') return -1;
   int i=(int)StringToInteger(tail); return i>=0 && i<ArraySize(draft)?i:-1;
}
#endif
