package BibTeX::Parser::Entry;
{
  $BibTeX::Parser::Entry::VERSION = '0.66';
}

use warnings;
use strict;

use BibTeX::Parser;
use BibTeX::Parser::Author;



sub new {
	my ($class, $type, $key, $parse_ok, $fieldsref) = @_;

	my %fields = defined $fieldsref ? %$fieldsref : ();
        if (defined $type) {
            $fields{_type} = uc($type);
        }
	$fields{_key}      = $key;
	$fields{_parse_ok} = $parse_ok;
        $fields{_raw}      = '';
	return bless \%fields, $class;
}



sub parse_ok {
	my $self = shift;
	if (@_) {
		$self->{_parse_ok} = shift;
	}
	$self->{_parse_ok};
}


sub error {
	my $self = shift;
	if (@_) {
		$self->{_error} = shift;
		$self->parse_ok(0);
	}
	return $self->parse_ok ? undef : $self->{_error};
}


sub type {
	if (scalar @_ == 1) {
		# get
		my $self = shift;
		return $self->{_type};
	} else {
		# set
		my ($self, $newval) = @_;
		$self->{_type} = uc($newval);
	}
}


sub key {
	if (scalar @_ == 1) {
		# get
		my $self = shift;
		return $self->{_key};
	} else {
		# set
		my ($self, $newval) = @_;
		$self->{_key} = $newval;
	}

}


sub field {
	if (scalar @_ == 2) {
		# get
		my ($self, $field) = @_;
		return $self->{ lc( $field ) };
	} else {
		my ($self, $key, $value) = @_;
		$self->{ lc( $key ) } = $value; #_sanitize_field($value);
	}

}

use LaTeX::ToUnicode qw( convert );


sub cleaned_field {
        my ( $self, $field, @options ) = @_;
        if ( $field =~ /author|editor/i ) {
            return $self->field( $field );
        } else {
            return convert( $self->field( lc $field ), @options );
        }
}


sub cleaned_author {
    my $self = shift;
    $self->_handle_cleaned_author_editor( [ $self->author ], @_ );
}


sub cleaned_editor {
    my $self = shift;
    $self->_handle_cleaned_author_editor( [ $self->editor ], @_ );
}

sub _handle_cleaned_author_editor {
    my ( $self, $authors, @options ) = @_;
    map {
        my $author = $_;
        my $new_author = BibTeX::Parser::Author->new;
        map {
            $new_author->$_( convert( $author->$_, @options ) )
        } grep { defined $author->$_ } qw( first von last jr );
        $new_author;
    } @$authors;
}

no LaTeX::ToUnicode;

sub _handle_author_editor {
    my $type = shift;
    my $self = shift;
    if (@_) {
	if (@_ == 1) { #single string
	    # my @names = split /\s+and\s+/i, $_[0];
	    $_[0] =~ s/^\s*//; 
	    $_[0] =~ s/\s*$//; 
	    my @names = BibTeX::Parser::_split_braced_string($_[0], 
							     '\s+and\s+');
	    if (!scalar @names) {
		$self->error('Bad names in author/editor field');
		return;
	    }
	    $self->{"_$type"} = [map {new BibTeX::Parser::Author $_} @names];
	    $self->field($type, join " and ", @{$self->{"_$type"}});
	} else {
	    $self->{"_$type"} = [];
	    foreach my $param (@_) {
		if (ref $param eq "BibTeX::Author") {
		    push @{$self->{"_$type"}}, $param;
		} else {
		    push @{$self->{"_$type"}}, new BibTeX::Parser::Author $param;
		}
		
		$self->field($type, join " and ", @{$self->{"_$type"}});
	    }
	}
    } else {
	unless ( defined $self->{"_$type"}) {
	    my @names = BibTeX::Parser::_split_braced_string($self->{$type} || "", '\s+and\s+' );
	    $self->{"_$type"} = [map {new BibTeX::Parser::Author $_} @names];
	}
	return @{$self->{"_$type"}};
    }
}



sub author {
	_handle_author_editor('author', @_);
}


sub editor {
	_handle_author_editor('editor', @_);
}


sub fieldlist {
	my $self = shift;
	
	return grep {!/^_/} keys %$self;	
}


sub has {
	my ($self, $field) = @_;

	return defined $self->{$field};
}

sub _sanitize_field {
	my $value = shift;	
	for ($value) {
		tr/\{\}//d;
		s/\\(?!=[ \\])//g;
		s/\\\\/\\/g;
	}
	return $value;
}



sub raw_bibtex {
	my $self = shift;
	if (@_) {
		$self->{_raw} = shift;
	}
	return $self->{_raw};
}

sub to_string {
    my $self = shift;
    my @fields = grep {!/^_/} keys %$self;	
    my $result = '@'.$self->type."{".$self->key.",\n";
    foreach my $field (@fields) {
	my $value = $self->field($field);
	if ($field eq 'author') {
	    my @names = ($self->author);
	    $value = join(' and ', @names);
	}
	if ($field eq 'editor') {
	    my @names = ($self->editors);
	    $value = join(' and ', @names);
	}
	$result .= "    $field = {"."$value"."},\n";
    }
    $result .= "}";
    return $result;
}

1; # End of BibTeX::Entry

__END__
=pod

=head1 NAME

BibTeX::Parser::Entry

=head1 VERSION

version 0.66

=head1 SYNOPSIS

This class ist a wrapper for a single BibTeX entry. It is usually created
by a BibTeX::Parser.

    use BibTeX::Parser::Entry;

    my $entry = BibTeX::Parser::Entry->new($type, $key, $parse_ok, \%fields);
    
    if ($entry->parse_ok) {
	    my $type    = $entry->type;
	    my $key     = $enty->key;
	    print $entry->field("title");
	    my @authors = $entry->author;
	    my @editors = $entry->editor;

	    ...

	    print $entry->to_string;
    }

   

=head1 NAME

BibTeX::Parser::Entry - Contains a single entry of a BibTeX document.

=head1 VERSION

version 0.66

=head1 FUNCTIONS

=head2 new

Create new entry.

=head2 parse_ok

If the entry was correctly parsed, this method returns a true value, false otherwise.

=head2 error

Return the error message, if the entry could not be parsed or undef otherwise.

=head2 type

Get or set the type of the entry, eg. 'ARTICLE' or 'BOOK'. Return value is 
always uppercase.

=head2 key

Get or set the reference key of the entry.

=head2 field($name [, $value])

Get or set the contents of a field. The first parameter is the name of the
field, the second (optional) value is the new value.

=head2 cleaned_field($name)

Retrieve the contents of a field in a format that is cleaned of TeX markup.

=head2 cleaned_author

Get an array of L<BibTeX::Parser::Author> objects for the authors of this
entry. Each name has been cleaned of accents and braces.

=head2 cleaned_editor

Get an array of L<BibTeX::Parser::Author> objects for the editors of this
entry. Each name has been cleaned of accents and braces.

=head2 author([@authors])

Get or set the authors. Returns an array of L<BibTeX::Author|BibTeX::Author> 
objects. The parameters can either be L<BibTeX::Author|BibTeX::Author> objects
or strings.

Note: You can also change the authors with $entry->field('author', $authors_string)

=head2 editor([@editors])

Get or set the editors. Returns an array of L<BibTeX::Author|BibTeX::Author> 
objects. The parameters can either be L<BibTeX::Author|BibTeX::Author> objects
or strings.

Note: You can also change the authors with $entry->field('editor', $editors_string)

=head2 fieldlist ()

Returns a list of all the fields used in this entry.

=head2 has($fieldname)

Returns a true value if this entry has a value for $fieldname.

=head2 raw_bibtex ()

Return raw BibTeX entry (if available).

=head2 to_string ()

Returns a text of the BibTeX entry in BibTeX format

=head1 AUTHOR

Gerhard Gossen <gerhard.gossen@googlemail.com> and
Boris Veytsman <boris@varphi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2015 by Gerhard Gossen and Boris Veytsman

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

