#line 1 "Bio/SearchIO.pm"
# $Id: SearchIO.pm,v 1.18 2002/12/13 13:54:03 jason Exp $
#
# BioPerl module for Bio::SearchIO
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 78


# Let the code begin...


package Bio::SearchIO;
use strict;
use vars qw(@ISA);

# Object preamble - inherits from Bio::Root::IO

use Bio::Root::IO;
use Bio::Event::EventGeneratorI;
use Bio::SearchIO::SearchResultEventBuilder;
use Bio::AnalysisParserI;
use Symbol();

@ISA = qw( Bio::Root::IO Bio::Event::EventGeneratorI Bio::AnalysisParserI);

#line 115

sub new {
  my($caller,@args) = @_;
  my $class = ref($caller) || $caller;
    
  # or do we want to call SUPER on an object if $caller is an
  # object?
  if( $class =~ /Bio::SearchIO::(\S+)/ ) {
    my ($self) = $class->SUPER::new(@args);	
    $self->_initialize(@args);
    return $self;
  } else { 
    my %param = @args;
    @param{ map { lc $_ } keys %param } = values %param; # lowercase keys
    my $format = $param{'-format'} ||
      $class->_guess_format( $param{'-file'} || $ARGV[0] ) || 'blast';

    my $output_format = $param{'-output_format'};
    my $writer = undef;

    if( defined $output_format ) {
	if( defined $param{'-writer'} ) {
	    my $dummy = Bio::Root::Root->new();
	    $dummy->throw("Both writer and output format specified - not good");
	}

	if( $output_format =~ /^blast$/i ) {
	    $output_format = 'TextResultWriter';
	}
	my $output_module = "Bio::SearchIO::Writer::".$output_format;
	$class->_load_module($output_module);
	$writer = $output_module->new();
	push(@args,"-writer",$writer);
    }


    # normalize capitalization to lower case
    $format = "\L$format";
    
    return undef unless( $class->_load_format_module($format) );
    return "Bio::SearchIO::${format}"->new(@args);
  }
}

#line 173

sub newFh {
  my $class = shift;
  return unless my $self = $class->new(@_);
  return $self->fh;
}

#line 192


sub fh {
  my $self = shift;
  my $class = ref($self) || $self;
  my $s = Symbol::gensym;
  tie $$s,$class,$self;
  return $s;
}

#line 213

sub attach_EventHandler{
    my ($self,$handler) = @_;
    return if( ! $handler );
    if( ! $handler->isa('Bio::SearchIO::EventHandlerI') ) {
	$self->warn("Ignoring request to attatch handler ".ref($handler). ' because it is not a Bio::SearchIO::EventHandlerI');
    }
    $self->{'_handler'} = $handler;
    return;
}

#line 235

sub _eventHandler{
   my ($self) = @_;
   return $self->{'_handler'};
}

sub _initialize {
    my($self, @args) = @_;
    $self->{'_handler'} = undef;
    # not really necessary unless we put more in RootI
    #$self->SUPER::_initialize(@args);
    
    # initialize the IO part
    $self->_initialize_io(@args);
    $self->attach_EventHandler(new Bio::SearchIO::SearchResultEventBuilder());
    $self->{'_reporttype'} = '';

    my ( $writer, $rfactory, $hfactory, $use_factories ) =
      $self->_rearrange([qw(WRITER 
			    RESULT_FACTORY 
			    HIT_FACTORY
			    USE_FACTORIES)], @args);

    $self->writer( $writer ) if $writer;

    # TODO: Resolve this issue:
    # The $use_factories flag is a temporary hack to allow factory-based and 
    # non-factory based SearchIO objects to co-exist. 
    # steve --- Sat Dec 22 04:41:20 2001
    if( $use_factories) {
      if( not defined $self->{'_result_factory'}) {
	$self->result_factory( $rfactory || $self->default_result_factory_class->new );
      }
      if( not defined $self->{'_hit_factory'}) {
	$self->hit_factory( $hfactory || $self->default_hit_factory_class->new );
      }
    }
}

#line 296

sub next_result {
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 317

sub write_result {
   my ($self, $result, @args) = @_;

   if( not ref($self->{'_result_writer'}) ) {
       $self->throw("ResultWriter not defined.");
   }
   my $str = $self->writer->to_string( $result, @args );
   #print "Got string: \n$str\n";
   $self->_print( "$str" );
   
   return 1;
}


#line 343

sub writer {
    my ($self, $writer) = @_;
    if( ref($writer) and $writer->isa( 'Bio::SearchIO::SearchWriterI' )) {
        $self->{'_result_writer'} = $writer;
    }
    elsif( defined $writer ) {
        $self->throw("Can't set ResultWriter. Not a Bio::SearchIO::SearchWriterI: $writer");
    }
    return $self->{'_result_writer'};
}


#line 371

sub hit_factory {
    my ($self, $fact) = @_;
    if( ref $fact and $fact->isa( 'Bio::Factory::HitFactoryI' )) {
    	   $self->{'_hit_factory'} = $fact;
    }
    elsif( defined $fact ) {
        $self->throw("Can't set HitFactory. Not a Bio::Factory::HitFactoryI: $fact");
    }
    return $self->{'_hit_factory'};
}

#line 399

sub result_factory {
    my ($self, $fact) = @_;
    if( ref $fact and $fact->isa( 'Bio::Factory::ResultFactoryI' )) {
    	   $self->{'_result_factory'} = $fact;
    }
    elsif( defined $fact ) {
        $self->throw("Can't set ResultFactory. Not a Bio::Factory::ResultFactoryI: $fact");
    }
    return $self->{'_result_factory'};
}


#line 422

sub result_count {
    my $self = shift;
    $self->throw_not_implemented;
}


#line 445

sub default_hit_factory_class {
    my $self = shift;
# TODO: Uncomment this when Jason's SearchIO code conforms
#    $self->throw_not_implemented;
}

#line 462

sub _load_format_module {
  my ($self,$format) = @_;
  my $module = "Bio::SearchIO::" . $format;
  my $ok;
  
  eval {
      $ok = $self->_load_module($module);
  };
  if ( $@ ) {
      print STDERR <<END;
$self: $format cannot be found
Exception $@
For more information about the SearchIO system please see the SearchIO docs.
This includes ways of checking for formats at compile time, not run time
END
  ;
  }
  return $ok;
}


#line 494


sub _guess_format {
   my $class = shift;
   return unless $_ = shift;
   return 'blast'   if (/blast/i or /\.bl\w$/i);
   return 'fasta' if (/fasta/i or /\.fas$/i);
   return 'blastxml' if (/blast/i and /\.xml$/i);
   return 'exonerate' if ( /\.exonerate/i or /\.exon/i );
}

sub close { 
    my $self = shift;
    if( $self->writer ) {
	$self->_print($self->writer->end_report());
    }
    $self->SUPER::close(@_);
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

sub TIEHANDLE {
  my $class = shift;
  return bless {processor => shift}, $class;
}

sub READLINE {
  my $self = shift;
  return $self->{'processor'}->next_result() unless wantarray;
  my (@list, $obj);
  push @list, $obj while $obj = $self->{'processor'}->next_result();
  return @list;
}

sub PRINT {
  my $self = shift;
  $self->{'processor'}->write_result(@_);
}

1;

__END__
