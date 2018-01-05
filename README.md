# nsw-oeh-npws-alerts

The NSW Office of Environment and Heritage (OEH) [publishes an RSS feed of park alerts](http://www.nationalparks.nsw.gov.au/api/rssfeed/get), this project aims to make that feed more developer friendly.

You can either build this application into your own pipeline or use the hosted URL at https://www.beyondtracks.com/contrib/nsw-oeh-npws-alerts/ (no service availability guarantees!).

_NSW OEH National Park Alerts are © State of New South Wales and Office of Environment and Heritage 2018. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0)._

# Where is it used?

This pipeline has been built for [www.beyondtracks.com](https://www.beyondtracks.com) to provide park alerts affecting walks on [BeyondTracks](https://www.beyondtracks.com).

# Features

 - **Connection reset by peer** The upstream feed suffers issues where the remote server resets the connection before it has finished transmitting the entire file to the client. This results in a truncated file. We try to work around this issue by continually re-requesting the file until it is retrieved in full, in fact this is the default wget behaviour. This was reported to OEH but the issue is still present at times.
 - **JSON** The upstream feed is in GeoRSS, and while that's great for feed aggregators, for web developers a JSON feed is preferable.
 - **Split by park** The upstream GeoRSS feed contains all alerts state wide, for BeyondTracks.com we prefer to be able to request alerts for an individual park.
 - **Sanitize HTML** The upstream feed uses HTML for formatting of alert content. This presents a security risk to any site using this feed directly to display alerts as NPWS could inject malicious content into the 3rd party site. We'd still like to retain the formatting used by NPWS to present their alert content as close as possible to as intended, so we use https://metacpan.org/pod/HTML::Scrubber to sanitize the HTML to ensure only safe formatting markup makes it through.

# Warranty

The use of information in the National Park Alerts feed can affect life and property.
Errors or omissions may be present and/or the upstream supplied data
structure may change without any notice causing issues. Use at your own risk.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
