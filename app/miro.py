import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
     def do_getroute(self, line):
        min_c = None
        re = None
        d = None
        rn = None
        p = None

        """
        # hotpotato(min<C>) :- IGP(Rn, Re, C)
        try:
           self.db.cursor.execute("SELECT MIN(C) FROM igp;")
           min_cursor = self.db.cursor.fetchall()
           if len(min_cursor) == 0:
             logger.warning("Failure: No minimum cost in IGP")
             return
           min_c = min_cursor[0][0]
        except Exception, e:
            print "Failure: TODO ERROR 1", e
            return

        # Fill out route(_, Rn, _) :- IGP(Rn, Re, C)
        # Save existential variable re
        try:
           self.db.cursor.execute("SELECT igp.rn, igp.re FROM igp WHERE igp.c=%d;" % min_c);

           igp_cursor = self.db.cursor.fetchall()
           if len(igp_cursor) == 0:
             logger.warning("Failure: IGP table query")
             return
           rn = igp_cursor[0][0]
           re = igp_cursor[0][1]
        except Exception, e:
            print "Failure: TODO ERROR 2", e
            return

        # fills out route(D, _, C) :- aBGP(D, Re, P)
        try:
           self.db.cursor.execute("SELECT abgp.d, abgp.p FROM abgp WHERE abgp.re='%s'" % re);
           bgp_cursor = self.db.cursor.fetchall()
           if len(bgp_cursor) == 0:
             logger.warning("Failure: IGP table query")
             return
           d = bgp_cursor[0][0]
           p = bgp_cursor[0][1]
        except Exception, e:
            print "Failure: TODO ERROR 3", e
            return
        """

        # All in one go
        # all(prefix, egress, ASPath, ingress, cost):
        # SELECT * FROM (SELECT d, igp.re, p, rn, c FROM abgp INNER JOIN igp ON abgp.re = igp.re) AS alt ORDER BY c ASC;
        policy = ""
        try:
           self.db.cursor.execute("""SELECT d, rn, p FROM 
                (SELECT d, igp.re, p, rn, c 
                FROM abgp INNER JOIN igp
                ON abgp.re = igp.re)
                AS alt {0}
                ORDER BY c ASC
                LIMIT 1;""".format(policy))
           bgp_cursor = self.db.cursor.fetchall()
           print(bgp_cursor)
        except Exception, e:
            print "Failure: TODO ERROR 4", e
            return


shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
