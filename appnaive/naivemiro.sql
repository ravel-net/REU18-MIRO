-- ==}{== TABLES ==}{== --

-- aBGP table
DROP TABLE IF EXISTS abgp CASCADE;
CREATE UNLOGGED TABLE abgp (prefix varchar(16), egress varchar(16), aspath varchar(16));

-- IGP table
DROP TABLE IF EXISTS igp CASCADE;
CREATE UNLOGGED TABLE igp(ingress varchar(16), egress varchar(16), cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy(prefix varchar(16), aspath varchar(16));


-- ==}{== BACKEND ==}{== --

-- Miro repair mechanism
CREATE OR REPLACE FUNCTION miro_repair_fun() RETURNS TRIGGER AS $$

# NEW table
newaspath = str(TD["new"]["aspath"])
newprefix = str(TD["new"]["prefix"])

# commands
delete_abgp = """DELETE FROM abgp
  WHERE prefix='{0}' AND aspath='{1}';""".format(newprefix, newaspath)
drop_constraint = "ALTER TABLE abgp DROP CONSTRAINT IF EXISTS policy1;"
add_constraint = """
ALTER TABLE abgp ADD CONSTRAINT policy1
  CHECK(prefix != '{0}' AND aspath != '{1}');""".format(newprefix, newaspath)

# refresh route
curr_path = "SELECT * FROM route;"
hot_potato = "SELECT MIN(cost) from igp, abgp WHERE igp.egress=abgp.egress;"
route = """CREATE OR REPLACE VIEW route AS
    SELECT prefix, ingress, aspath 
    FROM abgp, igp
    WHERE abgp.egress=igp.egress AND igp.cost = {0};"""


# delete from abgp
plpy.execute(delete_abgp)

# if route is not affected by policy, then no need to update
aspath = plpy.execute(curr_path)
if len(aspath) != 0:
  return None

# else refresh route
min_cost = plpy.execute(hot_potato)
min_cost = min_cost[0]['min']
if min_cost is not None:
  plpy.execute(route.format(min_cost))

return None
$$ LANGUAGE 'plpythonu' VOLATILE SECURITY DEFINER;

DROP TRIGGER IF EXISTS naivemiro_repair ON miro_policy;
CREATE TRIGGER naivemiro_repair
AFTER INSERT ON miro_policy
FOR EACH ROW
EXECUTE PROCEDURE miro_repair_fun();


-- ==}{== TEST VALUES ==}{== --

INSERT INTO abgp VALUES ('d', 'A','AS 1'),('d', 'A','AS 2'),('d', 'B','AS 2');
INSERT INTO igp VALUES('E', 'A', 15),('E', 'B', 13),('D', 'A', 8),
('D', 'B', 6),('C', 'A', 5),('C', 'B', 3);


CREATE OR REPLACE VIEW naivemiro_violation AS (SELECT * FROM igp);
