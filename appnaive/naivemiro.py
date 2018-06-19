import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
    def do_route(self, line):
        """
        Calculates interdomain route.
        Usage: route
        """

        hot_potato_query = """SELECT MIN(cost) from igp;"""
        vw_query = """CREATE OR REPLACE VIEW route AS
            SELECT prefix, ingress, aspath 
            FROM abgp, igp
            WHERE abgp.egress=igp.egress AND igp.cost = {0};"""
        try:
            self.db.cursor.execute(hot_potato_query)
            min_cost = self.db.cursor.fetchall()[0][0]

            self.db.cursor.execute(vw_query.format(min_cost))
            print("Success: Route in view 'route'")
        except Exception, e:
            print "Failure: Unable to retrieve route", e
            return

    # MIRO(D,P) :- route(D,Rn,P)
    def do_view(self, line):
        """
        Gets downstream ASes.
        Usage: view
        """
        vw_query = """CREATE OR REPLACE VIEW miro AS
                 SELECT prefix, aspath FROM abgp GROUP BY prefix, aspath;"""
        try:
            self.db.cursor.execute(vw_query)
            print("Success: Downstream ASes in view 'miro'")
        except Exception, e:
            print "Failure: Unable to retrieve miro view", e
            return

    # :- MIRO(D, P)
    def do_addpolicy(self, line):
        """
        Add policy. First arg is prefix and rest is path.
        Usage: addpolicy [prefix] [path]
        """
        # Enough arguments?
        args = line.split(' ')
        if len(args) < 2:
            print "Invalid syntax"
            return

        # Insert into miro_policy
        ins_query = """INSERT INTO miro_policy
            VALUES ('{0}','{1}')""".format(args[0], ' '.join(args[1:]))
        try:
            self.db.cursor.execute(ins_query);
            print("Success: Added policy to table 'miro_policy'")
        except Exception, e:
            print "Failure: Unable to add policy", e
            return

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole