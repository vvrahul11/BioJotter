#line 1 "Bio/SearchIO/Writer/ResultTableWriter.pm"
# $Id: ResultTableWriter.pm,v 1.13 2002/12/05 13:46:35 heikki Exp $

#line 131


package Bio::SearchIO::Writer::ResultTableWriter;

use strict;
use Bio::Root::Root;
use Bio::SearchIO::SearchWriterI;

use vars qw( @ISA );
@ISA = qw( Bio::Root::Root Bio::SearchIO::SearchWriterI );

# Array fields: column, object, method[/argument], printf format, column label
# Methods are defined in Bio::Search::Result::ResultI.
# Tech note: If a bogus method is supplied, it will result in all values to be zero.
#            Don't know why this is.
my %column_map = (
                  'query_name'        => ['1', 'result', 'query_name', 's', 'QUERY' ],
                  'query_length'      => ['2', 'result', 'query_length', 'd', 'LEN_Q'],
                  'query_description' => ['3', 'result', 'query_description', 's', 'DESC_Q'],
                 );

sub column_map { return %column_map }

sub new {
    my ($class, @args) = @_; 
    my $self = $class->SUPER::new(@args);

    my( $col_spec, $label_spec,
	$filters ) = $self->_rearrange( [qw(COLUMNS 
					    LABELS
					    FILTERS)], @args);
    
    $self->_set_cols( $col_spec );
    $self->_set_labels( $label_spec ) if $label_spec;
    $self->_set_printf_fmt();
    $self->_set_row_data_func();
    $self->_set_column_labels();
    
    if( defined $filters ) {
	if( !ref($filters) =~ /HASH/i ) { 
	    $self->warn("Did not provide a hashref for the FILTERS option, ignoring.");
	} else { 
	    while( my ($type,$code) = each %{$filters} ) {
		$self->filter($type,$code);
	    }
	}
    }


    return $self;
}


# Purpose : Stores the column spec internally. Also performs QC on the 
#           user-supplied column specification.
#
sub _set_cols {
    my ($self, $col_spec_ref) = @_;
    return if defined $self->{'_cols'};  # only set columns once

    my %map = $self->column_map;

    if( not defined $col_spec_ref) {
        print STDERR "\nUsing default column map.\n";
	$col_spec_ref = [ map { $_ } sort { $map{$a}->[0] <=> $map{$b}->[0] } keys %map ];
    }

    if( ref($col_spec_ref) eq 'ARRAY') {
        # printf "%d columns to process\n", scalar(@$col_spec_ref);
        my @col_spec = @{$col_spec_ref};
        while( my $item = lc(shift @col_spec) ) {
            if( not defined ($map{$item}) ) {
                $self->throw(-class =>'Bio::Root::BadParameter',
                             -text => "Unknown column name: $item"
                            );
            }
            push @{$self->{'_cols'}}, $item;
            #print "pushing on to col $col_num, $inner: $item\n";
        }
    }
    else {
        $self->throw(-class =>'Bio::Root::BadParameter',
                     -text => "Can't set columns: not a ARRAY ref",
                     -value => $col_spec_ref
                    );
    }
}

sub _set_printf_fmt {
    my ($self) = @_;

    my @cols = $self->columns();
    my %map = $self->column_map;

    my $printf_fmt = '';

    foreach my $col ( @cols ) {
	$printf_fmt .= "\%$map{$col}->[3]\t";
    }

    $printf_fmt =~ s/\\t$//;

    $self->{'_printf_fmt'} = $printf_fmt;
}

sub printf_fmt { shift->{'_printf_fmt'} }

# Sets the data to be used for the labels.
sub _set_labels {
    my ($self, $label_spec) = @_;
    if( ref($label_spec) eq 'HASH') {
        foreach my $col ( sort { $a <=> $b } keys %$label_spec ) {
#            print "LABEL: $col $label_spec->{$col}\n";
            $self->{'_custom_labels'}->{$col} = $label_spec->{$col};
        }
    }
    else {
        $self->throw(-class =>'Bio::Root::BadParameter',
                     -text => "Can't set labels: not a HASH ref: $label_spec"
                    );
    }
}

sub _set_column_labels {
    my $self = shift;

    my @cols = $self->columns;
    my %map = $self->column_map;
    my $printf_fmt = '';
    my (@data, $label, @underbars);

    my $i = 0;
    foreach my $col( @cols ) {
	$i++;
        $printf_fmt .= "\%s\t";

        if(defined $self->{'_custom_labels'}->{$i}) {
	    $label = $self->{'_custom_labels'}->{$i};
        }
	else {
	    $label = $map{$col}->[4];
	}
	push @data, $label;
        push @underbars, '-' x length($label);

    }
    $printf_fmt =~ s/\\t$//;

    my $str = sprintf "$printf_fmt\n", @data;

    $str =~ s/\t\n/\n/;
    $str .= sprintf "$printf_fmt\n", @underbars;

    $str =~ s/\t\n/\n/gs;
    $self->{'_column_labels'} = $str;
}

# Purpose : Generate a function that will call the appropriate
# methods on the result, hit, and hsp objects to retrieve the column data 
# specified in the column spec.
#
# We should only have to go through the column spec once
# for a given ResultTableWriter. To permit this, we'll generate code 
# for a method that returns an array of the data for a row of output
# given a result, hit, and hsp object as arguments.
#
sub _set_row_data_func {
    my $self = shift;

    # Now we need to generate a string that can be eval'd to get the data.
    my @cols = $self->columns();
    my %map = $self->column_map;
    my @data;
    while( my $col = shift @cols ) {
	my $object = $map{$col}->[1];
	my $method = $map{$col}->[2];
        my $arg = '';
        if( $method =~ m!(\w+)/(\w+)! ) {
            $method = $1;
            $arg = "\"$2\"";
        }
        push @data, "\$$object->$method($arg)";
    }
    my $code = join( ",", @data);

    if( $self->verbose > 0 ) {
## Begin Debugging	
	$self->debug( "Data to print:\n");
	foreach( 0..$#data) { $self->debug( " [". ($_+ 1) . "] $data[$_]\n");}
	$self->debug( "CODE:\n$code\n");
	$self->debug("Printf format: ". $self->printf_fmt. "\n");
## End Debugging
    }

    my $func = sub {
        my ($result, $hit, $hsp) = @_;
        my @r = eval $code;
        # This should reduce the occurrence of those opaque "all zeros" bugs.
	if( $@ ) { $self->throw("Trouble in ResultTableWriter::_set_row_data_func() eval: $@\n\n"); 
               }
	return @r;
    };
    $self->{'_row_data_func'} = $func;
}

sub row_data_func { shift->{'_row_data_func'} }


#line 358

#----------------
sub to_string {
#----------------
    my ($self, $result, $include_labels) = @_;

    my $str = $include_labels ? $self->column_labels() : '';
    my $resultfilter = $self->filter('RESULT');
    if( ! defined $resultfilter ||
        &{$resultfilter}($result) ) {	
	my @row_data  = &{$self->{'_row_data_func'}}( $result );
	$str .= sprintf "$self->{'_printf_fmt'}\n", @row_data;
	$str =~ s/\t\n/\n/gs;
    }
    return $str;
}



sub columns {
    my $self = shift;
    my @cols;
    if( ref $self->{'_cols'} ) {
        @cols = @{$self->{'_cols'}};
    }
    else {
        my %map = $self->column_map;
        @cols = sort { $map{$a}->[0] <=> $map{$b}->[0] } keys %map;
   }
    return @cols;
}


#line 400

sub column_labels { shift->{'_column_labels'} }

#line 415

sub end_report {
    return '';
}

#line 431


# Is this really needed?
#=head2 signif_format
#
# Usage     : $writer->signif_format( [FMT] );
# Purpose   : Allows retrieval of the P/Expect exponent values only
#           : or as a two-element list (mantissa, exponent).
# Usage     : $writer->signif_format('exp');
#           : $writer->signif_format('parts');
# Returns   : String or '' if not set.
# Argument  : String, FMT = 'exp' (return the exponent only)
#           :             = 'parts'(return exponent + mantissa in 2-elem list)
#           :              = undefined (return the raw value)
# Comments  : P/Expect values are still stored internally as the full,
#           : scientific notation value.
#
#=cut
#
##-------------
#sub signif_format {
##-------------
#    my $self = shift;
#    if(@_) { $self->{'_signif_format'} = shift; }
#    return $self->{'_signif_format'};
#}

1;
