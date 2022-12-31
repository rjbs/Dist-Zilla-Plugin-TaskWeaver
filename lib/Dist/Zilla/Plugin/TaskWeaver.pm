package Dist::Zilla::Plugin::TaskWeaver;
# ABSTRACT: a PodWeaver plugin used to build Task distributions

use Moose;
extends qw(Dist::Zilla::Plugin::PodWeaver);
with 'Dist::Zilla::Role::FileGatherer' => { -excludes => [ qw(mvp_aliases mvp_multivalue_args) ] },
     'Dist::Zilla::Role::PrereqSource' => { -excludes => [ qw(mvp_aliases mvp_multivalue_args) ] };

use namespace::autoclean;

=head1 DESCRIPTION

The TaskWeaver plugin acts just like the PodWeaver plugin, but gets its claws
just a bit into your Pod::Weaver configuration and then uses them to figure out
prerequisites and grouping for building a Task distribution.

The C<Task::> namespace is used for libraries that do not have any code of
their own, but are just ways of getting a lot of other libraries installed at
once.  In other words, they're just prerequisites with no actual logic.

TaskWeaver expects that your F<.pm> file will have Pod like the following:

  =pkgroup Modules That are Useful

  =pkg Sub::Exporter 0.901 first version with teeth

  =pkg Sub::Import

  =pkgroup Modules That are Useless

  =pkg Acme::ProgressBar 1.10

The C<=pkgroup> directives start groups of prerequisites.  You must have at
least one C<=pkgroup> (although that may change).  The C<=pkg> directives list
specific directives, and are in the following format:

  =pkg Package::Name  min_version  reason

Both C<min_version> and C<reason> are optional, although you can't give a
reason without giving a version.  If a reason is given, it will be included in
the Pod to explain why the specific version is required.

=head1 WARNING

TaskWeaver works, but relies on doing some pretty evil stuff.  It may
substantially change its method of operation in the future, but its
expectations from your Pod should not change.

=head1 ...AND ANOTHER THINGS

If you use three part versions, like C<1.2.3>, you will want to require a very
modern ExtUtils::MakeMaker, probably v6.68 or later.  You can do that with:

  [Prereqs / EUMM]
  -phase = configure
  -type  = requires
  ExtUtils::MakeMaker = 6.68

=head2 Placeholder Testfile

Due to the way various CPAN clients install modules, it is necessary
to generate a fake testfile so there is at least a test in the distribution.

If you do not want to generate the file, disable the C<placeholder_test>
attribute.

  [TaskWeaver]
  placeholder_test = 0

=cut

use Pod::Weaver::Plugin::TaskWeaver;

# need an attr for "plugin name to put this after" -- ugh! -- or a coderef to
# find the first plugin where the coderef tests true; useful for "generic and
# selector name is synopsis" or something -- rjbs, 2009-11-28

has placeholder_test => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);

around weaver => sub {
  my ($orig, $self) = @_;

  my $weaver = $self->$orig;

  my ($i) =
    grep { $weaver->plugins->[$_]->isa('Pod::Weaver::Section::Leftovers') }
    (0 .. $#{ $weaver->plugins });

  splice @{ $weaver->plugins }, $i, 0, Pod::Weaver::Plugin::TaskWeaver->new({
    weaver      => $weaver,
    plugin_name => 'TaskWeaver',
    zillaplugin => $self,
  });

  return $weaver;
};

has prereq => (
  is  => 'ro',
  isa => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(%{ $self->prereq });
}

sub gather_files {
  my ($self) = @_;

  $self->add_file(
    Dist::Zilla::File::InMemory->new({
      name    => 't/placeholder.t',
      content => <<'END_TEST',
use strict;
use warnings;
use Test::More tests => 1;
ok(1, 'tasks need no tests, but CPAN clients demand them');
END_TEST
    }),
  ) if $self->placeholder_test;
}

1;
