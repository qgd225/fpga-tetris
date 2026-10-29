// Continuous machined shell and static coordinate-generated background.
// Protected hardware and field bezels are supplied by the shared atlas.
module ui_hull_background(input [10:0] x,y,input choose,duo,output reg [23:0] rgb);
 function [23:0] bezel;
  input [10:0] px,py,bx,by,w,h;
  reg [10:0] dx,dy;
  begin
   dx=px-bx;dy=py-by;bezel=24'h0a1622;
   if(dx<3 || dx>=w-3 || dy<3 || dy>=h-3)bezel=24'h607d91;
   else if(dx<6 || dx>=w-6 || dy<6 || dy>=h-6)bezel=24'h142534;
  end
 endfunction
 function bolt;
  input [10:0] px,py,bx,by;
  reg [10:0] dx,dy;
  begin
   dx=px-bx;dy=py-by;
   bolt=dx<6 && dy<6 && !((dx==0 || dx==5) && (dy==0 || dy==5));
  end
 endfunction
 reg [10:0] side_x;
 wire [5:0] star_seed=x[10:5]^{y[7:5],y[10:8]};
 wire [4:0] star_x={star_seed[4:3],3'b101};
 wire [4:0] star_y={star_seed[5:4],3'b011};
 (* rom_style="distributed" *) reg [3:0] planet_pixels[0:4095];
 (* rom_style="distributed" *) reg [23:0] planet_palette[0:15];
 (* rom_style="distributed" *) reg [5:0] moon_edge[0:40];
 (* rom_style="distributed" *) reg [2:0] rock_pixels[0:1023];
 (* rom_style="distributed" *) reg [23:0] rock_palette[0:7];
 initial begin
  $readmemh("ui_asteroid_pixels.mem",rock_pixels);
  $readmemh("ui_asteroid_palette.mem",rock_palette);
  $readmemh("ui_planet_pixels.mem",planet_pixels);
  $readmemh("ui_planet_palette.mem",planet_palette);
  $readmemh("ui_planet_moon.mem",moon_edge);
 end
 wire [5:0] planet_x=(x+11'd24)>>1,planet_y=(y-11'd16)>>1;
 wire [3:0] planet_code=planet_pixels[{planet_y,planet_x}];
 wire [10:0] moon_dy=y<700?11'd700-y:y-11'd700;
 wire [5:0] moon_radius=moon_edge[moon_dy<=40?moon_dy[5:0]:6'd0];
 wire rock_large=y<400;
 wire [4:0] rock_x=rock_large?((x-11'd18)>>1):(11'd85-x);
 wire [4:0] rock_y=rock_large?((y-11'd302)>>1):(y-11'd490);
 wire [2:0] rock_code=rock_pixels[{rock_y,rock_x}];
 wire rock_visible=(x>=18 && x<82 && y>=302 && y<366) ||
                   (x>=54 && x<86 && y>=490 && y<522);
 wire [11:0] meteor_axis={1'b0,x}+{1'b0,y};
 always @(*)begin
  rgb=24'h070d15;
  // Sparse static stars; never uses a frame counter or an image ROM.
  if(star_seed[2:0]==3 && x[4:0]==star_x && y[4:0]==star_y)
   rgb=star_seed[5]?24'h607d91:24'h526c80;
  if(star_seed==6'd43 && ((x[4:0]==star_x && (y[4:0]==star_y-1 || y[4:0]==star_y+1)) ||
      (y[4:0]==star_y && (x[4:0]==star_x-1 || x[4:0]==star_x+1))))rgb=24'h314b5f;
  // Cel-shaded planet silhouettes behind the hull; tiny one-dimensional
  // extents avoid multipliers and full-frame bitmap storage.
  if(x<104 && y>=16 && y<144 && planet_code!=0)rgb=planet_palette[planet_code];
  // One quiet meteor in the outer starfield, ahead of the distant rocks.
  // One-pixel tapered tail, stepped brightness; never crosses the hull.
  if(x>=20 && x<86 && y>=202 && y<270 && meteor_axis==288)
   rgb=x<34?24'h93acb9:x<50?24'h607f94:x<68?24'h405e75:24'h1c3045;
  if(x>=20 && x<42 && (meteor_axis==287 || meteor_axis==289))
   rgb=x<28?24'h607f94:24'h2c455b;
  if(x>=18 && x<=22 && y>=266 && y<=270 && meteor_axis>=286 && meteor_axis<=290)
   rgb=24'hb3c8d8;
  if(rock_visible && rock_code!=0)rgb=rock_palette[rock_code];
  if(moon_dy<=40 && x>=1264-moon_radius && x<=1264+moon_radius)begin
   rgb=x<1264?24'h526c80:24'h607d91;
   if((x[4:2]^y[4:2])==3 || (x[3:1]==4 && y[3:1]<4))rgb=24'h314b5f;
   if(x<=1266-moon_radius)rgb=24'hb3c8d8;
  end
  if(x>=104 && x<1256 && y>=32 && y<696 && x+y>=170 && x+696-y>=170 && x+2*y<2648)begin
   rgb=24'h314b5f;
   if(x<108 || x>=1252 || y<36 || y>=692)rgb=24'h607d91;
   else if(x<112 || x>=1248 || y<40 || y>=688)rgb=24'h142534;
   if(x==120 || x==1238 || y==130 || y==634)rgb=24'h142534;
   if(x==121 || x==1239 || y==131 || y==635)rgb=24'h526c80;
   // Open seams follow the same large hull plates, without decorative boxes.
   if((x==132 || x==1228) && y>=152 && y<624)rgb=24'h142534;
   if((x==133 || x==1229) && y>=152 && y<624)rgb=24'h3a5064;
   if(y>=524 && y<610 && (x+y==790 || x-y==450))rgb=24'h142534;
   if(y>=524 && y<610 && (x+y==791 || x-y==451))rgb=24'h526c80;
   if(y>=52 && y<116 && (x==1220 || x==1221))rgb=x==1220?24'h142534:24'h526c80;
   if((x>=168 && x<192 || x>=1216 && x<1240) && y>=548 && y<572 && y[2:0]<3)
    rgb=y[2:0]==0?24'h607d91:24'h142534;
   if((x>=304 && x<320 || x>=1216 && x<1240) && y>=652 && y<668 && y[2:0]<3)
    rgb=y[2:0]==0?24'h607d91:24'h142534;
   // Joined lower service plates: long open seams meet existing panel edges.
   // Shallow stepped bevels and inset vents use the established steel ramp.
   if(x==288 && y>=512 && y<586 || y==614 && x>=142 && x<260 ||
      y>=586 && y<614 && x+y==874)rgb=24'h142534;
   if(x==289 && y>=512 && y<586 || y==615 && x>=142 && x<260 ||
      y>=586 && y<614 && x+y==875)rgb=24'h526c80;
   if(y==650 && (x>=136 && x<288 || x>=1116 && x<1234))rgb=24'h142534;
   if(y==651 && (x>=136 && x<288 || x>=1116 && x<1234))rgb=24'h526c80;
   if((x>=356 && x<412 || x>=908 && x<964) && y>=650 && y<674)begin
    if(y[2:0]<4)rgb=y[2:0]==0?24'h526c80:24'h142534;
    if((x==356 || x==908) && y[2:0]<4)rgb=24'h091722;
   end
   if(x>=1118 && x<1126 && y>=448 && y<472 && y[2:0]<3)
    rgb=y[2:0]==0?24'h526c80:24'h142534;
   // Small recessed amber fasteners belong to the long outer rail.
   if(x>=126 && x<130 && (y>=250 && y<258 || y>=554 && y<562))
    rgb=x==126?24'h142534:24'h82622b;
   if(bolt(x,y,146,620)||bolt(x,y,278,600)||bolt(x,y,440,650)||
      bolt(x,y,892,650)||bolt(x,y,1118,640)||bolt(x,y,1228,620))
    rgb=y[0]?24'h526c80:24'h142534;
   if(bolt(x,y,126,140)||bolt(x,y,310,140)||bolt(x,y,310,620)||
      bolt(x,y,1228,140)||bolt(x,y,1228,644)||bolt(x,y,126,674))
    rgb=y[0]?24'h607d91:24'h142534;
  end
  if(!choose)begin
   side_x=duo?328:376;
   if(x>=298 && x<328 && y>=136 && y<632)rgb=24'h3a5064;
   if(x>=952 && x<972 && y>=136 && y<632)rgb=24'h3a5064;
   if(!duo && ((x>=352 && x<376)||(x>=904 && x<928)) && y>=144 && y<624)rgb=24'h3a5064;
   if(y>=132 && y<632 && ((x>=side_x && x<side_x+24)||(x>=(duo?928:880) && x<(duo?952:904))))begin
    rgb=24'h3a5064;
    if(x==side_x+3 || x==(duo?931:883))rgb=24'h607d91;
    if(x>=side_x+20 && x<side_x+24 || x>=(duo?928:880) && x<(duo?932:884))rgb=24'h142534;
    if((y>=143 && y<159)||(y>=289 && y<305)||(y>=603 && y<619))begin
     if(x>=side_x+5 && x<side_x+18 || x>=(duo?934:886) && x<(duo?946:898))rgb=24'h142534;
     if(y==147 || y==293 || y==607)rgb=24'h607d91;
    end
   end
   if(x>=352 && x<928 && (y>=132 && y<144 || y>=624 && y<632))begin
    rgb=(y==133 || y==625)?24'h607d91:24'h142534;
   end
   if(x>=466 && x<880 && y>=640 && y<689)rgb=bezel(x,y,466,640,414,49);
   if(!duo && x>=972 && x<1114 && y>=148 && y<314)rgb=bezel(x,y,972,148,142,166);
  end else begin
   side_x=0;
   if(x>=200 && x<680 && y>=156 && y<616)begin
    rgb=24'h142534;
    if(x<203 || x>=677 || y<159 || y>=613)rgb=24'h607d91;
    else if(x<207 || x>=673 || y<163 || y>=609)rgb=24'h091722;
   end
   if(x>=716 && x<1208 && y>=172 && y<546)begin
    rgb=24'h0a1622;
    if(x<719 || x>=1205 || y<175 || y>=543)rgb=24'h3a5064;
   end
  end
 end
endmodule
