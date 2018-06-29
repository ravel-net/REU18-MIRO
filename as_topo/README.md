# AS topology README

## Files and sources:
Cycle files obtained from http://data.caida.org/datasets/topology/ipv4.allpref24-aslinks/. The data in this directory is from 01/01/2018
  * cycle-aslinks.l7.t1.c006274.20180101.txt --> cycles\_6274.txt
  * cycle-aslinks.l7.t2.c006273.20180101.txt --> cycles\_6273.txt
  * cycle-aslinks.l7.t3.c006272.20180101.txt --> cycles\_6272.txt

## Cycle file format:
  * First part of file describes the networks probed
  * Second part of the file is the format description. In the parser, I only take direct links. If MOAS/AS set, I split into multiple rows
  * The rest of the file is the data
