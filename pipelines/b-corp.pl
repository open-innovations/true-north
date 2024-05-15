#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use JSON::XS;
use Data::Dumper;
use Cwd qw(abs_path);
binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

# Get the real base directory for this script
my ($basedir, $path);
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }


# Set some paths
my $dir = $basedir."../working/b-corp/";
my $ofile = $basedir."../src/themes/true-north/_data/bcorp_list.csv";
my $lfile = $basedir."../src/themes/true-north/_data/bcorp_by_la.csv";
my $pcdfile = $basedir."../working/b-corp/NSPL21_FEB_2024_UK_cut.csv";


# Get any .env environment variables
my $env = getEnvironment();


# Loop over the the API results to load all the data
my $n = 0;
my $nbhits = 1;
my $page = 0;
my $nperpage = 500;
my ($json,$file,@hits,$i,$key,$csv,$fh,$pcds,$la,$ladata,$pcd,@sizes,$s,$industries,$industry,$own,$owned);
while($n < $nbhits){
	$file = $dir."page-$page.json";
	if(!-e $file || -s $file == 0){
		msg("Getting page <green>$page<none>\n");
		`curl 'https://bx1p6tr71m-dsn.algolia.net/1/indexes/*/queries?x-algolia-agent=Algolia%20for%20JavaScript%20(4.22.0)%3B%20Browser%20(lite)%3B%20instantsearch.js%20(4.66.0)%3B%20react%20(18.2.0)%3B%20react-instantsearch%20(7.7.0)%3B%20react-instantsearch-core%20(7.7.0)%3B%20JS%20Helper%20(3.16.3)&x-algolia-api-key=$env->{'B_CORP_API'}&x-algolia-application-id=$env->{'B_CORP_APP'}' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:125.0) Gecko/20100101 Firefox/125.0' -H 'Accept: */*' -H 'Accept-Language: en-GB,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'content-type: application/x-www-form-urlencoded' -H 'Origin: https://www.bcorporation.net' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://www.bcorporation.net/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: cross-site' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw '{"requests":[{"indexName":"companies-production-en-us-latest-certification-desc","params":"facetFilters=%5B%5B%22hqCountry%3AUnited%20Kingdom%22%5D%5D&facets=%5B%22countries%22%2C%22demographicsList%22%2C%22hqCountry%22%2C%22industry%22%2C%22size%22%5D&highlightPostTag=__%2Fais-highlight__&highlightPreTag=__ais-highlight__&hitsPerPage=$nperpage&maxValuesPerFacet=500&page=$page&query=&tagFilters="},{"indexName":"companies-production-en-us-latest-certification-desc","params":"analytics=false&clickAnalytics=false&facets=hqCountry&highlightPostTag=__%2Fais-highlight__&highlightPreTag=__ais-highlight__&hitsPerPage=0&maxValuesPerFacet=500&page=0&query="}]}' -o $file`;
	}
	$json = LoadJSON($file);
	$nbhits = $json->{'results'}[0]{'nbHits'};
	$n += @{$json->{'results'}[0]{'hits'}};
	push(@hits,@{$json->{'results'}[0]{'hits'}});
	$page++;
}


# If we don't have postcodes we quit
if(!-e $pcdfile){
	error("No NSPL postcode file exists at <cyan>$pcdfile<none>\n");
	exit;
}

# Load the postcode data
$pcds = GetPostcodeLookup($pcdfile);

$ladata = {};
@sizes = ("0","1-9","10-49","50-249","250-999","1000+");
$industries = {};
$owned = {};

# Build the CSV
$csv = "Name,Industry,Size,Postcode,LADCD\n";
for($i = 0; $i < @hits; $i++){
	foreach $key (keys(%{$hits[$i]})){
		$hits[$i]{$key} =~ s/(^\"|\"$)//g;
		#print "$i - $key\n";
	}
	$hits[$i]{'name'} =~ s/\"//g;
	$pcd = fixPostcode($hits[$i]{'hqPostalCode'});
	$la = $pcds->{$pcd}||"";

	if(!$la){
		warning("The postcode for $hits[$i]{'name'} ($i) seems invalid: <green>$pcd<none>\n");
	}else{
		if(!$ladata->{$la}){ $ladata->{$la} = {'count'=>0,'employeeOwned'=>0,'industries'=>{},'sizes'=>{},'owned'=>{}}; }
		$ladata->{$la}{'count'}++;
		if($hits[$i]{'demographics'}{'employeeOwned'}){ $ladata->{$la}{'employeeOwned'}++ }

		if(!$ladata->{$la}{'industries'}{$hits[$i]{'industry'}}){ $ladata->{$la}{'industries'}{$hits[$i]{'industry'}} = 0; }
		$ladata->{$la}{'industries'}{$hits[$i]{'industry'}}++;
		if($hits[$i]{'industry'}){ $industries->{$hits[$i]{'industry'}} = 1; }

		foreach $own (keys(%{$hits[$i]{'demographics'}})){
			if($own){
				if(!$ladata->{$la}{'owned'}{$own}){ $ladata->{$la}{'owned'}{$own} = 0; }
				if($hits[$i]{'demographics'}{$own}){ $ladata->{$la}{'owned'}{$own}++; }
				$owned->{$own} = 1;
			}
		}

		if(!$ladata->{$la}{'sizes'}{$hits[$i]{'size'}}){ $ladata->{$la}{'sizes'}{$hits[$i]{'size'}} = 0; }
		$ladata->{$la}{'sizes'}{$hits[$i]{'size'}}++;

	}
	$csv .= "\"$hits[$i]{'name'}\",\"$hits[$i]{'industry'}\",$hits[$i]{'size'},$hits[$i]{'hqPostalCode'},$la\n";
}



# Save the CSV
msg("Saving to <cyan>$ofile<none>\n");
open($fh,">:utf8",$ofile);
print $fh $csv;
close($fh);


# Create breakdowns by local authority
print Dumper $ladata;

msg("Saving LA breakdown to <cyan>$lfile<none>\n");
open($fh,">:utf8",$lfile);
# Make headers
print $fh "LADCD,Total";
$n = 2;
for($s = 0; $s < @sizes; $s++){
	print $fh ",Size";
	$n++;
}
foreach $own (sort(keys(%{$owned}))){
	print $fh ",Owned";
	$n++;
}
foreach $industry (sort(keys(%{$industries}))){
	print $fh ",Industry";
	$n++;
}
print $fh "\n";
# Make header second row
print $fh ",";
for($s = 0; $s < @sizes; $s++){
	print $fh ",$sizes[$s]";
}
foreach $own (sort(keys(%{$owned}))){
	print $fh ",\"$own\"";
}
foreach $industry (sort(keys(%{$industries}))){
	print $fh ",\"$industry\"";
}
print $fh "\n";
# Final header row
for($i = 0; $i < $n; $i++){ print $fh ($i == 0 ? "":",")."---"; }
print $fh "\n";

# Make rows
foreach $la (sort(keys(%{$ladata}))){
	print $fh "$la,$ladata->{$la}{'count'},$ladata->{$la}{'employeeOwned'}";

	for($s = 0; $s < @sizes; $s++){
		print $fh ",".($ladata->{$la}{'sizes'}{$sizes[$s]}||"0");
	}
	foreach $own (sort(keys(%{$owned}))){
		print $fh ",".($ladata->{$la}{'owned'}{$own}||"0");
	}
	foreach $industry (sort(keys(%{$industries}))){
		print $fh ",".($ladata->{$la}{'industries'}{$industry}||"0");
	}
	print $fh "\n";
}
close($fh);

##############################
# Sub routines
sub msg {
	my $str = $_[0];
	my $dest = $_[1]||"STDOUT";
	
	my %colours = (
		'black'=>"\033[0;30m",
		'red'=>"\033[0;31m",
		'green'=>"\033[0;32m",
		'yellow'=>"\033[0;33m",
		'blue'=>"\033[0;34m",
		'magenta'=>"\033[0;35m",
		'cyan'=>"\033[0;36m",
		'white'=>"\033[0;37m",
		'none'=>"\033[0m"
	);
	foreach my $c (keys(%colours)){ $str =~ s/\< ?$c ?\>/$colours{$c}/g; }
	if($dest eq "STDERR"){
		print STDERR $str;
	}else{
		print STDOUT $str;
	}
}

sub error {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<red>ERROR:<none> /;
	msg($str,"STDERR");
}

sub warning {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<yellow>WARNING:<none> /;
	msg($str,"STDERR");
}

sub ParseJSON {
	my $str = shift;
	my ($json);
	eval {
		$json = JSON::XS->new->decode($str);
	};
	if($@){ error("\tInvalid output in input: \"".substr($str,0,100)."...\".\n"); $json = {}; }
	return $json;
}

sub LoadJSON {
	my (@files,$str,@lines,$json);
	my $file = $_[0];
	open(FILE,"<:utf8",$file);
	@lines = <FILE>;
	close(FILE);
	$str = (join("",@lines));
	return ParseJSON($str);
}

sub getEnvironment {
	my ($fh,@lines,$env,$k,$v,$line);
	open($fh,$basedir."../.env");
	@lines = <$fh>;
	close($fh);
	foreach $line (@lines){
		chomp($line);
		($k,$v) = split(/=/,$line);
		$env->{$k} = $v;
	}
	return $env;
}

sub GetPostcodeLookup {
	my $file = shift;
	my ($fh,@lines,$line,$pcd,$la,$rgn,$pcds);

	msg("Reading postcodes from <cyan>$file<none>...\n");
	open($fh,$file);
	@lines = <$fh>;
	close($fh);
	
	$pcds = {};
	foreach $line (@lines){
		chomp($line);
		($pcd,$la,$rgn) = split(/,/,$line);
		$pcd =~ s/ //g;
		$pcds->{$pcd} = $la;
	}
	msg("done\n");
	return $pcds;
}

# Fixes for poorly formatted postcodes
sub fixPostcode {
	my $pcd = shift;
	$pcd = uc($pcd);
	$pcd =~ s/[^A-Z0-9]//g;
	$pcd =~ s/LONDON//g;
	if($pcd eq "LS25DZ"){ $pcd = "LS254DZ"; }
	if($pcd eq "GL52GQ"){ $pcd = "GL52QG"; }
	if($pcd eq "SN21NR"){ $pcd = "SN12NR"; }
	if($pcd eq "CH645FE"){ $pcd = "CH654FE"; }
	if($pcd eq "EC1V7DO"){ $pcd = "EC1V7DP"; }
	return $pcd;
}
