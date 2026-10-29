"""Compile constant strings to a shared character ROM; keep dynamic bytes only.

Editable source: assets/new_ui/renderer_source.v.in. Formal renderer and text
ROM are generated together, with byte layouts recorded for verification.
"""
from pathlib import Path
import ast,json,re
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'Tetris.srcs/sources_1/new'

def split_top(text,delimiter=','):
    result=[];start=0;depth=0;quote=False
    for i,c in enumerate(text):
        if c=='"':quote=not quote
        if quote:continue
        if c in '({[':depth+=1
        elif c in ')}]':depth-=1
        elif c==delimiter and depth==0:result.append(text[start:i].strip());start=i+1
    result.append(text[start:].strip());return result

def unwrap(text):
    text=text.strip()
    while text.startswith('(') and text.endswith(')'):
        depth=0;closed=None;quote=False
        for i,c in enumerate(text):
            if c=='"':quote=not quote
            if quote:continue
            if c=='(':depth+=1
            elif c==')':
                depth-=1
                if depth==0:closed=i;break
        if closed!=len(text)-1:break
        text=text[1:-1].strip()
    return text

def ternary(text):
    depth=0;quote=False;question=None;pending=0
    for i,c in enumerate(text):
        if c=='"':quote=not quote
        if quote:continue
        if c in '({[':depth+=1
        elif c in ')}]':depth-=1
        elif depth==0:
            if c=='?':
                if question is None:question=i
                else:pending+=1
            elif c==':' and question is not None:
                if pending:pending-=1
                else:return text[:question],text[question+1:i],text[i+1:]
    return None

def main():
    text=(ROOT/'assets/new_ui/renderer_source.v.in').read_bytes().decode('gbk')
    templates=[];cache={};records=[]
    def add(words):
        words=tuple(words)
        if words not in cache:cache[words]=len(templates);templates.append(words)
        return cache[words]
    add([0]*32)
    geometry=(SRC/'reference_ui_geometry.vh').read_text('ascii')
    comms={int(i):bytes.fromhex(h) for i,h in re.findall(r"4'd(\d+): ref_comms_line=256'h([0-9a-f]+)",geometry)}
    comms_ids=[add(comms.get(i,bytes(32))) for i in range(16)]
    def compile_expression(expression):
        expression=unwrap(expression)
        branches=ternary(expression)
        if branches:
            cond,a,b=branches;ia,da=compile_expression(a);ib,db=compile_expression(b)
            return f'({cond}?{ia}:{ib})',f'({cond}?{da}:{db})'
        if expression=='ref_comms_line(comms_id,y>=230)':return 'ui_comms_template(comms_id,y>=230)',"256'd0"
        if expression=='0':return "7'd0","256'd0"
        assert expression.startswith('{') and expression.endswith('}'),expression
        words=[];data=[];width=0
        for part in split_top(expression[1:-1]):
            if part.startswith('"'):
                raw=ast.literal_eval(part).encode('ascii');words.extend(raw);bits=len(raw)*8;data.append(f"{bits}'d0");width+=bits
                continue
            literal=re.fullmatch(r"(\d+)'([dhb])([0-9a-fA-F_]+)",part)
            if literal:
                bits=int(literal[1]);value=int(literal[3].replace('_',''),{'d':10,'h':16,'b':2}[literal[2]])
                assert bits%8==0
                words.extend(value.to_bytes(bits//8,'big'));data.append(f"{bits}'d0");width+=bits
                continue
            bits=48 if part.startswith('bcd6(') else 32 if part.startswith('percent4(') else 16 if part.startswith('decimal2(') else 8
            words.extend([256]*(bits//8));data.append(part);width+=bits
        assert width==256,(width,expression)
        tid=add(words);records.append({'source':expression,'id':tid,'dynamic_positions':[i for i,v in enumerate(words) if v==256]})
        return f"7'd{tid}",'{'+','.join(data)+'}'
    def replace(match):
        tid,data=compile_expression(match[1]);return f'begin text_id={tid};message={data};end '
    text=re.sub(r'\bmessage\s*=\s*([^;]+);',replace,text)
    assert len(templates)<=128,len(templates)
    text=text.replace('reg text_valid,compact_text;reg [255:0] message;', 'reg text_valid,compact_text;reg [6:0] text_id;reg [255:0] message;')
    text=text.replace('ui_text_raster #(.REGISTER_DESCRIPTION(1)) shared_text(', 'ui_text_compact shared_text(')
    text=text.replace('.message(message),.dx(shared_dx)', '.message(message),.text_id(text_id),.dx(shared_dx)')
    text=text.replace(' `include "story_palette.vh"',' `include "story_palette.vh"\n `include "ui_text_templates.vh"')
    (SRC/'reference_ui_renderer.v').write_bytes(text.encode('gbk'))
    header=[f'localparam UI_TEXT_WORDS={len(templates)*32};','function [6:0] ui_comms_template;','input [2:0] id;input second;','begin case({id,second})']
    header += [f"4'd{i}:ui_comms_template=7'd{v};" for i,v in enumerate(comms_ids)]
    header += ["default:ui_comms_template=0;","endcase end endfunction"]
    (SRC/'ui_text_templates.vh').write_text('\n'.join(header)+'\n','ascii')
    (SRC/'ui_text_templates.mem').write_text(''.join(f'{v:03x}\n' for row in templates for v in row),'ascii')
    (ROOT/'assets/new_ui/text_templates.json').write_text(json.dumps({'templates':len(templates),'rows':templates,'expressions':records},ensure_ascii=False,indent=2)+'\n','utf-8')
    print('UI_TEXT_TEMPLATES_COMPILED',len(templates),'ROWS',len(templates)*32,'WORDS')
if __name__=='__main__':main()
