-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), ingress varchar(16), egress varchar(16), aspath varchar(16), cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy(prefix varchar(16), aspath varchar(16));


-- ==}{== VIEWS ==}{== --

-- Refresh route
CREATE OR REPLACE FUNCTION route_refresh_fun(residue text) RETURNS void AS $$
hot_potato = "SELECT MIN(cost) from bgp {0};"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, aspath 
    FROM bgp
    WHERE cost = {0} {1};"""

# form residue
residue = ""
policy_view = "SELECT prefix, aspath FROM miro_policy;"
policy_view = plpy.execute(policy_view)
for p in policy_view:
  residue = "{0} NOT (prefix='{1}' AND aspath='{2}')".format(residue, p['prefix'], p['aspath'])

# attach residue
if residue == '':
  min_cost = plpy.execute(hot_potato.format(residue))
  for min_row in min_cost:
    m = min_row['min']
    plpy.execute(route.format(m, residue))
else:
  min_cost = plpy.execute(hot_potato.format('WHERE ' + residue))
  for min_row in min_cost:
    m = min_row['min']
    plpy.execute(route.format(m, 'AND ' + residue))
  

$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

-- Refresh miro view
CREATE OR REPLACE FUNCTION miro_refresh_fun(residue text) RETURNS void AS $$
miro = "CREATE OR REPLACE VIEW MIRO AS SELECT prefix, aspath FROM bgp {0} GROUP BY prefix, aspath;"

# form residue
residue = ""
policy_view = "SELECT prefix, aspath FROM miro_policy;"
policy_view = plpy.execute(policy_view)
for p in policy_view:
  residue = "{0} NOT (prefix='{1}' AND aspath='{2}')".format(residue, p['prefix'], p['aspath'])

# attach residue
if residue == '':
  plpy.execute(miro.format(residue))
else:
  plpy.execute(miro.format('WHERE ' + residue))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$

# refresh route
policy_view = "SELECT prefix, aspath FROM miro_policy;"
refresh_route  = "SELECT route_refresh_fun({0});"
refresh_miro  = "SELECT miro_refresh_fun({0});"

# form residue
#policy_view = plpy.execute(policy_view)
#for p in policy_view:
#  residue = "{0} NOT (prefix='{1}' AND aspath='{2}')".format(residue, p['prefix'], p['aspath'])

residue = "''"
plpy.execute(refresh_route.format(residue))
plpy.execute(refresh_miro.format(residue))

return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS miro_repair ON miro_policy;
CREATE TRIGGER miro_repair
AFTER INSERT OR UPDATE OR DELETE ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

INSERT INTO bgp VALUES ('d','E','A','AS 1',15),('d','D','A','AS 1',8),('d','C','A','AS 1',5),
('d','E','A','AS 2',15),('d','D','A','AS 2',8),('d','C','A','AS 2',5),
('d','E','B','AS 2',13),('d','D','B','AS 2',6),('d','C','B','AS 2',3);


-- ==}{== POPULATE INITIAL VIEWS ==}{== --

SELECT route_refresh_fun('');
SELECT miro_refresh_fun('');


-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW miro_violation AS (SELECT * from remove_error_msg);
