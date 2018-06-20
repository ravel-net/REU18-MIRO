-- ==}{== TABLES ==}{== --

-- BGP table
DROP TABLE IF EXISTS bgp CASCADE;
CREATE UNLOGGED TABLE bgp (prefix varchar(16), ingress varchar(16), egress varchar(16), aspath varchar(16), cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy(prefix varchar(16), aspath varchar(16));

-- ==}{== BACKEND ==}{== --

-- Refresh route
CREATE OR REPLACE FUNCTION route_refresh_fun() RETURNS void AS $$
hot_potato = "SELECT MIN(cost) from bgp;"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, aspath 
    FROM bgp
    WHERE igp.cost = {0};"""

#min_cost = plpy.execute(hot_potato)
#min_cost = min_cost[0]['min']
#if min_cost is not None:
#  plpy.execute(route.format(min_cost))
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;


-- Refresh miro view
CREATE OR REPLACE FUNCTION miro_refresh_fun() RETURNS void AS $$
CREATE OR REPLACE VIEW miro AS SELECT prefix, aspath FROM bgp GROUP BY prefix, aspath;
$$ LANGUAGE SQL;


-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$

plpy.execute('SELECT route_refresh_fun()')

return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS naivemiro_repair ON miro_policy;
CREATE TRIGGER naivemiro_repair
AFTER INSERT ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

INSERT INTO bgp VALUES
('d','E','A','AS 1',15),('d','D','A','AS 1',8),('d','C','A','AS 1',5)
('d','E','A','AS 2',15),('d','D','A','AS 2',8),('d','C','A','AS 2',5)
('d','E','B','AS 2',13),('d','D','B','AS 2',6),('d','C','B','AS 2',3);

SELECT route_refresh_fun();
SELECT miro_refresh_fun();

CREATE OR REPLACE VIEW naivemiro_violation AS (SELECT * FROM igp);
