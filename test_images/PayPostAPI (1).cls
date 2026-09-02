/*
@Author: Shivam Agarwal
@Description: This class is a controller of CalculateInsuranceLWC component which used to calculate Total Premium Amount.
ModifiedDate : 29/10/2025
*/
public class CalculateInsuranceLWCController {
    
    @AuraEnabled
    public static void saveGenericLog(Boolean isDetected) {
        try{
            Generic_Log__c obj = new Generic_Log__c();
            obj.Suspicious_Activity_Detected__c = isDetected;
            insert obj;
        }
        catch(Exception e){
            throw new AuraHandledException('Error ' + e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static List<Wrapper> getDetails(String appId, Boolean isBHOthers, Boolean isNewCIEditMode){
        try{
            Map<Integer, Boolean> employeeIdErrorMap = new Map<Integer, Boolean>();
            List<OpportunityContactRole> OpportunityContactRoleList= new List<OpportunityContactRole>();
            List<Insurance_Generation_Data__c> InsuranceGenList = new List<Insurance_Generation_Data__c>();
            List<Cam__c> camlist = new List<Cam__c>();
            List<Opportunity> OpportunityList = new List<Opportunity>();
            List<Property_Insurance_Generation_Data__c> propGenList = new List<Property_Insurance_Generation_Data__c>();
            List<Wrapper> wrapClassList = new List<wrapper>();
            List<CalculateInsurance> CalculateInsuranceList = new List<CalculateInsurance>();
            String branchInsuranceCompany = '';
            String branchPropertyInsuranceCompany = '';
            String branchHealthInsuranceCompany = '';
            String errorMessage = '';
            Decimal opportunitySanctionedAmount = 0.0;
            String LoanType = '';
            Boolean isHLA_DM = false;
            Boolean isEditable = false;
            Boolean isUnEditable = false;
            Boolean isEditableHo = false;
            Boolean isUnEditableHo = false;
            Boolean isPropertyFieldDisabled = false;
            Boolean isEditableFieldTeam = false;
            Boolean isUnEditableFieldTeam = false;
            Boolean isCriticalEditableFieldTeam = false;
            Boolean isCriticalUnEditableFieldTeam = false;
            Boolean nonEditMode = true;
            Boolean EditMode = false;
            Boolean show = false;
            Boolean isDisabled = false;
            Boolean isDisabledIns = false;
            Integer tempTenure = null;
            
            String regionalOperationsManagers = System.Label.Regional_Operations_Managers;
            List<String> listregionalOperationsManagers = regionalOperationsManagers.split(';');
            User usr = [SELECT ID, Name, UserName, Profile.Name FROM User WHERE ID =: UserInfo.getUserId()];
            if(listregionalOperationsManagers.contains(usr.Profile.Name) || listregionalOperationsManagers.contains(usr.UserName)){
                isEditable = true;
                isUnEditable = false;  
            }
            else{
                isEditable = false;
                isUnEditable = true; 
            }
            
            String headOfficeUsers	= System.Label.Head_Office_Users;
            List<String> listHeadOfficeUsers = headOfficeUsers.split(';');
            if(listHeadOfficeUsers.contains(usr.UserName)){
                isEditableHo = true;
                isUnEditableHo = false;  
            }
            else{
                isEditableHo = false;
                isUnEditableHo = true; 
            }
            
            String fieldTeamUsers	= System.Label.Field_Team;
            List<String> listFieldTeamUsers = fieldTeamUsers.split(';');
            List<String> listInsuranceCalculatorEditableRightsUser = System.Label.Insurance_Calculator_Editable_Rights.split(';');
            if(listFieldTeamUsers.contains(usr.Profile.Name) || listFieldTeamUsers.contains(usr.UserName)){
                isPropertyFieldDisabled = true;
                isEditableFieldTeam = true;
                isUnEditableFieldTeam = false;  
            }
            else{
                isPropertyFieldDisabled = false;
                isEditableFieldTeam = false;
                isUnEditableFieldTeam = true; 
            }
            
            // Added Shivam Agarwal 22-07-2024
            System.debug('usr.Profile.Name===>>>>'+usr.Profile.Name);
            if(usr.Profile.Name == 'ISFCL LO/CSO = AAdhaar' || usr.Profile.Name == 'ISFCL CPU - PD(AOPS)' || usr.Profile.Name == 'ISFCL CPU - PD(ROPS)' || usr.Profile.Name == 'System Administrator'
               || usr.UserName == 'rohit.kumar7@indiashelter.in.partial'){
                   isCriticalEditableFieldTeam = true;
                   isCriticalUnEditableFieldTeam = false;
               }
            else{
                isCriticalEditableFieldTeam = false;
                isCriticalUnEditableFieldTeam = true;
			}
            // End
            
            AccidentalCustomSetting__c obj = AccidentalCustomSetting__c.getValues('Bank Name');
            
            camlist = [SELECT Id, CreatedDate, Property_Value__c, Build_Up_Construction_Value__c, Proposed_Construction_Value__c, Total_Prop_Val__c, 
                       Final_Decision__c, HLAmt__c FROM Cam__c WHERE Loan_Application__c =: appId ORDER BY createdDate DESC];
            
            OpportunityList = [SELECT Id, Branch__c, Branch__r.Insurance_Company__c, Branch__r.Property_Insurance_Company__c, Branch__r.Critical_Insurance_Company__c, 
                               Branch__r.Health_Insurance_Company__c, Branch__r.Zonal_Collection_Manager__c, Branch__r.Zonal_Collection_Manager__r.Name, 
                               Branch__r.National_Collection_Manager__c, Branch__r.National_Collection_Manager__r.Name, Branch__r.AOps__c, Branch__r.AOps__r.Name, 
                               Branch__r.Branch_OPS_Manager__c, Branch__r.Branch_OPS_Manager__r.Name, Branch__r.Business_Head__c, Branch__r.Business_Head__r.Name, 
                               Loan_Product_Type__c, Loan_Product__r.Product_Def__c, Loan_Product__c, Sanctioned_Amont__c, Sanctioned_ROI__c, Sanctioned_Tenure__c, 
                               Sanctioned_Date__c, HLA_Sign_Date__c, Loan_Type__c, Household__c, Purpose_of_loan__c, Bra_State__c FROM Opportunity WHERE 
                               Id =: appId AND Branch__c != NULL];
            
            if(!OpportunityList.isEmpty()){
                if(OpportunityList[0].Loan_Type__c != null){
                    LoanType = OpportunityList[0].Loan_Type__c;
                }
                System.debug('LoanType===>>>'+LoanType);
                
                if(OpportunityList[0].Branch__r.Insurance_Company__c != null){
                    branchInsuranceCompany = OpportunityList[0].Branch__r.Insurance_Company__c;
                }
                System.debug('branchInsuranceCompany===>>>'+branchInsuranceCompany);
                
                if(OpportunityList[0].Branch__r.Property_Insurance_Company__c != null){
                    branchPropertyInsuranceCompany = OpportunityList[0].Branch__r.Property_Insurance_Company__c;
                }
                System.debug('branchPropertyInsuranceCompany===>>>'+branchPropertyInsuranceCompany);
                
                if(OpportunityList[0].Branch__r.Health_Insurance_Company__c != null){
                    branchHealthInsuranceCompany = OpportunityList[0].Branch__r.Health_Insurance_Company__c;
                }
                System.debug('branchHealthInsuranceCompany===>>>'+branchHealthInsuranceCompany);
                
                if(OpportunityList[0].Sanctioned_Tenure__c != null){
                    tempTenure = Integer.valueOf(OpportunityList[0].Sanctioned_Tenure__c)/12;
                    System.debug('tempTenure = '+tempTenure);
                    if(tempTenure > 10){
                        propGenList = [SELECT Insurer__c, Rate__c, Building_Round_Rate__c, Content_Round_Rate__c, Tenure__c from Property_Insurance_Generation_Data__c WHERE Tenure__c =: 10 AND Insurer__c != 'Tata'];  
                    }
                    else{
                        propGenList = [SELECT Insurer__c, Rate__c, Building_Round_Rate__c, Content_Round_Rate__c, Tenure__c from Property_Insurance_Generation_Data__c WHERE Tenure__c =: tempTenure AND Insurer__c != 'Tata'];
                    }
                    System.debug('propGenList = '+ propGenList);
                }
            }
            
            List<Disbursement__c> alreadyDMSanctionList = [SELECT Id from Disbursement__c WHERE Application__c =: OpportunityList[0].Id AND Tranch_Details__c = 'First' AND 
                                                           (Disb_Status__c = 'Pending' OR Disb_Status__c = 'Handed over customer' OR Disb_Status__c = 'Send to CPU' OR 
                                                            Disb_Status__c = 'Payment Under Process' OR Disb_Status__c = 'Payment Processed' OR Disb_Status__c = 'Send to UW' OR 
                                                            Disb_Status__c = 'Subjectivity Cleared' OR Disb_Status__c = 'Legal Approved' OR Disb_Status__c = 'Send to PRE-CPU'
                                                            //added by himanshu(13-05-2023)
                                                            OR Disb_Status__c = 'Cancelled by Legal'  OR Disb_Status__c = 'Cancelled DE' OR Disb_Status__c = 'Cancelled by branch'
                                                            OR Disb_Status__c = 'Cancelled By UW' OR Disb_Status__c = 'Cancelled by Finance' OR Disb_Status__c = 'Cancelled by CPU'
                                                            OR Disb_Status__c = 'Cancelled by PRE-CPU'
                                                           )];
            
            System.debug('AlreadyDm'+alreadyDMSanctionList);
            if(alreadyDMSanctionList.size() > 0 || OpportunityList[0].HLA_Sign_Date__c != null){
                isHLA_DM = true;
                if(listInsuranceCalculatorEditableRightsUser.contains(usr.Profile.Name)){
                	isHLA_DM = false;
                }
            }
            System.debug('isHLA_DM'+isHLA_DM);
            
            if((camlist.size() > 0 && camlist[0].Final_Decision__c == 'Approved') || Test.isRunningTest()){
                InsuranceGenList = [SELECT Id, Application__c, Application__r.Sanctioned_Tenure__c, Application__r.Sanctioned_Amont__c, Contact__c, Contact__r.Name, 
                                    Role__c, Applicant_Name__c, Date_of_Birth__c, Gender__c, Height__c, Weight__c, BMI1__c, Life_Cover__c, Life_Insurance__c, 
                                    Life_Insurance_Company_Name__c, Life_Insurance_Tenure__c, Life_Insurance_Sum_Assured__c, Life_Insurance_Premium__c, 
                                    Medicals_Required__c, Medical_Required_BMI__c, Medical_Required_LIAC__c, Medicals_Accepted__c, Medical_Insurance_Premium__c, 
                                    Nominee_Name__c, Nominee_DOB__c, Relationship_with_Insured__c, Accidental_Death_Insurance__c, Accidental_Death_Insurance_Premium__c, 
                                    Property_Insurance_Required__c, Property_Insurance_Company_Name__c, Property_Tenure__c, Total_Property_Value__c, Property_Insurance_Premium__c, 
                                    Critical_illness_Required__c, Critical_Insurance_Company_Name__c, Critical_illness_Tenure__c, Critical_illness_Sum_Assured__c, 
                                    Critical_illness_Sum_Assured_Percentage__c, Critical_illness_Premium__c, Health_Insurance_Required__c, Health_Insurance_Company_Name__c, 
                                    Health_Insurance_Tenure__c, Health_Insurance_Sum_Assured__c, Health_Insurance_Premium__c, Health_Insurance_Nominee__c, 
                                    Health_Insurance_Nominee_Name__c, Health_Insurance_Nominee_DOB__c, Health_Insurance_Nominee_Gender__c, Health_Insurance_Nominee_Relationship__c, 
                                    Final_Life_Assured_Amount__c, Life_Insurance_Amount_Considered__c, Life_Insurance_Premium_2__c, Total_Premium_Amount__c, 
                                    Round_Rate__c, Employee_Id__c, Name_of_employee_of_MPH__c FROM Insurance_Generation_Data__c 
                                    WHERE Application__c =: appId ORDER BY Contact__r.coappsno__c ASC];
                
                if(InsuranceGenList.size() > 0){
                    for(Integer index=0; index <= InsuranceGenList.size(); index++){
                        employeeIdErrorMap.put(index,false);
                    }
                }
                
            }
            else{
                errorMessage = 'Insurance calculator can be done post CAM sanction';
            }
            opportunitySanctionedAmount = camlist[0].HLAmt__c;
            System.debug('opportunitySanctionedAmount='+opportunitySanctionedAmount);
            System.debug('InsuranceGenList  '+InsuranceGenList.size());
            
            Wrapper wrap = new Wrapper();
            if(InsuranceGenList.size() == 0){
                nonEditMode = false;
                EditMode = true;
                show = false;
                OpportunityContactRoleList = [SELECT Contact.name,contactId,Contact.Life_Insurance__c,OpportunityId,Contact.Critical_illness_Required__c,
                                              Contact.Accidental_Death_Insurance__c,Contact.Relation_with_insured__c,Contact.Date_of_Birth__c,
                                              Contact.Account.Nominee_Name__r.name,Contact.Account.Date_of_Birth__c,Contact.Sex__c, Contact.is_Property_Owner__c, 
                                              role,Contact.Sum_Assured_Percentage__c,Opportunity.Sanctioned_Date__c FROM OpportunityContactRole WHERE OpportunityId =: appId AND 
                                              (Contact.Accidental_Death_Insurance__c !=null OR Contact.Life_Insurance__c != null) ORDER BY Contact.coappsno__c ASC];
                
                //Integer applicantCount = 0;
                System.debug('OpportunityContactRoleList.size()='+OpportunityContactRoleList.size());
                if(OpportunityContactRoleList.size()>0){
                    String monthStr = '';
                	String dayStr = '';
                    for(OpportunityContactRole ocr : OpportunityContactRoleList){
                        //applicantCount++;
                        Decimal sancAmount = 0;
                        CalculateInsurance calculateInsuranceWrap = new CalculateInsurance();
                        calculateInsuranceWrap.application = appId;
                        calculateInsuranceWrap.con = ocr.ContactId;
                        calculateInsuranceWrap.applicantDetails = ocr.role;
                        calculateInsuranceWrap.applicantDetailsApplicantName = ocr.role + ' - ' + ocr.Contact.name;
                        calculateInsuranceWrap.applicantName = ocr.Contact.name;
                        monthStr = String.valueOf(ocr.Contact.Date_of_Birth__c.month());
                        if(monthStr.length() == 1) {
                            monthStr = '0' + monthStr;
                        }
                        dayStr = String.valueOf(ocr.Contact.Date_of_Birth__c.day());
                        if(dayStr.length() == 1) {
                            dayStr = '0' + dayStr;
                        }
                        calculateInsuranceWrap.DOB = monthStr + '/' + dayStr + '/' + ocr.Contact.Date_of_Birth__c.year();
                        calculateInsuranceWrap.gender = ocr.Contact.Sex__c;
                        calculateInsuranceWrap.lifeInsurance = ocr.Contact.Life_Insurance__c != NULL ? ocr.Contact.Life_Insurance__c : '';
                        /*LifeInsuranceDetails lifeInsuranceWrap = new LifeInsuranceDetails();
                        if(camlist[0].HLAmt__c != null){
                            lifeInsuranceWrap.lifeInsuranceSumAssured = camlist[0].HLAmt__c;
                        }
                        if(lifeInsuranceWrap.lifeInsuranceCompanyName == 'None')
                            lifeInsuranceWrap.lifeInsurancePremium = 0;
                        if(OpportunityList[0].Sanctioned_Tenure__c != null){
                            lifeInsuranceWrap.lifeInsuranceTenure = Integer.valueOf(OpportunityList[0].Sanctioned_Tenure__c)/12;
                        }
                        /* Added by Laxmi  */
                        /*if(lifeInsuranceWrap.height != 0 && lifeInsuranceWrap.weight != 0){
                            Decimal heightInMeter = lifeInsuranceWrap.height/100;
                            Decimal heightSquared = heightInMeter * heightInMeter;
                            lifeInsuranceWrap.BMI = (lifeInsuranceWrap.weight/heightSquared).setScale(2, RoundingMode.CEILING);
                            if(lifeInsuranceWrap.BMI < 18 || lifeInsuranceWrap.BMI > 29){
                                lifeInsuranceWrap.medicalrequiredBMI ='Yes';
                            }
                            if(lifeInsuranceWrap.BMI > 18 && lifeInsuranceWrap.BMI < 29){
                                system.debug('line 291');
                                lifeInsuranceWrap.medicalrequiredBMI ='No';
                            }
                        }
                        /*------END by Laxmi-------*/
                        /*lifeInsuranceWrap.nomineeName = ocr.Contact.Account.Nominee_Name__r.Name;
                        lifeInsuranceWrap.relationship =  ocr.Contact.Relation_with_insured__c;
                        lifeInsuranceWrap.accidentalDeathInsurance = ocr.Contact.Accidental_Death_Insurance__c;
                        if(lifeInsuranceWrap.accidentalDeathInsurance == 'Yes'){
                            if(camlist[0].HLAmt__c != null && obj!= null && Label.GST != null ){
                                lifeInsuranceWrap.AccidentalDeathInsurancePremium = camlist[0].HLAmt__c*obj.rate__c*obj.Tenure__c;
                                Decimal temp = (lifeInsuranceWrap.AccidentalDeathInsurancePremium*Integer.valueOf(Label.GST))/100;
                                lifeInsuranceWrap.AccidentalDeathInsurancePremium = Math.round(lifeInsuranceWrap.AccidentalDeathInsurancePremium+temp);
                            }
                        }
                        calculateInsuranceWrap.LifeInsuranceList.add(lifeInsuranceWrap);*/
                        //calculateInsuranceWrap.LifeInsuranceList = getLifeInsurancePremiumQuote(OpportunityList, ocr.Contact.Sex__c, camlist[0].HLAmt__c, monthStr + '/' + dayStr + '/' + ocr.Contact.Date_of_Birth__c.year());
                        
                        if(ocr.Contact.is_Property_Owner__c == 'Yes'){
                            calculateInsuranceWrap.PropertyInsurance = 'Yes';
                            /*if(ocr.role == 'Main Applicant'){
                                calculateInsuranceWrap.isPropertyMainApplicant = true;
                            }
                            PropertyInsuranceDetails propertyInsuranceWrap = new PropertyInsuranceDetails();
                            //if(applicantCount == 1){
                            propertyInsuranceWrap.propcompanyname = 'ICICI Lombard';
                            if(OpportunityList[0].Sanctioned_Tenure__c != null){
                                if(Integer.valueOf(OpportunityList[0].Sanctioned_Tenure__c)/12 <= 10){
                                    propertyInsuranceWrap.propertyTenure = Integer.valueOf(OpportunityList[0].Sanctioned_Tenure__c)/12;
                                }
                                else{
                                    propertyInsuranceWrap.propertyTenure = 10;
                                }
                            }
                            
                            if(calculateInsuranceWrap.PropertyInsurance == 'Yes'){
                                Decimal camBuildUpConstructionValue;
                                Decimal proposedConstructionValue;
                                Decimal TotalValue;
                                System.debug('At 203');
                                if(camlist[0].Build_Up_Construction_Value__c == null){
                                    camBuildUpConstructionValue = 0;
                                }
                                else{
                                    camBuildUpConstructionValue = camlist[0].Build_Up_Construction_Value__c;  
                                }
                                if(camlist[0].Proposed_Construction_Value__c == null){
                                    proposedConstructionValue = 0;   
                                }
                                else{
                                    proposedConstructionValue = camlist[0].Proposed_Construction_Value__c; 
                                }
                                TotalValue = camBuildUpConstructionValue + proposedConstructionValue;
                                propertyInsuranceWrap.totalPropertyValue = String.valueOf(TotalValue);
                                if(!propGenList.isEmpty())
                                    propertyInsuranceWrap.PropertyInsurancePremium = TotalValue*propGenList[0].Rate__c;
                                Decimal temp = (propertyInsuranceWrap.PropertyInsurancePremium*Integer.valueOf(Label.GST))/100;
                                propertyInsuranceWrap.PropertyInsurancePremium = Math.round(propertyInsuranceWrap.PropertyInsurancePremium + temp);
                                System.debug('calculateInsuranceWrap.PropertyInsurancePremium='+propertyInsuranceWrap.PropertyInsurancePremium);
                            }
                            //}
                            calculateInsuranceWrap.PropertyInsuranceList.add(propertyInsuranceWrap);*/
                        }
                        else{
                            calculateInsuranceWrap.PropertyInsurance = 'No';
                        }
                        
                        calculateInsuranceWrap.HealthInsuranceRequired = 'Yes';
                        /*HealthInsuranceDetails healthInsuranceWrap = new HealthInsuranceDetails();
                        healthInsuranceWrap.HealthInsuranceRequired = 'Yes';
                        calculateInsuranceWrap.HealthInsuranceList.add(healthInsuranceWrap);
                        
                        calculateInsuranceWrap.criticalIllnessRequired = ocr.Contact.Critical_illness_Required__c;
                        if(calculateInsuranceWrap.criticalInsuranceCompanyName == 'None')
                            calculateInsuranceWrap.criticalIllnessPremium = 0;
                        if(camlist[0].HLAmt__c != null){
                            if(calculateInsuranceWrap.criticalIllnessSumAssuredPercentage != null)
                                calculateInsuranceWrap.criticalIllnessSumAssured = camlist[0].HLAmt__c*(Decimal.valueOf(calculateInsuranceWrap.criticalIllnessSumAssuredPercentage)/100);
                        }
                        if(calculateInsuranceWrap.criticalIllnessRequired == 'Yes'){
                            calculateInsuranceWrap.criticalIllnessTenure = 5;  
                        }
                        calculateInsuranceWrap.criticalIllnessSumAssuredPercentage = ocr.Contact.Sum_Assured_Percentage__c;
                        if(ocr.Contact.Date_of_Birth__c != null){
                            Date dateOfBirth = ocr.Contact.Date_of_Birth__c;
                            Integer numberOfdays = dateOfBirth.daysBetween(OpportunityList[0].Sanctioned_Date__c);
                            Integer age = Integer.valueOf(numberOfdays/365);
                        }
                        if(camlist[0].HLAmt__c != null)
                            sancAmount = camlist[0].HLAmt__c;
                        Date tempDOB;
                        if(ocr.Contact.Date_of_Birth__c != null){
                            tempDOB= ocr.Contact.Date_of_Birth__c;
                        }
                        Integer days=0;
                        Integer  tempage=0;
                        if(tempDOB != null){
                            days = tempDOB.daysBetween(Date.Today());
                            tempage= Integer.valueOf(days/365);
                        }
                        System.debug('tempage'+tempage);*/
                        
                        calculateInsuranceList.add(calculateInsuranceWrap);
                        //if(camlist[0].Build_Up_Construction_Value__c != null && camlist[0].Proposed_Construction_Value__c != null){
                        //Decimal OneValue = camlist[0].Build_Up_Construction_Value__c != null ? camlist[0].Build_Up_Construction_Value__c : 0;
                        //Decimal SecondValue = camlist[0].Proposed_Construction_Value__c != null ? camlist[0].Proposed_Construction_Value__c : 0;
                        //Decimal ValueOfTotal = OneValue + SecondValue;
                        //calculateInsuranceWrapClassList[0].totalPropertyValue = String.valueOf(ValueOfTotal);
                        // }
                    }
                }
                else{
                    errorMessage = 'There is no Contact Roles or may be Contact don\'t have any insurance';
                }
            }
            else{
                nonEditMode = true;
                EditMode = false;
                show = true;
                /*if(isBHOthers && !isNewCIEditMode){
                    EditMode = true;
                	show = false;
                }*/
                
                String monthStr = '';
                String dayStr = '';
                for(Insurance_Generation_Data__c igd : InsuranceGenList){
                    calculateInsurance calculateInsuranceWrap = new calculateInsurance();
                    calculateInsuranceWrap.application = appId;
                    calculateInsuranceWrap.con = igd.Contact__c;
                    calculateInsuranceWrap.insuranceId = igd.Id;
                    calculateInsuranceWrap.applicantDetails = igd.Role__c;
                    calculateInsuranceWrap.applicantDetailsApplicantName = igd.Role__c + ' - ' + igd.Applicant_Name__c;
                    calculateInsuranceWrap.applicantName = igd.Applicant_Name__c;
                    monthStr = String.valueOf(igd.Date_of_Birth__c.month());
                    if(monthStr.length() == 1) {
                        monthStr = '0' + monthStr;
                    }
                    dayStr = String.valueOf(igd.Date_of_Birth__c.day());
                    if(dayStr.length() == 1) {
                        dayStr = '0' + dayStr;
                    }
                    calculateInsuranceWrap.DOB = monthStr + '/' + dayStr + '/' + igd.Date_of_Birth__c.year();
                    calculateInsuranceWrap.gender = igd.Gender__c;
                    calculateInsuranceWrap.lifeInsurance = igd.Life_Insurance__c != NULL ? igd.Life_Insurance__c : '';
                    if(calculateInsuranceWrap.lifeInsurance == 'Yes'){
                        LifeInsuranceDetails lifeInsuranceWrap = new LifeInsuranceDetails();
                        lifeInsuranceWrap.isSelected = true;
                        lifeInsuranceWrap.OptionWithCompanyName = 'Option 1 - ' + igd.Life_Insurance_Company_Name__c;
                        lifeInsuranceWrap.LifeCover = igd.Life_Cover__c;
                        lifeInsuranceWrap.roundRate = igd.Round_Rate__c;
                        lifeInsuranceWrap.finalRate = igd.Round_Rate__c;
                        lifeInsuranceWrap.applicantAge = String.valueOf(calculateAge(calculateInsuranceWrap.DOB, OpportunityList[0].Sanctioned_Date__c));
                        lifeInsuranceWrap.lifeInsuranceCompanyName = igd.Life_Insurance_Company_Name__c;
                        lifeInsuranceWrap.lifeInsuranceSumAssured = igd.Life_Insurance_Sum_Assured__c;
                        lifeInsuranceWrap.lifeInsurancePremium = igd.Life_Insurance_Premium__c;
                        lifeInsuranceWrap.lifeInsuranceTenure = Integer.valueOf(igd.Life_Insurance_Tenure__c);
                        lifeInsuranceWrap.employeeId = igd.Employee_Id__c;
                        lifeInsuranceWrap.employeeName = igd.Name_of_employee_of_MPH__c;
                        lifeInsuranceWrap.height = igd.Height__c;
                        lifeInsuranceWrap.weight = igd.Weight__c;
                        lifeInsuranceWrap.BMI = igd.BMI1__c;
                        lifeInsuranceWrap.medicalrequiredBMI = igd.Medical_Required_BMI__c;
                        lifeInsuranceWrap.medicalrequired = igd.Medicals_Required__c;
                        lifeInsuranceWrap.medicalaccepted = igd.Medicals_Accepted__c == NULL ? 'No' : igd.Medicals_Accepted__c;
                        lifeInsuranceWrap.nomineeName = igd.Nominee_Name__c;
                        lifeInsuranceWrap.nomineeDOB = String.valueOf(igd.Nominee_DOB__c);
                        lifeInsuranceWrap.relationship =  igd.Relationship_with_Insured__c;
                        lifeInsuranceWrap.accidentalDeathInsurance = igd.Accidental_Death_Insurance__c;
                        lifeInsuranceWrap.AccidentalDeathInsurancePremium = igd.Accidental_Death_Insurance_Premium__c;
                        lifeInsuranceWrap.isDisabled = true;
                        calculateInsuranceWrap.LifeInsuranceList.add(lifeInsuranceWrap);
                    }
                    System.debug('igd.Property_Insurance_Required__c===>>>>'+igd.Property_Insurance_Required__c);
                    calculateInsuranceWrap.PropertyInsurance = igd.Property_Insurance_Required__c;
                    /*if(igd.Role__c == 'Main Applicant'){
                        calculateInsuranceWrap.isPropertyMainApplicant = true;
                    }*/
                    if(igd.Property_Insurance_Required__c != NULL && igd.Property_Insurance_Required__c == 'Yes'){
                        PropertyInsuranceDetails propertyInsuranceWrap = new PropertyInsuranceDetails();
                        //if(igd.Role__c == 'Main Applicant'){
                            propertyInsuranceWrap.isSelected = true;
                        	propertyInsuranceWrap.OptionWithCompanyName = 'Option 1 - ' + igd.Property_Insurance_Company_Name__c;
                            propertyInsuranceWrap.propcompanyname = igd.Property_Insurance_Company_Name__c;
                            propertyInsuranceWrap.totalPropertyValue = String.valueOf(igd.Total_Property_Value__c);
                            propertyInsuranceWrap.propertyTenure = Integer.valueOf(igd.Property_Tenure__c);
                            propertyInsuranceWrap.PropertyInsurancePremium = igd.Property_Insurance_Premium__c;
                        	propertyInsuranceWrap.isDisabled = true;
                        //}
                        calculateInsuranceWrap.PropertyInsuranceList.add(propertyInsuranceWrap);
                    }
                    
                    calculateInsuranceWrap.HealthInsuranceRequired = igd.Health_Insurance_Required__c != NULL ? igd.Health_Insurance_Required__c : 'No';
                    if(calculateInsuranceWrap.HealthInsuranceRequired == 'Yes'){
                        HealthInsuranceDetails healthInsuranceWrap = new HealthInsuranceDetails();
                        healthInsuranceWrap.isSelected = true;
                        healthInsuranceWrap.OptionWithCompanyName = 'Option 1 - ' + igd.Health_Insurance_Company_Name__c;
                        healthInsuranceWrap.HealthInsuranceCompanyName = igd.Health_Insurance_Company_Name__c;
                        healthInsuranceWrap.HealthInsuranceTenure = igd.Health_Insurance_Tenure__c;
                        healthInsuranceWrap.HealthInsuranceSumAssured = igd.Health_Insurance_Sum_Assured__c;
                        healthInsuranceWrap.HealthInsurancePremium = igd.Health_Insurance_Premium__c;
                        healthInsuranceWrap.HealthInsuranceNominee = igd.Health_Insurance_Nominee__c;
                        healthInsuranceWrap.HealthInsuranceNomineeName = igd.Health_Insurance_Nominee_Name__c;
                        healthInsuranceWrap.HealthInsuranceNomineeDOB = igd.Health_Insurance_Nominee_DOB__c;
                        healthInsuranceWrap.HealthInsuranceNomineeGender = igd.Health_Insurance_Nominee_Gender__c;
                        healthInsuranceWrap.HealthInsuranceNomineeRelationship = igd.Health_Insurance_Nominee_Relationship__c;
                        healthInsuranceWrap.isDisabled = true;
                        calculateInsuranceWrap.HealthInsuranceList.add(healthInsuranceWrap);
                    }
                    
                    calculateInsuranceWrap.FinalLifeAssuredAmount = igd.Final_Life_Assured_Amount__c;
                    calculateInsuranceWrap.LifeInsuranceAmountConsidered = igd.Life_Insurance_Amount_Considered__c;
                    calculateInsuranceWrap.LifeInsurancePremium2 = igd.Life_Insurance_Premium_2__c;
                    calculateInsuranceWrap.TotalPremiumAmount = igd.Total_Premium_Amount__c;
                    calculateInsuranceList.add(calculateInsuranceWrap);
                }
            }
            wrap.OpportunityList = OpportunityList;
            wrap.OpportunityContactRoleList = OpportunityContactRoleList;
            wrap.CAMList = camList;
            wrap.PropertyInsuranceGenerationList = propGenList;
            wrap.calculateInsuranceList = calculateInsuranceList;
            wrap.branchInsuranceCompany = branchInsuranceCompany;
            wrap.branchPropertyInsuranceCompany = branchPropertyInsuranceCompany;
            wrap.branchHealthInsuranceCompany = branchHealthInsuranceCompany;
            wrap.errorMessage = errorMessage;
            wrap.isDisabled = isDisabled;
            wrap.EditMode = EditMode;
            wrap.showEditButton = show;
            wrap.isHLA_DM = isHLA_DM;
            wrap.nomineeNameList = getNomineeNameDetails(appId);
            wrap.relationshipList = getRelationshipDetails();
            wrapClassList.add(wrap);
            System.debug(wrapClassList);
            return wrapClassList;
        }
        catch(Exception e){
            System.debug(e.getMessage()+'==='+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static Integer calculateAge(String dob, Date oppSanctionedDate){
        try{
            if(dob != null){
                List<String> parts = dob.split('/');
                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                Date dateOfBirth = Date.newInstance(year, month, day);
                Integer numberOfdays = dateOfBirth.daysBetween(oppSanctionedDate);
                return Integer.valueOf(numberOfdays/365);
            }
        }
        catch(Exception e){
            System.debug(e.getMessage()+'==='+e.getLineNumber());
        }
        return NULL;
    }
    
    public static List<SelectOption> getNomineeNameDetails(String appId){
        try{
            List<SelectOption> options = new List<SelectOption>();
            //options.add(new SelectOption('None', 'None'));
            for(OpportunityContactRole opp : [SELECT role, contact.name FROM OpportunityContactRole WHERE OpportunityId =: appId]){
                options.add(new SelectOption(opp.contact.name, opp.contact.name));
            }
            System.debug(options);
            return options;         
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }                    
    }
    
    public static List<SelectOption> getRelationshipDetails(){
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption('None','None'));
        options.add(new SelectOption('Brother','Brother'));
        options.add(new SelectOption('Brother in Law','Brother in Law'));
        options.add(new SelectOption('Daughter','Daughter'));
        options.add(new SelectOption('Daughter in Law','Daughter in Law'));
        options.add(new SelectOption('Father','Father'));
        options.add(new SelectOption('Father in Law','Father in Law'));
        options.add(new SelectOption('Husband','Husband'));
        options.add(new SelectOption('Mother','Mother'));
        options.add(new SelectOption('Mother in Law','Mother in Law'));
        options.add(new SelectOption('Sister','Sister'));
        options.add(new SelectOption('Son','Son'));
        options.add(new SelectOption('Wife','Wife'));
        options.add(new SelectOption('Niece','Niece'));
        options.add(new SelectOption('Nephew','Nephew'));
        options.add(new SelectOption('Sister in Law','Sister in Law'));
        options.add(new SelectOption('Grand Son','Grand Son'));
        options.add(new SelectOption('Grand Daughter','Grand Daughter'));
        options.add(new SelectOption('Uncle','Uncle'));
        options.add(new SelectOption('Aunty','Aunty'));
        return options;           
    } 
    
    @AuraEnabled
    public static List<LifeInsuranceDetails> getLifeInsurancePremiumQuote(List<Opportunity> OpportunityList, String gender, Decimal sumAssured, String dob, String branchInsuranceCompany, Boolean isBHOthers){
        try{
            List<LifeInsuranceDetails> lifeInsuranceList = new List<LifeInsuranceDetails>();
            Decimal roi = 0.0;
            Decimal roiStart = 0.0;
            Decimal roiEnd = 0.0;
            Integer tenure = 0;
            if(OpportunityList[0].Sanctioned_Tenure__c != null){
                tenure = Integer.valueOf(OpportunityList[0].Sanctioned_Tenure__c)/12;
            }
            System.debug(tenure);
            String product = '';
            //System.debug(OpportunityList[0].Loan_Product__r.Product_Def__c);
            if(!String.isBlank(OpportunityList[0].Loan_Product__r.Product_Def__c) && OpportunityList[0].Loan_Product__r.Product_Def__c != null){
                product = OpportunityList[0].Loan_Product__r.Product_Def__c;
            }
            Integer age = calculateAge(dob, OpportunityList[0].Sanctioned_Date__c);
            System.debug('age==>>'+age);
            if(OpportunityList[0].Sanctioned_ROI__c != null){
                roi = OpportunityList[0].Sanctioned_ROI__c;
            }
            system.debug('roi@398'+roi);
            if(roi != null){
                if(roi > 7){
                    if(roi >=8 && roi <= 12){
                        roiStart = 8;
                        roiEnd = 12;
                    }
                    else if(roi > 12 && roi <= 15){
                        roiStart = 12;
                        roiEnd = 15;
                    }
                    else if(roi > 15 && roi <= 18){
                        roiStart = 15;
                        roiEnd = 18;
                    }
                    else if(roi > 18 && roi <= 21){
                        roiStart = 18;
                        roiEnd = 21;
                    }
                }  
            }
            
            String bank = '';
            if(isBHOthers){
                bank = 'Axis Max Life Insurance';
            }
            
            String query1 = 'SELECT Id, Rate__c, Product__c, Start_Sum_Assured__c, End_Sum_Assured__c, Start_Tenure__c, Start_Age__c, Start_ROI__c, End_ROI__c, Round_Rate__c, Age__c, ROI__c, Gender__c, Insurer__c, ROI_Start__c, ROI_End__c, Tenure__c, Insurance_Term__c from Life_Insurance_Generation_Data__c WHERE ';
            if(bank != null && bank != '')
                query1 += 'Insurer__c  =: bank AND ';
            if(tenure != null)
                query1 += 'Start_Tenure__c  =: tenure';
            if(age != null)
                query1 += ' AND Start_Age__c  =: age';
            
            System.debug(roiStart);
            System.debug(roiEnd);
            System.debug(sumAssured);
            System.debug(product);
            System.debug(gender);
            System.debug(query1);
            List<Life_Insurance_Generation_Data__c> insuranceGenList = Database.query(query1);
            System.debug('-----insuranceGenList'+insuranceGenList.size());
            if(!insuranceGenList.isEmpty()){
                Integer countICICI = 0;
                for(Life_Insurance_Generation_Data__c obj : insuranceGenList){
                    LifeInsuranceDetails lifeInsuranceWrap = new LifeInsuranceDetails();
                    lifeInsuranceWrap.isSelected = false;
                    lifeInsuranceWrap.roundRate = obj.Round_Rate__c;
                    lifeInsuranceWrap.applicantAge = String.valueOf(age);
                    lifeInsuranceWrap.lifeInsuranceCompanyName = obj.Insurer__c;
                    lifeInsuranceWrap.lifeInsuranceTenure = Integer.valueOf(obj.Start_Tenure__c);
                    lifeInsuranceWrap.lifeInsuranceSumAssured = sumAssured;
                    lifeInsuranceWrap.medicalrequired = 'No';
                    lifeInsuranceWrap.medicalaccepted = 'No';
                    if(obj.Insurer__c == 'Axis Max Life Insurance' && obj.Start_ROI__c >= roiStart && obj.End_ROI__c <= roiEnd && obj.Insurance_Term__c == tenure){
                        Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                        Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                        lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                        lifeInsuranceWrap.isDisabled = false;
                        lifeInsuranceList.add(lifeInsuranceWrap);
                    }
                    else if(obj.Insurer__c == 'Bajaj Allianz' && obj.Start_Sum_Assured__c < sumAssured && obj.End_Sum_Assured__c >= sumAssured && !OpportunityList.isEmpty() && OpportunityList[0].Bra_State__c != NULL && (OpportunityList[0].Bra_State__c == 'Gujarat' || OpportunityList[0].Bra_State__c == 'Orissa')){
                        Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                        Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                        lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                        lifeInsuranceWrap.isDisabled = false;
                        lifeInsuranceList.add(lifeInsuranceWrap);
                    }
                    else if(obj.Insurer__c == 'ICICI' && !OpportunityList.isEmpty() && OpportunityList[0].Bra_State__c != NULL && (OpportunityList[0].Bra_State__c != 'Gujarat' && OpportunityList[0].Bra_State__c != 'Orissa')){
                        String ICICIMinimumValue = Label.ICICIMinValue;
                        String ICICImid = Label.ICICIMidValue;
                        String ICICIlarge = Label.ICICILargeValue;
                        System.debug(ICICIMinimumValue);
                        System.debug(ICICImid);
                        System.debug(ICICIlarge);
                        if(sumAssured >= Decimal.valueOf(ICICIMinimumValue) && sumAssured <= Decimal.valueOf(ICICImid)){
                            if(obj.Start_Sum_Assured__c >= Decimal.valueOf(ICICIMinimumValue) && obj.End_Sum_Assured__c <= Decimal.valueOf(ICICImid)){
                                Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                                Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                                lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                                lifeInsuranceWrap.isDisabled = false;
                                lifeInsuranceList.add(lifeInsuranceWrap);
                            }
                        }
                        else if(sumAssured > Decimal.valueOf(ICICImid) && sumAssured <= Decimal.valueOf(ICICIlarge) && obj.Gender__c == gender){
                            if(obj.Start_Sum_Assured__c > Decimal.valueOf(ICICImid) && obj.End_Sum_Assured__c <= Decimal.valueOf(ICICIlarge)){
                                Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                                Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                                lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                                lifeInsuranceWrap.isDisabled = false;
                                lifeInsuranceList.add(lifeInsuranceWrap);
                            }
                        }
                        countICICI++;
                    }
                }
                
                if(branchInsuranceCompany != null){
                    LifeInsuranceDetails selectedlifeInsuranceWrap;
                    List<LifeInsuranceDetails> remaininglifeInsuranceWrapList = new List<LifeInsuranceDetails>();
                    for(LifeInsuranceDetails obj : lifeInsuranceList) {
                        if(obj.lifeInsuranceCompanyName == branchInsuranceCompany && selectedlifeInsuranceWrap == null){
                            selectedlifeInsuranceWrap = obj;
                        }
                        else{
                            remaininglifeInsuranceWrapList.add(obj);
                        }
                    }
                    if(selectedlifeInsuranceWrap != null){
                        lifeInsuranceList.clear();
                        lifeInsuranceList.add(selectedlifeInsuranceWrap);
                        lifeInsuranceList.addAll(remaininglifeInsuranceWrapList);
                    }
                }
                
                Integer option = 1;
                for(LifeInsuranceDetails obj : lifeInsuranceList){
                    obj.OptionWithCompanyName = 'Option ' + option + ' - ' + obj.lifeInsuranceCompanyName;
                    option++;
                }
            }
            return lifeInsuranceList; 
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }                 
    }
    
    @AuraEnabled
    public static String calculateLifeInsurancePremium(List<Opportunity> OpportunityList, String lifeInsuranceWrap, String dob, String gender) {
        try{
            System.debug(lifeInsuranceWrap);
            LifeInsuranceDetails lifeInsurance = (LifeInsuranceDetails)JSON.deserialize(lifeInsuranceWrap, LifeInsuranceDetails.class);
            System.debug(lifeInsurance.lifeInsuranceCompanyName + '====' + lifeInsurance.lifeInsuranceTenure + '====' +  lifeInsurance.lifeInsuranceSumAssured + '====' +  dob);
            Decimal premiumAmount = 0.0;
            Integer age = 0;
            if(dob != null){
                List<String> parts = dob.split('/');
                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                Date dateOfBirth = Date.newInstance(year, month, day);
                Integer numberOfdays = dateOfBirth.daysBetween(OpportunityList[0].Sanctioned_Date__c);
                age = Integer.valueOf(numberOfdays/365);
            }
            System.debug('age==>>'+age);
            Decimal roi = 0.0;
            Decimal roiStart = 0.0;
            Decimal roiEnd = 0.0;
            if(OpportunityList[0].Sanctioned_ROI__c != null){
                roi = OpportunityList[0].Sanctioned_ROI__c;
            }
            system.debug('roi@398'+roi);
            if(roi != null){
                if(roi > 7){
                    if(roi >=8 && roi <= 12){
                        roiStart = 8;
                        roiEnd = 12;
                    }
                    else if(roi > 12 && roi <= 15){
                        roiStart = 12;
                        roiEnd = 15;
                    }
                    else if(roi > 15 && roi <= 18){
                        roiStart = 15;
                        roiEnd = 18;
                    }
                    else if(roi > 18 && roi <= 22){
                        roiStart = 18;
                        roiEnd = 22;
                    }
                }  
            }
            
            String lifeCompanyName = lifeInsurance.lifeInsuranceCompanyName;
            Integer lifeTenure = lifeInsurance.lifeInsuranceTenure;
            String product = OpportunityList[0].Loan_Product__r.Product_Def__c != NULL ? OpportunityList[0].Loan_Product__r.Product_Def__c : '';
            if(lifeInsurance.lifeInsuranceTenure <= 20){
                String query1 = 'SELECT Id, Rate__c, Product__c, Start_Sum_Assured__c, End_Sum_Assured__c, Start_Tenure__c, Start_Age__c, Start_ROI__c, End_ROI__c, Round_Rate__c, Age__c, ROI__c, Gender__c, Insurer__c, ROI_Start__c, ROI_End__c, Tenure__c from Life_Insurance_Generation_Data__c WHERE Insurer__c  =: lifeCompanyName';
                if(age != null)
                    query1 += ' AND Start_Age__c  =: age';
                if(lifeInsurance.lifeInsuranceTenure != null)
                    query1 += ' And Start_Tenure__c  =: lifeTenure';
                if(lifeInsurance.lifeInsuranceCompanyName == 'Axis Max Life Insurance' ){
                	if(lifeInsurance.lifeInsuranceTenure != null)
                    	query1 += ' And Insurance_Term__c  =: lifeTenure';
                    if(roiStart != null && roiEnd != null)
                        query1 += ' AND Start_ROI__c >=: roiStart AND End_ROI__c <=: roiEnd ';
                    System.debug(query1);
                }
                /*else if(lifeInsurance.lifeInsuranceCompanyName == 'Max Life Insurance' ){
                    if(roiStart != null && roiEnd != null)
                        query1 += ' AND Start_ROI__c >=: roiStart AND End_ROI__c <=: roiEnd ';
                    if(gender != null)
                        query1 += ' AND Gender__c =: gender';
                    if(product != '')
                        query1 += ' AND Product__c =: product';
                    System.debug(query1);
                }
                else if(lifeInsurance.lifeInsuranceCompanyName == 'Edelweiss Tokio Life'){
                    query1 += ' AND Gender__c =: gender ';
                    if(product != '')
                        query1 += ' AND Product__c =: product';
                    
                }*/
                else if(lifeInsurance.lifeInsuranceCompanyName == 'ICICI'){
                    String ICICIMinimumValue = Label.ICICIMinValue;
                    String ICICImid = Label.ICICIMidValue;
                    String ICICIlarge = Label.ICICILargeValue;
                    Decimal ValueOneOfICICI = Decimal.valueOf(ICICIMinimumValue);
                    Decimal ValueSecondOfICICI = Decimal.valueOf(ICICImid);
                    Decimal ValueThirdOfICICI = Decimal.valueOf(ICICIlarge);
                    System.debug(ValueOneOfICICI);
                    System.debug(ValueSecondOfICICI);
                    System.debug(ValueThirdOfICICI);
                    if(lifeInsurance.lifeInsuranceSumAssured >= Decimal.valueOf(ICICIMinimumValue) && lifeInsurance.lifeInsuranceSumAssured <= Decimal.valueOf(ICICImid))
                        query1 += ' AND Start_Sum_Assured__c >=: ValueOneOfICICI AND End_Sum_Assured__c <=: ValueSecondOfICICI';
                    else if(lifeInsurance.lifeInsuranceSumAssured > Decimal.valueOf(ICICImid) && lifeInsurance.lifeInsuranceSumAssured <= Decimal.valueOf(ICICIlarge))
                        query1 += ' AND Start_Sum_Assured__c >: ValueSecondOfICICI AND End_Sum_Assured__c <=: ValueThirdOfICICI';
                    System.debug(query1);
                }
                /*else if(lifeInsurance.lifeInsuranceCompanyName == 'Kotak Life'){
                    if(lifeInsurance.lifeInsuranceSumAssured != null && Label.MinimumSumAssuredKotak != null && Label.MidSumAssuredKotak != null && Label.MaxSumAssuredKotak != null ){
                        String tempsumAssured = Label.MinimumSumAssuredKotak;
                        String mid = Label.MidSumAssuredKotak;
                        String large = Label.MaxSumAssuredKotak;
                        Decimal ValueOneOfKotak = Decimal.valueOf(tempsumAssured);
                        Decimal ValueSecondOfKotak = Decimal.valueOf(mid);
                        Decimal ValueThirdOfKotak = Decimal.valueOf(large);
                        System.debug(mid+'---'+large+'---'+lifeInsurance.lifeInsuranceSumAssured+'----'+tempsumAssured);
                        
                        if(lifeInsurance.lifeInsuranceSumAssured >= Decimal.valueOf(tempsumAssured) && lifeInsurance.lifeInsuranceSumAssured <= Decimal.valueOf(mid)){
                            query1+= ' AND Start_Sum_Assured__c >=: ValueOneOfKotak AND End_Sum_Assured__c <=: ValueSecondOfKotak';
                        }
                        else if(lifeInsurance.lifeInsuranceSumAssured >= Decimal.valueOf(mid) && lifeInsurance.lifeInsuranceSumAssured <=  Decimal.valueOf(large))
                            query1+= ' AND Start_Sum_Assured__c >=: ValueSecondOfKotak AND End_Sum_Assured__c <=: ValueThirdOfKotak';
                        
                        if(gender != null)
                            query1 += ' AND Gender__c =: gender';
                        if(product != '')
                            query1 += ' AND Product__c =: product';
                        System.debug(query1);
                    }
                }*/
                
                List<Life_Insurance_Generation_Data__c> insuranceGenList = Database.query(query1);
                System.debug('-----insuranceGenList'+insuranceGenList.size());
                //System.debug('-----insuranceGenList'+insuranceGenList[0].Round_Rate__c);
                if(lifeInsurance.lifeInsuranceSumAssured != null && insuranceGenList.size() > 0 && insuranceGenList[0].Round_Rate__c != null && Label.GST != null){
                    /*if(lifeInsurance.lifeInsuranceCompanyName == 'ICICI'){
                        if(insuranceGenList.size() > 1){
                        return 'There might be no Life Insurance Generation data for Male/Female applicant. Please contact system admin.'; 
                        }
                    }*/
                    lifeInsurance.roundRate = insuranceGenList[0].Round_Rate__c;
                    lifeInsurance.lifeInsurancePremium = lifeInsurance.lifeInsuranceSumAssured * insuranceGenList[0].Round_Rate__c;
                    Decimal temp = (lifeInsurance.lifeInsurancePremium * Integer.valueOf(Label.GST))/100;
                    lifeInsurance.lifeInsurancePremium = Math.round(lifeInsurance.lifeInsurancePremium + temp);
                }
                else{
                    lifeInsurance.roundRate = 0.0;
                    lifeInsurance.lifeInsurancePremium = 0.0;
                }
                //calculateFinalFormula(Index, dob, wrapClassList[index].LifeInsuranceCompanyName, wrapClassList[index].LifeInsuranceTenure);
                //System.debug('wrapClassList'+wrapClassList);
            }
            else{
                return 'Term is outside specified Limit';
            }
            return JSON.serialize(lifeInsurance); 
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }       
    }
    
    @AuraEnabled
    public static LifeInsuranceDetails calculateBMI(String lifeInsuranceWrap){
        try{
            System.debug(lifeInsuranceWrap);
            LifeInsuranceDetails lifeInsurance = (LifeInsuranceDetails)JSON.deserialize(lifeInsuranceWrap, LifeInsuranceDetails.class);
            if(lifeInsurance.height != null && lifeInsurance.weight != null && lifeInsurance.height != 0 && lifeInsurance.weight != 0){
                Decimal heightInMeter = lifeInsurance.height/100;
                Decimal heightSquared = heightInMeter * heightInMeter;
                Decimal finalBMI =  (lifeInsurance.weight/heightSquared).setScale(2, RoundingMode.CEILING);
                System.debug(finalBMI);
                lifeInsurance.BMI = finalBMI;
                if(lifeInsurance.BMI < 18 || lifeInsurance.BMI > 29){
                    lifeInsurance.medicalrequiredBMI ='Yes';
                }
                if(lifeInsurance.BMI > 18 && lifeInsurance.BMI < 29){
                    system.debug('line 501');
                    lifeInsurance.medicalrequiredBMI ='No';
                }
            }
            System.debug(lifeInsurance);
            return lifeInsurance; 
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }       
    }
    
    @AuraEnabled
    public static String getEmployeeName(String empId) {
        try{
            String employeeName = '';
            List<Account> accList = [SELECT Name, Empl_Code__pc FROM Account WHERE Empl_Code__pc =: empId AND RecordType.Name =: 'ISFCL - Employee' LIMIT 1];
            if(accList.size() > 0 && accList[0].Empl_Code__pc != null) {
                employeeName = accList[0].Name;
            } 
            System.debug(employeeName);
            return employeeName; 
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }       
    }
    
    @AuraEnabled
    public static String getNomineeDOB(String appId, String nomineeName){
        try{
            String nomineeDOB = '';
            List<OpportunityContactRole> ocrList = [SELECT Contact.Name, Contact.Date_of_Birth__c FROM OpportunityContactRole WHERE OpportunityId =: appId 
                                                    AND Contact.Name=: nomineeName LIMIT 1];
            if(ocrList.size() > 0 && ocrList[0].Contact.Date_of_Birth__c != null) {
                nomineeDOB = String.valueOf(ocrList[0].Contact.Date_of_Birth__c);
            } 
            System.debug(nomineeDOB);
            return nomineeDOB; 
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }       
    }
    
    @AuraEnabled
    public static List<PropertyInsuranceDetails> getPropertyInsurancePremiumQuote(List<Opportunity> OpportunityList, List<CAM__c> camList, List<Property_Insurance_Generation_Data__c> propGenList, String branchPropertyInsuranceCompany){
        try{
            Decimal camBuildUpConstructionValue;
            Decimal proposedConstructionValue;
            Decimal TotalValue;
            System.debug('At 203');
            if(camlist[0].Build_Up_Construction_Value__c == null){
                camBuildUpConstructionValue = 0;
            }
            else{
                camBuildUpConstructionValue = camlist[0].Build_Up_Construction_Value__c;  
            }
            if(camlist[0].Proposed_Construction_Value__c == null){
                proposedConstructionValue = 0;   
            }
            else{
                proposedConstructionValue = camlist[0].Proposed_Construction_Value__c; 
            }
            TotalValue = camBuildUpConstructionValue + proposedConstructionValue;
            
            List<PropertyInsuranceDetails> propertyInsuranceList = new List<PropertyInsuranceDetails>();
            for(Property_Insurance_Generation_Data__c obj : propGenList){
                PropertyInsuranceDetails propertyInsuranceWrap = new PropertyInsuranceDetails();
                propertyInsuranceWrap.isSelected = false;
                propertyInsuranceWrap.propcompanyname = obj.Insurer__c;
                propertyInsuranceWrap.totalPropertyValue = String.valueOf(TotalValue);
                propertyInsuranceWrap.propertyTenure = Integer.valueOf(obj.Tenure__c);
                if(obj.Insurer__c == 'ICICI Lombard'){
                    propertyInsuranceWrap.PropertyInsurancePremium = TotalValue * obj.Rate__c;
                }
                else if(obj.Insurer__c == 'Chola'){
                    Decimal buildingPremium = TotalValue * obj.Building_Round_Rate__c;
                    Decimal contentPremium = 0.0;
                    Decimal twentyPercentOfTotalValue = TotalValue*0.20;
                    if(twentyPercentOfTotalValue < 1000000){
                        contentPremium = twentyPercentOfTotalValue * obj.Content_Round_Rate__c;
                    }
                    else{
                        contentPremium = 1000000 * obj.Content_Round_Rate__c;
                    }
                    propertyInsuranceWrap.PropertyInsurancePremium = buildingPremium + contentPremium;
                }
                Decimal temp = (propertyInsuranceWrap.PropertyInsurancePremium * Integer.valueOf(Label.GST))/100;
                propertyInsuranceWrap.PropertyInsurancePremium = Math.round(propertyInsuranceWrap.PropertyInsurancePremium + temp);
                propertyInsuranceWrap.isDisabled = false;
                propertyInsuranceList.add(propertyInsuranceWrap);
            }
            
            if(branchPropertyInsuranceCompany != null){
                PropertyInsuranceDetails selectedPropertyInsuranceWrap;
                List<PropertyInsuranceDetails> remainingPropertyInsuranceWrapList = new List<PropertyInsuranceDetails>();
                for(PropertyInsuranceDetails obj : propertyInsuranceList) {
                    if(obj.propcompanyname == branchPropertyInsuranceCompany && selectedPropertyInsuranceWrap == null){
                        selectedPropertyInsuranceWrap = obj;
                    }
                    else{
                        remainingPropertyInsuranceWrapList.add(obj);
                    }
                }
                if(selectedPropertyInsuranceWrap != null){
                    propertyInsuranceList.clear();
                    propertyInsuranceList.add(selectedPropertyInsuranceWrap);
                    propertyInsuranceList.addAll(remainingPropertyInsuranceWrapList);
                }
            }
            
            Integer option = 1;
            for(PropertyInsuranceDetails obj : propertyInsuranceList){
                obj.OptionWithCompanyName = 'Option ' + option + ' - ' + obj.propcompanyname;
                option++;
            }
            return propertyInsuranceList;    
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }       
    }
    
    @AuraEnabled
    public static String calculatePropertyInsurancePremium(String propertyInsuranceWrap) {
        try{
            System.debug(propertyInsuranceWrap);
            PropertyInsuranceDetails propertyInsurance = (PropertyInsuranceDetails)JSON.deserialize(propertyInsuranceWrap, PropertyInsuranceDetails.class);
            if(propertyInsurance.propertyTenure <= 10){
                String propertyCompanyName = propertyInsurance.propcompanyName;
                Integer propertyTenure = propertyInsurance.propertyTenure;
                String query = 'SELECT Id, Rate__c, Building_Round_Rate__c, Content_Round_Rate__c, Tenure__c, Insurer__c from Property_Insurance_Generation_Data__c WHERE Insurer__c  =: propertyCompanyName';
                if(propertyTenure != NULL && propertyTenure != 0){
                    query += ' AND Tenure__c =: propertyTenure';
                }
                System.debug(query);
                List<Property_Insurance_Generation_Data__c> propGenList = Database.query(query);
                System.debug(propGenList);
                if(propGenList.size() > 0){
                    if(propertyInsurance.propcompanyname != 'Chola'){
                        propertyInsurance.PropertyInsurancePremium = Decimal.valueOf(propertyInsurance.totalPropertyValue) * propGenList[0].Rate__c;
                    }
                    else{
                        Decimal buildingPremium = Decimal.valueOf(propertyInsurance.totalPropertyValue) * propGenList[0].Building_Round_Rate__c;
                        Decimal contentPremium = 0.0;
                        Decimal twentyPercentOfTotalValue = Decimal.valueOf(propertyInsurance.totalPropertyValue)*0.20;
                        if(twentyPercentOfTotalValue < 1000000){
                            contentPremium = twentyPercentOfTotalValue * propGenList[0].Content_Round_Rate__c;
                        }
                        else{
                            contentPremium = 1000000 * propGenList[0].Content_Round_Rate__c;
                        }
                        propertyInsurance.PropertyInsurancePremium = buildingPremium + contentPremium;
                    }
                    Decimal temp = (propertyInsurance.PropertyInsurancePremium * Integer.valueOf(Label.GST))/100;
                    propertyInsurance.PropertyInsurancePremium = Math.round(propertyInsurance.PropertyInsurancePremium + temp);
                }
            }
            else{
                return 'Term is outside specified Limit';
            }
            return JSON.serialize(propertyInsurance);
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<HealthInsuranceDetails> getHealthInsurancePremiumQuote(String branchHealthInsuranceCompany){
        try{
            List<HealthInsuranceDetails> healthInsuranceList = new List<HealthInsuranceDetails>();
            Map<String, Health_Insurance_Generation__mdt> healthInsuranceGenerationMap = new Map<String, Health_Insurance_Generation__mdt>();
            for(Health_Insurance_Generation__mdt obj : [Select Id, Insurer__c, Tenure__c, Sum_Assured__c, Premium__c, Nominee_Required__c from Health_Insurance_Generation__mdt]){
                System.debug('====>>>'+healthInsuranceGenerationMap.size());
                System.debug('====>>>'+healthInsuranceGenerationMap.containskey(obj.Insurer__c));
                if(!healthInsuranceGenerationMap.containskey(obj.Insurer__c)){
                    HealthInsuranceDetails healthInsuranceWrap = new HealthInsuranceDetails();
                    healthInsuranceWrap.isSelected = false;
                    healthInsuranceWrap.HealthInsuranceCompanyName = obj.Insurer__c;
                    healthInsuranceWrap.HealthInsuranceTenure = obj.Tenure__c;
                    healthInsuranceWrap.HealthInsuranceSumAssured = obj.Sum_Assured__c;
                    healthInsuranceWrap.HealthInsurancePremium = obj.Premium__c;
                    healthInsuranceWrap.HealthInsuranceNominee = obj.Nominee_Required__c;
                    healthInsuranceList.add(healthInsuranceWrap);
                }
                healthInsuranceGenerationMap.put(obj.Insurer__c, obj);
            }
            
            if(branchHealthInsuranceCompany != null){
                HealthInsuranceDetails selectedHealthInsuranceWrap;
                List<HealthInsuranceDetails> remainingHealthInsuranceWrapList = new List<HealthInsuranceDetails>();
                for(HealthInsuranceDetails obj : healthInsuranceList) {
                    if(obj.HealthInsuranceCompanyName == branchHealthInsuranceCompany && selectedHealthInsuranceWrap == null){
                        selectedHealthInsuranceWrap = obj;
                    }
                    else{
                        remainingHealthInsuranceWrapList.add(obj);
                    }
                }
                if(selectedHealthInsuranceWrap != null){
                    healthInsuranceList.clear();
                    healthInsuranceList.add(selectedHealthInsuranceWrap);
                    healthInsuranceList.addAll(remainingHealthInsuranceWrapList);
                }
            }
            
            Integer option = 1;
            for(HealthInsuranceDetails obj : healthInsuranceList){
                obj.OptionWithCompanyName = 'Option ' + option + ' - ' + obj.HealthInsuranceCompanyName;
                option++;
            }
            /*HealthInsuranceDetails healthInsuranceStarWrap = new HealthInsuranceDetails();
            healthInsuranceStarWrap.isSelected = false;
            healthInsuranceStarWrap.OptionWithCompanyName = 'Option 2 - Star Health Insurance';
            healthInsuranceStarWrap.HealthInsuranceCompanyName = 'Star Health Insurance';
            healthInsuranceStarWrap.HealthInsuranceTenure = '2';
            healthInsuranceStarWrap.HealthInsuranceSumAssured = '3 Lakh';
            healthInsuranceStarWrap.HealthInsurancePremium = 15985;
            healthInsuranceStarWrap.HealthInsuranceNominee = 'Yes';
            healthInsuranceStarWrap.isDisabled = false;
            healthInsuranceList.add(healthInsuranceStarWrap);*/
            return healthInsuranceList;
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String calculateHealthInsurancePremium(String healthInsuranceWrap){
        try{
            System.debug(healthInsuranceWrap);
            HealthInsuranceDetails healthInsurance = (HealthInsuranceDetails)JSON.deserialize(healthInsuranceWrap, HealthInsuranceDetails.class);
            List<Health_Insurance_Generation__mdt> healthInsuranceGenerationList = [Select Id, Insurer__c, Tenure__c, Sum_Assured__c, Premium__c, Nominee_Required__c 
                                                                                    from Health_Insurance_Generation__mdt where Tenure__c =: healthInsurance.healthInsuranceTenure
                                                                                    AND Sum_Assured__c =: healthInsurance.healthInsuranceSumAssured LIMIT 1];
            if(!healthInsuranceGenerationList.isEmpty()){
                healthInsurance.HealthInsurancePremium = healthInsuranceGenerationList[0].Premium__c;
            }
            else{
                healthInsurance.HealthInsurancePremium = 0;
            }
        	return JSON.serialize(healthInsurance);
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Added by Shivam Agarwal on 10-04-2023
    /*@AuraEnabled
    public static List<CalculateInsurance> calculateFinalFormula(String calculateInsurance, Decimal camLoanAmount, Integer parentIndex, Integer childIndex){
        List<CalculateInsurance> calculateInsuranceList = (List<CalculateInsurance>)JSON.deserialize(calculateInsurance, List<CalculateInsurance>.class);
        try{
            System.debug(calculateInsuranceList);
            System.debug(camLoanAmount);
            System.debug(parentIndex);
            System.debug(childIndex);
            if(camLoanAmount != null){
                System.debug(calculateInsuranceList[parentIndex]);
                Decimal PropertyInsurancePremium = 0.0;
                Decimal HealthInsurancePremium = 0.0;
                if(!calculateInsuranceList[parentIndex].PropertyInsuranceList.isEmpty() && calculateInsuranceList[parentIndex].PropertyInsuranceList[childIndex].isSelected && calculateInsuranceList[parentIndex].PropertyInsuranceList[childIndex].PropertyInsurancePremium == null){
                    PropertyInsurancePremium = 0.0;
                }
                
                if(!calculateInsuranceList[parentIndex].HealthInsuranceList.isEmpty() && calculateInsuranceList[parentIndex].HealthInsuranceList[childIndex].isSelected && calculateInsuranceList[parentIndex].HealthInsuranceList[childIndex].HealthInsurancePremium == null){
                    HealthInsurancePremium = 0.0;
                }
                
                if(calculateInsuranceList[parentIndex].lifeInsurance == 'Yes'){
                    Double finalRate = calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].roundRate + (calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].roundRate * Integer.valueOf(Label.GST)/100);
                    System.debug('finalRate = '+finalRate);
                    calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].finalRate = finalRate;
                    calculateInsuranceList[parentIndex].FinalLifeAssuredAmount = Math.round((camLoanAmount + PropertyInsurancePremium + HealthInsurancePremium)/(1-finalRate));
                    System.debug('camLoanAmount==>>'+camLoanAmount);
                    System.debug('calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].lifeInsuranceSumAssured==>>' + calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].lifeInsuranceSumAssured);
                    if(camLoanAmount > calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].lifeInsuranceSumAssured){
                        calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered = calculateInsuranceList[parentIndex].LifeInsuranceList[childIndex].lifeInsuranceSumAssured;
                    }
                    else{
                        calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered = calculateInsuranceList[parentIndex].FinalLifeAssuredAmount;
                    }
                    calculateInsuranceList[parentIndex].LifeInsurancePremium2 = Math.round(calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered * finalRate);
                    System.debug('calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered==>>' + calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered);
                }
                calculateInsuranceList[parentIndex].TotalPremiumAmount = calculateInsuranceList[parentIndex].LifeInsurancePremium2 + PropertyInsurancePremium + HealthInsurancePremium;
                //isCalculateFinalResultWrap = 'No';
                
                //calculateFinalResult();
            }
            else{
                System.debug('At new insurance');
                calculateInsuranceList[parentIndex].FinalLifeAssuredAmount = 0.0;
                calculateInsuranceList[parentIndex].LifeInsuranceAmountConsidered = 0.0;
                calculateInsuranceList[parentIndex].LifeInsurancePremium2 = 0.0;
                calculateInsuranceList[parentIndex].TotalPremiumAmount = 0.0;
            }
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
        }
        return calculateInsuranceList;
    }*/
    //End by Shivam Agarwal on 10-04-2023
    
    @AuraEnabled
    public static List<CalculateInsurance> getAllApplicantPremium(String calculateInsurance){
        try{
            List<CalculateInsurance> calculateInsuranceList = (List<CalculateInsurance>)JSON.deserialize(calculateInsurance, List<CalculateInsurance>.class);
            for(CalculateInsurance calculateInsuranceWrap : calculateInsuranceList){
                calculateInsuranceWrap.FinalLifeInsurancePremium = '';
                calculateInsuranceWrap.FinalPropertyInsurancePremium = '';
                calculateInsuranceWrap.FinalHealthInsurancePremium = '';
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && !calculateInsuranceWrap.LifeInsuranceList.isEmpty()){
                    for(LifeInsuranceDetails lifeWrap : calculateInsuranceWrap.LifeInsuranceList){
                        if(lifeWrap.isSelected){
                            if(lifeWrap.LifeInsurancePremium != null){
                            	calculateInsuranceWrap.FinalLifeInsuranceCompanyName = lifeWrap.lifeInsuranceCompanyName;
                            	calculateInsuranceWrap.FinalLifeInsurancePremium = String.valueof(lifeWrap.LifeInsurancePremium);
                            	//calculateInsuranceWrap.FinalLifeInsurancePremium = lifeWrap.lifeInsuranceCompanyName + ' - ₹ ' + String.format('{0,number,#,###}', new List<Object>{ lifeWrap.LifeInsurancePremium });
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.PropertyInsurance == 'Yes' && !calculateInsuranceWrap.PropertyInsuranceList.isEmpty()){
                    for(PropertyInsuranceDetails propertyWrap : calculateInsuranceWrap.PropertyInsuranceList){
                        if(propertyWrap.isSelected){
                            if(propertyWrap.PropertyInsurancePremium != null){
                                calculateInsuranceWrap.FinalPropertyInsuranceCompanyName = propertyWrap.propcompanyName;
                                calculateInsuranceWrap.FinalPropertyInsurancePremium = String.valueof(propertyWrap.PropertyInsurancePremium);
                            	//calculateInsuranceWrap.FinalPropertyInsurancePremium = propertyWrap.propcompanyName + ' - ₹ ' + propertyWrap.PropertyInsurancePremium;
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.HealthInsuranceRequired == 'Yes' && !calculateInsuranceWrap.HealthInsuranceList.isEmpty()){
                    for(HealthInsuranceDetails healthWrap : calculateInsuranceWrap.HealthInsuranceList){
                        if(healthWrap.isSelected){
                            if(healthWrap.HealthInsurancePremium != null){
                                calculateInsuranceWrap.FinalHealthInsuranceCompanyName = healthWrap.HealthInsuranceCompanyName;
                                calculateInsuranceWrap.FinalHealthInsurancePremium = String.valueof(healthWrap.HealthInsurancePremium);
                            	//calculateInsuranceWrap.FinalHealthInsurancePremium = healthWrap.HealthInsuranceCompanyName + ' - ₹ ' + healthWrap.HealthInsurancePremium;
                            }
                        }
                    }
                }
            }
        	return calculateInsuranceList;
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Added by Shivam Agarwal on 24-04-2023
    @AuraEnabled
    public static List<CalculateInsurance> calculateFinalResult(String calculateInsurance, List<Opportunity> OpportunityList, Decimal camLoanAmount, Boolean isJointLifeInsurance){
        try{
            System.debug('vnsvbnbvsjbvksjbvskjbvskjbvskjb');
            List<CalculateInsurance> calculateInsuranceList = (List<CalculateInsurance>)JSON.deserialize(calculateInsurance, List<CalculateInsurance>.class);
            System.debug(calculateInsuranceList);
            System.debug(camLoanAmount);
            Decimal totalAmount = 0.0;
            Decimal totalRate = 0.0;
            for(CalculateInsurance calculateInsuranceWrap : calculateInsuranceList){
                Decimal PropertyInsurancePremium = 0.0;
                Decimal HealthInsurancePremium = 0.0;
                Decimal FinalRate = 0.0;
                String LifeCover = '';
                if(calculateInsuranceWrap.PropertyInsurance == 'Yes' && !calculateInsuranceWrap.PropertyInsuranceList.isEmpty()){
                    for(PropertyInsuranceDetails propertyWrap : calculateInsuranceWrap.PropertyInsuranceList){
                        if(propertyWrap.isSelected){
                            if(propertyWrap.PropertyInsurancePremium != null){
                                PropertyInsurancePremium = propertyWrap.PropertyInsurancePremium;
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.HealthInsuranceRequired == 'Yes' && !calculateInsuranceWrap.HealthInsuranceList.isEmpty()){
                    for(HealthInsuranceDetails healthWrap : calculateInsuranceWrap.HealthInsuranceList){
                        if(healthWrap.isSelected){
                            if(healthWrap.HealthInsurancePremium != null){
                                HealthInsurancePremium = healthWrap.HealthInsurancePremium;
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && !calculateInsuranceWrap.LifeInsuranceList.isEmpty()){
                    for(LifeInsuranceDetails lifeWrap : calculateInsuranceWrap.LifeInsuranceList){
                        if(lifeWrap.isSelected){
                            System.debug('finalRate = '+lifeWrap.finalRate);
                            System.debug('roundRate = '+lifeWrap.roundRate);
                            if(lifeWrap.finalRate != null && lifeWrap.finalRate == 0.0){
                                lifeWrap.finalRate = lifeWrap.roundRate + (lifeWrap.roundRate * Integer.valueOf(Label.GST)/100);
                                System.debug('finalRate = '+lifeWrap.finalRate);
                            }
                            if(lifeWrap.finalRate != null && lifeWrap.finalRate > 0.0){
                                FinalRate = lifeWrap.finalRate;
                            }
                            if(lifeWrap.LifeCover != null){
                                LifeCover = lifeWrap.lifeCover;
                            }
                        }
                    }
                }
                System.debug('wrap.LifeCover = ' + LifeCover);
                System.debug('wrap.FinalRate = ' + FinalRate);
                System.debug('wrap.PropertyInsurancePremium = ' + PropertyInsurancePremium);
                System.debug('wrap.HealthInsurancePremium = ' + HealthInsurancePremium);
                System.debug('total Premium = ' + (PropertyInsurancePremium + HealthInsurancePremium));
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && LifeCover == 'Full'){
                    totalRate = totalRate + FinalRate;
                }
                totalAmount = totalAmount + Math.round(PropertyInsurancePremium + HealthInsurancePremium);
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && LifeCover == 'Less'){
                    totalAmount = totalAmount + calculateInsuranceWrap.LifeInsurancePremium2;
                }
            }
            System.debug('totalAmount = ' + totalAmount);
            totalAmount = totalAmount + camLoanAmount;
            System.debug('totalAmount = ' + totalAmount);
            System.debug('totalRate = ' + totalRate);
            
            for(CalculateInsurance calculateInsuranceWrap : calculateInsuranceList){
                Decimal PropertyInsurancePremium = 0.0;
                Decimal HealthInsurancePremium = 0.0;
                Decimal FinalRate = 0.0;
                String LifeCover = '';
                Decimal LifeInsuranceSumAssured = 0.0;
                if(calculateInsuranceWrap.PropertyInsurance == 'Yes' && !calculateInsuranceWrap.PropertyInsuranceList.isEmpty()){
                    for(PropertyInsuranceDetails propertyWrap : calculateInsuranceWrap.PropertyInsuranceList){
                        if(propertyWrap.isSelected){
                            if(propertyWrap.PropertyInsurancePremium != null){
                                PropertyInsurancePremium = propertyWrap.PropertyInsurancePremium;
                                //calculateInsuranceWrap.FinalPropertyInsurancePremium = propertyWrap.PropertyInsurancePremium + ' - ' + propertyWrap.propcompanyName;
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.HealthInsuranceRequired == 'Yes' && !calculateInsuranceWrap.HealthInsuranceList.isEmpty()){
                    for(HealthInsuranceDetails healthWrap : calculateInsuranceWrap.HealthInsuranceList){
                        if(healthWrap.isSelected){
                            if(healthWrap.HealthInsurancePremium != null){
                                HealthInsurancePremium = healthWrap.HealthInsurancePremium;
                                //calculateInsuranceWrap.FinalHealthInsurancePremium = healthWrap.HealthInsurancePremium + ' - ' + healthWrap.HealthInsuranceCompanyName;
                            }
                        }
                    }
                }
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && !calculateInsuranceWrap.LifeInsuranceList.isEmpty()){
                    for(LifeInsuranceDetails lifeWrap : calculateInsuranceWrap.LifeInsuranceList){
                        if(lifeWrap.isSelected){
                            if(lifeWrap.finalRate != null && lifeWrap.finalRate > 0.0){
                                FinalRate = lifeWrap.finalRate;
                            }
                            if(lifeWrap.LifeCover != null){
                                LifeCover = lifeWrap.lifeCover;
                            }
                            if(lifeWrap.lifeInsuranceSumAssured != null){
                                LifeInsuranceSumAssured = lifeWrap.lifeInsuranceSumAssured;
                            }
                            //calculateInsuranceWrap.FinalLifeInsurancePremium = lifeWrap.LifeInsurancePremium + ' - ' + lifeWrap.lifeInsuranceCompanyName;
                        }
                    }
                }
                if(LifeCover == 'Full'){
                    calculateInsuranceWrap.FinalLifeAssuredAmount = Math.round(totalAmount / (1 - totalRate));
                    if(camLoanAmount > LifeInsuranceSumAssured){
                        calculateInsuranceWrap.LifeInsuranceAmountConsidered = LifeInsuranceSumAssured;
                    }
                    else{
                        calculateInsuranceWrap.LifeInsuranceAmountConsidered = calculateInsuranceWrap.FinalLifeAssuredAmount;
                    }
                    calculateInsuranceWrap.LifeInsurancePremium2 = Math.round(calculateInsuranceWrap.LifeInsuranceAmountConsidered * FinalRate);
                    if(isJointLifeInsurance){
                        calculateInsuranceWrap.LifeInsurancePremium2 = Math.round(calculateInsuranceWrap.LifeInsurancePremium2 - (calculateInsuranceWrap.LifeInsurancePremium2*5)/100);
                    }
                    calculateInsuranceWrap.TotalPremiumAmount = calculateInsuranceWrap.LifeInsurancePremium2 + PropertyInsurancePremium + HealthInsurancePremium;
                }
                if(LifeCover == 'Less'){
                    calculateInsuranceWrap.FinalLifeAssuredAmount = LifeInsuranceSumAssured;
                    if(camLoanAmount > LifeInsuranceSumAssured){
                        calculateInsuranceWrap.LifeInsuranceAmountConsidered = LifeInsuranceSumAssured;
                    }
                    else{
                        calculateInsuranceWrap.LifeInsuranceAmountConsidered = calculateInsuranceWrap.FinalLifeAssuredAmount;
                    }
                    calculateInsuranceWrap.LifeInsurancePremium2 = Math.round(calculateInsuranceWrap.LifeInsuranceAmountConsidered * FinalRate);
                    if(isJointLifeInsurance){
                        calculateInsuranceWrap.LifeInsurancePremium2 = Math.round(calculateInsuranceWrap.LifeInsurancePremium2 - (calculateInsuranceWrap.LifeInsurancePremium2*5)/100);
                    }
                    calculateInsuranceWrap.TotalPremiumAmount = calculateInsuranceWrap.LifeInsurancePremium2 + PropertyInsurancePremium + HealthInsurancePremium;
                }
                if(LifeCover == null || LifeCover == ''){
                    calculateInsuranceWrap.TotalPremiumAmount = calculateInsuranceWrap.LifeInsurancePremium2 + PropertyInsurancePremium + HealthInsurancePremium;  
                }
                System.debug('wrap.FinalLifeAssuredAmount = ' + calculateInsuranceWrap.FinalLifeAssuredAmount);
                System.debug('wrap.LifeInsuranceAmountConsidered = ' + calculateInsuranceWrap.LifeInsuranceAmountConsidered);
                System.debug('wrap.LifeInsurancePremium2 = ' + calculateInsuranceWrap.LifeInsurancePremium2);
                System.debug('wrap.TotalPremiumAmount = ' + calculateInsuranceWrap.TotalPremiumAmount);
                
                /* 
                Author : Shivam Agarwal
                Description : Medical Required Yes or No based on below conditions.	
                ModifiedDate : 23/09/2024
                */
                //***************************************START HERE*************************************//
                Integer age = 0;
                List<String> parts = calculateInsuranceWrap.DOB.split('/');
                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                Date dateOfBirth = Date.newInstance(year, month, day);
                Integer numberOfdays = dateOfBirth.daysBetween(OpportunityList[0].Sanctioned_Date__c);
                age = Integer.valueOf(numberOfdays/365);
                System.debug('LoanType===>>>' + OpportunityList[0].Loan_Type__c);
                if(calculateInsuranceWrap.LifeInsurance == 'Yes' && !calculateInsuranceWrap.LifeInsuranceList.isEmpty()){
                    for(LifeInsuranceDetails lifeWrap : calculateInsuranceWrap.LifeInsuranceList){
                        if(lifeWrap.isSelected){
                            if(calculateInsuranceWrap.LifeInsuranceAmountConsidered != NULL){
                                if(lifeWrap.lifeInsuranceCompanyName == 'ICICI'){
                                    if(age >= 18 && age <= 40){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 22500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 40 && age <= 45){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 17500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 45 && age <= 50){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 10000000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 50 && age <= 55){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 7500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 55 && age <= 60){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 2500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else{
                                        lifeWrap.medicalrequiredLIAC ='No';
                                    }
                                }
                                if(lifeWrap.lifeInsuranceCompanyName == 'Axis Max Life Insurance'){
                                    if(age >= 18 && age <= 50){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 10000000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 50 && age <= 55){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 7500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else if(age > 55 && age <= 60){
                                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered <= 2500000)
                                            lifeWrap.medicalrequiredLIAC ='No';
                                        else
                                            lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                    else{
                                        lifeWrap.medicalrequiredLIAC ='Yes';
                                    }
                                }
                            }
                            System.debug('wrap.medicalrequiredBMI = ' + lifeWrap.medicalrequiredBMI);
                            System.debug('wrap.medicalrequiredLIAC = ' + lifeWrap.medicalrequiredLIAC);
                            
                            if(lifeWrap.medicalrequiredBMI != NULL && lifeWrap.medicalrequiredLIAC != NULL){
                                if(lifeWrap.medicalrequiredBMI != NULL && lifeWrap.medicalrequiredLIAC == ''){
                                    lifeWrap.medicalrequired = lifeWrap.medicalrequiredBMI;
                                }
                                else if(lifeWrap.medicalrequiredBMI == '' && lifeWrap.medicalrequiredLIAC != NULL){
                                    lifeWrap.medicalrequired = lifeWrap.medicalrequiredLIAC;
                                }
                                else if(lifeWrap.medicalrequiredBMI == 'No' && lifeWrap.medicalrequiredLIAC == 'No'){
                                    lifeWrap.medicalrequired = 'No';
                                }
                                else{
                                    lifeWrap.medicalrequired = 'Yes';
                                }
                            }
                            System.debug('wrap.medicalrequired = ' + lifeWrap.medicalrequired);
                        }
                    }
                }
                //***************************************END HERE*************************************//
            }
        	return calculateInsuranceList;
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    //End by Shivam Agarwal on 24-04-2023
    
    @AuraEnabled
    public static List<Wrapper> saveCalculateInsuranceData(String appId, String calculateInsurance, List<Opportunity> OpportunityList, Decimal camLoanAmount, Boolean isCalculateButtonClick, Boolean isJointLifeInsurance, Boolean isBHOthers, String insuranceJustification){
        try{
            Savepoint sp = Database.setSavepoint();
            List<Wrapper> wrapClassList = new List<wrapper>();
            String errorMessage = '';
            Decimal totalPremiumAmount = 0;
        	if(!isCalculateButtonClick){
                errorMessage = 'Please click on Calculate button to continue';
            }
            List<Insurance_Generation_Data__c>  tempInsuranceGenList = new List<Insurance_Generation_Data__c>();
            List<Disbursement__c> alreadyDMSanctionList = [SELECT id from Disbursement__c WHERE Application__c =: appId AND Tranch_Details__c = 'First' AND 
                                                           (Disb_Status__c = 'Payment Under Process' OR Disb_Status__c = 'Payment Processed' OR 
                                                            Disb_Status__c = 'Handed over customer')];
            System.debug('AlreadyDm'+alreadyDMSanctionList);
            if(alreadyDMSanctionList.size()>0){
                System.debug('Aready exist DM');
                errorMessage = 'You can\'t edit Insurance, as DM already processed';
            }
            else{
                List<CalculateInsurance> calculateInsuranceList = (List<CalculateInsurance>)JSON.deserialize(calculateInsurance, List<CalculateInsurance>.class);
                if(calculateInsuranceList.size() > 0){
                    for(CalculateInsurance calculateInsuranceWrap : calculateInsuranceList){
                        System.debug('calculateInsuranceWrap: ' + calculateInsuranceWrap);
                        //--------Added by @Siddharth Gupta on 13-04-2023--------
                        Integer age = 0;
                        List<String> parts = calculateInsuranceWrap.DOB.split('/');
                        Integer month = Integer.valueOf(parts[0]);
                        Integer day = Integer.valueOf(parts[1]);
                        Integer year = Integer.valueOf(parts[2]);
                        Date dateOfBirth = Date.newInstance(year, month, day);
                        Integer numberOfdays = dateOfBirth.daysBetween(OpportunityList[0].Sanctioned_Date__c);
                        age = Integer.valueOf(numberOfdays/365);
                        System.debug('ageAge1575:: ' + age);
                        System.debug('HealthInsuranceRequired:: ' + calculateInsuranceWrap.HealthInsuranceRequired);
                        if(age > 65 && calculateInsuranceWrap.HealthInsuranceRequired == 'Yes'){
                            errorMessage = 'Health Insurance cannot be given as the applicant\'s age is above 65 years';
                        }
                        if(calculateInsuranceWrap.HealthInsuranceRequired == 'Yes' && !calculateInsuranceWrap.HealthInsuranceList.isEmpty()){
                            for(HealthInsuranceDetails healthWrap : calculateInsuranceWrap.HealthInsuranceList){
                                if(healthWrap.isSelected){
                                    if(String.isBlank(healthWrap.HealthInsuranceNominee) || String.isBlank(healthWrap.HealthInsuranceNomineeName) || (healthWrap.HealthInsuranceNomineeDOB == null) || String.isBlank(healthWrap.HealthInsuranceNomineeGender)){   
                                        errorMessage = 'Fill Health Insurance Nominee details';
                                    }
                                }
                            }
                        }
                        //--------End by @Siddharth Gupta on 13-04-2023--------
                    
                    	Insurance_Generation_Data__c igd = new Insurance_Generation_Data__c();
                        if(calculateInsuranceWrap.insuranceId != ''){
                            igd.Id = calculateInsuranceWrap.insuranceId;
                        }
                        igd.Application__c = calculateInsuranceWrap.application; 
                        igd.Contact__c = calculateInsuranceWrap.con;
                        igd.Role__c = calculateInsuranceWrap.applicantDetails;
                        igd.Applicant_Name__c = calculateInsuranceWrap.applicantName;    
                        if(calculateInsuranceWrap.DOB != null) igd.Date_of_Birth__c = dateOfBirth;  
                        igd.Gender__c = calculateInsuranceWrap.gender;
                        igd.Life_Insurance__c = calculateInsuranceWrap.lifeInsurance;
                        if(calculateInsuranceWrap.lifeInsurance == 'Yes' && !calculateInsuranceWrap.LifeInsuranceList.isEmpty()){
                            for(LifeInsuranceDetails lifeWrap : calculateInsuranceWrap.LifeInsuranceList){
                                if(lifeWrap.isSelected){
                                    igd.Life_Cover__c = lifeWrap.lifeCover;
                                    if(lifeWrap.RoundRate != null) igd.Round_Rate__c = lifeWrap.RoundRate;
                                    igd.Life_Insurance_Company_Name__c = lifeWrap.lifeInsuranceCompanyName;
                                    igd.Life_Insurance_Tenure__c = lifeWrap.lifeInsuranceTenure;
                                    igd.Life_Insurance_Sum_Assured__c = lifeWrap.lifeInsuranceSumAssured;
                                    // Added by Shivam Agarwal on 13-04-2023
                                    if(lifeWrap.lifeInsuranceSumAssured > camLoanAmount){
                                        errorMessage = 'Life Insurance sum assured cannot be greater than sanction amount';
                                    }
                                    // End by Shivam Agarwal on 13-04-2023
                                    // Added by Shivam Agarwal on 10-07-2023
                                    if(!isJointLifeInsurance && !isBHOthers){
                                        if(lifeWrap.lifeInsuranceSumAssured == camLoanAmount && calculateInsuranceWrap.LifeInsurancePremium2 <= lifeWrap.LifeInsurancePremium){
                                            errorMessage = 'Please check data entry in Insurance calc / Refresh the Insurance Calculator';
                                        }
                                        if(lifeWrap.lifeInsuranceSumAssured < camLoanAmount && calculateInsuranceWrap.LifeInsurancePremium2 != lifeWrap.LifeInsurancePremium){
                                            errorMessage = 'Please check data entry in Insurance calc / Refresh the Insurance Calculator';
                                        }
                                    }
                                    // End by Shivam Agarwal on 10-07-2023
                                    igd.Life_Insurance_Premium__c = lifeWrap.lifeInsurancePremium;
                                    igd.Employee_Id__c = lifeWrap.EmployeeId;
                                    igd.Name_of_employee_of_MPH__c = lifeWrap.EmployeeName;
                                    igd.Height__c = lifeWrap.height;
                                    igd.Weight__c = lifeWrap.weight;
                                    igd.BMI1__c = lifeWrap.BMI;
                                    igd.Medicals_Required__c = lifeWrap.medicalrequired;
                                    if(lifeWrap.medicalaccepted == 'None')
                                        igd.Medicals_Accepted__c = null;
                                    else
                                        igd.Medicals_Accepted__c = lifeWrap.medicalaccepted;
                                    igd.Medical_Insurance_Premium__c = lifeWrap.MedicalInsurancePremium;
                                    if(lifeWrap.nomineeName != null) igd.Nominee_Name__c = lifeWrap.nomineeName;
                                    if(lifeWrap.nomineeDOB == null || lifeWrap.nomineeDOB == ''){
                                        errorMessage = 'Please fill Nominee DOB.';
                                    }
                                    else{
                                        igd.Nominee_DOB__c = Date.valueOf(lifeWrap.nomineeDOB);
                                    }
                                    System.debug(lifeWrap.relationship+'====relationship===>>'+lifeWrap.relationship);
                                    if(lifeWrap.relationship != null){
                                        if(lifeWrap.relationship == null || lifeWrap.relationship == '' || lifeWrap.relationship == 'None'){
                                            errorMessage = 'Please select Relationship with Insured';
                                        }
                                        else{
                                            igd.Relationship_with_Insured__c = lifeWrap.relationship;
                                        }
                                    }
                                    igd.Accidental_Death_Insurance__c = lifeWrap.accidentalDeathInsurance;
                                    igd.Accidental_Death_Insurance_Premium__c = lifeWrap.AccidentalDeathInsurancePremium;
                                }
                                if(!lifeWrap.isSelected){
                                    igd.Life_Cover_2__c = lifeWrap.lifeCover;
                                    if(lifeWrap.RoundRate != null) igd.Round_Rate_2__c = lifeWrap.RoundRate;
                                    igd.Life_Insurance_Company_Name_2__c = lifeWrap.lifeInsuranceCompanyName;
                                    igd.Life_Insurance_Tenure_2__c = lifeWrap.lifeInsuranceTenure;
                                    igd.Life_Insurance_Sum_Assured_2__c = lifeWrap.lifeInsuranceSumAssured;
                                    // Added by Shivam Agarwal on 13-04-2023
                                    if(lifeWrap.lifeInsuranceSumAssured > camLoanAmount){
                                        //errorMessage = 'Life Insurance sum assured cannot be greater than sanction amount';
                                    }
                                    // End by Shivam Agarwal on 13-04-2023
                                    // Added by Shivam Agarwal on 10-07-2023
                                    if(lifeWrap.lifeInsuranceSumAssured == camLoanAmount && calculateInsuranceWrap.LifeInsurancePremium2 <= lifeWrap.LifeInsurancePremium){
                                        //errorMessage = 'Please check data entry in Insurance calc / Refresh the Insurance Calculator';
                                    }
                                    if(lifeWrap.lifeInsuranceSumAssured < camLoanAmount && calculateInsuranceWrap.LifeInsurancePremium2 != lifeWrap.LifeInsurancePremium){
                                        //errorMessage = 'Please check data entry in Insurance calc / Refresh the Insurance Calculator';
                                    }
                                    // End by Shivam Agarwal on 10-07-2023
                                    igd.Life_Insurance_Premium_Option_2__c = lifeWrap.lifeInsurancePremium;
                                    igd.Employee_Id_2__c = lifeWrap.EmployeeId;
                                    igd.Name_of_employee_of_MPH_2__c = lifeWrap.EmployeeName;
                                    igd.Height_2__c = lifeWrap.height;
                                    igd.Weight_2__c = lifeWrap.weight;
                                    igd.BMI_2__c = lifeWrap.BMI;
                                    igd.Medicals_Required_2__c = lifeWrap.medicalrequired;
                                    if(lifeWrap.medicalaccepted == 'None')
                                        igd.Medicals_Accepted_2__c = null;
                                    else
                                        igd.Medicals_Accepted_2__c = lifeWrap.medicalaccepted;
                                    igd.Medical_Insurance_Premium_2__c = lifeWrap.MedicalInsurancePremium;
                                    if(lifeWrap.nomineeName != null) igd.Nominee_Name_2__c = lifeWrap.nomineeName;
                                    if(lifeWrap.nomineeDOB == null || lifeWrap.nomineeDOB == ''){
                                        //errorMessage = 'Please fill Nominee DOB.';
                                    }
                                    else{
                                        igd.Nominee_DOB_2__c = Date.valueOf(lifeWrap.nomineeDOB);
                                    }
                                    if(lifeWrap.relationship != null){
                                        if(lifeWrap.relationship == null || lifeWrap.relationship == '' || lifeWrap.relationship == 'None'){
                                            //errorMessage = 'Please select Relationship with Insured';
                                        }
                                        else{
                                            igd.Relationship_with_Insured_2__c = lifeWrap.relationship;
                                        }
                                    }
                                    igd.Accidental_Death_Insurance__c = lifeWrap.accidentalDeathInsurance;
                                    igd.Accidental_Death_Insurance_Premium__c = lifeWrap.AccidentalDeathInsurancePremium;
                                }
                            }
                        }
                    
                        igd.Property_Insurance_Required__c = calculateInsuranceWrap.PropertyInsurance;
                        if(calculateInsuranceWrap.PropertyInsurance == 'Yes' && !calculateInsuranceWrap.PropertyInsuranceList.isEmpty()){
                            for(PropertyInsuranceDetails propertyWrap : calculateInsuranceWrap.PropertyInsuranceList){
                                if(propertyWrap.isSelected){
                                    if(propertyWrap.propcompanyname != null) igd.Property_Insurance_Company_Name__c = propertyWrap.propcompanyname;
                                    if(propertyWrap.totalPropertyValue != null && propertyWrap.totalPropertyValue != '') igd.Total_Property_Value__c = Decimal.valueof(propertyWrap.totalPropertyValue);
                                    if(propertyWrap.propertyTenure != null) igd.Property_Tenure__c = propertyWrap.propertyTenure;
                                    igd.Property_Insurance_Premium__c = propertyWrap.PropertyInsurancePremium;
                                }
                                if(!propertyWrap.isSelected){
                                    if(propertyWrap.propcompanyname != null) igd.Property_Insurance_Company_Name_2__c = propertyWrap.propcompanyname;
                                    if(propertyWrap.totalPropertyValue != null && propertyWrap.totalPropertyValue != '') igd.Total_Property_Value_2__c = Decimal.valueof(propertyWrap.totalPropertyValue);
                                    if(propertyWrap.propertyTenure != null) igd.Property_Tenure_2__c = propertyWrap.propertyTenure;
                                    igd.Property_Insurance_Premium_2__c = propertyWrap.PropertyInsurancePremium;
                                }
                            }
                        }
                        
                        igd.Health_Insurance_Required__c = calculateInsuranceWrap.healthInsuranceRequired;
                        if(calculateInsuranceWrap.healthInsuranceRequired == 'Yes' && !calculateInsuranceWrap.HealthInsuranceList.isEmpty()){
                            System.debug('calculateInsuranceWrap.HealthInsuranceList===>>>'+calculateInsuranceWrap.HealthInsuranceList);
                            for(HealthInsuranceDetails healthWrap : calculateInsuranceWrap.HealthInsuranceList){
                                if(healthWrap.isSelected){
                                    if(healthWrap.HealthInsuranceCompanyName != null) igd.Health_Insurance_Company_Name__c = healthWrap.HealthInsuranceCompanyName;
                                    if(healthWrap.HealthInsuranceTenure != null) igd.Health_Insurance_Tenure__c = healthWrap.HealthInsuranceTenure;
                                    if(healthWrap.HealthInsuranceSumAssured != null) igd.Health_Insurance_Sum_Assured__c = healthWrap.HealthInsuranceSumAssured;
                                    if(healthWrap.HealthInsurancePremium != null) igd.Health_Insurance_Premium__c = healthWrap.HealthInsurancePremium;
                                    // Added by Shivam Agarwal on 03-05-2023
                                    if(healthWrap.HealthInsuranceNominee == 'No' && (healthWrap.HealthInsuranceNomineeName == '' || healthWrap.HealthInsuranceNomineeDOB == null || healthWrap.HealthInsuranceNomineeGender == '')){
                                        errorMessage = 'Health Insurance Nominee details should be mandatory to fill.';
                                    }
                                    // End by Shivam Agarwal on 03-05-2023
                                    if(healthWrap.HealthInsuranceNominee != '') igd.Health_Insurance_Nominee__c = healthWrap.HealthInsuranceNominee;
                                    if(healthWrap.HealthInsuranceNomineeName != '') igd.Health_Insurance_Nominee_Name__c = healthWrap.HealthInsuranceNomineeName;
                                    if(healthWrap.HealthInsuranceNomineeDOB != null) igd.Health_Insurance_Nominee_DOB__c = healthWrap.HealthInsuranceNomineeDOB;
                                    if(healthWrap.HealthInsuranceNomineeGender != '') igd.Health_Insurance_Nominee_Gender__c = healthWrap.HealthInsuranceNomineeGender;
                                    if(healthWrap.HealthInsuranceNomineeRelationship != '') igd.Health_Insurance_Nominee_Relationship__c = healthWrap.HealthInsuranceNomineeRelationship;
                                }
                                if(!healthWrap.isSelected){
                                    if(healthWrap.HealthInsuranceCompanyName != null) igd.Health_Insurance_Company_Name_2__c = healthWrap.HealthInsuranceCompanyName;
                                    if(healthWrap.HealthInsuranceTenure != null) igd.Health_Insurance_Tenure_2__c = healthWrap.HealthInsuranceTenure;
                                    if(healthWrap.HealthInsuranceSumAssured != null) igd.Health_Insurance_Sum_Assured_2__c = healthWrap.HealthInsuranceSumAssured;
                                    if(healthWrap.HealthInsurancePremium != null) igd.Health_Insurance_Premium_2__c = healthWrap.HealthInsurancePremium;
                                    // Added by Shivam Agarwal on 03-05-2023
                                    if(healthWrap.HealthInsuranceNominee == 'No' && (healthWrap.HealthInsuranceNomineeName == '' || healthWrap.HealthInsuranceNomineeDOB == null || healthWrap.HealthInsuranceNomineeGender == '')){
                                        //errorMessage = 'Health Insurance Nominee details should be mandatory to fill.';
                                    }
                                    // End by Shivam Agarwal on 03-05-2023
                                    if(healthWrap.HealthInsuranceNominee != '') igd.Health_Insurance_Nominee_2__c = healthWrap.HealthInsuranceNominee;
                                    if(healthWrap.HealthInsuranceNomineeName != '') igd.Health_Insurance_Nominee_Name_2__c = healthWrap.HealthInsuranceNomineeName;
                                    if(healthWrap.HealthInsuranceNomineeDOB != null) igd.Health_Insurance_Nominee_DOB_2__c = healthWrap.HealthInsuranceNomineeDOB;
                                    if(healthWrap.HealthInsuranceNomineeGender != '') igd.Health_Insurance_Nominee_Gender_2__c = healthWrap.HealthInsuranceNomineeGender;
                                    if(healthWrap.HealthInsuranceNomineeRelationship != '') igd.Health_Insurance_Nominee_Relationship_2__c = healthWrap.HealthInsuranceNomineeRelationship;
                                }
                            }
                        }
                    
                        /*Added by Shivam Agarwal on 10-04-2023*/
                        if(calculateInsuranceWrap.FinalLifeAssuredAmount != null) igd.Final_Life_Assured_Amount__c = calculateInsuranceWrap.FinalLifeAssuredAmount;
                        if(calculateInsuranceWrap.LifeInsuranceAmountConsidered != null) igd.Life_Insurance_Amount_Considered__c = calculateInsuranceWrap.LifeInsuranceAmountConsidered;
                        if(calculateInsuranceWrap.LifeInsurancePremium2 != null) igd.Life_Insurance_Premium_2__c = calculateInsuranceWrap.LifeInsurancePremium2;
                        if(calculateInsuranceWrap.TotalPremiumAmount != null){ 
                            igd.Total_Premium_Amount__c = calculateInsuranceWrap.TotalPremiumAmount;
                            totalPremiumAmount = totalPremiumAmount + calculateInsuranceWrap.TotalPremiumAmount;
                        }
                        /*End by Shivam Agarwal on 10-04-2023*/
                        tempInsuranceGenList.add(igd);
                    }
                }
                System.debug('tempInsuranceGenList'+tempInsuranceGenList.size() +'--'+tempInsuranceGenList);
                if(tempInsuranceGenList.size() > 0 && errorMessage == ''){
                    upsert tempInsuranceGenList;
                    if(isBHOthers){
                    	errorMessage = CalculateInsuranceRaiseDeviation.raisedDeviation(OpportunityList, camLoanAmount, totalPremiumAmount, calculateInsuranceList, insuranceJustification);
                        if(errorMessage != ''){
                            Database.rollback(sp);
                        }
                    }
                    calculateInsuranceList.clear();
                    /*InsuranceGenList = [SELECT Id, Application__c, Application__r.Sanctioned_Tenure__c, Application__r.Sanctioned_Amont__c, Contact__c, 
                                        Contact__r.Name, Role__c, Applicant_Name__c, Date_of_Birth__c, Gender__c, Height__c, Weight__c, BMI1__c, Life_Cover__c, 
                                        Life_Insurance__c, Life_Insurance_Company_Name__c, Life_Insurance_Tenure__c, Life_Insurance_Sum_Assured__c, 
                                        Life_Insurance_Premium__c, Medicals_Required__c, Medical_Required_BMI__c, Medical_Required_LIAC__c, Medicals_Accepted__c, 
                                        Medical_Insurance_Premium__c, Nominee_Name__c, Nominee_DOB__c, Relationship_with_Insured__c, Accidental_Death_Insurance__c, 
                                        Accidental_Death_Insurance_Premium__c, Property_Insurance_Required__c, Property_Insurance_Company_Name__c, Property_Tenure__c, 
                                        Total_Property_Value__c, Property_Insurance_Premium__c, Critical_illness_Required__c, Critical_Insurance_Company_Name__c, 
                                        Critical_illness_Tenure__c, Critical_illness_Sum_Assured__c, Critical_illness_Sum_Assured_Percentage__c, 
                                        Critical_illness_Premium__c, Health_Insurance_Required__c, Health_Insurance_Company_Name__c, Health_Insurance_Tenure__c, 
                                        Health_Insurance_Sum_Assured__c, Health_Insurance_Premium__c, Health_Insurance_Nominee__c, Health_Insurance_Nominee_Name__c,
                                        Health_Insurance_Nominee_DOB__c, Health_Insurance_Nominee_Gender__c, Final_Life_Assured_Amount__c, 
                                        Life_Insurance_Amount_Considered__c, Life_Insurance_Premium_2__c, Total_Premium_Amount__c, Round_Rate__c
                                        FROM Insurance_Generation_Data__c WHERE Application__c =: appId];*
                    
                    /*
                    Author : Shivam Agarwal
                    Description : If Post Sanction is unchecked then Disbursement not able to create.
                    Date : 06/03/2023
                    */ 
                    //*****************************START HERE********************************//
                    Boolean isValidated = Boolean.valueOf(System.Label.Post_Sanction_Validation);
                    if(isValidated){
                        List<Application_Flags__c> appFlagList = new List<Application_Flags__c>();
                        appFlagList = [Select Id, Name, Post_Sanction__c, Post_Sanction_Flag__c from Application_Flags__c where Application__c =: appId 
                                       AND Post_Sanction__c != null AND Post_Sanction_Flag__c = true LIMIT 1];
                        if(appFlagList.size() > 0){
                            if(appFlagList[0].Post_sanction_Flag__c){
                                appFlagList[0].Post_sanction_Flag__c = false;
                                update appFlagList[0];
                            }
                        }
                    }
                    //*****************************END HERE********************************//
            
                    List<Disbursement__c> disblist = [SELECT Id, Insurance_Company__c, Tranch_Details__c, Levels_Of_Tranch__c, CIP__c, Critical_illness_SA__c, 
                                                      Critical_illness_tenure__c from Disbursement__c where Application__c =: appId AND 
                                                      Tranch_Details__c = 'First' AND Levels_Of_Tranch__c = 'First Tranche' AND  Disb_Status__c != 'Cancelled by branch' 
                                                      AND Disb_Status__c != 'Cancelled DE' AND Disb_Status__c != 'Cancelled' LIMIT 1];
                    System.debug('disblist = ' + disblist.size());
                    if(disblist.size()>0){
                        Decimal totLifeInsamount = 0;
                        Decimal totLifeAccidentamount = 0;
                        Decimal totLifePropertyamount = 0;
                        Decimal totCriticalIllnessAmount = 0;
                        Decimal totHealthInsurancePremium = 0;
                        Decimal totCriticalSumAssured = 0;
                        String criticalIllnessTenure;
                        String bank;
                        String HealthInsuranceCompanyName = '';
                        for(Insurance_Generation_Data__c ins : tempInsuranceGenList){
                            System.debug('inside 1646' + ins.Life_Insurance_Premium_2__c);
                            if(ins.Life_Insurance_Premium_2__c!= null) totLifeInsamount += ins.Life_Insurance_Premium_2__c;
                            if(ins.Accidental_Death_Insurance_Premium__c != null) totLifeAccidentamount += ins.Accidental_Death_Insurance_Premium__c;
                            if(ins.Property_Insurance_Premium__c != null) totLifePropertyamount += ins.Property_Insurance_Premium__c;
                            if(ins.Life_Insurance_Company_Name__c != null) bank = ins.Life_Insurance_Company_Name__c;
                            if(ins.Critical_illness_Premium__c != null && ins.Critical_illness_Required__c == 'Yes') totCriticalIllnessAmount += ins.Critical_illness_Premium__c;
                            if(ins.Critical_illness_Sum_Assured__c != null && ins.Critical_illness_Required__c == 'Yes' && ins.Critical_illness_Tenure__c != null){
                                totCriticalSumAssured += ins.Critical_illness_Sum_Assured__c;
                                criticalIllnessTenure = ins.Critical_illness_Tenure__c; 
                            }    
                            if(ins.Health_Insurance_Premium__c != null && ins.Health_Insurance_Required__c == 'Yes') totHealthInsurancePremium += ins.Health_Insurance_Premium__c;
                            if(ins.Health_Insurance_Company_Name__c != null && ins.Health_Insurance_Required__c == 'Yes') HealthInsuranceCompanyName = ins.Health_Insurance_Company_Name__c;
                        }
                        System.debug('disblist = '+totCriticalSumAssured);
                        System.debug('disblist = '+criticalIllnessTenure);
                        System.debug('disblist = '+totCriticalIllnessAmount);
                        System.debug('inside 1669'+totLifeInsamount);
                        for(Disbursement__c dis : disblist){
                            dis.Insurance_Premium__c = totLifeInsamount;
                            dis.Accidental_Life_Insurance__c = totLifeAccidentamount;
                            dis.Health_Insurance_Premium__c = totHealthInsurancePremium;
                            dis.Health_Insurance_Company__c = HealthInsuranceCompanyName;
                            dis.Property_Insurance__c = totLifePropertyamount;
                            dis.CIP__c = totCriticalIllnessAmount;
                            dis.Critical_illness_SA__c = totCriticalSumAssured;
                            if(criticalIllnessTenure != null) dis.Critical_illness_tenure__c = Decimal.valueOf(criticalIllnessTenure);
                            if(bank != null) dis.Insurance_Company__c = bank;   
                        }
                        if(disblist.size()>0)
                            update disblist;
                    }
                } 
            }
            System.debug(errorMessage);
            Wrapper wrap = new Wrapper();
            wrap.InsuranceGenerationDataList = tempInsuranceGenList;
            wrap.errorMessage = errorMessage;
            wrapClassList.add(wrap);
            System.debug(wrapClassList);
            return wrapClassList;
        }
        catch(Exception e){
            System.debug('EXCEPTION'+e.getLineNumber()+'==='+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class Wrapper {
        @AuraEnabled
        public List<Opportunity> OpportunityList;
        @AuraEnabled
        public List<OpportunityContactRole> OpportunityContactRoleList;
        @AuraEnabled
        public List<Insurance_Generation_Data__c> InsuranceGenerationDataList;
        @AuraEnabled
        public List<CAM__c> CAMList;
        @AuraEnabled
        public List<Property_Insurance_Generation_Data__c> PropertyInsuranceGenerationList;
        @AuraEnabled
        public List<CalculateInsurance> CalculateInsuranceList;
        @AuraEnabled
        public String branchInsuranceCompany;
        @AuraEnabled
        public String branchPropertyInsuranceCompany;
        @AuraEnabled
        public String branchHealthInsuranceCompany;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public Boolean isDisabled;
        @AuraEnabled
        public Boolean EditMode;
        @AuraEnabled
        public Boolean showEditButton;
        @AuraEnabled
        public Boolean isHLA_DM;
        @AuraEnabled
        public List<SelectOption> nomineeNameList;
        @AuraEnabled
        public List<SelectOption> relationshipList;
    }
    
    public class CalculateInsurance { 
        @AuraEnabled
        public String application;
        @AuraEnabled
        public String con; 
        @AuraEnabled
        public String insuranceId;  
        @AuraEnabled
        public String applicantDetails;
        @AuraEnabled
        public String applicantDetailsApplicantName;
        @AuraEnabled
        public String applicantName;
        @AuraEnabled
        public String DOB;
        @AuraEnabled
        public String gender;
        @AuraEnabled
        public String lifeInsurance;
        @AuraEnabled
        public Boolean isLifeInsuranceNo;
        @AuraEnabled
        public List<LifeInsuranceDetails> LifeInsuranceList; 
        @AuraEnabled
        public String PropertyInsurance;
        @AuraEnabled
        public Boolean isPropertyMainApplicant;
        @AuraEnabled
        public List<PropertyInsuranceDetails> PropertyInsuranceList;  
        @AuraEnabled
        public String HealthInsuranceRequired;
        @AuraEnabled
        public List<HealthInsuranceDetails> HealthInsuranceList;
        public String criticalIllnessRequired{get;set;}
        public String criticalInsuranceCompanyName{get;set;}
        public Integer criticalIllnessTenure{get;set;}
        public Decimal criticalIllnessSumAssured{get;set;}
        public Decimal criticalIllnessPremium{get;set;}
        public String criticalIllnessSumAssuredPercentage{get;set;}
        @AuraEnabled
        public String FinalLifeInsuranceCompanyName;
        @AuraEnabled
        public String FinalLifeInsurancePremium;
        @AuraEnabled
        public String FinalPropertyInsuranceCompanyName;
        @AuraEnabled
        public String FinalPropertyInsurancePremium;
        @AuraEnabled
        public String FinalHealthInsuranceCompanyName;
        @AuraEnabled
        public String FinalHealthInsurancePremium;
        /*Added by Shivam Aarwal on 10-04-2023*/
        @AuraEnabled
        public Decimal FinalLifeAssuredAmount;
        @AuraEnabled
        public Decimal LifeInsuranceAmountConsidered;
        @AuraEnabled
        public Decimal LifeInsurancePremium2;
        @AuraEnabled
        public Decimal TotalPremiumAmount;
        @AuraEnabled
        public Boolean isOpenAccordion;
        @AuraEnabled
        public String accordionArrow;
        @AuraEnabled
        public Boolean isOpen;
        /*End by Shivam Aarwal on 10-04-2023*/
        
        public CalculateInsurance() {
            application = '';
            con = '';
            insuranceId = '';
            applicantDetails = '';
            applicantDetailsApplicantName = '';
            applicantName = '';
            DOB = null;
            gender = '';
            lifeInsurance = '';
            isLifeInsuranceNo = true;
            LifeInsuranceList = new List<LifeInsuranceDetails>();
            PropertyInsurance = 'Yes';
            isPropertyMainApplicant = false;
            PropertyInsuranceList = new List<PropertyInsuranceDetails>();
            HealthInsuranceRequired = 'Yes';
            HealthInsuranceList = new List<HealthInsuranceDetails>();
            criticalIllnessRequired = null;
            criticalInsuranceCompanyName = null;
            criticalIllnessTenure = null;
            criticalIllnessSumAssured = null;
            criticalIllnessPremium = null;
            criticalIllnessSumAssuredPercentage = null;
            /*End by Shivam Aarwal on 10-04-2023*/
            FinalLifeInsuranceCompanyName = '';
            FinalLifeInsurancePremium = '';
            FinalPropertyInsuranceCompanyName = '';
            FinalPropertyInsurancePremium = '';
            FinalHealthInsuranceCompanyName = '';
            FinalHealthInsurancePremium = '';
            FinalLifeAssuredAmount = 0.0;
            LifeInsuranceAmountConsidered = 0.0;
            LifeInsurancePremium2 = 0.0;
            TotalPremiumAmount = 0.0;
            isOpenAccordion = true;
            accordionArrow = 'utility:switch';
            isOpen = false;
            /*End by Shivam Aarwal on 10-04-2023*/
        }
    }
    
    public class LifeInsuranceDetails { 
        @AuraEnabled
        public Boolean isSelected;
        @AuraEnabled
        public String OptionWithCompanyName;
        @AuraEnabled
        public Decimal roundRate;
        @AuraEnabled
        public Decimal finalRate;
        @AuraEnabled
        public String applicantAge;
        @AuraEnabled
        public String lifeCover;
        @AuraEnabled
        public String lifeInsuranceCompanyName;
        @AuraEnabled
        public Integer lifeInsuranceTenure;
        @AuraEnabled
        public Decimal lifeInsuranceSumAssured;
        @AuraEnabled
        public Decimal lifeInsurancePremium;
        /*Added by Lokendra Singh on 27-aug-2025*/
        @AuraEnabled
        public String employeeId;
        @AuraEnabled
        public String employeeName;
        /* ended by lokendra singh */
        /*Added by Laxmi*/
        @AuraEnabled
        public Decimal height;
        @AuraEnabled
        public Decimal weight;
        @AuraEnabled
        public Decimal BMI;
        /* End by Laxmi*/  
        @AuraEnabled
        public String medicalrequired;
        @AuraEnabled
        public String medicalrequiredBMI;
        @AuraEnabled
        public String medicalrequiredLIAC;
        @AuraEnabled
        public String medicalaccepted;
        @AuraEnabled
        public Decimal MedicalInsurancePremium;
        @AuraEnabled
        public String nomineeName;
        @AuraEnabled
        public String nomineeDOB;
        @AuraEnabled
        public String relationship;
        @AuraEnabled
        public String accidentalDeathInsurance;
        @AuraEnabled
        public String accidentalDeathInsuranceCompanyname;
        @AuraEnabled
        public Decimal AccidentalDeathInsurancePremium; 
        @AuraEnabled
        public Boolean isDisabled;
        public LifeInsuranceDetails() {
            isSelected = false;
            OptionWithCompanyName = '';
            roundRate = 0.0;
            finalRate = 0.0;
            applicantAge = '';
            lifeCover = '';
            lifeInsuranceCompanyName = '';
            lifeInsuranceTenure = 0;
            lifeInsuranceSumAssured = 0.0;
            lifeInsurancePremium = 0.0;
            employeeId = ''; // added by lokendra singh
            employeeName = ''; // added by lokendra singh
            height = 0.0;
            weight = 0.0;
            BMI = 0.0;
            medicalrequired = '';
            medicalrequiredBMI = '';
            medicalrequiredLIAC = '';
            medicalaccepted = '';
            MedicalInsurancePremium = 0.0;
            nomineeName = '';
            nomineeDOB = '';
            relationship = '';
            accidentalDeathInsurance = '';
            accidentalDeathInsuranceCompanyname = '';
            AccidentalDeathInsurancePremium = 0.0;
            isDisabled = false;
        }
    }
    
    public class PropertyInsuranceDetails { 
        @AuraEnabled
        public Boolean isSelected;
        @AuraEnabled
        public String OptionWithCompanyName;
        @AuraEnabled
        public String propcompanyname;
        @AuraEnabled
        public String propertyInsuranceCompanyName;
        @AuraEnabled
        public String totalPropertyValue;
        @AuraEnabled
        public Integer propertyTenure;
        @AuraEnabled
        public Decimal PropertyInsurancePremium;
        @AuraEnabled
        public Boolean isDisabled;
        public PropertyInsuranceDetails() {
            isSelected = false;
            OptionWithCompanyName = '';
            propcompanyname = '';
            propertyInsuranceCompanyName = '';
            totalPropertyValue = '';
            propertyTenure = 0;
            PropertyInsurancePremium = 0.0;
            isDisabled = false;
        }
    }
    
    public class HealthInsuranceDetails {
        /*Added by Shivam Aarwal on 28-04-2023*/
        @AuraEnabled
        public Boolean isSelected;
        @AuraEnabled
        public String OptionWithCompanyName;
        @AuraEnabled
        public String HealthInsuranceCompanyName;
        @AuraEnabled
        public String HealthInsuranceTenure;
        @AuraEnabled
        public String HealthInsuranceSumAssured;
        @AuraEnabled
        public Decimal HealthInsurancePremium;
        @AuraEnabled
        public String HealthInsuranceNominee;
        @AuraEnabled
        public String HealthInsuranceNomineeName;
        @AuraEnabled
        public Date HealthInsuranceNomineeDOB;
        @AuraEnabled
        public String HealthInsuranceNomineeGender;
        @AuraEnabled
        public String HealthInsuranceNomineeRelationship;
        @AuraEnabled
        public Boolean isDisabled;
        public HealthInsuranceDetails() {
            isSelected = false;
            OptionWithCompanyName = '';
            HealthInsuranceCompanyName = 'Care Health Insurance';
            HealthInsuranceTenure = '3';
            HealthInsuranceSumAssured = '2 Lakh';
            HealthInsurancePremium = 16873;
            HealthInsuranceNominee = 'Yes';
            HealthInsuranceNomineeName = '';
            HealthInsuranceNomineeDOB = null;
            HealthInsuranceNomineeGender = '';
            HealthInsuranceNomineeRelationship = '';
            isDisabled = false;
        }
        /*End by Shivam Aarwal on 28-04-2023*/
    }
    
    public class SelectOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        public SelectOption(String label1, String value1){
            label = label1;
            value = value1;
        }
    }
    
   
}

                        /*if(obj.Insurer__c == 'Max Life Insurance' && roiStart != null && roiStart == obj.Start_ROI__c && roiEnd != null && 
                           roiEnd == obj.End_ROI__c && product != null && product == obj.Product__c && gender != NULL && gender == obj.Gender__c){
                               Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                               Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                               lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                               lifeInsuranceWrap.isDisabled = false;
                               lifeInsuranceList.add(lifeInsuranceWrap);
                               option++;
                           }
                        else*/ 

                        /*else if(obj.Insurer__c == 'Edelweiss Tokio Life' && product != null && product == obj.Product__c && gender != NULL && gender == obj.Gender__c){
                            Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                            Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                            lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                            lifeInsuranceWrap.isDisabled = false;
                            lifeInsuranceList.add(lifeInsuranceWrap);
                            option++;
                        }
                        else if(obj.Insurer__c == 'Bajaj Allianz' && obj.Start_Sum_Assured__c < sumAssured && obj.End_Sum_Assured__c >= sumAssured){
                            Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                            Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                            lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                            lifeInsuranceWrap.isDisabled = false;
                            lifeInsuranceList.add(lifeInsuranceWrap);
                            option++;
                        }*/
                        /*else if(obj.Insurer__c == 'Kotak Life' && gender != NULL && gender == obj.Gender__c){
                            String tempsumAssured = Label.MinimumSumAssuredKotak;
                            String mid = Label.MidSumAssuredKotak;
                            String large = Label.MaxSumAssuredKotak;
                            System.debug(tempsumAssured);
                            System.debug(mid);
                            System.debug(large);
                            System.debug(mid+'---'+large+'---'+sumassured+'----'+tempsumAssured);
                            if(sumAssured >= Decimal.valueOf(tempsumAssured) && sumAssured <= Decimal.valueOf(mid)){
                                if(obj.Start_Sum_Assured__c >= Decimal.valueOf(tempsumAssured) && obj.End_Sum_Assured__c <= Decimal.valueOf(mid) && product != null && product == obj.Product__c){
                                    lifeInsuranceWrap.lifeInsuranceCompanyName = obj.Insurer__c;
                                    lifeInsuranceWrap.lifeInsuranceTenure = Integer.valueOf(obj.Start_Tenure__c);
                                    lifeInsuranceWrap.lifeInsuranceSumAssured = sumAssured;
                                    Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                                    Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                                    lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                                    lifeInsuranceWrap.isDisabled = false;
                                    lifeInsuranceList.add(lifeInsuranceWrap);
                                    option++;
                                }
                            }
                            else if(sumAssured > Decimal.valueOf(mid) && sumAssured <= Decimal.valueOf(large)){
                                if(obj.Start_Sum_Assured__c > Decimal.valueOf(mid) && obj.End_Sum_Assured__c <= Decimal.valueOf(large) && product != null && product == obj.Product__c){
                                    lifeInsuranceWrap.lifeInsuranceCompanyName = obj.Insurer__c;
                                    lifeInsuranceWrap.lifeInsuranceTenure = Integer.valueOf(obj.Start_Tenure__c);
                                    lifeInsuranceWrap.lifeInsuranceSumAssured = sumAssured;
                                    Decimal premiumAmount = sumAssured * obj.Round_Rate__c;
                                    Decimal temp = (premiumAmount * Integer.valueOf(Label.GST))/100;
                                    lifeInsuranceWrap.lifeInsurancePremium = Math.round(premiumAmount + temp);
                                    lifeInsuranceWrap.isDisabled = false;
                                    lifeInsuranceList.add(lifeInsuranceWrap);
                                    option++;
                                }
                            }
                        }*/
