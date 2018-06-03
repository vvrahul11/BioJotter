#line 1 "Bio/Factory/BlastHitFactory.pm"
#-----------------------------------------------------------------
# $Id: BlastHitFactory.pm,v 1.7 2002/10/22 09:38:09 sac Exp $
#
# BioPerl module for Bio::Factory::BlastHitFactory
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 73

#'

package Bio::Factory::BlastHitFactory;

use strict;
use Bio::Root::Root;
use Bio::Factory::HitFactoryI;
use Bio::Search::Hit::BlastHit;

use vars qw(@ISA);

@ISA = qw(Bio::Root::Root Bio::Factory::HitFactoryI); 

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    return $self;
}

#line 110

sub create_hit {
    my ($self, @args) = @_;

    my ($blast, $raw_data, $shallow_parse) =
      $self->_rearrange( [qw(RESULT
			     RAW_DATA
			     SHALLOW_PARSE)], @args);

    my %args = @args;
    $args{'-PROGRAM'}   = $blast->analysis_method;
    $args{'-QUERY_LEN'} = $blast->query_length;
    $args{'-ITERATION'} = $blast->iterations;

    my $hit = Bio::Search::Hit::BlastHit->new( %args );
    
    unless( $shallow_parse ) {
      $self->_add_hsps( $hit, 
			$args{'-PROGRAM'}, 
			$args{'-QUERY_LEN'}, 
			$blast->query_name, 
			@{$raw_data} );
    }

    return $hit;
}

#=head2 _add_hsps
#
# Usage     : Private method; called automatically by create_hit().
# Purpose   : Creates BlastHSP.pm objects for each HSP in a BLAST hit alignment.
#           : Also collects the full description of the hit from the
#           : HSP alignment section.
# Returns   : n/a
# Argument  : (<$BlastHit_object>, <$program_name>, <$query_length>, <$query_name>, <@raw_data>
#             'raw data list' consists of traditional BLAST report 
#             format for a single HSP, supplied as a list of strings.
# Throws    : Warnings for each BlastHSP.pm object that fails to be constructed.
#           : Exception if no BlastHSP.pm objects can be constructed.
#           : Exception if can't parse length data for hit sequence.
# Comments  : Requires Bio::Search::HSP::BlastHSP.pm.
#           : Sets the description using the full string present in 
#           : the alignment data.
#=cut

#--------------
sub _add_hsps { 
#--------------
    my( $self, $hit, $prog, $qlen, $qname, @data ) = @_;
    my $start     = 0;
    my $hspCount  = 0;

    require Bio::Search::HSP::BlastHSP;

#    printf STDERR "\nBlastHit \"$hit\" _process_hsps(). \nDATA (%d lines) =\n@data\n", scalar(@data);

    my( @hspData, @hspList, @errs, @bad_names );
    my($line, $set_desc, @desc);
    $set_desc = 0;
    my $hname = $hit->name;
    my $hlen;

    hit_loop:
   foreach $line( @data ) {

       if( $line =~ /^\s*Length = ([\d,]+)/ ) {
	   $hit->_set_description(@desc);
	   $set_desc = 1;
	   $hit->_set_length($1);
           $hlen = $hit->length;
	   next hit_loop;
       } elsif( !$set_desc) {
	   $line =~ s/^\s+|\s+$//g;
	   push @desc, $line;
	   next hit_loop;
       } elsif( $line =~ /^\s*Score/ ) {
	   ## This block is for setting multiple HSPs.

	   if( not scalar @hspData ) {
	       $start = 1; 
	       push @hspData, $line; 
	       next hit_loop;

	    } elsif( scalar @hspData) {  
		$hspCount++;
		$self->verbose and do{ print STDERR +( $hspCount % 10 ? "+" : "+\n" ); };

#		print STDERR "\nBlastHit: setting HSP #$hspCount \n@hspData\n";
		my $hspObj =  Bio::Search::HSP::BlastHSP->new
				      (-RAW_DATA   => \@hspData, 
				       -RANK       => $hspCount,
				       -PROGRAM    => $prog,
				       -QUERY_NAME => $qname,
				       -HIT_NAME   => $hname,
				      ); 
		push @hspList, $hspObj;
		@hspData = ();
		push @hspData, $line;
		next;
	   } else {
	       push @hspData, $line;
	   }
       } elsif( $start ) {
	   ## This block is for setting the last HSP (which may be the first as well!).
	   if( $line =~ /^(end|>|Parameters|CPU|Database:)/ ) {
	       $hspCount++;
	       $self->verbose and do{ print STDERR +( $hspCount % 10 ? "+" : "+\n" ); };

#	       print STDERR "\nBlastHit: setting HSP #$hspCount \n@hspData"; 

	       my $hspObj = Bio::Search::HSP::BlastHSP->new
				     (-RAW_DATA   => \@hspData, 
				      -RANK       => $hspCount,
				      -PROGRAM    => $prog,
				      -QUERY_NAME => $qname,
				      -HIT_NAME   => $hname,
				     );
	       push @hspList, $hspObj;
	   } else {
	       push @hspData, $line;
	   }
       }
   }		

    $hit->{'_length'} or $self->throw( "Can't determine hit sequence length.");

    # Adjust logical length based on BLAST flavor.
    if($prog =~ /TBLAST[NX]/) {
	$hit->{'_logical_length'} = $hit->{'_length'} / 3;
    }

    $hit->{'_hsps'} = [ @hspList ];

#    print STDERR "\n--------> Done building HSPs for $hit (total HSPS: ${\$hit->num_hsps})\n";

}



1;
