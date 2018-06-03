#line 1 "bytes.pm"
package bytes;

our $VERSION = '1.02';

$bytes::hint_bits = 0x00000008;

sub import {
    $^H |= $bytes::hint_bits;
}

sub unimport {
    $^H &= ~$bytes::hint_bits;
}

sub AUTOLOAD {
    require "bytes_heavy.pl";
    goto &$AUTOLOAD if defined &$AUTOLOAD;
    require Carp;
    Carp::croak("Undefined subroutine $AUTOLOAD called");
}

sub length ($);
sub chr ($);
sub ord ($);
sub substr ($$;$$);
sub index ($$;$);
sub rindex ($$;$);

1;
__END__

#line 89
