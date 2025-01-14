#!/usr/bin/perl -wCS

use strict;
use warnings;
use utf8;

use Encode;
use File::Temp qw/ tempfile /;
use XML::RSS;
use JSON 'encode_json';
use File::Path qw(mkpath rmtree);
use HTML::Scrubber;
use HTML::Entities; # provides decode_entities
#use HTML::Clean;
use File::Spec;
use Text::Unidecode qw(unidecode);
use HTML::WikiConverter;

# any files saved should be in UTF-8
use open qw( :std :encoding(UTF-8) );

# setup the HTML to Markdown converter
my $html2md = new HTML::WikiConverter( dialect => 'Markdown', link_style => 'inline', md_extra => 1 );

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

    # parse the RSS file
    my $rss = XML::RSS->new( encoding => "UTF-8" );
    $rss->parsefile($feed_filename);

    # configure scrubbed to only allow basic HTML formatting
    my $scrubber = HTML::Scrubber->new(
        allow => [ qw[ strong b br a ul ol li i span ] ],
        rules => [
            a => {
                href => 1
            }
        ]
    );

    # each park's alerts are an item
    foreach my $item ( @{ $rss->{items} } ) {
        my $park_name = $item->{title};

        # ensure park name is a very basic string by stripping out everything except alphanumeric and space
        $park_name =~ s/[^A-Za-z0-0 ]//g;

        # replace spaces with -
        $park_name =~ tr/ /-/;

        # final check to ensure no path traversal can occur
        ($park_name) = File::Spec->no_upwards( ($park_name) );

        my $park_file_json_name = $basedir . "/$alertdir/" . (lc($park_name)) . ".json";
        my $park_file_html_name = $basedir . "/$alertdir/" . (lc($park_name)) . ".html";
        my $park_file_md_name = $basedir . "/$alertdir/" . (lc($park_name)) . ".md";

        open (my $park_file_json, '>', $park_file_json_name);
        open (my $park_file_html, '>', $park_file_html_name);
        open (my $park_file_md, '>', $park_file_md_name);

        my $raw_description = $item->{description};

        # the description contains double encoded character references
        # https://developer.mozilla.org/en-US/docs/Glossary/Character_reference
        # for example: &amp;#xA0;
        # we first decode entities to convert this to
        # &#xA0;
        # then again decode entities to convert this to
        my $first_decode = decode_entities($raw_description);
        my $second_decode = decode_entities($first_decode);

        # then we scrub the HTML to only allow basic formatting
        my $scrubbed = $scrubber->scrub($second_decode);

        # source description includes a lot of unnessesary unicode characters
        # while we would like to support unicode and provide the content as-is
        # it's causing some encoding issues, and so to simplify things we
        # convert back to ascii
        my $description = unidecode($scrubbed);

        # clean up the HTML manually

        # remove leading and trailing whitespace within a <strong> element as this
        # isn't handled correctly by the html to markdown
        $description =~ s/<strong>\s+/<strong>/g;
        $description =~ s/\s+<\/strong>/<\/strong>/g;

        # force a newline after the end of a list
        # to prevent the generated markdown including
        # the next paragraph within the list
        $description =~ s/<\/ul>/<\/ul><br \/>/g;

        # force newlines after <br>
        $description =~ s/<br \/>/<br \/>\n/g;

        # h1 headings
        $description =~ s/^<strong>(.*): (.*)<\/strong>/<h1>$1: $2<\/h1>/gm;
        # h2 headings
        $description =~ s/^<strong>(.*)<\/strong>/<h2>$1<\/h2>/gm;

        #my $clean = HTML::Clean->new(\$description);
        #$clean->strip( { whitespace => 1, shortertags => 0 });
        #my $clean_description = $clean->data();
        #print STDOUT $$clean_description

        # JSON structure
        my $park_alert = {
            "name" => $item->{title},
            "pubDate" => $item->{pubDate},
            "link" => $item->{link},
            "description" => $description,
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

        # convert HTML to Markdown
        my $md = $html2md->html2wiki( $description );

        # manually cleanup markdown

        # remove <br>
        $md =~ s/<br \/>/\n/g;

        # remove some leading spaces without affecting empty lines
        $md =~ s/^ +//gm;

        # remove consecutive empty lines
        $md =~ s/\n\n\n*/\n\n/g;

        # save as JSON
        print {$park_file_json} encode_json $json;

        # save description as HTML
        print $park_file_html $description;

        # save description as Markdown
        print $park_file_md $md;

        close $park_file_json;
        close $park_file_html;
        close $park_file_md;
    }
    unlink $feed_filename;
} else {
    unlink $feed_filename;
    print STDERR "Error downloading remote feed\n";
    exit $wget_status;
}
