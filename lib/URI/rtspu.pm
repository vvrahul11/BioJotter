#line 1 "URI/rtspu.pm"
package URI::rtspu;

require URI::rtsp;
@ISA=qw(URI::rtsp);

sub default_port { 554 }

1;
