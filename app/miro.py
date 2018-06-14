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
            self.db.cursor.execute("""CREATE VIEW bgproute AS
                SELECT d, rn, p FROM 
                (SELECT d, igp.re, p, rn, c 
                FROM abgp INNER JOIN igp
                ON abgp.re = igp.re)
                AS alt {0}
                ORDER BY c ASC
                LIMIT 1;""".format(policy))
            print("Success: Route in view 'bgproute'")
        except Exception, e:
            print "Failure: Unable to retrieve route", e
            return

    # MIRO(D,P) :- route(D,Rn,P)
    def do_downstream(self, line):
        try:
            self.db.cursor.execute("""CREATE VIEW downstream AS
                     SELECT d, p FROM abgp GROUP BY d, p;""")
            print("Success: Downstream ASes in view 'downstream'")
        except Exception, e:
            print "Failure: Unable to retrieve downstream ASes", e
            return



shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
