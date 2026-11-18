import subprocess,sys
elf=sys.argv[1]
out=subprocess.run(["mips-linux-gnu-readelf","-S","-W",elf],capture_output=True,text=True).stdout
b=open(elf,"rb").read()
for line in out.splitlines():
    if ".fragment" in line and "PROGBITS" in line and "AX" in line:
        p=line.split("]",1)[1].split()
        name,addr,off=p[0],int(p[2],16),int(p[3],16)
        w=int.from_bytes(b[off:off+4],"big"); w2=int.from_bytes(b[off+0x20:off+0x24],"big")
        t=(addr&0xF0000000)|((w&0x3FFFFFF)<<2) if w>>26==2 else None
        print(name, hex(addr), hex(w), hex(t) if t else "-", b[off+8:off+16])
