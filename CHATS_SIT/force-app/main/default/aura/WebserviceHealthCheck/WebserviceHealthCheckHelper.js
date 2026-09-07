({
	generateChart : function(component,componentName,data) {
        
        var chartdata = {
            labels: ['Success','Failure'],
            datasets: [
                {
                    data: [data.success,data.failure],
                    backgroundColor: ['#5ece30','#ff4242']
                }
            ]
        }
        
        var ctx = component.find(componentName).getElement();
        var lineChart = new Chart(ctx ,{
            type: 'pie',
            data: chartdata,
            options: {
                responsive: true,
                maintainAspectRatio: false,
            }
        });
        
	}
})