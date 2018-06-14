import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
    def do_route(self, line):
        """
        Calculates interdomain route.
        Usage: route
        """

        # all(prefix, egress, ASPath, ingress, cost) ->
        # SELECT * FROM
        #   (SELECT d, igp.re, p, rn, c
        #   FROM abgp INNER JOIN igp ON abgp.re = igp.re) AS alt
        # ORDER BY c ASC;
        policy = self.get_policy_sql()
        try:
            query = """CREATE OR REPLACE VIEW bgproute AS
                SELECT d, rn, p FROM 
                (SELECT d, igp.re, p, rn, c 
                FROM abgp INNER JOIN igp
                ON abgp.re = igp.re)
                AS alt {0}
                ORDER BY c ASC
                LIMIT 1;""".format(policy)
            self.db.cursor.execute(query)
            print("Success: Route in view 'bgproute'")
        except Exception, e:
            print "Failure: Unable to retrieve route", e
            return

    # MIRO(D,P) :- route(D,Rn,P)
    def do_downstream(self, line):
        """
        Gets downstream ASes.
        Usage: downstream
        """
        try:
            query = """CREATE VIEW downstream AS
                     SELECT d, p FROM abgp GROUP BY d, p;"""
            self.db.cursor.execute(query)
            print("Success: Downstream ASes in view 'downstream'")
        except Exception, e:
            print "Failure: Unable to retrieve downstream ASes", e
            return

    # :- MIRO(D, P)
    def do_addpolicy(self, line):
        """
        Add policy to miro_policy. First arg is prefix and rest is path.
        Usage: addpolicy [prefix] [path]
        """
        # Enough arguments?
        args = line.split(' ')
        if len(args) < 2:
            print "Invalid syntax"
            return

        # Insert into miro_policy
        try:
            query = """INSERT INTO miro_policy
                VALUES ('{0}','{1}')""".format(args[0], ' '.join(args[1:]))
            self.db.cursor.execute(query);
            print("Success: Added policy to table 'miro_policy'")
        except Exception, e:
            print "Failure: Unable to add policy", e
            return

    def get_policy_sql(self):
        # Get cursor to policy table
        policies = None;
        try:
            self.db.cursor.execute("SELECT * FROM miro_policy;")
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
            policy_sql = "{0}{1}NOT (d='{2}' AND p='{3}')".format(policy_sql,
                    conjunction, policy[0], policy[1])
        return policy_sql
        

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
