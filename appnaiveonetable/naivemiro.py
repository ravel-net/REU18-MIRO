import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
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
