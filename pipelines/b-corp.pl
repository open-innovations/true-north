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

# Get the real base directory for this script
my ($basedir, $path);
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }
require $basedir."lib.pl";


# Set some paths
my $dir = $basedir."../working/b-corp/";
my $ofile = $basedir."../src/themes/sustainable-growth/b-corporations/_data/bcorp_list.csv";
my $lfile = $basedir."../src/themes/sustainable-growth/b-corporations/_data/bcorp_by_la.csv";
my $sfile = $basedir."../src/themes/sustainable-growth/b-corporations/_data/bcorp_north.csv";
my $vfile = $basedir."../src/themes/sustainable-growth/b-corporations/index.vto";
my $yfile = $basedir."../src/themes/sustainable-growth/b-corporations/_data/updated.yaml";
my $pcdfile = $dir."postcodes.csv";
my $hexfile = $basedir."../src/_data/hexjson/uk-local-authority-districts-2023.hexjson";

# Get any .env environment variables
my $env = getEnvironment();

my $hexes = LoadJSON($hexfile)->{'hexes'};



# Loop over the the API results to load all the data
my $total = 0;
my $n = 0;
my $nbhits = 1;
my $page = 1;
my $nperpage = 250;
my ($json,$file,@hits,$i,$key,$csv,$fh,$pcds,$la,$ladata,$pcd,@sizes,$s,$industries,$industry,$sectors,$sector,$own,$owned,$bcorp,$d);
while($n < $nbhits){
	$file = $dir."page-$page.json";
	if(!-e $file || -s $file == 0){
		msg("Getting page <green>$page<none>\n");
		`curl 'https://94eo8lmsqa0nd3j5p.a1.typesense.net/multi_search?x-typesense-api-key=$env->{'B_CORP_API'}' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:129.0) Gecko/20100101 Firefox/129.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-GB,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Content-Type: text/plain' -H 'Origin: https://www.bcorporation.net' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://www.bcorporation.net/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: cross-site' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'TE: trailers' --data-raw '{"searches":[{"query_by":"name,description,websiteKeywords,countries,industry,sector,hqCountry,hqProvince,hqCity,hqPostalCode,provinces,cities,size,demographicsList","exhaustive_search":true,"sort_by":"initialCertificationDateTimestamp:asc","highlight_full_fields":"name,description,websiteKeywords,countries,industry,sector,hqCountry,hqProvince,hqCity,hqPostalCode,provinces,cities,size,demographicsList","collection":"companies-production-en-us","q":"*","facet_by":"countries,demographicsList,hqCountry,industry,size","filter_by":"hqCountry:=[\`United Kingdom\`]","max_facet_values":500,"page":$page,"per_page":$nperpage}]}' -o $file`;
	}
	$json = LoadJSON($file);
	$nbhits = $json->{'results'}[0]{'found'};
	$n += @{$json->{'results'}[0]{'hits'}};
	push(@hits,@{$json->{'results'}[0]{'hits'}});
	$page++;
}

# If we don't have postcodes we quit
if(!-e $pcdfile){
	error("No postcode file exists at <cyan>$pcdfile<none>\n");
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
	$bcorp = $hits[$i]{'document'};
	foreach $key (keys(%{$bcorp})){
		$bcorp->{$key} =~ s/(^\"|\"$)//g;
	}
	$bcorp->{'name'} =~ s/\"//g;
	$pcd = fixPostcode($bcorp->{'hqPostalCode'},$bcorp->{'name'});
	$la = "";
	$la = $pcds->{$pcd}||"";

	if(!defined($pcds->{$pcd})){
		# Try to get data on this postcode
		$la = FindThatLocalAuthority($pcd);
		$pcds->{$pcd} = $la;
	}

	if(!$la){
		warning("The postcode for $bcorp->{'name'} ($i) seems invalid: <green>$pcd<none>\n");
	}else{
		if(!$ladata->{$la}){ $ladata->{$la} = {'count'=>0,'industries'=>{},'sizes'=>{},'owned'=>{}}; }
		$ladata->{$la}{'count'}++;

		if(!$ladata->{$la}{'industries'}{$bcorp->{'industry'}}){ $ladata->{$la}{'industries'}{$bcorp->{'industry'}} = 0; }
		$ladata->{$la}{'industries'}{$bcorp->{'industry'}}++;
		if($bcorp->{'industry'}){
			if(!defined($industries->{$bcorp->{'industry'}})){ $industries->{$bcorp->{'industry'}} = 0; }
			$industries->{$bcorp->{'industry'}}++;
		}

		if(!$ladata->{$la}{'sectors'}{$bcorp->{'sector'}}){ $ladata->{$la}{'sectors'}{$bcorp->{'sector'}} = 0; }
		$ladata->{$la}{'sectors'}{$bcorp->{'sector'}}++;
		if($bcorp->{'sector'}){
			if(!defined($sectors->{$bcorp->{'sector'}})){ $sectors->{$bcorp->{'sector'}} = 0; }
			$sectors->{$bcorp->{'sector'}}++;
		}

		for($d = 0; $d < @{$bcorp->{'demographicsList'}}; $d++){
			$own = $bcorp->{'demographicsList'}[$d];
			$own =~ s/Owned$//g;
			if($own){
				if(!defined($ladata->{$la}{'owned'}{$own})){ $ladata->{$la}{'owned'}{$own} = 0; }
				$ladata->{$la}{'owned'}{$own}++;
				$owned->{$own} = 1;
			}
		}

		if(!$ladata->{$la}{'sizes'}{$bcorp->{'size'}}){ $ladata->{$la}{'sizes'}{$bcorp->{'size'}} = 0; }
		$ladata->{$la}{'sizes'}{$bcorp->{'size'}}++;

	}
	$csv .= "\"$bcorp->{'name'}\",\"$bcorp->{'industry'}\",$bcorp->{'size'},$bcorp->{'hqPostalCode'},$la\n";
}

SavePostcodeLookup($pcdfile,$pcds);

# Save the CSV
#msg("Saving to <cyan>$ofile<none>\n");
#open($fh,">:utf8",$ofile);
#print $fh $csv;
#close($fh);


# Create breakdowns by local authority
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
foreach $sector (sort(keys(%{$sectors}))){
	print $fh ",Sector";
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
foreach $sector (sort(keys(%{$sectors}))){
	print $fh ",\"$sector\"";
}
foreach $industry (sort(keys(%{$industries}))){
	print $fh ",\"$industry\"";
}
print $fh "\n";
# Final header row
for($i = 0; $i < $n; $i++){ print $fh ($i == 0 ? "":",")."---"; }
print $fh "\n";

# Make rows
foreach $la (sort(keys(%{$hexes}))){
	print $fh "$la,".($ladata->{$la}{'count'}||0);

	for($s = 0; $s < @sizes; $s++){
		print $fh ",".($ladata->{$la}{'sizes'}{$sizes[$s]}||"0");
	}
	foreach $own (sort(keys(%{$owned}))){
		print $fh ",".($ladata->{$la}{'owned'}{$own}||"0");
	}
	foreach $sector (sort(keys(%{$sectors}))){
		print $fh ",".($ladata->{$la}{'sectors'}{$sector}||"0");
	}
	foreach $industry (sort(keys(%{$industries}))){
		print $fh ",".($ladata->{$la}{'industries'}{$industry}||"0");
	}
	print $fh "\n";
	
	if($hexes->{$la}{'region'} eq "E12000001" || $hexes->{$la}{'region'} eq "E12000002" || $hexes->{$la}{'region'} eq "E12000003"){
		$total += ($ladata->{$la}{'count'}||0);
	}
}
close($fh);

msg("Save northern total to <cyan>$sfile<none>\n");
open($fh,">:utf8",$sfile);
print $fh "name,value,footnote,post\n";
print $fh "\"Total B Corps\",$nbhits,\"In the UK\"\n";
print $fh "\"Northern B Corps\",$total,,\n";
close($fh);

msg("Total of <yellow>$total<none> northern corps out of <yellow>$nbhits<none>.");


updateCreationTimestamp($yfile);



##############################
# Sub routines

sub getEnvironment {
	my ($fh,@lines,$env,$k,$v,$line);
	open($fh,$basedir."../.env");
	@lines = <$fh>;
	close($fh);
	foreach $line (@lines){
		$line =~ s/[\n\r]//g;
		($k,$v) = split(/=/,$line);
		$env->{$k} = $v;
	}
	return $env;
}

sub SavePostcodeLookup {
	my $file = shift;
	my $pcds = shift;
	my ($la,$pcd);
	msg("Saving postcodes to <cyan>$file<none>...\n");
	open($fh,">",$file);
	print $fh "Postcode,LADCD\n";
	foreach $pcd (sort(keys(%{$pcds}))){
		if($pcd){
			print $fh "$pcd,$pcds->{$pcd}\n";
		}
	}
	close($fh);
	return;
}

sub GetPostcodeLookup {
	my $file = shift;
	my ($fh,@lines,$line,$pcd,$la,$pcds);

	msg("Reading postcodes from <cyan>$file<none>...\n");
	open($fh,$file);
	@lines = <$fh>;
	close($fh);
	
	$pcds = {};
	foreach $line (@lines){
		$line =~ s/[\n\r]//g;
		($pcd,$la) = split(/,/,$line);
		$pcd = uc($pcd);
		$pcd =~ s/ //g;
		$pcds->{$pcd} = $la;
	}
	msg("done\n");
	return $pcds;
}

# Fixes for poorly formatted postcodes
sub fixPostcode {
	my $pcd = shift;
	my $name = shift;
	$pcd = uc($pcd);
	$pcd =~ s/[^A-Z0-9]//g;
	$pcd =~ s/LONDON//g;
	if($pcd eq "LS25DZ"){ $pcd = "LS254DZ"; }
	if($pcd eq "GL52GQ"){ $pcd = "GL52QG"; }
	if($pcd eq "SN21NR"){ $pcd = "SN12NR"; }
	if($pcd eq "CH645FE"){ $pcd = "CH654FE"; }
	if($pcd eq "EC1V7DO"){ $pcd = "EC1V7DP"; }
	if($pcd eq "TB91BE"){ $pcd = "TN91BE"; }
	if($pcd eq "BS14RWUK"){ $pcd = "BS14RW"; }
	if($pcd eq "TR11" && $name eq "Kingdom & Sparrow"){ $pcd = "TR113JJ"; }
	if($pcd eq "CA15" && $name eq "SISGroup Ltd."){ $pcd = "CA158NT"; }
	if($pcd eq "ECV12NX" && $name eq "Profit Impact"){ $pcd = "EC1V2NX"; }
	if($pcd eq "EH6" && $name eq "Rationale"){ $pcd = "EH66RA"; }
	if($pcd eq "BA30DL" && $name eq "Natural Vitality"){ $pcd = "BA20DL"; }
	if($pcd eq "S331AZ" && $name eq "Sladen Consulting"){ $pcd = "S321AZ"; }
	if($pcd eq "HA1SX1" && $name eq "The Curious Beetle"){ $pcd = "HA11SX"; }
	if($pcd eq "SW9" && $name eq "Urban Jungle Services Ltd"){ $pcd = "N17GU"; }
	if($pcd eq "W12" && $name eq "Higson"){ $pcd = "W127RZ"; }
	if($pcd eq "" && $name eq "Kin and Carta Plc"){ $pcd = "N19BE"; }
	if($pcd eq "UK" && $name eq "By Sarah"){ $pcd = "B798RH"; }
	if($pcd eq "WC2A0HF"){ $pcd = "WC2H0HF"; }
	if($pcd eq "TA11FH"){ $pcd = "TA11QN"; }
	if($pcd eq "SE28EA" && $name eq "ZeroBees"){ $pcd = "SE228EA"; }
	return $pcd;
}

sub FindThatLocalAuthority {
	my $pcd = shift;
	my (@lines,$json);

	if($pcd){
		msg("Getting postcode <green>$pcd<none>\n");
		@lines = `curl 'https://findthatpostcode.uk/postcodes/$pcd.json' -s`;
		$json = ParseJSON(join("",@lines));
		$la = $json->{'data'}{'attributes'}{'laua'};
		if(!defined($la)){
			warning("Bad postcode <green>$pcd<none>\n");
			return "";
		}else{
			return $la;
		}
	}
	return "";
}


#######################
sub updateCreationTimestamp {
	my ($file) = @_;
	my $dt = strftime("%FT%H:%M", localtime);
	open(my $fh, '>', $file);
	print $fh $dt;
	close $fh;
	msg("Updating timestamp in <cyan>$file<none>\n");
}