#!/usr/bin/perl -w

use Test::More;

use BibTeX::Parser;
use IO::File;


my $fh = new IO::File "t/bibs/01.bib", "r" ;

my $parser = new BibTeX::Parser $fh;




while (my $entry = $parser->next) {
    if($entry->key eq 'key01') {
	my $result='@ARTICLE{key01,
    year = {1950},
    author = {Duck, Donald and Else, Someone},
    title = {Title text},
    month = {January~1},
}';
    is($entry->to_string,$result);
    }

}

done_testing();

