-- aBGP table
DROP TABLE IF EXISTS abgp CASCADE;
CREATE UNLOGGED TABLE abgp (prefix varchar(16), egress varchar(16), aspath varchar(16));

-- IGP table
DROP TABLE IF EXISTS igp CASCADE;
CREATE UNLOGGED TABLE igp(ingress varchar(16), egress varchar(16), cost int);

-- Miro policies
DROP TABLE IF EXISTS miro_policy CASCADE;
CREATE UNLOGGED TABLE miro_policy(prefix varchar(16), aspath varchar(16));


INSERT INTO abgp VALUES ('d', 'A','AS 1'),('d', 'A','AS 2'),('d', 'B','AS 2');
INSERT INTO igp VALUES('E', 'A', 15),('E', 'B', 13),('D', 'A', 8),
('D', 'B', 6),('C', 'A', 5),('C', 'B', 3);


CREATE OR REPLACE VIEW miro_violation AS (SELECT * FROM nodes);
