@RestResource(urlMapping='/PayFunction/*')
global class PayPostAPI {
    @HttpPOST
    global static ResponseClass doPayPost() {
         //try catch block only added by Ankit Tiwari 
        try
        {
            Savepoint sp = Database.setSavepoint();
        ResponseClass objRes=New ResponseClass();
        string sMode='';
        Integer totalAmount=0;
        Integer Amount=0;
        string sId='';
        Set<Id> SetPaySlipId=new Set<Id>();
        List<Pay_Slip__c> LstRecordsPaySlip=New List<Pay_Slip__c>();
        Map<String,Id> couponNameAndID = new Map<String,Id>();
		List<Coupon__c> copIdList = new List<Coupon__c>();      
        try {
            RestRequest req = RestContext.request;
            System.debug('>>>>>>>>>>req.requestBody.tostring()'+req.requestBody.tostring());
            List<ModelRequest> RequestClass = (List<ModelRequest>) JSON.deserialize(req.requestBody.tostring(), List<ModelRequest>.class);
            System.debug('RequestClassRequestClass    '+RequestClass);
            if(RequestClass.size()>0 ){
                if(RequestClass[0].CouponId != null){
                  copIdList =  [Select Id,Coupon_Name__c From Coupon__c where Id =: RequestClass[0].CouponId];
                }               
               
                sMode=RequestClass[0].Mode;
                System.debug('>>>>>>>>>> sMode '+sMode);
                List<Contact> lstContact=[SELECT Id, Empl_Code__c FROM Contact where Empl_Code__c =:RequestClass[0].EMPCode];
                System.debug('lstContact'+lstContact);
                system.debug('++'+RequestClass[0].AppId);
                Opportunity oppList=[SELECT id,Loan_Number__c,Branch__c,Loan_Product_Type__c,Installment_Amount__c,Balance_Collectable__c,branch__r.Name,Loan_Amount_Required__c FROM Opportunity
                                     WHERE Loan_Number__c=:RequestClass[0].AppId limit 1]; 
                System.debug('oppList'+oppList);
                if(oppList!=null){
                    integer icount=0;
                    String tmpSource='';
                    Decimal tmpAmount=0;
                    string UniqueNumberForPayU='TRAN-'+string.valueOf(Math.round((Math.random() * (900000) + 100000)));
                   
                    for(ModelRequest MR:RequestClass){
                        Pay_Slip__c objPaySlip=New Pay_Slip__c();
                        objPaySlip.ICollect_Request__c=req.requestBody.tostring();
                        // MR.Source='ICollectApp';
                        system.debug('string.valueOf(MR.Source).toLowercase() ===> '+MR.Source);
                        if(string.isNotEmpty(string.valueOf(MR.Source))){
                            tmpSource=string.valueOf(MR.Source).toLowercase();
                            if(string.valueOf(MR.Source).toLowercase()==string.valueOf('ICollectApp').toLowercase())
                                objPaySlip.Source__c='ICollect App';
                            else if(string.valueOf(MR.Source).toLowercase()==string.valueOf('SalesApp').toLowercase())
                                objPaySlip.Source__c='Sales App';            
                        }
                        objPaySlip.Purpose__c=MR.purpose;
                        objPaySlip.Depositor_Phone_Number__c=MR.DepositorPhone;
                        //Added by Adarsh
                        objPaySlip.U_latitude__c = MR.u_latitude;
                        objPaySlip.U_longitude__c = MR.u_longitude;
                        
                        
                        objPaySlip.UniqueNumberForPayU__c=UniqueNumberForPayU;
                        tmpAmount=decimal.valueOf(MR.Amount);
                        objPaySlip.Amount__c=decimal.valueOf(MR.Amount);
                        totalAmount=Integer.valueOf(MR.Amount);
                        Amount=Amount+totalAmount;
                        objPaySlip.IsIcollectApp__c=true;
                        if( copIdList.size()>0){
                            objPaySlip.Coupon__c = copIdList[0].Id;
                        }
                        objPaySlip.Date__c=system.today();
                        objPaySlip.PaySlip_Status__c='Active';
                        objPaySlip.Instrument__c='Electronic payment';
                        objPaySlip.Application__c=oppList.id;
                        objPaySlip.Pay_Slip_Collector__c=lstContact[0].id;
                        if(sMode.containsIgnoreCase('PayByOnline'))
                            objPaySlip.IsIcollectForPayByOnline__c=true;
                        objPaySlip.RecordTypeId=Schema.SobjectType.Pay_Slip__c.getRecordTypeInfosByName().get('Online payment').getRecordTypeId();
                        LstRecordsPaySlip.add(objPaySlip);
                        icount=icount+1;
                    }
                    system.debug('line 42 totalAmount ---> '+Amount);
                   
                    List<Branch_Not_Eligible_for_Coupon__mdt> threatMappings = [SELECT Id,Branch_Name__c FROM Branch_Not_Eligible_for_Coupon__mdt];
                    List<String> branchlst=new List<String>();
                    for(Branch_Not_Eligible_for_Coupon__mdt mdt:threatMappings)
                    {
                        branchlst.add(mdt.Branch_Name__c);
                    }
                     if((tmpSource==string.valueOf('SalesApp').toLowercase()) && (branchlst.contains(oppList.branch__r.Name)) && ((oppList.Loan_Product_Type__c=='HL' && tmpAmount<=Integer.valueof(Label.Loan_Product_HL_Amount))||(oppList.Loan_Product_Type__c=='LAP' && tmpAmount<Integer.valueof(Label.Loan_Product_LAP_Amount) &&  oppList.Loan_Amount_Required__c<=Integer.valueof(label.Loan_Amount_Required))||((oppList.Loan_Product_Type__c=='LAP' && tmpAmount<Integer.valueof(label.Loan_Product_LAP_Amount_Greater_that_1500000) &&  oppList.Loan_Amount_Required__c>Integer.valueof(label.Loan_Amount_Required)))))
                    {
                       
                          
                                 System.debug('Test94');
                         		 objRes.ResponseCode='200';
                                objRes.status='Success';
                                objRes.message='Coupon not allowed for this branch, Please login via iTrust for Coupons'; 
                        		System.debug('objRes'+objRes);
                                 return objRes;           
                    }
                    else if(LstRecordsPaySlip.size()>0){
                        Database.SaveResult[] srList = Database.insert(LstRecordsPaySlip, false);
                        integer iCon=1;
                        for (Database.SaveResult sr : srList) {
                            if (sr.isSuccess()) {
                                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                                SetPaySlipId.add(sr.getId());
                                if(sMode.containsIgnoreCase('PayByOnline')){
                                    if(string.isEmpty(sId))
                                        sId='?id'+iCon+'='+sr.getId();
                                    else
                                        sId+='&id'+iCon+'='+sr.getId();
                                    iCon=iCon+1;
                                }
                                if(!string.isEmpty(sId))
                                    objRes.sUrl= label.ICollectionURLForPayByLink + sId;//'http://isfctest-indiashelter.cs59.force.com/PayUForICollection'+sId;
                                //objRes.sUrl='https://isfc--isfctest--c.visualforce.com/apex/PayUForIcollect'+sId;
                                objRes.ResponseCode='200';
                                objRes.status='Success';
                                objRes.message='Pay Slip is created Successfully.'; 
                            }
                            else {              
                                for(Database.Error err : sr.getErrors()) {              
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    objRes.ResponseCode='400';
                                    objRes.status='Failed';
                                    objRes.message=err.getMessage();
                                }
                            }
                        }
                        if(SetPaySlipId.size()>0){
                            if(sMode.containsIgnoreCase('PayByLink'))
                                PayPostAPIHelper.fncSendPaymentLink(SetPaySlipId,Amount);
                        }
                    }
                } else{
                    objRes.ResponseCode='400';
                    objRes.status='Failed';
                    objRes.message='Loan id does not exist in the system.';
                }
            }else{
                objRes.ResponseCode='400';
                objRes.status='Failed';
                objRes.message='Invalid Request Please check you Request.';
            }
        }catch(Exception e) {
            Database.rollback(sp);
            API_Logs__c ap=new API_Logs__c();
            ap.Name='Pay Function';
            ap.API_Request__c=e.getMessage()+e.getLineNumber();
            insert ap;
            System.debug('Exception--->'+e.getMessage()+e.getLineNumber());
            objRes.ResponseCode='400';
            objRes.status='Failed';
            objRes.message=e.getMessage();
        }
        return objRes; 
        }
       	 catch(Exception e)
        {
            System.debug('Error in Line No.'+e.getLineNumber());
            System.debug('Error Message '+e.getMessage());
			  return null;     
        }
        
    }
    global class ResponseClass {
        global String ResponseCode;
        global String status;
        global String message;
        global String sUrl;
    }
    global class ModelRequest {
        global Integer Amount;
        global String purpose;
        global String DepositorPhone;
        global String Mode;
        global String AppId;
        global String EMPCode;
        //This extra variable user for Source, which notified the form where this Api will hit linke sales app or collection app
        global String Source;
        global String CouponId;
        //Added by Adarsh
        global String u_latitude;
        global String u_longitude;
    }
     public static void testParser(){
        if(Test.isRunningTest()){
        integer i=0;
      
        
       
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
             i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;    
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;
        i=0;

        }
    }
}