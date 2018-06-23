import cmd
from ravel.app import AppConsole

class MiroConsole(AppConsole):
  def do_route(self, line):
    """
    Calculates interdomain route.
    Usage: route
    """
    # queries
    hot_potato_query = """SELECT MIN(cost) from igp, abgp
      WHERE igp.egress=abgp.egress{0};"""
    vw_query = """CREATE OR REPLACE VIEW route AS
      SELECT prefix, ingress, aspath 
      FROM abgp, igp
      WHERE abgp.egress=igp.egress AND igp.cost = {0}{1};"""
    residue = self.form_residue()

    # get route
    try:
      self.db.cursor.execute(hot_potato_query.format(residue))
      min_cost = self.db.cursor.fetchall()[0][0]
      self.db.cursor.execute(vw_query.format(min_cost, residue))
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
    # queries
    miro_query = """CREATE OR REPLACE VIEW miro AS
      SELECT prefix, aspath FROM abgp GROUP BY prefix, aspath;"""

    # get view
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

    # queries
    ins_query = """INSERT INTO miro_policy
      VALUES ('{0}','{1}')""".format(args[0], ' '.join(args[1:]))

    # add policy
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
    
    # delete policy
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

  def form_residue(self):
    policies_query = "SELECT * FROM miro_policy"
    residue = ""
    try:
      self.db.cursor.execute(policies_query);
      for p in self.db.cursor.fetchall():
        residue = "{0} AND NOT (prefix='{1}' AND aspath='{2}')".format(residue, p['prefix'], p['aspath'])
    except Exception, e:
      print "Failure: Unable to form residue", e

    return residue


shortcut = "miro"
description = "Interdomain routing policy"
console = MiroConsole
