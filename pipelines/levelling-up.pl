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

my ($basedir, $path,@rows,$r,@las,@lads,$l,%la,$lad,$hexjson,$fh,$percap,$stats,@segments,$s,$total,$north,$northtotal);

# Get the real base directory for this script
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }
require $basedir."lib.pl";


$north = {"E06000001"=>1,"E06000002"=>1,"E06000003"=>1,"E06000004"=>1,"E06000010"=>1,"E06000011"=>1,"E06000005"=>1,"E06000006"=>1,"E06000007"=>1,"E06000008"=>1,"E06000009"=>1,"E06000012"=>1,"E06000014"=>1,"E06000013"=>1,"E06000047"=>1,"E06000049"=>1,"E06000050"=>1,"E06000057"=>1,"E06000063"=>1,"E06000064"=>1,"E06000065"=>1,"E07000117"=>1,"E07000122"=>1,"E07000123"=>1,"E08000005"=>1,"E07000118"=>1,"E07000126"=>1,"E07000119"=>1,"E07000120"=>1,"E07000121"=>1,"E08000006"=>1,"E07000124"=>1,"E07000125"=>1,"E07000127"=>1,"E07000128"=>1,"E08000013"=>1,"E08000003"=>1,"E08000004"=>1,"E08000022"=>1,"E08000001"=>1,"E08000002"=>1,"E08000023"=>1,"E08000007"=>1,"E08000008"=>1,"E08000009"=>1,"E08000010"=>1,"E08000011"=>1,"E08000012"=>1,"E08000014"=>1,"E08000015"=>1,"E08000016"=>1,"E08000024"=>1,"E08000017"=>1,"E08000018"=>1,"E08000019"=>1,"E08000021"=>1,"E08000032"=>1,"E08000033"=>1,"E08000034"=>1,"E08000036"=>1,"E08000035"=>1,"E08000037"=>1};


$hexjson = LoadJSON($basedir."../src/_data/hexjson/uk-local-authority-districts-2023.hexjson");

# Get the full list of local authorities and create a structure
@lads = sort(keys(%{$hexjson->{'hexes'}}));
for($r = 0; $r < @lads; $r++){
	$la{$lads[$r]} = {'total'=>{'round1'=>0,'round2'=>0},'bids'=>{'round1'=>0,'round2'=>0},'population'=>0,'name'=>$hexjson->{'hexes'}{$lads[$r]}{'n'}};
}

# Load the population estimates - this is a flat file
@rows = LoadCSV($basedir."../working/levelling-up/population-estimates.csv");
for($r = 0; $r < @rows; $r++){
	$lad = $rows[$r]->{'Area code'};
	if(defined($hexjson->{'hexes'}{$lad})){
		$la{$lad}{'population'} += $rows[$r]->{'Mid-2022 population (Female)'}+$rows[$r]->{'Mid-2022 population (Male)'};
	}
}

# Load the Levelling Up Fund (augmented) data
@rows = LoadCSV($basedir."../working/levelling-up/levelling-up-fund-round-1.csv");
for($r = 0; $r < @rows; $r++){
	@las = split(/;/,$rows[$r]->{'LADs'});
	for($l = 0; $l < @las; $l++){
		$lad = $las[$l];
		$la{$lad}{'total'}{'round1'} += $rows[$r]->{'Bid Value'}/@las;
		$la{$lad}{'bids'}{'round1'}++;
	}
}
@rows = LoadCSV($basedir."../working/levelling-up/levelling-up-fund-round-2.csv");
for($r = 0; $r < @rows; $r++){
	@las = split(/;/,$rows[$r]->{'LADs'});
	for($l = 0; $l < @las; $l++){
		$lad = $las[$l];
		$la{$lad}{'total'}{'round2'} += $rows[$r]->{'Bid Value'}/@las;
		$la{$lad}{'bids'}{'round2'}++;
	}
}

@segments = ('all','round1','round2');
$stats = {'total'=>{'name'=>'','value'=>0},'percapita'=>{'name'=>'','value'=>0},'totalnorth'=>{'name'=>'','value'=>0},'percapitanorth'=>{'name'=>'','value'=>0}};
$total = 0;

open($fh,">:utf8",$basedir."../src/themes/purpose-social-impact/levelling-up/_data/levelling_up.csv");
print $fh "LAD23CD,LA name,Population (mid 2022 est),All,All,All,All,All,Round 1,Round 1,Round 1,Round 1,Round 1,Round 2,Round 2,Round 2,Round 2,Round 2\n";
print $fh ",,,Bids,Total (£),Total,Per capita (£),Per capita,Bids,Total (£),Total,Per capita (£),Per capita,Bids,Total (£),Total,Per capita (£),Per capita\n";
print $fh "---,---,---,---,---,---,---,---,---,---,---,---,---,---,---,---,---,---\n";
foreach $lad (@lads){
	print $fh "$lad,\"$la{$lad}->{'name'}\",$la{$lad}->{'population'}";
	$la{$lad}->{'bids'}{'all'} = $la{$lad}->{'bids'}{'round1'}+$la{$lad}->{'bids'}{'round2'};
	$la{$lad}->{'total'}{'all'} = $la{$lad}->{'total'}{'round1'}+$la{$lad}->{'total'}{'round2'};
	$total += $la{$lad}->{'total'}{'all'};
	if($north->{$lad}){ $northtotal += $la{$lad}->{'total'}{'all'}; }
	for($s = 0; $s < @segments; $s++){
		if($la{$lad}->{'bids'}{$segments[$s]} > 0){
			$percap = ($la{$lad}->{'total'}{$segments[$s]}/$la{$lad}->{'population'});
			print $fh ",".$la{$lad}->{'bids'}{$segments[$s]}.",".sprintf("%0.2d",$la{$lad}->{'total'}{$segments[$s]}).",\"".formatPounds($la{$lad}->{'total'}{$segments[$s]})."\",".sprintf("%0.2f",$percap).",\"".formatPounds($percap)."\"";
			if($segments[$s] eq "all"){
				if($la{$lad}->{'total'}{'all'} > $stats->{'total'}{'value'}){
					$stats->{'total'}{'value'} = $la{$lad}->{'total'}{'all'};
					$stats->{'total'}{'name'} = $la{$lad}->{'name'};
					if($north->{$lad}){
						$stats->{'totalnorth'}{'value'} = $la{$lad}->{'total'}{'all'};
						$stats->{'totalnorth'}{'name'} = $la{$lad}->{'name'};
					}
				}
				if($percap > $stats->{'percapita'}{'value'}){
					$stats->{'percapita'}{'value'} = sprintf("%0d",$percap);
					$stats->{'percapita'}{'name'} = $la{$lad}->{'name'};
					if($north->{$lad}){
						$stats->{'percapitanorth'}{'value'} = sprintf("%0d",$percap);
						$stats->{'percapitanorth'}{'name'} = $la{$lad}->{'name'};
					}
				}
			}
		}else{
			print $fh ",,,none,,none";
		}
	}
	print $fh "\n";
}
close($fh);

$total = sprintf("%0d",$total);

open($fh,">:utf8",$basedir."../src/themes/purpose-social-impact/levelling-up/_data/headlines.csv");
print $fh "name,value,pre,post,footnote\n";
print $fh "Total funding,$total,£,,Rounds 1 and 2\n";
print $fh "Highest total,$stats->{'total'}{'value'},£,,$stats->{'total'}{'name'}\n";
print $fh "Highest per person,$stats->{'percapita'}{'value'},£,,$stats->{'percapita'}{'name'}\n";
print $fh "Funding to the North,".sprintf("%0.1f",100*$northtotal/$total).",,%,\"North includes: North East, North West, Yorkshire and the Humber\"\n";
print $fh "Highest total (North),$stats->{'totalnorth'}{'value'},£,,$stats->{'totalnorth'}{'name'}\n";
print $fh "Highest per person (North),$stats->{'percapitanorth'}{'value'},£,,$stats->{'percapitanorth'}{'name'}\n";
close($fh);

msg("Total funding: <yellow>£$total<none>\n");
msg("North funding: <yellow>£$northtotal<none> (".sprintf("%0.1f",100*$northtotal/$total)."%)\n");
msg("Highest total: <yellow>£$stats->{'total'}{'value'}<none> ($stats->{'total'}{'name'})\n");
msg("Highest per capita: <yellow>£$stats->{'percapita'}{'value'}<none> ($stats->{'percapita'}{'name'})\n");



##############################
# Sub routines
sub formatPounds {
	my $v = shift;
	my ($a,$b,@c,$d,$e);
	$a = int($v);
	$v = $v-int($v);
	$b = reverse $a;               # reverse the number order
	@c = unpack("(A3)*", $b);      # split into groups of three
	$d = join ',', @c;             # join with commas
	$e = reverse $d;               # reverse it again
	if($v <= 0){ $v = ""; }
	else{ $v = sprintf("%.2f",$v); }
	$v =~ s/^0//g;
	$v = "";
	return "£".$e.$v;
}
