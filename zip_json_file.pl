#!/usr/bin/perl
#
# Zip to city and city to zip json script.
#
# Copyright (c) 2009 Greg Methvin
#
# See LICENSE for license

use strict;
use JSON::XS;

# File with zip codes.
use constant ZC_ALL => "zipcodes_all";

# Prefix for two-digit range zip code files.
use constant ZC_PREFIX => "zipcodes/";

# Print an empty json array and die.
sub error {
    print "[]" and die;
}

print "Content-Type: text/plain;charset=utf-8\r\n\r\n";
#print "Content-Type: application/json;charset=utf-8\r\n\r\n";

$ENV{'REQUEST_METHOD'} =~ /GET/i
    or error;

# Variables for params of city, state, and zip.
my ($pc, $ps, $pz);

for (split '&', $ENV{'QUERY_STRING'}) {
    # Get the parameters; convert param names to lowercase and values
    # to uppercase and check if they are city, state, or zip, storing
    # them in the appropriate variables.
    my ($n, $v) = split '=';
    $v =~ tr/+/ /;
    $v =~ s/%(..)/pack("C", hex($1))/eg;
    ($n, $v) = (lc $n, uc $v);
    $pc = $v if $n eq "city";
    $ps = $v if $n eq "state";
    $pz = $v if $n eq "zip";
}

# Check for the proper zip and state format; the zip can be a prefix,
# so 5 or fewer digits and the state must be a state code.
$pz =~ /^d{0,5}$/ || $ps =~ /^(\a{2}|)$/
    or error;

# See if we can use a prefix file, so we can get a faster lookup. This
# gives us an advantage in the usual case since a zip query is the
# most common and we need to search a smaller file. Also, the
# filesystem should cache the files for commonly-searched zip ranges.
if ($pz =~ /^\d{2}/) {
    open ZC, ZC_PREFIX . substr($pz, 0, 2)
        or error;
} else {
    open ZC, ZC_ALL;
}

# An array of hash references which we'll jsonize in the end.
my @data;

for (<ZC>) {
    # Parse out the line and check for a match.

    /(\d{5}):([\w\s]+), (\w{2})/ or next;
    my ($city, $state, $zip) = map { uc } ($2, $3, $1);
    next unless $zip =~ /^$pz/ &&
        (!$pc || $pc eq $city) && (!$ps || $ps eq $state);
    push @data, { city => $city,
                  state => $state,
                  zip => $zip };
}

close ZC;

# Print out the json.
print encode_json \@data;
