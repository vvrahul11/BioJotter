#line 1 "Bio/Root/Object.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::Root::Object.pm
# AUTHOR  : Steve Chervitz (sac@bioperl.org)
# CREATED : 23 July 1996
# REVISION: $Id: Object.pm,v 1.23 2002/10/22 07:38:37 lapp Exp $
# STATUS  : Alpha
#            
# For documentation, run this module through pod2html 
# (preferably from Perl v5.004 or better).
#
# MODIFICATION NOTES: See bottom of file.
#
# Copyright (c) 1996-2000 Steve Chervitz. All Rights Reserved.
#           This module is free software; you can redistribute it and/or 
#           modify it under the same terms as Perl itself.
#           Retain this notice and note any modifications made.
#-----------------------------------------------------------------------------

package Bio::Root::Object;
use strict;

require 5.002;
use Bio::Root::Global qw(:devel $AUTHORITY $CGI);
use Bio::Root::Root;

use Exporter ();

#use AutoLoader; 
#*AUTOLOAD = \&AutoLoader::AUTOLOAD;

use vars qw(@EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw($VERSION &find_object &stack_trace &containment &_rearrange);  
%EXPORT_TAGS = ( std => [qw(&stack_trace &containment)] );

use vars qw($ID $VERSION %Objects_created $Revision @ISA);

@ISA = qw(Bio::Root::Root);


# %Objects_created can be used for tracking all objects created.
# See _initialize() for details.

$ID       = 'Bio::Root::Object';
$VERSION  = 0.041;
$Revision = '$Id: Object.pm,v 1.23 2002/10/22 07:38:37 lapp Exp $';  #'

### POD Documentation:

#line 376


# 
## 
### 
#### END of main POD documentation. '
###
##
# 


#line 395

#
# This object is deprecated as the root of the inheritance tree, but some
# modules depend on it as a legacy. We issue a deprecation warning for all
# other modules.
#
my @inheriting_modules = ('Bio::Tools::Blast', 'Bio::Root::Object',
			  'Bio::Root::IOManager');


#######################################################
#               CONSTRUCTOR/DESTRUCTOR                #
#######################################################


#line 455

#----------
sub new {
#----------
    my($class, @param) = @_;
    my $self = {};
    bless $self, ref($class) || $class;
    $DEBUG==2 && print STDERR "CREATING $self";
    $self->_initialize(@param);
    $self;
}


#line 518

#----------------
sub _initialize {
#----------------
    local($^W) = 0;
    my($self, %param) = @_;

    if(! grep { ref($self) =~ /$_/; } @inheriting_modules) {
	$self->warn("Class " . ref($self) .
		    " inherits from Bio::Root::Object, which is deprecated. ".
		    "Try changing your inheritance to Bio::Root::Root.");
    }
    my($name, $parent, $make, $strict, $verbose, $obj, $record_err) = (
	($param{-NAME}||$param{'-name'}), ($param{-PARENT}||$param{'-parent'}), 
	($param{-MAKE}||$param{'-make'}), ($param{-STRICT}||$param{'-strict'}),
	($param{-VERBOSE}||$param{'-verbose'}),
        ($param{-OBJ}||$param{'-obj'}, $param{-RECORD_ERR}||$param{'-record_err'})
					  );

    ## See "Comments" above regarding use of _rearrange().
#	$self->_rearrange([qw(NAME PARENT MAKE STRICT VERBOSE OBJ)], %param);

    $DEBUG and do{ print STDERR ">>>> Initializing $ID (${\ref($self)}) ",$name||'anon';<STDIN>};

    if(defined($make) and $make =~ /clone/i) { 
	$self->_set_clone($obj);

    } else {
	$name ||= ($#_ == 1 ? $_[1] : '');  # If a single arg is given, use as name.

	## Another performance issue: calling name(), parent(), strict(), make()
	## Any speed diff with conditionals to avoid method calls?
	
	$self->name($name) if $name; 
	$self->parent($parent) if $parent;
	$self->{'_strict'}  = $strict  || undef;
	$self->{'_verbose'} = $verbose || undef;
	$self->{'_record_err'} = $record_err || undef;

	if($make) {
	    $make = $self->make($make);
	
	    # Index the Object in the global object hash only if requested.
	    # This feature is not used much. If desired, an object can always 
	    # call Bio::Root::Object::index()  any time after construction.
	    $self->index() if $make =~ /index/; 
	}
    }

    $DEBUG and print STDERR "---> Initialized $ID (${\ref($self)}) ",$name,"\n";

    ## Return data of potential use to subclass constructors.
#    return (($make || 'default'), $strict);   # maybe (?)
    return $make || 'default';
}



#line 593

#-----------
sub DESTROY { 
#-----------
    my $self=shift; 

    $DEBUG==2 && print STDERR "DESTROY called in $ID for ${\$self->to_string} ($self)\n";
}  


#line 630

#-------------'
sub destroy {
#-------------
## Note: Cannot delete parent and xref object refs since they are not 
##       owned by this object, merely associated with it.
    my $self = shift;

    if(ref($self->{'_parent'})) {
	$self->{'_parent'}->_drop_child($self);
	undef $self->{'_parent'};
    }

    if(ref($self->{'_io'})) {
	$self->{'_io'}->destroy;
	undef $self->{'_io'};
    } 

    if(ref($self->{'_err'})) {
	$self->{'_err'}->remove_all;
	undef $self->{'_err'};
    }

    if(ref($self->{'_xref'})) {
	$self->{'_xref'}->remove_all;
	undef $self->{'_xref'};
    } 

    $self->_remove_from_index if scalar %Objects_created;
}


#line 691

#---------------'
sub _drop_child {
#---------------
    my ($self, $child) = @_;
    my ($member, $found);

    $self->throw("Child not defined or not an object ($child).") unless ref $child;

    local($^W = 0);
    foreach $member (keys %{$self}) {
	next unless ref($self->{$member});
	# compare references.
	if (ref($self->{$member}) eq 'ARRAY') {
	    my ($i);
	    for($i=0; $i < @{$self->{$member}}; $i++) {
		if ($self->{$member}->[$i] eq $child) {
		    $DEBUG==2 && print STDERR "Removing array child $child\n";
		    undef $self->{$member}->[$i];
		    $found = 1; last;
		}
	    } 
	} elsif(ref($self->{$member}) eq 'HASH') {
	    foreach(keys %{$self->{$member}}) {
		if ($self->{$member}->{$_} eq $child) {
		    $DEBUG==2 && print STDERR "Removing hash child $child\n";
		    undef $self->{$member}->{$_};
		    $found = 1; last;
		}
	    } 
	} else {
	    if ($self->{$member} eq $child) {
		$DEBUG==2 && print STDERR "Removing child $child\n";
		undef $self->{$member};
		$found = 1; last;
	    }
	}
    }
    # Child not found:
    #   It is possible that a child object has a parent but has not yet been added to
    #   the parent due to a failure during construction of the child. Not warning.
    #$self->warn(sprintf "Child %s not found in Parent %s.", $child->to_string, $self->to_string) unless $found;

    undef;
}


#################################################################
#                    ACCESSORS & INSTANCE METHODS
#################################################################



#line 759

#---------
sub name {
#---------
    my $self = shift;

#    $DEBUG and do{ print STDERR "\n$ID: name(@_) called.";<STDIN>; };

    if (@_) { $self->{'_name'} = shift }
    return defined $self->{'_name'} ? $self->{'_name'} : 'anonymous '.ref($self);
}


#line 785

#-------------
sub to_string {
#-------------
    my $self = shift;
    return sprintf "Object %s \"%s\"", ref($self), $self->name;
}


#line 817

#------------'
sub parent {
#------------
    my ($self) = shift;
    if (@_) {
	my $arg = shift; 
	if(ref $arg) {
	    $self->{'_parent'} = $arg;
	} elsif($arg =~ /null/i) {
	    $self->{'_parent'} = undef;
	} else {
	    $self->throw("Can't set parent using $arg: Not an object");
	}
    }
    $self->{'_parent'};
}


#line 845

#------------'
sub src_obj {
#------------
    my ($self) = shift;
    $self->warn("DEPRECATED METHOD src_obj() CALLED. USE parent() INSTEAD.\n");
    $self->parent(@_);
}


#line 872

#--------------'
sub has_name { my $self = shift; return defined $self->{'_name'}; }
#--------------



#line 899

#----------'
sub make { 
#----------
    my $self = shift;
    if(@_) { $self->{'_make'} = shift; }
    $self->{'_make'} || 'default'; 
}


#line 960

#----------
sub err {
#----------
    my( $self, $data, $delimit) = @_;

    return undef unless defined $self->{'_err'};
    
    $data    ||= 'member';
#    $delimit ||= (wantarray ? 'list' : "\n");
    $delimit ||= "\n";

    $data eq 'member' and return $self->{'_err'}; 
    $data eq 'count'  and return $self->{'_err'}->size();

    return $self->{'_err'}->get_all($data, $delimit );
}	


#line 998

#---------------
sub record_err {
#---------------
    my $self = shift;

    if (@_) { $self->{'_record_err'} = shift }
    return $self->{'_record_err'} || 0;
}


#line 1018

#-------------'
sub err_state { 
#-------------
    my $self = shift; 
    return 'OKAY' if not defined $self->{'_err'};
    $self->{'_errState'} || 'OKAY'; 
}


#line 1036

#-------------
sub clear_err {
#-------------
    my $self = shift;
    undef $self->{'_err'};
}





#line 1069

#------------------
sub containment {
#------------------
    my( $self) = @_;
    my(@hierarchy);

#    print "$ID: getting err hierarchy.\n";
    push @hierarchy, $self->to_string; 
    my $obj = $self;
    my $count = 0;

    while( ref $obj->parent) {
	$obj = $obj->parent;
	push @hierarchy, sprintf "%sContained in %s", ' ' x ++$count, $obj->to_string;
    }
    return \@hierarchy;
}


#line 1110

#--------------'
sub set_stats {  
#--------------
    my( $self, %param ) = @_;
    
    my ($val);
    foreach (keys %param) { 
	$val = $param{$_};;
	s/^(\w)/_\l$1/; 
	$self->{$_} = $val;  
    }
}


#line 1162

#------------
sub strict {
#------------
    my $self = shift;

    # Use global strictness?
    if( $self->{'_use_global_strictness'}) {
	return &strictness(@_);
    }
    else {
        # Object-specific strictness 
        if (@_) { $self->{'_strict'} = shift; }
        defined($self->{'_strict'}) 
            ? return $self->{'_strict'}
            : (ref $self->{'_parent'} ? $self->{'_parent'}->strict : 0);
    }
}

#line 1194

sub use_global_strictness {
    my ($self, $value) = @_;

    if( defined $value ) {
	$self->{'_use_global_strictness'} = $value;
    }

    return $self->{'_use_global_strictness'};
}


#line 1233

#-------------'
sub clone {
#-------------
    my($self) = shift; 

#    warn sprintf "\nCloning %s \"%s\"\n\n", ref($self),$self->name;

    my $clone = $self->new(-MAKE    =>'clone', 
			   -OBJ     =>$self);  
    if($self->err()) { $clone->err($self->err); } 
    $clone; 
} 



#line 1265

#----------------
sub _set_clone {
#----------------
    my($self, $obj) = @_;

    ref($obj) || throw($self, "Can't clone $ID object: Not an object ref ($obj)");

    local($^W) = 0;  # suppress 'uninitialized' warnings.

    $self->{'_name'}     = $obj->{'_name'};
    $self->{'_strict'}   = $obj->{'_strict'};
    $self->{'_make'}     = $obj->{'_make'};
    $self->{'_verbose'}  = $obj->{'_verbose'};
    $self->{'_errState'} = $obj->{'_errState'};
    ## Better to use can() with Perl 5.004.
    $self->{'_parent'}   = ref($obj->{'_parent'}) and $obj->{'_parent'}->clone;
    $self->{'_io'}       = ref($obj->{'_io'}) and $obj->{'_io'}->clone;
    $self->{'_err'}      = ref($obj->{'_err'}) and $obj->{'_err'}->clone;
}



#line 1309

#------------
sub verbose { 
#------------
    my $self = shift; 

    # Using global verbosity
    return &verbosity(@_);

    # Object-specific verbosity (not used unless above code is commented out)
    if(@_) { $self->{'_verbose'} = shift; }
    defined($self->{'_verbose'}) 
	? return $self->{'_verbose'}
	: (ref $self->{'_parent'} ? $self->{'_parent'}->verbose : 0);
}



#line 1337

#-------
sub _io  {  my $self = shift;   return $self->{'_io'}; }
#-------



#line 1352

#------------
sub _set_io {
#------------
    my $self = shift;
    
    require Bio::Root::IOManager;

# See PR#192. 
#    $self->{'_io'} = new Bio::Root::IOManager(-PARENT=>$self, @_);
    $self->{'_io'} = new Bio::Root::IOManager(-PARENT=>$self);
}



#line 1383

#----------------'
sub set_display {
#----------------
    my($self, @param) = @_;
    
    $self->_set_io(@param) if !ref($self->{'_io'});

    eval { $self->{'_io'}->set_display(@param);  };

    if($@) {
	my $er = $@;
	$self->throw(-MSG=>$er, -NOTE=>"Can't set_display for ${\$self->name}");
    }

   return $self->{'_io'}->fh;
}


#line 1456

#-------------
sub display { 
#-------------
    my( $self, @param ) = @_; 
    $self->{'_io'} || $self->set_display(@param);
    $self->{'_io'}->display(@param); 
}




#line 1479

#-------------------
sub _display_stats {
#-------------------
    my($self, $OUT) = @_;
    

    printf ( $OUT "%-15s: %s\n","NAME", $self->name());
    printf ( $OUT "%-15s: %s\n","MAKE", $self->make());
    if($self->parent) {
	printf ( $OUT "%-15s: %s\n","PARENT", $self->parent->to_string);
    }
    printf ( $OUT "%-15s: %d\n",'ERRORS', (defined $self->err('count') ? $self->err('count') : 0)); ###JES###
    printf ( $OUT "%-15s: %s\n","ERR STATE", $self->err_state());
    if($self->err()) {
	print $OUT "ERROR:\n";
	$self->print_err();
    }
}



#line 1518

#--------
sub read { 
#--------
    my $self = shift; 

    $self->_set_io(@_) if not defined $self->{'_io'};
	
    $self->{'_io'}->read(@_); 
}



#line 1543

#--------'
sub fh      { 
#--------
    my $self = shift; 
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->fh(@_); 
}


#line 1566

#-----------
sub show    { 
#-----------
    my $self = shift; 
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->show; 
}



#line 1589

#---------
sub file    {   
#---------
    my $self = shift;  
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->file(@_); 
}


#line 1612

#-------------------
sub compress_file { 
#-------------------
    my $self = shift;
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->compress_file(@_); 
}



#line 1635

#--------------------
sub uncompress_file { 
#--------------------
    my $self = shift;  
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->uncompress_file(@_); 
}


#line 1658

#-----------------
sub delete_file { 
#-----------------
    my $self = shift;
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->delete_file(@_); 
}


#line 1682

#---------------
sub file_date { 
#---------------
    my $self = shift;  
    $self->_set_io(@_) if !defined $self->{'_io'};
    $self->{'_io'}->file_date(@_); 
}



#line 1715

#---------
sub xref  { 
#---------
    my $self = shift; 
    if(@_) { 
	my $arg = shift;
	if(ref $arg) {
	    require Bio::Root::Xref;
	    
	    if( !defined $self->{'_xref'}) {
		$self->{'_xref'} = new Bio::Root::Xref(-PARENT =>$self,
						       -OBJ     =>$arg);
	    } else {
		$self->{'_xref'}->add($arg);
	    }
	} elsif($arg =~ /null|undef/i) {
	    undef $self->{'_xref'};
	} else {
	    $self->throw("Can't set Xref using $arg: Not an object");
	}
    }
    
    $self->{'_xref'}; 
}



#line 1758

#----------
sub index {
#----------
    my $self    = shift;
    my $class   = ref $self;
    my $objName = $self->{'_name'};
    
    if( not defined $objName ) {
	$self->throw("Can't index $class object \"$objName\".");
    }
    
    $DEBUG and do{ print STDERR "$ID: Indexing $class object \"$objName\"."; <STDIN>; };
    
    $Objects_created{ $class }->{ $objName } = $self;
}

#----------------------
sub _remove_from_index {
#----------------------
    my $self    = shift;
    my $class   = ref $self;
    my $objName = $self->{'_name'};
    
    undef $Objects_created{$class}->{$objName} if exists $Objects_created{$class}->{$objName};
}



#line 1804

#---------------
sub find_object {
#---------------
    my $name   = shift;   # Assumes name has been validated.
    my $class  = undef;
    my $object = undef;
    
    foreach $class ( keys %Objects_created ) {
	if( exists $Objects_created{ $class }->{ $name } ) {
	    $object = $Objects_created{ $class }->{ $name };
	    last;
	}
    }
    $object;
}



#line 1835

#----------------
sub has_warning { 
#----------------
    my $self = shift; 
    my $errData = $self->err('type');
    return 1 if $errData =~ /WARNING/;
    0;
}



#line 1863

#-------------
sub print_err {
#-------------
    my( $self, %param ) = @_;
    
#    print "$ID: print_err()\n";

    my $OUT = $self->set_display(%param);

#    print "$ID: OUT = $OUT\n";

    print $OUT $self->err_string( %param );
    
#    print "$ID: done print_err()\n";
}



#line 1898

#----------------
sub err_string {
#----------------
    my( $self, %param ) = @_;
    my($out);
    my $errCount = $self->err('count');

#    print "$ID: err_string(): count = $errCount\n";

    if( $errCount) { 
	$out = sprintf("\n%d error%s in %s \"%s\"\n",
		       $errCount, $errCount>1?'s':'', ref($self), $self->name);
	$out .= $self->err->string( %param );
    } else {
	$out = sprintf("\nNo errors in %s \"%s\"\n", ref($self), $self->name);
    }
    $out;
}




#################################################################
#            DEPRECATED or HIGHLY EXPERIMENTAL METHODS
#################################################################

#line 1945

#----------
sub terse { 
#----------
    my $self = shift; 
    if(@_) { $self->{'_verbose'} = -1 * shift; }

    $self->warn("Deprecated method 'terse()'. Use verbose(-1) instead.");

    my $verbosity = $self->{'_verbose'} or
	(ref $self->{'_parent'} and $self->{'_parent'}->verbose) or 0;

    return $verbosity * -1;
}


#----------------------
#line 1977

#-----------------
sub set_err_data { 
#-----------------
    my( $self, $field, $data) = @_;
    
    $self->throw("Object has no errors.") if !$self->{'_err'};

#    print "$ID: set_err_data($field)  with data = $data\n  in object ${\$self->name}:\n", $self->err->last->string(-CURRENT=>1); <STDIN>;

    $self->{'_err'}->last->set( $field, $data );
}

#line 2001

#--------------
sub set_read { 
#--------------
    my($self,%param) = @_;
    
    $self->_set_io(%param) if !defined $self->{'_io'};

    $self->{'_io'}->set_read(%param);
}



#line 2026

#---------------'
sub set_log_err {
#---------------
    my($self,%param) = @_;
    
    $self->_set_io(%param) if !defined $self->{'_io'};

    $self->{'_io'}->set_log_err(%param);
}


1;
__END__


#####################################################################################
#                                  END OF CLASS                                     #
#####################################################################################

#line 2112


MODIFICATION NOTES:
-----------------------
0.041, sac --- Thu Feb  4 03:50:58 1999
 * warn() utilizes the Global $CGI indicator to supress output
   when script is running as a CGI.

0.04, sac --- Tue Dec  1 04:32:01 1998
 *  Incorporated the new globals $STRICTNESS and $VERBOSITY
    and eliminated WARN_ON_FATAL, FATAL_ON_WARN and DONT_WARN.
 *  Deprecated terse() since it is better to think of terseness
    as negative verbosity.
 *  Removed autoloading-related code and comments.

0.035, 28 Sep 1998, sac:
  * Added _drop_child() method to attempt to break cyclical refs
    between parent and child objects.
  * Added to_string() method.
  * Err objects no longer know their parents (no need).

0.031, 2 Sep 1998, sac:
  * Documentation changes only. Wrapped the data member docs
    at the bottom in POD comments which fixes compilation bug
    caused by commenting out __END__.

0.03, 16 Aug 1998, sac:
  * Calls to warn() or throw() now no longer result in Err.pm objects
    being attached to the current object. For discussion about this 
    descision, see comments under err().
  * Added the -RECORD_ERR constructor option and Global::record_err() 
    method to enable the attachment of Err.pm object to the current 
    object.
  * Minor bug fixes with parameter handling (%param -> @param).
  * Added note about AUTOLOADing.

0.023, 20 Jul 1998, sac:
  * Changes in Bio::Root::IOManager::read().
  * Improved memory management (destroy(), DESTROY(), and changes
    in Bio::Root::Vector.pm).

0.022, 16 Jun 1998, sac:
  * Changes in Bio::Root::IOManager::read().

0.021, May 1998, sac:
  * Touched up _set_clone().
  * Refined documentation in this and other Bio::Root modules
    (converted to use pod2html in Perl 5.004)


