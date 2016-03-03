#!perl -T
use strict;
use warnings;
use 5.10.1;

use Test::More;
use File::Slurp;

BEGIN { chdir 't' if -d 't' }

use_ok( 'Algorithm::DBSCAN' ) || print "Bail out!\n";

sub validate_answer {
	my ($dbscan, $results_file) = @_;
	
	my %clusters;
	
	foreach my $id (keys %{$dbscan->{dataset}}) {
		my $point = $dbscan->{dataset}->{$id};
		$clusters{$point->{cluster_id}}{$point->{point_id}}++;
	}
#die Dumper(\%clusters);
	
	my @result_clusters = split(/\n/, read_file($results_file));
	
	foreach my $result_cluster (@result_clusters) {
		$result_cluster =~ s/[<>,]//g;
		my @points = split(/\s+/, $result_cluster);
		shift(@points);
		my $cluster_found = 0;
		foreach my $cluster_id (keys %clusters) {
			if ($clusters{$cluster_id}->{$points[0]}) {
				$cluster_found++;
				my $nb_ok = 0;
				foreach my $p (@points) {
					$nb_ok++ if ($clusters{$cluster_id}->{$p})
				}
				
				die "error: [$nb_ok] != [".scalar(keys %{$clusters{$cluster_id}})."]" unless ($nb_ok == scalar(keys %{$clusters{$cluster_id}}));
			}
		}
		die "error: point [$points[0]] not found in any cluster" unless($cluster_found);
	}
	
	say "RESULT OK";
	return 1;
}

my $dataset = Algorithm::DBSCAN::DataSet->new();
my @lines = split(/\n/, read_file('test_datasets/dbscan_test_dataset_2.txt'));
foreach my $line (@lines) {
	$dataset->AddPoint(new Algorithm::DBSCAN::Point(split(/\s+/, $line)));
}

my $dbscan = Algorithm::DBSCAN->new($dataset, 4 * 4, 2);

$dbscan->UseRegionIndex('test_datasets/region_index_dataset_2.txt');
$dbscan->FindClusters();
$dbscan->PrintClustersShort();
my $result = validate_answer($dbscan, 'test_datasets/dbscan_test_dataset_2_result.txt');

ok( $result eq '1', 'Clustering of dataset 2 with usage of region index OK' );

done_testing;