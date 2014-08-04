package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Deferred;
use Try::Tiny;

use Ballerina::Runtime;

my $ballerina = Ballerina::Runtime->new;

hook before_template_render => sub {
    my $tokens = shift;
    $tokens->{tables} = [schema->sources];
};

get '/' => sub {
    template 'index';
};

[% FOREACH table IN tables %]
get '/[% table.name %]' => sub {
	my $table = "[% table.name %]";
	my $table_info = {
		name     => $table,
		label    => $ballerina->table_label($table),
	    columns  => [ $ballerina->table_columns($table) ],
	    coltypes => $ballerina->table_coltypes($table),
	};

	my @keys = $ballerina->table_keys($table);
	my $rows = [ schema->resultset($table)->search( undef,
		   	                                  { rows => 1000 })];
	my $json = to_json( [ map { my $row = $_; +{ map { ($_ => $row->$_ )} @keys} } @$rows ] );

	template 'table' => {
		table => $table_info,
		rows  => $rows,
		json  => $json,
	};
};

post '/[% table.name %]/edit' => sub {
	"OK"
};

post '/[% table.name %]/view' => sub {
	"OK"
};

get '/[% table.name %]/new' => sub {
	my $table = "[% table.name %]";
	my $table_info = {
		name    => $table,
	    columns => [ $ballerina->table_columns($table) ],
	    coltypes => $ballerina->table_coltypes($table),
	};

	template 'new_record' => {
		table => $table_info,
	};
};

post '/[% table.name %]/delete' => sub {
	my $table = "[% table.name %]";

	my $status = "OK";
	try {
		schema->resultset($table)->search( { params() } )->delete;
	}
	catch {
		$status = "NOK";
	};
	content_type "json";
	to_json { status => $status };
};

get '/[% table.name %]/deleted' => sub {
	my $table = "[% table.name %]";
	deferred type    => 'success';
	deferred message => "Record deleted successfully";
	redirect "/$table";
};

post '/[% table.name %]' => sub {
	my $table  = "[% table.name %]";	
	my $action = param('action') || "NOOP";

	if ($action eq "new") {		
		## FIXME - For now, not testing if all is filled up

		my %record = map  { ($_ => param "input_$_" ) }
					 map  { s/^input_//; $_ }
					 grep { m!^input_! }
					 keys %{ params() };

		schema->resultset($table)->create({%record});
		deferred type    => 'success';
		deferred message => "Record added successfully";
		## FIXME - later check if there was an error.
		redirect "/$table";
	}
	else {
		forward "/$table", { }, { method => 'GET' };
	}
};
[% END %]

true;
