({
	doInit : function(component) {
		var rid = component.get("v.recordId");
        var action = component.get("c.getOpportunity");
        action.setParams({oppId : rid});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				var opp = response.getReturnValue();

				if(opp.TemplateCotation__c == 'C5'){
					component.set("v.isC5", true);
					component.set("v.isC4", false);
				} else if(opp.TemplateCotation__c == 'C1/C2/C3/C4'){
					component.set("v.isC5", false);
					component.set("v.isC4", true);
				} else {
					component.set("v.isC5", false);
					component.set("v.isC4", false);
				}
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } 
                else {
                    console.log("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
	}
})