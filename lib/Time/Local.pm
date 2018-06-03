#line 1 "Time/Local.pm"
package Time::Local;

require Exporter;
use Carp;
use Config;
use strict;
use integer;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
$VERSION    = '1.11';
$VERSION    = eval $VERSION;
@ISA	= qw( Exporter );
@EXPORT	= qw( timegm timelocal );
@EXPORT_OK	= qw( timegm_nocheck timelocal_nocheck );

my @MonthDays = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

# Determine breakpoint for rolling century
my $ThisYear     = (localtime())[5];
my $Breakpoint   = ($ThisYear + 50) % 100;
my $NextCentury  = $ThisYear - $ThisYear % 100;
   $NextCentury += 100 if $Breakpoint < 50;
my $Century      = $NextCentury - 100;
my $SecOff       = 0;

my (%Options, %Cheat, %Min, %Max);
my ($MinInt, $MaxInt);

if ($^O eq 'MacOS') {
    # time_t is unsigned...
    $MaxInt = (1 << (8 * $Config{intsize})) - 1;
    $MinInt = 0;
} else {
    $MaxInt = ((1 << (8 * $Config{intsize} - 2))-1)*2 + 1;
    $MinInt = -$MaxInt - 1;

    # On Win32 (and others?) time_t appears to be signed, but negative
    # epochs still don't work. - XXX - this is experimental
    $MinInt = 0
        unless defined ((localtime(-1))[0]);
}

$Max{Day} = ($MaxInt >> 1) / 43200;
$Min{Day} = $MinInt ? -($Max{Day} + 1) : 0;

$Max{Sec} = $MaxInt - 86400 * $Max{Day};
$Min{Sec} = $MinInt - 86400 * $Min{Day};

# Determine the EPOC day for this machine
my $Epoc = 0;
if ($^O eq 'vos') {
# work around posix-977 -- VOS doesn't handle dates in
# the range 1970-1980.
  $Epoc = _daygm((0, 0, 0, 1, 0, 70, 4, 0));
}
elsif ($^O eq 'MacOS') {
  no integer;

  # MacOS time() is seconds since 1 Jan 1904, localtime
  # so we need to calculate an offset to apply later
  $Epoc = 693901;
  $SecOff = timelocal(localtime(0)) - timelocal(gmtime(0));
  $Epoc += _daygm(gmtime(0));
}
else {
  $Epoc = _daygm(gmtime(0));
}

%Cheat=(); # clear the cache as epoc has changed

sub _daygm {
    $_[3] + ($Cheat{pack("ss",@_[4,5])} ||= do {
	my $month = ($_[4] + 10) % 12;
	my $year = $_[5] + 1900 - $month/10;
	365*$year + $year/4 - $year/100 + $year/400 + ($month*306 + 5)/10 - $Epoc
    });
}


sub _timegm {
    my $sec = $SecOff + $_[0]  +  60 * $_[1]  +  3600 * $_[2];

    no integer;

    $sec +  86400 * &_daygm;
}


sub _zoneadjust {
    my ($day, $sec, $time) = @_;

    $sec = $sec + _timegm(localtime($time)) - $time;
    if ($sec >= 86400) { $day++; $sec -= 86400; }
    if ($sec <  0)     { $day--; $sec += 86400; }

    ($day, $sec);
}


sub timegm {
    my ($sec,$min,$hour,$mday,$month,$year) = @_;

    if ($year >= 1000) {
	$year -= 1900;
    }
    elsif ($year < 100 and $year >= 0) {
	$year += ($year > $Breakpoint) ? $Century : $NextCentury;
    }

    unless ($Options{no_range_check}) {
	if (abs($year) >= 0x7fff) {
	    $year += 1900;
	    croak "Cannot handle date ($sec, $min, $hour, $mday, $month, *$year*)";
	}

	croak "Month '$month' out of range 0..11" if $month > 11 or $month < 0;

	my $md = $MonthDays[$month];
#        ++$md if $month == 1 and $year % 4 == 0 and
#            ($year % 100 != 0 or ($year + 1900) % 400 == 0);
	++$md unless $month != 1 or $year % 4 or !($year % 400);

	croak "Day '$mday' out of range 1..$md"   if $mday  > $md  or $mday  < 1;
	croak "Hour '$hour' out of range 0..23"   if $hour  > 23   or $hour  < 0;
	croak "Minute '$min' out of range 0..59"  if $min   > 59   or $min   < 0;
	croak "Second '$sec' out of range 0..59"  if $sec   > 59   or $sec   < 0;
    }

    my $days = _daygm(undef, undef, undef, $mday, $month, $year);
    my $xsec = $sec + $SecOff + 60*$min + 3600*$hour;

    unless ($Options{no_range_check}
        or  ($days > $Min{Day} or $days == $Min{Day} and $xsec >= $Min{Sec})
       and  ($days < $Max{Day} or $days == $Max{Day} and $xsec <= $Max{Sec}))
    {
        warn "Day too small - $days > $Min{Day}\n" if $days < $Min{Day};
        warn "Day too big - $days > $Max{Day}\n" if $days > $Max{Day};
        warn "Sec too small - $days < $Min{Sec}\n" if $days < $Min{Sec};
        warn "Sec too big - $days > $Max{Sec}\n" if $days > $Max{Sec};
	$year += 1900;
	croak "Cannot handle date ($sec, $min, $hour, $mday, $month, $year)";
    }

    no integer;

    $xsec + 86400 * $days;
}


sub timegm_nocheck {
    local $Options{no_range_check} = 1;
    &timegm;
}


sub timelocal {
    # Adjust Max/Min allowed times to fit local time zone and call timegm
    local ($Max{Day}, $Max{Sec}) = _zoneadjust($Max{Day}, $Max{Sec}, $MaxInt);
    local ($Min{Day}, $Min{Sec}) = _zoneadjust($Min{Day}, $Min{Sec}, $MinInt);
    my $ref_t = &timegm;

    # Calculate first guess with a one-day delta to avoid localtime overflow
    my $delta = ($_[5] < 100)? 86400 : -86400;
    my $loc_t = _timegm(localtime( $ref_t + $delta )) - $delta;

    # Is there a timezone offset from GMT or are we done
    my $zone_off = $ref_t - $loc_t
	or return $loc_t;

    # This hack is needed to always pick the first matching time
    # during a DST change when time would otherwise be ambiguous
    $zone_off -= 3600 if ($delta > 0 && $ref_t >= 3600);

    # Adjust for timezone
    $loc_t = $ref_t + $zone_off;

    # Are we close to a DST change or are we done
    my $dst_off = $ref_t - _timegm(localtime($loc_t))
	or return $loc_t;

    # Adjust for DST change
    $loc_t += $dst_off;

    return $loc_t if $dst_off >= 0;

    # for a negative offset from GMT, and if the original date
    # was a non-extent gap in a forward DST jump, we should
    # now have the wrong answer - undo the DST adjust;

    my ($s,$m,$h) = localtime($loc_t);
    $loc_t -= $dst_off if $s != $_[0] || $m != $_[1] || $h != $_[2];

    $loc_t;
}


sub timelocal_nocheck {
    local $Options{no_range_check} = 1;
    &timelocal;
}

1;

__END__

#line 366

