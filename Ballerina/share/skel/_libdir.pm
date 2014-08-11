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

### [% table.name %]

get '/[% table.name %]' => sub {
	my $table = "[% table.name %]";
	my $table_info = $ballerina->table_info($table);

	my @keys = @{ $table_info->{keys} };
	my $rows = [ schema->resultset($table)->search( undef,
		   	                                  { rows => 1000 })];
	my $json = to_json( [ map { my $row = $_; +{ map { ($_ => $row->$_ )} @keys} } @$rows ] );

	template 'table' => {
		table => $table_info,
		rows  => $rows,
		json  => $json,
	};
};

post qr{/[% table.name %]/(view|edit)} => sub {
	my ($action) = splat;
	my $table = "[% table.name %]";
	my $table_info = $ballerina->table_info($table);
	my %record_keys = map  { ($_ => param "input_$_" ) }
					  map  { s/^input_//; $_ }
					  grep { m!^input_! }
					  keys %{ params() };
	my ($row) = schema->resultset($table)->search( \%record_keys );
	template 'record' => {
		table => $table_info,
		type  => $action,
		row   => $row,
	};
};

get '/[% table.name %]/new' => sub {
	my $table = "[% table.name %]";
	## FIXME: make this a method from Runtime
	my $table_info = $ballerina->table_info($table);
	template 'record' => {
		type  => 'new',
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
	deferred type    => 'warning';
	deferred message => "Record deleted successfully";
	redirect "/$table";
};

post '/[% table.name %]' => sub {
	my $table  = "[% table.name %]";	
	my $action = param('action') || "NOOP";

	if ($action eq "new") {		
		## FIXME - For now, not testing if all is filled up
		## Also, generalize this as a Ballerina-> method.
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
