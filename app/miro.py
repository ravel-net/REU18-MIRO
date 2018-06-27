import cmd
from itertools import groupby
from ravel.app import AppConsole

class MiroConsole(AppConsole):
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
      print("Success: Added policy to table 'miro_policy'")
    except Exception, e:
      print "Failure: Unable to add policy.", e
      return
    return

#=============================================================================#
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
      use_demo_data()
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
          bgp_ins = "INSERT INTO BGP VALUES ('{0}','{1}','{2}','{3}','{4}')"
          bgp_ins = bgp_ins.format(prefix, ingress, ingress, aspath_str, 0)
          try:
            self.db.cursor.execute(bgp_ins)
          except Exception, e:
            print "Failure: Unable to add to bgp table.", e
    return

#=============================================================================#
  def do_route(self, line):
    """
    Calculate route
    Usage: route [prefix]
    """
    args = line.split(' ')
    if len(args) != 1:
      print('Not enough arguments')
      return
    prefix = args[0]

    # If prefix is blocked, then error

    hot_potato = "SELECT MIN(cost) from bgp {0};"
    route = """CREATE OR REPLACE VIEW route AS
        SELECT prefix, ingress, aspath
        FROM bgp
        WHERE cost = {0} {1};"""

    # Get list of policies
    policy_vw = "SELECT prefix, aspath FROM miro_policy"
    residue = ""
    residue_hotpotato = ""
    residue_route = ""
    try:
      self.db.cursor.execute(policy_vw)
      policies = self.db.cursor.fetchall()
    except Exception, e:
      print(e)
      return

    # Form residue
    needs_and = False
    for p in policies:
      if needs_and:
        residue = "{0} AND".format(residue)
      else:
        needs_and = True
      residue = "{0} NOT (prefix='{1}' AND {2}=ANY(aspath))".format(residue, p[0], p[1])

    # Add prefix and residue to query
    if residue != "":
      residue_hotpotato = "WHERE prefix='{0}' AND {1}".format(prefix, residue)
      residue_route = "AND prefix='{0}' AND {1}".format(prefix, residue)
    else:
      residue_hotpotato = "WHERE prefix='{0}'".format(prefix)
      residue_route = "AND prefix='{0}'".format(prefix)

    # Calculate the route
    try:
      print(hot_potato.format(residue_hotpotato))
      self.db.cursor.execute(hot_potato.format(residue_hotpotato))
      min_cost = self.db.cursor.fetchall()
      if min_cost != None and len(min_cost) != 0:
        min_cost = min_cost[0][0]
      else:
        min_cost = 0

      print(route.format(min_cost, residue_route))
      self.db.cursor.execute(route.format(min_cost, residue_route))
    except Exception, e:
      print(e)

#=============================================================================#
  def do_data(self, line):
    bgp_ins = "INSERT INTO BGP VALUES ('{0}','{1}','{2}','{3}','{4}')"

    #clear table
    try:
      self.db.cursor.execute('TRUNCATE bgp;')
    except Exception, e:
      print "Failure: Unable to clear bgp table.", e
    
    #error handling
    if line.split(' ') < 1 or line.split(' ')[0] == '':
      print('Insufficient arguments, using demo data.')
      self.use_demo_data()
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

  def use_demo_data(self):
    bgp_ins = """INSERT INTO bgp VALUES 
                ('1.0.4.0/24','55.55.55.55','11.11.11.11','{43110,293,209,4637,1221,38803,56203}',15),
                ('1.0.4.0/24','44.44.44.44','11.11.11.11','{43110,293,209,4637,1221,38803,56203}',8),
                ('1.0.4.0/24','33.33.33.33','11.11.11.11','{43110,293,209,4637,1221,38803,56203}',5),
                ('1.0.4.0/24','55.55.55.55','11.11.11.11','{43110,20912,174,4637,1221,38803,56203}',15),
                ('1.0.4.0/24','44.44.44.44','11.11.11.11','{43110,20912,174,4637,1221,38803,56203}',8),
                ('1.0.4.0/24','33.33.33.33','11.11.11.11','{43110,20912,174,4637,1221,38803,56203}',5),
                ('1.0.4.0/24','55.55.55.55','22.22.22.22','{43110,20912,174,4637,1221,38803,56203}',13),
                ('1.0.4.0/24','44.44.44.44','22.22.22.22','{43110,20912,174,4637,1221,38803,56203}',6),
                ('1.0.4.0/24','33.33.33.33','22.22.22.22','{43110,20912,174,4637,1221,38803,56203}',3);
                """
    try:
      self.db.cursor.execute(bgp_ins)
    except Exception, e:
      print "Failure: Unable to add to bgp table.", e
    return

shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
