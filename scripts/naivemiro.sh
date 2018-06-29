# Run this script from bash:
# $ sudo ./ravel.py --topo=single,2 --script=./naivemiro.sh

# Run this script from ravel's CLI:
# exec ./naivemiro.sh

orch load naivemiro

# Load demo data
miro data

# Show miro downstream view
p SELECT * FROM miro;

# Show current route
miro route 1.0.4.0/24
p SELECT * FROM route;

# Add policy
miro addpolicy 1.0.4.0/24 174

# Show updated route
miro route 1.0.4.0/24
p SELECT * FROM route;
