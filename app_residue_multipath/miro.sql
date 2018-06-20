-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), ingress varchar(16), egress varchar(16), pid int, cost int);

-- Links pid to path, relation is multiple to multiple
DROP TABLE IF EXISTS aspath CASCADE;
CREATE UNLOGGED TABLE aspath (pid int, aspath int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy (prefix varchar(16), aspath int);


-- ==}{== VIEWS ==}{== --

-- Refresh route
CREATE OR REPLACE FUNCTION route_refresh_fun(residue text) RETURNS void AS $$
hot_potato = "SELECT MIN(cost) from bgp {0};"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, pid
    FROM bgp
    WHERE cost = {0} {1};"""

# form residue
policy_vw = """SELECT prefix, pid 
    FROM aspath, miro_policy 
    WHERE miro_policy.aspath=aspath.aspath GROUP BY pid, prefix;"""
residue = ""
residue_hotpotato = ""
residue_route = ""
policies = plpy.execute(policy_vw)
needs_and = False
for p in policies:
  if needs_and:
    residue = "{0} AND".format(residue)
  else:
    needs_and = True
  residue = "{0} NOT (prefix='{1}' AND pid={2})".format(residue, p['prefix'], p['pid'])

if residue != "":
  residue_hotpotato = "WHERE {0}".format(residue)
  residue_route = "AND {0}".format(residue)
# end form residue

# calculate route
min_cost = plpy.execute(hot_potato.format(residue_hotpotato))
if len(min_cost) > 0 and min_cost[0]['min'] != None:
  min_cost = min_cost[0]['min']
  plpy.execute(route.format(min_cost, residue_route))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

-- Refresh miro view
CREATE OR REPLACE FUNCTION miro_refresh_fun(residue text) RETURNS void AS $$
miro = """CREATE OR REPLACE VIEW MIRO AS 
    SELECT prefix, bgp.pid, aspath 
    FROM bgp, aspath 
    WHERE aspath.pid=bgp.pid {0}
    GROUP BY prefix, bgp.pid, aspath;"""

# form residue
policy_vw = """SELECT prefix, pid 
    FROM aspath, miro_policy 
    WHERE miro_policy.aspath=aspath.aspath GROUP BY pid, prefix;"""
residue = ""
residue_miro = ""
policies = plpy.execute(policy_vw)
needs_and = False
for p in policies:
  if needs_and:
    residue = "{0} AND".format(residue)
  else:
    needs_and = True
  residue = "{0} NOT (prefix='{1}' AND bgp.pid={2})".format(residue, p['prefix'], p['pid'])

if residue != "":
  residue_miro = "AND {0}".format(residue)
# end form residue

plpy.execute(miro.format(residue_miro))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$
plpy.execute("SELECT route_refresh_fun('')")
plpy.execute("SELECT miro_refresh_fun('')")
return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS miro_repair ON miro_policy;
CREATE TRIGGER miro_repair
AFTER INSERT OR UPDATE OR DELETE ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

INSERT INTO bgp VALUES ('d','E','A',1,15),('d','D','A',1,8),('d','C','A',1,5),
('d','E','A',2,15),('d','D','A',2,8),('d','C','A',2,5),
('d','E','B',2,13),('d','D','B',2,6),('d','C','B',2,3);
INSERT INTO aspath VALUES (1,1),(1,3),(2,2),(2,4);


-- ==}{== POPULATE INITIAL VIEWS ==}{== --

SELECT route_refresh_fun('');
SELECT miro_refresh_fun('');


-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW miro_violation AS (SELECT * from remove_error_msg);
