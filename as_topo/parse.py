#!/usr/bin/env python3
import sys

if len(sys.argv) < 2:
    print('Not enough arguments')
    sys.exit(0)

for filename in sys.argv[1:]:
    with open(filename,'r') as fp:
        for l in fp:
            l = l.strip()
            if l.startswith('D'):
                l_arr = l.replace(',','_').split('\t')
                for eachfrom in l_arr[1].split('_'):
                    for eachto in l_arr[2].split('_'):
                        print(eachfrom + ' ' + eachto)
                
