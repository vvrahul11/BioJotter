#line 1 "threads/shared.pm"
package threads::shared;

use 5.008;

use strict;
use warnings;

our $VERSION = '1.01';

BEGIN {
    # Declare that we have been loaded
    $threads::shared::threads_shared = 1;
}


# Load the XS code, if applicable
if ($threads::threads) {
    require XSLoader;
    XSLoader::load('threads::shared', $VERSION);

    *is_shared = \&_id;

} else {
    # String eval is generally evil, but we don't want these subs to
    # exist at all if 'threads' is not loaded successfully.
    # Vivifying them conditionally this way saves on average about 4K
    # of memory per thread.
    eval <<'_MARKER_';
        sub share          (\[$@%])         { return $_[0] }
        sub is_shared      (\[$@%])         { undef }
        sub cond_wait      (\[$@%];\[$@%])  { undef }
        sub cond_timedwait (\[$@%]$;\[$@%]) { undef }
        sub cond_signal    (\[$@%])         { undef }
        sub cond_broadcast (\[$@%])         { undef }
_MARKER_
}


### Export ###

sub import
{
    # Exported subroutines
    my @EXPORT = qw(share is_shared cond_wait cond_timedwait
                    cond_signal cond_broadcast);
    if ($threads::threads) {
        push(@EXPORT, 'bless');
    }

    # Export subroutine names
    my $caller = caller();
    foreach my $sym (@EXPORT) {
        no strict 'refs';
        *{$caller.'::'.$sym} = \&{$sym};
    }
}


### Methods, etc. ###

sub threads::shared::tie::SPLICE
{
    require Carp;
    Carp::croak('Splice not implemented for shared arrays');
}

1;

__END__

#line 392
