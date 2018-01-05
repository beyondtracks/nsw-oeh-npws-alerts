#!/usr/bin/perl -w

# apt-get install libwww-perl libxml-rss-perl libjson-perl libhtml-scrubber-perl libfile-spec-perl

use strict;
use warnings;

require LWP::UserAgent;
use XML::RSS;
use JSON 'encode_json';
use File::Path qw(mkpath rmtree);
use HTML::Scrubber;
use File::Spec;

if (@ARGV < 1) {
    die "Usage: $0 <output-directory>\n";
}

my $basedir = $ARGV[0];

if (!-d $basedir) {
    die "$basedir does not exist\nUsage: $0 <output-directory>\n";
}

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my $rss_url = "http://www.nationalparks.nsw.gov.au/api/rssfeed/get";

my $response = $ua->get($rss_url);

if ($response->is_success) {
    #remove existing park alerts as they are no longer current
    rmtree( $basedir . "/park-alerts" );

    # create a new empty directory for the new park alerts
    mkdir $basedir . "/park-alerts";

    my $rss = XML::RSS->new();
    $rss->parse( $response->decoded_content );
    
    my $scrubber = HTML::Scrubber->new(
        allow => [ qw[ strong b br a ul ol li i span ] ],
        rules => [
            a => {
                href => 1
            }
        ]
    );

    foreach my $item ( @{ $rss->{items} } ) {
        my $park_name = $item->{title};

        # ensure park name is a very basic string by stripping out everything except alphanumeric and space
        $park_name =~ s/[^A-Za-z0-0 ]//g;

        # replace spaces with -
        $park_name =~ tr/ /-/;

        # final check to ensure no path traversal can occur
        ($park_name) = File::Spec->no_upwards( ($park_name) );

        my $park_file_name = $basedir . "/park-alerts/" . (lc($park_name)) . ".json";

        open (my $park_file, '>', $park_file_name);


        my $park_alert = {
            "name" => $item->{title},
            "pubDate" => $item->{pubDate},
            "link" => $item->{link},
            "description" => $scrubber->scrub($item->{description}),
            "category" => $item->{category}
        };
        
        my $json = {
            "metadata" => {
                "pubDate" => $rss->{channel}->{'pubDate'},
                "generator" => $rss->{channel}->{generator},
                "link" => $rss->{channel}->{link},
                "attribution" => "&copy; State of New South Wales through the Office of Environment and Heritage"
            },
            "content" => $park_alert
        };

        
        print $park_file encode_json $json;

        close $park_file;
    }

}else{
    die "NPSW RSS Feed failed to download providing response " . $response->status_line;
}
