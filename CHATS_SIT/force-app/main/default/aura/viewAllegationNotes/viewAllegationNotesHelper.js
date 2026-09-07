({
	openPDF : function(cmp, evt, hlp) {
		var recId = cmp.get("v.recordId");
        var pdfWin= window.open("/apex/AllegationNotesView?ipvInformationId="+recId+" ", "", "height=650,width=840");
	window.parent.location = '/' + recId;
	}
})