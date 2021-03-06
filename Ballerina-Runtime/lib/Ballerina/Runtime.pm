# ABSTRACT: Ballerina backend.

use strict;
use warnings;
package Ballerina::Runtime;

use YAML::Tiny;

sub new {
	my $class = shift;
	my $self = { schema => YAML::Tiny->read("database.yml")->[0] };
	return bless $self, $class;
}

sub table_info {
	my ($self, $table) = @_;
	return +{
		name     => $table,
		label    => $self->table_label($table),
	    columns  => $self->table_columns($table),
	    coltypes => $self->table_coltypes($table),
	    keys     => $self->table_keys($table),
	};
}

sub table_coltypes {
	my ($self, $table) = @_;
	die "Unknown table $table" unless exists $self->{schema}{$table};

	return $self->{schema}{$table}{columns}
}

sub table_label {
	my ($self, $table) = @_;
	die "Unknown table $table" unless exists $self->{schema}{$table};

	return $self->{schema}{$table}{label} || $table;
}

sub table_columns {
	my ($self, $table) = @_;
	die "Unknown table $table" unless exists $self->{schema}{$table};

	return [ sort {
	    $self->{schema}{$table}{columns}{$a}{order}
	    <=>
	    $self->{schema}{$table}{columns}{$b}{order}
	} keys %{$self->{schema}{$table}{columns}} ];
}

sub table_keys {
	my ($self, $table) = @_;
	die "Unknown table $table" unless exists $self->{schema}{$table};

	[ grep {
    	exists($self->{schema}{$table}{columns}{$_}{is_primary_key})
	} keys %{$self->{schema}{$table}{columns}} ];
}


1;
