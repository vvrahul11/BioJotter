#line 1 "Math/Trig.pm"
#
# Trigonometric functions, mostly inherited from Math::Complex.
# -- Jarkko Hietaniemi, since April 1997
# -- Raphael Manfredi, September 1996 (indirectly: because of Math::Complex)
#

require Exporter;
package Math::Trig;

use 5.006;
use strict;

use Math::Complex 1.35;
use Math::Complex qw(:trig);

our($VERSION, $PACKAGE, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);

$VERSION = 1.03;

my @angcnv = qw(rad2deg rad2grad
		deg2rad deg2grad
		grad2rad grad2deg);

@EXPORT = (@{$Math::Complex::EXPORT_TAGS{'trig'}},
	   @angcnv);

my @rdlcnv = qw(cartesian_to_cylindrical
		cartesian_to_spherical
		cylindrical_to_cartesian
		cylindrical_to_spherical
		spherical_to_cartesian
		spherical_to_cylindrical);

my @greatcircle = qw(
		     great_circle_distance
		     great_circle_direction
		     great_circle_bearing
		     great_circle_waypoint
		     great_circle_midpoint
		     great_circle_destination
		    );

my @pi = qw(pi2 pip2 pip4);

@EXPORT_OK = (@rdlcnv, @greatcircle, @pi);

# See e.g. the following pages:
# http://www.movable-type.co.uk/scripts/LatLong.html
# http://williams.best.vwh.net/avform.htm

%EXPORT_TAGS = ('radial' => [ @rdlcnv ],
	        'great_circle' => [ @greatcircle ],
	        'pi'     => [ @pi ]);

sub pi2  () { 2 * pi }
sub pip2 () { pi / 2 }
sub pip4 () { pi / 4 }

sub DR  () { pi2/360 }
sub RD  () { 360/pi2 }
sub DG  () { 400/360 }
sub GD  () { 360/400 }
sub RG  () { 400/pi2 }
sub GR  () { pi2/400 }

#
# Truncating remainder.
#

sub remt ($$) {
    # Oh yes, POSIX::fmod() would be faster. Possibly. If it is available.
    $_[0] - $_[1] * int($_[0] / $_[1]);
}

#
# Angle conversions.
#

sub rad2rad($)     { remt($_[0], pi2) }

sub deg2deg($)     { remt($_[0], 360) }

sub grad2grad($)   { remt($_[0], 400) }

sub rad2deg ($;$)  { my $d = RD * $_[0]; $_[1] ? $d : deg2deg($d) }

sub deg2rad ($;$)  { my $d = DR * $_[0]; $_[1] ? $d : rad2rad($d) }

sub grad2deg ($;$) { my $d = GD * $_[0]; $_[1] ? $d : deg2deg($d) }

sub deg2grad ($;$) { my $d = DG * $_[0]; $_[1] ? $d : grad2grad($d) }

sub rad2grad ($;$) { my $d = RG * $_[0]; $_[1] ? $d : grad2grad($d) }

sub grad2rad ($;$) { my $d = GR * $_[0]; $_[1] ? $d : rad2rad($d) }

sub cartesian_to_spherical {
    my ( $x, $y, $z ) = @_;

    my $rho = sqrt( $x * $x + $y * $y + $z * $z );

    return ( $rho,
             atan2( $y, $x ),
             $rho ? acos( $z / $rho ) : 0 );
}

sub spherical_to_cartesian {
    my ( $rho, $theta, $phi ) = @_;

    return ( $rho * cos( $theta ) * sin( $phi ),
             $rho * sin( $theta ) * sin( $phi ),
             $rho * cos( $phi   ) );
}

sub spherical_to_cylindrical {
    my ( $x, $y, $z ) = spherical_to_cartesian( @_ );

    return ( sqrt( $x * $x + $y * $y ), $_[1], $z );
}

sub cartesian_to_cylindrical {
    my ( $x, $y, $z ) = @_;

    return ( sqrt( $x * $x + $y * $y ), atan2( $y, $x ), $z );
}

sub cylindrical_to_cartesian {
    my ( $rho, $theta, $z ) = @_;

    return ( $rho * cos( $theta ), $rho * sin( $theta ), $z );
}

sub cylindrical_to_spherical {
    return ( cartesian_to_spherical( cylindrical_to_cartesian( @_ ) ) );
}

sub great_circle_distance {
    my ( $theta0, $phi0, $theta1, $phi1, $rho ) = @_;

    $rho = 1 unless defined $rho; # Default to the unit sphere.

    my $lat0 = pip2 - $phi0;
    my $lat1 = pip2 - $phi1;

    return $rho *
        acos(cos( $lat0 ) * cos( $lat1 ) * cos( $theta0 - $theta1 ) +
             sin( $lat0 ) * sin( $lat1 ) );
}

sub great_circle_direction {
    my ( $theta0, $phi0, $theta1, $phi1 ) = @_;

    my $distance = &great_circle_distance;

    my $lat0 = pip2 - $phi0;
    my $lat1 = pip2 - $phi1;

    my $direction =
	acos((sin($lat1) - sin($lat0) * cos($distance)) /
	     (cos($lat0) * sin($distance)));

    $direction = pi2 - $direction
	if sin($theta1 - $theta0) < 0;

    return rad2rad($direction);
}

*great_circle_bearing = \&great_circle_direction;

sub great_circle_waypoint {
    my ( $theta0, $phi0, $theta1, $phi1, $point ) = @_;

    $point = 0.5 unless defined $point;

    my $d = great_circle_distance( $theta0, $phi0, $theta1, $phi1 );

    return undef if $d == pi;

    my $sd = sin($d);

    return ($theta0, $phi0) if $sd == 0;

    my $A = sin((1 - $point) * $d) / $sd;
    my $B = sin(     $point  * $d) / $sd;

    my $lat0 = pip2 - $phi0;
    my $lat1 = pip2 - $phi1;

    my $x = $A * cos($lat0) * cos($theta0) + $B * cos($lat1) * cos($theta1);
    my $y = $A * cos($lat0) * sin($theta0) + $B * cos($lat1) * sin($theta1);
    my $z = $A * sin($lat0)                + $B * sin($lat1);

    my $theta = atan2($y, $x);
    my $phi   = atan2($z, sqrt($x*$x + $y*$y));
    
    return ($theta, $phi);
}

sub great_circle_midpoint {
    great_circle_waypoint(@_[0..3], 0.5);
}

sub great_circle_destination {
    my ( $theta0, $phi0, $dir0, $dst ) = @_;

    my $lat0 = pip2 - $phi0;

    my $phi1   = asin(sin($lat0)*cos($dst)+cos($lat0)*sin($dst)*cos($dir0));
    my $theta1 = $theta0 + atan2(sin($dir0)*sin($dst)*cos($lat0),
				 cos($dst)-sin($lat0)*sin($phi1));

    my $dir1 = great_circle_bearing($theta1, $phi1, $theta0, $phi0) + pi;

    $dir1 -= pi2 if $dir1 > pi2;

    return ($theta1, $phi1, $dir1);
}

1;

__END__
#line 621

# eof
