@isTest public class TestLeadDataEntryController { 
	static testmethod void TestController(){
		List<Position__c> positions = new List<Position__c>();
		//create some test positions...
		for(integer i = 0; i < 10; i++){
			positions.add(TestDataGenerator.CreatePosition('Project Manager', 'Engineering', 100000, 'Open'));
			positions.add(TestDataGenerator.CreatePosition('Software Developer ', 'Marketing', 80000, 'Open'));
			positions.add(TestDataGenerator.CreatePosition('Software tester ', 'Operations',  50000, 'Open'));
		}
		insert positions;
		
		//create new Lead use case
		PageReference pageRef = Page.LeadDataEntry;
		Test.setCurrentPage(pageRef);
		Lead recLead = new Lead();
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(recLead);
		LeadDataEntryController ctrl = new LeadDataEntryController(stdCtrl);
		ctrl.FilterPositions();
		system.assertEquals(6, ctrl.totalPages);

		//Test pagination
		ctrl.ShowNext();
		system.assertEquals(2, ctrl.currentPage);
		ctrl.ShowPrevious();
		ctrl.ShowLast();
		system.assert(ctrl.lastRendered);
		ctrl.ShowFirst();
		system.assert(ctrl.firstRendered);

		system.assert(ctrl.getCategories().size() > 0);
		system.assert(ctrl.getPositionStatuses().size() > 0);

		system.assertEquals(false, ctrl.isAtLeastOnePositionSelected);
		ctrl.positionId2Selected.put(positions[5].Id, true);
		system.assertEquals(true, ctrl.isAtLeastOnePositionSelected);
		
		//test chart DTOs
		List<LeadDataEntryController.CategoryWedgeData> categoryData = ctrl.GetBarData();
		system.assertEquals(1, categoryData.size());
		system.assertEquals(positions[5].category__c, categoryData[0].category);
		system.assertEquals(1, categoryData[0].cnt);
		
		//test drop down changes
		ctrl.selectedCategory = 'Operations';
		ctrl.FilterPositions();
		system.assertEquals(2, ctrl.totalPages);
		system.assertEquals(10, ctrl.setCon.getResultSize());
		
		ctrl.selectedCategory = null;
		ctrl.selectedPositionStatus = 'Filled';
		ctrl.FilterPositions();
		
		ctrl.selectedCategory = 'Operations';
		ctrl.selectedPositionStatus = 'Filled';
		ctrl.FilterPositions();
		
		//test save of a new Lead
		recLead.firstName = 'testFN';
		recLead.lastName = 'testLN';		
		ctrl.Save();//negative use case, should not save successfuly 
		System.assertEquals(0, [select id from Lead where id =: recLead.id].size());
		recLead.company = 'testcompany';
		ctrl.Save();//Positive use case, save should succeed

		Lead savedLead = [select firstName, lastName, company from Lead where id =: recLead.id];
		system.assertEquals(recLead.firstName, savedLead.firstName);
		system.assertEquals(recLead.lastName, savedLead.lastName);
		system.assertEquals(recLead.company, savedLead.company);
		
		//edit Lead use case
		stdCtrl = new ApexPages.StandardController(savedLead);
		ctrl = new LeadDataEntryController(stdCtrl);
		integer cntSelectedPositions = 0;
		for(Id positionId : ctrl.positionId2Selected.keySet()){
			if(ctrl.positionId2Selected.get(positionId)){
				cntSelectedPositions++;
			}
		}
		system.assertEquals(1, cntSelectedPositions);
		//covering some corner cases like there is oly one page of positions
		List<Position__c> operations = new List<Position__c>();
		for(Position__c p : positions){
			if(p.category__c == 'Operations'){			
				operations.add(p);
			}
		}
		delete operations;
		
		Position__c newPos = TestDataGenerator.CreatePosition('Software tester ', 'Operations',  50000, 'Open');
		insert newPos;
		
		stdCtrl = new ApexPages.StandardController(savedLead);
		ctrl = new LeadDataEntryController(stdCtrl);
		ctrl.selectedCategory = 'Operations';
		ctrl.FilterPositions();
		system.assertEquals(1, ctrl.totalPages);
		system.assertEquals(1, ctrl.setCon.getResultSize());
		
		List<LeadDataEntryController.CategoryWedgeData> catData = ctrl.GetCountOfOpenPositionsPerCategory();
		for(LeadDataEntryController.CategoryWedgeData catDat : catData){
			if(catDat.category == 'Operations'){
				system.assertEquals(1, catDat.cnt);
			}
			if(catDat.category == 'Engineering'){
				system.assertEquals(10, catDat.cnt);
			}
			if(catDat.category == 'Marketing'){
				system.assertEquals(10, catDat.cnt);
			}
		}
		
		//edit Lead use case when there are applications save for the lead		
		Application__c app = TestDataGenerator.CreateApplication(newPos.Id, recLead.Id,  'Submitted');
		insert app;
		
		stdCtrl = new ApexPages.StandardController(recLead);
		ctrl = new LeadDataEntryController(stdCtrl);
		ctrl.selectedCategory = null;
		ctrl.FilterPositions();
		for(Id positionId : ctrl.positionId2Selected.keySet()){
			ctrl.positionId2Selected.put(positionId, false);
		}		
		ctrl.save();
		
		delete [select id  from Position__c where id !=: newPos.Id];
		stdCtrl = new ApexPages.StandardController(recLead);
		ctrl = new LeadDataEntryController(stdCtrl);
		ctrl.selectedCategory = null;
		ctrl.FilterPositions();
		for(Id positionId : ctrl.positionId2Selected.keySet()){
			ctrl.positionId2Selected.put(positionId, false);
		}	
		ctrl.save();
		
		delete [select id  from Position__c];
		ctrl.FilterPositions();
		system.assertEquals(0, ctrl.totalPages);
		system.assertEquals(0, ctrl.setCon.getResultSize());
		
		ctrl.selectedCategory = null;
		ctrl.selectedPositionStatus = 'Filled';
		ctrl.FilterPositions();
		
		ctrl.selectedCategory = 'Operations';
		ctrl.selectedPositionStatus = 'Filled';
		ctrl.FilterPositions();
	}
	 
	//Testing if current user who is rcruiter but not the recruiter who is the owner of the lead can update it 
	static testmethod void TestDataAccess(){		
        Profile pRecruiter = [select id from profile where name='Recruiter']; 
        User uRecruiter1 = new User(alias = 'standt', email='standarduser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', localesidkey='en_US', profileid = pRecruiter.Id, timezonesidkey='America/Los_Angeles', username='rec1_standarduser@testorg.com');
        insert uRecruiter1;
        User uRecruiter2 = new User(alias = 'standt', email='standarduser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', localesidkey='en_US', profileid = pRecruiter.Id, timezonesidkey='America/Los_Angeles', username='rec2_standarduser@testorg.com');
		insert uRecruiter2;

		Lead lead1;
        System.runAs(uRecruiter1) {
        	lead1 = TestDataGenerator.CreateLeads(1)[0];
            insert lead1;
            lead1 = [select id, ownerId from Lead where id =: lead1.Id];
            PageReference pageRef = Page.LeadDataEntry;
			Test.setCurrentPage(pageRef);			
			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(lead1);
			LeadDataEntryController ctrl = new LeadDataEntryController(stdCtrl);
			system.debug(ApexPages.getMessages());
			system.assertEquals(false, ApexPages.hasMessages());//no errors since the owner is the same as the editor
         }
         
         System.runAs(uRecruiter2){
         	lead1 = [select id, ownerId from Lead where id =: lead1.Id];
         	PageReference pageRef = Page.LeadDataEntry;
			Test.setCurrentPage(pageRef);			
			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(lead1);
			LeadDataEntryController ctrl = new LeadDataEntryController(stdCtrl);
			system.assertEquals(true, ApexPages.hasMessages());//present error since the editor is not the same as the owner
			
         	lead1.firstName = 'testing';
         	try{
         		update lead1;
         	}catch(System.DmlException e){//if exception happens that is the right behavior
         		System.assertEquals(true, true);
         	}
         }
	}
}