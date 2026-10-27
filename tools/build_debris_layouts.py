"""Deterministic covered-cavity layouts with replayable, normal vertical-I witnesses."""
import random
from collections import deque


def cavities(board, width):
    full=(1<<width)-1
    empty={(y,x) for y,row in enumerate(board) for x in range(width) if not row>>x&1}
    outside={(0,x) for x in range(width) if (0,x) in empty}
    todo=list(outside)
    while todo:
        y,x=todo.pop()
        for p in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
            if p in empty and p not in outside:outside.add(p);todo.append(p)
    hidden=empty-outside;groups=0;depth=0
    while hidden:
        groups+=1;seed=hidden.pop();todo=[seed]
        while todo:
            y,x=todo.pop();d=0;r=y-1
            while r>=0 and board[r]>>x&1:d+=1;r-=1
            depth=max(depth,d)
            for p in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
                if p in hidden:hidden.remove(p);todo.append(p)
    return groups,depth


def witness(board,width):
    full=(1<<width)-1;board=list(board);debris=board.copy();columns=[];history=[];seen=set()
    for _ in range(180):
        if not any(debris):return columns,history
        key=tuple(board),tuple(debris)
        if key in seen:return None
        seen.add(key);top=next(y for y,row in enumerate(debris) if row)
        choices=[]
        for x in range(width):
            first=next((y for y,row in enumerate(board) if row>>x&1),20)
            bottom=first-1
            if bottom<3:continue
            b=board.copy();d=debris.copy()
            for y in range(bottom-3,bottom+1):b[y]|=1<<x
            clear=[y for y,row in enumerate(b) if row==full]
            removed=sum(d[y].bit_count() for y in clear)
            if clear:
                b=[0]*len(clear)+[row for y,row in enumerate(b) if y not in clear]
                d=[0]*len(clear)+[row for y,row in enumerate(d) if y not in clear]
            height=20-next((y for y,row in enumerate(b) if row),20)
            hits_target=not (board[top]>>x&1) and first>top
            choices.append(((removed,len(clear),hits_target,-height,first,-x),x,b,d,clear))
        if not choices:return None
        _,x,board,debris,clear=max(choices)
        columns.append(x);history.append({'cleared':len(clear),'remaining':sum(v.bit_count() for v in debris)})
    return None


def layouts(width,counts,level):
    goals=((0,0,1,1),(1,1,2,2),(1,2,2,3),(2,2,3,4))[level]
    max_depth=(1,1,2,3)[level];full=(1<<width)-1;used=set();bases=[];proofs=[]
    rng=random.Random(200000+width*101+level*10007)
    for variant,goal in enumerate(goals):
        for attempt in range(100000):
            board=[0]*20
            for k,n in enumerate(counts):
                gap=width-n
                # A broad opening plus displaced missing cells creates covered pockets.
                if goal==0:
                    center=int(width*(0.2+variant*0.19));start=max(0,min(width-gap,center-gap//2+rng.randrange(-1,2)))
                    holes=set(range(start,start+gap))
                else:
                    center=int(width*(0.18+variant*0.18));run=max(1,gap-rng.randrange(1,min(gap,5)))
                    start=max(0,min(width-run,center-run//2+rng.randrange(-2,3)))
                    holes=set(range(start,start+run));holes.update(rng.sample([x for x in range(width) if x not in holes],gap-run))
                board[19-k]=full^sum(1<<x for x in holes)
            mirror=[int(f'{row:0{width}b}'[::-1],2) for row in board]
            key=tuple(board);mkey=tuple(mirror)
            if key in used or mkey in used or key==mkey:continue
            group,depth=cavities(board,width)
            if group!=goal or depth>max_depth:continue
            result=witness(board,width)
            if result is None:continue
            threshold=(13 if width==20 else 16) if level==0 else (sum(counts)*2+4)//5
            if not any(0<h['remaining']<=threshold for h in result[1]):continue
            bases.append(tuple(reversed(board[20-len(counts):])));proofs.append({'columns':result[0],'history':result[1],'cavities':group,'depth':depth})
            used.update((key,mkey));break
        else:raise RuntimeError(f'No legal template width={width} level={level} variant={variant} goal={goal}')
    return bases+[tuple(int(f'{v:0{width}b}'[::-1],2) for v in rows) for rows in bases],proofs
