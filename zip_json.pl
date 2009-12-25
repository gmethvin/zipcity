#!/usr/bin/perl
#
# Zip to city and city to zip json script.
#
# Copyright (c) 2009 Greg Methvin
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

print "Content-Type: text/plain;charset=iso-8859-1\r\n\r\n";
#print "Content-Type: application/json;charset=iso-8859-1\r\n\r\n";

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
