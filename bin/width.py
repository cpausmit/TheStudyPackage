#!/usr/bin/env python
import sys,math

def avwidth(iType,g,med,mfm):
    front=g*g*(med*med+2*mfm*mfm)/(12*med*3.141159265)
    if abs(iType) == 2:
        front=g*g*(med*med-4*mfm*mfm)/(12*med*3.141159265)
    if 2.*mfm > med:
        return 0.001
    sqrtV=math.sqrt(1-4*(mfm/med)*(mfm/med))
    return front*sqrtV

def avtotwidth(iType,gdm,gsm,med,mdm):
    u=avwidth(iType,gsm,med,0.001)
    d=u
    s=avwidth(iType,gsm,med,0.135)
    c=avwidth(iType,gsm,med,1.5)
    b=avwidth(iType,gsm,med,5.1)
    t=0
    if med > 2.*172.5:
        t=avwidth(iType,gsm,med,172.5)
    quarks=3*(u+d+s+c+b+t)
    dm=avwidth(iType,gdm,med,mdm)
    #print u,d,s,c,b,t,dm,quarks                                                                                                                                                                    
    return dm+quarks

usage = '\n width.py  <type (1 - vector, 2 - axial-vector)>  <mediator_mass>  <darkmatter_mass>\n\n'
if len(sys.argv) != 4:
    print usage
    sys.exit(0)


print "Width: %f"%(avtotwidth(int(sys.argv[1]),1.,1.,float(sys.argv[2]),float(sys.argv[3])))
