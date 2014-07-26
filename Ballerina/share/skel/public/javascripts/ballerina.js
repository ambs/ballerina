
/** ballerina.js **/

/**
*
*/
function edit_record(table, pos) {
	var target = table + "/edit";
	var form = '<form action="' + target + '" method="POST">';
	$.each( records[pos], function (key, val) {
		// FIXME: encode value somehow
		form += "<input type='hidden' name='input_" + key + "' value='" + val + "'/>";
	});
	form += "</form>";
	$(form).appendTo('body').submit().remove();
}

/**
*
*/
function delete_record(table) {
	var pos = $('#selected_record').val();
	$.ajax({
		url: table + '/delete',
		data: records[pos],
		type: 'POST'
	}).done(
		function(data) {
			if (data.status == "OK") {
				window.location.replace( table + "/deleted");
			} else {
				error_alert("Error deleting record!");
			}
			$('#delete-modal').modal('hide');
		}
	).fail(
		function() {
			error_alert("Error deleting record!");
			$('#delete-modal').modal('hide');
		}
	);
}

/**
*
*/
function delete_record_modal(pos) {
	var form = '<input id="selected_record" type="hidden" value="'+pos+'"/>';
	$.each( records[pos], function(key, val) {
		form += "<div><b>" + key + ":</b> " + val + "</div>";
	});
	$('#delete-modal-record').html(form);
	$('#delete-modal').modal('show');
}

/**
* Creates a bootstrap Alert with class Success
*/
function success_alert(contents) {
	create_generic_alert('success', contents);
}

/**
* Creates a bootstrap Alert with class Danger
*/
function error_alert(contents) {
	create_generic_alert('danger', contents);
}

/**
* Creates a bootstrap Alert with class Warning
*/
function warning_alert(contents) {
	create_generic_alert('warning', contents);
}

/**
* Creates a generic bootstrap Alert
*/
function create_generic_alert(type, contents) {
	var alert = '<div class="alert alert-' + type + ' alert-dismissible" role="alert">';
	alert += '<button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>';
    alert += contents;
    alert += '</div>';
    $(alert).insertAfter('#title');
}

