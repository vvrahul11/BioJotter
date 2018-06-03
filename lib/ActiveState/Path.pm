#line 1 "ActiveState/Path.pm"
package ActiveState::Path;

use strict;

our $VERSION = '0.02';

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(path_list find_prog is_abs_path abs_path join_path rel_path unsymlinked realpath);

use constant IS_WIN32 => $^O eq "MSWin32";
use File::Basename qw(dirname basename);
use Cwd ();
use Carp ();

my $ABS_PATH_RE = IS_WIN32 ? qr,^(?:[a-zA-Z]:)?[\\/], : qr,^/,;
my $PATH_SEP_RE = IS_WIN32 ? qr,[\\/], : qr,/,;
my $PATH_SEP    = IS_WIN32 ? "\\" : "/";

sub path_list {
    require Config;
    my @list = split /\Q$Config::Config{path_sep}/o, $ENV{PATH}, -1;
    if (IS_WIN32) {
        s/"//g for @list;
        @list = grep length, @list;
        unshift(@list, ".");
    }
    else {
        for (@list) {
            $_ = "." unless length;
        }
    }
    return @list;
}

sub find_prog {
    my $name = shift;
    return _find_prog($name) if $name =~ $PATH_SEP_RE;

    # try to locate it in the PATH
    for my $dir (path_list()) {
        if (defined(my $file = _find_prog(_join_path($dir, $name)))) {
	    return $file;
	}
    }
    return undef;
}

sub _find_prog {
    my $file = shift;
    return $file if -x $file && -f _;
    if (IS_WIN32) {
	for my $ext (qw(bat exe com cmd)) {
	    return "$file.$ext" if -f "$file.$ext";
	}
    }
    return undef;
}

sub is_abs_path {
    my $path = shift;
    return $path =~ $ABS_PATH_RE;
}

sub abs_path {
    my $path = shift;
    return ($path =~ $ABS_PATH_RE) ? $path : _join_path(_cwd(), $path)
}

sub _cwd {
    if (IS_WIN32) {
        my $cwd = Cwd::cwd();
	$cwd =~ s,/,\\,g;
	return $cwd;
    }
    else {
	return Cwd::cwd();
    }
}

sub join_path {
    my($base, $path) = @_;
    return ($path =~ $ABS_PATH_RE) ? $path : _join_path($base, $path);
}

sub _join_path {
    my($base, $path) = @_; # $path assumed to be relative
    while ($path =~ s,^(\.\.?)$PATH_SEP_RE?,,o) {
	$base = dirname(unsymlinked($base)) if $1 eq "..";
    }
    if (length($path)) {
	return $path if $base eq ".";
	$base .= $PATH_SEP if $base !~ m,$PATH_SEP_RE\z,o;
    }
    $base .= $path;
    return $base;
}

sub rel_path {
    my($base, $path, $depth) = @_;

    # try the short way out
    $base .= $PATH_SEP if $base !~ m,$PATH_SEP_RE\z,o;
    if (substr($path, 0, length($base)) eq $base) {
	$path = substr($path, length($base));
	$path = "." unless length($path);
	return $path;
    }

    # the hard way
    $_ = abs_path($_) for $base, $path;

    my @base = split($PATH_SEP_RE, $base);
    my @path = split($PATH_SEP_RE, $path, -1);

    while (@base && @path && $base[0] eq $path[0]) {
        shift(@base);
        shift(@path);
    }

    my $up = @base;

    if (!IS_WIN32) {
	$base =~ s,$PATH_SEP_RE\z,,o;  # otherwise the -l test might fail
	my @base_rest;
	while (@base) {
	    if (-l $base) {
		my $rel_path = eval {
		    $base = _unsymlinked($base);
		    $depth ||= 0;
		    Carp::croak("rel_path depth limit exceeded") if $depth > 10;
		    return rel_path(_join_path($base, join($PATH_SEP, @base_rest)), $path, $depth + 1);
		};
		return $@ ? $path : $rel_path;
	    }
	    unshift(@base_rest, pop(@base));
	    $base = dirname($base);
	}
    }

    unshift(@path, ".") if !$up && (!@path || (@path == 1 && $path[0] eq ""));
    $path = join($PATH_SEP, ("..") x $up, @path);
    return $path;
}

sub unsymlinked {
    my $path = shift;
    $path = _unsymlinked($path) if !IS_WIN32 && -l $path;
    return $path;
}

sub realpath {
    my $path = shift;
    if (IS_WIN32) {
        Carp::croak("The path '$path' is not valid\n") unless -e $path;
        return scalar(Win32::GetFullPathName($path));
    }

    lstat($path);  # prime tests on '_'

    Carp::croak("The path '$path' is not valid\n") unless -e _;
    return Cwd::realpath($path) if -d _;

    $path = _unsymlinked($path) if -l _;
    return _join_path(Cwd::realpath(dirname($path)), basename($path));
}

sub _unsymlinked {
    my $path = shift;  # assumed to be a link
    my $orig_path = $path;
    my %seen;
    my $count;
    while (1) {
	Carp::croak("symlink cycle for $orig_path") if $seen{$path}++;
	Carp::croak("symlink resolve limit exceeded") if ++$count > 10;
	my $link = readlink($path);
	die "readlink failed: $!" unless defined $link;
	$path = join_path(dirname($path), $link);
	last unless -l $path;
    }
    return $path;
}

1;

__END__

#line 302
