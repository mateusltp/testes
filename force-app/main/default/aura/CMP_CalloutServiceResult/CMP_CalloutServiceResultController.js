({
	doInit : function(component, event, helper) {
		var onDemandad = component.get("v.loadStartup");
		if (onDemandad == 'True') {
			helper.getCalloutResults(component, helper);
		}
    },
    showModal : function(component, event, helper) {
        var modal = component.find("modalView");
        modal.showModal(); 
	},
	onLoad : function(component, event, helper) {
		helper.getCalloutResults(component, helper);
    },
    openDocument: function(component, event, helper) {
		helper.getContentData(component,event,helper);
		helper.previewFile(component,event,helper);
    },
	navigateToLink: function(component, event, helper) {
		var navEvt = $A.get("e.force:navigateToSObject");
        var idSF = event.currentTarget.getAttribute("data-attriVal");
        navEvt.setParams({
          "recordId": idSF,
          "slideDevName": "related"
        });
	    navEvt.fire();
	}
	
})