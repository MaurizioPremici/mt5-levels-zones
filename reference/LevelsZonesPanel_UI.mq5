//+------------------------------------------------------------------+
//|                                             LevelsZonesPanel_UI.mq5
//|  GUI ONLY - nessuna logica di trading / nessun disegno livelli
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0

//====================================================================
// COSTANTI UI
//====================================================================

#define UI_PREFIX       "LZUI_"

#define PANEL_W         520
#define HEADER_H        44
#define COLUMNS_H       32
#define ROW_H           34
#define PANEL_PAD       12
#define SETTINGS_GAP    8
#define ADD_H           42
#define FOOTER_H        66

#define BASE_ROWS       9

//====================================================================
// COLORI
//====================================================================

color CLR_PANEL          = C'15,22,29';
color CLR_PANEL_2        = C'18,27,36';
color CLR_HEADER         = C'17,25,34';
color CLR_ROW            = C'18,27,35';
color CLR_ROW_ALT        = C'20,29,38';
color CLR_SETTINGS       = C'25,36,47';

color CLR_BORDER         = C'46,61,77';
color CLR_BORDER_SOFT    = C'36,49,63';

color CLR_TEXT           = C'226,233,241';
color CLR_TEXT_MUTED     = C'137,153,169';
color CLR_TEXT_DIM       = C'100,117,134';

color CLR_INPUT          = C'12,20,28';
color CLR_INPUT_ACTIVE   = C'17,27,37';

color CLR_BLUE           = C'31,134,255';
color CLR_BLUE_DARK      = C'20,102,205';

color CLR_GREEN          = C'43,205,95';
color CLR_RED            = C'255,67,74';
color CLR_ORANGE         = C'255,126,18';
color CLR_PURPLE         = C'130,73,255';
color CLR_CYAN           = C'39,169,255';
color CLR_YELLOW         = C'255,218,26';
color CLR_GREY           = C'170,185,199';

//====================================================================
// STATO RIGHE
//====================================================================

struct SLevelRow
{
   string name;
   string price_from;
   string price_to;

   color  row_color;

   bool   visible;
   bool   locked;
   bool   custom;
   bool   expanded;

   int    thickness;
   bool   dashed;
   int    transparency;
};

SLevelRow Rows[];

int  panel_x = 20;
int  panel_y = 20;

bool panel_collapsed = false;
bool panel_closed    = false;

//====================================================================
// UTILITA'
//====================================================================

string Obj(const string suffix)
{
   return UI_PREFIX + suffix;
}

//--------------------------------------------------------------------
bool IsZone(const int index)
{
   if(index < 0 || index >= ArraySize(Rows))
      return false;

   return (Rows[index].price_to != "" &&
           Rows[index].price_to != "-" &&
           Rows[index].price_to != "—");
}

//--------------------------------------------------------------------
int SettingsHeight(const int index)
{
   if(IsZone(index))
      return 154;

   return 104;
}

//--------------------------------------------------------------------
void DeleteUI()
{
   ObjectsDeleteAll(0,UI_PREFIX);
   ChartRedraw();
}

//====================================================================
// PRIMITIVE UI
//====================================================================

void Rect(const string name,
          const int x,
          const int y,
          const int w,
          const int h,
          const color bg,
          const color border,
          const bool selectable=false,
          const int z=0)
{
   string id=Obj(name);

   ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0);

   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,h);

   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,id,OBJPROP_BORDER_TYPE,BORDER_FLAT);

   ObjectSetInteger(0,id,OBJPROP_BACK,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,selectable);
   ObjectSetInteger(0,id,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_ZORDER,z);
}

//--------------------------------------------------------------------
void Label(const string name,
           const string text,
           const int x,
           const int y,
           const int font_size,
           const color clr,
           const string font="Segoe UI",
           const int z=10)
{
   string id=Obj(name);

   ObjectCreate(0,id,OBJ_LABEL,0,0,0);

   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);

   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);

   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,font);

   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clr);

   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_ZORDER,z);
}

//--------------------------------------------------------------------
void Edit(const string name,
          const string text,
          const int x,
          const int y,
          const int w,
          const int h,
          const int font_size=9,
          const bool center=false)
{
   string id=Obj(name);

   ObjectCreate(0,id,OBJ_EDIT,0,0,0);

   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);

   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,h);

   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,"Segoe UI");

   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,id,OBJPROP_COLOR,CLR_TEXT);

   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,CLR_INPUT);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,CLR_BORDER);

   ObjectSetInteger(0,id,OBJPROP_ALIGN,
                    center ? ALIGN_CENTER : ALIGN_LEFT);

   ObjectSetInteger(0,id,OBJPROP_READONLY,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_ZORDER,20);
}

//--------------------------------------------------------------------
void Button(const string name,
            const string text,
            const int x,
            const int y,
            const int w,
            const int h,
            const color bg,
            const color fg,
            const color border,
            const int font_size=9,
            const string tooltip="")
{
   string id=Obj(name);

   ObjectCreate(0,id,OBJ_BUTTON,0,0,0);

   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);

   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,h);

   ObjectSetString(0,id,OBJPROP_TEXT,text);
   ObjectSetString(0,id,OBJPROP_FONT,"Segoe UI Symbol");

   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,font_size);

   ObjectSetInteger(0,id,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,border);

   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,id,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,id,OBJPROP_STATE,false);
   ObjectSetInteger(0,id,OBJPROP_ZORDER,30);

   if(tooltip!="")
      ObjectSetString(0,id,OBJPROP_TOOLTIP,tooltip);
}

//--------------------------------------------------------------------
void ColorBox(const string name,
              const int x,
              const int y,
              const int w,
              const int h,
              const color clr)
{
   Rect(name,x,y,w,h,clr,CLR_BORDER,false,25);
}

//====================================================================
// DATI VISIVI INIZIALI
//====================================================================

void SetRow(const int index,
            const string name,
            const string from,
            const string to,
            const color clr,
            const bool custom=false,
            const bool expanded=false,
            const int thickness=1,
            const bool dashed=false,
            const int transparency=25)
{
   Rows[index].name         = name;
   Rows[index].price_from   = from;
   Rows[index].price_to     = to;

   Rows[index].row_color    = clr;

   Rows[index].visible      = true;
   Rows[index].locked       = true;
   Rows[index].custom       = custom;
   Rows[index].expanded     = expanded;

   Rows[index].thickness    = thickness;
   Rows[index].dashed       = dashed;
   Rows[index].transparency = transparency;
}

//--------------------------------------------------------------------
void InitRows()
{
   ArrayResize(Rows,10);

   SetRow(0,
          "Entry Price",
          "1.13800",
          "—",
          CLR_PURPLE);

   SetRow(1,
          "Breakout Price",
          "1.12600",
          "—",
          CLR_GREY);

   SetRow(2,
          "Retest Price",
          "1.13540",
          "—",
          CLR_BLUE,
          false,
          true,
          2,
          true);

   SetRow(3,
          "Rejection Price",
          "1.14000",
          "1.14120",
          CLR_ORANGE,
          false,
          true,
          1,
          false,
          25);

   SetRow(4,
          "Support",
          "1.13200",
          "1.13350",
          CLR_GREEN);

   SetRow(5,
          "Resistance",
          "1.14920",
          "1.15080",
          CLR_RED);

   SetRow(6,
          "SL",
          "1.12900",
          "—",
          CLR_RED);

   SetRow(7,
          "TP 1",
          "1.14380",
          "—",
          CLR_BLUE);

   SetRow(8,
          "TP 2",
          "1.14650",
          "—",
          CLR_GREEN);

   SetRow(9,
          "My Level",
          "1.13100",
          "—",
          CLR_YELLOW,
          true);
}

//====================================================================
// SINCRONIZZAZIONE CAMPI EDIT
//====================================================================

void SyncStateFromObjects()
{
   int count=ArraySize(Rows);

   for(int i=0;i<count;i++)
   {
      string n=Obj("NAME_"+IntegerToString(i));
      string f=Obj("FROM_"+IntegerToString(i));
      string t=Obj("TO_"+IntegerToString(i));

      if(ObjectFind(0,n)>=0)
         Rows[i].name=ObjectGetString(0,n,OBJPROP_TEXT);

      if(ObjectFind(0,f)>=0)
         Rows[i].price_from=ObjectGetString(0,f,OBJPROP_TEXT);

      if(ObjectFind(0,t)>=0)
         Rows[i].price_to=ObjectGetString(0,t,OBJPROP_TEXT);
   }
}

//====================================================================
// CALCOLO ALTEZZA
//====================================================================

int PanelHeight()
{
   if(panel_collapsed)
      return HEADER_H;

   int y=HEADER_H+COLUMNS_H;

   int count=ArraySize(Rows);

   // Righe predefinite
   for(int i=0;i<BASE_ROWS && i<count;i++)
   {
      y+=ROW_H;

      if(Rows[i].expanded)
         y+=SettingsHeight(i)+SETTINGS_GAP;
   }

   // Pulsante aggiunta campo
   y+=ADD_H;

   // Personalizzate
   for(int i=BASE_ROWS;i<count;i++)
   {
      y+=ROW_H;

      if(Rows[i].expanded)
         y+=SettingsHeight(i)+SETTINGS_GAP;
   }

   y+=FOOTER_H;

   return y;
}

//====================================================================
// HEADER
//====================================================================

void DrawHeader()
{
   Rect("HEADER_BG",
        panel_x,
        panel_y,
        PANEL_W,
        HEADER_H,
        CLR_HEADER,
        CLR_BORDER,
        true,
        5);

   Label("TITLE_ICON",
         "▦",
         panel_x+14,
         panel_y+12,
         13,
         CLR_BLUE,
         "Segoe UI Symbol");

   Label("TITLE",
         "Livelli e zone",
         panel_x+37,
         panel_y+11,
         12,
         CLR_TEXT);

   Label("SYMBOL",
         _Symbol,
         panel_x+382,
         panel_y+12,
         10,
         CLR_TEXT);

   Button("MINIMIZE",
          panel_collapsed ? "□" : "–",
          panel_x+442,
          panel_y+8,
          30,
          27,
          CLR_HEADER,
          CLR_TEXT_MUTED,
          CLR_HEADER,
          12,
          panel_collapsed ? "Espandi pannello" : "Riduci pannello");

   Button("CLOSE",
          "×",
          panel_x+478,
          panel_y+8,
          28,
          27,
          CLR_HEADER,
          CLR_TEXT_MUTED,
          CLR_HEADER,
          13,
          "Chiudi pannello");
}

//====================================================================
// INTESTAZIONI COLONNE
//====================================================================

void DrawColumns(const int y)
{
   Label("COL_NAME",
         "Nome",
         panel_x+22,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_FROM",
         "Prezzo / Da",
         panel_x+154,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_TO",
         "A",
         panel_x+250,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_COLOR",
         "Colore",
         panel_x+329,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_VIS",
         "Vis",
         panel_x+375,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_LOCK",
         "Lock",
         panel_x+413,
         y+8,
         8,
         CLR_TEXT_MUTED);

   Label("COL_SETTINGS",
         "Impost.",
         panel_x+453,
         y+8,
         8,
         CLR_TEXT_MUTED);
}

//====================================================================
// RIGA
//====================================================================

void DrawRow(const int index,const int y)
{
   color bg=(index%2==0 ? CLR_ROW : CLR_ROW_ALT);

   Rect("ROW_BG_"+IntegerToString(index),
        panel_x+10,
        y,
        PANEL_W-20,
        ROW_H-2,
        bg,
        CLR_BORDER_SOFT);

   // Indicatore colore
   Rect("ROW_ACCENT_"+IntegerToString(index),
        panel_x+12,
        y+7,
        4,
        20,
        Rows[index].row_color,
        Rows[index].row_color);

   // Nome
   Edit("NAME_"+IntegerToString(index),
        Rows[index].name,
        panel_x+21,
        y+4,
        128,
        26,
        9);

   // Prezzo / Da
   Edit("FROM_"+IntegerToString(index),
        Rows[index].price_from,
        panel_x+153,
        y+4,
        84,
        26,
        9,
        true);

   // A
   Edit("TO_"+IntegerToString(index),
        Rows[index].price_to,
        panel_x+241,
        y+4,
        84,
        26,
        9,
        true);

   // Campione colore
   Button("COLOR_"+IntegerToString(index),
          "",
          panel_x+331,
          y+6,
          30,
          22,
          Rows[index].row_color,
          CLR_TEXT,
          CLR_BORDER,
          8,
          "Colore elemento");

   // Visibilità
   Button("EYE_"+IntegerToString(index),
          Rows[index].visible ? "◉" : "○",
          panel_x+369,
          y+4,
          33,
          26,
          bg,
          Rows[index].visible ? CLR_TEXT : CLR_TEXT_DIM,
          bg,
          12,
          Rows[index].visible ? "Nascondi" : "Mostra");

   // Lock
   Button("LOCK_"+IntegerToString(index),
          Rows[index].locked ? "▣" : "□",
          panel_x+406,
          y+4,
          33,
          26,
          bg,
          Rows[index].locked ? CLR_TEXT : CLR_TEXT_DIM,
          bg,
          11,
          Rows[index].locked ? "Sblocca" : "Blocca");

   // Impostazioni
   if(!Rows[index].custom)
   {
      Button("SET_"+IntegerToString(index),
             Rows[index].expanded ? "⚙ ︿" : "⚙ ﹀",
             panel_x+446,
             y+4,
             60,
             26,
             Rows[index].expanded ? CLR_INPUT_ACTIVE : bg,
             Rows[index].expanded ? CLR_BLUE : CLR_TEXT_MUTED,
             Rows[index].expanded ? CLR_BLUE_DARK : bg,
             9,
             "Impostazioni grafiche");
   }
   else
   {
      Button("SET_"+IntegerToString(index),
             "⚙",
             panel_x+445,
             y+4,
             27,
             26,
             Rows[index].expanded ? CLR_INPUT_ACTIVE : bg,
             Rows[index].expanded ? CLR_BLUE : CLR_TEXT_MUTED,
             Rows[index].expanded ? CLR_BLUE_DARK : bg,
             10,
             "Impostazioni grafiche");

      Button("DEL_"+IntegerToString(index),
             "×",
             panel_x+478,
             y+4,
             27,
             26,
             bg,
             CLR_TEXT_MUTED,
             bg,
             12,
             "Elimina campo");
   }
}

//====================================================================
// IMPOSTAZIONI GRAFICHE
//====================================================================

void DrawSettings(const int index,const int y)
{
   bool zone=IsZone(index);

   int h=SettingsHeight(index);

   Rect("SETTINGS_BG_"+IntegerToString(index),
        panel_x+14,
        y,
        PANEL_W-28,
        h,
        CLR_SETTINGS,
        CLR_BORDER);

   Label("SETTINGS_TITLE_"+IntegerToString(index),
         zone ? "Impostazioni zona" : "Impostazioni linea",
         panel_x+28,
         y+12,
         9,
         CLR_TEXT);

   // ---------------------------------------------------------------
   // LINEA
   // ---------------------------------------------------------------

   Label("SET_COLOR_LBL_"+IntegerToString(index),
         zone ? "Colore bordo" : "Colore",
         panel_x+28,
         y+45,
         8,
         CLR_TEXT);

   ColorBox("SET_COLOR_"+IntegerToString(index),
            panel_x+106,
            y+38,
            28,
            25,
            Rows[index].row_color);

   Label("SET_WIDTH_LBL_"+IntegerToString(index),
         "Spessore",
         panel_x+151,
         y+45,
         8,
         CLR_TEXT);

   Button("WIDTH_"+IntegerToString(index),
          IntegerToString(Rows[index].thickness)+"  ▾",
          panel_x+210,
          y+36,
          54,
          29,
          CLR_INPUT,
          CLR_TEXT,
          CLR_BORDER,
          9);

   Label("SET_STYLE_LBL_"+IntegerToString(index),
         "Stile",
         panel_x+280,
         y+45,
         8,
         CLR_TEXT);

   Button("STYLE_"+IntegerToString(index),
          Rows[index].dashed ? "Tratteggiata  ▾" : "Continua  ▾",
          panel_x+318,
          y+36,
          112,
          29,
          CLR_INPUT,
          CLR_TEXT,
          CLR_BORDER,
          8);

   // Anteprima linea
   Label("LINE_PREVIEW_"+IntegerToString(index),
         Rows[index].dashed ? "—  —  —" : "━━━━━━",
         panel_x+441,
         y+43,
         9,
         Rows[index].row_color,
         "Segoe UI Symbol");

   // ---------------------------------------------------------------
   // ZONA
   // ---------------------------------------------------------------

   if(zone)
   {
      Label("FILL_LBL_"+IntegerToString(index),
            "Colore riempimento",
            panel_x+28,
            y+94,
            8,
            CLR_TEXT);

      ColorBox("FILL_COLOR_"+IntegerToString(index),
               panel_x+137,
               y+84,
               31,
               31,
               Rows[index].row_color);

      Label("TRANS_LBL_"+IntegerToString(index),
            "Trasparenza",
            panel_x+189,
            y+94,
            8,
            CLR_TEXT);

      // Barra slider
      Rect("SLIDER_BG_"+IntegerToString(index),
           panel_x+190,
           y+122,
           250,
           4,
           C'55,71,86',
           C'55,71,86');

      int knob_x=(int)(250.0*
                      (double)Rows[index].transparency/
                      100.0);

      if(knob_x<0)   knob_x=0;
      if(knob_x>250) knob_x=250;

      Rect("SLIDER_FILL_"+IntegerToString(index),
           panel_x+190,
           y+122,
           knob_x,
           4,
           CLR_BLUE,
           CLR_BLUE);

      Label("SLIDER_KNOB_"+IntegerToString(index),
            "●",
            panel_x+183+knob_x,
            y+114,
            14,
            CLR_BLUE,
            "Segoe UI Symbol");

      Label("TRANS_VALUE_"+IntegerToString(index),
            IntegerToString(Rows[index].transparency)+"%",
            panel_x+451,
            y+116,
            8,
            CLR_TEXT);
   }
}

//====================================================================
// AGGIUNGI CAMPO
//====================================================================

void DrawAddButton(const int y)
{
   Button("ADD_FIELD",
          "＋  Aggiungi campo",
          panel_x+14,
          y+6,
          142,
          30,
          CLR_PANEL_2,
          CLR_TEXT,
          CLR_BORDER,
          9,
          "Aggiungi un campo personalizzato");
}

//====================================================================
// FOOTER
//====================================================================

int CountCustomRows()
{
   int count=0;

   for(int i=0;i<ArraySize(Rows);i++)
      if(Rows[i].custom)
         count++;

   return count;
}

//--------------------------------------------------------------------
void DrawFooter(const int y)
{
   Rect("FOOTER_BG",
        panel_x,
        y,
        PANEL_W,
        FOOTER_H,
        CLR_PANEL,
        CLR_BORDER_SOFT);

   string info=
      IntegerToString(BASE_ROWS)+
      " campi predefiniti, "+
      IntegerToString(CountCustomRows())+
      " personalizzato";

   Label("FOOTER_INFO",
         info,
         panel_x+15,
         y+39,
         8,
         CLR_TEXT_DIM);

   Button("APPLY",
          "Applica",
          panel_x+382,
          y+15,
          124,
          38,
          CLR_BLUE,
          C'255,255,255',
          CLR_BLUE_DARK,
          11,
          "Conferma i valori");
}

//====================================================================
// COSTRUZIONE COMPLETA PANEL
//====================================================================

void BuildUI()
{
   ObjectsDeleteAll(0,UI_PREFIX);

   if(panel_closed)
   {
      ChartRedraw();
      return;
   }

   int total_h=PanelHeight();

   if(!panel_collapsed)
   {
      Rect("PANEL_BG",
           panel_x,
           panel_y,
           PANEL_W,
           total_h,
           CLR_PANEL,
           CLR_BORDER);
   }

   DrawHeader();

   if(panel_collapsed)
   {
      ChartRedraw();
      return;
   }

   int y=panel_y+HEADER_H;

   DrawColumns(y);

   y+=COLUMNS_H;

   int count=ArraySize(Rows);

   // ---------------------------------------------------------------
   // CAMPI PREDEFINITI
   // ---------------------------------------------------------------

   for(int i=0;i<BASE_ROWS && i<count;i++)
   {
      DrawRow(i,y);

      y+=ROW_H;

      if(Rows[i].expanded)
      {
         DrawSettings(i,y);
         y+=SettingsHeight(i)+SETTINGS_GAP;
      }
   }

   // ---------------------------------------------------------------
   // AGGIUNGI CAMPO
   // ---------------------------------------------------------------

   DrawAddButton(y);
   y+=ADD_H;

   // ---------------------------------------------------------------
   // CAMPI PERSONALIZZATI
   // ---------------------------------------------------------------

   for(int i=BASE_ROWS;i<count;i++)
   {
      DrawRow(i,y);

      y+=ROW_H;

      if(Rows[i].expanded)
      {
         DrawSettings(i,y);
         y+=SettingsHeight(i)+SETTINGS_GAP;
      }
   }

   DrawFooter(y);

   ChartRedraw();
}

//====================================================================
// CAMPI PERSONALIZZATI
//====================================================================

void AddCustomRow()
{
   SyncStateFromObjects();

   int old_size=ArraySize(Rows);

   ArrayResize(Rows,old_size+1);

   Rows[old_size].name=
      "Nuovo livello "+IntegerToString(old_size-BASE_ROWS+1);

   Rows[old_size].price_from="";
   Rows[old_size].price_to="—";

   Rows[old_size].row_color=CLR_CYAN;

   Rows[old_size].visible=true;
   Rows[old_size].locked=true;
   Rows[old_size].custom=true;
   Rows[old_size].expanded=false;

   Rows[old_size].thickness=1;
   Rows[old_size].dashed=false;
   Rows[old_size].transparency=25;

   BuildUI();
}

//--------------------------------------------------------------------
void DeleteCustomRow(const int index)
{
   if(index<BASE_ROWS)
      return;

   if(index>=ArraySize(Rows))
      return;

   SyncStateFromObjects();

   int total=ArraySize(Rows);

   for(int i=index;i<total-1;i++)
      Rows[i]=Rows[i+1];

   ArrayResize(Rows,total-1);

   BuildUI();
}

//====================================================================
// EVENTI VISIVI
//====================================================================

int ExtractIndex(const string object_name,
                 const string control_prefix)
{
   string complete=Obj(control_prefix);

   if(StringFind(object_name,complete)!=0)
      return -1;

   string number=
      StringSubstr(object_name,StringLen(complete));

   return (int)StringToInteger(number);
}

//--------------------------------------------------------------------
void ToggleSettings(const int index)
{
   if(index<0 || index>=ArraySize(Rows))
      return;

   SyncStateFromObjects();

   Rows[index].expanded=!Rows[index].expanded;

   BuildUI();
}

//--------------------------------------------------------------------
void ToggleVisibility(const int index)
{
   if(index<0 || index>=ArraySize(Rows))
      return;

   SyncStateFromObjects();

   Rows[index].visible=!Rows[index].visible;

   BuildUI();
}

//--------------------------------------------------------------------
void ToggleLock(const int index)
{
   if(index<0 || index>=ArraySize(Rows))
      return;

   SyncStateFromObjects();

   Rows[index].locked=!Rows[index].locked;

   BuildUI();
}

//====================================================================
// INIT
//====================================================================

int OnInit()
{
   InitRows();

   long chart_width=0;

   if(ChartGetInteger(0,
                      CHART_WIDTH_IN_PIXELS,
                      0,
                      chart_width))
   {
      panel_x=(int)chart_width-PANEL_W-12;

      if(panel_x<10)
         panel_x=10;
   }

   panel_y=12;

   BuildUI();

   return(INIT_SUCCEEDED);
}

//====================================================================
// DEINIT
//====================================================================

void OnDeinit(const int reason)
{
   DeleteUI();
}

//====================================================================
// CHART EVENTS
//====================================================================

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // ---------------------------------------------------------------
   // DRAG HEADER
   // ---------------------------------------------------------------

   if(id==CHARTEVENT_OBJECT_DRAG &&
      sparam==Obj("HEADER_BG"))
   {
      int new_x=
         (int)ObjectGetInteger(0,
                               Obj("HEADER_BG"),
                               OBJPROP_XDISTANCE);

      int new_y=
         (int)ObjectGetInteger(0,
                               Obj("HEADER_BG"),
                               OBJPROP_YDISTANCE);

      if(new_x<0)
         new_x=0;

      if(new_y<0)
         new_y=0;

      panel_x=new_x;
      panel_y=new_y;

      BuildUI();

      return;
   }

   // ---------------------------------------------------------------
   // FINE EDIT
   // ---------------------------------------------------------------

   if(id==CHARTEVENT_OBJECT_ENDEDIT)
   {
      SyncStateFromObjects();
      return;
   }

   // ---------------------------------------------------------------
   // CLICK
   // ---------------------------------------------------------------

   if(id!=CHARTEVENT_OBJECT_CLICK)
      return;

   // ---------------------------------------------------------------
   // MINIMIZZA
   // ---------------------------------------------------------------

   if(sparam==Obj("MINIMIZE"))
   {
      SyncStateFromObjects();

      panel_collapsed=!panel_collapsed;

      BuildUI();
      return;
   }

   // ---------------------------------------------------------------
   // CHIUDI
   // ---------------------------------------------------------------

   if(sparam==Obj("CLOSE"))
   {
      panel_closed=true;

      DeleteUI();
      return;
   }

   // ---------------------------------------------------------------
   // AGGIUNGI CAMPO
   // ---------------------------------------------------------------

   if(sparam==Obj("ADD_FIELD"))
   {
      AddCustomRow();
      return;
   }

   // ---------------------------------------------------------------
   // APPLY
   // Solo stato grafico del pulsante.
   // Nessuna logica viene eseguita.
   // ---------------------------------------------------------------

   if(sparam==Obj("APPLY"))
   {
      SyncStateFromObjects();

      ObjectSetInteger(0,
                       Obj("APPLY"),
                       OBJPROP_STATE,
                       false);

      ChartRedraw();

      return;
   }

   // ---------------------------------------------------------------
   // SETTINGS
   // ---------------------------------------------------------------

   int index=ExtractIndex(sparam,"SET_");

   if(index>=0)
   {
      ToggleSettings(index);
      return;
   }

   // ---------------------------------------------------------------
   // VISIBILITA'
   // ---------------------------------------------------------------

   index=ExtractIndex(sparam,"EYE_");

   if(index>=0)
   {
      ToggleVisibility(index);
      return;
   }

   // ---------------------------------------------------------------
   // LOCK
   // ---------------------------------------------------------------

   index=ExtractIndex(sparam,"LOCK_");

   if(index>=0)
   {
      ToggleLock(index);
      return;
   }

   // ---------------------------------------------------------------
   // DELETE CUSTOM
   // ---------------------------------------------------------------

   index=ExtractIndex(sparam,"DEL_");

   if(index>=0)
   {
      DeleteCustomRow(index);
      return;
   }
}

//====================================================================
// INDICATORE: NESSUN CALCOLO
//====================================================================

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}
//+------------------------------------------------------------------+