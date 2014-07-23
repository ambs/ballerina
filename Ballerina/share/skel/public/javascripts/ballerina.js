
function edit_record(table, pos) {
	var target = table + "/edit";
	var form = '<form action="' + target + '" method="POST">';
	$.each( records[pos], function (key, val) {
		// XXX - FIXME: encode value somehow
		form += "<input type='hidden' name='input_" + key + "' value='" + val + "'/>";
	});
	form += "</form>";
	$(form).appendTo('body').submit();
}

function delete_record(pos) {
	var form = "";
	$.each( records[pos], function(key, val) {
		form += "<div><b>" + key + ":</b> " + val + "</div>";
	});
	$('#delete-modal-record').html(form);
	$('#delete-modal').modal();
}