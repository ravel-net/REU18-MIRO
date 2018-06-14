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

DROP TYPE IF EXISTS route CASCADE;
CREATE TYPE route AS (D varchar(16), Rn varchar(16), P varchar(16));

DROP FUNCTION IF EXISTS vanilla_bgp_route() CASCADE;
CREATE OR REPLACE FUNCTION vanilla_bgp_route() RETURNS route AS $$

DECLARE
min_c INTEGER;
exist_re VARCHAR(16);
r route;

BEGIN
  -- hotpotato(min<C>) :- IGP(Rn, Re, C)
  SELECT INTO min_c MIN(C) from igp;
  -- Fill out route(_, Rn, _) :- IGP(Rn, Re, C)
  -- Save existential variable _re
  SELECT igp.rn, igp.re INTO r.rn, exist_re FROM igp WHERE igp.c = min_c;
  -- fills out route(D, _, C) :- aBGP(D, Re, P)
  SELECT abgp.d, abgp.p INTO r.d, r.p FROM abgp WHERE abgp.re = exist_re;
  RETURN r;
END;

$$LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

SELECT vanilla_bgp_route();
