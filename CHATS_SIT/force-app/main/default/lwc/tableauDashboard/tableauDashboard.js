import { LightningElement } from 'lwc';
export default class TableauDashboard extends LightningElement 
{
    buttons = 
    [
        { label: 'Application Pending',           url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/ApplicationPending?:iid=2'},
        { label: 'Redetermination Pending',       url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/RedeterminationPending?:iid=1'},
        { label: 'Redetermination for the month', url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/RedeterminationFortheMonth?:iid=1'},
        { label: 'Application Backlog',           url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/ApplicationBacklog?:iid=1'},
        { label: 'Redetermination Backlog',       url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/RedeterminationBacklog?:iid=1'},
        { label: 'Redetermination Timeliness',    url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/RedeterminationTimeliness?:iid=1'},
        { label: 'Application Timeliness',        url: 'https://tableau.private.state.co.us/#/site/CDHSHCPFPerformancePortal/views/TableauDashboard_17279232515600/ApplicationTimeliness?:iid=2'}
    ];

    navigateToUrl(url) 
    {
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.target = '_blank';
        anchor.rel = 'noopener noreferrer'; /* Security measure */
        anchor.click();
    }

    // Event handler for button clicks
    handleButtonClick(event) 
    {
        const url = event.target.dataset.url;
        this.navigateToUrl(url);
    }
}