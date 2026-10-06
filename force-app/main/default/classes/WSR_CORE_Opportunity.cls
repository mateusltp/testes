/*
    -------------------------------------------------------------------------------
    -- - Name         : WSR_Opportunity
    -- - Author       : ACTP
    -- - Date         : 01/09/2020
    -- - Description  : Opportunity Web service
    -- - Maintenance History:
    --   Date          Author      Version   Comments
    -- -------------  ----------   -------   ---------------------------------------
    -- 01/09/2020     ACTP         1.0       First Version.
    --------------------------------------------------------------------------------
*/

@RestResource(urlMapping='/core/opportunity/*')
global class WSR_CORE_Opportunity {

    @HttpPost
    global static List<Result> doPost(OpportunityWrapper opportunityWrapper) {
        
        Map<String, List<String>> errors = new Map<String, List<String>>();
        List <Asset> quotesToInsert = new List <Asset>();
        String userIsoCode = SEL_Users.newInstance().selectById(UserInfo.getUserId()).get(0).ISOCode__c;
        Result result = new Result();
        Boolean accountAlredyExit = False;
        Opportunity opportunityRecord = new Opportunity();
        Account accountRecord = new Account(); 
        User recordOwner;
        Boolean opportunityAlreadyExists = false;
        Id accountIdOpportunity;//Id de la cuenta asociada a la oportunidad
        List<Task> taskToUpdate;//Lista para migrar las tareas
        List<Result> results = new List<Result>();

        if (validationRules(errors, opportunityWrapper)){


        // To delete in the future
        List<User> genericUserOpportunityList = SEL_Users.newInstance().selectOpportunityGenericUsers();
        Map<String, User> genericUserOpportunity = new Map<String, User>();
        for(User userRecord : genericUserOpportunityList)
        {
            genericUserOpportunity.put(userRecord.ISOCode__c, userRecord);
        } 

        

        
        if(String.isNotEmpty(opportunityWrapper.idOpportunity))
        {
            List<Opportunity> opportunitiesList = SEL_Opportunities.newInstance().selectByIdInternal(userIsoCode + '_' + opportunityWrapper.idOpportunity);
            // idOpportunity == Id Salesforce
            if(opportunitiesList.size()==0 && Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(opportunityWrapper.idOpportunity).matches())
            {
                opportunitiesList = SEL_Opportunities.newInstance().selectById(opportunityWrapper.idOpportunity);
            }
            if(opportunitiesList.size()>0)
            {
                opportunityAlreadyExists = true;
            }
            opportunityRecord = opportunitiesList.size() > 0 ? opportunitiesList.get(0) : new Opportunity();
            //Rellanamos con el AccountId de la oportunidad
            accountIdOpportunity = opportunitiesList.size() > 0 ?opportunitiesList.get(0).AccountId : null;
            opportunityRecord.IdInternal__c = userIsoCode + '_' + opportunityWrapper.idOpportunity;
        }

        // // TO DELETED
        // if(String.isNotEmpty(opportunityWrapper.idOwner))
        // {
        //     String userInternalId = userIsoCode + '_' + opportunityWrapper.idOwner;
        //     List<User> recordsOwner = new List<User> (SEL_Users.newInstance().selectByIdInternal(userInternalId));
        //     // To delete in the future
        //     if(recordsOwner.size() > 0)
        //     {
        //         recordOwner = recordsOwner.get(0);
        //     }else
        //     {
        //         if(genericUserOpportunity.containsKey(userIsoCode))
        //         {
        //             opportunityRecord.PendingToAssign__c = true;
        //             recordOwner = genericUserOpportunity.get(userIsoCode);
        //         }else
        //         {
        //             throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, Please include a valid owner of the opportunity or contact to your Salesforce Administrator to define a default one.');
        //         }
        //     }                    
        // }else {
        //     if(genericUserOpportunity.containsKey(userIsoCode))
        //     {
        //         opportunityRecord.PendingToAssign__c = true;
        //         recordOwner = genericUserOpportunity.get(userIsoCode);
        //     }else
        //     {
        //         throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, Please include a valid owner of the opportunity or contact to your Salesforce Administrator to define a default one.');
        //     }
        // }

        // opportunityRecord.OwnerId = recordOwner.Id;
        if (String.isNotEmpty(opportunityWrapper.idInternal)) {
            List<User> recordsOwner =
                SEL_Users.newInstance().selectByIdInternal(opportunityWrapper.idInternal);

            if (!recordsOwner.isEmpty()) {
                recordOwner = recordsOwner.get(0);
                opportunityRecord.OwnerId = recordOwner.Id;
            }else {
                throw new EXT_CustomException(
                    'MISSING_REQUIRED_VALUE, No User found for idInternal: '
                    + opportunityWrapper.idInternal
                );
            }
        } else if (String.isNotEmpty(opportunityWrapper.idOwner)) {
          //  String userInternalId = userIsoCode + '_' + opportunityWrapper.idOwner;
            List<User> recordsOwner = SEL_Users.newInstance().selectById(opportunityWrapper.idOwner);
            recordOwner = recordsOwner.get(0);
            if (!recordsOwner.isEmpty()) {
                opportunityRecord.OwnerId = recordOwner.Id;
            }
        }

        if(String.isNotEmpty(opportunityWrapper.intermediaryCode))
        {
            List<AccountRole__c> intermediaryList = SEL_AccountRoles.newInstance().selectByIdInternal(userIsoCode + '_' + opportunityWrapper.intermediaryCode);
            opportunityRecord.AccountRoleIntermediary__c = intermediaryList.size() > 0 ? intermediaryList.get(0).Id : null;
        }

        opportunityRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.idOpportunity) ? opportunityWrapper.idOpportunity : null;
        // opportunityRecord.IdInternal__c = String.isNotEmpty(opportunityWrapper.idOpportunity) ? userIsoCode + '_' + opportunityWrapper.idOpportunity : null;
        
        if(String.isNotEmpty(opportunityWrapper.campaignId))
        {
            List<Campaign> campaignList = SEL_Campaigns.newInstance().selectByIdInternal(userIsoCode + '_' + opportunityWrapper.campaignId);
            opportunityRecord.CampaignId = campaignList.size() > 0 ? campaignList.get(0).Id : null;
        }
        if(!opportunityAlreadyExists){
            opportunityRecord.Name = String.isNotEmpty(opportunityWrapper.opportunityNumber) ? opportunityWrapper.opportunityNumber : 'Opportunity';
        }
        opportunityRecord.OppNumber__c = String.isNotEmpty(opportunityWrapper.opportunityNumber) ? opportunityWrapper.opportunityNumber : null;
        opportunityRecord.StartDate__c = opportunityWrapper.startDate!= null ? opportunityWrapper.startDate : Date.today();                    
		Integer defaultCloseDays = userIsoCode == 'CO' ? 60 : 30;
        opportunityRecord.CloseDate = opportunityWrapper.closeDate != null ? opportunityWrapper.closeDate : Date.today().addDays(defaultCloseDays);        
        opportunityRecord.Type = String.isNotEmpty(opportunityWrapper.opportunityType) ? opportunityWrapper.opportunityType : null;
        opportunityRecord.Amount = opportunityWrapper.amount != null ? opportunityWrapper.amount : null;
        opportunityRecord.CurrencyIsoCode = String.isNotEmpty(opportunityWrapper.currencyIsoCode) ? opportunityWrapper.currencyIsoCode : null;
        opportunityRecord.Description = String.isNotEmpty(opportunityWrapper.description) ? opportunityWrapper.description : null;

        if(opportunityWrapper.opportunityCustom != null)
        {
            opportunityRecord.OfficialAndAlternateChannel__c = String.isNotEmpty(opportunityWrapper.opportunityCustom.OfficialAndAlternateChannel) ? opportunityWrapper.opportunityCustom.OfficialAndAlternateChannel : null;
        }

        if(opportunityWrapper.policyInformation != null)
        {
            if(String.isNotEmpty(opportunityWrapper.policyInformation.competitorCode))
            {
                List<AccountRole__c> competitorList = SEL_AccountRoles.newInstance().selectByIdInternal(userIsoCode + '_' + opportunityWrapper.policyInformation.competitorCode);
                opportunityRecord.Competitor__c = competitorList.size() > 0 ? competitorList.get(0).Id : null;
            }

            opportunityRecord.PolicyNetPremiumOther__c = opportunityWrapper.policyInformation.polNetPremium != null ? opportunityWrapper.policyInformation.polNetPremium : null;
            opportunityRecord.PolicyExpirationDateOther__c = opportunityWrapper.policyInformation.polExpDate != null ? opportunityWrapper.policyInformation.polExpDate : null;
            opportunityRecord.PolicyNumber__c = opportunityWrapper.policyInformation.policyNumber != null ? opportunityWrapper.policyInformation.policyNumber : null;
            opportunityRecord.ConvertedStatus__c = opportunityWrapper.policyInformation.convertedStatus != null ? opportunityWrapper.policyInformation.convertedStatus : null;

        }

        /*
         *
         *      PERSON OPPORTUNITY
         *
         */

        if( opportunityWrapper.personOpportunity != null && opportunityWrapper.businessOpportunity == null) 
        {

            opportunityRecord.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_PersonPolicy').getRecordTypeId();

            if(opportunityWrapper.personOpportunity.productInformation != null)
            {

                opportunityRecord.BusinessLine__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.businessLine) ? opportunityWrapper.personOpportunity.productInformation.businessLine : null;
                if(userIsoCode != 'PE'){
	            opportunityRecord.Sector__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.sector) ? opportunityWrapper.personOpportunity.productInformation.sector : null;
                }
                opportunityRecord.SubSector__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.subSector) ? opportunityWrapper.personOpportunity.productInformation.subSector : null;
                opportunityRecord.Branch__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.branch) ? opportunityWrapper.personOpportunity.productInformation.branch : null;
                opportunityRecord.RiskDetail__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.risk) ? opportunityWrapper.personOpportunity.productInformation.risk : null;
                opportunityRecord.ProductCode__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.productCode) ? opportunityWrapper.personOpportunity.productInformation.productCode : null;
                opportunityRecord.ProductName__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.productName) ? opportunityWrapper.personOpportunity.productInformation.productName : null;
                opportunityRecord.InterestProduct__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.interestProduct) ? opportunityWrapper.personOpportunity.productInformation.interestProduct : null;
                opportunityRecord.AdditionalInformation__c = String.isNotEmpty(opportunityWrapper.personOpportunity.productInformation.additionalInformation) ? opportunityWrapper.personOpportunity.productInformation.additionalInformation : null;   
            }
            opportunityRecord.StageName = String.isNotEmpty(opportunityWrapper.personOpportunity.stage) ?  opportunityWrapper.personOpportunity.stage : null;
            if(opportunityWrapper.personOpportunity.personAccount != null)
            {
                if(String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentType) &&
                    String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentNumber))
                {
                    
                    String idIndernal = userIsoCode + '_' + opportunityWrapper.personOpportunity.personAccount.documentType + '_' + opportunityWrapper.personOpportunity.personAccount.documentNumber;
                    List<Account> clientOrProspect = new List<Account>(SEL_Accounts.newInstance().selectByIdInternal(idIndernal));
                    List<Account> clientOrProspect2 = new List<Account>(); //Lista para buscar por Id Interno

                    //Si no encuentra el cliente por el IdInternal buscamos por el Id de SF y tengo la Id de la oportunidad del servicio
                    if(clientOrProspect.size() == 0 && accountIdOpportunity!=null){
                        clientOrProspect2 = new List<Account>(SEL_Accounts.newInstance().selectById(accountIdOpportunity));
                    }
                    // Existe la cuenta en la base de datos de SF y no es el mismo asociado a la oportunidad
                    if(clientOrProspect.size() > 0 && accountIdOpportunity != accountRecord.id)
                    {
                        accountRecord = clientOrProspect.get(0);
                        opportunityRecord.AccountId = accountRecord.id;//Actualizamos la oportuniad con el cliente del WSR
                        taskToUpdate = SEL_Tasks.newInstance().selectWithWhere(' WhatId = \'' + accountIdOpportunity + '\'', null, null);
                        for(Task t : taskToUpdate)//Movemos todas las tareas al cliente que viene en el WSR
                        {
                            t.WhatId = accountRecord.id;
                        }
                        accountAlredyExit = True;
                    }//Si el cliente existe por IdInternal y es el mismo que el de la oportunidad
                    else if(clientOrProspect.size() > 0 && accountIdOpportunity == accountRecord.id) {
                        accountRecord = clientOrProspect.get(0);
                        accountAlredyExit = True;
                    }
                    // Si el cliente no existe por IdInternal y si por Id SF
                    if(clientOrProspect2!= null && clientOrProspect2.size() > 0 && accountIdOpportunity != accountRecord.id)
                    {
                        accountRecord = clientOrProspect2.get(0);
                        //Si tiene tipo de documento provisional le ponemos el que viene en el servicio y actualizamos su IdInternal e IdExternal
                        if(accountRecord.DocumentType__c == '90'){
                            accountRecord.DocumentType__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentType) ? opportunityWrapper.personOpportunity.personAccount.documentType: null;
                            accountRecord.DocumentNumber__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentNumber) ? opportunityWrapper.personOpportunity.personAccount.documentNumber: null;
                            accountRecord.IdInternal__c = idIndernal;
                            accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.idAccount) ? opportunityWrapper.personOpportunity.personAccount.idAccount: null;
                        }
                        accountAlredyExit = True;
                    }
                    //Si no se ha localizado al cliente por IdInternal ni Id SF y viene como prospecto
                    if(clientOrProspect.size() == 0 && clientOrProspect2.size() == 0 || accountRecord.Type == '01' )
                    {
                        accountRecord.Type = '01';
                        accountRecord.OwnerId = recordOwner != null? recordOwner.Id : null;                      
                        accountRecord.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_PersonAccount').getRecordTypeId();
                        accountRecord.IdInternal__c = idIndernal;
                        accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.idAccount) ? opportunityWrapper.personOpportunity.personAccount.idAccount: null;
                        accountRecord.Salutation = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.salutation) ? opportunityWrapper.personOpportunity.personAccount.salutation: null;
                        accountRecord.FirstName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.firstName) ? opportunityWrapper.personOpportunity.personAccount.firstName: null;
                        accountRecord.MiddleName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.middleName) ? opportunityWrapper.personOpportunity.personAccount.middleName: null;
                        accountRecord.LastName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.lastName) ? opportunityWrapper.personOpportunity.personAccount.lastName: null;
                        accountRecord.Suffix = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.suffix) ? opportunityWrapper.personOpportunity.personAccount.suffix: null;
                        accountRecord.DocumentType__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentType) ? opportunityWrapper.personOpportunity.personAccount.documentType: null;
                        accountRecord.DocumentNumber__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentNumber) ? opportunityWrapper.personOpportunity.personAccount.documentNumber: null;
                        accountRecord.PersonBirthdate = opportunityWrapper.personOpportunity.personAccount.birthdate != null ? opportunityWrapper.personOpportunity.personAccount.birthdate: null;
                        accountRecord.Sex__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.sex) ? opportunityWrapper.personOpportunity.personAccount.sex: null;
                        accountRecord.MaritalStatus__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.maritalStatus) ? opportunityWrapper.personOpportunity.personAccount.maritalStatus: null;
                        accountRecord.NumberOfChildren__pc = opportunityWrapper.personOpportunity.personAccount.numberChildren != null ? opportunityWrapper.personOpportunity.personAccount.numberChildren: null;
                        accountRecord.Profession__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.profession) ? opportunityWrapper.personOpportunity.personAccount.profession: null;
                        accountRecord.Occupation__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.occupation) ? opportunityWrapper.personOpportunity.personAccount.occupation: null;
                        accountRecord.Nationality__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.nationality) ? opportunityWrapper.personOpportunity.personAccount.nationality: null;
                        accountRecord.ReferenceLanguage__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.referenceLanguage) ? opportunityWrapper.personOpportunity.personAccount.referenceLanguage: null;
                        accountRecord.PersonMobilePhone = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.mobilePhone) ? opportunityWrapper.personOpportunity.personAccount.mobilePhone: null;
                        accountRecord.PersonHomePhone = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.phone) ? opportunityWrapper.personOpportunity.personAccount.phone: null;
                        accountRecord.PersonEmail = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.email) ? opportunityWrapper.personOpportunity.personAccount.email: null;
						accountRecord.AccountSource = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.accountSource) ? opportunityWrapper.personOpportunity.personAccount.accountSource: null;
                        opportunityRecord.LeadSource = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.accountSource) ? opportunityWrapper.personOpportunity.personAccount.accountSource: null;
                        accountRecord.Origin__c = '02';
                    
                        if(opportunityWrapper.personOpportunity.personAccount.address != null){
                            accountRecord.BillingStreet = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.street) ? opportunityWrapper.personOpportunity.personAccount.address.street : null;
                            accountRecord.BillingPostalCode = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.postalCode) ? opportunityWrapper.personOpportunity.personAccount.address.postalCode : null;
                            accountRecord.BillingCity = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.city) ? opportunityWrapper.personOpportunity.personAccount.address.city : null;
                            accountRecord.BillingState = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.state) ? opportunityWrapper.personOpportunity.personAccount.address.state : null;
                            accountRecord.BillingCountry = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.country) ? opportunityWrapper.personOpportunity.personAccount.address.country : null;
                        }
                    }
                   
                }else 
                {	
                    if(accountIdOpportunity!=null){
                        List<Account> clientOrProspect = new List<Account>(SEL_Accounts.newInstance().selectById(accountIdOpportunity));
                        accountRecord = clientOrProspect.get(0);
                        accountAlredyExit = True;
                        if(accountRecord.Type == '01' )
                    	{
                            accountRecord.Type = '01';
                            accountRecord.OwnerId = recordOwner != null? recordOwner.Id : accountRecord.OwnerId;                      
                            accountRecord.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_PersonAccount').getRecordTypeId();
                            accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.idAccount) ? opportunityWrapper.personOpportunity.personAccount.idAccount: accountRecord.IdExternal__c;
                            accountRecord.Salutation = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.salutation) ? opportunityWrapper.personOpportunity.personAccount.salutation: accountRecord.Salutation;
                            accountRecord.FirstName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.firstName) ? opportunityWrapper.personOpportunity.personAccount.firstName: accountRecord.FirstName;
                            accountRecord.MiddleName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.middleName) ? opportunityWrapper.personOpportunity.personAccount.middleName: accountRecord.MiddleName;
                            accountRecord.LastName = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.lastName) ? opportunityWrapper.personOpportunity.personAccount.lastName: accountRecord.LastName;
                            accountRecord.Suffix = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.suffix) ? opportunityWrapper.personOpportunity.personAccount.suffix: accountRecord.Suffix;
                            accountRecord.PersonBirthdate = opportunityWrapper.personOpportunity.personAccount.birthdate != null ? opportunityWrapper.personOpportunity.personAccount.birthdate: accountRecord.PersonBirthdate;
                            accountRecord.Sex__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.sex) ? opportunityWrapper.personOpportunity.personAccount.sex: accountRecord.Sex__pc;
                            accountRecord.MaritalStatus__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.maritalStatus) ? opportunityWrapper.personOpportunity.personAccount.maritalStatus: accountRecord.MaritalStatus__pc;
                            accountRecord.NumberOfChildren__pc = opportunityWrapper.personOpportunity.personAccount.numberChildren != null ? opportunityWrapper.personOpportunity.personAccount.numberChildren: accountRecord.NumberOfChildren__pc;
                            accountRecord.Profession__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.profession) ? opportunityWrapper.personOpportunity.personAccount.profession: accountRecord.Profession__pc;
                            accountRecord.Occupation__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.occupation) ? opportunityWrapper.personOpportunity.personAccount.occupation: accountRecord.Occupation__pc;
                            accountRecord.Nationality__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.nationality) ? opportunityWrapper.personOpportunity.personAccount.nationality: accountRecord.Nationality__pc;
                            accountRecord.ReferenceLanguage__pc = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.referenceLanguage) ? opportunityWrapper.personOpportunity.personAccount.referenceLanguage: accountRecord.ReferenceLanguage__pc;
                            accountRecord.PersonMobilePhone = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.mobilePhone) ? opportunityWrapper.personOpportunity.personAccount.mobilePhone: accountRecord.PersonMobilePhone;
                            accountRecord.PersonHomePhone = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.phone) ? opportunityWrapper.personOpportunity.personAccount.phone: accountRecord.PersonHomePhone;
                            accountRecord.PersonEmail = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.email) ? opportunityWrapper.personOpportunity.personAccount.email:   accountRecord.PersonEmail;
                            accountRecord.AccountSource = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.accountSource) ? opportunityWrapper.personOpportunity.personAccount.accountSource:  accountRecord.AccountSource;
                            opportunityRecord.LeadSource = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.accountSource) ? opportunityWrapper.personOpportunity.personAccount.accountSource: opportunityRecord.LeadSource;
                            accountRecord.Origin__c = '02';
                        
                            if(opportunityWrapper.personOpportunity.personAccount.address != null){
                                accountRecord.BillingStreet = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.street) ? opportunityWrapper.personOpportunity.personAccount.address.street : accountRecord.BillingStreet;
                                accountRecord.BillingPostalCode = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.postalCode) ? opportunityWrapper.personOpportunity.personAccount.address.postalCode : accountRecord.BillingPostalCode;
                                accountRecord.BillingCity = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.city) ? opportunityWrapper.personOpportunity.personAccount.address.city : accountRecord.BillingCity;
                                accountRecord.BillingState = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.state) ? opportunityWrapper.personOpportunity.personAccount.address.state : accountRecord.BillingState;
                                accountRecord.BillingCountry = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.address.country) ? opportunityWrapper.personOpportunity.personAccount.address.country : accountRecord.BillingCountry;
                            }
                        }
                    }else
                    {
                    	throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, please include a valid Document Type and Document Number');
                    }
                }
            }else 
            {
                throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, please include a valid Person Account');
            }
            if (opportunityWrapper.personOpportunity.productInformation != null && opportunityWrapper.personOpportunity.productInformation.quotes != null){
                for (Quote q : opportunityWrapper.personOpportunity.productInformation.quotes) {
                    Asset asset = new Asset();
                    asset.ISOCode__c = userIsoCode;
                    asset.IdExternal__c = q.id != null ? q.Id : null;
                    asset.Name = asset.IdExternal__c;
                    asset.IdInternal__c = String.isBlank(asset.IdInternal__c) && String.isNotBlank(asset.IdExternal__c) ? asset.ISOCode__c + '_' + asset.IdExternal__c : asset.IdInternal__c;
                    asset.IssueDate__c = q.issueDate != null ? q.issueDate : null;
                    asset.DueDate__c = q.dueDate != null ? q.dueDate : null;
                    asset.EffectiveDate__c = q.effectiveDate != null ? q.effectiveDate : null;
                    asset.ExpirationDate__c = q.expirationDate != null ? q.expirationDate : null;
                    asset.ProductCode__c = q.productCode != null ? q.productCode : null;
                    asset.ProductName__c = q.productName != null ? q.productName : null;
                    asset.NetPremium__c = q.netPremium != null ? q.netPremium : null;
                    asset.TotalPremiumFactured__c = q.totalPremium != null ? q.totalPremium : null;
                    asset.PaymentMethod__c = q.paymentMethod != null ? q.paymentMethod : null;
                    asset.PaymentPeriodicity__c = q.paymentPeriodicity != null ? q.paymentPeriodicity : null;
                    asset.PaymentTerm__c = q.paymentTerm != null ? q.paymentTerm : null;
                    asset.CurrencyIsoCode = q.currencyIsoCode != null ? q.currencyIsoCode : null;
                    asset.IsSelected__c = q.isSelected != null ? q.isSelected : null;
                    asset.Discount__c = q.discount != null ? q.discount : null;
                    asset.AdditionalInformation__c = q.additionalInformation != null ? q.additionalInformation : null;
                    if (String.isNotEmpty(q.regionalOffice)) {
    
                        List<Account> accounts = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.regionalOffice);
    
                        asset.RegionalOffice__c = !accounts.isEmpty() ? accounts[0].Id : null;
                    }
                    if (String.isNotEmpty(q.managerOffice)) {
                 
                        List<Account> accounts = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.managerOffice);
                       
                     
                        asset.ManagersOffice__c = !accounts.isEmpty() ? accounts[0].Id : null;
                    }
                    if (String.isNotEmpty(q.idIntermediate)) {
                 
                        List<AccountRole__c> accountRoles = SEL_AccountRoles.newInstance().selectByIdInternal(userIsoCode + '_' + q.idIntermediate);
                       
                     
                        asset.AccountRoleIntermediaryId__c = !accountRoles.isEmpty() ? accountRoles[0].Id : null;
                    }
                    asset.IsSelected__c = q.isSelected != null ? q.isSelected : null;
     
                    quotesToInsert.add(asset);

                    if(q.idCompany != null){
                        List <Account> companyAccount = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.idCompany);
                        if(!companyAccount.isEmpty()){
                            asset.AccountId = companyAccount.get(0).Id;
                        }
                    }
                }
            }
            
        /*
         *
         *      BUSINESS OPPORTUNITY
         *
         */
        } else if( opportunityWrapper.personOpportunity == null && opportunityWrapper.businessOpportunity != null) 
        {
            opportunityRecord.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_BusinessPolicy').getRecordTypeId();

            if(opportunityWrapper.businessOpportunity.productInformation != null)
            {
                opportunityRecord.BusinessLine__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.businessLine) ? opportunityWrapper.businessOpportunity.productInformation.businessLine : null;
                if(userIsoCode != 'PE'){
	                opportunityRecord.Sector__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.sector) ? opportunityWrapper.businessOpportunity.productInformation.sector : null;
                }                    
                opportunityRecord.SubSector__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.subSector) ? opportunityWrapper.businessOpportunity.productInformation.subSector : null;
                opportunityRecord.Branch__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.branch) ? opportunityWrapper.businessOpportunity.productInformation.branch : null;
                opportunityRecord.RiskDetail__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.risk) ? opportunityWrapper.businessOpportunity.productInformation.risk : null;
                opportunityRecord.ProductCode__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.productCode) ? opportunityWrapper.businessOpportunity.productInformation.productCode : null;
                opportunityRecord.ProductName__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.productName) ? opportunityWrapper.businessOpportunity.productInformation.productName : null;
                opportunityRecord.InterestProduct__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.interestProduct) ? opportunityWrapper.businessOpportunity.productInformation.interestProduct : null;
                opportunityRecord.AdditionalInformation__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.productInformation.additionalInformation) ? opportunityWrapper.businessOpportunity.productInformation.additionalInformation : null;   
            }

            opportunityRecord.StageName = String.isNotEmpty(opportunityWrapper.businessOpportunity.stage) ?  opportunityWrapper.businessOpportunity.stage : null;

            if(opportunityWrapper.businessOpportunity.businessAccount != null)
            {
                if(String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.documentType) &&
                    String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.documentNumber))
                {

                    String idIndernal = userIsoCode + '_' + opportunityWrapper.businessOpportunity.businessAccount.documentType + '_' + opportunityWrapper.businessOpportunity.businessAccount.documentNumber;
                    List<Account> clientOrProspect = new List<Account>(SEL_Accounts.newInstance().selectByIdInternal(idIndernal));
                    List<Account> clientOrProspect2 = new List<Account>(); //Lista para buscar por Id Interno

                    //Si no encuentra el cliente por el IdInternal buscamos por el Id de SF
                    if(clientOrProspect.size() == 0 && accountIdOpportunity!=null){
                        clientOrProspect2 = new List<Account>(SEL_Accounts.newInstance().selectById(accountIdOpportunity));
                    }
                    // Is the account already in the system? y no es el mismo asociado a la oportunidad
                    if(clientOrProspect.size() > 0 && accountIdOpportunity != accountRecord.id)
                    {
                        accountRecord = clientOrProspect.get(0);
                        opportunityRecord.AccountId = accountRecord.id;//Actualizamos la oportuniad con el cliente cliente del WSR
                        taskToUpdate = SEL_Tasks.newInstance().selectWithWhere(' WhatId = \'' + accountIdOpportunity + '\'', null, null);
                        for(Task t : taskToUpdate)//Movemos todas las tareas al cliente que viene en el WSR
                        {
                            t.WhatId = accountRecord.id;
                        }
                        accountAlredyExit = True;
                    }//Si el cliente existe por IdInternal y es el mismo que el de la oportunidad
                    else if(clientOrProspect.size() > 0 && accountIdOpportunity == accountRecord.id) {
                        accountRecord = clientOrProspect.get(0);
                        accountAlredyExit = True;
                    }
                    // Si el cliente no existe por IdInternal y si por Id SF
                    if(clientOrProspect2!= null && clientOrProspect2.size() > 0 && accountIdOpportunity != accountRecord.id)
                    {
                        accountRecord = clientOrProspect2.get(0);
                        //Si tiene tipo de documento provisional le ponemos el que viene en el servicio y actualizamos su IdInternal e IdExternal
                        if(accountRecord.DocumentType__c == '90'){
                            accountRecord.DocumentType__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentType) ? opportunityWrapper.personOpportunity.personAccount.documentType: null;
                            accountRecord.DocumentNumber__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.documentNumber) ? opportunityWrapper.personOpportunity.personAccount.documentNumber: null;
                            accountRecord.IdInternal__c = idIndernal;
                            accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.personOpportunity.personAccount.idAccount) ? opportunityWrapper.personOpportunity.personAccount.idAccount: null;
                        }
                        accountAlredyExit = True;
                    }
                    
                    //Si no se ha localizado al cliente por IdInternal ni Id SF y viene como prospecto 
                    if(clientOrProspect.size() == 0 && clientOrProspect2.size() == 0 || accountRecord.Type == '01' )
                    {
                        accountRecord.Type = '01';
                        accountRecord.OwnerId = recordOwner != null? recordOwner.Id : null;                      
                        accountRecord.RecordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_BusinessAccount').getRecordTypeId();
                        accountRecord.IdInternal__c = idIndernal;
                        accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.idAccount) ? opportunityWrapper.businessOpportunity.businessAccount.idAccount: null;
                        accountRecord.Name = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.company) ? opportunityWrapper.businessOpportunity.businessAccount.company : null;
                        accountRecord.DocumentType__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.documentType) ? opportunityWrapper.businessOpportunity.businessAccount.documentType : null;
                        accountRecord.DocumentNumber__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.documentNumber) ? opportunityWrapper.businessOpportunity.businessAccount.documentNumber : null;
                        accountRecord.Industry = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.industry) ? opportunityWrapper.businessOpportunity.businessAccount.industry : null;
                        accountRecord.NumberOfEmployees = opportunityWrapper.businessOpportunity.businessAccount.numberEmployees != null ? opportunityWrapper.businessOpportunity.businessAccount.numberEmployees : null;
                        accountRecord.Website = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.website) ? opportunityWrapper.businessOpportunity.businessAccount.website : null;
                        accountRecord.Phone = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.phone) ? opportunityWrapper.businessOpportunity.businessAccount.phone : null;
                        accountRecord.Email__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.email) ? opportunityWrapper.businessOpportunity.businessAccount.email : null;
						accountRecord.AccountSource = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.accountSource) ? opportunityWrapper.businessOpportunity.businessAccount.accountSource: null;
                        opportunityRecord.LeadSource = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.accountSource) ? opportunityWrapper.businessOpportunity.businessAccount.accountSource: null;
                        accountRecord.Origin__c = '02';
                        opportunityRecord.AccountId = accountRecord.id;
                    
                        
                        if(opportunityWrapper.businessOpportunity.businessAccount.address != null){
                            accountRecord.BillingStreet = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.street) ? opportunityWrapper.businessOpportunity.businessAccount.address.street : null;
                            accountRecord.BillingPostalCode = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.postalCode) ? opportunityWrapper.businessOpportunity.businessAccount.address.postalCode : null;
                            accountRecord.BillingCity = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.city) ? opportunityWrapper.businessOpportunity.businessAccount.address.city : null;
                            accountRecord.BillingState = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.state) ? opportunityWrapper.businessOpportunity.businessAccount.address.state : null;
                            accountRecord.BillingCountry = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.country) ? opportunityWrapper.businessOpportunity.businessAccount.address.country : null;
                        }
                    }       
                }else 
                {
                   if(accountIdOpportunity!=null){
                        List<Account> clientOrProspect = new List<Account>(SEL_Accounts.newInstance().selectById(accountIdOpportunity));
                        accountRecord = clientOrProspect.get(0);
                        accountAlredyExit = True;
                       if(accountRecord.Type == '01' )
                    	{
                        accountRecord.Type = '01';
                        accountRecord.OwnerId = recordOwner != null? recordOwner.Id : null;                      
                        accountRecord.RecordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get(userIsoCode + '_BusinessAccount').getRecordTypeId();
                        accountRecord.IdExternal__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.idAccount) ? opportunityWrapper.businessOpportunity.businessAccount.idAccount: null;
                        accountRecord.Name = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.company) ? opportunityWrapper.businessOpportunity.businessAccount.company : null;
                        accountRecord.Industry = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.industry) ? opportunityWrapper.businessOpportunity.businessAccount.industry : null;
                        accountRecord.NumberOfEmployees = opportunityWrapper.businessOpportunity.businessAccount.numberEmployees != null ? opportunityWrapper.businessOpportunity.businessAccount.numberEmployees : null;
                        accountRecord.Website = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.website) ? opportunityWrapper.businessOpportunity.businessAccount.website : null;
                        accountRecord.Phone = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.phone) ? opportunityWrapper.businessOpportunity.businessAccount.phone : null;
                        accountRecord.Email__c = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.email) ? opportunityWrapper.businessOpportunity.businessAccount.email : null;
						accountRecord.AccountSource = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.accountSource) ? opportunityWrapper.businessOpportunity.businessAccount.accountSource: null;
                        opportunityRecord.LeadSource = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.accountSource) ? opportunityWrapper.businessOpportunity.businessAccount.accountSource: null;
                        accountRecord.Origin__c = '02';
                        opportunityRecord.AccountId = accountRecord.id;
                        
                            if(opportunityWrapper.businessOpportunity.businessAccount.address != null){
                            accountRecord.BillingStreet = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.street) ? opportunityWrapper.businessOpportunity.businessAccount.address.street : null;
                            accountRecord.BillingPostalCode = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.postalCode) ? opportunityWrapper.businessOpportunity.businessAccount.address.postalCode : null;
                            accountRecord.BillingCity = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.city) ? opportunityWrapper.businessOpportunity.businessAccount.address.city : null;
                            accountRecord.BillingState = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.state) ? opportunityWrapper.businessOpportunity.businessAccount.address.state : null;
                            accountRecord.BillingCountry = String.isNotEmpty(opportunityWrapper.businessOpportunity.businessAccount.address.country) ? opportunityWrapper.businessOpportunity.businessAccount.address.country : null;
                                }
                        }
                    }else
                    {
                    	throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, please include a valid Document Type and Document Number');
                    }
                }
                                
            }else 
            {
                throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, please include a valid Business Account');
            }
            if(opportunityWrapper.businessOpportunity.productInformation != null && opportunityWrapper.businessOpportunity.productInformation.quotes != null){
                for (Quote q : opportunityWrapper.businessOpportunity.productInformation.quotes) {
                    Asset asset = new Asset();
                    asset.ISOCode__c = userIsoCode;
                    asset.IdExternal__c = q.id != null ? q.Id : null;
                    asset.Name = asset.IdExternal__c;
                    asset.IdInternal__c = String.isBlank(asset.IdInternal__c) && String.isNotBlank(asset.IdExternal__c) ? asset.ISOCode__c + '_' + asset.IdExternal__c : asset.IdInternal__c;
                    asset.IssueDate__c = q.issueDate != null ? q.issueDate : null;
                    asset.DueDate__c = q.dueDate != null ? q.dueDate : null;
                    asset.EffectiveDate__c = q.effectiveDate != null ? q.effectiveDate : null;
                    asset.ExpirationDate__c = q.expirationDate != null ? q.expirationDate : null;
                    asset.ProductCode__c = q.productCode != null ? q.productCode : null;
                    asset.ProductName__c = q.productName != null ? q.productName : null;
                    asset.NetPremium__c = q.netPremium != null ? q.netPremium : null;
                    asset.TotalPremiumFactured__c = q.totalPremium != null ? q.totalPremium : null;
                    asset.PaymentMethod__c = q.paymentMethod != null ? q.paymentMethod : null;
                    asset.PaymentPeriodicity__c = q.paymentPeriodicity != null ? q.paymentPeriodicity : null;
                    asset.PaymentTerm__c = q.paymentTerm != null ? q.paymentTerm : null;
                    asset.CurrencyIsoCode = q.currencyIsoCode != null ? q.currencyIsoCode : null;
                    asset.IsSelected__c = q.isSelected != null ? q.isSelected : null;
                    asset.Discount__c = q.discount != null ? q.discount : null;
                    asset.AdditionalInformation__c = q.additionalInformation != null ? q.additionalInformation : null;
                    if (String.isNotEmpty(q.regionalOffice)) {
    
                        List<Account> accounts = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.regionalOffice);
    
                        asset.RegionalOffice__c = !accounts.isEmpty() ? accounts[0].Id : null;
                    }
                    if (String.isNotEmpty(q.managerOffice)) {
                 
                        List<Account> accounts = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.managerOffice);
                       
                     
                        asset.ManagersOffice__c = !accounts.isEmpty() ? accounts[0].Id : null;
                    }
                    if (String.isNotEmpty(q.idIntermediate)) {
                 
                        List<AccountRole__c> accountRoles = SEL_AccountRoles.newInstance().selectByIdInternal(userIsoCode + '_' + q.idIntermediate);
                       
                     
                        asset.AccountRoleIntermediaryId__c = !accountRoles.isEmpty() ? accountRoles[0].Id : null;
                    }
                    asset.IsSelected__c = q.isSelected != null ? q.isSelected : null;
     
                    quotesToInsert.add(asset);

                    if(q.idCompany != null){
                        List <Account> companyAccount = SEL_Accounts.newInstance().selectByIdInternal(userIsoCode + '_' + q.idCompany);
                        if(!companyAccount.isEmpty()){
                            asset.AccountId = companyAccount.get(0).Id;
                        }
                    }
                }

            }
            
        } else 
        {
            throw new EXT_CustomException ('MISSING_REQUIRED_VALUE, please include a valid personOpportunity or businessOpportunity');
        }

        

        Map<Id,User> userForm = new Map<Id,User>(SEL_Users.newInstance().selectGuestUsers());

        System.debug('Account to insert: ' + accountRecord);
        System.debug('Opportunity to insert: ' + opportunityRecord);
        System.debug('Is Guest user?: ' + userForm.containsKey(UserInfo.getUserId()) + ' do the account already exist?: ' + accountAlredyExit);

        try {
            
            if((accountRecord.Type == '01' && !userForm.containsKey(UserInfo.getUserId())) ||
            (accountRecord.Type == '01' && userForm.containsKey(UserInfo.getUserId())))
            {
                if(accountAlredyExit)
                {
                    update  accountRecord ;
                }else
                {
                    insert  accountRecord ;
                }
            }
            
            opportunityRecord.AccountId = accountRecord.Id;
            if(opportunityAlreadyExists)
            {
                update opportunityRecord;
            }else
            {
                insert opportunityRecord;
            }
           
            for(Asset q : quotesToInsert){
                
                q.OpportunityId__c = opportunityRecord.Id;
                if(accountRecord.Id != null){
                    q.HolderId__c = accountRecord.Id;
                }

            }
    
            upsert quotesToInsert IdInternal__c;
            if(taskToUpdate != null)
            {
                update taskToUpdate;
            }
            System.debug('Account inserted: ' + accountRecord);
            System.debug('Opportunity inserted: ' + opportunityRecord);
            result.opportunityId =  opportunityRecord.Id;
			result.accountId = opportunityRecord.AccountId;
            Account currentRecord = new SEL_Accounts().selectByIdWithContacts(opportunityRecord.AccountId).get(0);
            if(!currentRecord.Contacts.isEmpty()){
                result.contactId = currentRecord.Contacts[0].Id;
            }          
            results.add(result);
        } catch(DmlException e) {
            throw new EXT_CustomException ('DML_EXCEPTION, ' + e.getMessage());
        }
        return results;
    }
    else{
        
        for(String eId : errors.keySet()){
            Result resultError = new Result();
            resultError.resultErrors = new List<ResultErrors>();
                for (String e : errors.get(eId)){
                    ResultErrors errorToDisplay = new resultErrors();
                    errorToDisplay.errorMessage = e;
                    resultError.resultErrors.add(errorToDisplay);
                }
            results.add(resultError);
        } 
        return results;
    }
    
}



    /*
     * 
     *      WRAPPER
     *
     */
    

    global class OpportunityWrapper {
        global String   idOpportunity;
        global String   idOwner;
        global String idInternal;
        global String   intermediaryCode;
        global String   opportunityNumber;
        global String   campaignId;
        global String   probability;
        global Date     startDate;
        global Date     closeDate;
        global String   opportunityType;
        global Decimal  amount;
        global String   currencyIsoCode;
        global String   description;

        global OpportunityCustom       opportunityCustom;
        global PolicyInformation   policyInformation;
        global PersonOpportunity       personOpportunity;
        global BusinessOpportunity     businessOpportunity;
    }

    global class OpportunityCustom {
        global String  OfficialAndAlternateChannel;
    }

    global class PolicyInformation {
        global String   competitorCode; 
        global Decimal  polNetPremium;
        global Date     polExpDate;
        global String convertedStatus;
        global String policyNumber;
        global Decimal totalPremium;
    }

    global class PersonOpportunity {
        global ProductInformation   productInformation;
        global String   stage;
        global PersonAccount   personAccount;
    }

    global class BusinessOpportunity {
        global ProductInformation   productInformation;
        global String   stage;
        global BusinessAccount businessAccount;
    }

    global class ProductInformation {
        global String sector;
        global String subSector;
        global String branch;
        global String productCode;
        global String productName;
        global String interestProduct;
        global String additionalInformation;
        global String businessLine;
        global String risk; 
        global Quote[] quotes;
    }

    global class Quote {
        global String id;
        global Date issueDate;
        global Date dueDate;
        global Date effectiveDate;
        global Date expirationDate;
        global String productCode;
        global String productName;
        global Decimal netPremium;
        global Decimal totalPremium;
        global Decimal discount; 
        global String paymentMethod;
        global String paymentPeriodicity; 
        global String paymentTerm; 
        global String currencyIsoCode; 
        global String additionalInformation; 
        global boolean isSelected;
        global String idIntermediate;
        global String regionalOffice;
        global String managerOffice;
        global String idCompany;
    }

    global class PersonAccount {
        global String   idAccount;
        global String   salutation;
        global String   firstName;
        global String   middleName;
        global String   lastName;
        global String   suffix;
        global String   documentType;
        global String   documentNumber;
        global Date     birthdate;
        global String   sex; 
        global String   maritalStatus; 
        global Integer  numberChildren;        
        global String   profession; 
        global String   occupation; 
        global String   nationality; 
        global String   referenceLanguage; 
        global String   mobilePhone;
        global String   phone;
        global String   email;
        global Address  address;
        global String   accountSource; 
    }

    global class BusinessAccount {
        global String   idAccount;
        global String   company;
        global String   documentType;
        global String   documentNumber;
        global String   industry;
        global Integer  numberEmployees;
        global String   website;
        global String   phone;
        global String   email;
        global Address         address;
        global String   accountSource;
    } 

    global class Address {
        global String street;
        global String postalCode;
        global String city;
        global String state;
        global String country;
    }

    global class Result {
        global String opportunityId;
		global String accountId;
        global String contactId;
        global List<ResultErrors> resultErrors;
    }
    global class ResultErrors{
        global String errorMessage;
    }

    global static boolean validationRules (Map<String, List<String>> e, OpportunityWrapper ow){
        Boolean valid;
        
        List <String> errorsList = new List<String>();
        List<Account> existingAccount = new List<Account>();


        //General validations


        if (ow.startDate != null){
            if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', ow.startDate + '')) {
                errorsList.add('Invalid StartDate Format');
                
            }
        }
        if(ow.closeDate != null){
            if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', ow.closeDate + '')) {
                errorsList.add('Invalid CloseDate Format');
                
            }
        }

        if(ow.policyInformation != null){
            if (ow.policyInformation.polExpDate != null){
                if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', ow.policyInformation.polExpDate + '')) {
                    errorsList.add('Invalid PolDate Format');     
                }
            }
            
            if(ow.policyInformation.convertedStatus != null){
                if(ow.policyInformation.convertedStatus == '02' && ow.policyInformation.policyNumber == null){
                    errorsList.add('You must complete the PolicyNumber field');         
                }
            if (!pickListValidation('ConvertedStatus__c', ow.policyInformation.convertedStatus)){
                errorsList.add('Select a valid ConvertedStatus');
                
            }
        }
    

        }
        if (!pickListValidation('Probability__c', ow.probability)){
            errorsList.add('Select a valid Probability');
            
        }
        if (!pickListValidation('Type', ow.opportunityType)){
            errorsList.add('Select a valid Type');
            
        }
        if (!pickListValidation('CurrencyIsoCode', ow.currencyIsoCode)){
            errorsList.add('Select a valid CurrencyIsoCode');
            
        }
    

        //Person validations

        if (ow.personOpportunity != null && ow.businessOpportunity == null){

            if(ow.personOpportunity.personAccount.idAccount != null){
                existingAccount = SEL_Accounts.newInstance().selectById(ow.personOpportunity.personAccount.idAccount);
            }
                       
            if (existingAccount.isEmpty()){
                if(ow.personOpportunity.personAccount.email != null){
                    if(!Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', ow.personOpportunity.personAccount.email)){
                        errorsList.add('Invalid Email format');
                    }
                }
                if (ow.personOpportunity.personAccount.email == null && ow.personOpportunity.personAccount.mobilePhone == null && ow.personOpportunity.personAccount.phone == null){
                    errorsList.add('You must complete at least one contact information field');
                }
            }

            

            if(ow.policyInformation != null && ow.policyInformation.convertedStatus != null){
                if((ow.policyInformation.convertedStatus == '01' || ow.policyInformation.convertedStatus == '02') && (ow.personOpportunity.personAccount.documentType == null && ow.personOpportunity.personAccount.documentNumber == null)){
                    errorsList.add('You must complete both DocumentType and DocumentNumber fields');
                }
                if (ow.policyInformation.convertedStatus == '01'){
                    ow.personOpportunity.stage = '07';
                }
                else if (ow.policyInformation.convertedStatus == '02'){
                    ow.personOpportunity.stage = '06';
                }
            }

            if(ow.personOpportunity.productInformation != null){
                if (!pickListValidation('Sector__c', ow.personOpportunity.productInformation.sector)){
                    errorsList.add('Select a valid Sector');
                    
                }
                if (!pickListValidation('SubSector__c', ow.personOpportunity.productInformation.subSector)){
                    errorsList.add('Select a valid Subsector');
                    
                }
                if (!pickListValidation('Branch__c', ow.personOpportunity.productInformation.branch)){
                    errorsList.add('Select a valid Branch');
                    
                }
                if (!pickListValidation('BusinessLine__c', ow.personOpportunity.productInformation.businessLine)){
                    errorsList.add('Select a valid BusinessLine');
                    
                }
            }
            
            //Person account validations

            if (ow.personOpportunity.personAccount != null){

                if(ow.personOpportunity.personAccount.birthdate != null){
                    if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', ow.personOpportunity.personAccount.birthdate + '')) {
                        errorsList.add('Invalid BirthDate Format');
                        
                    }
                }
                if (!pickListValidationAccount('Salutation', ow.personOpportunity.personAccount.salutation)){
                    errorsList.add('Select a valid Salutation');
                }
                if (!pickListValidationAccount('DocumentType__pc', ow.personOpportunity.personAccount.documentType)){
                    errorsList.add('Select a valid DocumentType');
                }
                if (!pickListValidationAccount('Sex__pc', ow.personOpportunity.personAccount.sex)){
                    errorsList.add('Select a valid Sex');
                }
                if (!pickListValidationAccount('MaritalStatus__pc', ow.personOpportunity.personAccount.maritalStatus)){
                    errorsList.add('Select a valid MaritalStatus');
                }
                if (!pickListValidationAccount('Profession__pc', ow.personOpportunity.personAccount.profession)){
                    errorsList.add('Select a valid Profession');
                }
                if (!pickListValidationAccount('Occupation__pc', ow.personOpportunity.personAccount.occupation)){
                    errorsList.add('Select a valid Occupation');
                }
                if (!pickListValidationAccount('Nationality__pc', ow.personOpportunity.personAccount.nationality)){
                    errorsList.add('Select a valid Nacionality');
                }
                if (!pickListValidationAccount('ReferenceLanguage__pc', ow.personOpportunity.personAccount.referenceLanguage)){
                    errorsList.add('Select a valid ReferenceLanguage');
                }
                if (!pickListValidationAccount('AccountSource', ow.personOpportunity.personAccount.accountSource)){
                    errorsList.add('Select a valid AccountSource');    
                }
            }

            //Person Quote validations
           if(ow.personOpportunity.productInformation != null && ow.personOpportunity.productInformation.quotes != null){
                for (Quote q : ow.personOpportunity.productInformation.quotes) {

                    if(!picklistValidationQuote('CurrencyIsoCode', q.currencyIsoCode)){
                        errorsList.add('Select a valid CurrencyIsoCode Quote');
                    }
                    if(!picklistValidationQuote('PaymentMethod__c', q.paymentMethod)){
                        errorsList.add('Select a valid PaymentMethod');
                    }
                    if(!picklistValidationQuote('PaymentTerm__c', q.paymentTerm)){
                        errorsList.add('Select a valid PaymentTerm');
                    }
                    if(!picklistValidationQuote('PaymentPeriodicity__c', q.paymentPeriodicity)){
                        errorsList.add('Select a valid PaymentPeriodicity');
                    }
                    if(q.issueDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.issueDate + '')) {
                            errorsList.add('Invalid IssueDate Format');
                        
                        }
                    }
                    if(q.dueDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.dueDate + '')) {
                            errorsList.add('Invalid DueDate format');
            
                        }
                    }
                    if(q.effectiveDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.effectiveDate + '')) {
                            errorsList.add('Invalid EffectiveDate format');
                            
                        }
                    }
                    if(q.expirationDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.expirationDate + '')) {
                            errorsList.add('Invalid ExpirationDate format');
                            
                        }
                    }
                }
            }
            
        }

        //Business validations

        else if (ow.personOpportunity == null && ow.businessOpportunity != null){   

            if(ow.policyInformation != null && ow.policyInformation.convertedStatus != null){
                if((ow.policyInformation.convertedStatus == '01' || ow.policyInformation.convertedStatus == '02') && (ow.businessOpportunity.businessAccount.documentType == null && ow.businessOpportunity.businessAccount.documentNumber == null)){
                    errorsList.add('You must complete both DocumentType and DocumentNumber fields');
                }
                if (ow.policyInformation.convertedStatus == '01'){
                    ow.businessOpportunity.stage = '07';
                }
                else if (ow.policyInformation.convertedStatus == '02'){
                    ow.businessOpportunity.stage = '06';
                }
            }
            if(ow.businessOpportunity.businessAccount.idAccount != null){
                existingAccount = SEL_Accounts.newInstance().selectById(ow.businessOpportunity.businessAccount.idAccount);
            }
                       
            if (existingAccount.isEmpty()){
                if(ow.businessOpportunity.businessAccount.email != null){
                    if(!Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', ow.businessOpportunity.businessAccount.email)){
                        errorsList.add('Invalid Email format');
                    }
                }
                if (ow.businessOpportunity.businessAccount.email == null && ow.businessOpportunity.businessAccount.phone == null){
                    errorsList.add('You must complete at least one contact information field');
                }
            }
            if(ow.businessOpportunity.productInformation != null){
                
                if (!pickListValidation('Sector__c', ow.businessOpportunity.productInformation.sector)){
                    errorsList.add('Select a valid Sector');
                    
                }
                if (!pickListValidation('SubSector__c', ow.businessOpportunity.productInformation.subSector)){
                    errorsList.add('Select a valid Subsector');
                    
                }
                if (!pickListValidation('Branch__c', ow.businessOpportunity.productInformation.branch)){
                    errorsList.add('Select a valid Branch');
                    
                }
                if (!pickListValidation('BusinessLine__c', ow.businessOpportunity.productInformation.businessLine)){
                    errorsList.add('Select a valid BusinessLine');
                    
                }   
            }


            //Business Account validations

            if (ow.businessOpportunity.businessAccount != null){
                if (!pickListValidationAccount('DocumentType__c', ow.businessOpportunity.businessAccount.documentType)){
                    errorsList.add('Select a valid DocumentType Business');
                    
                }
                if (!pickListValidationAccount('AccountSource', ow.businessOpportunity.businessAccount.accountSource)){
                    errorsList.add('Select a valid AccountSource Business');
                    
                }
            }

            //Business Quote validations
            
            if(ow.businessOpportunity.productInformation !=null && ow.businessOpportunity.productInformation.quotes != null){
                for (Quote q : ow.businessOpportunity.productInformation.quotes) {
                    if(!picklistValidationQuote('CurrencyIsoCode', q.currencyIsoCode)){
                        errorsList.add('Select a valid CurrencyIsoCode Quote');
                    }
                    if(!picklistValidationQuote('PaymentMethod__c', q.paymentMethod)){
                        errorsList.add('Select a valid PaymentMethod');
                    }
                    if(!picklistValidationQuote('PaymentTerm__c', q.paymentTerm)){
                        errorsList.add('Select a valid PaymentTerm');
                    }
                    if(!picklistValidationQuote('PaymentPeriodicity__c', q.paymentPeriodicity)){
                        errorsList.add('Select a valid PaymentPeriodicity');
                    }
                    if(q.issueDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.issueDate + '')) {
                            errorsList.add('Invalid IssueDate format');
                        
                        }
                    }
                    if(q.dueDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.dueDate + '')) {
                            errorsList.add('Invalid DueDate format');
            
                        }
                    }
                    if(q.effectiveDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.effectiveDate + '')) {
                            errorsList.add('Invalid EffectiveDate format');
                            
                        }
                    }
                    if(q.expirationDate != null){
                        if(!Pattern.matches('^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$', q.expirationDate + '')) {
                            errorsList.add('Invalid ExpirationDate format');
                            
                        }
                    }
                }
            }
            
        }
        else{
            errorsList.add('You must select a Business or Person type');
            
        }
       
        e.put(ow.idOpportunity, errorsList);
        
        
        return errorsList.isEmpty() ? true : false;
    }
    global static boolean picklistValidation(String picklistField, String jsonValue){
        boolean valid;
        List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get(picklistField).getDescribe().getPicklistValues();
            for (Schema.PicklistEntry pv : picklistValues) {
                if(jsonValue == pv.getValue() || jsonValue == null){
                    valid = true;
                    break;
                }
                 else {
                    valid = false;
                }
            }
        return valid;
    }
    global static boolean picklistValidationAccount(String picklistField, String jsonValue){
        boolean valid;
        List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get(picklistField).getDescribe().getPicklistValues();
            for (Schema.PicklistEntry pv : picklistValues) {
                if(jsonValue == pv.getValue() || jsonValue == null){
                    valid = true;
                    break;
                }
                 else {
                    valid = false;
                }
            }
        return valid;
    }
    global static boolean picklistValidationQuote(String picklistField, String jsonValue){
        boolean valid;
        List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Asset').getDescribe().fields.getMap().get(picklistField).getDescribe().getPicklistValues();
            for (Schema.PicklistEntry pv : picklistValues) {
                if(jsonValue == pv.getValue() || jsonValue == null){
                    valid = true;
                    break;
                } else {
                    valid = false;
                }
            }
        return valid;
    }
}