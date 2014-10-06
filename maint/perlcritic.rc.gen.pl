#!/usr/bin/env perl
## no critic (Modules::RequireVersionVar)

# ABSTRACT: Write an INI file from a bundle

use 5.008;    # utf8
use strict;
use warnings;
use utf8;

our $VERSION = 0.001;

use Carp qw( croak carp );
use Perl::Critic::ProfileCompiler::Util qw( create_bundle );
use Path::Tiny qw(path);

## no critic (ErrorHandling::RequireUseOfExceptions)
my $bundle = create_bundle('Example::Author::KENTNL');
$bundle->configure;

my @stopwords = (
  qw(
    ACCESSORS Ebuilds ebuild Ebuild ebuilds
    )
);
for my $wordlist (@stopwords) {
  $bundle->add_or_append_policy_field( 'Documentation::PodSpelling' => ( 'stop_words' => $wordlist ) );
}
for my $type (qw( Overlay Category Ebuild Package CategoryName EbuildName PackageName RepositoryName )) {
  $bundle->add_or_append_policy_field(
    'Subroutines::ProhibitCallsToUndeclaredSubs' => ( 'exempt_subs' => 'MooseX::Types::Gentoo__Overlay_' . $type, ), );

}
for my $mxtype (qw( class_type coerce from via as where subtype )) {
  $bundle->add_or_append_policy_field(
    'Subroutines::ProhibitCallsToUndeclaredSubs' => ( 'exempt_subs' => 'MooseX::Types::' . $mxtype, ), );

}

$bundle->remove_policy('ErrorHandling::RequireUseOfExceptions');
$bundle->remove_policy('CodeLayout::RequireUseUTF8');

#$bundle->remove_policy('ErrorHandling::RequireCarping');
$bundle->remove_policy('NamingConventions::Capitalization');

my $inf = $bundle->actionlist->get_inflated;

my $config = $inf->apply_config;

{
  my $rcfile = path('./perlcritic.rc')->openw_utf8;
  $rcfile->print( $config->as_ini, "\n" );
  close $rcfile or croak 'Something fubared closing perlcritic.rc';
}
my $deps = $inf->own_deps;
{
  my $target = path('./misc');
  $target->mkpath if not $target->is_dir;

  my $depsfile = $target->child('perlcritic.deps')->openw_utf8;
  for my $key ( sort keys %{$deps} ) {
    $depsfile->printf( "%s~%s\n", $key, $deps->{$key} );
    *STDERR->printf( "%s => %s\n", $key, $deps->{$key} );
  }
  close $depsfile or carp 'Something fubared closing perlcritic.deps';
}

