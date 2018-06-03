#line 1 "Bio/SearchIO/chadosxpr.pm"
# $Id: chadosxpr.pm,v 1.2 2002/12/05 13:46:35 heikki Exp $
#
# BioPerl module for Bio::SearchIO::chadosxpr
#
# Chris Mungall <cjm@fruitfly.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 62

# Let the code begin...

package Bio::SearchIO::chadosxpr;
use Bio::SearchIO::chado;
use vars qw(@ISA);
use strict;

use Data::Stag::SxprWriter;

@ISA = qw(Bio::SearchIO::chado);

sub default_handler_class {
    return "Data::Stag::SxprWriter";
} 

1;
