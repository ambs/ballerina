package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;
use YAML::Tiny;

our $_SCHEMA = YAML::Tiny->read("database.yml");


hook before_template_render => sub {
    my $tokens = shift;
    $tokens->{tables} = [schema->sources];
};

get '/' => sub {
    template 'index';
};

[% FOREACH table IN tables %]
get '/[% table.name %]' => sub {
	my $table = { name => "[% table.name %]" };

	template 'table' => {
		table => $table,
	};
};
[% END %]

true;
