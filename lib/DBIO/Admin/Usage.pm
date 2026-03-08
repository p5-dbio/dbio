package DBIO::Admin::Usage;
# ABSTRACT: POD-aware usage renderer for DBIO admin commands

use warnings;
use strict;

use base 'Getopt::Long::Descriptive::Usage';

use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors('simple', 'synopsis', 'short_description');

=head1 METHODS

=method prog_name

Return the invoked program name.

=cut

sub prog_name {
    Getopt::Long::Descriptive::prog_name();
}

=method set_simple

Store usage text with C<%c> placeholder expanded to program name.

=cut

sub set_simple {
    my ($self,$field, $value) = @_;
    my $prog_name = prog_name();
    $value =~ s/%c/$prog_name/g;
    $self->next::method($field, $value);
}



# This returns the usage formatted as a pod document
=method pod

Return full usage output formatted as POD text.

=cut

sub pod {
  my ($self) = @_;
  return join qq{\n}, $self->pod_leader_text, $self->pod_option_text, $self->pod_authorlic_text;
}

=method pod_leader_text

Render NAME/SYNOPSIS sections for generated POD.

=cut

sub pod_leader_text {
  my ($self) = @_;

  return qq{=head1 NAME\n\n}.prog_name()." - ".$self->short_description().qq{\n\n}.
         qq{=head1 SYNOPSIS\n\n}.$self->leader_text().qq{\n}.$self->synopsis().qq{\n\n};

}

=method pod_authorlic_text

Render AUTHORS/LICENSE sections for generated POD.

=cut

sub pod_authorlic_text {

  return join ("\n\n",
    '=head1 AUTHORS',
    'See L<DBIO/AUTHORS>',
    '=head1 LICENSE',
    'You may distribute this code under the same terms as Perl itself',
    '=cut',
  );
}


=method pod_option_text

Render OPTIONS section for generated POD from Getopt descriptors.

=cut

sub pod_option_text {
  my ($self) = @_;
  my @options = @{ $self->{options} || [] };
  my $string = q{};
  return $string unless @options;

  $string .= "=head1 OPTIONS\n\n=over\n\n";

  foreach my $opt (@options) {
    my $spec = $opt->{spec};
    my $desc = $opt->{desc};
    next if ($desc eq 'hidden');
    if ($desc eq 'spacer') {
        $string .= "=back\n\n=head2 $spec\n\n=cut\n\n=over\n\n";
        next;
    }

    $spec = Getopt::Long::Descriptive->_strip_assignment($spec);
    $string .= "=item " . join " or ", map { length > 1 ? "B<--$_>" : "B<-$_>" }
                             split /\|/, $spec;
    $string .= "\n\n$desc\n\n=cut\n\n";

  }
  $string .= "=back\n\n";
  return $string;
}

1;
