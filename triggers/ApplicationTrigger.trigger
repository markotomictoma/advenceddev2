trigger ApplicationTrigger on Application__c (after Insert, after update) {
	(new ApplicationHandler()).Handle();
}