#!/usr/bin/env python3
# tgtnorm.py A B : compare two corpus outputs on .aux/.lof/.lot/... after normalising link target names
# (<type>.N and <type>.struct.N -> TARGET) and dropping tagpdf mcid label records; prints jobs that still differ.
import sys,os,re,glob
A,B=sys.argv[1:3]
pat=re.compile(r'\{[A-Za-z@]+\.(struct\.)?[0-9]+(\.[0-9]+)*\}')
def norm(p):
    if not os.path.exists(p): return None
    L=[l for l in open(p,encoding='latin-1') if 'new@label@record{mcid-' not in l]
    return [pat.sub('{TARGET}',l) for l in L]
n=0;same=0
for d in sorted(glob.glob(os.path.join(A,'*/*/'))):
    j=os.path.relpath(d,A).rstrip('/'); job=j.split('/')[0]
    bad=[]
    for ext in ('aux','lof','lot','lop','loc','lol'):
        a=norm(os.path.join(A,j,job+'.'+ext)); b=norm(os.path.join(B,j,job+'.'+ext))
        if a!=b: bad.append(ext)
    if bad: print(j,'differs after target normalisation:',' '.join(bad)); n+=1
    else: same+=1
print('jobs identical after normalisation:',same,'still differing:',n)
