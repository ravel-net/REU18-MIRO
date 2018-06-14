orch load miro sample

sample echo "SHOW DOWNSTREAM ASes"
miro downstream
p SELECT * FROM downstream;

sample echo "SHOW VANILLA BGP ROUTE"
miro route
p SELECT * FROM bgproute;

sample echo "ADD POLICY, THEN RECALCULATE ROUTE"
miro addpolicy d AS 2
p SELECT * FROM miro_policy;
miro route
p SELECT * FROM bgproute;
miro delpolicy d AS 2
p SELECT * FROM miro_policy;

#sample echo "CASE WHERE MULTIPLE CHOICES IN ABGP"
#miro addpolicy d AS 1
#p SELECT * FROM miro_policy;
#miro route
#p SELECT * FROM bgproute;
#miro delpolicy d AS 1

miro help
