#line 1 "Carp.pm"
package Carp;

our $VERSION = '1.04';

#line 106

# This package is heavily used. Be small. Be fast. Be good.

# Comments added by Andy Wardley <abw@kfs.org> 09-Apr-98, based on an
# _almost_ complete understanding of the package.  Corrections and
# comments are welcome.

# The members of %Internal are packages that are internal to perl.
# Carp will not report errors from within these packages if it
# can.  The members of %CarpInternal are internal to Perl's warning
# system.  Carp will not report errors from within these packages
# either, and will not report calls *to* these packages for carp and
# croak.  They replace $CarpLevel, which is deprecated.    The
# $Max(EvalLen|(Arg(Len|Nums)) variables are used to specify how the eval
# text and function arguments should be formatted when printed.

# Comments added by Jos I. Boumans <kane@dwim.org> 11-Aug-2004
# I can not get %CarpInternal or %Internal to work as advertised,
# therefor leaving it out of the below documentation.
# $CarpLevel may be decprecated according to the last comment, but
# after 6 years, it's still around and in heavy use ;)

#line 180


$CarpInternal{Carp}++;
$CarpInternal{warnings}++;
$CarpLevel = 0;     # How many extra package levels to skip on carp.
                    # How many calls to skip on confess.
                    # Reconciling these notions is hard, use
                    # %Internal and %CarpInternal instead.
$MaxEvalLen = 0;    # How much eval '...text...' to show. 0 = all.
$MaxArgLen = 64;    # How much of each argument to print. 0 = all.
$MaxArgNums = 8;    # How many arguments to print. 0 = all.
$Verbose = 0;       # If true then make shortmess call longmess instead

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw(confess croak carp);
@EXPORT_OK = qw(cluck verbose longmess shortmess);
@EXPORT_FAIL = qw(verbose);	# hook to enable verbose mode

#line 206

# if the caller specifies verbose usage ("perl -MCarp=verbose script.pl")
# then the following method will be called by the Exporter which knows
# to do this thanks to @EXPORT_FAIL, above.  $_[1] will contain the word
# 'verbose'.

sub export_fail {
    shift;
    $Verbose = shift if $_[0] eq 'verbose';
    return @_;
}


# longmess() crawls all the way up the stack reporting on all the function
# calls made.  The error string, $error, is originally constructed from the
# arguments passed into longmess() via confess(), cluck() or shortmess().
# This gets appended with the stack trace messages which are generated for
# each function call on the stack.

sub longmess {
    {
	local($@, $!);
	# XXX fix require to not clear $@ or $!?
	# don't use require unless we need to (for Safe compartments)
	require Carp::Heavy unless $INC{"Carp/Heavy.pm"};
    }
    # Icky backwards compatibility wrapper. :-(
    my $call_pack = caller();
    if ($Internal{$call_pack} or $CarpInternal{$call_pack}) {
      return longmess_heavy(@_);
    }
    else {
      local $CarpLevel = $CarpLevel + 1;
      return longmess_heavy(@_);
    }
}


# shortmess() is called by carp() and croak() to skip all the way up to
# the top-level caller's package and report the error from there.  confess()
# and cluck() generate a full stack trace so they call longmess() to
# generate that.  In verbose mode shortmess() calls longmess() so
# you always get a stack trace

sub shortmess {	# Short-circuit &longmess if called via multiple packages
    {
	local($@, $!);
	# XXX fix require to not clear $@ or $!?
	# don't use require unless we need to (for Safe compartments)
	require Carp::Heavy unless $INC{"Carp/Heavy.pm"};
    }
    # Icky backwards compatibility wrapper. :-(
    my $call_pack = caller();
    local @CARP_NOT = caller();
    shortmess_heavy(@_);
}


# the following four functions call longmess() or shortmess() depending on
# whether they should generate a full stack trace (confess() and cluck())
# or simply report the caller's package (croak() and carp()), respectively.
# confess() and croak() die, carp() and cluck() warn.

sub croak   { die  shortmess @_ }
sub confess { die  longmess  @_ }
sub carp    { warn shortmess @_ }
sub cluck   { warn longmess  @_ }

1;
