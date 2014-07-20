package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;
use YAML::Tiny;

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
	};

	template 'new_record' => {
		table => $table_info,
	};
};
[% END %]

true;
