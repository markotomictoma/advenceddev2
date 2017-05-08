@IsTest public with sharing class TestApplicationTrigger {
    static testmethod void TestUpdateNumOfOpenApplications(){
		Position__c pos = TestDataGenerator.CreatePosition('Project Manager', 'Engineering', 100000, 'Open');
		insert pos;
		
		Lead recLead = TestDataGenerator.CreateLeads(1)[0];
		insert recLead;
		recLead = [select Number_of_Open_Applications__c from Lead where id =: recLead.Id];
		system.assertEquals(null, recLead.Number_of_Open_Applications__c);
		
		Application__c app = TestDataGenerator.CreateApplication(pos.Id, recLead.Id, 'Submitted');
		insert app;
		recLead = [select Number_of_Open_Applications__c from Lead where id =: recLead.Id];
		system.assertEquals(1, recLead.Number_of_Open_Applications__c);
	}
	
	static testmethod void TestUpdateNotHiredApplications(){
		Position__c pos = TestDataGenerator.CreatePosition('Project Manager', 'Engineering', 100000, 'Open');
		insert pos;
		
		List<Lead> leads = TestDataGenerator.CreateLeads(2);
		insert leads;
		
		List<Application__c> apps = new List<Application__c>();
		Application__c app1 = TestDataGenerator.CreateApplication(pos.Id, leads[0].Id, 'Submitted');
		apps.add(app1);
		Application__c app2 = TestDataGenerator.CreateApplication(pos.Id, leads[1].Id, 'Submitted');
		apps.adD(app2);
		insert apps;		
		app1.application_status__c = 'Hired';
		update app1;
		List<Application__c> appsAfterUpdate = [select application_status__c from Application__c where application_status__c = 'Submitted'];
		system.assertEquals(0, appsAfterUpdate.size());
		appsAfterUpdate = [select application_status__c from Application__c where application_status__c = 'Rejected'];
		system.assertEquals(1, appsAfterUpdate.size());
	}
}