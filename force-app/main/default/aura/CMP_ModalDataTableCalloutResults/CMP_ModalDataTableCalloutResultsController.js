({
	hideModal:function(component,event,helper){    
		var cmpTarget = component.find('Modalbox');
		var cmpBack = component.find('Modalbackdrop');
		$A.util.removeClass(cmpBack,'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open'); 
    	},
	showModal:function(component,event,helper) {
        helper.initializeData(component);
		var cmpTarget = component.find('Modalbox');
		var cmpBack = component.find('Modalbackdrop');
		$A.util.addClass(cmpTarget, 'slds-fade-in-open');
		$A.util.addClass(cmpBack, 'slds-backdrop--open'); 
	},
    handleSearch:function(component,event,helper) {
        helper.filterData(component);
    },
    handleSort:function(component,event,helper) {
        component.set('v.sortedBy', event.getParam('fieldName'));
        component.set('v.sortedDirection', event.getParam('sortDirection'));
        helper.sortData(component);
    },
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'download':
                helper.basetoBlobDownload(row);
                break;
            case 'preview':
                helper.preview(cmp,row);
                break;
            default:
                break;
        }
    }
})