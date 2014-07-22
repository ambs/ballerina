package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Deferred;
use YAML::Tiny;
use Try::Tiny;

our $_SCHEMA = YAML::Tiny->read("database.yml")->[0];

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
		name    => $table,
	    columns => [ sort {
	    	$_SCHEMA->{$table}{$a}{order} <=> $_SCHEMA->{$table}{$b}{order}
	    } keys %{$_SCHEMA->{$table}} ],
	    coltypes => $_SCHEMA->{$table},
	};

	template 'table' => {
		table => $table_info,
		rows  => [ schema->resultset($table)->search( undef, { rows => 1000 })],
	};
};

get '/[% table.name %]/new' => sub {
	my $table = "[% table.name %]";
	my $table_info = {
		name    => $table,
	    columns => [ sort {
	    	$_SCHEMA->{$table}{$a}{order} <=> $_SCHEMA->{$table}{$b}{order}
	    } keys %{$_SCHEMA->{$table}} ],
	    coltypes => $_SCHEMA->{$table},
	};

	template 'new_record' => {
		table => $table_info,
	};
};

post '/[% table.name %]' => sub {
	my $table  = "[% table.name %]";	
	my $action = param('action') || "NOOP";

	if ($action eq "new") {		
		## XXX - For now, not testing if all is filled up
		
		my %record = map  { ($_ => param "input_$_" ) }
					 map  { s/^input_//; $_ }
					 grep { m!^input_! }
					 keys params();

		schema->resultset($table)->create({%record});
		deferred type    => 'success';
		deferred message => "Record added successfully";
		## XXX - later check if there was an error.
		redirect "/$table";
	}
	else {
		forward "/$table", { }, { method => 'GET' };
	}
};
[% END %]

true;
