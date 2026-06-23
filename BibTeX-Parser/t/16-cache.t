#!/usr/bin/perl -w

BEGIN{ unshift @INC, "./lib/";};

use BibTeX::Parser;
use IO::File;
my $fh = new IO::File "t/bibs/english.bib", "r" ;

my $parser = new BibTeX::Parser($fh);
$parser->read();
print "Number of entries: ", $parser->n(), "\n";
print "Entries: ", join(", ", @{$parser->keys}), "\n";
print "Existing entry: ", $parser->has('Quirk-CompGram'), "\n";
print "Non-existing entry: ", $parser->has('QuirkCompGram'), "\n";
print "Entry: ", $parser->entry('Quirk-CompGram')->to_string(), "\n";

