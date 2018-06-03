#line 1 "Bio/Seq/QualI.pm"
# $Id: QualI.pm,v 1.4 2002/10/22 07:38:40 lapp Exp $
#
# BioPerl module for Bio::Seq::QualI
#
# Cared for by Chad Matsalla <bioinformatics@dieselwurks.com
#
# Copyright Chad Matsalla
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 91


# Let the code begin...


package Bio::Seq::QualI;
use vars qw(@ISA);
use strict;
use Carp;

#line 117

sub qual {
   my ($self) = @_;
   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
   }
}

#line 140

sub subqual {
   my ($self) = @_;

   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of subqual - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of subqual - implementing class did not provide this method");
   }

}

#line 176

sub display_id {
   my ($self) = @_;

   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of id - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of id - implementing class did not provide this method");
   }

}


#line 206

sub accession_number {
   my ($self,@args) = @_;

   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of seq - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of seq - implementing class did not provide this method");
   }

}



#line 235

sub primary_id {
   my ($self,@args) = @_;

   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
   }

}


#line 268

sub can_call_new{
   my ($self,@args) = @_;
   # we default to 0 here
   return 0;
}

#line 287

sub qualat {
   my ($self,$value) = @_;
   if( $self->can('warn') ) {
       $self->warn("Bio::Seq::QualI definition of qualat - implementing class did not provide this method");
   } else {
       warn("Bio::Seq::QualI definition of qualat - implementing class did not provide this method");
   }
   return '';
} 

#line 332

sub revcom{
   my ($self) = @_;
		# this is the cleanest way
	my @qualities = @{$self->seq()};	
	my @reversed_qualities = reverse(@qualities);
   my $seqclass;
   if($self->can_call_new()) {
       $seqclass = ref($self);
   } else {
       $seqclass = 'Bio::Seq::PrimaryQual';
		# Wassat?
		# $self->_attempt_to_load_Seq();
   }
	# the \@reverse_qualities thing works simply because I will it to work.
   my $out = $seqclass->new( '-qual' => \@reversed_qualities,
			     '-display_id'  => $self->display_id,
			     '-accession_number' => $self->accession_number,
			     '-desc' => $self->desc()
			     );
   return $out;
}

#line 365

sub trunc {
   my ($self,$start,$end) = @_;

   if( !$end ) {
       if( $self->can('throw')  ) {
	   $self->throw("trunc start,end");
       } else {
	   confess("[$self] trunc start,end");
       }
   }

   if( $end < $start ) {
       if( $self->can('throw')  ) {
	   $self->throw("$end is smaller than $start. if you want to truncated and reverse complement, you must call trunc followed by revcom. Sorry.");
       } else {
	   confess("[$self] $end is smaller than $start. If you want to truncated and reverse complement, you must call trunc followed by revcom. Sorry.");
       }
   }

   my $r_qual = $self->subqual($start,$end);

   my $seqclass;
   if($self->can_call_new()) {
       $seqclass = ref($self);
   } else {
       $seqclass = 'Bio::Seq::PrimaryQual';
		# wassat?
		# $self->_attempt_to_load_Seq();
   }
   my $out = $seqclass->new( '-qual' => $r_qual,
			     '-display_id'  => $self->display_id,
			     '-accession_number' => $self->accession_number,
			     '-desc' => $self->desc()
			     );
   return $out;
}


#line 415


sub translate {
	return 0;
}


#line 434

sub  id {
   my ($self)= @_;
   return $self->display_id();
}

#line 453

sub length {
   my ($self)= @_;
   if( $self->can('throw') ) {
       $self->throw("Bio::Seq::QualI definition of length - implementing class did not provide this method");
   } else {
       confess("Bio::Seq::QualI definition of length - implementing class did not provide this method");
   }
}


#line 475

sub desc {
   my ($self,$value) = @_;
   if( $self->can('warn') ) {
       $self->warn("Bio::Seq::QualI definition of desc - implementing class did not provide this method");
   } else {
       warn("Bio::Seq::QualI definition of desc - implementing class did not provide this method");
   }
   return '';
}

#  These methods are here for backward compatibility with the old, 0.5
#  Seq objects. They all throw warnings that someone is using a
#  deprecated method, and may eventually be removed completely from
#  this object. However, they are important to ease the transition from
#  the old system.

#line 508

sub _attempt_to_load_Seq{
   my ($self) = @_;

   if( $main::{'Bio::Seq::PrimaryQual'} ) {
       return 1;
   } else {
       eval {
	   require Bio::Seq::PrimaryQual;
       };
       if( $@ ) {
	   if( $self->can('throw') ) {
	       $self->throw("Bio::Seq::PrimaryQual could not be loaded for $self\nThis indicates that you are using Bio::Seq::PrimaryQualI without Bio::Seq::PrimaryQual loaded and without providing a complete solution\nThe most likely problem is that there has been a misconfiguration of the bioperl environment\nActual exception\n\n$@\n");
	   } else {
	       confess("Bio::Seq::PrimarySeq could not be loaded for $self\nThis indicates that you are usnig Bio::Seq::PrimaryQualI without Bio::Seq::PrimaryQual loaded and without providing a complete solution\nThe most likely problem is that there has been a misconfiguration of the bioperl environment\nActual exception\n\n$@\n");
	   }
	   return 0;
       }
       return 1;
   }

}


#line 546

sub qualtype {
   my ($self,@args) = @_;
   if( $self->can('throw') ) {
	# $self->throw("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
       $self->throw("qualtypetype is not used with quality objects.");
   } else {
	# confess("Bio::Seq::QualI definition of qual - implementing class did not provide this method");
	confess("qualtype is not used with quality objects.");
   }


}




1;
