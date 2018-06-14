import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
    def do_route(self, line):

        # all(prefix, egress, ASPath, ingress, cost) ->
        # SELECT * FROM
        #   (SELECT d, igp.re, p, rn, c
        #   FROM abgp INNER JOIN igp ON abgp.re = igp.re) AS alt
        # ORDER BY c ASC;
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

    def do_downstream(self, line):
        try:
            self.db.cursor.execute("""SELECT d, p FROM
                     (SELECT d, igp.re, p, rn, c
                     FROM abgp INNER JOIN igp ON abgp.re=igp.re) AS alt
                     GROUP BY d, p;""")
            downstream_cursor = self.db.cursor.fetchall()
            print(downstream_cursor)
        except Exception, e:
            print "Failure: Downstream MIRO-capable AS", e
            return



shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
