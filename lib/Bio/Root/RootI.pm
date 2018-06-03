#line 1 "Bio/Root/RootI.pm"
# $Id: RootI.pm,v 1.61 2002/12/16 09:44:28 birney Exp $
#
# BioPerl module for Bio::Root::RootI
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code
# 
# This was refactored to have chained calls to new instead
# of chained calls to _initialize
#
# added debug and deprecated methods --Jason Stajich 2001-10-12
# 

#line 99

# Let the code begin...

package Bio::Root::RootI;

use vars qw($DEBUG $ID $Revision $VERSION $VERBOSITY);
use strict;
use Carp 'confess','carp';

BEGIN { 
    $ID        = 'Bio::Root::RootI';
    $VERSION   = 1.0;
    $Revision  = '$Id: RootI.pm,v 1.61 2002/12/16 09:44:28 birney Exp $ ';
    $DEBUG     = 0;
    $VERBOSITY = 0;
}

sub new {
  my $class = shift;
  my @args = @_;
  unless ( $ENV{'BIOPERLDEBUG'} ) {
      carp("Use of new in Bio::Root::RootI is deprecated.  Please use Bio::Root::Root instead");
  }
  eval "require Bio::Root::Root";
  return Bio::Root::Root->new(@args);
}

# for backwards compatibility
sub _initialize {
    my($self,@args) = @_;
    return 1;
}


#line 144

sub throw{
   my ($self,$string) = @_;

   my $std = $self->stack_trace_dump();

   my $out = "\n-------------------- EXCEPTION --------------------\n".
       "MSG: ".$string."\n".$std."-------------------------------------------\n";
   die $out;

}

#line 171

sub warn{
    my ($self,$string) = @_;
    
    my $verbose;
    if( $self->can('verbose') ) {
	$verbose = $self->verbose;
    } else {
	$verbose = 0;
    }

    if( $verbose == 2 ) {
	$self->throw($string);
    } elsif( $verbose == -1 ) {
	return;
    } elsif( $verbose == 1 ) {
	my $out = "\n-------------------- WARNING ---------------------\n".
		"MSG: ".$string."\n";
	$out .= $self->stack_trace_dump;
	
	print STDERR $out;
	return;
    }    

    my $out = "\n-------------------- WARNING ---------------------\n".
       "MSG: ".$string."\n".
	   "---------------------------------------------------\n";
    print STDERR $out;
}

#line 211

sub deprecated{
   my ($self,$msg) = @_;
   if( $self->verbose >= 0 ) { 
       print STDERR $msg, "\n", $self->stack_trace_dump;
   }
}

#line 230

sub stack_trace_dump{
   my ($self) = @_;

   my @stack = $self->stack_trace();

   shift @stack;
   shift @stack;
   shift @stack;

   my $out;
   my ($module,$function,$file,$position);
   

   foreach my $stack ( @stack) {
       ($module,$file,$position,$function) = @{$stack};
       $out .= "STACK $function $file:$position\n";
   }

   return $out;
}


#line 264

sub stack_trace{
   my ($self) = @_;

   my $i = 0;
   my @out;
   my $prev;
   while( my @call = caller($i++)) {
       # major annoyance that caller puts caller context as
       # function name. Hence some monkeying around...
       $prev->[3] = $call[3];
       push(@out,$prev);
       $prev = \@call;
   }
   $prev->[3] = 'toplevel';
   push(@out,$prev);
   return @out;
}


#line 348

sub _rearrange {
    my $dummy = shift;
    my $order = shift;

    return @_ unless (substr($_[0]||'',0,1) eq '-');
    push @_,undef unless $#_ %2;
    my %param;
    while( @_ ) {
	(my $key = shift) =~ tr/a-z\055/A-Z/d; #deletes all dashes!
	$param{$key} = shift;
    }
    map { $_ = uc($_) } @$order; # for bug #1343, but is there perf hit here?
    return @param{@$order};
}


#----------------'
sub _rearrange_old {
#----------------
    my($self,$order,@param) = @_;
    
    # JGRG -- This is wrong, because we don't want
    # to assign empty string to anything, and this
    # code is actually returning an array 1 less
    # than the length of @param:

    ## If there are no parameters, we simply wish to return
    ## an empty array which is the size of the @{$order} array.
    #return ('') x $#{$order} unless @param;
    
    # ...all we need to do is return an empty array:
    # return unless @param;
    
    # If we've got parameters, we need to check to see whether
    # they are named or simply listed. If they are listed, we
    # can just return them. 

    # The mod test fixes bug where a single string parameter beginning with '-' gets lost.
    # This tends to happen in error messages such as: $obj->throw("-id not defined")
    return @param unless (defined($param[0]) && $param[0]=~/^-/o && ($#param % 2));

    # Tester
#    print "\n_rearrange() named parameters:\n";
#    my $i; for ($i=0;$i<@param;$i+=2) { printf "%20s => %s\n", $param[$i],$param[$i+1]; }; <STDIN>;

    # Now we've got to do some work on the named parameters.
    # The next few lines strip out the '-' characters which
    # preceed the keys, and capitalizes them.
    for (my $i=0;$i<@param;$i+=2) {
	$param[$i]=~s/^\-//;
	$param[$i]=~tr/a-z/A-Z/;
    }
    
    # Now we'll convert the @params variable into an associative array.
    # local($^W) = 0;  # prevent "odd number of elements" warning with -w.
    my(%param) = @param;
    
    # my(@return_array);
    
    # What we intend to do is loop through the @{$order} variable,
    # and for each value, we use that as a key into our associative
    # array, pushing the value at that key onto our return array.
    # my($key);
    
    #foreach (@{$order}) {
	# my($value) = $param{$key};
	# delete $param{$key};
	#push(@return_array,$param{$_});
    #}

    return @param{@{$order}};
    
#    print "\n_rearrange() after processing:\n";
#    my $i; for ($i=0;$i<@return_array;$i++) { printf "%20s => %s\n", ${$order}[$i], $return_array[$i]; } <STDIN>;

    # return @return_array;
}

#line 442

sub _register_for_cleanup {
  my ($self,$method) = @_;
   $self->throw_not_implemented();
}

#line 459

sub _unregister_for_cleanup {
  my ($self,$method) = @_;
   $self->throw_not_implemented();
}

#line 474

sub _cleanup_methods {
  my $self = shift;
  unless ( $ENV{'BIOPERLDEBUG'} || $self->verbose  > 0 ) {
      carp("Use of Bio::Root::RootI is deprecated.  Please use Bio::Root::Root instead");
  }
  return;
}

#line 508

#'

sub throw_not_implemented {
    my $self = shift;
    my $package = ref $self;
    my $iface = caller(0);
    my @call = caller(1);
    my $meth = $call[3];

    my $message = "Abstract method \"$meth\" is not implemented by package $package.\n" .
		   "This is not your fault - author of $package should be blamed!\n";

    # Checking if Error.pm is available in case the object isn't decended from
    # Bio::Root::Root, which knows how to check for Error.pm.

    # EB - this wasn't working and I couldn't figure out!
    # SC - OK, since most RootI objects will be Root.pm-based,
    #      and Root.pm can deal with Error.pm. 
    #      Still, I'd like to know why it wasn't working...

    if( $self->can('throw') ) {
	 $self->throw( -text  => $message,
                       -class => 'Bio::Root::NotImplemented');
    }
    else {
	confess $message ;
    }
}


#line 558

#'

sub warn_not_implemented {
    my $self = shift;
    my $package = ref $self;
    my $iface = caller(0);
    my @call = caller(1);
    my $meth = $call[3];

    my $message = "Abstract method \"$meth\" is not implemented by package $package.\n" .
		   "This is not your fault - author of $package should be blamed!\n";

    if( $self->can('warn') ) {
        $self->warn( $message );
    }
    else {
	carp $message ;
    }
}


1;
