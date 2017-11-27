#!perl
###
# Script to help folks upgrade their 'omnitool' main sysadamin database.
# Attempts to preserve their instances, db servers, users, access, roles, and api keys.
###

use strict;
use warnings;
use IO::Prompter;

my ($can_continue, $bkup_directory, $backup_filename, $filename, $mysql_host, $mysql_password, $mysql_user, $table, $schema_file, $ot_root_dir);

# this script needs to be run as root, just in case the directories are locked-down
if ($ENV{USER} ne 'root') {
	die(qq{ERROR: This script needs to be run as 'root' or via sudo.});
}

# explain what this is for
print qq{

USE THIS SCRIPT TO UPDATE YOUR 'OMNITOOL' DATABASE WITH A NEWER VERSION

The OmniTool Admin Web UI allows you to maintain your Datatypes, Tools, Users and other behaviors
for your custom applications.  The main 'omnitool' database is where the behavior of the OmniTool
Admin Web UI is configured. This 'omnitool' DB should only be modified by the owner of the main
OmniTool code repo (currently https://github.com/ericschernoff/omnitool ). You can add Instances,
Users, Access Roles, and API keys to your copy of the 'omnitool' database, but any other changes will
render your version incompatible with future releases of OmniTool.  Please send any change
requests/suggestions to the code maintainer via https://www.omnitool.org/#/tools/contact_form .

This script attempts to safely upgrade/sync your 'omnitool' database to the version provided at
/distribution/schema/omnitool.sql  under your OmniTool root directory.  It will try to preserve any
custom Instances, Database Servers, Users, Access Roles  and API Keys.  Just in case, it will attempt
to make a backup via 'mysqldump' prior to any changes.

This only affects the primary OmniTool Admin database.  Your custom OmniTool Admin instances will
not be affected.

Reminder: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. (From the MIT license).

};

# Verify that they want to continue
$can_continue = prompt "Type 'yes' if wish to continue and upgrade your 'omnitool' database?", -yes;
if (!$can_continue) {
	print "Process canceled.\n";
	exit;
}


# retrieve the required options
$ot_root_dir = prompt 'OmniTool Root Directory [/opt/omnitool/]', -v;
	$ot_root_dir ||= '/opt/omnitool/';

$bkup_directory = prompt 'Backup Directory to Place Files [/opt/omnitool/tmp/]', -v;
	$bkup_directory ||= '/opt/omnitool/tmp/';

$mysql_host = prompt 'MySQL Host [127.0.0.1]', -v;
	$mysql_host ||= '127.0.0.1';

$mysql_user = prompt 'MySQL User [root]', -v;
	$mysql_user ||= 'root';

# the password is really required
$mysql_password = prompt 'MySQL Password (Required)', -v, -echo=>'*';
if (!length($mysql_password)) {
	die(qq{ERROR: You must provide a password to access the MySQL Database.});
}

# first off, save the a backup of the current database
print qq{
---
Backing up your current 'omnitool' dataabse.
};
#     0    1    2     3     4    5     6     7     8
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$backup_filename = $bkup_directory.'/omnitool-'.$mon.'-'.$mday.'-'.$year.'.sql';
system("mysqldump -t -u$mysql_user -p$mysql_password -h$mysql_host omnitool -r $backup_filename");

# OK, try to preserve the following datatypes / tables.
foreach $table ('access_roles','database_servers','instances','omnitool_users','user_api_keys','user_api_keys_metainfo') {
	$filename = $bkup_directory.'/'.$table.'.sql';
	system("mysqldump -t -u$mysql_user -p$mysql_password -h$mysql_host --replace omnitool $table -r $filename");
}

# stash out the affected metainfo records as well
print qq{
---
Saving a copy of your custom data.
};
$filename = $bkup_directory.'/metainfo_saves.sql';
system(qq{mysqldump -t -u$mysql_user -p$mysql_password -h$mysql_host --replace omnitool metainfo --where="the_type in ('4_1','5_1','9_1','12_1','18_1')" -r $filename});

# now load in the new omnitool database
print qq{
---
Loading in the new 'omnitool' database.
};
$schema_file = $ot_root_dir.'/distribution/schema/omnitool.sql';
system(qq{mysql -u$mysql_user -p$mysql_password -h$mysql_host omnitool < $schema_file});

# and bring back in the bits we just archived
print qq{
---
Loading in your custom data.
};
foreach $table ('access_roles','database_servers','instances','omnitool_users','user_api_keys','user_api_keys_metainfo','metainfo_saves') {
	$filename = $bkup_directory.'/'.$table.'.sql';
	system("mysql -u$mysql_user -p$mysql_password -h$mysql_host omnitool < $filename");
	unlink $filename;
}

# report what we did for the user
print qq{
---
PROCESS COMPLETE

Your 'omnitool' database should now be upgraded with the latest info from the OmniTool code repository.  We attempted
to preserve your custom Instances, Database Servers, Users, Access Roles and API Keys.

A copy of the pre-upgrade 'omnitool' database was saved to $backup_filename -- please put that somewhere safe in case
you run into any problems.

Reminder:  This only affects the main 'omnitool' database, which controls the OmniTool Admin application instances.
Your local 'omnitool_*' databases were not affected.

};

exit;

