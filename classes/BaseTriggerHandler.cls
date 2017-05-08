public with sharing abstract class BaseTriggerHandler { 
	protected virtual void AfterInsert(){}
	protected virtual void BeforeUpdate(){}
	protected virtual void AfterUpdate(){}

	public virtual void Handle(){
		if(Trigger.isInsert && Trigger.isAfter){
			AfterInsert();
		}
		if(Trigger.isUpdate && Trigger.isBefore){
			BeforeUpdate();
		}
		if(Trigger.isUpdate && Trigger.isAfter){
			AfterUpdate();
		}		
	}
}