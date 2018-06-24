import cmd
from itertools import groupby
from ravel.app import AppConsole

class MiroConsole(AppConsole):
  # :- MIRO(D, P)
  def do_addpolicy(self, line):
    """
    Add policy. First arg is prefix and rest is path.
    Usage: addpolicy [prefix] [ASN]
    """
    # Enough arguments?
    args = line.split(' ')
    if len(args) != 2:
      print("Invalid syntax")
      return
    # Is AS path numeric?
    if not args[1].isdigit():
      print("ASN is not numeric")
      return
    
    # Insert into policy.
    policy_ins = "INSERT INTO miro_policy VALUES ('{0}', {1});"
    try:
      self.db.cursor.execute(policy_ins.format(args[0], args[1]))
    except Exception, e:
      print "Failure: Unable to add policy.", e
      return
    
    return

"""
  def do_data(self, line):
    bgp_ins = "INSERT INTO BGP VALUES ('{0}','{1}','{2}','{3}','{4}')"

    #clear table
    try:
      self.db.cursor.execute('TRUNCATE bgp;')
    except Exception, e:
      print "Failure: Unable to clear bgp table.", e
    
    #error handling
    if line.split(' ') < 1 or line.split(' ')[0] == '':
      print('Insufficient arguments')
      return

    #parse rib file
    with open(line.split(' ')[0]) as fp:
      for l in fp:
        row_ls = l.split('|')
        if not l.startswith('#') and not l.isspace() and row_ls[0] is 'R' and row_ls[1] is 'R':
          prefix = row_ls[7]
          ingress = row_ls[8]
          egress = ingress
          aspath = [k for k, g in groupby([int(x) for x in row_ls[9].split(' ')])]
          aspath_str = str(aspath).replace('[', '{').replace(']','}')

          #Insert into bgp
          bgp_ins = bgp_ins.format(prefix, ingress, ingress, aspath_str, 0)
          print(bgp_ins)
          try:
            self.db.cursor.execute(bgp_ins)
          except Exception, e:
            print "Failure: Unable to add to bgp table.", e
    return
"""

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
