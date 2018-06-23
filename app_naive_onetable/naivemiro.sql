-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), ingress varchar(16), egress varchar(16), aspath int[], cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy(prefix varchar(16), aspath int);


-- ==}{== VIEWS ==}{== --

-- Refresh route
CREATE OR REPLACE FUNCTION route_refresh_fun() RETURNS void AS $$
hot_potato = "SELECT MIN(cost) from bgp;"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, aspath 
    FROM bgp
    WHERE cost = {0};"""

min_cost = plpy.execute(hot_potato)
if len(min_cost) > 0 and min_cost[0]['min'] != None:
  min_cost = min_cost[0]['min']
  plpy.execute(route.format(min_cost))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

-- Refresh miro view
CREATE OR REPLACE FUNCTION miro_refresh_fun() RETURNS void AS $$
CREATE OR REPLACE VIEW miro AS SELECT prefix, aspath FROM bgp GROUP BY prefix, aspath;
$$ LANGUAGE SQL;


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$
newprefix = str(TD["new"]["prefix"])
newaspath = str(TD["new"]["aspath"])

delete_bgp = "DELETE FROM bgp WHERE prefix='{0}' AND {1}=ANY(aspath);"
plpy.execute(delete_bgp.format(newprefix, newaspath))
plpy.execute('SELECT route_refresh_fun()')

return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS naivemiro_repair ON miro_policy;
CREATE TRIGGER naivemiro_repair
AFTER INSERT ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

INSERT INTO bgp VALUES ('d','E','A','{1,3}',15),('d','D','A','{1,3}',8),('d','C','A','{1,3}',5),('d','E','A','{2,4}',15),('d','D','A','{2,4}',8),('d','C','A','{2,4}',5),('d','E','B','{2,4}',13),('d','D','B','{2,4}',6),('d','C','B','{2,4}',3);


-- ==}{== POPULATE INITIAL VIEWS ==}{== --

SELECT route_refresh_fun();
SELECT miro_refresh_fun();


-- ==}{== REMOVE ERROR MESSAGE ==}{== --

DROP TABLE IF EXISTS remove_error_msg;
CREATE UNLOGGED TABLE remove_error_msg(violation int);
CREATE OR REPLACE VIEW naivemiro_violation AS (SELECT * from remove_error_msg);
