#line 1 "File/Path.pm"
package File::Path;

#line 104

use 5.006;
use Carp;
use File::Basename ();
use Exporter ();
use strict;
use warnings;
use Cwd 'getcwd';

our $VERSION = "1.08";  # but modified for ActivePerl
our @ISA = qw( Exporter );
our @EXPORT = qw( mkpath rmtree );

my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

# These OSes complain if you want to remove a file that you have no
# write permission to:
my $force_writeable = ($^O eq 'os2' || $^O eq 'dos' || $^O eq 'MSWin32' ||
		       $^O eq 'amigaos' || $^O eq 'MacOS' || $^O eq 'epoc');

sub mkpath {
    my($paths, $verbose, $mode) = @_;
    # $paths   -- either a path string or ref to list of paths
    # $verbose -- optional print "mkdir $path" for each directory created
    # $mode    -- optional permissions, defaults to 0777
    local($")=$Is_MacOS ? ":" : "/";
    $mode = 0777 unless defined($mode);
    $paths = [$paths] unless ref $paths;
    my(@created,$path);
    foreach $path (@$paths) {
	$path .= '/' if $^O eq 'os2' and $path =~ /^\w:\z/s; # feature of CRT 
	# Logic wants Unix paths, so go with the flow.
	if ($Is_VMS) {
	    next if $path eq '/';
	    $path = VMS::Filespec::unixify($path);
	    if ($path =~ m:^(/[^/]+)/?\z:) {
	        $path = $1.'/000000';
	    }
	}
	next if -d $path;
	my $parent = File::Basename::dirname($path);
	unless (-d $parent or $path eq $parent) {
	    push(@created,mkpath($parent, $verbose, $mode));
 	}
	print "mkdir $path\n" if $verbose;
	unless (mkdir($path,$mode)) {
	    my $e = $!;
	    # allow for another process to have created it meanwhile
	    $! = $e, croak ("mkdir $path: $e") unless -d $path;
	}
	push(@created, $path);
    }
    @created;
}

sub _rmtree
{
    my ($path, $prefix, $up, $up_dev, $up_ino, $verbose, $safe) = @_;

    my ($dev, $ino, $perm) = lstat $path or do {
	return 0;
    };
    $perm &= 07777;

    unless (-d _)
    {
	my $nperm;
	if ($force_writeable) {
	    # make the file writable
	    $nperm = $perm | 0600;
	    unless ($safe or $nperm == $perm or chmod $nperm, $path) {
		carp "Can't make file $prefix$path writeable: $!";
	    }
	}
	print "unlink $prefix$path\n" if $verbose;
	unless (unlink $path)
	{
	    carp "Can't remove file $prefix$path ($!)";
	    if ($force_writeable) {
		unless ($safe or $nperm == $perm or chmod $perm, $path) {
		    carp("and can't restore permissions to "
			 . sprintf("0%o",$perm) . "\n");
		}
	    }
	    return 0;
	}
	return 1;
    }

    CHDIR: {
	last CHDIR if chdir $path;
	my $err = $!;
	unless ($safe || ($perm & 0100)) { 
	    # might be able to succeed by tweaking the permission
	    # before we chdir
	    last CHDIR if chmod(0700, $path) && chdir($path);
	}
	carp "Can't chdir to $prefix$path ($err)";
	return 0;
    }

    # avoid a race condition where a directory may be replaced by a
    # symlink between the initial lstat and the chdir
    my ($new_dev, $new_ino) = stat '.';
    unless ("$new_dev:$new_ino" eq "$dev:$ino")
    {
	croak "Directory $prefix$path changed before chdir, aborting";
    }

    my $nperm = $perm | 0700;
    unless ($safe or $nperm == $perm or chmod $nperm, '.')
    {
	carp "Can't make directory $prefix$path read+writeable ($!)";
	$nperm = $perm;
    }

    my $count = 0;
    if (opendir my $dir, '.')
    {
	my $entry;
	while (defined ($entry = readdir $dir))
	{
	    next if $entry =~ /^\.\.?$/;
	    $entry =~ /^(.*)$/s; $entry = $1; # untaint
	    $count += _rmtree($entry, "$prefix$path/", '..', $dev, $ino,
		$verbose, $safe);
	}

	closedir $dir;
    }

    # restore directory permissions is required (in case the rmdir
    # below fails) now, while we're still in the directory and may do
    # so without a race via '.'
    unless ($force_writeable or $safe or $nperm == $perm or chmod $perm, '.')
    {
	carp "Can't restore permissions on directory $prefix$path ($!)";
    }

    # don't leave the caller in an unexpected directory
    unless (chdir $up)
    {
	croak "Can't return to $up from $prefix$path ($!)";
    }

    # ensure that a chdir ..  didn't take us somewhere other than
    # where we expected (see CVE-2002-0435)
    unless (($new_dev, $new_ino) = stat '.'
	and "$new_dev:$new_ino" eq "$up_dev:$up_ino")
    {
	croak "Previous directory $up changed since entering $prefix$path";
    }

    print "rmdir $prefix$path\n" if $verbose;
    if (rmdir $path)
    {
	$count++;
    }
    else
    {
	carp "Can't remove directory $prefix$path ($!)";
    }

    return $count;
}

sub rmtree
{
    my ($p, $verbose, $safe) = @_;
    $p = [] unless defined $p and length $p;
    $p = [ $p ] unless ref $p;
    my @paths = grep defined && length, @$p;

    # default to "unsafe" for non-root (will chmod dirs)
    $safe = ($> || $force_writeable) ? 0 : 1 unless defined $safe;

    unless (@paths)
    {
	carp "No root path(s) specified";
	return 0;
    }

    my $oldpwd = getcwd or do {
	carp "Can't fetch initial working directory";
	return 0;
    };

    my ($dev, $ino) = stat '.' or do {
	carp "Can't stat initial working directory";
	return 0;
    };

    # untaint
    for ($oldpwd) { /^(.*)$/s; $_ = $1 }

    my $count = 0;
    for my $path (@paths)
    {
	$count += _rmtree($path, '', $oldpwd, $dev, $ino, $verbose, $safe);
    }

    $count;
}

1;
