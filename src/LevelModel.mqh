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
};
string Trim(string s) { StringTrimLeft(s); StringTrimRight(s); return s; }
bool EmptyPrice(string s) { s=Trim(s); return s=="" || s=="-" || s=="—"; }
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
bool ValidateLevel(Level &r,const int digits,string &message)
{
   r.name=Trim(r.name);
   if(StringLen(r.name)==0 || StringLen(r.name)>48 || StringFind(r.name,"\n")>=0 || StringFind(r.name,"\r")>=0)
   { message="Name required, up to 48 characters"; return false; }
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
   if(EmptyPrice(r.to)) { r.to=""; return true; }
   if(!ParsePrice(r.to,digits,b,message)) return false;
   if(a==b) { message="Zone prices must be different"; return false; }
   r.from=DoubleToString(MathMin(a,b),digits);
   r.to=DoubleToString(MathMax(a,b),digits);
   return true;
}
void DefaultLevels(Level &rows[])
{
   string names[]={"Entry Price","Breakout Price","Retest Price","Rejection Price","Support","Resistance","SL","TP 1","TP 2"};
   color colors[]={C'130,73,255',C'170,185,199',C'31,134,255',C'255,126,18',C'43,205,95',C'255,67,74',C'255,67,74',C'39,169,255',C'43,205,95'};
   ArrayResize(rows,LZ_BASE);
   for(int i=0;i<LZ_BASE;i++)
   {
      rows[i].key=i+1; rows[i].name=names[i]; rows[i].from=""; rows[i].to="";
      rows[i].stroke=colors[i]; rows[i].fill=colors[i]; rows[i].width=1;
      rows[i].transparency=80; rows[i].visible=true; rows[i].locked=true;
      rows[i].dashed=false; rows[i].custom=false;
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
         a[i].visible!=b[i].visible || a[i].locked!=b[i].locked || a[i].custom!=b[i].custom) return false;
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
