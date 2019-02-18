package omnitool::common::excel_grinder;
# Class to handle reading & writing XLSX files.
# We will only support the more modern xlsx in OT6.  2007 is a while ago now
# 'Reading' means we convert an Excel file to a data structure --> three-level array
# 'Writing' means we take just such an array-of-arrays-of-arrays and turn it into
#	a new xlsx file

# sixth time's the charm
$omnitool::common::excel_grinder::VERSION = '6.0';

# time to grow up
use strict;

# use third-party modules to do the real work
use File::Slurp;
use Excel::Writer::XLSX;
use Spreadsheet::XLSX;

# Docs for these modules:
# http://search.cpan.org/~mikeb/Spreadsheet-XLSX-0.15/lib/Spreadsheet/XLSX.pm
# http://search.cpan.org/~jmcnamara/Excel-Writer-XLSX-0.95/lib/Excel/Writer/XLSX.pm

# constructor method
sub new {
	my $class = shift;

	# accept an arguments hash; the only argument is the %$luggage hash
	my (%args) = @_;
	# looks like:
	#	'luggage' => $luggage, # required

	# fail if no %$luggage provided
	if (!$args{luggage}{belt}->{all_hail}) {
		die(qq{Can't create an omnitool::common::excel_grinder object without my luggage.'});
	}

	my $self = bless \%args, $class;

	# ready to go
	return $self;

}

# method to convert a three-level array into a nice excel file
sub write_excel {
	my $self = shift;

	# required arguments are (1) the filename and (2) the data structure to turn into an XLSX file
	my (%args) = @_;
	# looks like:
	#	'filename' => 'some_file.xlsx', # will be saved under $ENV{OTHOME}/tmp/some_file.xlsx; required
	#	'the_data' => @$three_level_arrayref, # worksheets->rows->columns; see below; required
	#	'headings_in_data' => 1, # if filled, first row of each worksheet will be captialized; optional
	#	'worksheet_names' => ['Names','of','Worksheets'], # if filled, will be the names to give the worksheets

	my ($item, $col, @bits, $workbook, $worksheet_data, $worksheet, $n, $row_array, $row_upper, $worksheet_name);

	# fail without a filename
	if (!$args{filename}) {
		$self->{luggage}{belt}->mr_zebra('Error: Filename required for write_excel()',1);
	}

	# the data structure must be an array of arrays of arrays
	# three levels: worksheets, rows, columns
	if (!$args{the_data}[0][0][0]) {
		$self->{luggage}{belt}->mr_zebra('Error: Must send a three-level arrayref (workbook->rows->columns) to write_excel()',1);
	}

	# make sure $filename is a file.xlsx in $OTHOM/tmp
	if ($args{filename} =~ /\//) {
		(@bits) = split /\//, $args{filename};
		$args{filename} = $bits[-1];
	}
	$args{filename} = $ENV{OTHOME}.'/tmp/'.$args{filename};
	$args{filename} .= '.xlsx' if $args{filename} !~ /.xlsx$/;

	# start our workbook
	$workbook = Excel::Writer::XLSX->new( $args{filename} );

	# Set the format for dates.
	my $date_format = $workbook->add_format( num_format => 'mm/dd/yy' );

	# start adding worksheets
	foreach $worksheet_data (@{ $args{the_data} }) {
		$worksheet_name = shift @{ $args{worksheet_names} }; # if it's there
		$worksheet_name =~ s/[^0-9a-z\-\s]//gi; # clean it up
		$worksheet = $workbook->add_worksheet($worksheet_name);

		$n = 0;
		foreach $row_array (@$worksheet_data) {

			if ($args{headings_in_data} && $n == 0) { # uppercase the first row
				@$row_upper = map { uc($_) } @$row_array;
				$row_array = $row_upper;
			}

			$col = 0;
			foreach $item (@$row_array) {
				# dates are no funzies
				if ($item =~ /^(\d{4})-(\d{2})-(\d{2})$/) { # special routine for dates
					$worksheet->write_date_time( $n, $col++, $1.'-'.$2.'-'.$3.'T', $date_format );
				} else {
					 $worksheet->write( $n, $col++, $item );
				}

			}
			$n++;
		}
	}

	# that's not hard
	return $args{filename};
}

# method to import an excel file into a nice three-level array
sub read_excel {
	my ($self) = shift;

	# require argument is the full path to the excel xlsx file
	my ($full_filename) = @_;

	if (!$full_filename || !(-e "$full_filename")) {
		$self->{luggage}{belt}->mr_zebra('Error: Must send a valid full file path to an XLSX file to read_excel()',1);
	}

	my ($excel, $sheet_num, $sheet, $row_num, $row, @the_data, $cell, $col);

	# this is so easy, i basically just stole the example
	$excel = Spreadsheet::XLSX -> new ($full_filename);

	$sheet_num = 0;
	foreach $sheet (@{$excel -> {Worksheet}}) {

		# set the max = 0 if there is one or none rows
		$sheet->{MaxRow} ||= $sheet->{MinRow};

		# same for the columns
		$sheet->{MaxCol} ||= $sheet->{MinCol};

		# cycle through each row
		$row_num = 0;
		foreach $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
			# go through each available column
			foreach $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {

                # get ahold of the actual cell object
				$cell = $sheet->{Cells}[$row][$col];
				
				# next if !$cell; # skip if blank

				# add it to our nice array
				push (@{ $the_data[$sheet_num][$row] }, $cell->{Val} );
			}
			# advance
			$row_num++;
        }
		$sheet_num++;
	}

	# send it back
	return \@the_data;
}

1;

__END__

=head1 omnitool::common::excel_grinder

This library exists because Excel files are a key output and data-organization
method in Corporate America ;)

Anyhow, this is for OmniTool to be able to export data to Excel files, as
well as to convert Excel files into data structures.  That second function is
to allow for some nasty batch-update tools.  Please note that for both of these,
we are only supporting the 'modern' XLSX format.

Start it up like so, passing in a valid %$luggage hashref:

	$xlsx = omnitool::common::excel_grinder->new('luggage' => $luggage);

=head2 write_excel()

To write out an XLSX file, you will prepare a nice three-level arrayref.
The actual data is at the third level; the first two are organizational 
to represent worksheets and rows.

Here is a nice example:

	$full_file_path = $xlsx->write_excel(
		'filename' => 'ginger.xlsx',
		'headings_in_data' => 1,
		'worksheet_names' => ['Dogs','People'],
		'the_data' => [
			[
				['Name','Main Trait','Age Type'],
				['Ginger','Wonderful','Old'],
				['Pepper','Loving','Passed'],
				['Polly','Fun','Young']
			],
			[
				['Name','Main Trait','Age Type'],
				['Melanie','Smart','Oldish'],
				['Lorelei','Fun','Young'],
				['Eric','Fat','Old']
			]
		],
	);

That will create a file at $ENV{OTHOME}/tmp/ginger.xlsx .  Please use
your file_manager object if you need to save it to a proper spot.  The
$full_file_path variable is now your full path to the file on the disk.

In normal use, you'd probably prepare the arrayref beforehand and then
call like so:

	$xlsx->write_excel(
		'filename' => 'ginger.xlsx',
		'the_data' => \@my_data,
		'headings_in_data' => 1,
		'worksheet_names' => ['Dogs','People'],
	);

The 'headings_in_data' arg tells use to make each worksheet's first row
all caps to indicate those are the headings.  Fancy.  We are not exactly
stretching the use of Excel::Writer::XLSX here.

The 'worksheet_names' argument is the arrayref to the names to put on the
nice tabs for the worksheets.  Both 'worksheet_names' and 'headings_in_data'
are optional.


=head2 read_excel()

This does the exact opposite of write_excel() in that it reads in an XLSX
file and returns the arrayref in the exact same format as what write_excel()
receives.  All it needs is the absolute filepath for an XLSX file:

	$the_data = $xlsx->read_excel('/opt/omnitool/tmp/ginger.xlsx');

@$the_data will look like the structure in the example above.  Try it out ;)
