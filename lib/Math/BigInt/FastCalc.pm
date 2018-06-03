#line 1 "Math/BigInt/FastCalc.pm"
package Math::BigInt::FastCalc;

use 5.005;
use strict;
# use warnings;	# dont use warnings for older Perls

use DynaLoader;
use Math::BigInt::Calc;

use vars qw/@ISA $VERSION $BASE $BASE_LEN/;

@ISA = qw(DynaLoader);

$VERSION = '0.10';

bootstrap Math::BigInt::FastCalc $VERSION;

##############################################################################
# global constants, flags and accessory

# announce that we are compatible with MBI v1.70 and up
sub api_version () { 1; }
 
BEGIN
  {
  # use Calc to override the methods that we do not provide in XS

  for my $method (qw/
    new str
    add sub mul div
    rsft lsft
    mod modpow modinv
    gcd
    pow root sqrt log_int fac
    digit check
    from_hex from_bin as_hex as_bin
    zeros base_len
    xor or and
    /)
    {
    no strict 'refs';
    *{'Math::BigInt::FastCalc::_' . $method} = \&{'Math::BigInt::Calc::_' . $method};
    }
  my ($AND_BITS, $XOR_BITS, $OR_BITS, $BASE_LEN_SMALL, $MAX_VAL);
 
  # store BASE_LEN and BASE to later pass it to XS code 
  ($BASE_LEN, $AND_BITS, $XOR_BITS, $OR_BITS, $BASE_LEN_SMALL, $MAX_VAL, $BASE) =
    Math::BigInt::Calc::_base_len();

  }

sub import
  {
  _set_XS_BASE($BASE, $BASE_LEN);
  }

##############################################################################
##############################################################################

1;
__END__

#line 124
