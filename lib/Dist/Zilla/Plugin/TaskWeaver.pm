package Dist::Zilla::Plugin::TaskWeaver;
use Moose;
extends 'Dist::Zilla::Plugin::PodWeaver';

use Moose::Autobox;
use Pod::Weaver::Plugin::TaskWeaver;

# need an attr for "plugin name to put this after" -- ugh! -- or a coderef to
# find the first plugin where the coderef tests true; useful for "generic and
# selector name is synopsis" or something -- rjbs, 2009-11-28

around weaver => sub {
  my ($orig, $self) = @_;

  my $weaver = $self->$orig;

  my $plugin = Pod::Weaver::Plugin::TaskWeaver->new({
    plugin_name => 'TaskWeaver',
    weaver      => $weaver,
    zillaplugin => $self,
  });

  my ($i) =
    grep { $weaver->plugins->[$_]->isa('Pod::Weaver::Section::Leftovers') }
    ($weaver->plugins->keys->flatten);

  splice @{ $weaver->plugins }, $i, 0, $plugin;

  return $weaver;
};

has prereq => (
  is  => 'ro',
  isa => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);

with 'Dist::Zilla::Role::FixedPrereqs';

1;
