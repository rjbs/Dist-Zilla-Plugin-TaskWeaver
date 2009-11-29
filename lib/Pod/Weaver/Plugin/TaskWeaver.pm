package Pod::Weaver::Plugin::TaskWeaver;
use Moose;
with 'Pod::Weaver::Role::Transformer';
with 'Pod::Weaver::Role::Section';

# TRANSFORMER: find all =pkgroup and collect =pkg and flat under them
#              convert =pkgroup to head1, =pkg to head2
#         
# SECTION:     register packages with prereq (no $zilla until now)
#              include all prereqs

sub weave_section {
  my ($self, $document, $input) = @_;


  return;
}

no Moose;
1;
