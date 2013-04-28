
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4004"
  },
  "configure_requires" => {
    "Module::Build" => "0.4004"
  },
  "dist_abstract" => "Tools for working with Gentoo Overlays",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Gentoo-Overlay",
  "dist_version" => "1.0.4",
  "license" => "perl",
  "module_name" => "Gentoo::Overlay",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dump" => 0,
    "Moose" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::OneArgNew" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Tiny" => 0,
    "Readonly" => 0,
    "Role::HasMessage::Errf" => 0,
    "Role::Identifiable::HasIdent" => 0,
    "Role::Identifiable::HasTags" => 0,
    "StackTrace::Auto" => 0,
    "Sub::Exporter" => 0,
    "Throwable" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.98",
    "Test::Output" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
