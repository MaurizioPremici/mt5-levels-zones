#ifndef SCENARIO_IMPORT_MQH
#define SCENARIO_IMPORT_MQH
// Small, bounded JSON reader. No network, DLLs, terminal positions or execution API.
struct JsonNode { string key,value; int kind,parent; }; // 1 object,2 array,3 string,4 number,5 bool,6 null
class ScenarioJson
{
public:
   JsonNode nodes[];string error,text;int pos;
   void Space(){while(pos<StringLen(text)&&StringGetCharacter(text,pos)<=32)pos++;}
   bool Quoted(string &out)
   {
      out="";if(StringSubstr(text,pos++,1)!="\"")return false;
      while(pos<StringLen(text))
      {
         ushort c=StringGetCharacter(text,pos++);
         if(c=='"')return true;if(c<32)return false;
         if(c=='\\')
         {
            if(pos>=StringLen(text))return false;c=StringGetCharacter(text,pos++);
            if(c=='n')c=10;else if(c=='r')c=13;else if(c=='t')c=9;else if(c=='b')c=8;else if(c=='f')c=12;
            else if(c=='u')
            {
               int v=0;for(int j=0;j<4;j++){if(pos>=StringLen(text))return false;ushort h=StringGetCharacter(text,pos++);int d=h>='0'&&h<='9'?h-'0':h>='a'&&h<='f'?h-'a'+10:h>='A'&&h<='F'?h-'A'+10:-1;if(d<0)return false;v=v*16+d;}c=(ushort)v;
            }
            else if(c!='"'&&c!='\\'&&c!='/')return false;
         }
         if(c==0)return false;out+=ShortToString(c);
      }return false;
   }
   bool Value(const string key,const int parent,const int depth)
   {
      if(depth>8||ArraySize(nodes)>=4096)return false;Space();
      int i=ArraySize(nodes);ArrayResize(nodes,i+1);nodes[i].key=key;nodes[i].parent=parent;
      string c=StringSubstr(text,pos,1);
      if(c=="{"||c=="[")
      {
         bool obj=c=="{";nodes[i].kind=obj?1:2;pos++;Space();string end=obj?"}":"]";
         if(StringSubstr(text,pos,1)==end){pos++;return true;}
         while(pos<StringLen(text))
         {
            string k="";if(obj){Space();if(!Quoted(k))return false;Space();if(StringSubstr(text,pos++,1)!=":")return false;for(int j=i+1;j<ArraySize(nodes);j++)if(nodes[j].parent==i&&nodes[j].key==k)return false;}
            if(!Value(k,i,depth+1))return false;Space();c=StringSubstr(text,pos++,1);if(c==end)return true;if(c!=",")return false;
         }return false;
      }
      if(c=="\""){nodes[i].kind=3;return Quoted(nodes[i].value);}
      int begin=pos;while(pos<StringLen(text)&&StringFind(",}] \t\r\n",StringSubstr(text,pos,1))<0)pos++;
      string v=StringSubstr(text,begin,pos-begin);nodes[i].value=v;
      if(v=="true"||v=="false"){nodes[i].kind=5;return true;}if(v=="null"){nodes[i].kind=6;return true;}
      // JSON number grammar, including exponents. Prices are validated more strictly later.
      int n=StringLen(v),k=0;if(StringSubstr(v,k,1)=="-")k++;if(k>=n)return false;
      if(StringSubstr(v,k,1)=="0")k++;else{int start=k;while(k<n&&StringGetCharacter(v,k)>='0'&&StringGetCharacter(v,k)<='9')k++;if(k==start)return false;}
      if(StringSubstr(v,k,1)=="."){k++;int start=k;while(k<n&&StringGetCharacter(v,k)>='0'&&StringGetCharacter(v,k)<='9')k++;if(k==start)return false;}
      if(StringSubstr(v,k,1)=="e"||StringSubstr(v,k,1)=="E"){k++;if(StringSubstr(v,k,1)=="+"||StringSubstr(v,k,1)=="-")k++;int start=k;while(k<n&&StringGetCharacter(v,k)>='0'&&StringGetCharacter(v,k)<='9')k++;if(k==start)return false;}
      nodes[i].kind=4;return k==n;
   }
   bool Parse(const string data){text=data;pos=0;error="";ArrayResize(nodes,0);bool ok=Value("",-1,0);Space();return ok&&pos==StringLen(text)&&nodes[0].kind==1;}
   int Find(const int parent,const string key){for(int i=parent+1;i<ArraySize(nodes);i++)if(nodes[i].parent==parent&&nodes[i].key==key)return i;return -1;}
   bool Keys(const int parent,const string allowed)
   {for(int i=parent+1;i<ArraySize(nodes);i++)if(nodes[i].parent==parent&&!InList(nodes[i].key,allowed)){error="Unknown JSON field: "+nodes[i].key;return false;}return true;}
   bool Str(const int parent,const string key,string &out,const bool required=false,const bool price=false)
   {
      int i=Find(parent,key);if(i<0){if(required)error="Missing "+key;return !required;}
      if(price&&nodes[i].kind==6){out="";return true;}
      if(nodes[i].kind!=3&&!(price&&nodes[i].kind==4)){error="Invalid type: "+key;return false;}out=nodes[i].value;return true;
   }
   bool Bool(const int parent,const string key,bool &out){int i=Find(parent,key);if(i<0)return true;if(nodes[i].kind!=5){error="Expected boolean: "+key;return false;}out=nodes[i].value=="true";return true;}
   bool Int(const int parent,const string key,int &out){int i=Find(parent,key);if(i<0)return true;if(nodes[i].kind!=4||StringFind(nodes[i].value,".")>=0||StringFind(nodes[i].value,"e")>=0||StringFind(nodes[i].value,"E")>=0||StringLen(nodes[i].value)>9){error="Expected integer: "+key;return false;}out=(int)StringToInteger(nodes[i].value);return true;}
};
bool ParseScenarioJSON(const string data,const string symbol,const int digits,ScenarioState &scenario,Level &rows[],string &error)
{
   ScenarioJson j;if(!j.Parse(data)){error="Invalid JSON, duplicate key or file too complex";return false;}
   if(!j.Keys(0,"schema_version|symbol|snapshot_id|source|generated_at|mode|direction|decision|trigger_tf|overall_status|activation_condition|fields")){error=j.error;return false;}
   int schema_version=1;if(!j.Int(0,"schema_version",schema_version)||schema_version!=1){error="Unsupported schema_version; expected 1";return false;}
   ScenarioState s;DefaultScenario(s,symbol);s.source="Imported";
   bool ok=j.Str(0,"symbol",s.symbol,true)&&j.Str(0,"snapshot_id",s.snapshot_id,true)&&j.Str(0,"source",s.source)&&j.Str(0,"generated_at",s.generated_at)&&
      j.Str(0,"mode",s.mode)&&j.Str(0,"direction",s.direction)&&j.Str(0,"decision",s.decision)&&j.Str(0,"trigger_tf",s.trigger_tf)&&
      j.Str(0,"overall_status",s.overall_status)&&j.Str(0,"activation_condition",s.activation_condition);
   s.latest_snapshot_id=s.snapshot_id;
   int fields=j.Find(0,"fields");if(!ok){error=j.error;return false;}if(fields<0||j.nodes[fields].kind!=2){error="fields must be a complete replacement array";return false;}
   Level temp[];int n=0;
   for(int i=fields+1;i<ArraySize(j.nodes)&&ok;i++)if(j.nodes[i].parent==fields)
   {
      if(j.nodes[i].kind!=1||n>=LZ_MAX){error="Invalid field object or more than 128 fields";return false;}
      if(!j.Keys(i,"id|name|semantic_type|value_type|from_price|to_price|timeframe|state|label_position|visible|locked|show_label|dashed|line_width|fill_opacity|border_opacity|target_index|color|fill_color")){error=j.error;return false;}
      ArrayResize(temp,n+1);Level r;ZeroMemory(r);InitFieldMeta(r);
      r.key=n+10;r.name="Level";r.from="";r.to="";r.width=1;r.transparency=80;r.visible=true;r.locked=true;r.custom=true;r.stroke=clrGold;r.fill=clrGold;
      int fill_opacity=20;
      ok=j.Int(i,"id",r.key)&&j.Str(i,"name",r.name,true)&&j.Str(i,"semantic_type",r.semantic_type,true)&&j.Str(i,"value_type",r.value_type,true)&&
         j.Str(i,"from_price",r.from,false,true)&&j.Str(i,"to_price",r.to,false,true)&&j.Str(i,"timeframe",r.timeframe)&&j.Str(i,"state",r.state)&&j.Str(i,"label_position",r.label_position)&&
         j.Bool(i,"visible",r.visible)&&j.Bool(i,"locked",r.locked)&&j.Bool(i,"show_label",r.show_label)&&j.Bool(i,"dashed",r.dashed)&&j.Int(i,"line_width",r.width)&&
         j.Int(i,"fill_opacity",fill_opacity)&&j.Int(i,"border_opacity",r.border_opacity)&&j.Int(i,"target_index",r.target_index);
      string c=HexColor(r.stroke),f=HexColor(r.fill);ok=ok&&j.Str(i,"color",c)&&j.Str(i,"fill_color",f);
      if(ok&&(!ParseHex(c,r.stroke)||!ParseHex(f,r.fill))){error="Invalid #RRGGBB color";return false;}
      r.transparency=100-fill_opacity;temp[n++]=r;
   }
   if(!ok){error=j.error;return false;}
   if(!ValidateScenario(s,temp,symbol,digits,error))return false;
   scenario=s;CopyLevels(rows,temp);return true;
}
bool ImportScenarioFile(const string path,const string symbol,const int digits,ScenarioState &scenario,Level &rows[],string &error)
{
   if(path==""||StringFind(path,":")>=0||StringFind(path,"..")>=0){error="Use a relative file in MQL5/Files";return false;}
   int h=FileOpen(path,FILE_READ|FILE_BIN|FILE_SHARE_READ);
   if(h==INVALID_HANDLE){error="Cannot open MQL5/Files/"+path;return false;}
   ulong size=FileSize(h);if(size==0||size>131072){FileClose(h);error="JSON must be between 1 byte and 128 KiB";return false;}
   uchar bytes[];int count=(int)FileReadArray(h,bytes,0,(int)size);FileClose(h);
   if(count!=(int)size){error="Incomplete JSON read";return false;}
   int offset=count>=3&&bytes[0]==239&&bytes[1]==187&&bytes[2]==191?3:0;
   string data=CharArrayToString(bytes,offset,count-offset,CP_UTF8);
   return ParseScenarioJSON(data,symbol,digits,scenario,rows,error);
}
#endif
