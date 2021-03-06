#line 1 "Bio/SeqIO/chadoxml.pm"
# $Id: chadoxml.pm,v 1.2 2002/12/05 13:46:36 heikki Exp $
#
# BioPerl module for Bio::SeqIO::chadoxml
#
# Chris Mungall <cjm@fruitfly.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 63

# Let the code begin...

package Bio::SeqIO::chadoxml;
use Bio::SeqIO::chado;
use vars qw(@ISA);
use strict;

use Data::Stag::XMLWriter;

@ISA = qw(Bio::SeqIO::chado);

sub default_handler_class {
    return "Data::Stag::XMLWriter";
} 

1;
