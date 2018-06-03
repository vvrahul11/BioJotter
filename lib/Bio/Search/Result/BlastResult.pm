#line 1 "Bio/Search/Result/BlastResult.pm"
#-----------------------------------------------------------------
# $Id: BlastResult.pm,v 1.13 2002/12/24 15:48:41 jason Exp $
#
# BioPerl module Bio::Search::Result::BlastResult
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 86

#line 97


# Let the code begin...

package Bio::Search::Result::BlastResult;

use strict;

use Bio::Search::Result::ResultI;
use Bio::Root::Root;

use overload 
    '""' => \&to_string;

use vars qw(@ISA $Revision );

$Revision = '$Id: BlastResult.pm,v 1.13 2002/12/24 15:48:41 jason Exp $';  #'
@ISA = qw( Bio::Root::Root Bio::Search::Result::ResultI);

#----------------
sub new {
#----------------
    my ($class, @args) = @_; 
    my $self = $class->SUPER::new(@args);
    return $self;
}

#sub DESTROY {
#    my $self = shift;
#    print STDERR "->DESTROYING $self\n";
#}


#=================================================
# Begin Bio::Search::Result::ResultI implementation
#=================================================

#line 139

#----------------
sub next_hit {
#----------------
    my ($self) = @_;
    
    unless(defined $self->{'_hit_queue'}) {	
        $self->{'_hit_queue'} = [$self->hits()];	
    }
    
    shift @{$self->{'_hit_queue'}};
}

#line 157

#----------------
sub query_name {
#----------------
    my $self = shift;
    if (@_) { 
        my $name = shift;
        $name =~ s/^\s+|(\s+|,)$//g;
        $self->{'_query_name'} = $name;
    }
    return $self->{'_query_name'};
}

#line 175

#----------------
sub query_length {
#----------------
    my $self = shift;
    if(@_) { $self->{'_query_length'} = shift; }
    return $self->{'_query_length'};
}

#line 189

#----------------
sub query_description {
#----------------
    my $self = shift;
    if(@_) { 
        my $desc = shift;
        defined $desc && $desc =~ s/(^\s+|\s+$)//g;
        # Remove duplicated ID at beginning of description string
        defined $desc && $desc =~ s/^$self->{'_query_name'}//o;
        $self->{'_query_query_desc'} = $desc || '';
    }
    return $self->{'_query_query_desc'};
}


#line 212

#----------------
sub analysis_method { 
#----------------
    my ($self, $method) = @_;  
    if($method ) {
      if( $method =~ /blast/i) {
	$self->{'_analysis_prog'} = $method;
      } else {
	$self->throw("method $method not supported in " . ref($self));
      }
    }
    return $self->{'_analysis_prog'}; 
}

#line 232

#----------------
sub analysis_method_version {
#----------------
    my ($self, $version) = @_; 
    if($version) {
	$self->{'_analysis_progVersion'} = $version;
    }
    return $self->{'_analysis_progVersion'}; 
}


#line 249

#----------------
sub analysis_query {
#----------------

    my ($self) = @_;
    if(not defined $self->{'_analysis_query'}) {
        require Bio::PrimarySeq;
        my $moltype = $self->analysis_method =~ /blastp|tblastn/i ? 'protein' : 'dna';
	$self->{'_analysis_query'} =  Bio::PrimarySeq->new( -display_id => $self->query_name,
                                                            -desc => $self->query_description,
                                                            -moltype => $moltype
                                                          );
        $self->{'_analysis_query'}->length( $self->query_length );
    }
    return $self->{'_analysis_query'};
}

#line 276

#---------------
sub analysis_subject { 
#---------------
    my ($self, $blastdb) = @_; 
    if($blastdb) {
        if( ref $blastdb and $blastdb->isa('Bio::Search::DatabaseI')) {
            $self->{'_analysis_sbjct'} = $blastdb;
        }
        else {
            $self->throw(-class =>'Bio::Root::BadParameter',
                         -text => "Can't set BlastDB: not a Bio::Search::DatabaseI $blastdb"
                         );
        }
    }
    return $self->{'_analysis_sbjct'};
}

#line 306

#---------------
sub next_feature{
#---------------
   my ($self) = @_;
   my ($hit, $hsp);
   $hit = $self->{'_current_hit'};
   unless( defined $hit ) {
       $hit = $self->{'_current_hit'} = $self->next_hit;
       return undef unless defined $hit;
   }
   $hsp = $hit->next_hsp;
   unless( defined $hsp ) {
       $self->{'_current_hit'} = undef;
       return $self->next_feature;
   }
   return $hsp || undef;
}


sub algorithm { shift->analysis_method( @_ ); }
sub algorithm_version { shift->analysis_method_version( @_ ); }

#line 338

sub available_parameters{
    return ();
}


#line 354

sub get_parameter{
    return '';
}

#line 369

sub get_statistic{
    return '';
}

#line 383

sub available_statistics{
    return ();
}

#=================================================
# End Bio::Search::Result::ResultI implementation
#=================================================


#line 407

#---------------
sub to_string {
#---------------
    my $self = shift;
    my $str = "[BlastResult] " . $self->analysis_method . " query=" . $self->query_name . " " . $self->query_description .", db=" . $self->database_name;
    return $str;
}

#---------------
sub database_name {
#---------------
    my $self = shift;
    my $dbname = '';
    if( ref $self->analysis_subject) {
      $dbname = $self->analysis_subject->name;
    } 
    return $dbname;
}

#line 438

#---------------
sub database_entries {
#---------------
    my $self = shift;
    my $dbentries = '';
    if( ref $self->analysis_subject) {
      $dbentries = $self->analysis_subject->entries;
    } 
    return $dbentries;
}


#line 463

#---------------
sub database_letters {
#---------------
    my $self = shift;
    my $dbletters = '';
    if( ref $self->analysis_subject) {
      $dbletters = $self->analysis_subject->letters;
    } 
    return $dbletters;
}

#---------------
sub hits {
#---------------
    my $self = shift;
    my @hits = ();
    if( ref $self->{'_hits'}) {
        @hits = @{$self->{'_hits'}};
    }
    return @hits;
}

#line 497

#---------------
sub add_hit {
#---------------
    my ($self, $hit) = @_;
    my $add_it = 1;
    unless( ref $hit and $hit->isa('Bio::Search::Hit::HitI')) {
        $add_it = 0;
        $self->throw(-class =>'Bio::Root::BadParameter',
                     -text => "Can't add hit: not a Bio::Search::Hit::HitI: $hit"
                    );
    }

    # Avoid adding duplicate hits if we're doing multiple iterations (PSI-BLAST)
#    if( $self->iterations > 1 ) {
#        my $hit_name = $hit->name;
#        if( grep $hit_name eq $_, @{$self->{'_hit_names'}}) {
#            $add_it = 0;
#        }
#    }

    if( $add_it ) {
        push @{$self->{'_hits'}}, $hit;
        push @{$self->{'_hit_names'}}, $hit->name;
    }
}


#line 537

#------------
sub is_signif { my $self = shift; return $self->{'_is_significant'}; }
#------------


#line 553

#------------
sub matrix { 
#------------
    my $self = shift; 
    if(@_) {
         $self->{'_matrix'} = shift;
    }
    $self->{'_matrix'};
}


#line 574

#------------
sub raw_statistics { 
#------------
    my $self = shift; 
    if(@_) {
	my $params = shift;
	if( ref $params eq 'ARRAY') {
	    $self->{'_raw_statistics'} = $params;
	}
	else {
            $self->throw(-class =>'Bio::Root::BadParameter',
                         -text => "Can't set statistical params: not an ARRAY ref: $params"
                         );
        }
    }
    if(not defined $self->{'_raw_statistics'}) {
	$self->{'_raw_statistics'} = [];
    }

    @{$self->{'_raw_statistics'}};
}



#line 619

#-----------
sub no_hits_found {
#-----------
    my ($self, $round) = @_;

    my $result = 0;   # final return value of this method.
    # Watch the double negative! 
    # result = 0 means "yes hits were found"
    # result = 1 means "no hits were found" (for the indicated iteration or all iterations)

    # If a iteration was not specified and there were multiple iterations,
    # this method should return true only if all iterations had no hits found.
    if( not defined $round ) {
        if( $self->{'_iterations'} > 1) {
            $result = 1;
            foreach my $i( 1..$self->{'_iterations'} ) {
                if( not defined $self->{"_iteration_$i"}->{'_no_hits_found'} ) {
                    $result = 0;
                    last;
                }
            }
        }
        else {
            $result = $self->{"_iteration_1"}->{'_no_hits_found'};
        }
    }
    else {
        $result = $self->{"_iteration_$round"}->{'_no_hits_found'};
    }

    return $result;
}


#line 663

#-----------
sub set_no_hits_found {
#-----------
    my ($self, $round) = @_;
    $round ||= 1;
    $self->{"_iteration_$round"}->{'_no_hits_found'} = 1;
}


#line 682

#----------------
sub iterations {
#----------------
    my ($self, $num ) = @_;
    if( defined $num ) {
        $self->{'_iterations'} = $num;
    }
    return $self->{'_iterations'};
}


#line 703

#----------------
sub psiblast {
#----------------
    my ($self, $val ) = @_;
    if( $val ) {
        $self->{'_psiblast'} = 1;
    }
    return $self->{'_psiblast'};
}


1;
__END__
