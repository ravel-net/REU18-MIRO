DROP TABLE IF EXISTS abgp CASCADE;
CREATE UNLOGGED TABLE abgp (D varchar(16), Re varchar(16), P varchar(16));

INSERT INTO abgp VALUES ('d', 'A','AS 1');
INSERT INTO abgp VALUES ('d', 'A','AS 2');
INSERT INTO abgp VALUES ('d', 'B','AS 2');

DROP TABLE IF EXISTS igp CASCADE;
CREATE UNLOGGED TABLE igp(Rn varchar(16), Re varchar(16), C int);

INSERT INTO igp VALUES('E', 'A', 15);
INSERT INTO igp VALUES('E', 'B', 13);
INSERT INTO igp VALUES('D', 'A', 8);
INSERT INTO igp VALUES('D', 'B', 6);
INSERT INTO igp VALUES('C', 'A', 5);
INSERT INTO igp VALUES('C', 'B', 3);

SELECT d, rn, p FROM 
  (SELECT d, bgp.igp.re, p, rn, c 
    FROM bgp.abgp INNER JOIN bgp.igp
    ON bgp.abgp.re = bgp.igp.re)
    AS alt
    WHERE alt.c = (SELECT MIN(C) FROM bgp.igp);
