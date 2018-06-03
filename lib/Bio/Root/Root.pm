#line 1 "Bio/Root/Root.pm"
package Bio::Root::Root;
use strict;

# $Id: Root.pm,v 1.30 2002/12/16 09:44:28 birney Exp $

#line 147

#'

use vars qw(@ISA $DEBUG $ID $Revision $VERSION $VERBOSITY $ERRORLOADED);
use strict;
use Bio::Root::RootI;
use Bio::Root::IO;

@ISA = 'Bio::Root::RootI';

BEGIN { 

    $ID        = 'Bio::Root::Root';
    $VERSION   = 1.0;
    $Revision  = '$Id: Root.pm,v 1.30 2002/12/16 09:44:28 birney Exp $ ';
    $DEBUG     = 0;
    $VERBOSITY = 0;
    $ERRORLOADED = 0;

    # Check whether or not Error.pm is available.

    # $main::DONT_USE_ERROR is intended for testing purposes and also
    # when you don't want to use the Error module, even if it is installed.
    # Just put a INIT { $DONT_USE_ERROR = 1; } at the top of your script.
    if( not $main::DONT_USE_ERROR ) {
        if ( eval "require Error"  ) {
            import Error qw(:try);
            require Bio::Root::Exception;
            $ERRORLOADED = 1;
            $Error::Debug = 1; # enable verbose stack trace 
        }
    } 
    if( !$ERRORLOADED ) {
        require Carp; import Carp qw( confess );
    }    
    $main::DONT_USE_ERROR;  # so that perl -w won't warn "used only once"

}



#line 194

sub new {
#    my ($class, %param) = @_;
    my $class = shift;
    my $self = {};
    bless $self, ref($class) || $class;

    if(@_ > 1) {
	# if the number of arguments is odd but at least 3, we'll give
	# it a try to find -verbose
	shift if @_ % 2;
	my %param = @_;
	## See "Comments" above regarding use of _rearrange().
	$self->verbose($param{'-VERBOSE'} || $param{'-verbose'});
    }
    return $self;
}

		     
#line 227

sub verbose {
   my ($self,$value) = @_;
   # allow one to set global verbosity flag
   return $DEBUG  if $DEBUG;
   return $VERBOSITY unless ref $self;
   
    if (defined $value || ! defined $self->{'_root_verbose'}) {
       $self->{'_root_verbose'} = $value || 0;
    }
    return $self->{'_root_verbose'};
}

sub _register_for_cleanup {
  my ($self,$method) = @_;
  if($method) {
    if(! exists($self->{'_root_cleanup_methods'})) {
      $self->{'_root_cleanup_methods'} = [];
    }
    push(@{$self->{'_root_cleanup_methods'}},$method);
  }
}

sub _unregister_for_cleanup {
  my ($self,$method) = @_;
  my @methods = grep {$_ ne $method} $self->_cleanup_methods;
  $self->{'_root_cleanup_methods'} = \@methods;
}


sub _cleanup_methods {
  my $self = shift;
  return unless ref $self && $self->isa('HASH');
  my $methods = $self->{'_root_cleanup_methods'} or return;
  @$methods;

}

#line 304

#'

sub throw{
   my ($self,@args) = @_;
   
   my ( $text, $class ) = $self->_rearrange( [qw(TEXT CLASS)], @args);

   if( $ERRORLOADED ) {
#       print STDERR "  Calling Error::throw\n\n";

       # Enable re-throwing of Error objects.
       # If the error is not derived from Bio::Root::Exception, 
       # we can't guarantee that the Error's value was set properly
       # and, ipso facto, that it will be catchable from an eval{}.
       # But chances are, if you're re-throwing non-Bio::Root::Exceptions,
       # you're probably using Error::try(), not eval{}.
       # TODO: Fix the MSG: line of the re-thrown error. Has an extra line
       # containing the '----- EXCEPTION -----' banner.
       if( ref($args[0])) {
           if( $args[0]->isa('Error')) {
               my $class = ref $args[0];
               throw $class ( @args );
           } else {
               my $text .= "\nWARNING: Attempt to throw a non-Error.pm object: " . ref$args[0];
               my $class = "Bio::Root::Exception";
               throw $class ( '-text' => $text, '-value' => $args[0] ); 
           }
       } else {
           $class ||= "Bio::Root::Exception";

   	   my %args;
	   if( @args % 2 == 0 && $args[0] =~ /^-/ ) {
	       %args = @args;
	       $args{-text} = $text;
	       $args{-object} = $self;
	   }

           throw $class ( scalar keys %args > 0 ? %args : @args ); # (%args || @args) puts %args in scalar context!
       }
   }
   else {
#       print STDERR "  Not calling Error::throw\n\n";
       $class ||= '';
       my $std = $self->stack_trace_dump();
       my $title = "------------- EXCEPTION $class -------------";
       my $footer = "\n" . '-' x CORE::length($title);
       $text ||= '';

       my $out = "\n$title\n" .
           "MSG: $text\n". $std . $footer . "\n";

       die $out;
   }
}

#line 369

sub debug{
   my ($self,@msgs) = @_;
   
   if( $self->verbose > 0 ) { 
       print STDERR join("", @msgs);
   }   
}

#line 389

sub _load_module {
    my ($self, $name) = @_;
    my ($module, $load, $m);
    $module = "_<$name.pm";
    return 1 if $main::{$module};

    # untaint operation for safe web-based running (modified after a fix
    # a fix by Lincoln) HL
    if ($name !~ /^([\w:]+)$/) {
	$self->throw("$name is an illegal perl package name");
    }

    $load = "$name.pm";
    my $io = Bio::Root::IO->new();
    # catfile comes from IO
    $load = $io->catfile((split(/::/,$load)));
    eval {
        require $load;
    };
    if ( $@ ) {
        $self->throw("Failed to load module $name. ".$@);
    }
    return 1;
}


sub DESTROY {
    my $self = shift;
    my @cleanup_methods = $self->_cleanup_methods or return;
    for my $method (@cleanup_methods) {
      $method->($self);
    }
}



1;

