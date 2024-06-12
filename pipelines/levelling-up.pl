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

my ($basedir, $path,@rows,$r,@las,@lads,$l,%la,$lad,$hexjson,$fh,$percap);

# Get the real base directory for this script
BEGIN { ($basedir, $path) = abs_path($0) =~ m{(.*/)?([^/]+)$}; push @INC, $basedir; }

$hexjson = LoadJSON($basedir."../src/_data/hexjson/uk-local-authority-districts-2023.hexjson");

# Get the full list of local authorities and create a structure
@lads = sort(keys(%{$hexjson->{'hexes'}}));
for($r = 0; $r < @lads; $r++){
	$la{$lads[$r]} = {'total'=>0,'bids'=>0,'population'=>0,'name'=>$hexjson->{'hexes'}{$lads[$r]}{'n'}};
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
		$la{$lad}{'total'} += $rows[$r]->{'Bid Value'}/@las;
		$la{$lad}{'bids'}++;
	}
}
@rows = LoadCSV($basedir."../working/levelling-up/levelling-up-fund-round-2.csv");
for($r = 0; $r < @rows; $r++){
	@las = split(/;/,$rows[$r]->{'LADs'});
	for($l = 0; $l < @las; $l++){
		$lad = $las[$l];
		$la{$lad}{'total'} += $rows[$r]->{'Bid Value'}/@las;
		$la{$lad}{'bids'}++;
	}
}

open($fh,">:utf8",$basedir."../src/themes/purpose-social-impact/levelling-up/_data/levelling_up.csv");
print $fh "LAD23CD,LA name,Population (mid 2022 est),Bids,Total (£),Total,Per capita (£),Per capita\n";
foreach $lad (@lads){
	print $fh "$lad,\"$la{$lad}->{'name'}\",$la{$lad}->{'population'},";
	if($la{$lad}->{'bids'} > 0){
		$percap = ($la{$lad}->{'total'}/$la{$lad}->{'population'});
		print $fh "$la{$lad}->{'bids'},".sprintf("%0.2d",$la{$lad}->{'total'}).",\"".formatPounds($la{$lad}->{'total'})."\",".sprintf("%0.2f",$percap).",\"".formatPounds($percap)."\"\n";
	}else{
		print $fh ",,none,,none\n";
	}
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

# Version 1.3
sub ParseCSV {
	my $str = shift;
	my $config = shift;
	my (@rows,@cols,@header,$r,$c,@features,$data,$key,$k,$f,$n,$n2,$compact,$sline,$col);

	$compact = $config->{'compact'};
	$sline = $config->{'startrow'}||0;
	$col = $config->{'key'};

	$n = () = $str =~ /\r\n/g;
	$n2 = () = $str =~ /\n/g;
	if($n < $n2 * 0.25){ 
		# Replace CR LF with escaped newline
		$str =~ s/\r\n/\\n/g;
	}
	@rows = split(/[\n]/,$str);

	$n = @rows;
	
	for($r = $sline; $r < @rows; $r++){
		$rows[$r] =~ s/[\n\r]//g;
		@cols = split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/,$rows[$r]);

		if($r < $sline+1){
			# Header
			if(!@header){
				for($c = 0; $c < @cols; $c++){
					$cols[$c] =~ s/(^\"|\"$)//g;
				}
				@header = @cols;
			}else{
				for($c = 0; $c < @cols; $c++){
					$header[$c] .= "\n".$cols[$c];
				}
			}
		}else{
			$data = {};
			for($c = 0; $c < @cols; $c++){
				$cols[$c] =~ s/(^\"|\"$)//g;
				$data->{$header[$c]} = $cols[$c];
			}
			push(@features,$data);
		}
	}
	if($col){
		$data = {};
		for($r = 0; $r < @features; $r++){
			$f = $features[$r]->{$col};
			if($compact){ $f =~ s/ //g; }
			$data->{$f} = $features[$r];
		}
		return $data;
	}else{
		return @features;
	}
}

sub LoadCSV {
	# version 1.3
	my $file = shift;
	my $config = shift;
	
	msg("Processing CSV from <cyan>$file<none>\n");
	open(FILE,"<:utf8",$file);
	my @lines = <FILE>;
	close(FILE);
	return ParseCSV(join("",@lines),$config);
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
	open(FILE,"<:utf8",$file) || error("Unable to load <cyan>$file<none>.");
	@lines = <FILE>;
	close(FILE);
	$str = (join("",@lines));
	return ParseJSON($str);
}
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
