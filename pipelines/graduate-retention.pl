#!/usr/bin/perl


use utf8;
use warnings;
use strict;
use JSON::XS;
use Data::Dumper;
use Cwd qw(abs_path);
use POSIX qw(strftime);
binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';
my ($basedir, $path);
# Get the real base directory for this script
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }
use lib $basedir."lib";
require "lib.pl";
use OpenInnovations::ProgressBar;


my ($csvfile, $ofile, $total, $totals, $segment, $worksegment, $size, @rows, $fh, $regionlookup, $regions, $section, $tab, $line, @cols, @head, $header, $c, $r, $l, $region, $row, $yy, $progress, $workregion, $other, $years);

$csvfile = $basedir."../working/hesa/figure-16.csv";
$ofile = $basedir."../src/themes/people-skills-future/_data/graduate-retention.csv";

$regionlookup = {
	'East Midlands'=>'E12000004',
	'East of England'=>'E12000006',
	'London'=>'E12000007',
	'North East'=>'E12000001',
	'North West'=>'E12000002',
	'Northern Ireland'=>'N92000002',
	'Scotland'=>'S92000003',
	'South East'=>'E12000008',
	'South West'=>'E12000009',
	'Wales'=>'W92000004',
	'West Midlands'=>'E12000005',
	'Yorkshire and The Humber'=>'E12000003'
};

if(!-e $csvfile){
	msg("Download data from: <green>https://www.hesa.ac.uk/data-and-analysis/sb268/figure-16.csv<none> to <cyan>$ofile<none>\n");
	exit;
}

$progress = OpenInnovations::ProgressBar->new();
$total = -s $csvfile;
$progress->max($total);


msg("Reading data from <cyan>$csvfile<none>\n");
open($fh,$csvfile);
$section = 0;
$tab = 0;
$l = 0;
$size = 0;
while(<$fh>){
	$line = $_;
	$size += length($line);
	$line =~ s/[\n\r]//g;
	if($section > 0){
		@cols = split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/,$line);
		if($section == 1){
			@head = @cols;
			$section = 2;
		}else{
			$tab++;

			if($tab > 3){
				$tab = 1;
			}
			
			if($tab == 3){

				# Construct a row hash
				for($c = 0; $c < @cols; $c++){
					$row->{$head[$c]} = $cols[$c];
				}

				if(($row->{'Region of domicile'} ne "England")
				&& ($row->{'Region of provider'} ne "All" && $row->{'Region of provider'} ne "England" && $row->{'Region of provider'} ne "Total England")
				&& ($row->{'Region of work'} ne "All" && $row->{'Region of work'} ne "England" && $row->{'Region of work'} ne "Total England")
				&& $row->{'Work population marker'} eq "Work is an activity"
				&& $row->{'Work type marker'} eq "All"
				&& $row->{'Provider type'} eq "All"
				&& $row->{'Level of qualification obtained'} eq "All"){

					$region = $row->{'Region of provider'};
					$yy = $row->{'Academic year'};
					
					if(!defined($regions->{$region})){
						$regions->{$region} = {};
					}
					if(!defined($regions->{$region}{$yy})){	
						$regions->{$region}{$yy} = {'work'=>{}};
					}
					if(!defined($regions->{$region}{$yy}{'work'}{$row->{'Region of work'}})){
						$regions->{$region}{$yy}{'work'}{$row->{'Region of work'}} = 0;
					}
					$regions->{$region}{$yy}{'work'}{$row->{'Region of work'}} += $row->{'Number'};
				}
				$progress->update($size);
			}
		}
	}
	if($section==0 && $line =~ /^,,,,,,,,,/){
		$section = 1;
	}
	$l++;
}
close($fh);


# Build summaries for North and Elsewhere
#$totals = {'north'=>{},'elsewhere'=>{}};
#foreach $region (sort(keys(%{$regions}))){
#	if($region eq "North East" || $region eq "North West" || $region eq "Yorkshire and The Humber"){
#		$segment = "north";
#	}else{
#		$segment = "elsewhere";
#	}
#	foreach $yy (sort(keys(%{$regions->{$region}}))){
#		foreach $workregion (keys(%{$regions->{$region}{$yy}{'work'}})){
#			if($workregion eq "North East" || $workregion eq "North West" || $workregion eq "Yorkshire and The Humber"){
#				$worksegment = "north";
#			}else{
#				$worksegment = "elsewhere";
#			}
#
#			if(!defined($totals->{$segment}{$yy})){
#				$totals->{$segment}{$yy} = {'all'=>0,'same'=>0};
#			}
#
#			$totals->{$segment}{$yy}{'all'} += $regions->{$region}{$yy}{'work'}{$workregion};
#			if($worksegment eq $segment){
#				$totals->{$segment}{$yy}{'same'} += $regions->{$region}{$yy}{'work'}{$workregion};
#			}
#		}
#	}
#}

foreach $region (sort(keys(%{$regions}))){
	foreach $yy (sort(keys(%{$regions->{$region}}))){
		if(!defined($years->{$yy})){
			$years->{$yy} = 1;
		}
		$total = 0;
		$size = 0;
		foreach $workregion (keys(%{$regions->{$region}{$yy}{'work'}})){
			#print "\tWork in $workregion: ".($regions->{$region}{$yy}{'work'}{$workregion})."\n";
			$total += $regions->{$region}{$yy}{'work'}{$workregion};
			if($workregion eq $region){
				$size += $regions->{$region}{$yy}{'work'}{$region};
			}
		}
		$regions->{$region}{$yy}{'same'} = sprintf("%0.1f",100*$size/$total);
		#print "\t$size/$total (".sprintf("%0.1f",100*$size/$total).")\n";
	}
}


msg("Saving output to <cyan>$ofile<none>\n");
open($fh,">",$ofile);
print $fh "Region of provider,Region";
foreach $yy (sort(keys(%{$years}))){
	print $fh ",Work in same region (%)";
}
print $fh "\n";
print $fh ",";
foreach $yy (sort(keys(%{$years}))){
	print $fh ",$yy";
}
print $fh "\n";
print $fh "---,---";
foreach $yy (sort(keys(%{$years}))){
	print $fh ",---";
}
print $fh "\n";
foreach $region (sort(keys(%{$regions}))){
	print $fh "$region,$regionlookup->{$region}";
	foreach $yy (sort(keys(%{$years}))){
		print $fh ",$regions->{$region}{$yy}{'same'}";
	}
	print $fh "\n";
}
#print $fh "The North";
#foreach $yy (sort(keys(%{$years}))){
#	print $fh ",".sprintf("%0.1f",100*$totals->{'north'}{$yy}{'same'}/$totals->{'north'}{$yy}{'all'});
#}
#print $fh "\n";
#print $fh "Outside The North";
#foreach $yy (sort(keys(%{$years}))){
#	print $fh ",".sprintf("%0.1f",100*$totals->{'elsewhere'}{$yy}{'same'}/$totals->{'elsewhere'}{$yy}{'all'});
#}
#print $fh "\n";

close($fh);





