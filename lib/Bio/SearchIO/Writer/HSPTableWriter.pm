#line 1 "Bio/SearchIO/Writer/HSPTableWriter.pm"
# $Id: HSPTableWriter.pm,v 1.12 2002/11/23 15:32:24 jason Exp $

#line 162

package Bio::SearchIO::Writer::HSPTableWriter;

use strict;
use Bio::SearchIO::Writer::ResultTableWriter;

use vars qw( @ISA );
@ISA = qw( Bio::SearchIO::Writer::ResultTableWriter );


# Array fields: column, object, method[/argument], printf format, column label
# Methods for result object are defined in Bio::Search::Result::ResultI.
# Methods for hit object are defined in Bio::Search::Hit::HitI.
# Methods for hsp object are defined in Bio::Search::HSP::HSPI.
# Tech note: If a bogus method is supplied, it will result in all values to be zero.
#            Don't know why this is.
# TODO (maybe): Allow specification of signif_format (i.e., separate mantissa/exponent)
my %column_map = (
                  'query_name'            => ['1', 'result', 'query_name', 's', 'QUERY' ],
                  'query_length'          => ['2', 'result', 'query_length', 'd', 'LEN_Q'],
                  'hit_name'              => ['3', 'hit', 'name', 's', 'HIT'],
                  'hit_length'            => ['4', 'hit', 'hit_length', 'd', 'LEN_H'],
                  'round'                 => ['5', 'hit', 'iteration', 'd', 'ROUND', 'hit'],
                  'rank'                  => ['6', 'hsp', 'rank', 'd', 'RANK'],
                  'expect'                => ['7', 'hsp', 'expect', '.1e', 'EXPCT'],
                  'score'                 => ['8', 'hsp', 'score', 'd', 'SCORE'],
                  'bits'                  => ['9', 'hsp', 'bits', 'd', 'BITS'],
                  'frac_identical_query'  => ['10', 'hsp', 'frac_identical/query', '.2f', 'FR_IDQ'],
                  'frac_identical_hit'    => ['11', 'hsp', 'frac_identical/hit', '.2f', 'FR_IDH'],
                  'frac_conserved_query'  => ['12', 'hsp', 'frac_conserved/query', '.2f', 'FR_CNQ'],
                  'frac_conserved_hit'    => ['13', 'hsp', 'frac_conserved/hit', '.2f', 'FR_CNH'],
                  'length_aln_query'      => ['14', 'hsp', 'length/query', 'd', 'LN_ALQ'],
                  'length_aln_hit'        => ['15', 'hsp', 'length/hit', 'd', 'LN_ALH'],
                  'gaps_query'            => ['16', 'hsp', 'gaps/query', 'd', 'GAPS_Q'],
                  'gaps_hit'              => ['17', 'hsp', 'gaps/hit', 'd', 'GAPS_H'],
                  'gaps_total'            => ['18', 'hsp', 'gaps/total', 'd', 'GAPS_QH'],
                  'start_query'           => ['19', 'hsp', 'start/query', 'd', 'START_Q'],
                  'end_query'             => ['20', 'hsp', 'end/query', 'd', 'END_Q'],
                  'start_hit'             => ['21', 'hsp', 'start/hit', 'd', 'START_H'],
                  'end_hit'               => ['22', 'hsp', 'end/hit', 'd', 'END_H'],
                  'strand_query'          => ['23', 'hsp', 'strand/query', 'd', 'STRND_Q'],
                  'strand_hit'            => ['24', 'hsp', 'strand/hit', 'd', 'STRND_H'],
                  'frame'                 => ['25', 'hsp', 'frame', 's', 'FRAME'],
                  'hit_description'       => ['26', 'hit', 'hit_description', 's', 'DESC_H'],
                  'query_description'     => ['27', 'result', 'query_description', 's', 'DESC_Q'],
                 );

sub column_map { return %column_map }


#line 232

sub to_string {
    my ($self, $result, $include_labels) = @_;
    
    my $str = $include_labels ? $self->column_labels() : '';
    my ($resultfilter,$hitfilter,
	$hspfilter) = ( $self->filter('RESULT'),
			$self->filter('HIT'),
			$self->filter('HSP'));
    if( ! defined $resultfilter || &{$resultfilter}($result) ) {
	my $func_ref = $self->row_data_func;
	my $printf_fmt = $self->printf_fmt;
	$result->can('rewind') && 
	    $result->rewind(); # insure we're at the beginning
	while( my $hit = $result->next_hit) {
	    next if( defined $hitfilter && ! &{$hitfilter}($hit) );
	    $hit->can('rewind') && $hit->rewind;# insure we're at the beginning
	    while(my $hsp = $hit->next_hsp) {
		next if ( defined $hspfilter && ! &{$hspfilter}($hsp));
		my @row_data  = &{$func_ref}($result, $hit, $hsp);
		$str .= sprintf "$printf_fmt\n", @row_data;
	    }
	}
    }
    $str =~ s/\t\n/\n/gs;
    return $str;
}

#line 272

sub end_report {
    return '';
}

#line 288


1;
