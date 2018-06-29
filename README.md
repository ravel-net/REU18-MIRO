# REU18-MIRO
## Notes

### Tables:
* **bgp** (prefix varchar(18), ingress int, egress int, aspath int [], cost int)
* **miro_policy** (prefix varchar(18), aspath int, UNIQUE(prefix, aspath))

\* Prefixes are varchar(18) because longest prefix possible is 255.255.255.255/36

### Views:
* **miro:** SELECT bgp.prefix, bgp.aspath FROM bgp GROUP BY bgp.prefix, bgp.aspath;

## Installation
1. Copy miro.py and miro.sql from app folder of this repo into app folder in Ravel.
2. Copy miro.sh into Ravel folder.
```
sudo ./ravel.py --topo=single,3 --onlydb --script=miro.sh
```
3. Repeat for naivemiro files

## Commands
* ```miro route [prefix]``` - queries route to prefix
* ```miro addpolicy [prefix] [ASN]``` - adds policy to avoid paths with ASN to prefix

## Demo
First, load in the demo data. Miro data with no arguments loads the demo data.
```
ravel> miro data
ravel> p SELECT * FROM bgp;
prefix      ingress      egress       aspath                                           cost
----------  -----------  -----------  ---------------------------------------------  ------
1.0.4.0/24  55.55.55.55  11.11.11.11  [43110, 293, 209, 4637, 1221, 38803, 56203]        15
1.0.4.0/24  44.44.44.44  11.11.11.11  [43110, 293, 209, 4637, 1221, 38803, 56203]         8
1.0.4.0/24  33.33.33.33  11.11.11.11  [43110, 293, 209, 4637, 1221, 38803, 56203]         5
1.0.4.0/24  55.55.55.55  11.11.11.11  [43110, 20912, 174, 4637, 1221, 38803, 56203]      15
1.0.4.0/24  44.44.44.44  11.11.11.11  [43110, 20912, 174, 4637, 1221, 38803, 56203]       8
1.0.4.0/24  33.33.33.33  11.11.11.11  [43110, 20912, 174, 4637, 1221, 38803, 56203]       5
1.0.4.0/24  55.55.55.55  22.22.22.22  [43110, 20912, 174, 4637, 1221, 38803, 56203]      13
1.0.4.0/24  44.44.44.44  22.22.22.22  [43110, 20912, 174, 4637, 1221, 38803, 56203]       6
1.0.4.0/24  33.33.33.33  22.22.22.22  [43110, 20912, 174, 4637, 1221, 38803, 56203]       3
```
Query the miro view to retrieve advertised ASes.
```
ravel> p SELECT * FROM miro;
prefix      aspath
----------  ---------------------------------------------
1.0.4.0/24  [43110, 293, 209, 4637, 1221, 38803, 56203]
1.0.4.0/24  [43110, 20912, 174, 4637, 1221, 38803, 56203]
```
Without any policies, we get the path with the least cost to the prefix 1.0.4.0/24:
```
ravel> miro route 1.0.4.0/24
ravel> p SELECT * FROM route;
prefix      ingress      aspath
----------  -----------  ---------------------------------------------
1.0.4.0/24  33.33.33.33  [43110, 20912, 174, 4637, 1221, 38803, 56203]
```
Add a policy to the miro_policy table using the ```miro addpolicy``` command.
```
ravel> miro addpolicy 1.0.4.0/24 174
Success: Added policy to table 'miro_policy'
```
Getting the route to 1.0.4.0/24 again retrieves the next best path that does not contain AS174.
```
ravel> p SELECT * FROM route;
prefix      ingress      aspath
----------  -----------  -------------------------------------------
1.0.4.0/24  33.33.33.33  [43110, 293, 209, 4637, 1221, 38803, 56203]
```
