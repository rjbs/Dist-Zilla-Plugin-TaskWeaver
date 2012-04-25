package Pod::Weaver::Plugin::TaskWeaver;
use Moose;
with 'Pod::Weaver::Role::Dialect';
with 'Pod::Weaver::Role::Section';
# ABSTRACT: Dist::Zilla::Plugin::TaskWeaver's helper

=head1 DESCRIPTION

B<Achtung!>  This class should not need to exist; it should be possible for
Dist::Zilla::Plugin::TaskWeaver to also be a Pod::Weaver plugin, but a subtle
bug in Moose prevents this from happening right now.  In the future, this class
may go away.

This is a Pod::Weaver plugin.  It functions as both a Dialect and a Section,
although this is basically hackery to get things into the right order.  For
more information consult the L<Dist::Zilla::Plugin::TaskWeaver> documentation.

=cut

use Moose::Autobox;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;

has zillaplugin => (is => 'ro', isa => 'Object', required => 1);

sub record_prereq {
  my ($self, $pkg, $ver) = @_;
  $self->zillaplugin->prereq->{$pkg} = defined $ver ? $ver : 0;
}

sub translate_dialect {
  my ($self, $document) = @_;

  my $pkg_nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(pkg) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(over item back) ]),
    ],
  });

  $pkg_nester->transform_node($document);

  my $pkgroup_nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(pkgroup pkggroup) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(pkg) ]),
    ],
  });

  $pkgroup_nester->transform_node($document);

  return;
}

sub weave_section {
  my ($self, $document, $input) = @_;

  my $input_pod = $input->{pod_document};

  my @pkgroups;
  for my $i (reverse $input_pod->children->keys->flatten) {
    my $child = $input_pod->children->[ $i ];
    unshift @pkgroups, splice(@{$input_pod->children}, $i, 1)
      if  $child->does('Pod::Elemental::Command')
      and ($child->command eq 'pkgroup' or $child->command eq 'pkggroup');
  }

  for my $pkgroup (@pkgroups) {
    $pkgroup->command('head2');

    for my $child (@{ $pkgroup->children }) {
      next unless $child->does('Pod::Elemental::Command')
           and    $child->command eq 'pkg';

      $child->command('head3');

      my ($pkg, $ver, $reason) = split /\s+/sm, $child->content, 3;
      $self->record_prereq($pkg, $ver);

      $child->content(defined $ver ? "L<$pkg> $ver" : "L<$pkg>");

      if (defined $ver and defined $reason) {
        $child->children->unshift(
          Pod::Elemental::Element::Pod5::Ordinary->new({
            content => "Version $ver required because: $reason",
          })
        );
      }
    }
  }

  my $section = Pod::Elemental::Element::Nested->new({
    command  => 'head1',
    content  => 'TASK CONTENTS',
    children => \@pkgroups,
  });

  $input_pod->children->unshift($section);

  return;
}

1;
