#line 1 "ActivePerl/Config.pm"
package ActivePerl::Config;

use strict;
my %OVERRIDE;
my %COMPILER_ENV = map { $_ => 1 } qw(
    cc
    ccflags
    cccdlflags
    ccname
    ccversion
    gccversion
    ar
    cpp
    cppminus
    cpprun
    cppstdin
    ld
    lddlflags
    ldflags
    lib_ext
    libc
    libs
    optimize
    perllibs
    _a
    _o
    obj_ext
    i64type
    u64type
    quadtype
    uquadtype
    d_casti32
);
my $compiler_env_initialized;

# Make sure none of the modules used here uses
#
#        use base 'Exporter';
#
# because broken versions of Module::Install (0.60 and earlier)
# hide base.pm on case-insensitive filesystems behind Base.pm.

use ActiveState::Path qw(find_prog realpath);

use Config ();
my $CONFIG_OBJ = tied %Config::Config;

sub override {
    return 0 if $ENV{ACTIVEPERL_CONFIG_DISABLE};

    my $key = shift;

    if (exists $ENV{"ACTIVEPERL_CONFIG_\U$key"}) {
	$_[0] = $ENV{"ACTIVEPERL_CONFIG_\U$key"};
	return 1;
    }

    if (exists $OVERRIDE{$key}) {
	$_[0] = $OVERRIDE{$key};
	return 1;
    }

    if ($key eq "make" && $^O eq "MSWin32") {
	for (qw(nmake dmake)) {
	    if (find_prog($_)) {
		$_[0] = $OVERRIDE{$key} = $_;
		return 1;
	    }
	}
	return 0;
    }
    if ($key eq "make" && ($^O eq "solaris" || $^O eq "hpux")) {
	if (!find_prog(_orig_conf("make")) && -x "/usr/ccs/bin/make") {
	    $_[0] = $OVERRIDE{$key} = "/usr/ccs/bin/make";
	    return 1;
	}
    }

    if ($COMPILER_ENV{$key} && !$compiler_env_initialized++) {
	if ($^O eq "MSWin32" && !find_prog(_orig_conf("cc"))) {
	    if (find_prog("gcc")) {
		# assume MinGW or similar is available
		_override("cc", "gcc");
		_override("ccname", "gcc");
		my($gccversion) = qx(gcc --version);
		$gccversion =~ s/^gcc(\.exe)? \(GCC\) //;
		chomp($gccversion);
		warn "Set up gcc environment - $gccversion\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
		_override("gccversion", $gccversion);
		_override("ccversion", "");

		foreach my $key (qw(libs perllibs)) {
		    # Old: "  foo.lib oldnames.lib bar.lib"
		    # New: "-lfoo -lbar"
		    my @libs = split / +/, _orig_conf($key);
		    # Filter out empty prefix and oldnames.lib
		    @libs = grep {$_ && $_ ne "oldnames.lib"} @libs;
		    # Remove '.lib' extension and add '-l' prefix
		    s/(.*)\.lib$/-l$1/ for @libs;
		    _override($key, join(' ', @libs));
		}

		# Copy all symbol definitions from the CCFLAGS
		my @ccflags = grep /^-D/, split / +/, _orig_conf("ccflags");
		# Add GCC specific flags
		push(@ccflags, qw(-DHASATTRIBUTE -fno-strict-aliasing));
		_override("ccflags", join(" ", @ccflags));

		# more overrides assuming MinGW
		_override("cpp",       "gcc -E");
		_override("cpprun",    "gcc -E");
		_override("cppminus",  "-");
		_override("ar",        "ar");
		_override("ld",        "g++");
		_override("_a",        ".a");
		_override("_o",        ".o");
		_override("obj_ext",   ".o");
		_override("lib_ext",   ".a");
		_override("optimize",  "-O2");
		_override("i64type",   "long long");
		_override("u64type",   "unsigned long long");
		_override("quadtype",  "long long");
		_override("uquadtype", "unsigned long long");
		_override("d_casti32", "define");

		# Extract all library paths from lddlflags
		my @libpaths = map "-L$_", map /^-libpath:(.+)/,
		    _orig_conf("lddlflags") =~ /(?=\S)(?>[^"\s]+|"[^"]*")+/g;
		_override("lddlflags", join(" ", "-mdll", @libpaths));
	    }
	}
	elsif ($^O eq 'darwin') {
	    my($gccversion) = qx(gcc --version);
	    $gccversion =~ s/^gcc \(GCC\) //;
	    chomp($gccversion);
	    _override("gccversion", $gccversion);

	    my %flags = map { ($_ => _orig_conf($_)) } qw(ccflags ldflags lddlflags);

	    # gcc < 4 doesn't support -Wdeclaration-after-statement
	    $flags{ccflags} =~ s/-Wdeclaration-after-statement\s*//g
		if $gccversion =~ /^3\./;

	    # Try and find the SDK we built against
	    my $sdk;
	    my $sdkv;
	    if ($flags{ccflags} =~ m[(/Developer/SDKs/(MacOSX10\.[0-9a-z]+)\.sdk)]i) {
		$sdk = $1;
		$sdkv = $2;
	    }

	    # If the SDK is missing, we can't produce FAT binaries, so we have
	    # to fallback to regular native binaries
	    if ($sdk && !-d $sdk) {
		warn "Set up build environment without $sdkv SDK (will build native binaries)\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
		my $sdk_re = qr/$sdk|-nostdinc|-no-cpp-precomp|-mmacosx-version-min/;

		foreach my $flag (keys %flags) {
		    $flags{$flag} =~ s/-arch\s+(ppc|i386)\s*//g;
		    $flags{$flag} = join ' ', grep { !/$sdk_re/ } split /\s+/, $flags{$flag};
		}
	    }

	    _override($_, $flags{$_}) for keys %flags;
	}
	elsif (($^O eq "solaris" || $^O eq "hpux") && !_orig_conf("gccversion")) {
	    my $cc = find_prog(_orig_conf("cc"));
	    if ($cc && $^O eq "hpux" && _is_bundled_hpux_compiler($cc)) {
		undef($cc);
	    }
	    if (!$cc && find_prog("gcc")) {
		_override("cc", "gcc");
		my($gccversion) = qx(gcc --version);
		$gccversion =~ s/^gcc(\.exe)? \(GCC\) //;
		chomp($gccversion);
		warn "Set up gcc environment - $gccversion\n"
		    unless $ENV{ACTIVEPERL_CONFIG_SILENT};
		_override("gccversion", $gccversion);
		_override("ccversion", "");

		my $opt_mlp64 = "";
		$opt_mlp64 = "-mlp64 " if _orig_conf("archname") =~ /IA64/;

		for (qw(ccflags cppflags)) {
	            my $v = _orig_conf($_);
		    if ($^O eq "hpux") {
		        $v =~ s/(?:-Ae|-Wl,\+\w+)(?:\s+|$)//g;
			$v =~ s/\+Z/-fPIC/;
			$v =~ s/\+DD64\s*/$opt_mlp64/;
		    }
		    $v .= " -fno-strict-aliasing -pipe"; 
		    _override($_, $v);
		}
		my $cccdlflags = _orig_conf("cccdlflags");
		if (($^O eq "solaris" && $cccdlflags =~ s/-KPIC/-fPIC/) ||
		    ($^O eq "hpux" && $cccdlflags =~ s/\+Z/-fPIC/)
		   )
		{
		    _override("cccdlflags", $cccdlflags);
		}

		_override("ld", "gcc");
		_override("ccname", "gcc");
		_override("cpprun", "gcc -E");
		_override("cppstdin", "gcc -E");

		if ($^O eq "hpux") {
		    _override("optimize", "");
		    my $lddlflags = _orig_conf("lddlflags");
		    $lddlflags =~ s/\+vnocompatwarnings(?:\s+|$)//;
		    $lddlflags =~ s/-b(\s+|$)/-shared -static-libgcc -fPIC$1/;
		    $lddlflags =~ s,(-L/usr/lib/hpux64),$opt_mlp64$1,;
		    _override("lddlflags", $lddlflags);

		    my $ldflags = _orig_conf("ldflags");
		    if ($ldflags =~ s/\+DD64\s*/$opt_mlp64/ ||
			($opt_mlp64 && $ldflags =~ s,(-L/usr/lib/hpux64),$opt_mlp64$1,))
		    {
			_override("ldflags", $ldflags);
		    }
		}
	    }
	}

	if (exists $OVERRIDE{$key}) {
	    $_[0] = $OVERRIDE{$key};
	    return 1;
	}
    }

    return 0;
}

sub _orig_conf {
    $CONFIG_OBJ->_fetch_string($_[0]);
}

sub _override {
    my($key, $val) = @_;
    $OVERRIDE{$key} = $val unless exists $OVERRIDE{$key};
}


sub _is_bundled_hpux_compiler {
    my $cc = shift;
    $cc = realpath($cc);
    return $cc =~ /\bcc_bundled$/;
}

1;

__END__

#line 375