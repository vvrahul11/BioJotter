#line 1 "MIME/Base64.pm"
package MIME::Base64;

# $Id: Base64.pm,v 3.11 2005/11/29 20:59:55 gisle Exp $

use strict;
use vars qw(@ISA @EXPORT $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encode_base64 decode_base64);

$VERSION = '3.07';

require XSLoader;
XSLoader::load('MIME::Base64', $VERSION);

*encode = \&encode_base64;
*decode = \&decode_base64;

1;

__END__

#line 178
