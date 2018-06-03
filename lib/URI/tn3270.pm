#line 1 "URI/tn3270.pm"
package URI::tn3270;
require URI::_login;
@ISA = qw(URI::_login);

sub default_port { 23 }

1;
