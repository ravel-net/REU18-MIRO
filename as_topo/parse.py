#!/usr/bin/env python3
import sys

if len(sys.argv) < 2:
    print('Not enough arguments')
    sys.exit(0)

# For determining unique edges
lines_seen = set()
as_seen = set()

# Output file pointer
ofp = open('cycles_combined.txt','w')
ofp_as = open('cycles_combined_as.txt','w')
for filename in sys.argv[1:]:
    with open(filename,'r') as fp:
        for l in fp:
            l = l.strip()

            # Direct connections and unique lines
            if l.startswith('D') and l not in lines_seen:
                lines_seen.add(l)

                # Deal with Multi-Oriign ASes
                l_arr = l.replace(',','_').split('\t')
                for eachfrom in l_arr[1].split('_'):
                    for eachto in l_arr[2].split('_'):

                        # Write to file
                        ofp.write(eachfrom + ',' + eachto + '\n')
                        if int(eachfrom) not in as_seen:
                            as_seen.add(int(eachfrom))
                            ofp_as.write(eachfrom + '\n')
                        if int(eachto) not in as_seen:
                            as_seen.add(int(eachto))
                            ofp_as.write(eachto + '\n')

ofp.close()
ofp_as.close()

