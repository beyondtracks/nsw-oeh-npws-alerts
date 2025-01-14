#!/usr/bin/perl -w

use strict;
use warnings;

use File::Temp qw/ tempfile /;
use XML::RSS;
use JSON 'encode_json';
use File::Path qw(mkpath rmtree);
use HTML::Scrubber;
use File::Spec;

if (@ARGV < 2) {
    die "Usage: $0 <output-directory> <alert-directory-name>\n";
}

my $basedir = $ARGV[0];
my $alertdir = $ARGV[1];

if (!-d $basedir) {
    die "$basedir does not exist\nUsage: $0 <output-directory> <alert-directory-name>\n";
}

my $rss_url = "https://www.nationalparks.nsw.gov.au/api/rssfeed/get";

# create a temp file to store the downloaded feed
my ($feed_filehandle, $feed_filename) = tempfile();

# download the feed with wget as LWP doesn't seem to handle dropped connections well
# see README.md for further details
my $wget_status = system("wget --quiet --tries=0 --read-timeout=30 -O $feed_filename $rss_url");

if ($wget_status == 0) {
    #remove existing park alerts as they are no longer current
    rmtree( $basedir . "/$alertdir" );

    # create a new empty directory for the new park alerts
    mkdir $basedir . "/$alertdir";

    my $rss = XML::RSS->new();
    $rss->parsefile($feed_filename);

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

        my $park_file_name = $basedir . "/$alertdir/" . (lc($park_name)) . ".json";

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
                "attribution" => "&copy; State of New South Wales and Department of Climate Change, Energy, the Environment and Water (DCCEEW)"
            },
            "content" => $park_alert
        };


        print $park_file encode_json $json;

        close $park_file;
    }
    unlink $feed_filename;
} else {
    unlink $feed_filename;
    print STDERR "Error downloading remote feed\n";
    exit $wget_status;
}
