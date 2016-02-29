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
	
	my @clusters = split(/\n/, read_file($results_file));
	
	foreach my $cluster (@clusters) {
		$cluster =~ s/[<>,]//g;
		my @points = split(/\s+/, $cluster);
		foreach my $cluster_id (keys %clusters) {
			if ($clusters{$cluster_id}->{$points[0]}) {
				my $nb_ok = 0;
				foreach my $p (@points) {
					$nb_ok++ if ($clusters{$cluster_id}->{$p})
				}
				
				die "error: [$nb_ok] != [".scalar(keys %{$clusters{$cluster_id}})."]" unless ($nb_ok == scalar(keys %{$clusters{$cluster_id}}));
			}
		}
	}
	
	say "RESULT OK";
	return 1;
}

my $dataset = Algorithm::DBSCAN::DataSet->new();
my @lines = split(/\n/, read_file('dbscan_test_dataset_1.txt'));
foreach my $line (@lines) {
	$dataset->AddPoint(new Algorithm::DBSCAN::Point(split(/\s+/, $line)));
}

my $dbscan = Algorithm::DBSCAN->new($dataset, 3.1 * 3.1, 6);

$dbscan->FindClusters();
$dbscan->PrintClustersShort();
my $result = validate_answer($dbscan, 'dbscan_test_dataset_1_result.txt');

ok( $result eq '1', 'Clustering of dataset 1 ok' );

done_testing;