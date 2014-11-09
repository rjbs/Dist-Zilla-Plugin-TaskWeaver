package Dist::Zilla::Plugin::TaskWeaver;
use Moose;
extends qw(Dist::Zilla::Plugin::PodWeaver);
with 'Dist::Zilla::Role::FileGatherer';
# ABSTRACT: a PodWeaver plugin used to build Task distributions

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

=cut

use Moose::Autobox;
use Pod::Weaver::Plugin::TaskWeaver;

# this is weird because it is *supposed* to work via extending PodWeaver!
sub mvp_aliases { return { config_plugin => 'config_plugins' } }
sub mvp_multivalue_args { qw(config_plugins) }

has config_plugins => (
  isa => 'ArrayRef[Str]',
  traits  => [ 'Array' ],
  default => sub {  []  },
  handles => {
    config_plugins     => 'elements',
    has_config_plugins => 'count',
  },
);

# need an attr for "plugin name to put this after" -- ugh! -- or a coderef to
# find the first plugin where the coderef tests true; useful for "generic and
# selector name is synopsis" or something -- rjbs, 2009-11-28

around weaver => sub {
  my ($orig, $self) = @_;

  my $weaver = $self->$orig;

  my ($i) =
    grep { $weaver->plugins->[$_]->isa('Pod::Weaver::Section::Leftovers') }
    ($weaver->plugins->keys->flatten);

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
      name    => 't/task-bogus.t',
      content => <<'END_TEST',
use strict;
use Test::More tests => 1;
ok(1, 'tasks need no tests, but CPAN clients demand them');
END_TEST
    }),
  );
}

with 'Dist::Zilla::Role::PrereqSource';

1;
