/**
 * Created by abdellah on 03/12/2019.
 */

trigger OpportunityTrigger on Opportunity (after update) {
    new OpportunityTriggerHandler().run();
}