use strict;
use warnings;
package LaTeX::ToUnicode;
BEGIN {
  $LaTeX::ToUnicode::VERSION = '0.11';
}
#ABSTRACT: Convert LaTeX commands to Unicode (simplistically)


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( convert );

use utf8;
use Encode;
use LaTeX::ToUnicode::Tables;

sub convert {
    my ( $string, %options ) = @_;
    $string = _convert_commands( $string );
    $string = _convert_accents( $string );
    $string = _convert_german( $string ) if $options{german};
    $string = _convert_symbols( $string );
    $string = _convert_specials( $string );
    $string = _convert_ligatures( $string );
    $string = _convert_markups( $string );
    
    # After all this, $string contains \x{....} where translations have
    # happened. Change those to the desired output format. Thus we
    # assume that the Unicode \x{....}'s are not themselves involved in
    # further translations, which is, so far, true.
    # 
    my $ofmt = $options{outputfmt};
    my $ofmt_ok = 1;
    if (! $ofmt || $ofmt eq "chars") {
      # Convert our \x strings from Tables.pm to the binary characters.
      # Presumably no more than four hex digits.
      $string =~ s/\\x\{(.{1,4})\}/ pack('U*', hex($1))/eg;

    } elsif ($ofmt eq "entities") {
      # First convert the XML special characters that appeared in the
      # input, e.g., from a TeX \&.
      $string =~ s/&/&amp;/g;
      $string =~ s/</&lt;/g;
      $string =~ s/>/&gt;/g;
      
      # Our values in Tables.pm are simple ASCII strings \x{....},
      # so we can replace them with hex entities with no trouble.
      # Fortunately TeX does not have a standard \x control sequence.
      $string =~ s/\\x\{(....)\}/&#x$1;/g;
      
      # The rest of the job is about binary Unicode characters in the
      # input. We want to transform them into entities also. As always
      # in Perl, there's more than one way to do it.
      my $ret = "";
      #
      # decode_utf8 is described in https://perldoc.perl.org/Encode.
      # Without the decode_utf8, all of these methods output each byte
      # separately; apparently $string is a byte string at this point,
      # not a Unicode string. I don't know why that is.
      $ret = decode_utf8($string);
      #
      # Transform everything that's not printable ASCII or newline into
      # entities.
      $ret =~ s/([^ -~\n])/ sprintf("&#x%04x;", ord($1)) /eg;
      # 
      # This method leaves control characters as literal; doesn't matter
      # for XML output, since control characters aren't allowed, but
      # let's use the regexp method anyway.
      #$ret = encode("ascii", decode_utf8($string), Encode::FB_XMLCREF);
      # 
      # The nice_string function from perluniintro also works.
      # 
      # This fails, just outputs numbers (that is, ord values):
      # foreach my $c (unpack("U*", $ret)) {
      # 
      # Without the decode_utf8, outputs each byte separately.
      # With the decode_utf8, works, but the above seems cleaner.
      #foreach my $c (split(//, $ret)) {
      #  if (ord($c) <= 31 || ord($c) >= 128) {
      #    $ret .= sprintf("&#x%04x;", ord($c));
      #  } else {
      #    $ret .= $c;
      #  }
      #}
      #
      $string = $ret; # assigned from above.

    } else {
      $ofmt_ok = 0;
      warn "LaTeX::ToUnicode::convert: unknown outputfmt value: $ofmt\n";
      # leave \x{....}.
    }
    
    if ($ofmt_ok && $string =~ /\\x\{/) {
      warn "LaTeX::ToUnicode::convert: untranslated \\x remains: $string\n";
      warn "LaTeX::ToUnicode::convert:   please report as bug.\n";
    }
    
    # Drop braces around text at end, unless we have untranslated \x.
    $string =~ s/{(\w*)}/$1/g if $ofmt_ok;
    $string;
}

sub _convert_commands {
    my $string = shift;

    foreach my $command ( keys %LaTeX::ToUnicode::Tables::COMMANDS ) {
        my $repl = $LaTeX::ToUnicode::Tables::COMMANDS{$command};
        # replace {\CMD}
        $string =~ s/\{\\$command\}/$repl/g;
        #
        # replace \CMD, preceded by not-consumed non-backslash,
        # and followed by (not consumed) whitespace or end-of-word
        # or (for control symbols) right brace.
        $string =~ s/(?<=[^\\])\\$command(?=\s|\b|\})/$repl/g;
        #
        # replace \CMD, followed similarly, but at beginning of whole
        # string, which otherwise wouldn't be matched. Two separate
        # regexps to avoid variable-length lookbehind.
        $string =~ s/^\\$command(?=\s|\b\})/$repl/g;
    }

    $string;
}

sub _convert_accents {
    my $string = shift;
    my %tbl = %LaTeX::ToUnicode::Tables::ACCENTS;
    $string =~ s/(\{\\(.)\s*\{(\\?\w{1,2})\}\})/$tbl{$2}{$3} || $1/eg; #{\"{a}}
    $string =~ s/(\{\\(.)\s*(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # {\"a}
    $string =~ s/(\\(.)\s*(\\?\w{1,1}))/        $tbl{$2}{$3} || $1/eg; # \"a
    $string =~ s/(\\(.)\s*\{(\\?\w{1,2})\})/    $tbl{$2}{$3} || $1/eg; # \"{a}
    
    # The argument is just one \w character for the \"a case, not two,
    # because otherwise we might consume a following character that is
    # not part of the accent, e.g., a backslash (\"a\'e).
    # 
    # Others can be two because of the \t tie-after accent. Even {\t oo} is ok.
    # 
    # Allow whitespace after the \CMD, e.g., "\c c". Even for the
    # control symbols, it turns out spaces are ignored there (\" o),
    # unlike the usual syntax.
    # 
    # Some non-word constituents would work, but in practice we hope
    # everyone just uses letters.

    $string;
}

sub _convert_german {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::GERMAN ) {
        $string =~ s/\Q$symbol\E/$LaTeX::ToUnicode::Tables::GERMAN{$symbol}/g;
    }
    $string;
}

sub _convert_symbols {
    my $string = shift;

    foreach my $symbol ( keys %LaTeX::ToUnicode::Tables::SYMBOLS ) {
        $string =~ s/{\\$symbol}/$LaTeX::ToUnicode::Tables::SYMBOLS{$symbol}/g;
        $string =~ s/\\$symbol\b/$LaTeX::ToUnicode::Tables::SYMBOLS{$symbol}/g;
    }
    $string;
}

# Replace \<specialchar> with <specialchar>.
sub _convert_specials {
    my $string = shift;
    my $specials = join( '|', @LaTeX::ToUnicode::Tables::SPECIALS );
    my $pattern = qr/\\($specials)/o;
    $string =~ s/$pattern/$1/g;
    $string =~ s/\\\$/\$/g;
    $string;
}

sub _convert_ligatures {
    my $string = shift;

    # have to convert these in order specified.
    my @ligs = @LaTeX::ToUnicode::Tables::LIGATURES;
    for (my $i = 0; $i < @ligs; $i+=2) {
        my $in = $ligs[$i];
        my $out = $ligs[$i+1];
        $string =~ s/\Q$in\E/$out/g;
    }
    $string;
}

# 
sub _convert_markups {
    my $string = shift;
    my $orig_string = $string;
    
    my $markups = join( '|', @LaTeX::ToUnicode::Tables::MARKUPS );
    
    # Remove \textMARKUP{...}, leaving just the {...}
    $string =~ s/\\text($markups)\b\s*//g;

    # Similarly remove \MARKUPshape.
    $string =~ s/\\($markups)shape\b\s*//g;

    # Remove braces and \command in: {... \command ...}
    $string =~ s/(\{[^{}]+)\\(?:$markups)\s+([^{}]+\})/$1$2/g;

    # Remove braces and \command in: {\command ...}
    $string =~ s/\{\\(?:$markups)\s+([^{}]*)\}/$1/g;

    # Remove: {\command
    # Although this will leave unmatched } chars behind, there's no
    # alternative without full parsing, since the bib entry will often
    # look like: {\em {The TeX{}book}}. Also might, in principle, be
    # at the end of a line.
    $string =~ s/\{\\(?:$markups)\b\s*//g;

    # Ultimately we remove all braces in ltx2crossrefxml SanitizeText fns,
    # so the unmatched braces don't matter ... that code should be moved here.

    $string;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

LaTeX::ToUnicode - Convert LaTeX commands to Unicode

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use LaTeX::ToUnicode qw( convert );

  convert( '{\"a}'           ) eq 'ä';  # true
  convert( '"a', german => 1 ) eq 'ä';  # true, `german' package syntax
  convert( '"a',             ) eq '"a';  # not enabled by default
  
  # more generally:
  my $latexstr;
  my $unistr = convert($latexstr);  # get literal (binary) Unicode characters

  my $entstr = convert($latexstr, outputfmt => "entities");  # get &#xUUUU;

=head1 DESCRIPTION

This module provides a method to convert LaTeX-style markups for accents etc.
into their Unicode equivalents. It translates commands for special characters
or accents into their Unicode equivalents and removes formatting commands.
It is not at all bulletproof or complete.

This module converts string fragments from BibTeX files into plain text.
It is nowhere near a complete conversion system.

=head1 FUNCTIONS

=head2 convert( $latex_string, %options )

Convert the text in C<$string> that contains LaTeX into a plain(er)
Unicode string. All escape sequences for accented and special characters
(e.g., C<\i>, C<\"a>, ...) are converted. Some basic formatting commands
(e.g., C<{\it ...}>) are removed.

These keys are recognized in C<%options>:

=over

=item C<german>

If this option is set, the commands introduced by the package `german'
(e.g. C<"a> eq C<ä>, note the missing backslash) are also
handled.

=item C<outputfmt> I<type>

If I<type> is C<entities>, output C<&#xUUUU;> entities (for XML); in
this case, also convert the E<lt>, E<gt>, C<&> metacharacters to entities.
Non-ASCII characters in the input are also converted to entities, not
only the translations from TeX.

If I<type> is C<chars>, output literal (binary) Unicode characters, and
do not change any metacharacters; this is the default.

=back

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com> and
Boris Veytsman <boris@varphi.com>
L<https://github.com/borisveytsman/bibtexperllibs>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2020 by Gerhard Gossen and Boris Veytsman

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
