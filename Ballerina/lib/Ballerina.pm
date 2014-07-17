# ABSTRACT: Ballerina build modules.

use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';


package Ballerina;

use Carp;
use File::Spec;
use File::Copy;
use File::Temp 'tempfile';
use File::Find;
use IO::Prompt;
use YAML::Tiny;
use DBIx::Class::Schema::Loader qw/make_schema_at/;
use File::Path qw(remove_tree make_path);
use Dancer2::CLI::Command::gen 0.143000;
use LWP::Simple;
use Template;

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

sub set_conf($self, $param, $value) {
	$self->{conf}{$param} = $value;
}


sub compute_dbix_class($self) {
	$self->log("Generating DBIx::Class schema.");

	my $lib_folder = File::Spec->catfile($self->conf('root'), "lib");
	my $dsn = sprintf("DBI:mysql:database=%s;host=%s;port=%s", 
			   map { $self->conf($_) } qw/database db-server db-port/);

	$self->set_conf(dsn    => $dsn);
	$self->set_conf(schema => $self->conf('name') . "::Schema");

	make_schema_at $self->conf("schema"),
	               { dump_directory => $lib_folder },
	               [ $dsn, $self->conf('db-user'), $self->conf('db-password') ]
}

sub run_dancer2($self) {
	$self->log("Generating Dancer2 skeleton.");

	Dancer2::CLI::Command::gen->execute( {
   		       path => '',
   		   no_check => 1,
  	  	  directory => $self->conf('root'),
		application => $self->conf('name'),
  	} );
}

sub clean_up_dancer2($self) {
	my @files = qw(
		public/css/style.css
		public/images/perldancer-bg.jpg
		public/images/perldancer.jpg
		Makefile.PL
		MANIFEST
		MANIFEST.SKIP		
	);
	for my $f (@files) {
		my $full_path = File::Spec->catfile($self->conf("root"), $f);
		unlink $full_path if -f $full_path;
	}
}
sub fetch_jquery($self) {
	$self->log("Trying to fetch a recent jquery.js version");

	my $target = File::Spec->catfile($self->conf("root"),
	 	                 "public", "javascripts", "jquery.js");
	if (!$self->_download_file("http://code.jquery.com/jquery.min.js" => $target)) {
		print "Failed to retrieve a recent version of jquery.\n";
		print "Using Dancer2 default version.\n";
	}
}

sub fetch_bootstrap($self) {
	$self->log("Trying to fetch a recent bootstrap version");

	my $target = File::Spec->catfile($self->conf("root"),
	 	                 "public", "javascripts", "bootstrap.js");
	if (!$self->_download_file("http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js" => $target)) {
		print "Failed to retrieve a recent version of bootstrap.js.\n";
		print "Using our own version.\n";		
	}

	$target = File::Spec->catfile($self->conf("root"),
	 	                 "public", "css", "bootstrap.js");
	if (!$self->_download_file("http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js" => $target)) {
		print "Failed to retrieve a recent version of bootstrap.css.\n";
		print "Using our own version.\n";		
	}

	$target = File::Spec->catfile($self->conf("root"),
	 	                 "public", "css", "bootstrap-theme.css");
	if (!$self->_download_file("http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap-theme.min.css" => $target)) {
		print "Failed to retrieve a recent version of bootstrap-theme.js.\n";
		print "Using our own version.\n";		
	}
}

sub connect_dbix($self) {
	$self->log("Creating DBIx::Class schema.");

	my $module_path = File::Spec->catfile($self->conf("root"), "lib");
	unshift @INC, $module_path;
	my $schema = $self->conf("schema");
	eval "require $schema";
	$self->{schema} = $schema->connect($self->conf("dsn"));
}

sub log($self, @msg) {
	$self->conf("verbose") && say STDERR @msg;
}

sub create_templates($self) {
	$self->log("Generating extra skeleton files.1")

	$self->clean_up_dancer2;

	my $tt = Template->new() || die "$Template::ERROR\n";
	my $vars = {
					appname => $self->conf("name"),
					author  => $self->conf("author") || "A. U. Thor",					
					email   => $self->conf("email")  || 'a.u.thor@cpan.org',
					db_user => $self->conf("db-user"),
					db_pass => $self->conf("db-password"),
					dsn     => $self->conf("dsn"),
					year    => (localtime(time))[5] + 1900,
			   };

	for my $infile ($self->_find_skel_files()) {
		### XXX - Fixme => share/skel replaced by the correct folder name
		my $outfile = $infile =~ s{share/skel}{$self->conf('root')}re;	
		$outfile =~ s{_libdir}{"lib/" . join("/", split /::/, $self->conf("name"))}e;
	    $tt->process($infile, $vars, $outfile, binmode => ':utf8');
	}

	$self->fetch_jquery;
	$self->fetch_bootstrap;
}

## Auxiliary metods bellow

sub _find_skel_files($self) {
	my @files = ();
	### XXX - Fixme => share replaced by the correct folder name
	find(sub {-f $_ and push @files, $File::Find::name}, "share");
	return @files;
}

sub _init_folder($self) {
	my $root = $self->conf('root');

	if (-d $root) {
		if (!$self->conf('force')) {
			croak "Not overwriting folder. Bailing out.\n" 
				unless prompt "Folder $root exists. Overwrite? ", '-tyn1';
		}
		remove_tree $root;
	}

	make_path $root;
}

sub _download_file($self, $url, $target) {
	my ($fh, $filename) = tempfile();
	my $ans = getstore($url, $filename);
	if (is_success($ans)) {
		move $filename, $target;
		return 1;
	} else {
		return 0;
	}
}


1;
