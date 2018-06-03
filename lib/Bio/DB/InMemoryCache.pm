#line 1 "Bio/DB/InMemoryCache.pm"
# POD documentation - main docs before the code
#
#

#line 48


# Let the code begin...

package Bio::DB::InMemoryCache;

use Bio::DB::SeqI;

use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Seq;

@ISA = qw(Bio::Root::Root Bio::DB::SeqI);


sub new {
    my ($class,@args) = @_;

    my $self = Bio::Root::Root->new();
    bless $self,$class;

    my ($seqdb,$number,$agr) = $self->_rearrange([qw(SEQDB NUMBER AGRESSION)],@args);

    if( !defined $seqdb || !ref $seqdb || !$seqdb->isa('Bio::DB::RandomAccessI') ) {
       $self->throw("Must be a randomaccess database not a [$seqdb]");
    }
    if( !defined $number ) {
        $number = 1000;
    }
    
    $self->seqdb($seqdb);
    $self->number($number);
    $self->agr($agr);

    # we consider acc as the primary id here
    $self->{'_cache_number_hash'} = {};
    $self->{'_cache_id_hash'}     = {};
    $self->{'_cache_acc_hash'}    = {};
    $self->{'_cache_number'}      = 1;

    return $self;
}



#line 106

sub get_Seq_by_id{
   my ($self,$id) = @_;

   if( defined $self->{'_cache_id_hash'}->{$id} ) {
     my $acc = $self->{'_cache_id_hash'}->{$id};
     my $seq = $self->{'_cache_acc_hash'}->{$acc};
     $self->{'_cache_number_hash'}->{$seq->accession} = $self->{'_cache_number'}++;
     return $seq;
   } else {
     return $self->_load_Seq('id',$id);
   }
}

#line 131

sub get_Seq_by_acc{
   my ($self,$acc) = @_;

   #print STDERR "In cache get for $acc\n";
   if( defined $self->{'_cache_acc_hash'}->{$acc} ) {
       #print STDERR "Returning cached $acc\n";
       my $seq = $self->{'_cache_acc_hash'}->{$acc};
       $self->{'_cache_number_hash'}->{$seq->accession} = $self->{'_cache_number'}++;
       return $seq;
   } else {
     return $self->_load_Seq('acc',$acc);
   }
}



sub number {
    my ($self, $number) = @_;
    if ($number) {
        $self->{'number'} = $number;
    } else {
        return $self->{'number'};
    }
}

sub seqdb {
    my ($self, $seqdb) = @_;
    if ($seqdb) {
        $self->{'seqdb'} = $seqdb;
    } else {
        return $self->{'seqdb'};
    }
}

sub agr {
    my ($self, $agr) = @_;
    if ($agr) {
        $self->{'agr'} = $agr;
    } else {
        return $self->{'agr'};
    }
}


sub _load_Seq {
  my ($self,$type,$id) = @_;

  my $seq;

  if( $type eq 'id') {
    $seq = $self->seqdb->get_Seq_by_id($id);
  }elsif ( $type eq 'acc' ) {
    $seq = $self->seqdb->get_Seq_by_acc($id);
  } else {
    $self->throw("Bad internal error. Don't understand $type");
  }

  if( $self->agr() ) {
      #print STDERR "Pulling out into memory\n";
      my $newseq = Bio::Seq->new( -display_id => $seq->display_id,
				  -accession_number  => $seq->accession,
				  -seq        => $seq->seq,
				  -desc       => $seq->desc,
				  );
      if( $self->agr() == 1 ) {
	  foreach my $sf ( $seq->top_SeqFeatures() ) {
	      $newseq->add_SeqFeature($sf);
	  }
	  
	  $newseq->annotation($seq->annotation);
      }
      $seq = $newseq;
  }

  if( $self->_number_free < 1 ) {
    # remove the latest thing from the hash
    my @accs = sort { $self->{'_cache_number_hash'}->{$a} <=> $self->{'_cache_number_hash'}->{$b} } keys %{$self->{'_cache_number_hash'}};

    my $acc = shift @accs;
    # remove this guy
    my $seq = $self->{'_cache_acc_hash'}->{$acc};

    delete $self->{'_cache_number_hash'}->{$acc};
    delete $self->{'_cache_id_hash'}->{$seq->id};
    delete $self->{'_cache_acc_hash'}->{$acc};
  }

  # up the number, register this sequence into the hash.
  $self->{'_cache_id_hash'}->{$seq->id} = $seq->accession;
  $self->{'_cache_acc_hash'}->{$seq->accession} = $seq;
  $self->{'_cache_number_hash'}->{$seq->accession} = $self->{'_cache_number'}++;

  return $seq;
}


sub _number_free {
  my $self = shift;

  return $self->number - scalar(keys %{$self->{'_cache_number_hash'}});
}




#line 247


sub get_Seq_by_version{
   my ($self,@args) = @_;
   $self->throw("Not implemented it");
}



## End of Package

1;
