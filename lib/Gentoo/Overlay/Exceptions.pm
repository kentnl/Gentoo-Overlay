use strict;
use warnings;

package Gentoo::Overlay::Exceptions;

use Moose;
use MooseX::Types::Moose qw( :all );
use Sub::Exporter ();
use Readonly;

Readonly our $W_SILENT => 'silent';
Readonly our $W_WARNING => 'warning';
Readonly our $W_FATAL => 'fatal';

our $WARNINGS_ARE= $W_WARNING;


has 'payload' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1,
  default  => sub { {} },
);

sub as_string {
  my ($self) = @_;
  join qq{}, $self->message, "\n\n  ", ( join qq{\n*  }, ( split /\n/, $self->stack_trace ) ), "\n";
}

use overload ( q{""} => 'as_string' );

sub exception {
  return __PACKAGE__->throw(@_);
}

sub warning {
  # This code is because warnings::register sucks.
  # You can't do long-distance warning-changes that behave
  # similar to exceptions.
  #
  # warnings::register can only be toggled in the direcltly
  # preceeding scope.

  return if(  $WARNINGS_ARE eq $W_SILENT );
  if( $WARNINGS_ARE eq $W_WARNING ){
      return warn __PACKAGE__->new(@_);
  }
  return __PACKAGE__->throw(@_);
}

Sub::Exporter::setup_exporter( { exports => [ 'exception', 'warning', ] } );
use Data::Dump qw( dump );
with(
  'Throwable',
  'Role::Identifiable::HasIdent',
  'Role::Identifiable::HasTags',
  'Role::HasMessage::Errf' => {
    lazy    => 1,
    default => sub { shift->ident }
  },
  'StackTrace::Auto',
  'MooseX::OneArgNew' => {
    type     => Str,
    init_arg => 'ident',
  },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );    # Mx::OneArg's fault.

1;

__END__
use Sub::Exporter ();
extends qw( Throwable::Error );
with qw( StackTrace::Auto );

my $heirachy = {
  'Overlay::MissingFile' => {},
  'Overlay::MissingDir'  => {},
  'Category::Missing' => {},
  'Internal::DefaultPath' => {},
  }

  ;
my $methodmap = {};

for my $class ( keys %{$heirachy} ) {
  my $classname = __PACKAGE__ . q{::} . $class;
  eval sprintf '{ package %s; use Moose; extends q{Gentoo::Overlay::Exceptions}; }  1;', $classname;
  my $filename = $classname;
  $filename =~ s{::}{/}g;
  $filename =~ s/$/.pm/;
  $INC{$filename} = __FILE__;

  my $exceptionname = $class;
  $exceptionname =~ s/:://g;
  $exceptionname =~ s/$/Exception/;
  $methodmap->{$exceptionname} = $classname;
}

sub _caller_generator {
  my ( $class, $name, $arg ) = @_;
  my $zname = $methodmap->{$name};
  return eval qq[sub() { $zname } ];
}

Sub::Exporter::setup_exporter( { exports => [ map { $_, \&_caller_generator } keys %{$methodmap} ] } );

#__PACKAGE__->meta->make_immutable;
1;
