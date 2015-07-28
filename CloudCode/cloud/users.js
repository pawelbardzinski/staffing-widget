/* global Parse */

var _ = require ('underscore');

var Facility = Parse.Object.extend("Facility");

/***** CloudCode API endpoints *****/

Parse.Cloud.define("createUser", function(request, response) {
    var username = request.params.username;
    var password = request.params.password;
    var facilityId = request.params.facilityId;
	var roleName = request.params.roleName;
	var assignedUnits = request.params.assignedUnits;
    
    var facility = new Facility();
    facility.id = facilityId;
    
    authenticate(["editFacility"]).then(function() {
        var user = new Parse.User();
        user.set("username", username);
        user.set("password", password);
        user.set("facility", facility);
        
        return user.save();
    }).then(function(user) {
        return updateUserRole(user, roleName, assignedUnits);
    }).done(function(user) {
		response.success(user);
	}).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("deleteUser", function(request, response) {
    var username = request.params.username;
    
    authenticate(["editFacility"]).then(function() {
        var query = new Parse.Query(Parse.User);
        query.equalTo("username", username);
    
        return query.first();
    }).then(function(user) {
        if (!user)
            throw new Error("User not found: " + username);
        
        // Unset the user's role
        return updateUserRole(user, null, []);
    }).then(function(user) {
        return user.destroy({ useMasterKey: true });
    }).done(function(user) {
		response.success(user);
	}).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("updateUser", function(request, response) {
    var username = request.params.username;
    var password = request.params.password;
    
    authenticate(["editFacility"]).then(function() {
        var query = new Parse.Query(Parse.User);
        query.equalTo("username", username);
    
        return query.first();
    }).then(function(user) {
        if (!user)
            throw new Error("User not found: " + username);
        
        if (password)
            user.set("password", password);
        
        return user.save(null, { useMasterKey: true });
    }).done(function(user) {
		response.success(user);
	}).fail(function(error) {
        response.error(error);
    });
});

Parse.Cloud.define("updateUserRole", function(request, response) {
	var username = request.params.username;
	var role = request.params.role;
	var assignedUnits = request.params.assignedUnits;
    
    authenticate(["editFacility"]).then(function() {
        var query = new Parse.Query(Parse.User);
    	query.equalTo("username", username);
    
        return query.find();
    }).then(function(users) {
        if (users.length != 1)
            throw new Error("User not found!");
        
        return updateUserRole(users[0], role, assignedUnits);
    }).done(function(user) {
		response.success(user);
	}).fail(function(error) {
        response.error(error);
    });
});

/***** Functions *****/

function updateUserRole(user, roleName, assignedUnits) {
    var facility;
    var units;
    var role;
    
    return user.get("facility").fetch().then(function(facilityResponse) {
        facility = facilityResponse;
        
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
        
        return query.find();
    }).then(function(unitsResponse) {
        units = unitsResponse;
        
        // First remove user from all assigned units
        
        _.each(units, function(unit) {
            if (assignedUnits.indexOf(unit.id) == -1) {
                unit.getACL().setReadAccess(user, false);
                unit.getACL().setWriteAccess(user, false);
            } else {
                unit.getACL().setReadAccess(user, true);
            }
        });
        
        return Parse.Object.saveAll(units);
    }).then(function() {
        var query = new Parse.Query(Parse.Role);
        return query.equalTo("users", user).find();
    }).then(function(roles) {
        // Remove the user from all roles
        
        _.each(roles, function(role) {
            role.getUsers().remove(user);
        });
        
        return Parse.Object.saveAll(roles);
    }).then(function() {
        if (roleName) {
            var query = new Parse.Query(Parse.Role);
            query.equalTo("name", facility.id + " - " + roleName);
            query.include("info");
            
            return query.find().then(function(roles) {
                if (roles.length == 0)
                    throw new Error("Role not found: " + roleName);
                else if (roles.length != 1)
                    throw new Error("There can be only one instance of the specified role!");
                
                role = roles[0];
                
                // Add the user to the role
                role.getUsers().add(user);
                return role.save();
            })
        }
    }).then(function() {
        if (role) {
            user.set("roleInfo", role.get("info"));
        } else {
            user.unset("roleInfo");
        }
        return user.save(null, { useMasterKey: true });
    });
}
  
function setUpRoles(facility) {
    var roleACL = new Parse.ACL();
    roleACL.setRoleReadAccess("admin", true);
    roleACL.setRoleWriteAccess("admin", true);
    
    var facilityRole = new Parse.Role(facility.id, roleACL);
    facilityRole.set("facility", facility);
    
    var facilityACL = new Parse.ACL();
    facilityACL.setRoleReadAccess("admin", true);
    facilityACL.setRoleWriteAccess("admin", true);
    
    var rolesInfo = [];
    
    return facilityRole.save().then(function() {
        // Get a list of all role info objects
        facilityACL.setRoleReadAccess(facilityRole, true);
        
        var RoleInfo = Parse.Object.extend("RoleInfo");
        
        var query = new Parse.Query(RoleInfo);
        
        return query.find();
    }).then(function(list) {
        // Create a role for the facility based on each role info object
        rolesInfo = list;
        
        var roles = [];
        
        _.each(rolesInfo, function(roleInfo) {
            var role = new Parse.Role(facility.id + " - " + roleInfo.get("name"), roleACL);
            role.set("info", roleInfo);
            role.set("facility", facility);
            
            roles.push(role);
        });
        
        return Parse.Object.saveAll(roles);
    }).then(function(roles) {
        _.each(roles, function(role) {
            facilityRole.getRoles().add(role);
        });
        
        return facilityRole.save();
    }).then(function() {
        // Allow a user with edit facility perms to write to the facility object    
        _.each(rolesInfo, function(roleInfo) {
            if (roleInfo.get("editFacility") == true) {
                facilityACL.setRoleWriteAccess(facility.id + " - " + roleInfo.get("name"), true);
            }
        });
    
        // Retrieve all units
        var query = new Parse.Query("Unit");
        query.equalTo("facility", facility);
        
        return query.find();
    }).then(function(units) {
        // Allow a user with edit facility perms to read and write all units
        // Allow a user with view all units perms to read all units
        _.each(units, function(unit) {
            var unitACL = new Parse.ACL();
            
            unitACL.setRoleReadAccess("admin", true);
            unitACL.setRoleWriteAccess("admin", true);
                    
            _.each(rolesInfo, function(roleInfo) {
                if (roleInfo.get("editFacility") == true) {
                    unitACL.setRoleReadAccess(facility.id + " - " + roleInfo.get("name"), true);
                    unitACL.setRoleWriteAccess(facility.id + " - " + roleInfo.get("name"), true);
                } else if (roleInfo.get("viewAllUnits") == true) {
                    unitACL.setRoleReadAccess(facility.id + " - " + roleInfo.get("name"), true);
                }
            });
            
            unit.setACL(unitACL);
        });
        
        return Parse.Object.saveAll(units);
    }).then(function() {
        facility.setACL(facilityACL);
        return facility.save();
    });
}

function authenticate(permissions) {
    var user = Parse.User.current()
    
    return user.get("roleInfo").fetch().then(function(roleInfo) {
        var canAccess = true
        
        _.forEach(permissions, function(permission) {
            canAccess = canAccess && roleInfo.get(permission)
        });
        
        if (!canAccess) {
            throw new Error("User '" + user.get("username") + "' does not have the following permissions: " + 
                    permissions.join(", "))
        }
    });
}