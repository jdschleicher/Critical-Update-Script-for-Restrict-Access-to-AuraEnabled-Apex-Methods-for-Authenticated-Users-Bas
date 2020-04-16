// search org for "@AuraEnabled"
// make note of all classes that belong to your app that compe up in the results
// create map of permission sets and confirm they don't already have access to the specific classes

// map of perm sets
// map of classes
// get all permission for classes, if read permissoin exist already remove, if not create permission

// to test:
// turn on critical update, login as user with targeted permission set and try to initiate call to AuraEnabled method.  Should receive error modal with red background colored header immediately.
// run script
// retest method call

List<String> apiNamesOfClassesToAddAccessTo = new List<String>{
        'Error_Logger',
        'SearchController'
};

List<String> permissionSetsNeedingAccess = new List<String>{
        'Tier_One_User',
        'Tier_Two_User'
};

Map<Id, PermissionSet> mapPermissionSets = new Map<Id, PermissionSet> (
    [
        Select Id, Name from PermissionSet where Name in:permissionSetsNeedingAccess
    ]
);

Map<Id, Apexclass> mapApexClasses = new Map<Id, Apexclass>(
   [
        SELECT Id, Name,
        (   
                SELECT 
                Id,
                SetupEntityId,
                Parent.Name,
                ParentId,
                Parent.Profile.Name
                FROM SetupEntityAccessItems
                WHERE Parent.Name IN: permissionSetsNeedingAccess
        )
        FROM ApexClass 
        where Name in:apiNamesOfClassesToAddAccessTo
   ]
);


List<SetupEntityAccess> setupEntityAccesses = new List<SetupEntityAccess>();

for (PermissionSet permSet : mapPermissionSets.values()) {
    for (ApexClass apxClass : mapApexClasses.values()) {

        Boolean permissionForClassExists = false;
        for (SetupEntityAccess access : apxClass.SetupEntityAccessItems) {

            if (access.ParentId == permSet.Id) {
                permissionForClassExists = true;
            }
        }

        // permissionForClassExists prevents already existing SetupEntityAccess relationship from being created and causing runtime error
        if (!permissionForClassExists) {
            SetupEntityAccess accessSetup = new SetupEntityAccess(
                    ParentId = permSet.Id,
                    SetupEntityId = apxClass.Id
            );

            setupEntityAccesses.add(accessSetup);
        }
        
    }
}

insert setupEntityAccesses;


///////////////////////////////////////////////

// for testing purposes //
/// TO DELETE ////
List<String> apiNamesOfClassesToAddAccessTo = new List<String>{
        'Error_Logger',
        'SearchController'
};

Map<Id, Apexclass> mapApexClasses = new Map<Id, Apexclass>(
    [
        Select Id, Name from Apexclass where Name in:apiNamesOfClassesToAddAccessTo
    ]
);

List<String> permissionSetsNeedingAccess = new List<String>{
        'Tier_One_User',
        'Tier_Two_User'
};
Map<Id, PermissionSet> mapPermissionSets = new Map<Id, PermissionSet> (
   [
        Select Id, Name from PermissionSet where Name in:permissionSetsNeedingAccess
   ]
);

List<SetupEntityAccess> setupEntityAccessesToDelete = [
  SELECT Id, Parent.Name, SetupEntityId
  FROM SetupEntityAccess
        WHERE ParentId IN :mapPermissionSets.keySet()
        AND SetupEntityId IN: mapApexClasses.keySet()
];

for (SetupEntityAccess access : setupEntityAccessesToDelete) {
    System.debug(LoggingLevel.ERROR, 'HERE BE access name: ' + access.Parent.Name);
    System.debug(LoggingLevel.ERROR, 'HERE BE the clas: ' + access.SetupEntityId);
}

delete setupEntityAccessesToDelete;
 

///// END DELETE ///



////////////////////////////////////////////////////////////////////////
