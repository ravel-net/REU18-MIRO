---- ==}{== TABLES/VIEWS ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), 
    ingress varchar(16),
    egress varchar(16),
    aspath int [],
    cost int);

-- Miro downstream view
CREATE OR REPLACE VIEW MIRO AS 
    SELECT prefix, aspath 
    FROM bgp
    GROUP BY prefix, aspath;

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy (prefix varchar(16), aspath int);


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$
newprefix = str(TD["new"]["prefix"])
newaspath = str(TD["new"]["aspath"])

delete_bgp = "DELETE FROM bgp WHERE prefix='{0}' AND {1}=ANY(aspath);"
plpy.execute(delete_bgp.format(newprefix, newaspath))

return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS naivemiro_repair ON miro_policy;
CREATE TRIGGER naivemiro_repair
AFTER INSERT ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

CREATE OR REPLACE FUNCTION load_data() RETURNS void AS $$
from itertools import groupby

bgp_ins = "INSERT INTO BGP VALUES ('{0}','{1}','{2}','{3}','{4}');"

plpy.execute("TRUNCATE TABLE bgp;")

with open('/home/ravel/ravel/apps/ribshort.txt') as fp:
  for l in fp:
    row_ls = l.split('|')
    if not l.startswith('#') and not l.isspace() and row_ls[0] is 'R' and row_ls[1] is 'R':
      prefix = row_ls[7]
      ingress = row_ls[8]
      egress = ingress
      aspath = [k for k, g in groupby([int(x) for x in row_ls[9].split(' ')])]
      aspath_str = str(aspath).replace('[', '{').replace(']','}')

      bgp_ins_f = bgp_ins.format(prefix, ingress, ingress, aspath_str, 0)
      
      plpy.execute(bgp_ins_f)
return

$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

-- ==}{== POPULATE INITIAL VIEWS ==}{== --

SELECT load_data();

---- Refresh route
--CREATE OR REPLACE FUNCTION route_refresh_fun() RETURNS void AS $$
--hot_potato = "SELECT MIN(cost) from bgp;"
--route = """CREATE OR REPLACE VIEW route AS
--    SELECT prefix, ingress, aspath 
--    FROM bgp
--    WHERE cost = {0};"""
--
--min_cost = plpy.execute(hot_potato)
--if len(min_cost) > 0 and min_cost[0]['min'] != None:
--  min_cost = min_cost[0]['min']
--  plpy.execute(route.format(min_cost))
--$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;
--
---- Refresh miro view
--CREATE OR REPLACE FUNCTION miro_refresh_fun() RETURNS void AS $$
--CREATE OR REPLACE VIEW miro AS SELECT prefix, aspath FROM bgp GROUP BY prefix, aspath;
--$$ LANGUAGE SQL;
--SELECT route_refresh_fun();
--SELECT miro_refresh_fun();


-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW naivemiro_violation AS (SELECT * from remove_error_msg);
