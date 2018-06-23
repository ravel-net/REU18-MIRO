import cmd
from itertools import groupby
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

  def do_data(self, line):
    i = 0
    bgp_ins = "INSERT INTO BGP VALUES ('{0}','{1}','{2}','{3}','{4}')"
    with open('apps/ribshort.txt') as fp:
      for l in fp:
        row_ls = l.split('|')
        if not l.startswith('#') and not l.isspace() and row_ls[0] is 'R' and row_ls[1] is 'R':
          prefix = row_ls[7]
          ingress = row_ls[8]
          egress = ingress
          aspath = [k for k, g in groupby([int(x) for x in row_ls[9].split(' ')])]
          aspath_str = str(aspath).replace('[', '{').replace(']','}')
          try:
            self.db.cursor.execute(bgp_ins.format(prefix, ingress, ingress, aspath_str, 0))
          except Exception, e:
            print "Failure: Unable to add to bgp table.", e
    return
    
    

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
