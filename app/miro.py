import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
    def do_route(self, line):
        """
        Calculates interdomain route.
        Usage: route
        """

        policy = self.get_policy_sql()
        hot_potato_query = """SELECT MIN(cost) from igp;"""
        route_query = """CREATE OR REPLACE VIEW route AS
            SELECT prefix, ingress, aspath 
            FROM abgp, igp
            WHERE abgp.egress=igp.egress AND igp.cost = {0};"""
        try:
            self.db.cursor.execute(hot_potato_query)
            min_cost = self.db.cursor.fetchall()[0][0]

            self.db.cursor.execute(route_query.format(min_cost))
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
        miro_query = """CREATE OR REPLACE VIEW miro AS
                 SELECT prefix, aspath FROM abgp GROUP BY prefix, aspath;"""
        try:
            self.db.cursor.execute(miro_query)
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

    def do_delpolicy(self, line):
        """
        Delete policy. First arg is prefix and rest is path.
        Usage: delpolicy [prefix] [path]
        """
        # Enough arguments?
        args = line.split(' ')
        if len(args) < 2:
            print "Invalid syntax"
            return

        #try to delete policy
        sel_query = """SELECT * FROM miro_policy WHERE 
            prefix='{0}' AND aspath='{1}'""".format(args[0], ' '.join(args[1:]))

        del_query = """DELETE FROM miro_policy WHERE 
            prefix='{0}' AND aspath='{1}'""".format(args[0], ' '.join(args[1:]))
        try:
            self.db.cursor.execute(sel_query);
            if len(self.db.cursor.fetchall()) == 0:
                print("No policies matched.")
                return
            self.db.cursor.execute(del_query);
            print("Success: Deleted policy to table 'miro_policy'")
        except Exception, e:
            print "Failure: Unable to delete policy", e
            return

    def get_policy_sql(self):
        # Get cursor to policy table
        policies = None;
        sel_query = "SELECT * FROM miro_policy"
        try:
            self.db.cursor.execute(sel_query)
            policies = self.db.cursor.fetchall()
        except Exception, e:
            print "Failure: Unable to view policy", e
            return

        # No policies
        if len(policies) == 0:
            print("")
            return ""

        # Convert policy to SQL SELECT
        policy_sql = "WHERE"
        first = True
        for policy in policies:
            conjunction = " " if first else " AND "
            first = False if first==True else False
            policy_sql = "{0}{1}NOT (d='{2}' AND p LIKE'%{3}%')".format(policy_sql,
                    conjunction, policy[0], policy[1])
            return policy_sql


shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
