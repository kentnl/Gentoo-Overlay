
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Module::Build' => '0.3601',
    'Test::Fatal' => '0',
    'Test::More' => '0.96',
    'Test::Output' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Tools for working with Gentoo Overlays',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'Gentoo-Overlay',
  'dist_version' => '0.03000000',
  'license' => 'perl',
  'module_name' => 'Gentoo::Overlay',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Data::Dump' => '0',
    'Moose' => '0',
    'MooseX::ClassAttribute' => '0',
    'MooseX::Has::Sugar' => '0',
    'MooseX::OneArgNew' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::Path::Class' => '0',
    'Readonly' => '0',
    'Role::HasMessage::Errf' => '0',
    'Role::Identifiable::HasIdent' => '0',
    'Role::Identifiable::HasTags' => '0',
    'StackTrace::Auto' => '0',
    'Sub::Exporter' => '0',
    'Throwable' => '0',
    'namespace::autoclean' => '0',
    'overload' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
