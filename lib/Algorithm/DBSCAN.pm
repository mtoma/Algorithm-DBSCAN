package Algorithm::DBSCAN;

use strict;
use warnings;
use 5.10.1;

use Data::Dumper;

use Algorithm::DBSCAN::Point;
use Algorithm::DBSCAN::Dataset;

=head1 NAME

Algorithm::DBSCAN - The great new Algorithm::DBSCAN!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Algorithm::DBSCAN;

    my $foo = Algorithm::DBSCAN->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

=head2 new

=cut

sub new {
	my($type, $dataset, $eps, $min_points) = @_;
	
	my $self = {};
	$self->{dataset_object} = $dataset;
	$self->{dataset} = $dataset->{points};
	@{$self->{id_list}} = keys %{$dataset->{points}};
	$self->{eps} = $eps;
	$self->{min_points} = $min_points;
	$self->{current_cluster} = 1;
		
	bless($self, $type);

	return($self);
}

=head2 _one_more_point_visited

=cut

sub _one_more_point_visited {
	my ($self) = @_;
	
	$self->{nb_visited_points}++;
	$self->{start_time} = time() unless ($self->{start_time});
	my $eta = time() + ((time() - $self->{start_time})/$self->{nb_visited_points})*(500000);
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($eta);

	say "ETA:".sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	say "nb visited:".$self->{nb_visited_points};
}

=head2 FindClusters

=cut

sub FindClusters {
	my ($self, $starting_point_id) = @_;

	my $i = 0;
	unshift(@{$self->{id_list}}, $starting_point_id) if (defined $starting_point_id);
	foreach my $id (@{$self->{id_list}}) {
		my $point = $self->{dataset}->{$id};
		say "$i";
		$i++;
		next if ($point->{visited});
		$point->{visited} = 1;
		$self->_one_more_point_visited();
		
		my $neighborPts = $self->GetRegion($point);
#say Dumper($neighborPts);
		
		if (scalar(@$neighborPts) < $self->{min_points}) {
			$point->{cluster_id} = -1;
		}
		else {
			$self->{current_cluster}++;
			$self->ExpandCluster($point, $neighborPts);
		}
	}
}

=head2 PrintClusters

=cut

sub PrintClusters {
	my ($self, $point) = @_;

	my %clusters;
	
	foreach my $point (@{$self->{dataset}}) {
		push(@{$clusters{$point->{cluster_id}}}, $point->{point_id});
	}
	
	foreach my $cluster_id (sort keys %clusters) {
		say "CLUSTER: $cluster_id";
		foreach my $point_id (sort @{$clusters{$cluster_id}}) {
			my $min_distance = 1000000000000;
			my $closest_point_id;
			foreach my $distance_point_id (sort @{$clusters{$cluster_id}}) {
				if ($distance_point_id ne $point_id) {
					my $this_point = $self->{dataset_object}->GetPointById($point_id);
					my $distance_point = $self->{dataset_object}->GetPointById($distance_point_id);
					
					my $distance = $this_point->Distance($distance_point);
					
					if ($distance < $min_distance) {
						$min_distance = $distance;
						$closest_point_id = $distance_point_id;
					}
				}
			}
			
			say "\t$point_id : (closest point: $closest_point_id, distance: $min_distance)";
		}
	}
}

=head2 PrintClustersShort

=cut

sub PrintClustersShort {
        my ($self) = @_;

        my %clusters;

        foreach my $id (keys %{$self->{dataset}}) {
		my $point = $self->{dataset}->{$id};
                push(@{$clusters{$point->{cluster_id}}}, $point->{point_id});
        }

        foreach my $cluster_id (sort keys %clusters) {
                say "CLUSTER: $cluster_id, [".scalar(@{$clusters{$cluster_id}})."] points";
		my $nb = 0;
                foreach my $point_id (sort @{$clusters{$cluster_id}}) {
			$nb++;
                        say "\t$point_id";
			last if ($nb >= 100);
                }
        }
}


=head2 validate_answer

=cut

sub ExpandCluster {
	my ($self, $point, $neighborPts) = @_;
	
	if (scalar(@$neighborPts) < $self->{min_points}) {
		$point->{cluster_id} = -1;
	}
	else {
		$self->{current_cluster}++;

		$point->{cluster_id} = $self->{current_clustr};
	
		my $cluster_expanded = 0;
		do {
			$cluster_expanded = 0;
			foreach my $id (@$neighborPts) {
				my $p = $self->{dataset}->{$id};
				unless ($p->{visited}) {
					$p->{visited} = 1;
					$self->_one_more_point_visited();
					
					my $neighborPtsOfClusterMember = $self->GetRegion($p);
					if (scalar(@$neighborPtsOfClusterMember) >= $self->{min_points}) {
						my %h;
						foreach my $id1 (@$neighborPts, @$neighborPtsOfClusterMember) {
							$h{$id1}++;
						}
						@$neighborPts = keys(%h);
#die Dumper(@$neighborPts);
say "Cluster [$self->{current_cluster}] has now [".scalar(@$neighborPts)."] members, added region of point:".Dumper($p);
						$cluster_expanded = 1;
						last;
					}
				}

				$p->{cluster_id} = $self->{current_cluster} unless($p->{cluster_id});
			}
		}
		while($cluster_expanded);
	}
}

=head2 GetRegion

=cut

sub GetRegion {
	my ($self, $point) = @_;

	my $coordinate_id = join(',', @{$point->{coordinates}});
	unless ($self->{point_neighbourhood_cache}->{$coordinate_id}) {
		my @region;
		
		foreach my $region_candidate_point_id (@{$self->{id_list}}) {
			push(@region, $region_candidate_point_id) if ($self->{dataset}->{$region_candidate_point_id}->Distance($point) < $self->{eps});
		}
		$self->{point_neighbourhood_cache}->{$coordinate_id} = \@region;
	}
	
	return $self->{point_neighbourhood_cache}->{$coordinate_id};
}


=head1 AUTHOR

Michal TOMA, C<< <mtoma at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-dbscan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-DBSCAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::DBSCAN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-DBSCAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-DBSCAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-DBSCAN>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-DBSCAN/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michal TOMA.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Algorithm::DBSCAN
