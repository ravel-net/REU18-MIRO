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
    if len(args) != 2:
      print("Invalid syntax")
      return
    # Is AS path numeric?
    if not args[1].isdigit():
      print("AS Path is not numeric")
      return
    
    # Convert pid(s) affected by policy's aspath
    policy_ins = "INSERT INTO miro_policy VALUES ('{0}', {1});"
    try:
      self.db.cursor.execute(policy_ins.format(args[0], args[1]))
    except Exception, e:
      print "Failure: Unable to add policy.", e
      return
    
    return

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
