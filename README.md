# nsw-oeh-npws-alerts

The NSW National Parks and Wildlife Service (NPWS) publishes [park alerts](https://www.nationalparks.nsw.gov.au/alerts/alerts-list) as an [RSS feed](https://www.nationalparks.nsw.gov.au/api/rssfeed/get). This project aims to make that feed more developer friendly.

You can either build this application into your own pipeline or use the hosted URL at https://www.beyondtracks.com/contrib/nsw-oeh-npws-alerts/ (no service availability guarantees!).

_NSW NPWS National Park Alerts are © State of New South Wales and Department of Climate Change, Energy, the Environment and Water (DCCEEW). Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0)._ See [https://www.nationalparks.nsw.gov.au/copyright-disclaimer](https://www.nationalparks.nsw.gov.au/copyright-disclaimer).

# Where is it used?

This pipeline has been built for [www.beyondtracks.com](https://www.beyondtracks.com) to provide park alerts affecting walks on [BeyondTracks](https://www.beyondtracks.com).

# Features

 - **Workaround for "Connection reset by peer"** The upstream feed suffered issues where the remote server resets the connection before it has finished transmitting the entire file to the client. This results in a truncated file. We try to work around this issue by continually re-requesting the file until it is retrieved in full, in fact this is the default wget behaviour. This was reported to OEH but the issue is still present at times.
 - **JSON** The upstream feed is in GeoRSS, and while that's great for feed aggregators, for web developers a JSON feed is preferable.
 - **Split by park** The upstream GeoRSS feed contains all alerts state wide, for BeyondTracks.com we prefer to be able to request alerts for an individual park.
 - **Sanitize HTML** The upstream feed uses HTML for formatting of alert content. This presents a security risk to any site using this feed directly to display alerts as NPWS could inject malicious content into the 3rd party site. We'd still like to retain the formatting used by NPWS to present their alert content as close as possible to as intended, so we use https://metacpan.org/pod/HTML::Scrubber to sanitize the HTML to ensure only safe formatting markup makes it through.
 - **HTML output** The HTML content is extracted from the GeoRSS into a sanitized .html file.
 - **Markdown output** The HTML content as extracted from the GeoRSS is converted to a .md file.

# Usage

Install required Perl dependencies, on Debian with:

     sudo apt-get install libxml-rss-perl libjson-perl libhtml-scrubber-perl libfile-spec-perl libhtml-wikiconverter-markdown-perl libtext-unidecode-perl libhtml-clean-perl

Then run the script with:

    ./nsw-oeh-npws-alerts.pl /srv/www nsw-oeh-npws-alerts

This will create the directory `nsw-oeh-npws-alerts` within `/srv/www`. Inside `nsw-oeh-npws-alerts` will be a series of JSON files, one for each park which contains an alert. The individual park alert JSON files will look like this:

```json
{
    "content": {
        "pubDate": "Wed, 08 Nov 2017 10:59:33 +1100",
        "category": "Other planned events",
        "name": "South East Forests National Park",
        "description": "<strong>Other planned events: Weed spraying on Nungatta Road and Palarang Road</strong> ...",
        "link": "http://www.nationalparks.nsw.gov.au/visit-a-park/parks/South-East-Forests-National-Park/Local-alerts"
    },
    "metadata": {
        "pubDate": "Sat, 06 Jan 2018 10:25:48 +1100",
        "attribution": "&copy; State of New South Wales through the Office of Environment and Heritage",
        "link": "http://www.nationalparks.nsw.gov.au/alerts/alerts-list",
        "generator": "NSW National Parks and Wildlife Service"
    }
}
```

`metadata` is details about the park alerts feed, and `content` is specific to this park alert. With this in mind the `content.pubDate` indicates when the specific park alert was published/last revised and the `metadata.pubDate` indicates when the park alerts feed was last updated/retrieved.

Alongside the JSON files, an HTML file and a Markdown file are created including just the `content.description` content.

# Warranty

The use of information in the National Park Alerts feed can affect life and property.
Errors or omissions may be present and/or the upstream supplied data
structure may change without any notice causing issues. Use at your own risk.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
