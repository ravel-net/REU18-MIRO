#!/usr/bin/env python3
from itertools import groupby
import re
import sys

class RibsParser:
    ribsfp = ''

    def __init__(self, ribsfp):
        self.ribsfp = ribsfp

    def parse(self, downstream=0, upstream=0, n=sys.maxsize, outfp='/dev/stdout'):
        i = 0
        ofp = open(outfp, 'w')
        with open(self.ribsfp,'r') as fp:
            for l in fp:
                feed = l.split('|')
                
                # Invalid cases
                if (l.startswith('#') or l.isspace() or
                        feed[0] is not 'R' or feed[1] is not 'R'):
                    continue
                if i >= n:
                    break
                else:
                    i += 1

                # PREFIX
                prefix = feed[7]

                # AS PATH
                # Remove all non-numerical, non-whitespace characters
                aspath = [int(x) for x in re.sub('[^\s0-9]','',feed[9]).split()]
                # Group aspaths
                aspath_str = str([k for k, g in groupby(aspath)])
                # PostgreSQL notation
                aspath_str = aspath_str.replace('[', '{').replace(']','}')

                ofp.write('{0}|{1}\n'.format(prefix, aspath_str))

        if ofp is not sys.stdout:
            ofp.close()


parser = RibsParser('ribshort.txt')
#parser.parse()
parser.parse(n=100,outfp='ribs100.txt')
parser.parse(n=1000,outfp='ribs1000.txt')
parser.parse(n=10000,outfp='ribs10000.txt')
