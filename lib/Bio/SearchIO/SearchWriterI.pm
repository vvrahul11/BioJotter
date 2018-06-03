#line 1 "Bio/SearchIO/SearchWriterI.pm"
#-----------------------------------------------------------------
# $Id: SearchWriterI.pm,v 1.7 2002/12/01 00:05:01 jason Exp $
#
# BioPerl module Bio::SearchIO::SearchWriterI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

#line 44

package Bio::SearchIO::SearchWriterI;

use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 65

sub to_string {
    my ($self, $result, @args) = @_;
    $self->throw_not_implemented;
}

#line 84

sub end_report { 
    my $self = shift;
    return '';
}

#line 101

# yes this is an implementation in the interface, 
# yes it assumes that the underlying class is hash-based
# yes that might not be a good idea, but until people
# start extending the SearchWriterI interface I think
# this is an okay way to go

sub filter {
    my ($self,$method,$code) = @_;    
    return undef unless $method;
    $method = uc($method);
    if( $method ne 'HSP' &&
	$method ne 'HIT' &&
	$method ne 'RESULT' ) {
	$self->warn("Unknown method $method");
	return undef;
    }
    if( $code )  {
	$self->throw("Must provide a valid code reference") unless ref($code) =~ /CODE/;
	$self->{$method} = $code;
    }
    return $self->{$method};
}

1;


