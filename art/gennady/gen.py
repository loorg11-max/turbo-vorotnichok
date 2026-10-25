import math
from PIL import Image, ImageDraw
from collections import Counter
P={'O':'#090c1c','H':'#4a2a1c','h':'#7a4a2a','S':'#e9cdb3','s':'#d8a07a','k':'#a67e66',
   'W':'#f7f4ea','w':'#c9ccd6','R':'#e8342a','r':'#c91410','N':'#28497e','n':'#22385c',
   'B':'#1a1623','b':'#2b2638','E':'#f7f4ea','M':'#561c26','G':'#d0ed4e','g':'#a2d576','q':'#7ec26b','L':'#e8c07a','l':'#b5793e','Y':'#fbe356','C':'#e98a8a'}
KEYS=list(P); IDX={k:i+1 for i,k in enumerate(KEYS)}
def hx(c): return tuple(int(c[i:i+2],16) for i in (1,3,5))
SC=6; W=H=64
class Fig:
    def __init__(s): s.img=Image.new('L',(W*SC,H*SC),0); s.d=ImageDraw.Draw(s.img)
    def tp(s,pts,org,ang):
        ca,sa=math.cos(ang),math.sin(ang); ox,oy=org
        K=0.8; return [((ox+(x*ca-y*sa)*K)*SC,(oy+(x*sa+y*ca)*K)*SC) for x,y in pts]
    def poly(s,pts,c,org,ang=0): s.d.polygon(s.tp(pts,org,ang),fill=IDX[c])
    def ell(s,cx,cy,rx,ry,c,org,ang=0,n=28):
        s.poly([(cx+rx*math.cos(t*2*math.pi/n),cy+ry*math.sin(t*2*math.pi/n)) for t in range(n)],c,org,ang)
    def limb(s,x0,y0,x1,y1,wd,c,org,ang=0):
        dx,dy=x1-x0,y1-y0; L=math.hypot(dx,dy) or 1; nx,ny=-dy/L*wd/2,dx/L*wd/2
        s.poly([(x0+nx,y0+ny),(x1+nx,y1+ny),(x1-nx,y1-ny),(x0-nx,y0-ny)],c,org,ang)
        s.ell(x0,y0,wd/2,wd/2,c,org,ang,12); s.ell(x1,y1,wd/2,wd/2,c,org,ang,12)
    def olimb(s,x0,y0,x1,y1,wd,c,org,ang=0):
        s.limb(x0,y0,x1,y1,wd+1.6,'O',org,ang); s.limb(x0,y0,x1,y1,wd,c,org,ang)
    def done(s):
        out=Image.new('L',(W,H),0); px=s.img.load(); o=out.load()
        for y in range(H):
            for x in range(W):
                cnt=Counter(px[x*SC+i,y*SC+j] for i in range(SC) for j in range(SC))
                v,n=cnt.most_common(1)[0]
                if v==0 and n<SC*SC*0.6:
                    v=[k for k,_ in cnt.most_common() if k][0]
                o[x,y]=v
        # outline
        o2=out.copy(); q=o2.load()
        for y in range(H):
            for x in range(W):
                if o[x,y]==0 and o[x,y]!=IDX['G']:
                    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                        X,Y=x+dx,y+dy
                        if 0<=X<W and 0<=Y<H and o[X,Y] and KEYS[o[X,Y]-1] not in 'Ggq': q[x,y]=IDX['O'];break
        return o2
def draw(fig,o,ang,arm_f,arm_b,leg_f,leg_b,tie,face='calm',gas=0,food=0,belly=0):
    # body coords: hip at origin, up is -y, facing +x
    A=ang
    def L(*a): fig.limb(*a,o,A)
    # back arm
    L(-1,-17,-1+6*math.sin(arm_b),-17+11*math.cos(arm_b),4,'w')
    L(-1+6*math.sin(arm_b),-17+11*math.cos(arm_b),-1+8*math.sin(arm_b),-17+14*math.cos(arm_b),4,'s')
    # back leg
    L(-2,1,-2+12*math.sin(leg_b),1+12*math.cos(leg_b),6,'n')
    fx,fy=-2+13*math.sin(leg_b),1+13*math.cos(leg_b)
    fig.ell(fx+2*math.cos(leg_b),fy-2*math.sin(leg_b)*0,3.5,2,'B',o,A)
    # torso (belly forward)
    fig.ell(1,-10,8,11,'W',o,A); fig.ell(4+belly,-6,7+belly,6+belly*0.5,'W',o,A); fig.ell(-4,-10,3.5,9,'w',o,A)
    fig.ell(1,-1,8.5,3.5,'N',o,A)   # waist
    # front leg
    fig.olimb(2,1,2+12*math.sin(leg_f),1+12*math.cos(leg_f),6,'N',o,A)
    fx,fy=2+13*math.sin(leg_f),1+13*math.cos(leg_f)
    fig.ell(fx+2,fy,3.5,2,'B',o,A)
    # tie
    if tie=='hang': fig.poly([(4,-19),(7,-19),(8,-9),(6,-6),(4,-9)],'R',o,A)
    else:
        w=tie
        fig.poly([(4,-20),(7,-19),(3,-15),(-6,-14+w),(-14,-10+w*2),(-16,-13+w*2),(-7,-17+w),(2,-19)],'R',o,A)
        fig.poly([(-7,-16+w),(-16,-12+w*2),(-14,-10+w*2),(-6,-14+w)],'r',o,A)
    fig.poly([(3,-21),(8,-20),(6,-17)],'W',o,A)  # collar
    # head
    fig.ell(3,-29,7.5,8,'S',o,A); fig.ell(-1,-28,3,5,'s',o,A)
    fig.ell(2,-34,7.6,4.5,'H',o,A); fig.poly([(-5,-33),(-8,-36),(-4,-36),(-6,-40),(-1,-38),(0,-42),(4,-38),(8,-40),(9,-34)],'H',o,A)
    fig.poly([(1,-37),(5,-38),(7,-36)],'h',o,A)
    fig.ell(-1,-28,1.5,2,'k',o,A)  # ear
    fig.ell(10.5,-27,1.8,1.6,'s',o,A) # nose
    # eye
    if face in ('blink','happy','chew'):
        fig.limb(5.5,-29.5,8.5,-29.5,0.9,'O',o,A)
    else:
        fig.ell(7,-30,2.2,2.6,'E',o,A); fig.ell(7.8,-30,0.9,1.3,'O',o,A)
    if face in ('shock','strain'): fig.ell(7,-23.5,2.4,2.6 if face=='shock' else 1.4,'M',o,A)
    elif face=='chew': fig.ell(6,-25,3.5,3,'S',o,A); fig.ell(6,-24.5,1.5,1.2,'C',o,A)
    elif face=='happy': fig.limb(4.5,-24.5,8.5,-23.5,1.1,'M',o,A)
    else: fig.limb(5,-24,8,-24.5,0.9,'M',o,A)
    if face=='strain': fig.ell(4,-26,2,1.2,'C',o,A)
    # front arm
    fig.olimb(3,-17,3+6*math.sin(arm_f),-17+10*math.cos(arm_f),4.2,'W',o,A)
    hx_,hy_=3+8*math.sin(arm_f),-17+13*math.cos(arm_f)
    fig.ell(hx_,hy_,3,3,'O',o,A); fig.ell(hx_,hy_,2.2,2.2,'S',o,A)
    if food:
        fig.ell(hx_+2,hy_-2,4.4,2.6,'O',o,A+0.0); fig.ell(hx_+2,hy_-2,3.6,1.8,'L',o,A)
        fig.ell(hx_+4.5,hy_-2.5,1.4,1.2,'l',o,A)
def gasblob(img,cx,cy,r):
    d=ImageDraw.Draw(img)
    for rr,c in ((r,'q'),(r-1,'g'),(max(r-2.5,0.6),'G')):
        d.ellipse([cx-rr,cy-rr,cx+rr,cy+rr],fill=IDX[c])
def render(fn,**k):
    f=Fig(); draw(f,**k); return f.done()
def star(img,cx,cy):
    p=img.load()
    for dx,dy in ((0,0),(1,0),(-1,0),(0,1),(0,-1)):
        if 0<=cx+dx<64 and 0<=cy+dy<64: p[cx+dx,cy+dy]=IDX['Y']
def F(**k):
    return render('',**k)
sin,cos,pi=math.sin,math.cos,math.pi
rows={}
std=dict(ang=0,arm_f=0.15,arm_b=-0.1,leg_f=0.05,leg_b=-0.05,tie='hang')
rows['idle']=[F(o=(30,46),**std),F(o=(30,46),**{**std,'arm_f':0.2,'belly':0.6}),F(o=(30,46),face='blink',**std)]
walk=[]
for i in range(6):
    t=i/6*2*pi
    walk.append(F(o=(30,46-abs(sin(t))*1.2+0.6),ang=0.04,arm_f=-0.4*sin(t),arm_b=0.4*sin(t),leg_f=0.45*sin(t),leg_b=-0.45*sin(t),tie='hang'))
rows['walk']=walk
rows['eat']=[F(o=(30,46),ang=0,arm_f=1.6,arm_b=-0.1,leg_f=0.05,leg_b=-0.05,tie='hang',food=1),
             F(o=(30,46),ang=0,arm_f=2.3,arm_b=-0.1,leg_f=0.05,leg_b=-0.05,tie='hang',food=1,face='shock'),
             F(o=(30,46),ang=0,arm_f=1.3,arm_b=-0.1,leg_f=0.05,leg_b=-0.05,tie='hang',food=1,face='chew',belly=0.5),
             F(o=(30,46),ang=0,arm_f=0.5,arm_b=-0.1,leg_f=0.05,leg_b=-0.05,tie='hang',face='happy',belly=1.2)]
rows['launch']=[F(o=(30,46),ang=0,arm_f=0.7,arm_b=0.3,leg_f=0.05,leg_b=-0.05,tie='hang',face='shock',belly=1.2),
                F(o=(30,49),ang=0.25,arm_f=0.9,arm_b=-0.5,leg_f=0.75,leg_b=-0.45,tie='hang',face='strain',belly=1.2),
                F(o=(32,44),ang=0.1,arm_f=2.9,arm_b=2.8,leg_f=0.0,leg_b=-0.1,tie=2,face='shock',belly=1),
                F(o=(34,40),ang=0.45,arm_f=2.2,arm_b=-2.4,leg_f=-0.4,leg_b=-0.9,tie=1,face='shock',belly=1)]
rows['fly']=[F(o=(36,38),ang=0.5,arm_f=af,arm_b=-2.3+lb,leg_f=-0.45-lb,leg_b=-0.95+lb,tie=w,face='shock')
             for w,af,lb in [(0,1.9,0.0),(2,1.95,0.15),(1,1.85,-0.1),(-1,1.9,0.1)]]
rows['fall']=[F(o=(30,44),ang=-0.15,arm_f=2.6+0.4*sin(i*2.1),arm_b=-2.6+0.4*cos(i*2.1),leg_f=0.5*sin(i*2.1+1),leg_b=-0.5*sin(i*2.1+1),tie=-2+i,face='shock') for i in range(3)]
land=[F(o=(30,56),ang=-0.1,arm_f=1.2,arm_b=-1.2,leg_f=1.45,leg_b=1.3,tie='hang',face='shock'),
      F(o=(30,56),ang=-0.05,arm_f=0.6,arm_b=-0.4,leg_f=1.4,leg_b=1.25,tie='hang',face='blink'),
      F(o=(30,56),ang=-0.05,arm_f=2.75,arm_b=-0.4,leg_f=1.4,leg_b=1.25,tie='hang',face='happy')]
for x,y in ((25,22),(33,18),(41,22)): star(land[1],x,y)
rows['land']=land
def rgba(im):
    out=Image.new('RGBA',im.size,(0,0,0,0)); p=im.load(); q=out.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            if p[x,y]: q[x,y]=hx(P[KEYS[p[x,y]-1]])+(255,)
    return out
# полоски как у GPT: розовый фон, каждый кадр ×8, промежутки — чтобы прогнать через hero_sheet.py
order=[('12_gennady_idle','idle'),('13_gennady_walk','walk'),('14_gennady_eat','eat'),('15_gennady_launch','launch'),('16_gennady_fly','fly'),('17_gennady_fall',('fall','land'))]
import os; os.makedirs('strips',exist_ok=True)
for fn,key in order:
    fr=[rgba(f) for f in (rows[key[0]]+rows[key[1]] if isinstance(key,tuple) else rows[key])]
    S=8; strip=Image.new('RGBA',(len(fr)*80*S,80*S),(255,0,255,255))
    for i,f in enumerate(fr):
        strip.alpha_composite(f.resize((64*S,64*S),Image.NEAREST),((i*80+8)*S,8*S))
    strip.convert('RGB').save(f'strips/{fn}.png')
print('ok')
