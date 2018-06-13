import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
     def do_getroute(self, line):
        min_c = None
        re = None
        d = None
        rn = None
        p = None


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

        print("DEBUG min: %d" % min_c)
        print("DEBUG re: %s" % re)
        print("route(D, Rn, P) = (%s, %s, %s)" % (d, rn, p))


shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
