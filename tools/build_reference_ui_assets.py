"""Prepare the approved UI material for the RTL renderer; no gameplay state."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter,ImageChops
import json,hashlib,math,re

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'Tetris.srcs/sources_1/new'
ASSET=ROOT/'assets/reference_ui'
ASSET.mkdir(parents=True,exist_ok=True)
source=ROOT/'docs/参考图/最新参考图/05_双人闯关UI.png'
art=Image.open(source).convert('RGB')
core_source=ASSET/'source_core_pipe.png'
panel_source=ASSET/'source_header_panels.png'
core_art=Image.open(core_source).convert('RGB')
panel_art=Image.open(panel_source).convert('RGB')
# Central field and existing preview sample coordinates are unchanged in RTL.
xs=[0,231,254,422,447,463,1134,1156,1175,1321,1340,1378,1444,1468,1672]
xd=[0,152,168,280,298,352,928,972,984,1096,1112,1130,1184,1200,1280]
ys=[0,185,815,941];yd=[0,144,624,720]
mesh=[]
for j in range(len(ys)-1):
    for i in range(len(xs)-1):
        mesh.append(((xd[i],yd[j],xd[i+1],yd[j+1]),(xs[i],ys[j],xs[i],ys[j+1],xs[i+1],ys[j+1],xs[i+1],ys[j])))
skin=art.transform((1280,720),Image.Transform.MESH,mesh,Image.Resampling.NEAREST)
def map_axis(v,sp,dp):
    for i in range(len(sp)-1):
        if v<=sp[i+1]:return round(dp[i]+(v-sp[i])*(dp[i+1]-dp[i])/(sp[i+1]-sp[i]))
    return dp[-1]
def mr(r):return [map_axis(r[0],xs,xd),map_axis(r[1],ys,yd),map_axis(r[2],xs,xd),map_axis(r[3],ys,yd)]
def box(r,color):ImageDraw.Draw(skin).rectangle((r[0],r[1],r[2]-1,r[3]-1),fill=color)
def ninepatch(crop,sx,sy,tx,ty):
    t=panel_art.crop(crop);m=[]
    for j in range(len(sy)-1):
        for i in range(len(sx)-1):
            m.append(((tx[i]-tx[0],ty[j]-ty[0],tx[i+1]-tx[0],ty[j+1]-ty[0]),(sx[i]-crop[0],sy[j]-crop[1],sx[i]-crop[0],sy[j+1]-crop[1],sx[i+1]-crop[0],sy[j+1]-crop[1],sx[i+1]-crop[0],sy[j]-crop[1])))
    skin.paste(t.transform((tx[-1]-tx[0],ty[-1]-ty[0]),Image.Transform.MESH,m,Image.Resampling.NEAREST),(tx[0],ty[0]))

# Copy the chosen panel surfaces rather than drawing new panel silhouettes.
ninepatch((197,188,433,418),[197,236,411,433],[188,249,395,418],[143,168,280,298],[148,192,304,320])
ninepatch((1166,188,1367,413),[1166,1186,1354,1367],[188,249,395,413],[970,984,1096,1112],[148,192,304,320])
ninepatch((220,434,421,676),[220,239,407,421],[434,487,617,676],[154,168,280,294],[332,368,480,506])
# Dynamic holes: none of the sampled blocks, numbers, bars or lights is baked in.
box([352,144,928,624],'#091722')
# Fig.3 zones 3/4/5: crisp mechanical edges with a shared upper-left key light.
def poly(points,fill):ImageDraw.Draw(skin).polygon(points,fill=fill)
def line(points,fill,width=1):ImageDraw.Draw(skin).line(points,fill=fill,width=width)
def chamfer(r,c):
    x,y,rr,bb=r
    return [(x+c,y),(rr-c-1,y),(rr-1,y+c),(rr-1,bb-c-1),
            (rr-c-1,bb-1),(x+c,bb-1),(x,bb-c-1),(x,y+c)]
def fastener(x,y):
    box([x-3,y-3,x+4,y+4],'#0a1622')
    poly([(x-1,y-2),(x+2,y-2),(x+2,y+1),(x,y+2),(x-2,y)],'#5d778f')
    line([(x-1,y),(x+1,y)],'#142534')
def recess(r,cut=7):
    x,y,rr,bb=r
    poly(chamfer(r,cut),'#091722')
    poly(chamfer([x+1,y+1,rr-1,bb-1],cut-1),'#5d778f')
    poly(chamfer([x+3,y+3,rr-2,bb-2],cut-2),'#22323f')
    poly(chamfer([x+5,y+5,rr-4,bb-4],max(2,cut-3)),'#0a1622')
    line([(x+cut,y+4),(rr-cut-1,y+4),(rr-5,y+cut)],'#101e29',2)
    line([(x+6,bb-cut-2),(x+cut,bb-5),(rr-cut-1,bb-5),(rr-5,bb-cut-1)],'#3b5366')
# Shoulder plates meet the bezel; no separate decorative boxes.
for l,r in [(298,328),(952,970)]:
    box([l,136,r,632],'#3a5064')
    line([(l,140),(l,628)],'#1c2c3a',2)
    for yy in [148,306,474]:
        line([(l+1,yy),(r-7,yy),(r-1,yy+6)],'#152635',2)
        line([(l+1,yy+2),(r-8,yy+2)],'#5d778f')
for l,r in [(328,352),(928,952)]:
    box([l,136,r,632],'#101e2a')
    box([l+2,138,r-2,630],'#3a5064')
    box([l+3,140,r-4,628],'#5d778f')
    box([l+6,143,r-6,626],'#324b5f')
    # Raised lip and three-pixel inner occlusion remain outside game cells.
    inner=r-3 if l<500 else l
    box([inner,144,inner+3,624],'#050d15')
    for yy in [156,300,460,612]:
        poly([(l+2,yy-9),(r-3,yy-9),(r-3,yy+8),(l+8,yy+8),(l+2,yy+2)],'#192c3c')
        line([(l+3,yy-8),(r-4,yy-8)],'#7890a1')
        line([(l+8,yy+7),(r-4,yy+7)],'#0a1622')
        fastener((l+r)//2,yy-1)
# The matching top/bottom lips close the frame at the same material depth.
for y0 in [132,624]:
    box([328,y0,952,y0+8],'#101e2a')
    box([332,y0+1,948,y0+3],'#5d778f')
    box([336,y0+3,944,y0+6],'#3a5064')
for xx in [336,936]:
    for yy in [138,624]:
        poly([(xx,yy),(xx+9,yy),(xx+9,yy+7),(xx+3,yy+7),(xx,yy+4)],'#22323f')
        box([xx+2,yy+2,xx+8,yy+4],'#35e0f5')
# Two recessed windows and HOLD share the same double bevel.
for r in [[160,184,288,312],[976,184,1104,312],[160,360,288,488]]:
    recess(r,8)
    for xx in [r[0]+3,r[2]-4]:
        for yy in [r[1]+3,r[3]-4]:fastener(xx,yy)
for r in [[168,192,280,304],[984,192,1096,304],[168,368,280,480]]:box(r,'#06121d')
# Same protruding header silhouette for both players: preview anchors differ by 816px.
# Keep the unmodified P2 header for solo's graphical hint console.
original_p2_header=skin.crop((959,148,1114,184))
original_p2_transition=skin.crop((959,184,984,216))
p1_header=skin.crop((143,148,298,184))
chip_source=skin.crop((978,155,1014,180))
# Keep the two interior ink components; reject the chip's dark outer outline.
black={(xx,yy) for yy in range(25) for xx in range(36)
       if max(chip_source.getpixel((xx,yy)))<105}
visited=set();components=[]
for seed in black:
    if seed in visited:continue
    todo=[seed];visited.add(seed);part=[]
    while todo:
        point=todo.pop();part.append(point)
        xx,yy=point
        for nxt in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
            if nxt in black and nxt not in visited:visited.add(nxt);todo.append(nxt)
    if len(part)>20 and not any(xx in (0,35) or yy in (0,24) for xx,yy in part):
        components.append(part)
components=sorted(components,key=len,reverse=True)[:2]
assert len(components)==2,'reference P2 letter components missing'
p2_glyph=Image.new('L',(36,25),0)
for part in components:
    for point in part:p2_glyph.putpixel(point,255)
p2_glyph=p2_glyph.crop(p2_glyph.getbbox())
# Recolour only P1's cyan chip, preserving its exact outline and metal surround.
for yy in range(155,180):
    for xx in range(154,187):
        rr,gg,bb=p1_header.getpixel((xx-143,yy-148))
        if gg>90 and gg>rr*1.5 and bb>rr*1.4:
            lum=max(gg,bb)/255
            p1_header.putpixel((xx-143,yy-148),(round(255*lum),round(64*lum),round(170*lum)))
# Clear the full old ink interior, including the original 1's lower serif.
ImageDraw.Draw(p1_header).rectangle((157-143,158-148,184-143,178-148),fill=(244,61,162))
if p2_glyph.width>26:p2_glyph=p2_glyph.resize((26,p2_glyph.height),Image.Resampling.NEAREST)
p1_header.paste((5,12,18),(154-143+(33-p2_glyph.width)//2,159-148),p2_glyph)
skin.paste(p1_header,(959,148))
# Continue the same P1 lower-left triangular shoulder down to the common
# preview-frame rail. The previous header copy stopped at y=184 too early.
p1_transition=skin.crop((143,184,168,216))
transition_mask=Image.new('L',(25,32),0)
ImageDraw.Draw(transition_mask).polygon([(0,0),(24,0),(24,31),(16,31),(0,14)],fill=255)
skin.paste(p1_transition,(959,184),transition_mask)


def header_rect(r):
    return [round(156+(r[0]-140)*908/1238),round(32+(r[1]-15)*96/127),
            round(156+(r[2]-140)*908/1238),round(32+(r[3]-15)*96/127)]
skin.paste(panel_art.crop((140,15,1378,142)).resize((908,96),Image.Resampling.NEAREST),(156,32))
box([1064,32,1110,132],'#30495a')
fields={
 'charge_value':header_rect([703,48,803,78]),'debris_value':header_rect([703,94,811,124]),
 'charge_track':header_rect([833,51,1287,78]),'debris_track':header_rect([833,98,1287,123]),
 'charge_percent':header_rect([1304,48,1356,79]),'debris_percent':header_rect([1304,96,1356,126]),
 'ship_number':header_rect([270,30,320,68]),'time_value':mr([811,843,961,887])}
fields['debris_value']=[569,92,660,114]
fields['charge_percent']=[1000,57,1048,80]
fields['debris_percent']=[1000,93,1048,116]
for k,r in fields.items():box(r,'#081925' if 'track' not in k else '#101f2b')
# Three conditions are small and dim and have no independent player label.
box([172,482,280,504],'#112634')
for i in range(3):box([212+i*10,490,217+i*10,495],'#344c5e')
# The material reference provides shell and typography; logic provides 8 segments.
core={'x':1130,'y':260,'w':54,'h':288,'glass_x':1157,'glass_w':26,'pitch':36}
# Fig.3 zone 6: remove the old nonuniformly stretched rectangular patch.
# Rebuild a single connected hull facet behind the original core and pipe.
box([1110,42,1280,656],'#050e18')
right_hull=[(1110,42),(1176,42),(1200,66),(1218,66),(1244,92),(1244,150),
            (1272,178),(1272,614),(1240,648),(1110,648)]
poly(right_hull,'#101e2a')
poly([(1112,46),(1174,46),(1198,70),(1216,70),(1240,94),(1240,152),
      (1268,180),(1268,612),(1238,644),(1112,644)],'#3a5064')
line([(1112,46),(1174,46),(1198,70),(1216,70),(1240,94),(1240,152),(1268,180)],'#5d778f',2)
line([(1268,182),(1268,612),(1238,644),(1112,644)],'#22323f',3)
line([(1128,100),(1165,100),(1180,115),(1180,192),(1206,218),(1264,218)],'#172a38',2)
line([(1128,102),(1164,102),(1178,116)],'#5d778f')
line([(1264,534),(1230,534),(1218,546),(1218,604),(1197,625)],'#172a38',2)
for xx in [1163,1170,1177,1184]:
    box([xx,126,xx+4,158],'#0a1622')
    box([xx+1,128,xx+2,156],'#172d3d')
for yy in [559,567,575,583]:
    box([1229,yy,1252,yy+5],'#0a1622')
    box([1230,yy+4,1252,yy+5],'#5d778f')
for xx,yy in [(1207,82),(1253,198),(1254,598),(1122,184),(1210,614)]:fastener(xx,yy)
# A recessed legend shares the tank mounting surface, not a floating pasted tile.
# The selected stacked legend keeps full labels and a 12px text safe area.
recess([972,364,1108,612],6)
box([978,370,1102,606],'#0e1c28')
# Lower mounting struts connect the original tank to the existing status plate.
for xx in [1138,1188]:
    box([xx,560,xx+5,622],'#142535')
    box([xx,564,xx+1,618],'#5d778f')
for yy in [584,592,600]:box([1150,yy,1180,yy+3],'#132635')
# Rigid axis-aligned energy mast. All coordinates derive from one axis.
# Fixed chamber and eight dynamic cells remain at the approved screen anchors.
axis=1170
mast_left,mast_right=axis-29,axis+29
chamber_left,chamber_right=axis-16,axis+16
rail_top,rail_bottom=258,548
rung_pitch=18
joint_rows=[260+72*i for i in range(5)]
def hex_bolt(x,y):
    poly([(x-2,y-3),(x+2,y-3),(x+3,y),(x+2,y+3),(x-2,y+3),(x-3,y)],'#07121a')
    line([(x-2,y-2),(x+2,y-2)],'#819caf')
    box([x-1,y-1,x+2,y+1],'#2a4355')
# Three rectangular metal courses: parallel rails and a square-cornered recess.
box([mast_left,246,mast_right,554],'#07121a')
box([mast_left+1,247,mast_right-1,553],'#294154')
box([mast_left+3,249,mast_right-3,551],'#607f94')
box([mast_left+5,251,mast_right-5,549],'#223a4c')
box([chamber_left-2,256,chamber_right+2,548],'#142735')
box([chamber_left,258,chamber_right,548],'#040c13')
# Shadow is an inner face; nothing floats to the left of the silhouette.
box([mast_left+1,251,mast_left+3,549],'#132836')
box([mast_left+3,251,mast_left+5,548],'#93adbf')
box([mast_right-5,251,mast_right-3,548],'#7693a8')
box([mast_right-3,251,mast_right-1,549],'#142836')
# Left ladder rungs are level and exactly 18px apart; right rail is a straight bar.
box([mast_left+5,rail_top,mast_left+8,rail_bottom],'#4b687d')
box([chamber_left-3,rail_top,chamber_left,rail_bottom],'#354f63')
for yy in range(rail_top+7,rail_bottom-3,rung_pitch):
    box([mast_left+5,yy,chamber_left,yy+4],'#152a39')
    box([mast_left+5,yy,chamber_left,yy+1],'#98b2c3')
    box([mast_left+5,yy+1,chamber_left,yy+3],'#516e83')
box([chamber_right,rail_top,mast_right-5,rail_bottom],'#3a556b')
box([chamber_right,rail_top,chamber_right+2,rail_bottom],'#90adbf')
box([mast_right-6,rail_top,mast_right-4,rail_bottom],'#172e3e')
for yy in joint_rows:
    hex_bolt(axis-21,yy)
    hex_bolt(axis+21,yy)
# The dome and every collar step share the chamber center axis.
poly([(axis-18,236),(axis-18,228),(axis-10,217),(axis+10,217),
      (axis+18,228),(axis+18,236)],'#07121a')
poly([(axis-16,233),(axis-16,229),(axis-9,219),(axis+9,219),
      (axis+16,229),(axis+16,233)],'#bd751b')
poly([(axis-13,228),(axis-8,221),(axis+8,221),(axis+13,228)],'#ffc23a')
line([(axis-7,221),(axis+7,221)],'#ffe4a0',2)
hex_bolt(axis,226)
# Square shoulders, horizontal top highlights, no detached bracket tab.
for r,ink in [
 ([axis-22,234,axis+22,242],'#07121a'),
 ([axis-20,235,axis+20,240],'#59798f'),
 ([axis-25,241,axis+25,248],'#07121a'),
 ([axis-23,242,axis+23,246],'#2b4559'),
 ([axis-29,247,axis+29,257],'#182e3e')]:box(r,ink)
line([(axis-20,235),(axis+19,235)],'#a3bbcc',2)
line([(axis-26,248),(axis+25,248)],'#7b99ae',2)
# Matched clamp blocks sit outside their respective rail, sharing one datum.
clamp_y,clamp_h=512,42
for x0,x1 in [(axis-36,axis-24),(axis+24,axis+36)]:
    poly(chamfer([x0,clamp_y,x1,clamp_y+clamp_h],2),'#07121a')
    box([x0+1,clamp_y+2,x1-1,clamp_y+clamp_h-2],'#b36b1a')
    box([x0+2,clamp_y+3,x1-2,clamp_y+clamp_h-4],'#f5a21f')
    box([x0+2,clamp_y+4,x0+4,clamp_y+clamp_h-5],'#ffe08a')
    box([x0,clamp_y,x1,clamp_y+6],'#284254')
    line([(x0+1,clamp_y+1),(x1-2,clamp_y+1)],'#9cb5c6',2)
    hex_bolt((x0+x1)//2,clamp_y+4)
# Level base plate: bolt pair mirrors around the same axis; amber is mechanical.
box([axis-27,548,axis+27,565],'#07121a')
box([axis-25,549,axis+25,564],'#3c586c')
line([(axis-24,549),(axis+23,549)],'#8da9bd',2)
box([axis-24,561,axis+24,564],'#213b4d')
poly(chamfer([axis-14,548,axis+14,561],3),'#a36c1c')
poly(chamfer([axis-12,549,axis+12,559],2),'#ffc23a')
line([(axis-9,550),(axis+8,550)],'#ffe7a1',2)
hex_bolt(axis-20,557)
hex_bolt(axis+20,557)
box([axis-6,564,axis+6,570],'#152c3c')
box([axis-4,565,axis+4,569],'#e69a25')
line([(axis-3,565),(axis+2,565)],'#ffe4a0')
# Phase glyphs/rings are now rendered in RTL, avoiding stretched source text.
# Legend geometry and labels are native RTL; its recess was drawn above.
box([1157,260,1183,548],'#081824')
# Status and SPD plaques use the same steel lip and deep number recess.
recess([1114,618,1210,660],7)
box([1120,624,1204,648],'#091722')
for xx in range(1129,1194,9):
    poly([(xx,651),(xx+4,651),(xx+1,655),(xx-3,655)],'#f5a21f')
# SPD has 2px corner cuts and enough vertical space for 12px minimum padding.
poly(chamfer([974,312,1110,354],2),'#081620')
poly(chamfer([975,313,1109,353],2),'#7893a8')
poly(chamfer([977,315,1107,351],2),'#223849')
poly(chamfer([979,317,1105,349],2),'#0a1622')
# Three small, dim condition sockets: shared HOLD has no second player label.
for xx in [211,221,231]:
    box([xx-1,489,xx+6,496],'#091722')
    line([(xx-1,495),(xx+5,495)],'#3a5064')
# Clean underlay is retained so endless modes can omit the complete assembly,
# including grooves, mounting tabs and both endpoint sockets.
pipe_free_skin=skin.copy()
# Interface finishing from the hardware reference: the housing owns the groove,
# while each tube end has a gasket, a collar and a bolted mounting flange.
# Preserve the P2/SPD outer face where it forms the left wall of the pipe recess.
shared_panel_edge=skin.crop((1102,148,1110,354))
# The upper turn is seated into an armour shoulder with matched two-step lips.
poly([(1081,48),(1105,48),(1138,79),(1138,104),(1130,104),
      (1128,88),(1118,73),(1104,61),(1081,59)],'#0a1a27')
poly([(1082,50),(1104,50),(1136,80),(1136,102),(1132,102),
      (1130,87),(1120,71),(1105,58),(1082,57)],'#3b566b')
line([(1083,50),(1103,50),(1136,81)],'#7995aa',2)
# A lower shoulder meets the mast mount without a detached diagonal fragment.
poly([(1103,292),(1108,292),(1110,308),(1119,323),(1134,333),
      (1153,333),(1153,345),(1130,345),(1112,333),(1103,317)],'#102332')
line([(1105,293),(1105,315),(1115,331),(1131,342),(1151,342)],'#607c92',2)
# Uniform 14px tube, radius-20 quarter elbows, and a continuous recessed channel.
# Build the centerline analytically; there are no resampled angled source joints.
pipe=[(1064.0,70.0),(1098.0,70.0)]
for n in range(1,81):
    theta=math.radians(-90+n*90/80)
    pipe.append((1098+20*math.cos(theta),90+20*math.sin(theta)))
pipe.append((1118.0,304.0))
for n in range(1,81):
    theta=math.radians(180-n*90/80)
    pipe.append((1138+20*math.cos(theta),304+20*math.sin(theta)))
pipe.append((1141.0,324.0))
channel_radius=15
pipe_layer=Image.new('RGBA',(1280,720));best={}
for a,b in zip(pipe,pipe[1:]):
    ax,ay=a;bx,by=b;dx,dy=bx-ax,by-ay;ln=math.hypot(dx,dy)
    if ln<.00001:continue
    nx,ny=-dy/ln,dx/ln
    for yy in range(max(0,math.floor(min(ay,by)-16)),min(720,math.ceil(max(ay,by)+17))):
        for xx in range(max(0,math.floor(min(ax,bx)-16)),min(1280,math.ceil(max(ax,bx)+17))):
            t=max(0,min(1,((xx+.5-ax)*dx+(yy+.5-ay)*dy)/(ln*ln)))
            qx,qy=ax+t*dx,ay+t*dy
            dist=math.hypot(xx+.5-qx,yy+.5-qy)
            if dist>channel_radius or dist>=best.get((xx,yy),99):continue
            across=(xx+.5-qx)*nx+(yy+.5-qy)*ny
            lighting=(nx*(-.707)+ny*(-.707))*across/7
            if dist>14:rgb=(8,23,34)
            elif dist>12:rgb=(105,131,151) if lighting>=0 else (45,68,87)
            elif dist>10:rgb=(27,47,63)
            elif dist>8:rgb=(13,30,43)
            elif dist>7:rgb=(5,15,24)
            elif dist>6:rgb=(81,45,14)
            elif lighting>.42:rgb=(255,222,138)
            elif lighting>.08:rgb=(255,180,61)
            elif lighting>-.32:rgb=(245,154,31)
            else:rgb=(162,87,21)
            # A single straight glass section; the brighter core is restricted
            # to its middle third and never uses clipped pure white.
            if abs(qx-1118)<.01 and 106<=qy<154 and dist<=7:
                if qy<109 or qy>=151:rgb=(99,127,146) if lighting>0 else (31,55,72)
                elif dist>5:rgb=(73,181,204) if lighting>0 else (19,92,119)
                elif abs(across)<1.5 and 122<=qy<138:rgb=(194,249,252)
                elif lighting>.12:rgb=(102,237,246)
                else:rgb=(27,181,208)
            pipe_layer.putpixel((xx,yy),rgb+(255,));best[(xx,yy)]=dist
skin.paste(pipe_layer,(0,0),pipe_layer)
# The adjacent panel's machined edge is the shared left groove wall.
# Keeping it intact prevents the channel from slicing through NEXT/SPD trim.
skin.paste(shared_panel_edge,(1102,148))
line([(1110,160),(1110,299)],'#607d93')
# Source-style header outlet flange: anchored into the header cap at CHARGE height.
poly([(1049,53),(1063,53),(1071,60),(1071,81),(1063,88),(1049,88)],'#081824')
poly([(1050,55),(1062,55),(1068,61),(1068,80),(1062,85),(1050,85)],'#3f5a70')
line([(1051,55),(1061,55),(1067,61)],'#8aa8bf',2)
line([(1051,84),(1061,84),(1067,79)],'#20394c',2)
# Recessed bore and a short, coaxial sleeve sit between flange and orange tube.
box([1063,60,1072,81],'#071620')
box([1066,61,1073,80],'#58768d')
box([1068,62,1070,78],'#a9bfce')
box([1072,63,1079,77],'#925416')
box([1072,64,1079,67],'#ffd185')
box([1072,67,1079,74],'#f5a21f')
box([1072,75,1079,77],'#713c13')
hex_bolt(1056,59)
hex_bolt(1056,82)
# The straight glass section has level collars rather than a bare colour seam.
for yy in [106,154]:
    box([1109,yy-3,1127,yy+3],'#081824')
    box([1110,yy-2,1126,yy+2],'#3b586e')
    box([1111,yy-2,1125,yy],'#91acbf')
    box([1111,yy,1125,yy+2],'#284358')
# Two small tabs fasten the recess to the hull; they meet the outer slot lip.
for yy in [190,270]:
    poly(chamfer([1129,yy-5,1139,yy+7],2),'#112634')
    line([(1130,yy-4),(1136,yy-4)],'#7d99ad',2)
    hex_bolt(1134,yy+1)
# Core entry: a fixed seat is part of the left mast rail, with paired bolts.
# The mouth, sleeve and bore all use y=324; no 45-degree protruding cap.
poly(chamfer([1140,310,1155,339],2),'#071620')
poly(chamfer([1142,312,1154,337],1),'#3e5c72')
line([(1143,312),(1152,312)],'#90aec2',2)
line([(1153,314),(1153,335)],'#1b3446')
hex_bolt(1149,315)
hex_bolt(1149,334)
box([1135,315,1143,333],'#06151f')
box([1136,316,1142,332],'#59788f')
box([1137,317,1139,331],'#a0bacd')
box([1142,319,1146,329],'#142b3b')
box([1132,318,1136,330],'#89501b')
box([1132,319,1136,322],'#ffd58b')
box([1132,322,1136,328],'#f5a21f')
pipe_diff=ImageChops.difference(skin,pipe_free_skin)
pipe_dr,pipe_dg,pipe_db=pipe_diff.split()
pipe_removal_mask=ImageChops.lighter(ImageChops.lighter(pipe_dr,pipe_dg),pipe_db).point(lambda v:255 if v else 0)
pipe_removal_mask.save(ASSET/'pipe_removal_mask.png')
# Fig.3 zones 2/7: instrument troughs and an independent beveled time plaque.
for key in ['charge_track','debris_track']:
    x,y,r,b=fields[key]
    box([x-3,y-3,r+3,b+3],'#0a1622')
    line([(x-3,b+2),(r+2,b+2),(r+2,y-3)],'#526d83')
    line([(x-2,y-2),(r+1,y-2)],'#132332',2)
for xx,yy in [(459,47),(1056,47),(459,119),(1056,119)]:fastener(xx,yy)

# Eight pixels of hull above the plaque separate it from the playfield bezel.
box([450,632,896,640],'#22323f')
poly(chamfer([466,640,880,689],14),'#0a1622')
poly(chamfer([468,641,878,688],13),'#5d778f')
poly(chamfer([471,644,875,686],11),'#22323f')
poly(chamfer([476,647,870,683],9),'#071521')

box(fields['time_value'],'#071521')
for xx in [480,865]:fastener(xx,660)
# Keep the material reference details; no blur, fog or global glow pass.
# Typography is runtime-rendered from one shared 5x7 alphabet.
for r in [[168,38,303,75],[475,52,566,82],[475,88,566,118]]:box(r,'#081925')
for r in [[196,153,270,179],[1012,153,1086,179],[196,334,270,355]]:box(r,'#112634')
box([157,158,184,179],'#26d7ec')
box([973,158,1000,179],'#f43da2')
skin.save(ASSET/'skin_material.png')
# Four companion material banks reuse the approved hardware, at real mode sizes.
base_skin=skin.copy()
def solo_shell():
    global skin
    skin=base_skin.copy()
    # Only the field envelope narrows; cells remain exactly 24x24.
    box([328,132,952,632],'#304958')
    for l,r in [(328,376),(904,952)]:
        box([l,140,r,624],'#344e62')
        line([(l+2,144),(l+2,620)],'#203647',2)
        for yy in [148,306,474]:
            line([(l+3,yy),(r-9,yy),(r-2,yy+7)],'#152635',2)
            line([(l+4,yy+2),(r-10,yy+2)],'#5d778f')
        for yy in [324,332,340]:
            box([l+14,yy,r-12,yy+4],'#102330')
            line([(l+15,yy+3),(r-13,yy+3)],'#6a879c')
    skin.paste(base_skin.crop((328,132,352,632)),(376,132))
    skin.paste(base_skin.crop((928,132,952,632)),(880,132))
    for y0 in [132,624]:
        box([376,y0,904,y0+8],'#101e2a')
        box([380,y0+1,900,y0+3],'#5d778f')
        box([384,y0+3,896,y0+6],'#3a5064')
    box([400,144,880,624],'#091722')
    # P2's functional preview becomes the solo-only hint console.
    skin.paste(original_p2_header,(959,148))
    skin.paste(original_p2_transition,(959,184))
    box([974,150,1106,181],'#102330')
    box([984,192,1096,304],'#06121d')
    return skin.copy()
def endless_shell(canvas):
    global skin
    skin=canvas.copy()
    # Restore the exact hull/panel underlay only under the pipe assembly.
    skin.paste(pipe_free_skin,(0,0),pipe_removal_mask)
    box([168,38,296,116],'#091925')
    box([471,52,1051,83],'#081925')
    box([471,88,1051,118],'#081925')
    for yy in [51,86,119]:line([(471,yy),(1050,yy)],'#344f63')
    # The reserve column is not a campaign phase indicator.

    return skin.copy()
solo_campaign=solo_shell()
solo_endless=endless_shell(solo_campaign)
duo_endless=endless_shell(base_skin)
# Menu and ship selection share one recessed terminal, keeping the hull exterior.
skin=base_skin.copy()
poly([(146,142),(156,32),(1088,32),(1156,44),(1192,76),(1218,104),
      (1258,148),(1276,178),(1276,610),(1242,634),(146,634)],'#30495a')
poly(chamfer([164,62,1248,624],12),'#081620')
poly(chamfer([166,64,1246,622],11),'#69869b')
poly(chamfer([170,68,1242,618],9),'#1a3041')
poly(chamfer([174,72,1238,614],7),'#07131f')
line([(194,144),(1215,144)],'#314e63',2)
for xx in [181,1230]:
    for yy in [82,604]:fastener(xx,yy)
# Integrated navigation rails and a reference-derived ship silhouette.
recess([206,172,686,456],8)
ship_source=panel_art.crop((249,35,524,140))
ship_source_mask=Image.new('L',ship_source.size,0)
# Explicit ship silhouette excludes SHIP 02 typography and surrounding chrome.
ImageDraw.Draw(ship_source_mask).polygon([(x-249,y-35) for x,y in [
 (250,91),(337,87),(341,74),(366,64),(402,64),(403,40),(421,40),(424,64),
 (458,77),(479,80),(483,91),(520,92),(520,116),(490,116),(486,123),
 (456,127),(438,138),(402,138),(380,136),(362,126),(341,119),(300,118),
 (280,110),(250,105)]],fill=255)
ship_tile=ship_source.resize((440,168),Image.Resampling.NEAREST)
ship_mask=ship_source_mask.resize((440,168),Image.Resampling.NEAREST)
skin.paste(ship_tile,(226,245),ship_mask)
for yy in [194,438]:
    line([(224,yy+9),(224,yy),(236,yy)],'#4caabd',2)
    line([(668,yy+9),(668,yy),(656,yy)],'#4caabd',2)
for row in range(4):
    yy=172+row*98
    recess([716,yy,1208,yy+80],6)
    for dx,dy in [(0,12),(12,12),(12,0)]:
        box([738+dx,yy+24+dy,748+dx,yy+34+dy],'#2c6e84')
line([(208,570),(1206,570)],'#314e63')
# The terminal has no running timer or campaign status plaque.
poly(chamfer([476,647,870,683],9),'#071521')
box([1110,618,1214,664],'#294354')
line([(1122,624),(1203,624)],'#4f6d83',2)
for yy in [643,650,657]:
    box([1142,yy,1183,yy+3],'#142b3a')
    line([(1143,yy+2),(1182,yy+2)],'#547489')
menu_skin=skin.copy()
skin=base_skin
skin_banks=[base_skin,solo_campaign,solo_endless,duo_endless,menu_skin]
for name,canvas in zip(['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal'],skin_banks):
    canvas.save(ASSET/(name+'_material.png'))
with (SRC/'reference_ui_skin.mem').open('w',encoding='ascii',newline='\n') as f:
    for canvas in skin_banks:
        f.writelines(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in canvas.getdata())

# Small material atlas: seven type faces, debris, dark/charged core glass.
atlas=[]
palette_text=(SRC/'story_palette.vh').read_bytes().decode('gbk')
palette={int(i):tuple(int(h[p:p+2],16) for p in (0,2,4))
         for i,h in re.findall(r"6'd(\d+):\s*story_palette=24'h([0-9A-Fa-f]{6})",palette_text)}
# Original block_index face, one-pixel bevel and clipped corners.
for kind in range(7):
    for py in range(22):
        for px in range(22):
            if px in (0,21) and py in (0,21):index=46
            elif px==0 or py==0:index=8+kind
            elif px==21 or py==21:index=30+kind
            else:index=1+kind
            atlas.append(palette[index])
# Original debris shader: gray-blue face with a thin X.
for py in range(22):
    for px in range(22):
        index=22 if px==0 or py==0 else 21 if px==py or px+py==21 else 23
        atlas.append(palette[index])
# Dark cells show only faint separators; lit cells have a clipped glass rim.
# These two 38x28 faces are selected by the existing eight-segment RTL state.
dark_cell=Image.new('RGB',(38,28),'#040c13')
ImageDraw.Draw(dark_cell).line([(3,27),(34,27)],fill='#17303e')
atlas.extend(list(dark_cell.getdata()))
lit_cell=Image.new('RGB',(38,28),'#040c13')
cell_mask=Image.new('L',(38,28),0)
ImageDraw.Draw(cell_mask).rounded_rectangle((1,1,36,26),radius=3,fill=255)
for yy in range(28):
    t=max(0,min(1,(yy-2)/23))
    rgb=tuple(round(a+(b-a)*t) for a,b in zip((111,245,255),(18,199,232)))
    for xx in range(38):
        if cell_mask.getpixel((xx,yy)):lit_cell.putpixel((xx,yy),rgb)
cell_draw=ImageDraw.Draw(lit_cell)
cell_draw.line([(5,2),(32,2)],fill='#d5ffff')
cell_draw.line([(3,5),(3,22)],fill='#b5fbff',width=2)
cell_draw.line([(6,25),(32,25)],fill='#087c9d')
atlas.extend(list(lit_cell.getdata()))
for region in [(836,53,854,77),(1040,54,1058,77),(836,98,854,121),(1110,98,1128,121)]:
    atlas.extend(list(panel_art.crop(region).resize((14,16),Image.Resampling.NEAREST).getdata()))
# A steel chain wraps the mast only when its existing LOCKED condition is true.
chain_offset=len(atlas)
chain=Image.new('RGBA',(88,264),(0,0,0,0))
def chain_link(cx,cy,angle,front):
    link=Image.new('RGBA',(19,13),(0,0,0,0));d=ImageDraw.Draw(link)
    d.rounded_rectangle((1,2,17,10),radius=4,outline='#06121c',width=5)
    d.rounded_rectangle((2,3,16,9),radius=3,outline='#536a7b' if front else '#314757',width=3)
    d.line([(5,3),(13,3),(15,5)],fill='#b7cfdf' if front else '#6b8599',width=1)
    d.line([(5,9),(13,9)],fill='#263b4c',width=1)
    link=link.rotate(angle,Image.Resampling.NEAREST,expand=True)
    chain.alpha_composite(link,(round(cx-link.width/2),round(cy-link.height/2)))
# One descending six-turn helix, sampled at uniform link-to-link distances.
# Rear links are occluded by the mast; front links cross both rails/chamber.
links=[];last=None;distance=0.0
for step in range(3601):
    t=step*12*math.pi/3600
    cx=44+36*math.cos(t);cy=13+40*t/(2*math.pi)+8*math.sin(t)
    if last is not None:distance+=math.hypot(cx-last[0],cy-last[1])
    if not links or distance>=8.0:
        tangent=math.degrees(math.atan2(40/(2*math.pi)+8*math.cos(t),-36*math.sin(t)))
        links.append((cx,cy,-tangent,math.sin(t)>=0))
        distance=0.0
    last=(cx,cy)
for front in [False,True]:
    for cx,cy,angle,is_front in links:
        if is_front!=front:continue
        if not front and 13<cx<75:continue
        chain_link(cx,cy,angle,front)
# Lock attached to the lowest front crossing, not an isolated middle belt.
d=ImageDraw.Draw(chain)
d.rounded_rectangle((37,230,50,243),radius=4,outline='#081722',width=4)
d.rounded_rectangle((39,230,48,241),radius=3,outline='#a8c3d6',width=2)
d.polygon([(36,238),(51,238),(53,240),(53,251),(34,251),(34,240)],fill='#081722')
d.rectangle((36,240,50,249),fill='#536d82')
d.line([(36,240),(50,240)],fill='#b2cbdc',width=2)
d.rectangle((42,243,44,246),fill='#e94a36')
chain.save(ASSET/'chain_sprite.png')
atlas.extend([(r,g,b) if a else (255,0,255) for r,g,b,a in chain.getdata()])

with (SRC/'reference_ui_material.mem').open('w',encoding='ascii',newline='\n') as f:
    f.writelines(f'{r:02x}{g:02x}{b:02x}\n' for r,g,b in atlas)

# Approved number shapes: extract the actual digits visible in the reference.
# Missing digits get a matching bold fallback, not a baked-in sample number.
def glyph_spans(region,threshold):
    tile=art.crop(region);mask=Image.new('L',tile.size);q=mask.load()
    for yy in range(tile.height):
        for xx in range(tile.width):
            rr,gg,bb=tile.getpixel((xx,yy));q[xx,yy]=255 if threshold(rr,gg,bb) else 0
    spans=[];start=None
    for xx in range(tile.width+1):
        on=xx<tile.width and mask.crop((xx,0,xx+1,tile.height)).getbbox() is not None
        if on and start is None:start=xx
        if not on and start is not None:
            g=mask.crop((start,0,xx,tile.height));spans.append(g.crop(g.getbbox()));start=None
    return spans
digits={}
spans=glyph_spans((800,836,975,890),lambda r,g,b:r>110 and g>130 and b>140)
if len(spans)==5:
    digits.update(dict(zip('02:18',spans)))
spans=glyph_spans((720,68,820,106),lambda r,g,b:g>125 and b>125)
if len(spans)==5:
    for ch,g in zip('15/35',spans):digits.setdefault(ch,g)
fallback=ImageFont.truetype('C:/Windows/Fonts/consolab.ttf',25)
digit_atlas=[]
for ch in '0123456789:/%':
    if ch in digits:g=digits[ch]
    else:
        g=Image.new('L',(32,36));ImageDraw.Draw(g).text((1,-2),ch,font=fallback,fill=255)
        g=g.crop(g.getbbox())
    target=Image.new('L',(12,20))
    # Normalized per-glyph ink box; advances and text heights are runtime properties.
    g=g.resize((10 if ch not in ':/' else 5,18),Image.Resampling.NEAREST)
    target.paste(g,((12-g.width)//2,1));digit_atlas.extend(target.getdata())
(SRC/'reference_ui_digits.mem').write_text(''.join(f'{v:02x}\n' for v in digit_atlas),encoding='ascii')

header=['// Generated material geometry; visual only.']
for key,r in fields.items():
    x,y,rr,bb=r
    for suffix,v in [('X',x),('Y',y),('W',rr-x),('H',bb-y)]:header.append(f'localparam integer REF_{key.upper()}_{suffix} = {v};')
header.append(f'localparam integer REF_MATERIAL_WORDS = {len(atlas)};')
for key,value in {'X':1126,'Y':274,'W':88,'H':264,'OFFSET':chain_offset}.items():
    header.append(f'localparam integer REF_CHAIN_{key} = {value};')
texts=json.loads((ROOT/'assets/story_ui.json').read_text('utf-8'))['texts']
header.extend(['function [255:0] ref_comms_line;','input [2:0] id; input second;','begin case ({id,second})'])
for idx in range(7):
    for row,text in enumerate(texts[f'COMMS{idx}']):
        header.append(f"4'd{idx*2+row}: ref_comms_line=256'h{text.encode('ascii').hex().ljust(64,'0')};")
header.extend(["default: ref_comms_line=0;",'endcase end endfunction'])
for key,val in core.items():header.append(f'localparam integer REF_CORE_{key.upper()} = {val};')
chars=json.loads((ROOT/'assets/story_ui.json').read_text(encoding='utf-8'))['characters']
header.extend(['function [5:0] ref_font_char;','input [7:0] ascii;','begin case(ascii)'])
for i,ch in enumerate(chars):header.append(f"8'd{ord(ch)}: ref_font_char=6'd{i};")
header.extend(["default: ref_font_char=0;","endcase end endfunction"])
(SRC/'reference_ui_geometry.vh').write_text('\n'.join(header)+'\n',encoding='ascii')
metadata={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'canvas':[1280,720],
 'kind':'material_only_not_rtl_preview','fields':fields,'core':core,'atlas_words':len(atlas),
 'core_logic_changed':False,'scope':'four play modes, main menu and solo/duo ship selection'}
metadata['player_tabs']={'p1_header':[143,148,298,184],'p2_header':[959,148,1114,184],
 'offset_x':816,'same_protruding_silhouette':True,
 'p1_lower_transition':[143,184,168,216],'p2_lower_transition':[959,184,984,216],'p2_ink_source':'approved reference chip'}
metadata['skin_banks']=['duo_campaign','solo_campaign','solo_endless','duo_endless','terminal']
metadata['component_sources']={'pipe_core_phase':{'file':core_source.name,'sha256':hashlib.sha256(core_source.read_bytes()).hexdigest()},
 'header_next_hold':{'file':panel_source.name,'sha256':hashlib.sha256(panel_source.read_bytes()).hexdigest()}}
metadata['pipe_path']=pipe
metadata['block_style']='original block_index and story_palette; one-pixel bevel, clipped corners'
metadata['debris_style']='original story_ui shader; gray-blue face with one-pixel X'
metadata['field_edge_repair']={'left':[298,132,352,632],'right':[928,132,970,632],
 'bezel_width':24,'facets':'three hard value steps; no global haze'}
metadata['finishing_brief']='art_review/fig3_fix_prompts.md zones 2,3,4,5,6,7; retain approved layout and original blocks/debris'
metadata['hint_panel']='solo only; falling-piece/projected-target diagram, reticle and arrow; campaign slots/time bar; endless infinity icon; no text'
metadata['endless_pipe']='absent; pipe, recessed channel, collars and endpoints restored to clean underlay'
metadata['phase_labels']='stacked circles above full labels, centered and 54px spaced; bottom-to-top RECONNECT REBUILD STABILIZE RECHARGE'
metadata['legend_panel']=[972,364,1108,612]
metadata['locked_chain']={'rect':[1126,274,1214,538],'turns':6,'path':'one continuous descending helix; rear links occluded by mast','atlas_offset':chain_offset,'condition':'campaign and debris_left > mode_half'}
metadata['typography']='one runtime 5x7 alphabet; same-group common bottom baseline'
metadata['comms']='existing seven dialogue IDs, native RTL, upper-left playfield overlay'
metadata['spd_plate']=[974,312,1110,354]
metadata['time_plaque']=[466,640,880,689]
metadata['core_mast_revision']={'envelope':[1124,214,1204,570],
 'layers':3,'axis_x':axis,'left_rail':'ladder','right_rail':'straight machined bar',
 'chamber':[chamber_left,258,chamber_right,548],'square_chamber':True,
 'rung_pitch':rung_pitch,'joint_rows':joint_rows,'clamp_datum_y':clamp_y,
 'crown':'orange-gold dome and stepped collar','amber_base_is_not_charge_cell':True,
 'runtime_cells':8,'scope':'energy mast only; original core glass coordinates retained'}
metadata['pipe_channel']={'sample_radius':channel_radius,'tube_radius':7,
 'source':'analytic centerline; reference hardware palette','elbow_radius':20,'diameter':14,
 'fluid_segment':[1118,106,1118,154],
 'interface_revision':{'header_flange':[1049,53,1079,88],
 'mast_seat':[1140,310,1155,339],'shared_panel_edge':[1102,148,1110,354],
 'glass_collars_y':[106,154],'hull_tab_y':[190,270]},'includes':['recess_floor','inner_shadow','steel_lip']}
(ASSET/'material_manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
print('MATERIALS_READY',len(atlas),'atlas words; five 1280x720 skin banks; renderer geometry emitted.')
