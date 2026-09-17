#ifndef LEVEL_PANEL_MQH
#define LEVEL_PANEL_MQH
color C_PANEL=C'15,22,29',C_HEADER=C'17,25,34',C_ROW=C'18,27,35',C_SETTINGS=C'25,36,47';
color C_BORDER=C'46,61,77',C_TEXT=C'226,233,241',C_MUTED=C'137,153,169',C_INPUT=C'12,20,28',C_BLUE=C'31,134,255';
int settings_y=-1,last_shown=0,palette_row=-1;
bool palette_fill=false;
color palette[]={C'130,73,255',C'170,185,199',C'31,134,255',C'255,126,18',C'43,205,95',C'255,67,74',C'255,218,26',C'39,169,255',clrWhite,clrMagenta,clrTeal,clrPink,clrOrange,clrGold,clrLime,clrSilver};
string UI(const string s) { return "LZ_UI_"+s; }
void Place(const string id,const int x,const int y,const int w,const int h,const int z)
{
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
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,PX(font)));
   ObjectSetString(0,id,OBJPROP_FONT,"Arial"); ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_TOOLTIP,"\n");
}
void Btn(const string name,const string text,const int x,const int y,const int w,const int h,const color bg,const color fg,const string tip="",const int z=130)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_BUTTON,0,0,0); Place(id,x,y,w,h,z);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,id,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,C_BORDER); ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,PX(9)));
   ObjectSetInteger(0,id,OBJPROP_STATE,false); ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetString(0,id,OBJPROP_TEXT,text); ObjectSetString(0,id,OBJPROP_TOOLTIP,tip==""?text:tip);
}
void Input(const string name,const string value,const int x,const int y,const int w,const bool center=false,const int z=140)
{
   string id=UI(name); ObjectCreate(0,id,OBJ_EDIT,0,0,0); Place(id,x,y,w,PX(26),z);
   ObjectSetString(0,id,OBJPROP_TEXT,value); ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,MathMax(7,PX(9))); ObjectSetInteger(0,id,OBJPROP_COLOR,C_TEXT);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,C_INPUT); ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,C_BORDER);
   ObjectSetInteger(0,id,OBJPROP_READONLY,false); ObjectSetInteger(0,id,OBJPROP_ALIGN,center?ALIGN_CENTER:ALIGN_LEFT);
}
void SyncInputs()
{
   for(int i=0;i<ArraySize(draft);i++)
   {
      string k=IntegerToString(i),id=UI("NAME_"+k);
      if(ObjectFind(0,id)>=0) draft[i].name=ObjectGetString(0,id,OBJPROP_TEXT);
      id=UI("FROM_"+k); if(ObjectFind(0,id)>=0) draft[i].from=ObjectGetString(0,id,OBJPROP_TEXT);
      id=UI("TO_"+k); if(ObjectFind(0,id)>=0) draft[i].to=ObjectGetString(0,id,OBJPROP_TEXT);
   }
}
bool Dirty() { return !SameLevels(draft,levels); }
void StatusLine()
{
   string text=status;
   if(text=="") text=Dirty()?"Modifiche da applicare":"Salvato  |  "+_Symbol;
   ObjectSetString(0,UI("STATUS"),OBJPROP_TEXT,StringLen(text)>69?StringSubstr(text,0,66)+"...":text);
   ObjectSetString(0,UI("STATUS"),OBJPROP_TOOLTIP,text);
   ObjectSetInteger(0,UI("STATUS"),OBJPROP_COLOR,status!=""?C'255,187,75':C_MUTED);
}
int SettingsH(const int i) { return PX(EmptyPrice(draft[i].to)?104:166); }
void DrawSettings(const int i,const int y)
{
   string k=IntegerToString(i); bool zone=!EmptyPrice(draft[i].to); settings_y=y;
   Box("SET_BG",panel_x+PX(12),y,PX(496),SettingsH(i),C_SETTINGS,C_BORDER);
   Txt("SET_TITLE",zone?"Impostazioni zona":"Impostazioni linea",panel_x+PX(24),y+PX(10));
   Txt("SET_CLR_TXT",zone?"Bordo":"Colore",panel_x+PX(24),y+PX(42),8);
   Btn("SCOLOR_"+k,"",panel_x+PX(73),y+PX(34),PX(30),PX(28),draft[i].stroke,C_TEXT,"Scegli colore linea");
   Txt("SET_WIDTH_TXT","Spessore",panel_x+PX(122),y+PX(42),8);
   Btn("WIDTH_"+k,IntegerToString(draft[i].width)+" px +",panel_x+PX(181),y+PX(34),PX(62),PX(28),C_INPUT,C_TEXT,"Cambia spessore: da 1 a 5 pixel");
   Txt("SET_STYLE_TXT","Stile",panel_x+PX(258),y+PX(42),8);
   Btn("STYLE_"+k,draft[i].dashed?"Tratteggiata":"Continua",panel_x+PX(294),y+PX(34),PX(112),PX(28),C_INPUT,C_TEXT,"Alterna continua / tratteggiata");
   int yy=y+PX(47),th=PX(draft[i].width);
   if(draft[i].dashed)
      for(int j=0;j<4;j++) Box("PREVIEW_"+IntegerToString(j),panel_x+PX(420+j*19),yy,PX(12),th,draft[i].stroke,draft[i].stroke,115);
   else Box("PREVIEW",panel_x+PX(420),yy,PX(70),th,draft[i].stroke,draft[i].stroke,115);
   Txt("SET_HINT",zone?"Da = limite inferiore, A = limite superiore":"Compila anche A per creare una zona",panel_x+PX(24),y+PX(76),8,C_MUTED);
   if(zone)
   {
      Txt("FILL_TXT","Riempimento",panel_x+PX(24),y+PX(112),8);
      Btn("FILL_"+k,"",panel_x+PX(111),y+PX(104),PX(30),PX(28),draft[i].fill,C_TEXT,"Scegli colore del riempimento");
      Txt("TRANS_TXT","Trasparenza",panel_x+PX(164),y+PX(101),8);
      Box("SLIDER_BG",panel_x+PX(166),y+PX(135),PX(255),PX(4),C_BORDER,C_BORDER,150);
      int fill=PX((int)MathRound(255.0*draft[i].transparency/100));
      if(fill>0) Box("SLIDER_FILL",panel_x+PX(166),y+PX(135),fill,PX(4),C_BLUE,C_BLUE,151);
      Box("SLIDER_KNOB",panel_x+PX(162)+fill,y+PX(129),PX(9),PX(16),C_BLUE,C_TEXT,152);
      Txt("TRANS_VALUE",IntegerToString(draft[i].transparency)+"%",panel_x+PX(440),y+PX(126),9);
      ObjectSetString(0,UI("SLIDER_KNOB"),OBJPROP_TOOLTIP,"0% opaco - 100% trasparente. Trascina o fai clic sulla barra.");
   }
}
void DrawRow(const int i,const int y)
{
   string k=IntegerToString(i); color bg=i%2==0?C_ROW:C'20,29,38';
   Box("ROW_"+k,panel_x+PX(10),y,PX(500),PX(33),bg,C'36,49,63');
   Box("ACCENT_"+k,panel_x+PX(12),y+PX(7),PX(4),PX(20),draft[i].stroke,draft[i].stroke);
   Input("NAME_"+k,draft[i].name,panel_x+PX(21),y+PX(4),PX(129));
   Input("FROM_"+k,draft[i].from,panel_x+PX(154),y+PX(4),PX(83),true);
   Input("TO_"+k,draft[i].to,panel_x+PX(241),y+PX(4),PX(83),true);
   Btn("COLOR_"+k,"",panel_x+PX(331),y+PX(6),PX(27),PX(23),draft[i].stroke,C_TEXT,"Colore linea / bordo");
   Btn("VIS_"+k,draft[i].visible?"ON":"OFF",panel_x+PX(364),y+PX(4),PX(37),PX(26),bg,draft[i].visible?C_TEXT:C_MUTED,draft[i].visible?"Nascondi elemento":"Mostra elemento");
   Btn("LOCK_"+k,draft[i].locked?"L":"U",panel_x+PX(406),y+PX(4),PX(30),PX(26),bg,draft[i].locked?C_TEXT:C_BLUE,draft[i].locked?"Bloccato. Clic per sbloccare":"Sbloccato. Clic per bloccare");
   Btn("SET_"+k,expanded==i?"^":"...",panel_x+PX(443),y+PX(4),PX(draft[i].custom?29:62),PX(26),expanded==i?C'17,40,62':bg,expanded==i?C_BLUE:C_TEXT,"Impostazioni grafiche");
   if(draft[i].custom) Btn("DEL_"+k,"x",panel_x+PX(478),y+PX(4),PX(27),PX(26),bg,C_MUTED,"Elimina campo personalizzato");
}
void DrawPalette()
{
   if(palette_row<0 || palette_row>=ArraySize(draft)) return;
   int x=panel_x+PX(76),y=panel_y+PX(90);
   Box("PAL_BG",x,y,PX(370),PX(176),C_HEADER,C_BLUE,300);
   Txt("PAL_TITLE",palette_fill?"Colore riempimento":"Colore linea / bordo",x+PX(12),y+PX(10),10);
   for(int i=0;i<ArraySize(palette);i++)
      Btn("PAL_"+IntegerToString(i),"",x+PX(12+(i%8)*43),y+PX(39+(i/8)*35),PX(33),PX(27),palette[i],C_TEXT,HexColor(palette[i]),330);
   Txt("PAL_HEX_LABEL","HEX",x+PX(12),y+PX(124),9);
   Input("PAL_HEX",HexColor(palette_fill?draft[palette_row].fill:draft[palette_row].stroke),x+PX(50),y+PX(117),PX(116),true,340);
   Btn("PAL_OK","OK",x+PX(184),y+PX(116),PX(65),PX(29),C_BLUE,clrWhite,"Conferma colore HEX",350);
   Btn("PAL_CANCEL","Annulla",x+PX(260),y+PX(116),PX(94),PX(29),C_INPUT,C_TEXT,"Chiudi selettore",350);
}
void BuildPanel()
{
   ObjectsDeleteAll(0,"LZ_UI_"); settings_y=-1;
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   panel_x=IClamp(panel_x,0,MathMax(0,cw-PX(520)));
   int count=ArraySize(draft),wanted=PX(44+32+92)+count*PX(34)+(expanded>=0 && expanded<count?SettingsH(expanded)+PX(6):0);
   panel_h=panel_collapsed?PX(44):MathMin(wanted,MathMax(PX(280),ch-PX(24)));
   panel_y=IClamp(panel_y,0,MathMax(0,ch-panel_h));
   if(panel_hidden)
   {
      Btn("OPEN","Livelli e zone",MathMax(0,cw-PX(150)),PX(12),PX(138),PX(32),C_HEADER,C_TEXT,"Riapri pannello"); return;
   }
   Box("BG",panel_x,panel_y,PX(520),panel_h,C_PANEL,C_BORDER);
   Box("HEADER",panel_x,panel_y,PX(520),PX(44),C_HEADER,C_BORDER);
   Txt("TITLE","::  Livelli e zone",panel_x+PX(14),panel_y+PX(12),12);
   Txt("SYMBOL",_Symbol,panel_x+PX(335),panel_y+PX(14),10);
   Btn("MIN",panel_collapsed?"+":"-",panel_x+PX(444),panel_y+PX(8),PX(28),PX(27),C_HEADER,C_MUTED,"Riduci / espandi pannello");
   Btn("CLOSE","x",panel_x+PX(480),panel_y+PX(8),PX(27),PX(27),C_HEADER,C_MUTED,"Nascondi pannello, mantieni disegni");
   if(panel_collapsed) return;
   int y=panel_y+PX(44),footer=panel_y+panel_h-PX(92);
   Txt("COL_NAME","Nome",panel_x+PX(24),y+PX(9),8,C_MUTED);
   Txt("COL_FROM","Prezzo / Da",panel_x+PX(154),y+PX(9),8,C_MUTED);
   Txt("COL_TO","A",panel_x+PX(272),y+PX(9),8,C_MUTED);
   Txt("COL_COLOR","Colore",panel_x+PX(329),y+PX(9),8,C_MUTED);
   Txt("COL_VIS","Vis",panel_x+PX(373),y+PX(9),8,C_MUTED);
   Txt("COL_LOCK","Lock",panel_x+PX(405),y+PX(9),8,C_MUTED);
   Txt("COL_SET","Impost.",panel_x+PX(452),y+PX(9),8,C_MUTED);
   y+=PX(32); first_row=IClamp(first_row,0,MathMax(0,count-1)); last_shown=first_row;
   for(int i=first_row;i<count;i++)
   {
      int h=PX(34)+(expanded==i?SettingsH(i)+PX(6):0);
      if(y+h>footer) break;
      DrawRow(i,y); y+=PX(34); last_shown=i+1;
      if(expanded==i) { DrawSettings(i,y); y+=SettingsH(i)+PX(6); }
   }
   Box("FOOTER",panel_x,footer,PX(520),PX(92),C_PANEL,C_BORDER);
   Btn("ADD","+ Aggiungi campo",panel_x+PX(14),footer+PX(9),PX(141),PX(28),C_ROW,C_TEXT,"Aggiungi riga personalizzata");
   Btn("UP","Su",panel_x+PX(167),footer+PX(9),PX(40),PX(28),C_ROW,C_MUTED,"Scorri righe verso l'alto");
   Btn("DOWN","Giu",panel_x+PX(211),footer+PX(9),PX(40),PX(28),C_ROW,C_MUTED,"Scorri righe verso il basso");
   Btn("RELOAD","Ricarica",panel_x+PX(266),footer+PX(9),PX(88),PX(28),C_ROW,C_TEXT,"Scarta la bozza e ricarica i livelli salvati");
   Btn("APPLY","Applica",panel_x+PX(382),footer+PX(9),PX(124),PX(37),C_BLUE,clrWhite,"Disegna, salva e sincronizza questa coppia");
   Txt("COUNT",IntegerToString(count)+" campi  |  righe "+IntegerToString(first_row+1)+"-"+IntegerToString(last_shown),panel_x+PX(15),footer+PX(44),8,C_MUTED);
   Txt("STATUS","",panel_x+PX(15),footer+PX(66),8,C_MUTED); StatusLine(); DrawPalette(); ChartRedraw();
}
bool InPanel(const int x,const int y)
{
   if(panel_hidden) return false;
   return x>=panel_x && x<=panel_x+PX(520) && y>=panel_y && y<=panel_y+panel_h;
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
