-- Create or replace abgp table
DROP TABLE IF EXISTS abgp;
CREATE UNLOGGED TABLE abgp(prefix varchar(87), aspath int[]);

-- Load data from file
COPY abgp FROM '/mnt/c/Tony/Code/REU/REU18-MIRO/routeviews/ribs1000.txt' WITH DELIMITER '|';

-- Select role of AS 3
SELECT * FROM abgp WHERE abgp.aspath[1]=1221;
