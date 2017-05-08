public with sharing class ApplicationHandler extends BaseTriggerHandler { 
	
	protected override void AfterInsert(){
		super.AfterInsert();
		UpdateNotHiredApplications();
        UpdateNumOfOpenApplications();
	}

	protected override void AfterUpdate(){
		super.AfterUpdate();
    	UpdateNotHiredApplications();
		UpdateNumOfOpenApplications();
	} 
    
    private void UpdateNumOfOpenApplications(){//updates number of open applications on the lead object
        Set<ID> leadIds = new Set<ID>();
        
        for(SObject sobj : trigger.new){
			leadIds.add(((Application__c)sobj).lead__c);
		}
        
        List<Lead> leads = [SELECT (SELECT ID FROM Applications__r WHERE Application_Status__c NOT IN ('Rejected','Hired')) FROM Lead WHERE id in: leadIds];
        for(Lead l : leads){
            integer cnt = 0;
            for(Application__c app : l.applications__r){
                cnt++;
            }           
            l.Number_of_Open_Applications__c = cnt;
        }
        update leads; 
    }
    
    private void UpdateNotHiredApplications(){//if one application is set as "hired", set all others for the same position as "rejected"
        Set<ID> positionIds = new Set<ID>();
        Set<ID> applicationIds = new Set<ID>();
        
        for(SObject sobj : trigger.new){
            if(((Application__c)sobj).application_status__c == 'Hired'){
                positionIds.add(((Application__c)sobj).position__c);
                applicationIds.add(((Application__c)sobj).Id);
            }
        }
        System.debug(positionIds);
        if(positionIds.size() > 0){
            List<Application__c> appsToUpdate = [SELECT id from Application__c where position__c in: positionIds and id not in: applicationIds];
            for(Application__c app : appsToUpdate){
                app.Application_Status__c = 'Rejected';
            }
            update appsToUpdate;
        }
    }
}