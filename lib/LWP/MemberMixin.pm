#line 1 "LWP/MemberMixin.pm"
package LWP::MemberMixin;

# $Id: MemberMixin.pm,v 1.8 2004/04/09 15:07:04 gisle Exp $

sub _elem
{
    my $self = shift;
    my $elem = shift;
    my $old = $self->{$elem};
    $self->{$elem} = shift if @_;
    return $old;
}

1;

__END__

#line 47