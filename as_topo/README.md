# AS topology README

## Code
  * parse.py, generates miro\_wiser\_diff.txt, miro\_wiser\_diff\_nodes.txt, miro\_edges\_030101.txt, miro\_nodes\_030101.txt

## Files and sources:
AS-link files obtained from http://data.caida.org/datasets/topology/ipv4.allpref24-aslinks/. The data in this directory are from 01/01/2018
  * cycle-aslinks.l7.t1.c006274.20180101.txt --> miro\_6274\_180101.txt
  * cycle-aslinks.l7.t2.c006273.20180101.txt --> miro\_6273\_180101.txt
  * cycle-aslinks.l7.t3.c006272.20180101.txt --> miro\_6272\_180101.txt

Older AS-link data from http://data.caida.org/datasets/topology/skitter-aslinks/. The data in this directory are from 01/01/2003
  * skitter\_as\_links.20030101.gz --> skitter\_as\_links.20030101 (unzipped)

## AS links file format:
  * First part of file describes the networks probed
  * Second part of the file is the format description. In the parser, I only take direct links. If MOAS/AS set, I split into multiple rows
  * The rest of the file is the data


./asadj2graph.pl -d -smun -l . -g skitter\_combined
