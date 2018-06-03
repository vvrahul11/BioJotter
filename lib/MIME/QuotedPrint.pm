#line 1 "MIME/QuotedPrint.pm"
package MIME::QuotedPrint;

# $Id: QuotedPrint.pm,v 3.7 2005/11/29 20:49:46 gisle Exp $

use strict;
use vars qw(@ISA @EXPORT $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encode_qp decode_qp);

$VERSION = "3.07";

use MIME::Base64;  # will load XS version of {en,de}code_qp()

*encode = \&encode_qp;
*decode = \&decode_qp;

1;

__END__

#line 117
