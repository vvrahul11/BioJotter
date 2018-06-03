#line 1 "Bio/Ontology/Term.pm"
# $Id: Term.pm,v 1.8.2.3 2003/05/27 22:00:52 lapp Exp $
#
# BioPerl module for Bio::Ontology::Term
#
# Cared for by Christian M. Zmasek <czmasek@gnf.org> or <cmzmasek@yahoo.com>
#
# (c) Christian M. Zmasek, czmasek@gnf.org, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code


#line 91


# Let the code begin...

package Bio::Ontology::Term;
use vars qw( @ISA );
use strict;
use Bio::Root::Object;
use Bio::Ontology::TermI;
use Bio::Ontology::Ontology;
use Bio::Ontology::OntologyStore;
use Bio::IdentifiableI;
use Bio::DescribableI;

use constant TRUE    => 1;
use constant FALSE   => 0;

@ISA = qw( Bio::Root::Root
           Bio::Ontology::TermI
           Bio::IdentifiableI
           Bio::DescribableI
         );



#line 136

sub new {

    my( $class,@args ) = @_;

    my $self = $class->SUPER::new( @args );

    my ( $identifier,
         $name,
         $definition,
         $category,
	 $ont,
         $version,
         $is_obsolete,
         $comment,
	 $dblinks)
	= $self->_rearrange( [ qw( IDENTIFIER
				   NAME
				   DEFINITION
				   CATEGORY
                                   ONTOLOGY
				   VERSION
				   IS_OBSOLETE
				   COMMENT
                                   DBLINKS
                                 ) ], @args );

    $self->init();

    $identifier            && $self->identifier( $identifier );
    $name                  && $self->name( $name );
    $definition            && $self->definition( $definition );
    $category              && $self->category( $category );
    $ont                   && $self->ontology( $ont );
    defined($version)      && $self->version( $version );
    defined($is_obsolete)  && $self->is_obsolete( $is_obsolete );
    $comment               && $self->comment( $comment  );
    ref($dblinks)          && $self->add_dblink(@$dblinks);

    return $self;

} # new



sub init {

    my $self = shift;

    $self->identifier(undef);
    $self->name(undef);
    $self->comment(undef);
    $self->definition(undef);
    $self->ontology(undef);
    $self->is_obsolete(0);
    $self->remove_synonyms();
    $self->remove_dblinks();
    $self->remove_secondary_ids();

} # init



#line 210

sub identifier {
    my $self = shift;

    return $self->{'identifier'} = shift if @_;
    return $self->{'identifier'};
} # identifier




#line 232

sub name {
    my $self = shift;

    return $self->{'name'} = shift if @_;
    return $self->{'name'};
} # name





#line 255

sub definition {
    my $self = shift;

    return $self->{'definition'} = shift if @_;
    return $self->{'definition'};
} # definition


#line 281

sub ontology {
    my $self = shift;
    my $ont;

    if(@_) {
	$ont = shift;
	if($ont) {
	    $ont = Bio::Ontology::Ontology->new(-name => $ont) if ! ref($ont);
	    if(! $ont->isa("Bio::Ontology::OntologyI")) {
		$self->throw(ref($ont)." does not implement ".
			     "Bio::Ontology::OntologyI. Bummer.");
	    }
	}
	return $self->{"_ontology"} = $ont;
    }
    return $self->{"_ontology"};
} # ontology


#line 312

sub version {
    my $self = shift;

    return $self->{'version'} = shift if @_;
    return $self->{'version'};
} # version



#line 333

sub is_obsolete{
    my $self = shift;

    return $self->{'is_obsolete'} = shift if @_;
    return $self->{'is_obsolete'};
} # is_obsolete





#line 356

sub comment{
    my $self = shift;

    return $self->{'comment'} = shift if @_;
    return $self->{'comment'};
} # comment




#line 376

sub get_synonyms {
    my $self = shift;

    return @{ $self->{ "_synonyms" } } if exists($self->{ "_synonyms" });
    return ();
} # get_synonyms


#line 396

sub add_synonym {
    my ( $self, @values ) = @_;

    return unless( @values );

    # avoid duplicates
    foreach my $syn (@values) {
	next if grep { $_ eq $syn; } @{$self->{ "_synonyms" }};
	push( @{ $self->{ "_synonyms" } }, $syn );
    }

} # add_synonym


#line 420

sub remove_synonyms {
    my ( $self ) = @_;

    my @a = $self->get_synonyms();
    $self->{ "_synonyms" } = [];
    return @a;

} # remove_synonyms

#line 439

sub get_dblinks {
    my $self = shift;

    return @{$self->{ "_dblinks" }} if exists($self->{ "_dblinks" });
    return ();
} # get_dblinks


#line 460

sub add_dblink {
    my ( $self, @values ) = @_;

    return unless( @values );

    # avoid duplicates
    foreach my $dbl (@values) {
	next if grep { $_ eq $dbl; } @{$self->{ "_dblinks" }};
	push( @{ $self->{ "_dblinks" } }, $dbl );
    }

} # add_dblink


#line 484

sub remove_dblinks {
    my ( $self ) = @_;

    my @a = $self->get_dblinks();
    $self->{ "_dblinks" } = [];
    return @a;

} # remove_dblinks

#line 507

sub get_secondary_ids {
    my $self = shift;

    return @{$self->{"_secondary_ids"}} if exists($self->{"_secondary_ids"});
    return ();
} # get_secondary_ids


#line 527

sub add_secondary_id {
    my $self = shift;

    return unless @_;

    # avoid duplicates
    foreach my $id (@_) {
	next if grep { $_ eq $id; } @{$self->{ "_secondary_ids" }};
	push( @{ $self->{ "_secondary_ids" } }, $id );
    }

} # add_secondary_id


#line 551

sub remove_secondary_ids {
    my $self = shift;

    my @a = $self->get_secondary_ids();
    $self->{ "_secondary_ids" } = [];
    return @a;

} # remove_secondary_ids


# Title   :_is_true_or_false
# Function: Checks whether the argument is TRUE or FALSE.
# Returns :
# Args    : The value to be checked.
sub _is_true_or_false {
    my ( $self, $value ) = @_;
    unless ( $value !~ /\D/ && ( $value == TRUE || $value == FALSE ) ) {
        $self->throw( "Found [" . $value
        . "] where " . TRUE . " or " . FALSE . " expected" );
    }
} # _is_true_or_false

#line 577

#line 590

sub object_id {
    return shift->identifier(@_);
}

#line 611

sub authority {
    my $self = shift;
    my $ont = $self->ontology();

    return $ont->authority(@_) if $ont;
    $self->throw("cannot manipulate authority prior to ".
		 "setting the namespace or ontology") if @_;
    return undef;
}


#line 640

sub namespace {
    my $self = shift;

    $self->ontology(@_) if(@_);
    my $ont = $self->ontology();
    return defined($ont) ? $ont->name() : undef;
}

#line 664

sub display_name {
    return shift->name(@_);
}


#line 688

sub description {
    return shift->definition(@_);
}

#################################################################
# aliases or forwards to maintain backward compatibility
#################################################################

#line 702

#line 714

sub category {
    my $self = shift;

    $self->warn("TermI::category is deprecated and being phased out. ".
		"Use TermI::ontology instead.");

    # called in set mode?
    if(@_) {
	# yes; what is incompatible with ontology() is if we were given
	# a TermI object
	my $arg = shift;
	$arg = $arg->name() if ref($arg) && $arg->isa("Bio::Ontology::TermI");
	return $self->ontology($arg,@_);
    } else {
	# No, called in get mode. This is always incompatible with ontology()
	# since category is supposed to return a TermI.
	my $ont = $self->ontology();
	my $term;
	if(defined($ont)) {
	    $term = Bio::Ontology::Term->new(-name => $ont->name(),
					     -identifier =>$ont->identifier());
	}
	return $term;
    }
} # category

*each_synonym = \&get_synonyms;
*add_synonyms = \&add_synonym;
*each_dblink = \&get_dblinks;
*add_dblinks = \&add_dblink;

1;
