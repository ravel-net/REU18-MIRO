-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(32), 
    ingress varchar(32),
    egress varchar(32), 
    aspath int [], 
    cost int);

-- Miro downstream view
CREATE OR REPLACE VIEW MIRO AS 
    SELECT prefix, aspath 
    FROM bgp
    GROUP BY prefix, aspath;

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy (prefix varchar(32), aspath int, UNIQUE(prefix, aspath));


-- ==}{== BACKEND ==}{== --

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

-- Refresh route
--CREATE OR REPLACE FUNCTION refresh_fun() RETURNS void AS $$
--hot_potato = "SELECT MIN(cost) from bgp {0};"
--route = """CREATE OR REPLACE VIEW route AS
--    SELECT prefix, ingress, aspath
--    FROM bgp
--    WHERE cost = {0} {1};"""
--
--# form residue
--policy_vw = "SELECT prefix, aspath FROM miro_policy"
--residue = ""
--residue_hotpotato = ""
--residue_route = ""
--policies = plpy.execute(policy_vw)
--needs_and = False
--for p in policies:
--  if needs_and:
--    residue = "{0} AND".format(residue)
--  else:
--    needs_and = True
--  residue = "{0} NOT (prefix='{1}' AND {2}=ANY(aspath))".format(residue, p['prefix'], p['aspath'])
--
--if residue != "":
--  residue_hotpotato = "WHERE {0}".format(residue)
--  residue_route = "AND {0}".format(residue)
--# end form residue
--
--# calculate route
--min_cost = plpy.execute(hot_potato.format(residue_hotpotato))
--if len(min_cost) > 0 and min_cost[0]['min'] != None:
--  min_cost = min_cost[0]['min']
--  plpy.execute(route.format(min_cost, residue_route))
--$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;


--CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$
--#plpy.execute("SELECT refresh_fun()")
--return None
--$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

--DROP TRIGGER IF EXISTS miro_repair ON miro_policy;
--CREATE TRIGGER miro_repair
--AFTER INSERT OR UPDATE OR DELETE ON miro_policy
--FOR EACH ROW
--EXECUTE PROCEDURE miro_repair_fun();
--SELECT refresh_fun();

-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg CASCADE;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW miro_violation AS (SELECT * from remove_error_msg);
