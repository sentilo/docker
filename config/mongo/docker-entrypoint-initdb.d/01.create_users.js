print('Create admin user');
db.createUser(
{
    user: "admin",
    pwd: "sentilo",
    roles: [
		{ role: "userAdminAnyDatabase", db: "admin" },
		{ role: "readWriteAnyDatabase", db: "admin" },
		{ role: "clusterAdmin", 		db: "admin"	},
		{ role: "dbAdminAnyDatabase", 	db: "admin" }
	]
});

print('Create sentilo user');
db.createUser(
{
	user: "sentilo",
    pwd: "sentilo",
    roles: [
		{ role: "readWrite", 	db: "sentilo" }, 
		{ role: "dbAdmin", 		db: "sentilo" }
    ]
});