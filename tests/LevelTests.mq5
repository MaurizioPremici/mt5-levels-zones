#property strict
#include "../src/LevelStore.mqh"
int passed=0,failed=0;
string report="";
void Check(const bool condition,const string name)
{
   report+=(condition?"PASS ":"FAIL ")+name+"\r\n";
   if(condition) passed++; else failed++;
}
void OnStart()
{
   double p=0; string error; Level r[]; DefaultLevels(r);
   Check(ArraySize(r)==9 && r[6].name=="SL","Nine defaults including SL");
   Check(r[0].from=="" && r[0].to=="","No demo price on startup");
   Check(ParsePrice(" 1.15008 ",5,p,error) && p==1.15008,"Pasted price with whitespace");
   Check(ParsePrice("151,237",3,p,error) && p==151.237,"JPY and decimal comma");
   Check(!ParsePrice("1.150,08",5,p,error),"Reject mixed separators");
   Check(!ParsePrice("1.15008abc",5,p,error),"Reject partial numeric conversion");
   Check(!ParsePrice("1.150081",5,p,error),"Reject excess precision");
   Check(!ParsePrice("0",5,p,error) && !ParsePrice("-1",5,p,error),"Reject nonpositive prices");
   Check(!ParsePrice("1e3",5,p,error) && !ParsePrice("1.",5,p,error),"Reject exponents and incomplete decimal");
   r[0].from="1.15100"; r[0].to="1.14900";
   Check(ValidateLevel(r[0],5,error) && r[0].from=="1.14900" && r[0].to=="1.15100","Normalize reversed range");
   r[1].to="1.2"; Check(!ValidateLevel(r[1],5,error),"Reject missing first endpoint"); r[1].to="";
   r[2].from="1.2"; r[2].to="1.2"; Check(!ValidateLevel(r[2],5,error),"Reject zero-width range"); r[2].from="";r[2].to="";
   color c; Check(ParseHex("#1F86FF",c) && HexColor(c)=="#1F86FF","Exact RGB/BGR conversion");
   Check(!ParseHex("#GG0011",c),"Reject invalid HEX");
   Check(SymbolKey("EURUSD")!=SymbolKey("USDJPY") && SymbolKey("EURUSD.a")!=SymbolKey("EURUSD_a"),"Exact distinct symbol keys");
   string sym="__LZ_TEST_"+IntegerToString(GetTickCount64()),sym2=sym+"JPY";
   long rev=0; r[0].name="Zona personalizzata à"; r[0].fill=C'12,34,56';r[0].transparency=73;r[0].locked=false;r[0].dashed=true;r[0].width=4;
   Check(SaveLevels(sym,5,r,0,rev,error) && rev==1,"First durable save");
   Level loaded[]; long got=0;
   Check(LoadLevels(sym,5,loaded,got,error) && got==1 && SameLevels(r,loaded),"Round trip names, prices, colors and style");
   Level other[]; long otherrev=0;
   Check(LoadLevels(sym2,3,other,otherrev,error) && otherrev==0 && other[0].from=="","Other pair remains empty");
   r[0].from="1.14800"; Check(SaveLevels(sym,5,r,rev,rev,error) && rev==2,"Second save increments revision");
   long stale=0; Check(!SaveLevels(sym,5,loaded,1,stale,error),"Reject stale write from another chart");
   Check(LoadLevels(sym,5,loaded,got,error) && got==2 && loaded[0].from=="1.14800","Stale draft cannot overwrite current value");
   Level backup[]; long br=0;
   Check(ReadStoreFile(DataFile(sym)+".bak",sym,5,backup,br) && br==1,"Previous complete revision retained as backup");
   int h=FileOpen(DataFile(sym),FILE_WRITE|FILE_BIN); FileWriteInteger(h,123);FileClose(h);
   Check(!LoadLevels(sym,5,loaded,got,error),"Detect corrupt state");
   Check(!SaveLevels(sym,5,r,2,rev,error),"Do not overwrite corrupt state with defaults");
   FileDelete(DataFile(sym)); FileDelete(DataFile(sym)+".bak");FileDelete(DataFile(sym)+".lock");
   report+="RESULT "+IntegerToString(passed)+" passed, "+IntegerToString(failed)+" failed\r\n";
   int f=FileOpen("LZ_core_test_results.txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(f!=INVALID_HANDLE) { FileWriteString(f,report); FileClose(f); }
   Print(report);
}
