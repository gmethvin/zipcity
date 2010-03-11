#!/usr/bin/perl
#
# Zip to city and city to zip json script.
#
# Copyright (c) 2009 Greg Methvin
#
# See LICENSE for license

use strict;
use JSON::XS;
use DBI;

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
    my ($n, $v) = split /=/;
    $v =~ tr/+/ /;
    $v =~ s/%(..)/pack("C", hex($1))/eg;
    ($n, $v) = (lc $n, uc $v);
    $pc = $v if $n eq "city";
    $ps = $v if $n eq "state";
    $pz = $v if $n eq "zip";
}

# Allow "city, state" as a possible input for the city
$pc =~ s/^([\w\s]+)\s*\,\s*(\w{2})$/$1/
    and ($pc, $ps) = ($1, $ps || $2);

# Check for the proper zip, city and state format: the zip can be a
# prefix, so 5 or fewer digits, the city is any word char and the
# state must be a two-letter state code.
$pz =~ /^\d{0,5}$/ && $pc =~ /^[\w\s]*$/ && $ps =~ /^(\w{2})?$/
    or error;

# Make blank city and state match any.
$pc or $pc = "%";
$ps or $ps = "%";

# Connect to the database.
my $dbh = DBI->connect("dbi:SQLite:dbname=zipdb","","");

# Prepare the statement.
my $sth = $dbh->prepare(
    "SELECT zip, city, state FROM zipcodes WHERE " .
    "zip LIKE ? AND city LIKE ? AND state LIKE ?");
$sth->bind_param(1, $pz . "%");
$sth->bind_param(2, $pc);
$sth->bind_param(3, $ps);
$sth->execute;

# Print out the json.
print encode_json $sth->fetchall_arrayref({});
