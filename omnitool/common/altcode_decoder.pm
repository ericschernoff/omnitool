package omnitool::common::altcode_decoder;
# utility package to take altcodes and return the the_type, data_code, and name
# values for that record.  Looks in the database set in the %$luggage they send;
# or can accept a 'database_name' argument

# could do all this with omniclass, but that could get pretty heavy just to
# build breadcrumbs or similiar functions for several records.

# sixth time doing this all wrong
$omnitool::common::altcode_decoder::VERSION = '6.0';

# time to grow up
use strict;

sub new {
	my $class = shift;
	
	my (%args) = @_;
	# needs at least 'luggage' for the luggage; can also provide 'db' for an 'database 
	# handle and 'database_name'; those values will be in %$luggage for you
	
	# Need to stop here if luggagenot provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an OmniClass without my luggage.'});
	}	

	# did they provide a $db? if not, use $$luggage{db}
	if (!$args{db}) {
		$args{db} = $args{luggage}{db};
	}

	# need a database object for sure
	if (!$args{db}->{created}) {
		$args{luggage}{belt}->mr_zebra(qq{Can't create an altcode_decorder without a database object.},1);
	}	
	
	# same treatment for database_name
	if (!$args{database_name}) {
		$args{database_name} = $args{luggage}{database_name};
	}
	
	# book it and cook it
	my $self = bless \%args, $class;
	return $self;
}

# utility method to fetch a potential parent string from metainfo based on altcode
# useful for tool->search(); needs the datatype of the altcode's record
sub parent_string_from_altcode {
	my $self = shift;
	my ($altcode,$datatype) = @_;	
	
	# only proceed if they provided an altcode AND a datatype
	return if !$altcode || !$datatype;

	# declare vars
	my ($parent_string,$metainfo_table);

	# use method below to get the metainfo table 
	$metainfo_table = $self->figure_metainfo_table($datatype);
	
	# should be an easy query
	if ($altcode) { # argument is required
		($parent_string) = $self->{db}->quick_select(qq{
			select concat(the_type,':',data_code) from }.
			$self->{database_name}.'.'.$metainfo_table.' where altcode=?',
		[$altcode]);
	}		

	# this 'parent_string' is really the TYPE/ID of the altcode's record, but
	# it's meant to find children of that record, hence the 'parent_string' name
	return $parent_string;
}

# for the 'find_breadcrumbs' routines in tool::html_sender, we need to resolve a record's
# altcode to its name and it's parent's altcode; needs the datatype of the altcode's record
sub name_and_parent_from_altcode {
	my $self = shift;
	my ($altcode,$datatype) = @_;	

	# only proceed if they provided an altcode AND a datatype
	return if !$altcode || !$datatype;

	# declare vars
	my ($parent_string,$table_name,$record_name,$parent_altcode, $data_code, $metainfo_table,$parent_metainfo_table, $parent_type, $parent_datacode);

	# use method below to get the metainfo table 
	$metainfo_table = $self->figure_metainfo_table($datatype);
	
	# query metainfo for my parent info, plus my record's table_name	
	($data_code,$parent_string,$table_name) = $self->{db}->quick_select(qq{
		select data_code,parent,table_name from }.
		$self->{database_name}.'.'.$metainfo_table.
		' where altcode=?',
	[$altcode]);

	# return if nothing found
	return if !$parent_string;

	# get the record's name
	($record_name) = $self->{db}->quick_select(qq{
		select name from }.$self->{database_name}.'.'.
		$table_name.qq{ where concat(code,'_',server_id)=?},
	[$data_code]);	

	# we need to get the parent's datatype's metainfo table
	($parent_type,$parent_datacode) = split /:/, $parent_string;
	# use method below to get the metainfo table 
	$parent_metainfo_table = $self->figure_metainfo_table($datatype);
	
	# and the record's parent's altcode
	($parent_altcode) = $self->{db}->quick_select(qq{
		select altcode from }.$self->{database_name}.'.'.
		$parent_metainfo_table.qq{ where concat(the_type,':',data_code)=?},
	[$parent_string]);

	# ship out that info
	return ($record_name, $parent_altcode);

}

# method to take a datatype and figure out which 'metainfo' table it uses;
# needed because many DT's will use a separate metinfo table for scaling.
sub figure_metainfo_table {
	my $self = shift;
	my ($datatype) = @_;
	
	my ($metainfo_table);
	# does this datatype have its own metainfo table?
	if ($self->{luggage}{datatypes}{$datatype}{metainfo_table} eq 'Own Table') { # set one up just for this datatype
		$metainfo_table = $self->{luggage}{datatypes}{$datatype}{table_name}.'_metainfo';
	} else { # use the main metainfo table for the database; possibly skipping if 'metainfo_table' = 'Skip Metainfo'
		$metainfo_table = 'metainfo';
	}
	
	# send it back
	return $metainfo_table;
}

1;