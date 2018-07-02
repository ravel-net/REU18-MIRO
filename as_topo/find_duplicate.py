#!/usr/bin/env python3
import sys

if len(sys.argv) != 2:
    print('Invalid number of arguments')

edges = set()
duplicates = set()
with open(sys.argv[1],'r') as fp:
    for l in fp:
        l = l.strip()
        l_arr = l.split(',')

        forwards = l
        backwards = l_arr[1] + ',' + l_arr[0]
        if forwards not in edges and backwards not in edges:
            edges.add(forwards)
        elif backwards in edges:
            duplicates.add(forwards)
        else:
            print('wtf')
    print(len(duplicates))
