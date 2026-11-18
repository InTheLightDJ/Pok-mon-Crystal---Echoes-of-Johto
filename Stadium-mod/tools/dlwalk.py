import struct, sys
d = open(sys.argv[1], 'rb').read()
start = int(sys.argv[2], 16) & 0xFFFFFF
seg = [0]*16
names = {0x01:'VTX',0x02:'MODIFYVTX',0x03:'CULLDL',0x04:'BRANCH_Z',0x05:'TRI1',0x06:'TRI2',0x07:'QUAD',0xD6:'DMA_IO',0xD7:'TEXTURE',0xD8:'POPMTX',0xD9:'GEOMETRYMODE',0xDA:'MTX',0xDB:'MOVEWORD',0xDC:'MOVEMEM',0xDD:'LOAD_UCODE',0xDE:'DL',0xDF:'ENDDL',0xE0:'SPNOOP',0xE1:'RDPHALF_1',0xE2:'SETOTHERMODE_L',0xE3:'SETOTHERMODE_H',0xF1:'RDPHALF_2',0x00:'NOOP'}
def w(a): return struct.unpack('>II', d[a:a+8])
def res(x):
    return (seg[(x>>24)&0xF] + (x & 0xFFFFFF)) & 0xFFFFFF
stack=[]; pc=start; n=0; maxn=int(sys.argv[3]) if len(sys.argv)>3 else 100000
verbose = len(sys.argv)>4
while n<maxn:
    w0,w1 = w(pc); op=w0>>24; n+=1
    nm = names.get(op, 'RDP%02X'%op if op>=0xE4 else '??%02X'%op)
    if verbose or op in (0xDE,0xDF,0x04,0xDD,0xDB) or nm.startswith('??'):
        print('%06X depth%d %-12s %08X %08X'%(pc,len(stack),nm,w0,w1))
    if op==0xDB and ((w0>>16)&0xFF)==6:
        seg[((w0&0xFFFF)//4)&0xF]=w1&0xFFFFFF
    if op==0xDE:
        tgt=res(w1)
        if ((w0>>16)&0xFF)==0: stack.append(pc+8)
        pc=tgt; continue
    if op==0xDF:
        if not stack: print('END after',n); break
        pc=stack.pop(); continue
    if op==0x04 and ((w0>>1)&0x7FF)>=64: print('  !! bad vtx index', (w0>>1)&0x7FF)
    pc+=8
