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
require $basedir."lib.pl";

# Define some files
my $apiresult = $basedir."../working/true-north/api.json";
my $csvfile = $basedir."../src/overview/northern-stars/_data/northern_stars.csv";
my $datefile = $basedir."../src/overview/northern-stars/_data/updated.yaml";


my ($raw,$json,$csv,$i,$name,$link,$date,$desc,$article,$fh);

# Create the raw data to send
$raw = '{"query":"query GetPaginatedInsights($entryIds: [QueryArgument], $limit: Int, $offset: Int) {\n  insights: insightsEntries(relatedTo: $entryIds, limit: $limit, offset: $offset) {\n    ... on insights_default_Entry {\n      ...RelatedInsight_Fragment\n    }\n  }\n  numResults: entryCount(section: \"insights\", relatedTo: $entryIds)\n}\n\nfragment RelatedInsight_Fragment on EntryInterface {\n  ... on insights_default_Entry {\n    id\n    title\n    uri\n    slug\n    postDate @formatDateTime(format: \"Y-m-d\")\n    postDateFormatted: postDate @formatDateTime(format: \"j F Y\")\n    indexHeading\n    indexSummary\n    fallbackImage: indexImage(limit: 1) @transform(width: 559, height: 559) {\n      ...Image_Fragment\n    }\n    img_image_webp_xs: indexImage(limit: 1) @transform(width: 344, height: 344, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n    img_image_webp_sm: indexImage(limit: 1) @transform(width: 559, height: 559, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n    img_image_webp_md: indexImage(limit: 1) @transform(width: 324, height: 324, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n    img_image_webp_lg: indexImage(limit: 1) @transform(width: 277, height: 277, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n    img_image_webp_xl: indexImage(limit: 1) @transform(width: 353, height: 353, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n    img_image_webp_2xl: indexImage(limit: 1) @transform(width: 382, height: 382, format: \"webp\") {\n      ...SrcSetAll_Fragment\n    }\n  }\n}\n\nfragment Image_Fragment on servd_Asset {\n  width\n  height\n  alt\n  title\n  url\n}\n\nfragment SrcSetAll_Fragment on servd_Asset {\n  srcset(sizes: [\"1x\", \"1.5x\", \"1.75x\", \"2x\"])\n}","variables":{"entryIds":["92171"],"limit":96,"offset":0},"operationName":"GetPaginatedInsights"}';
# Get the response back on the command line
msg("Get data from Brabner's website...\n");
`curl -s -H 'accept: */*' -H 'accept-language: en-US,en;q=0.9' -H 'cache-control: no-cache' -H 'content-type: application/json; charset=UTF-8' -H 'origin: https://www.brabners.com' -H 'pragma: no-cache' -H 'priority: u=1, i' -H 'referer: https://www.brabners.com/insights/northern-stars' -H 'sec-ch-ua: "Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-dest: empty' -H 'sec-fetch-mode: cors' -H 'sec-fetch-site: same-site' -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' --data-raw '$raw' -o "$apiresult.tmp" 'https://cms.brabners.com/api'`;
# Load the JSON
$json = LoadJSON($apiresult.".tmp");

# Check if the response looks like the sort of JSON we expect
if(!defined($json->{'data'})){
	# The output seems bad so load from our existing API result
	$json = LoadJSON($apiresult);
}else{
	# Overwrite with the temporary version
	`mv $apiresult.tmp $apiresult`;
}

# Build the CSV
$csv = "company_name,article_link,date_published,date_formatted,description\n";
for($i = 0; $i < @{$json->{'data'}{'insights'}}; $i++){
	$article = $json->{'data'}{'insights'}[$i];
	while($article->{'title'} =~ s/^(True North|Northern Star|Northern Stars)(\: | — )//){
		
	}
	$article->{'title'} =~ s/ (—|–) .*//g;
	$csv .= "\"".($article->{'title'}||"")."\",";
	$csv .= "https://www.brabners.com/".($article->{'uri'}).",";
	$csv .= "".($article->{'postDate'}).",";
	$csv .= "\"".($article->{'postDateFormatted'})."\",";
	$csv .= "\"".($article->{'indexSummary'})."\"";
	$csv .= "\n";
}

msg("Save CSV to <cyan>$csvfile<none>\n");
open($fh,">:utf8",$csvfile);
print $fh $csv;
close($fh);

updateCreationTimestamp($datefile);
