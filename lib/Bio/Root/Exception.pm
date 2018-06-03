#line 1 "Bio/Root/Exception.pm"
#-----------------------------------------------------------------
# $Id: Exception.pm,v 1.14 2002/06/29 00:42:17 sac Exp $
#
# BioPerl module Bio::Root::Exception
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

#line 185

# Define some generic exceptions.'

package Bio::Root::Exception;

use strict;

my $debug = $Error::Debug;  # Prevents the "used only once" warning.
my $DEFAULT_VALUE = "__DUMMY__";  # Permits eval{} based handlers to work

#line 203

#---------------------------------------------------------
@Bio::Root::Exception::ISA = qw( Error );
#---------------------------------------------------------

#line 238

sub new {
    my ($class, @args) = @_; 
    my ($value, %params);
    if( @args % 2 == 0 && $args[0] =~ /^-/) {
        %params = @args;
        $value = $params{'-value'};
    }
    else {
        $params{-text} = $args[0];
        $value = $args[1];
    }

    if( defined $value and not $value) {
	$value = "The number zero (0)" if $value == 0;
	$value = "An empty string (\"\")" if $value eq "";
    }
    else {
	$value ||= $DEFAULT_VALUE;
    }
    $params{-value} = $value;

    my $self = $class->SUPER::new( %params );
    return $self;
}

#line 274

sub pretty_format {
    my $self = shift;
    my $msg = $self->text;
    my $stack = '';
    if( $Error::Debug ) {
      $stack = $self->_reformat_stacktrace();
    }
    my $value_string = $self->value ne $DEFAULT_VALUE ? "VALUE: ".$self->value."\n" : "";
    my $class = ref($self);

    my $title = "------------- EXCEPTION: $class -------------";
    my $footer = "\n" . '-' x CORE::length($title);
    my $out = "\n$title\n" .
       "MSG: $msg\n". $value_string. $stack. $footer . "\n";
    return $out;
}


# Reformatting of the stack performed by  _reformat_stacktrace:
#   1. Shift the file:line data in line i to line i+1.
#   2. change xxx::__ANON__() to "try{} block"
#   3. skip the "require" and "Error::subs::try" stack entries (boring)
# This means that the first line in the stack won't have any file:line data
# But this isn't a big issue since it's for a Bio::Root::-based method 
# that doesn't vary from exception to exception.

sub _reformat_stacktrace {
    my $self = shift;
    my $msg = $self->text;
    my $stack = $self->stacktrace();
    $stack =~ s/\Q$msg//;
    my @stack = split( /\n/, $stack);
    my @new_stack = ();
    my ($method, $file, $linenum, $prev_file, $prev_linenum);
    my $stack_count = 0;
    foreach my $i( 0..$#stack ) {
        # print "STACK-ORIG: $stack[$i]\n";
        if( ($stack[$i] =~ /^\s*([^(]+)\s*\(.*\) called at (\S+) line (\d+)/) ||
             ($stack[$i] =~ /^\s*(require 0) called at (\S+) line (\d+)/)) {
            ($method, $file, $linenum) = ($1, $2, $3);
            $stack_count++;
        }
        else{
            next;
        }
        if( $stack_count == 1 ) {
            push @new_stack, "STACK: $method";
            ($prev_file, $prev_linenum) = ($file, $linenum);
            next;
        }

        if( $method =~ /__ANON__/ ) {
            $method = "try{} block";
        }
        if( ($method =~ /^require/ and $file =~ /Error\.pm/ ) ||
            ($method =~ /^Error::subs::try/ ) )   {
            last;
        }
        push @new_stack, "STACK: $method $prev_file:$prev_linenum";
        ($prev_file, $prev_linenum) = ($file, $linenum);
    }
    push @new_stack, "STACK: $prev_file:$prev_linenum";

    return join "\n", @new_stack;
}

#line 354

sub stringify {
    my ($self, @args) = @_;
    return $self->pretty_format( @args );
}



#line 375

#---------------------------------------------------------
@Bio::Root::NotImplemented::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------

#line 388

#---------------------------------------------------------
@Bio::Root::IOException::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------


#line 402

#---------------------------------------------------------
@Bio::Root::FileOpenException::ISA = qw( Bio::Root::IOException );
#---------------------------------------------------------


#line 416

#---------------------------------------------------------
@Bio::Root::SystemException::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------


#line 431

#---------------------------------------------------------
@Bio::Root::BadParameter::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------


#line 446

#---------------------------------------------------------
@Bio::Root::OutOfRange::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------


#line 461

#---------------------------------------------------------
@Bio::Root::NoSuchThing::ISA = qw( Bio::Root::Exception );
#---------------------------------------------------------


1;

