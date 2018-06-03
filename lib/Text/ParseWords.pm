#line 1 "Text/ParseWords.pm"
package Text::ParseWords;

use vars qw($VERSION @ISA @EXPORT $PERL_SINGLE_QUOTE);
$VERSION = "3.24";

require 5.000;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(shellwords quotewords nested_quotewords parse_line);
@EXPORT_OK = qw(old_shellwords);


sub shellwords {
    my(@lines) = @_;
    $lines[$#lines] =~ s/\s+$//;
    return(quotewords('\s+', 0, @lines));
}



sub quotewords {
    my($delim, $keep, @lines) = @_;
    my($line, @words, @allwords);

    foreach $line (@lines) {
	@words = parse_line($delim, $keep, $line);
	return() unless (@words || !length($line));
	push(@allwords, @words);
    }
    return(@allwords);
}



sub nested_quotewords {
    my($delim, $keep, @lines) = @_;
    my($i, @allwords);

    for ($i = 0; $i < @lines; $i++) {
	@{$allwords[$i]} = parse_line($delim, $keep, $lines[$i]);
	return() unless (@{$allwords[$i]} || !length($lines[$i]));
    }
    return(@allwords);
}



sub parse_line {
    my($delimiter, $keep, $line) = @_;
    my($word, @pieces);

    no warnings 'uninitialized';	# we will be testing undef strings

    while (length($line)) {
	$line =~ s/^(["'])			# a $quote
        	    ((?:\\.|(?!\1)[^\\])*)	# and $quoted text
		    \1				# followed by the same quote
		   |				# --OR--
		   ^((?:\\.|[^\\"'])*?)		# an $unquoted text
		    (\Z(?!\n)|(?-x:$delimiter)|(?!^)(?=["']))  
		    				# plus EOL, delimiter, or quote
		  //xs or return;		# extended layout
	my($quote, $quoted, $unquoted, $delim) = ($1, $2, $3, $4);
	return() unless( defined($quote) || length($unquoted) || length($delim));

        if ($keep) {
	    $quoted = "$quote$quoted$quote";
	}
        else {
	    $unquoted =~ s/\\(.)/$1/sg;
	    if (defined $quote) {
		$quoted =~ s/\\(.)/$1/sg if ($quote eq '"');
		$quoted =~ s/\\([\\'])/$1/g if ( $PERL_SINGLE_QUOTE && $quote eq "'");
            }
	}
        $word .= substr($line, 0, 0);	# leave results tainted
        $word .= defined $quote ? $quoted : $unquoted;
 
        if (length($delim)) {
            push(@pieces, $word);
            push(@pieces, $delim) if ($keep eq 'delimiters');
            undef $word;
        }
        if (!length($line)) {
            push(@pieces, $word);
	}
    }
    return(@pieces);
}



sub old_shellwords {

    # Usage:
    #	use ParseWords;
    #	@words = old_shellwords($line);
    #	or
    #	@words = old_shellwords(@lines);
    #	or
    #	@words = old_shellwords();	# defaults to $_ (and clobbers it)

    no warnings 'uninitialized';	# we will be testing undef strings
    local *_ = \join('', @_) if @_;
    my (@words, $snippet);

    s/\A\s+//;
    while ($_ ne '') {
	my $field = substr($_, 0, 0);	# leave results tainted
	for (;;) {
	    if (s/\A"(([^"\\]|\\.)*)"//s) {
		($snippet = $1) =~ s#\\(.)#$1#sg;
	    }
	    elsif (/\A"/) {
		require Carp;
		Carp::carp("Unmatched double quote: $_");
		return();
	    }
	    elsif (s/\A'(([^'\\]|\\.)*)'//s) {
		($snippet = $1) =~ s#\\(.)#$1#sg;
	    }
	    elsif (/\A'/) {
		require Carp;
		Carp::carp("Unmatched single quote: $_");
		return();
	    }
	    elsif (s/\A\\(.)//s) {
		$snippet = $1;
	    }
	    elsif (s/\A([^\s\\'"]+)//) {
		$snippet = $1;
	    }
	    else {
		s/\A\s+//;
		last;
	    }
	    $field .= $snippet;
	}
	push(@words, $field);
    }
    return @words;
}

1;

__END__

#line 264
