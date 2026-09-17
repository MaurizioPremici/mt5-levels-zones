#ifndef LEVEL_STORE_MQH
#define LEVEL_STORE_MQH
#include "LevelModel.mqh"
// Terminal-local data, exact symbol key; no account or market data is read.
#define STORE_MAGIC 0x4C5A3031
#define STORE_END   0x454E4431
string DataFile(const string symbol) { return "LevelsZones\\"+SymbolKey(symbol)+".dat"; }
bool WriteText(const int h,const string s)
{
   int n=StringLen(s); if(FileWriteInteger(h,n)!=4) return false;
   return n==0 || FileWriteString(h,s,n)==(uint)(n*2);
}
bool ReadText(const int h,string &s,const int maxlen)
{
   if(FileTell(h)+4>FileSize(h)) return false;
   int n=FileReadInteger(h);
   if(n<0 || n>maxlen || FileTell(h)+(ulong)(n*2)>FileSize(h)) return false;
   s=n==0 ? "" : FileReadString(h,n); return StringLen(s)==n;
}
bool ReadStoreFile(const string path,const string symbol,const int digits,Level &rows[],long &revision)
{
   int h=FileOpen(path,FILE_READ|FILE_BIN|FILE_UNICODE|FILE_SHARE_READ);
   if(h==INVALID_HANDLE) return false;
   bool ok=FileSize(h)>=24 && FileReadInteger(h)==STORE_MAGIC;
   string saved_symbol;
   if(ok) ok=ReadText(h,saved_symbol,128) && saved_symbol==symbol;
   revision=ok ? FileReadLong(h) : 0;
   int n=ok ? FileReadInteger(h) : 0;
   ok=ok && revision>=1 && n>=LZ_BASE && n<=LZ_MAX;
   Level temp[]; if(ok) ArrayResize(temp,n);
   for(int i=0;i<n && ok;i++)
   {
      temp[i].key=FileReadInteger(h);
      ok=ReadText(h,temp[i].name,48) && ReadText(h,temp[i].from,32) && ReadText(h,temp[i].to,32);
      if(!ok || FileTell(h)+20>FileSize(h)) { ok=false; break; }
      temp[i].stroke=(color)FileReadInteger(h); temp[i].fill=(color)FileReadInteger(h);
      temp[i].width=FileReadInteger(h); temp[i].transparency=FileReadInteger(h);
      int flags=FileReadInteger(h);
      temp[i].visible=(flags&1)!=0; temp[i].locked=(flags&2)!=0;
      temp[i].dashed=(flags&4)!=0; temp[i].custom=(flags&8)!=0;
      string error;
      ok=flags>=0 && flags<=15 && temp[i].key>0 && ValidateLevel(temp[i],digits,error);
      if(i<LZ_BASE) ok=ok && !temp[i].custom && temp[i].key==i+1;
      else ok=ok && temp[i].custom;
      for(int j=0;j<i && ok;j++) if(temp[j].key==temp[i].key) ok=false;
   }
   if(ok) ok=FileTell(h)+4==FileSize(h) && FileReadInteger(h)==STORE_END;
   FileClose(h);
   if(ok) CopyLevels(rows,temp);
   return ok;
}
bool LoadLevels(const string symbol,const int digits,Level &rows[],long &revision,string &error)
{
   error=""; string path=DataFile(symbol);
   if(!FileIsExist(path)) { DefaultLevels(rows); revision=0; return true; }
   if(ReadStoreFile(path,symbol,digits,rows,revision)) return true;
   error="Salvataggio non leggibile: originale conservato"; return false;
}
// Optimistic revision check under a per-symbol exclusive lock. Never overwrite a newer draft.
bool SaveLevels(const string symbol,const int digits,const Level &rows[],const long expected,long &new_revision,string &error)
{
   error=""; FolderCreate("LevelsZones");
   string path=DataFile(symbol),tmp=path+"."+IntegerToString(ChartID())+".tmp";
   int lock=FileOpen(path+".lock",FILE_READ|FILE_WRITE|FILE_BIN);
   if(lock==INVALID_HANDLE) { error="Coppia occupata: riprova Applica"; return false; }
   Level existing[]; long current=0;
   bool ok=LoadLevels(symbol,digits,existing,current,error);
   if(ok && current!=expected) { error="Modifiche da altro grafico: usa Ricarica"; ok=false; }
   int h=INVALID_HANDLE;
   if(ok)
   {
      h=FileOpen(tmp,FILE_WRITE|FILE_BIN|FILE_UNICODE);
      ok=h!=INVALID_HANDLE;
   }
   if(ok)
   {
      ResetLastError();
      ok=FileWriteInteger(h,STORE_MAGIC)==4 && WriteText(h,symbol);
      ok=ok && FileWriteLong(h,current+1)==8 && FileWriteInteger(h,ArraySize(rows))==4;
      for(int i=0;i<ArraySize(rows) && ok;i++)
      {
         ok=FileWriteInteger(h,rows[i].key)==4 && WriteText(h,rows[i].name) && WriteText(h,rows[i].from) && WriteText(h,rows[i].to);
         int flags=(rows[i].visible?1:0)|(rows[i].locked?2:0)|(rows[i].dashed?4:0)|(rows[i].custom?8:0);
         ok=ok && FileWriteInteger(h,(int)rows[i].stroke)==4 && FileWriteInteger(h,(int)rows[i].fill)==4 &&
            FileWriteInteger(h,rows[i].width)==4 && FileWriteInteger(h,rows[i].transparency)==4 && FileWriteInteger(h,flags)==4;
      }
      ok=ok && FileWriteInteger(h,STORE_END)==4;
      FileFlush(h); if(GetLastError()!=0) ok=false;
   }
   if(h!=INVALID_HANDLE) FileClose(h);
   if(ok)
   {
      Level verify[]; long vr=0;
      ok=ReadStoreFile(tmp,symbol,digits,verify,vr) && vr==current+1 && SameLevels(rows,verify);
   }
   if(ok && FileIsExist(path)) ok=FileCopy(path,0,path+".bak",FILE_REWRITE);
   if(ok) ok=FileMove(tmp,0,path,FILE_REWRITE);
   if(!ok && error=="") error="Salvataggio fallito: livelli precedenti conservati";
   if(FileIsExist(tmp)) FileDelete(tmp);
   FileClose(lock);
   if(ok) new_revision=current+1;
   return ok;
}
#endif
