package Dist::Zilla::Plugin::TaskWeaver;
use Moose;
extends 'Dist::Zilla::Plugin::PodWeaver';

use Moose::Autobox;

# need an attr for "plugin name to put this after" -- ugh! -- or a coderef to
# find the first plugin where the coderef tests true; useful for "generic and
# selector name is synopsis" or something -- rjbs, 2009-11-28

around weaver => sub {
  my ($orig, $self) = @_;

  my $weaver = $self->$orig;

  my $plugin = Pod::Weaver::Plugin::TaskWeaver->new({
    plugin_name => 'TaskWeaver',
    weaver      => $weaver,
  });

  $weaver->plugins->push($plugin);

  return $weaver;
};

1;
