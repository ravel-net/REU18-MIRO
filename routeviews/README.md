# Routeviews BGP data README

## Command to get data from Route views:
```bgpreader -i -d singlefile -o rib-file,http://archive.routeviews.org/bgpdata/2017.01/RIBS/rib.20170101.0000.bz2```

## To run sql file:
```psql -f bgptable.sql```
