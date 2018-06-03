#line 1 "Bio/SearchIO/Writer/HitTableWriter.pm"
# $Id: HitTableWriter.pm,v 1.14 2002/12/24 15:46:47 jason Exp $

#line 174

package Bio::SearchIO::Writer::HitTableWriter;

use strict;
use Bio::SearchIO::Writer::ResultTableWriter;

use vars qw( @ISA );
@ISA = qw( Bio::SearchIO::Writer::ResultTableWriter );


# Array fields: column, object, method[/argument], printf format,
# column label Methods for result object are defined in
# Bio::Search::Result::ResultI.  Methods for hit object are defined in
# Bio::Search::Hit::HitI.  Tech note: If a bogus method is supplied,
# it will result in all values to be zero.  Don't know why this is.

# TODO (maybe): Allow specification of separate mantissa/exponent for
# significance data.

my %column_map = (
                  'query_name'            => ['1', 'result', 'query_name', 's', 'QUERY' ],
                  'query_length'          => ['2', 'result', 'query_length', 'd', 'LEN_Q'],
                  'hit_name'              => ['3', 'hit', 'name', 's', 'HIT'],
                  'hit_length'            => ['4', 'hit', 'length', 'd', 'LEN_H'],
                  'round'                 => ['5', 'hit', 'iteration', 'd', 'ROUND'],
                  'expect'                => ['6', 'hit', 'significance', '.1e', 'EXPCT'],
                  'score'                 => ['7', 'hit', 'raw_score', 'd', 'SCORE'],
                  'bits'                  => ['8', 'hit', 'bits', 'd', 'BITS'],
                  'num_hsps'              => ['9', 'hit', 'num_hsps', 'd', 'HSPS'],
                  'frac_identical_query'  => ['10', 'hit', 'frac_identical/query', '.2f', 'FR_IDQ'],
                  'frac_identical_hit'    => ['11', 'hit', 'frac_identical/hit', '.2f', 'FR_IDH'],
                  'frac_conserved_query'  => ['12', 'hit', 'frac_conserved/query', '.2f', 'FR_CNQ'],
                  'frac_conserved_hit'    => ['13', 'hit', 'frac_conserved/hit', '.2f', 'FR_CNH'],
                  'frac_aligned_query'    => ['14', 'hit', 'frac_aligned_query', '.2f', 'FR_ALQ'],
                  'frac_aligned_hit'      => ['15', 'hit', 'frac_aligned_hit', '.2f', 'FR_ALH'],
                  'length_aln_query'      => ['16', 'hit', 'length_aln/query', 'd', 'LN_ALQ'],
                  'length_aln_hit'        => ['17', 'hit', 'length_aln/hit', 'd', 'LN_ALH'],
                  'gaps_query'            => ['18', 'hit', 'gaps/query', 'd', 'GAPS_Q'],
                  'gaps_hit'              => ['19', 'hit', 'gaps/hit', 'd', 'GAPS_H'],
                  'gaps_total'            => ['20', 'hit', 'gaps/total', 'd', 'GAPS_QH'],
                  'start_query'           => ['21', 'hit', 'start/query', 'd', 'START_Q'],
                  'end_query'             => ['22', 'hit', 'end/query', 'd', 'END_Q'],
                  'start_hit'             => ['23', 'hit', 'start/hit', 'd', 'START_H'],
                  'end_hit'               => ['24', 'hit', 'end/hit', 'd', 'END_H'],
                  'strand_query'          => ['25', 'hit', 'strand/query', 's', 'STRND_Q'],
                  'strand_hit'            => ['26', 'hit', 'strand/hit', 's', 'STRND_H'],
                  'frame'                 => ['27', 'hit', 'frame', 'd', 'FRAME'],
                  'ambiguous_aln'         => ['28', 'hit', 'ambiguous_aln', 's', 'AMBIG'],
                  'hit_description'       => ['29', 'hit', 'description', 's', 'DESC_H'],
                  'query_description'     => ['30', 'result', 'query_description', 's', 'DESC_Q'],
                 );

sub column_map { return %column_map }


#line 249

#----------------
sub to_string {
#----------------
    my ($self, $result, $include_labels) = @_;

    my $str = $include_labels ? $self->column_labels() : '';
    my $func_ref = $self->row_data_func;
    my $printf_fmt = $self->printf_fmt;
    
    my ($resultfilter,$hitfilter) = ( $self->filter('RESULT'),
				      $self->filter('HIT') );
    if( ! defined $resultfilter ||
        &{$resultfilter}($result) ) {
	$result->can('rewind') && 
	    $result->rewind(); # insure we're at the beginning
	foreach my $hit($result->hits) {	    
	    next if( defined $hitfilter && ! &{$hitfilter}($hit));
	    my @row_data  = map { defined $_ ? $_ : 0 } &{$func_ref}($result, $hit);
	    $str .= sprintf "$printf_fmt\n", @row_data;
	}
    }
    $str =~ s/\t\n/\n/gs;
    return $str;
}

#line 287

sub end_report {
    return '';
}


#line 304

1;
