# ABSTRACT: Ballerina build modules.

use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';


package Ballerina;

use Carp;
use File::Spec;
use IO::Prompt;
use YAML::Tiny;
use DBIx::Class::Schema::Loader qw/make_schema_at/;
use File::Path qw(remove_tree make_path);

sub new($class, %config) {
	my $self = bless { conf => \%config }, $class;
	$self->_init_folder();
	return $self;
}

sub save($self) {
	my $yaml = YAML::Tiny->new( $self->{conf} );
	$yaml->write( File::Spec->catfile($self->conf('root'), "ballerina.yml"));
}

sub conf($self, $param) {
	return $self->{conf}{$param};
}

sub _init_folder($self) {
	my $root = $self->conf('root');

	if (!$self->conf('force') && -d $root) {
		croak "Not overwriting folder. Bailing out.\n" 
			unless prompt "Folder $root exists. Overwrite? ", '-tyn1';
		remove_tree $root;
	}

	make_path $root;
}


sub compute_dbix_class($self) {
	my $lib_folder = File::Spec->catfile($self->conf('root'), "lib");
	my $dsn = sprintf("DBI:mysql:database=%s;host=%s;port=%s", 
			   map { $self->conf($_) } qw/database db-server db-port/);

	make_schema_at $self->conf('name') . "::Schema",
	               { dump_directory => $lib_folder },
	               [ $dsn, $self->conf('db-user'), $self->conf('db-password') ]
}

1;
