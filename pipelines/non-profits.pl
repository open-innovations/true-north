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

my ($basedir,$path,$datafile,$hexfile,$dashfile,@rows,$i,$n,$r,@las,@lads,$l,%la,$lad,$hexjson,$fh,$percap,$stats,@segments,$s,$total,$north,$northtotal,$fraction,$northfraction,$industry,$size,$status,@industries,$tooltip);

# Get the real base directory for this script
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }
require $basedir."lib.pl";

# Define the LADs that make up the north in 2021
$north = {"E06000001"=>1,"E06000002"=>1,"E06000003"=>1,"E06000004"=>1,"E06000010"=>1,"E06000011"=>1,"E06000005"=>1,"E06000006"=>1,"E06000007"=>1,"E06000008"=>1,"E06000009"=>1,"E06000012"=>1,"E06000014"=>1,"E06000013"=>1,"E06000047"=>1,"E06000049"=>1,"E06000050"=>1,"E06000057"=>1,"E06000064"=>1,"E07000117"=>1,"E07000122"=>1,"E07000123"=>1,"E08000005"=>1,"E07000118"=>1,"E07000126"=>1,"E07000119"=>1,"E07000120"=>1,"E07000121"=>1,"E08000006"=>1,"E07000124"=>1,"E07000125"=>1,"E07000127"=>1,"E07000128"=>1,"E08000013"=>1,"E08000003"=>1,"E08000004"=>1,"E08000022"=>1,"E08000001"=>1,"E08000002"=>1,"E08000023"=>1,"E08000007"=>1,"E08000008"=>1,"E08000009"=>1,"E08000010"=>1,"E08000011"=>1,"E08000012"=>1,"E08000014"=>1,"E08000015"=>1,"E08000016"=>1,"E08000024"=>1,"E08000017"=>1,"E08000018"=>1,"E08000019"=>1,"E08000021"=>1,"E08000032"=>1,"E08000033"=>1,"E08000034"=>1,"E08000036"=>1,"E08000035"=>1,"E08000037"=>1,
"E07000026"=>1,"E07000028"=>1,"E07000029"=>1,
"E07000027"=>1,"E07000030"=>1,"E07000031"=>1,
"E07000163"=>1,"E07000164"=>1,"E07000165"=>1,"E07000166"=>1,"E07000167"=>1,"E07000168"=>1,"E07000169"=>1,
"E07000187"=>1,"E07000188"=>1,"E07000246"=>1,"E07000189"=>1};

$datafile = $basedir."../src/themes/purpose-social-impact/non-profit/_data/ukbc_lu.csv";
$dashfile = $basedir."../src/themes/purpose-social-impact/non-profit/_data/headlines.csv";
$hexfile = $basedir."../src/_data/hexjson/uk-local-authority-districts-2021.hexjson";

# Get the HexJSON file
$hexjson = LoadJSON($hexfile);

# Get the full list of local authorities and create a structure
@lads = sort(keys(%{$hexjson->{'hexes'}}));
for($r = 0; $r < @lads; $r++){
	$la{$lads[$r]} = {'totals'=>{},'industry'=>{},'name'=>$hexjson->{'hexes'}{$lads[$r]}{'n'}};
}

# Load the UK business numbers - this is a flat file
@rows = LoadCSV($basedir."../working/cs/ukbc_lu.csv");
for($r = 0; $r < @rows; $r++){
	$lad = $rows[$r]->{'geography.code'};
	if(!defined($la{$lad})){
		error("No LAD for <green>$lad<none> in HexJSON.\n");
		exit;
	}
	if($rows[$r]->{'geography.type'} eq "LAD21"){
		$industry = $rows[$r]->{'industry.name'};
		$size = $rows[$r]->{'employment_sizeband.name'};
		$status = $rows[$r]->{'legal_status.name'};
		if(!defined($la{$lad}{'industry'}{$industry})){
			# Create structure for sizes
			$la{$lad}{'industry'}{$industry} = {};
		}
		if(!defined($la{$lad}{'industry'}{$industry}{$size})){
			$la{$lad}{'industry'}{$industry}{$size} = {};
		}
		if(!defined($la{$lad}{'industry'}{$industry}{$size}{$status})){
			$la{$lad}{'industry'}{$industry}{$size}{$status} = 0;
		}
		$la{$lad}{'industry'}{$industry}{$size}{$status} += $rows[$r]->{'value'};
	}
}


msg("Saving data to <cyan>$datafile<none>\n");
open($fh,">:utf8",$datafile);
print $fh "LAD21CD,LAD21NM,All,Non-profit,Non-profit (%),Summary\n";
$total = {'all'=>0,'non-profit'=>0};
$northtotal = {'all'=>0,'non-profit'=>0};
foreach $lad (sort(keys(%la))){

	# Get a sorted list of industries by the total non-profit bodies
	@industries = reverse(sort{ $la{$lad}{'industry'}{$a}{'Total'}{'Non-profit body or mutual association'} <=> $la{$lad}{'industry'}{$b}{'Total'}{'Non-profit body or mutual association'} || $b cmp $a }(keys(%{$la{$lad}{'industry'}})));
	for($i = 0; $i < @industries; $i++){
		if(!defined($la{$lad}{'totals'}{'all'})){
			$la{$lad}{'totals'}{'all'} = 0;
		}
		if(!defined($la{$lad}{'totals'}{'non-profit'})){
			$la{$lad}{'totals'}{'non-profit'} = 0;
		}
		$la{$lad}{'totals'}{'all'} += $la{$lad}{'industry'}{$industries[$i]}{'Total'}{'Total'};
		$la{$lad}{'totals'}{'non-profit'} += $la{$lad}{'industry'}{$industries[$i]}{'Total'}{'Non-profit body or mutual association'};
	}


	# Work out fraction of all businesses
	if(defined($la{$lad}{'totals'}{'all'}) && $la{$lad}{'totals'}{'all'} > 0){
		$fraction = sprintf("%0.1f",100*$la{$lad}{'totals'}{'non-profit'}/$la{$lad}{'totals'}{'all'});

		$total->{'all'} += $la{$lad}{'totals'}{'all'};
		$total->{'non-profit'} += $la{$lad}{'totals'}{'non-profit'};
		if($north->{$lad}){
			$northtotal->{'all'} += $la{$lad}{'totals'}{'all'};
			$northtotal->{'non-profit'} += $la{$lad}{'totals'}{'non-profit'};
		}

	}else{
		$fraction = "";
	}

	# Construct the tooltip
	$tooltip = "";
	$n = @industries;
	if($n > 3){ $n = 3; }
	if($n > 0){
		$tooltip .= "<br />Non-profits: <strong class='number'>$la{$lad}{'totals'}{'non-profit'}</strong> ($fraction\%)";
		$tooltip .= "<br />Top non-profit industries:<ol>";
		for($i = 0; $i < $n; $i++){
			$tooltip .= "<li>$industries[$i]: <strong class='number'>$la{$lad}{'industry'}{$industries[$i]}{'Total'}{'Non-profit body or mutual association'}</strong></li>";
		}
		$tooltip .= "</ol>";
	}

	# Start making the CSV line
	print $fh "$lad,\"$la{$lad}{'name'}\"";
	print $fh ",".($la{$lad}{'totals'}{'all'}||"");
	print $fh ",".($la{$lad}{'totals'}{'non-profit'}||"");
	print $fh ",".$fraction;
	if($tooltip){
		print $fh ",\"".($tooltip)."\"";
	}else{
		print $fh ",";
	}
	print $fh "\n";

}
close($fh);


# Calculate percentages
if($total->{'all'} > 0){
	$fraction = sprintf("%0.1f",100*$total->{'non-profit'}/$total->{'all'});
}else{
	$fraction = "";
}
if($northtotal->{'all'} > 0){
	$northfraction = sprintf("%0.1f",100*$northtotal->{'non-profit'}/$northtotal->{'all'});
}else{
	$northfraction = "";
}


msg("Saving headlines to <cyan>$dashfile<none>\n");
open($fh,">:utf8",$dashfile);
print $fh "name,value,footnote,post,pre\n";
print $fh "Total companies,$total->{'all'},In the UK,,\n";
print $fh "Non-profit companies,$total->{'non-profit'},In the UK,,\n";
print $fh "Non-profits,$fraction,In the UK,%,\n";
print $fh "Total companies,$northtotal->{'all'},In The North,,\n";
print $fh "Non-profit companies,$northtotal->{'non-profit'},In The North,,\n";
print $fh "Non-profits,$northfraction,In The North,%,\n";
close($fh);

##############################
# Sub routines