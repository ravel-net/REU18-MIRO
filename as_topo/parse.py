#!/usr/bin/env python3
import sys

class WiserLinks:
    edges = set()

    # Read Wiser AS-links file
    def __init__(self, link_fp):
        with open(link_fp,'r') as fp:
            for l in fp:
                self.edges.add(l.strip())
        print('Found {0} Wiser edges'.format(len(self.edges)))
        return

    # Sort wiser
    def write_edges(self, outfp):
        with open(outfp,'w') as fp:
            for e in sorted(self.edges):
                fp.write(e)
                fp.write('\n')
        return

class MiroLinks:
    # Unique edges and nodes
    lines_seen = set()
    edges = set()
    nodes = set()
    
    def __init__(self, link_fps):
        # Parse each file
        for link_fp in link_fps:
            with open(link_fp,'r') as fp: 
                self.parse_lines(fp)
        print('Found {0} MIRO edges'.format(len(self.edges)))
        return

    def parse_lines(self, fp):
        for l in fp:
            l = l.strip()

            # Direct connections, non-null ASNs, unique lines
            if (l.startswith('D') or l.startswith('I')) and '(null)' not in l and l not in self.lines_seen:
                self.lines_seen.add(l)

                #Deal with MOAS
                l = l.replace('{','').replace('}','').replace(',','_')

                #Parse l
                l_arr = l.split('\t')
                for eachfrom in l_arr[1].split('_'):
                    for eachto in l_arr[2].split('_'):
                        
                        #Add to node set
                        if int(eachfrom) not in self.nodes:
                            self.nodes.add(int(eachfrom))
                        if int(eachto) not in self.nodes:
                            self.nodes.add(int(eachto))
                        
                        #Add to edge set
                        self.edges.add('{0},{1}'.format(eachfrom, eachto))
                        self.edges.add('{0},{1}'.format(eachto, eachfrom))
        return

    #Write edges to file
    def write_edges(self, outfp):
        with open(outfp,'w') as fp:
            for e in sorted(self.edges):
                fp.write(e)
                fp.write('\n')
        return

    #Write nodes to file
    def write_nodes(self, outfp):
        with open(outfp,'w') as fp:
            for n in sorted(self.nodes):
                fp.write(str(n))
                fp.write('\n')
        return
    
    # Write intersection of mirolinks and wiserlink to file
    def compare_links(self, wiserlinks, outfp, nodeoutfp):
        intersection = set()
        nodes = set()
        for e in wiserlinks.edges:
            if e in self.edges:
                intersection.add(e)
                e_arr = e.split(',')
                if int(e_arr[0]) not in nodes:
                    nodes.add(int(e_arr[0]))
                if int(e_arr[1]) not in nodes:
                    nodes.add(int(e_arr[1]))

        print('Found {0} shared edges'.format(len(intersection)))
        print('Found {0} shared nodes'.format(len(nodes)))

        with open(outfp,'w') as fp:
            for e in sorted(intersection):
                fp.write(e)
                fp.write('\n')
        with open(nodeoutfp,'w') as fp:
            for n in sorted(nodes):
                fp.write(str(n))
                fp.write('\n')

        return


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Not enough arguments')
        sys.exit(0)

    mirolinks = MiroLinks(sys.argv[1:])
    mirolinks.write_edges('miro_edges_030101.txt')
    wiserlinks = WiserLinks('wiser_edges_03.txt')
    mirolinks.compare_links(wiserlinks, 'miro_wiser_diff.txt','miro_wiser_diff_nodes.txt')
