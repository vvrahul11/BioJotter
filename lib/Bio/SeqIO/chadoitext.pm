#line 1 "Bio/SeqIO/chadoitext.pm"
# $Id: chadoitext.pm,v 1.2 2002/12/05 13:46:36 heikki Exp $
#
# BioPerl module for Bio::SeqIO::chadoitext
#
# Chris Mungall <cjm@fruitfly.org>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 62

# Let the code begin...

package Bio::SeqIO::chadoitext;
use Bio::SeqIO::chado;
use vars qw(@ISA);
use strict;

use Data::Stag::ITextWriter;

@ISA = qw(Bio::SeqIO::chado);

sub default_handler_class {
    return "Data::Stag::ITextWriter";
} 

1;
