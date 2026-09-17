#ifndef LEVEL_RENDERER_MQH
#define LEVEL_RENDERER_MQH
#include <Canvas/Canvas.mqh>
CCanvas drawing;
bool canvas_ready=false;
int plot_w=0,plot_h=0;
double view_min=0,view_max=0;
datetime render_time=0;
int IClamp(int v,int lo,int hi) { return MathMax(lo,MathMin(hi,v)); }
int PriceY(const double p)
{
   if(view_max<=view_min) return 0;
   int exact_x=0,exact_y=0;
   if(render_time>0 && ChartTimePriceToXY(0,0,render_time,p,exact_x,exact_y)) return exact_y;
   double y=(view_max-p)/(view_max-view_min)*(plot_h-1);
   return (int)MathMax(-100000,MathMin(100000,y));
}
double YPrice(int y)
{
   int sub=0; datetime t=0; double price=0;
   if(ChartXYToTimePrice(0,plot_w/2,y,sub,t,price) && sub==0) return price;
   return view_max-(double)y/MathMax(1,plot_h-1)*(view_max-view_min);
}
bool ActiveLevel(const int i) { return i>=0 && i<ArraySize(levels) && levels[i].visible && !EmptyPrice(levels[i].from); }
string LevelDetail(const int i)
{
   return (StaleScenario(g_scenario)?"OLD SNAPSHOT | ":"")+levels[i].name+" "+levels[i].timeframe+"  "+levels[i].from+(EmptyPrice(levels[i].to)?"":" - "+levels[i].to)+"  ["+levels[i].state+"]";
}
// Straight-alpha source-over composition for overlapping highlighted bands.
uint Blend(const uint dst,const color source,const int transparency)
{
   double sa=(100-transparency)/100.0,da=(double)((dst>>24)&255)/255.0;
   double a=sa+da*(1-sa); if(a<=0) return 0;
   uint rgb=(uint)source;
   uint r=(uint)MathRound(((rgb&255)*sa+((dst>>16)&255)*da*(1-sa))/a);
   uint g=(uint)MathRound((((rgb>>8)&255)*sa+((dst>>8)&255)*da*(1-sa))/a);
   uint b=(uint)MathRound((((rgb>>16)&255)*sa+(dst&255)*da*(1-sa))/a);
   return ((uint)MathRound(a*255)<<24)|(r<<16)|(g<<8)|b;
}
void Stroke(const int y,const Level &r)
{
   if(y<0 || y>=plot_h) return;
   int top=y-r.width/2,bottom=top+r.width-1;
   if(!r.dashed) drawing.FillRectangle(0,top,plot_w-1,bottom,ColorToARGB(r.stroke,(uchar)MathRound(255.0*r.border_opacity/100)));
   else for(int x=0;x<plot_w;x+=18) drawing.FillRectangle(x,top,MathMin(plot_w-1,x+10),bottom,ColorToARGB(r.stroke,(uchar)MathRound(255.0*r.border_opacity/100)));
}
int HandleX()
{
   int x=plot_w/2;
   if(!panel_hidden && !panel_collapsed && x>=panel_x && x<=panel_x+PX(PANEL_W))
      x=panel_x>PX(150) ? panel_x/2 : (panel_x+PX(PANEL_W)+plot_w)/2;
   return IClamp(x,30,MathMax(30,plot_w-30));
}
void SmallHandle(const int x,const int y,const color c,const bool whole)
{
   if(y<6 || y>=plot_h-6) return;
   int w=whole?9:4,h=whole?6:4;
   drawing.FillRectangle(x-w,y-h,x+w,y+h,ColorToARGB(C'15,22,29'));
   drawing.Rectangle(x-w,y-h,x+w,y+h,ColorToARGB(c));
   if(whole)
   {
      drawing.LineHorizontal(x-4,x+4,y-2,ColorToARGB(c));
      drawing.LineHorizontal(x-4,x+4,y+2,ColorToARGB(c));
   }
}
void ChartTag(const string suffix,const string text,const string tooltip,const int y,const color clr,const bool compact,const bool right=false)
{
   string name="LZ_TAG_"+suffix,caption=text;
   int w=DP(compact?78:(int)MathMin(470,16+StringLen(text)*6)),h=DP(22);
   int x=right?MathMax(DP(8),plot_w-w-DP(8)):DP(8);
   if(!panel_hidden && !panel_collapsed && panel_x<x+w && panel_x+PX(PANEL_W)>x && y+h>panel_y && y<panel_y+panel_h)
   {
      x=panel_x+PX(PANEL_W)+DP(8);
      if(x+w>plot_w)
      {
         int left_space=panel_x-DP(16),right_space=plot_w-panel_x-PX(PANEL_W)-DP(16);
         bool use_right=right_space>left_space;
         x=use_right?panel_x+PX(PANEL_W)+DP(8):DP(8);
         w=MathMin(w,MathMax(left_space,right_space));
         if(w<DP(65))return;
         caption="Details (hover)";
      }
   }
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w); ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'15,22,29'); ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clr); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial"); ObjectSetString(0,name,OBJPROP_TEXT,caption);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,5); ObjectSetInteger(0,name,OBJPROP_BACK,false);
}
void DrawTags()
{
   ObjectsDeleteAll(0,"LZ_TAG_");
   int indexes[],ys[],n=0;
   for(int i=0;i<ArraySize(levels);i++) if(ActiveLevel(i) && levels[i].show_label)
   {
      double p=StringToDouble(levels[i].from);
      if(!EmptyPrice(levels[i].to)) p=(p+StringToDouble(levels[i].to))/2;
      int y=PriceY(p);
      if(y<0 || y>=plot_h) continue;
      ArrayResize(indexes,n+1); ArrayResize(ys,n+1); indexes[n]=i; ys[n]=IClamp(y-DP(11),DP(4),plot_h-DP(26)); n++;
   }
   for(int i=1;i<n;i++)
   {
      int k=indexes[i],y=ys[i],j=i-1;
      while(j>=0 && ys[j]>y) { ys[j+1]=ys[j]; indexes[j+1]=indexes[j]; j--; }
      ys[j+1]=y; indexes[j+1]=k;
   }
   int last=-DP(24);
   for(int i=0;i<n;)
   {
      int end=i+1;
      while(end<n && ys[end]-ys[end-1]<DP(24) && levels[indexes[end]].label_position==levels[indexes[i]].label_position) end++;
      int count=end-i;
      // Nearby labels use a compact group with a complete native hover tooltip.
      if(count>1)
      {
         string tip="";
         for(int j=i;j<end;j++) tip+=(j>i?"\n":"")+LevelDetail(indexes[j]);
         int y=IClamp(MathMax(last+DP(24),ys[i]),DP(4),plot_h-DP(26));
         ChartTag(IntegerToString(i),IntegerToString(count)+" levels",tip,y,levels[indexes[i]].stroke,true,levels[indexes[i]].label_position=="RIGHT");
         last=y;
      }
      else
      {
         int y=IClamp(MathMax(last+DP(24),ys[i]),DP(4),plot_h-DP(26));
         ChartTag(IntegerToString(i),LevelDetail(indexes[i]),LevelDetail(indexes[i]),y,levels[indexes[i]].stroke,false,levels[indexes[i]].label_position=="RIGHT");
         last=y;
      }
      i=end;
   }
}
bool RenderLevels()
{
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   plot_w=MathMax(1,cw-72); plot_h=MathMax(1,ch);
   view_min=ChartGetDouble(0,CHART_PRICE_MIN,0); view_max=ChartGetDouble(0,CHART_PRICE_MAX,0);
   if(view_max<=view_min || plot_h<30) return false;
   int anchor_sub=0; double anchor_price=0;
   ChartXYToTimePrice(0,plot_w/2,plot_h/2,anchor_sub,render_time,anchor_price);
   if(!canvas_ready)
   {
      canvas_ready=drawing.CreateBitmapLabel(0,0,"LZ_CANVAS",0,0,plot_w,plot_h,COLOR_FORMAT_ARGB_NORMALIZE);
      if(!canvas_ready) { status="Unable to create chart drawing"; return false; }
      ObjectSetInteger(0,"LZ_CANVAS",OBJPROP_BACK,true);
      ObjectSetInteger(0,"LZ_CANVAS",OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,"LZ_CANVAS",OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,"LZ_CANVAS",OBJPROP_ZORDER,0);
      ObjectSetString(0,"LZ_CANVAS",OBJPROP_TOOLTIP,"\n");
   }
   if(drawing.Width()!=plot_w || drawing.Height()!=plot_h)
      if(!drawing.Resize(plot_w,plot_h)) return false;
   drawing.Erase(0);
   int edges[]; ArrayResize(edges,2); edges[0]=0; edges[1]=plot_h;
   for(int i=0;i<ArraySize(levels);i++) if(ActiveLevel(i) && !EmptyPrice(levels[i].to))
   {
      int n=ArraySize(edges); ArrayResize(edges,n+2);
      edges[n]=IClamp(PriceY(StringToDouble(levels[i].from)),0,plot_h);
      edges[n+1]=IClamp(PriceY(StringToDouble(levels[i].to)),0,plot_h);
   }
   ArraySort(edges);
   for(int j=1;j<ArraySize(edges);j++)
   {
      int top=edges[j-1],bottom=edges[j]; if(bottom<=top) continue;
      double p=YPrice((top+bottom)/2); uint pixel=0;
      for(int i=0;i<ArraySize(levels);i++) if(ActiveLevel(i) && !EmptyPrice(levels[i].to))
         if(p>=StringToDouble(levels[i].from) && p<=StringToDouble(levels[i].to))
            pixel=Blend(pixel,levels[i].fill,levels[i].transparency);
      if(pixel!=0) drawing.FillRectangle(0,top,plot_w-1,bottom-1,pixel);
   }
   for(int i=0;i<ArraySize(levels);i++) if(ActiveLevel(i))
   {
      int a=PriceY(StringToDouble(levels[i].from)); Stroke(a,levels[i]);
      bool zone=!EmptyPrice(levels[i].to);
      int b=zone?PriceY(StringToDouble(levels[i].to)):a;
      if(zone) Stroke(b,levels[i]);
      if(!levels[i].locked)
      {
         int x=HandleX(); SmallHandle(x,a,levels[i].stroke,false);
         if(zone)
         {
            SmallHandle(x,b,levels[i].stroke,false);
            if(a>=0 && b<plot_h) SmallHandle(x,IClamp((a+b)/2,12,plot_h-12),levels[i].stroke,true);
         }
      }
   }
   drawing.Update(false); DrawTags(); ChartRedraw(); return true;
}
// Hit modes: 1 lower endpoint, 2 upper endpoint, 3 translate the entire band.
int HitLevel(const int x,const int y,int &mode,const bool include_locked=false)
{
   mode=0; if(x<0 || x>=plot_w || y<0 || y>=plot_h) return -1;
   int best=-1,distance=7;
   for(int i=ArraySize(levels)-1;i>=0;i--) if(ActiveLevel(i) && (include_locked || !levels[i].locked))
   {
      int a=PriceY(StringToDouble(levels[i].from));
      bool zone=!EmptyPrice(levels[i].to); int b=zone?PriceY(StringToDouble(levels[i].to)):a;
      if(zone && a>=0 && b<plot_h && MathAbs(x-HandleX())<=12 && MathAbs(y-IClamp((a+b)/2,12,plot_h-12))<=9)
      { mode=3; return i; }
      int d=MathAbs(y-a); if(d<distance) { best=i; distance=d; mode=1; }
      if(zone) { d=MathAbs(y-b); if(d<distance) { best=i; distance=d; mode=2; } }
   }
   return best;
}
void DestroyDrawing()
{
   if(canvas_ready) drawing.Destroy(); canvas_ready=false;
   ObjectsDeleteAll(0,"LZ_TAG_"); ObjectDelete(0,"LZ_HOVER");
}
#endif
