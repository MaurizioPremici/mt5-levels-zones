#ifndef LEVEL_STORE_MQH
#define LEVEL_STORE_MQH
#include "LevelModel.mqh"
// Terminal-local data, exact symbol key; no account or market data is read.
#define STORE_MAGIC 0x4C5A3031
#define SCENARIO_MAGIC 0x4C5A3032
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
bool ReadScenarioFile(const string path,const string symbol,const int digits,Level &rows[],ScenarioState &scenario,long &revision,const bool validate=true)
{
   int h=FileOpen(path,FILE_READ|FILE_BIN|FILE_UNICODE|FILE_SHARE_READ);
   if(h==INVALID_HANDLE) return false;
   int magic=FileReadInteger(h);
   bool v2=magic==SCENARIO_MAGIC;
   bool ok=FileSize(h)>=24 && (magic==STORE_MAGIC || v2);
   ScenarioState meta; DefaultScenario(meta,symbol);
   string saved_symbol;
   if(ok) ok=ReadText(h,saved_symbol,128) && saved_symbol==symbol;
   if(ok && v2) ok=ReadText(h,meta.snapshot_id,128) && ReadText(h,meta.latest_snapshot_id,128) && ReadText(h,meta.source,64) &&
      ReadText(h,meta.generated_at,64) && ReadText(h,meta.mode,32) && ReadText(h,meta.direction,32) && ReadText(h,meta.decision,32) &&
      ReadText(h,meta.trigger_tf,32) && ReadText(h,meta.overall_status,32) && ReadText(h,meta.activation_condition,8192);
   revision=ok ? FileReadLong(h) : 0;
   int n=ok ? FileReadInteger(h) : 0;
   ok=ok && revision>=0 && n>=0 && n<=LZ_MAX;
   Level temp[]; if(ok) ArrayResize(temp,n);
   for(int i=0;i<n && ok;i++)
   {
      temp[i].key=FileReadInteger(h);
      ok=ReadText(h,temp[i].name,validate?48:2048) && ReadText(h,temp[i].from,validate?32:256) && ReadText(h,temp[i].to,validate?32:256);
      if(!ok || FileTell(h)+20>FileSize(h)) { ok=false; break; }
      temp[i].stroke=(color)FileReadInteger(h); temp[i].fill=(color)FileReadInteger(h);
      temp[i].width=FileReadInteger(h); temp[i].transparency=FileReadInteger(h);
      int flags=FileReadInteger(h);
      temp[i].visible=(flags&1)!=0; temp[i].locked=(flags&2)!=0;
      temp[i].dashed=(flags&4)!=0; temp[i].custom=(flags&8)!=0;
      InitFieldMeta(temp[i],i<LZ_BASE?i:-1);
      if(v2)
      {
         ok=ReadText(h,temp[i].semantic_type,32) && ReadText(h,temp[i].value_type,16) && ReadText(h,temp[i].timeframe,32) &&
            ReadText(h,temp[i].state,32) && ReadText(h,temp[i].label_position,16);
         if(!ok || FileTell(h)+12>FileSize(h)){ok=false;break;}
         temp[i].show_label=FileReadInteger(h)!=0; temp[i].border_opacity=FileReadInteger(h);temp[i].target_index=FileReadInteger(h);
      }
      else
      {
         // Legacy rows may be lines even when their default type is now a zone.
         temp[i].value_type=EmptyPrice(temp[i].to)?"LEVEL":"ZONE";
         if(temp[i].name=="Breakout Price")temp[i].name="Breakout Level";
         if(temp[i].name=="Retest Price")temp[i].name="Retest Zone";
         if(temp[i].name=="Rejection Price")temp[i].name="Rejection Zone";
      }
      string error;
      ok=flags>=0 && flags<=15 && temp[i].key>0 && (!validate || ValidateLevel(temp[i],digits,error));

      for(int j=0;j<i && ok;j++) if(temp[j].key==temp[i].key) ok=false;
   }
   if(ok) ok=FileTell(h)+4==FileSize(h) && FileReadInteger(h)==STORE_END;
   FileClose(h);
   if(ok && validate) { string error; ok=ValidateScenario(meta,temp,symbol,digits,error); }
   if(ok) { CopyLevels(rows,temp); scenario=meta; }
   return ok;
}
bool ReadStoreFile(const string path,const string symbol,const int digits,Level &rows[],long &revision)
{
   ScenarioState meta;return ReadScenarioFile(path,symbol,digits,rows,meta,revision);
}
bool LoadScenario(const string symbol,const int digits,Level &rows[],ScenarioState &scenario,long &revision,string &error)
{
   error=""; string path=DataFile(symbol);
   if(!FileIsExist(path)) { DefaultLevels(rows); DefaultScenario(scenario,symbol);revision=0; return true; }
   if(ReadScenarioFile(path,symbol,digits,rows,scenario,revision)) return true;
   error="Cannot read saved data; original file kept"; return false;
}
bool LoadLevels(const string symbol,const int digits,Level &rows[],long &revision,string &error)
{ ScenarioState meta;return LoadScenario(symbol,digits,rows,meta,revision,error); }
bool WriteScenarioFile(const string path,const Level &rows[],const ScenarioState &s,const long revision)
{
   int h=FileOpen(path,FILE_WRITE|FILE_BIN|FILE_UNICODE);if(h==INVALID_HANDLE)return false;
   ResetLastError();
   bool ok=FileWriteInteger(h,SCENARIO_MAGIC)==4 && WriteText(h,s.symbol) && WriteText(h,s.snapshot_id) && WriteText(h,s.latest_snapshot_id) &&
      WriteText(h,s.source) && WriteText(h,s.generated_at) && WriteText(h,s.mode) && WriteText(h,s.direction) && WriteText(h,s.decision) &&
      WriteText(h,s.trigger_tf) && WriteText(h,s.overall_status) && WriteText(h,s.activation_condition) &&
      FileWriteLong(h,revision)==8 && FileWriteInteger(h,ArraySize(rows))==4;
   for(int i=0;i<ArraySize(rows) && ok;i++)
   {
      int flags=(rows[i].visible?1:0)|(rows[i].locked?2:0)|(rows[i].dashed?4:0)|(rows[i].custom?8:0);
      ok=FileWriteInteger(h,rows[i].key)==4 && WriteText(h,rows[i].name) && WriteText(h,rows[i].from) && WriteText(h,rows[i].to) &&
         FileWriteInteger(h,(int)rows[i].stroke)==4 && FileWriteInteger(h,(int)rows[i].fill)==4 && FileWriteInteger(h,rows[i].width)==4 &&
         FileWriteInteger(h,rows[i].transparency)==4 && FileWriteInteger(h,flags)==4 &&
         WriteText(h,rows[i].semantic_type) && WriteText(h,rows[i].value_type) && WriteText(h,rows[i].timeframe) && WriteText(h,rows[i].state) &&
         WriteText(h,rows[i].label_position) && FileWriteInteger(h,rows[i].show_label?1:0)==4 && FileWriteInteger(h,rows[i].border_opacity)==4 && FileWriteInteger(h,rows[i].target_index)==4;
   }
   ok=ok && FileWriteInteger(h,STORE_END)==4;FileFlush(h);if(GetLastError()!=0)ok=false;FileClose(h);return ok;
}
// One atomic file contains both levels and provenance, guarded by the symbol revision.
bool SaveScenario(const string symbol,const int digits,const Level &rows[],const ScenarioState &scenario,const long expected,long &new_revision,string &error)
{
   error=""; FolderCreate("LevelsZones");
   Level checked[];CopyLevels(checked,rows);ScenarioState meta=scenario;
   if(!ValidateScenario(meta,checked,symbol,digits,error))return false;
   string path=DataFile(symbol),tmp=path+"."+IntegerToString(ChartID())+".tmp";
   int lock=FileOpen(path+".lock",FILE_READ|FILE_WRITE|FILE_BIN);
   if(lock==INVALID_HANDLE) { error="Symbol is busy; try Apply again"; return false; }
   Level existing[]; long current=0;ScenarioState old;
   bool ok=LoadScenario(symbol,digits,existing,old,current,error);
   if(ok && current!=expected) { error="Another chart has changes; load last scenario"; ok=false; }
   if(ok)ok=WriteScenarioFile(tmp,checked,meta,current+1);
   if(ok)
   {
      Level verify[]; ScenarioState verify_meta;long vr=0;
      ok=ReadScenarioFile(tmp,symbol,digits,verify,verify_meta,vr) && vr==current+1 && SameLevels(checked,verify) && SameScenario(meta,verify_meta);
   }
   if(ok && FileIsExist(path)) ok=FileCopy(path,0,path+".bak",FILE_REWRITE);
   if(ok) ok=FileMove(tmp,0,path,FILE_REWRITE);
   if(!ok && error=="") error="Save failed; previous scenario kept";
   if(FileIsExist(tmp)) FileDelete(tmp);
   FileClose(lock); if(ok) new_revision=current+1; return ok;
}
bool SaveLevels(const string symbol,const int digits,const Level &rows[],const long expected,long &new_revision,string &error)
{
   ScenarioState meta;Level old[];long revision;
   if(!LoadScenario(symbol,digits,old,meta,revision,error))return false;
   return SaveScenario(symbol,digits,rows,meta,expected,new_revision,error);
}
// Drafts are recovery files, never rendered until validated with Apply.
bool SaveRecovery(const Level &rows[],const ScenarioState &s,const long base_revision)
{
   FolderCreate("LevelsZones");string path=DataFile(s.symbol)+".draft",tmp=path+"."+IntegerToString(ChartID())+".tmp";
   bool ok=WriteScenarioFile(tmp,rows,s,base_revision);
   if(ok)
   {
      Level verify[];ScenarioState meta;long base=0;
      ok=ReadScenarioFile(tmp,s.symbol,0,verify,meta,base,false) && base==base_revision && SameLevels(rows,verify) && SameScenario(s,meta);
   }
   if(ok)ok=FileMove(tmp,0,path,FILE_REWRITE);
   if(FileIsExist(tmp))FileDelete(tmp);return ok;
}
#endif
