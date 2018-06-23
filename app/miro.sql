-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), ingress varchar(16), egress varchar(16), aspath int [], cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy (prefix varchar(16), aspath int);


-- ==}{== VIEWS ==}{== --

-- Refresh route
CREATE OR REPLACE FUNCTION refresh_fun() RETURNS void AS $$
miro = """CREATE OR REPLACE VIEW MIRO AS 
    SELECT prefix, aspath 
    FROM bgp {0}
    GROUP BY prefix, aspath;"""
hot_potato = "SELECT MIN(cost) from bgp {0};"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, aspath
    FROM bgp
    WHERE cost = {0} {1};"""

# form residue
policy_vw = "SELECT prefix, aspath FROM miro_policy"
residue = ""
residue_miro = ""
residue_hotpotato = ""
residue_route = ""
policies = plpy.execute(policy_vw)
needs_and = False
for p in policies:
  if needs_and:
    residue = "{0} AND".format(residue)
  else:
    needs_and = True
  residue = "{0} NOT (prefix='{1}' AND {2}=ANY(aspath))".format(residue, p['prefix'], p['aspath'])

if residue != "":
  residue_miro = "WHERE {0}".format(residue)
  residue_hotpotato = "WHERE {0}".format(residue)
  residue_route = "AND {0}".format(residue)
# end form residue

#calculate miro view
plpy.execute(miro.format(residue_miro))

# calculate route
min_cost = plpy.execute(hot_potato.format(residue_hotpotato))
if len(min_cost) > 0 and min_cost[0]['min'] != None:
  min_cost = min_cost[0]['min']
  plpy.execute(route.format(min_cost, residue_route))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$
plpy.execute("SELECT refresh_fun()")
return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS miro_repair ON miro_policy;
CREATE TRIGGER miro_repair
AFTER INSERT OR UPDATE OR DELETE ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

--INSERT INTO bgp VALUES ('d','E','A','{1,3}',15),('d','D','A','{1,3}',8),('d','C','A','{1,3}',5),('d','E','A','{2,4}',15),('d','D','A','{2,4}',8),('d','C','A','{2,4}',5),('d','E','B','{2,4}',13),('d','D','B','{2,4}',6),('d','C','B','{2,4}',3);

-- ==}{== POPULATE INITIAL VIEWS ==}{== --

SELECT refresh_fun();


-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg CASCADE;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW miro_violation AS (SELECT * from remove_error_msg);
