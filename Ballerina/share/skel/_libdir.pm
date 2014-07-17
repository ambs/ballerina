package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;

hook before_template_render => sub {
    my $tokens = shift;
    $tokens->{tables} = [schema->sources];
};

get '/' => sub {
    template 'index';
};

true;
