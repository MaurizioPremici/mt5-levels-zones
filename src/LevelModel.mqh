#ifndef LEVEL_MODEL_MQH
#define LEVEL_MODEL_MQH
#define LZ_BASE 9
#define LZ_MAX 128
struct Level
{
   int key;
   string name,from,to;
   color stroke,fill;
   int width,transparency;
   bool dashed,visible,locked,custom;
   string semantic_type,value_type,timeframe,state,label_position;
   bool show_label;
   int border_opacity,target_index;
};
string Trim(string s) { StringTrimLeft(s); StringTrimRight(s); return s; }
bool EmptyPrice(string s) { s=Trim(s); return StringLen(s)==0 || s=="-" || s=="—"; }
// No partial conversions: reject pasted text, exponent notation and mixed separators.
bool ParsePrice(string s,const int digits,double &value,string &message)
{
   s=Trim(s); value=0; message="";
   if(EmptyPrice(s)) { message="Missing price"; return false; }
   int sep=-1,decimal_count=0,n=StringLen(s);
   for(int i=0;i<n;i++)
   {
      ushort c=StringGetCharacter(s,i);
      if(c=='.' || c==',')
      {
         if(sep>=0) { message="Use one decimal separator"; return false; }
         sep=i;
      }
      else if(c<'0' || c>'9') { message="Enter a price only"; return false; }
   }
   if(sep==0 || sep==n-1) { message="Incomplete price"; return false; }
   if(sep>=0) decimal_count=n-sep-1;
   if(decimal_count>digits) { message="Too many decimal places for this symbol"; return false; }
   StringReplace(s,",","."); value=StringToDouble(s);
   if(!MathIsValidNumber(value) || value<=0 || value>1e12)
   { message="Price must be positive and no greater than 1e12"; return false; }
   value=NormalizeDouble(value,digits); return true;
}

#define LZ_STATES "INACTIVE|WAITING|WAITING_BREAKOUT|BREAKOUT_CONFIRMED|WAITING_RETEST|RETEST_TOUCHED|RETEST_CONFIRMED|WAITING_REJECTION|REJECTION_CONFIRMED|ENTRY_READY|ACTIVE|FAILED|INVALIDATED|EXPIRED|UNDEFINED|CANDIDATE|READY|FILLED|CONDITIONAL"
struct ScenarioState
{
   string symbol,snapshot_id,latest_snapshot_id,source,generated_at,mode,direction,decision,trigger_tf,overall_status,activation_condition;
};
bool InList(const string v,const string list) { return StringFind("|"+list+"|","|"+v+"|")>=0 && v!=""; }
bool ValidState(const string v) { return InList(v,LZ_STATES); }
bool ValidTF(const string tf)
{
   if(tf=="") return true;
   string parts[]; int n=StringSplit(tf,'/',parts);
   for(int i=0;i<n;i++) if(!InList(parts[i],"M1|M2|M3|M4|M5|M6|M10|M12|M15|M20|M30|H1|H2|H3|H4|H6|H8|H12|D1|W1|MN1")) return false;
   return n>0 && StringLen(tf)<=32;
}
void InitFieldMeta(Level &r,const int index=-1)
{
   string types[]={"ENTRY","BREAKOUT","RETEST","REJECTION","SUPPORT","RESISTANCE","SL","TP","TP"};
   r.semantic_type=index>=0 && index<9?types[index]:"CUSTOM";
   r.value_type=(!EmptyPrice(r.to) || index==2 || index==3)?"ZONE":"LEVEL";
   r.timeframe=""; r.state=index==0?"UNDEFINED":"INACTIVE";
   r.show_label=true; r.label_position="LEFT"; r.border_opacity=100;
   r.target_index=index==7?1:index==8?2:0;
}
void DefaultScenario(ScenarioState &s,const string symbol)
{
   s.symbol=symbol; s.snapshot_id=""; s.latest_snapshot_id=""; s.source="Manual"; s.generated_at="";
   s.mode="SETUP"; s.direction="WAIT"; s.decision="DATI_INSUFFICIENTI"; s.trigger_tf="M5";
   s.overall_status="INACTIVE"; s.activation_condition="";
}
bool SameScenario(const ScenarioState &a,const ScenarioState &b)
{
   return a.symbol==b.symbol && a.snapshot_id==b.snapshot_id && a.latest_snapshot_id==b.latest_snapshot_id &&
      a.source==b.source && a.generated_at==b.generated_at && a.mode==b.mode && a.direction==b.direction &&
      a.decision==b.decision && a.trigger_tf==b.trigger_tf && a.overall_status==b.overall_status && a.activation_condition==b.activation_condition;
}
bool StaleScenario(const ScenarioState &s) { return s.latest_snapshot_id!="" && s.latest_snapshot_id!=s.snapshot_id; }
bool HasPrices(const Level &rows[]) { for(int i=0;i<ArraySize(rows);i++) if(!EmptyPrice(rows[i].from)||!EmptyPrice(rows[i].to))return true;return false; }
void ModeDefaults(Level &rows[],const string mode)
{
   DefaultLevels(rows);
   if(mode!="OPEN_POSITION") return;
   string names[]={"Entry / Open Price","Current Bid","Current Ask","SL Current","SL Management","TP Current","TP1 Management","TP2 Management","Invalidation"};
   string types[]={"OPEN_PRICE","CURRENT_BID","CURRENT_ASK","SL_CURRENT","SL_MANAGEMENT","TP_CURRENT","TP1_MANAGEMENT","TP2_MANAGEMENT","INVALIDATION"};
   for(int i=0;i<9;i++)
   {
      rows[i].name=names[i];rows[i].semantic_type=types[i]; rows[i].value_type="LEVEL";rows[i].state="INACTIVE";
      rows[i].stroke=i==0?C'130,73,255':(i>=3&&i<=4)||i==8?C'255,67,74':i>=5?C'43,205,95':clrWhite;
      rows[i].fill=rows[i].stroke;rows[i].target_index=0;
   }
}
bool ValidateScenario(ScenarioState &s,Level &rows[],const string symbol,const int digits,string &error)
{
   if(s.symbol!=symbol) {error="Scenario symbol does not match this chart";return false;}
   if(!InList(s.mode,"SETUP|OPEN_POSITION") || !ValidState(s.overall_status) || !ValidTF(s.trigger_tf) || s.trigger_tf=="")
   {error="Invalid scenario mode, status or trigger timeframe";return false;}
   if(!InList(s.direction,s.mode=="SETUP"?"BUY|SELL|WAIT|WAIT -> BUY|WAIT -> SELL":"LONG|SHORT") || !InList(s.decision,"LASCIA|CHIUDI|DATI_INSUFFICIENTI"))
   {error="Invalid direction or decision for this mode";return false;}
   if(StringLen(s.snapshot_id)>128 || StringLen(s.latest_snapshot_id)>128 || StringLen(s.source)>64 || StringLen(s.generated_at)>64 || StringLen(s.activation_condition)>8192)
   {error="Scenario text exceeds its maximum length";return false;}
   if(ArraySize(rows)>LZ_MAX) {error="Maximum of 128 fields";return false;}
   double entry=0,sl=0,tp1=0,tp2=0;
   for(int i=0;i<ArraySize(rows);i++)
   {
      string e; if(!ValidateLevel(rows[i],digits,e)){error=rows[i].name+": "+e;return false;}
      if(rows[i].key<=0 || !InList(rows[i].semantic_type,"ENTRY|BREAKOUT|RETEST|REJECTION|SUPPORT|RESISTANCE|SL|TP|CUSTOM|OPEN_PRICE|CURRENT_BID|CURRENT_ASK|SL_CURRENT|SL_MANAGEMENT|TP_CURRENT|TP1_MANAGEMENT|TP2_MANAGEMENT|INVALIDATION"))
      {error="Invalid field ID or semantic type";return false;}
      for(int j=0;j<i;j++)if(rows[j].key==rows[i].key){error="Duplicate field ID";return false;}
      for(int j=0;j<i;j++)
      {
         if((rows[i].semantic_type=="ENTRY" || rows[i].semantic_type=="SL") && rows[j].semantic_type==rows[i].semantic_type)
         {error="Only one primary Entry and SL are allowed; use Custom for alternatives";return false;}
         if(rows[i].semantic_type=="TP" && rows[j].semantic_type=="TP" && rows[j].target_index==rows[i].target_index)
         {error="Duplicate TP target number";return false;}
      }
      if(rows[i].semantic_type=="ENTRY")entry=StringToDouble(rows[i].from);
      if(rows[i].semantic_type=="SL")sl=StringToDouble(rows[i].from);
      if(rows[i].semantic_type=="TP" && rows[i].target_index==1)tp1=StringToDouble(rows[i].from);
      if(rows[i].semantic_type=="TP" && rows[i].target_index==2)tp2=StringToDouble(rows[i].from);
   }
   if(s.mode=="SETUP" && entry>0 && sl>0 && tp1>0 && tp2>0)
   {
      if(s.direction=="BUY" && !(sl<entry&&entry<tp1&&tp1<tp2)){error="BUY requires SL < Entry < TP1 < TP2";return false;}
      if(s.direction=="SELL" && !(tp2<tp1&&tp1<entry&&entry<sl)){error="SELL requires TP2 < TP1 < Entry < SL";return false;}
   }
   error="";return true;
}

bool ValidateLevel(Level &r,const int digits,string &message)
{
   r.name=Trim(r.name);
   if(StringLen(r.name)==0 || StringLen(r.name)>48 || StringFind(r.name,"\n")>=0 || StringFind(r.name,"\r")>=0)
   { message="Name required, up to 48 characters"; return false; }
   if(r.semantic_type=="TP" && (r.target_index<1 || r.target_index>LZ_MAX)){message="TP requires a target number (1, 2, ...)";return false;}
   if(r.value_type!="LEVEL" && r.value_type!="ZONE") { message="Choose Level or Zone"; return false; }
   if(!ValidTF(r.timeframe) || !ValidState(r.state)) { message="Invalid timeframe or state"; return false; }
   if(r.border_opacity<0 || r.border_opacity>100 || (r.label_position!="LEFT" && r.label_position!="RIGHT")) { message="Invalid label or border opacity"; return false; }
   if(r.value_type=="LEVEL" && !EmptyPrice(r.to)) { message="A Level cannot have a To price"; return false; }
   if(r.width<1 || r.width>5 || r.transparency<0 || r.transparency>100)
   { message="Invalid style"; return false; }
   if(EmptyPrice(r.from))
   {
      if(!EmptyPrice(r.to)) { message="Enter Price / From first"; return false; }
      r.from=""; r.to=""; return true;
   }
   double a,b;
   if(!ParsePrice(r.from,digits,a,message)) return false;
   r.from=DoubleToString(a,digits);
   if(EmptyPrice(r.to)) { r.to=""; if(r.value_type=="ZONE") { message="Enter both zone endpoints or leave both empty"; return false; } return true; }
   if(!ParsePrice(r.to,digits,b,message)) return false;
   if(a>b) { message="Zone From must be less than or equal to To"; return false; }
   r.from=DoubleToString(a,digits);
   r.to=DoubleToString(b,digits);
   return true;
}
void DefaultLevels(Level &rows[])
{
   string names[]={"Entry Price","Breakout Level","Retest Zone","Rejection Zone","Support","Resistance","SL","TP 1","TP 2"};
   color colors[]={C'130,73,255',clrWhite,C'130,73,255',C'255,126,18',C'43,205,95',C'255,67,74',C'255,67,74',C'43,205,95',C'43,205,95'};
   ArrayResize(rows,LZ_BASE);
   for(int i=0;i<LZ_BASE;i++)
   {
      rows[i].key=i+1; rows[i].name=names[i]; rows[i].from=""; rows[i].to="";
      rows[i].stroke=colors[i]; rows[i].fill=colors[i]; rows[i].width=1;
      rows[i].transparency=80; rows[i].visible=true; rows[i].locked=true;
      rows[i].dashed=false; rows[i].custom=false;
      InitFieldMeta(rows[i],i);
   }
}
void CopyLevels(Level &dst[],const Level &src[])
{
   int n=ArraySize(src); ArrayResize(dst,n);
   for(int i=0;i<n;i++) dst[i]=src[i];
}
bool SameLevels(const Level &a[],const Level &b[])
{
   if(ArraySize(a)!=ArraySize(b)) return false;
   for(int i=0;i<ArraySize(a);i++)
      if(a[i].key!=b[i].key || a[i].name!=b[i].name || a[i].from!=b[i].from || a[i].to!=b[i].to ||
         a[i].stroke!=b[i].stroke || a[i].fill!=b[i].fill || a[i].width!=b[i].width ||
         a[i].transparency!=b[i].transparency || a[i].dashed!=b[i].dashed ||
         a[i].visible!=b[i].visible || a[i].locked!=b[i].locked || a[i].custom!=b[i].custom ||
         a[i].semantic_type!=b[i].semantic_type || a[i].value_type!=b[i].value_type ||
         a[i].timeframe!=b[i].timeframe || a[i].state!=b[i].state || a[i].show_label!=b[i].show_label ||
         a[i].label_position!=b[i].label_position || a[i].border_opacity!=b[i].border_opacity || a[i].target_index!=b[i].target_index) return false;
   return true;
}
string SymbolKey(const string symbol)
{
   string key="";
   for(int i=0;i<StringLen(symbol);i++) key+=StringFormat("%04X",StringGetCharacter(symbol,i));
   return key;
}
string HexColor(const color c)
{
   uint v=(uint)c; return StringFormat("#%02X%02X%02X",v&255,(v>>8)&255,(v>>16)&255);
}
bool ParseHex(string s,color &c)
{
   s=Trim(s); if(StringSubstr(s,0,1)=="#") s=StringSubstr(s,1);
   if(StringLen(s)!=6) return false;
   StringToUpper(s); uint v=0;
   for(int i=0;i<6;i++)
   {
      ushort a=StringGetCharacter(s,i); int d=-1;
      if(a>='0' && a<='9') d=a-'0'; else if(a>='A' && a<='F') d=a-'A'+10;
      if(d<0) return false; v=(v<<4)|(uint)d;
   }
   c=(color)(((v>>16)&255)|(v&0x00ff00)|((v&255)<<16)); return true;
}
#endif
