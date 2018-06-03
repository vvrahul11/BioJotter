#line 1 "ActivePerl.pm"
package ActivePerl;

sub perl_version {
    return sprintf("%vd.%s", $^V, BUILD());
}

1;

__END__

#line 122
