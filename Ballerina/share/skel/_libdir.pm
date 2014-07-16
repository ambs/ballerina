package [% appname %];
use Dancer2;
use Dancer2::Plugin::DBIC;

get '/' => sub {
    template 'index';
};

true;
