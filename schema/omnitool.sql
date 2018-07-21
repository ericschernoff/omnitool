-- MySQL dump 10.13  Distrib 5.7.22, for Linux (x86_64)
--
-- Host: localhost    Database: omnitool
-- ------------------------------------------------------
-- Server version	5.7.22-0ubuntu18.04.1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `access_roles`
--

DROP TABLE IF EXISTS `access_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access_roles` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `description` mediumtext,
  `username_list` mediumtext,
  `status` varchar(8) DEFAULT NULL,
  `used_in_applications` text,
  `match_hash_key` varchar(100) DEFAULT NULL,
  `match_operator` varchar(100) DEFAULT NULL,
  `match_value` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `access_roles`
--

LOCK TABLES `access_roles` WRITE;
/*!40000 ALTER TABLE `access_roles` DISABLE KEYS */;
INSERT INTO `access_roles` VALUES (1,1,'top','OmniTool Admin','Reserved for system / tools administrators. ',NULL,'Active','1_1','omnitool_admins','Equals','1');
/*!40000 ALTER TABLE `access_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `applications`
--

DROP TABLE IF EXISTS `applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `applications` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `contact_email` varchar(100) DEFAULT NULL,
  `description` text NOT NULL,
  `status` varchar(12) NOT NULL DEFAULT '',
  `ui_template` varchar(40) DEFAULT 'default.tt',
  `app_code_directory` varchar(60) NOT NULL DEFAULT 'None',
  `lock_lifetime` varchar(12) DEFAULT NULL,
  `share_my_datatypes` varchar(100) DEFAULT NULL,
  `appwide_search_function` varchar(100) DEFAULT NULL,
  `appwide_search_name` varchar(100) DEFAULT NULL,
  `appwide_quickstart_tool_uri` varchar(100) DEFAULT NULL,
  `ui_navigation_placement` varchar(15) DEFAULT NULL,
  `ui_ace_skin` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `applications`
--

LOCK TABLES `applications` WRITE;
/*!40000 ALTER TABLE `applications` DISABLE KEYS */;
INSERT INTO `applications` VALUES (1,1,'top','OmniTool Admin','ericschernoff@gmail.com','Administrative Bits for OmniTool 6','Active','default.tt','otadmin','10','None','None','None','None','Left Side','Skin 1');
/*!40000 ALTER TABLE `applications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `background_tasks`
--

DROP TABLE IF EXISTS `background_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `background_tasks` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `create_time` int(11) unsigned NOT NULL,
  `update_time` int(11) unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `run_seconds` int(11) DEFAULT NULL,
  `username` varchar(30) DEFAULT NULL,
  `error_message` varchar(1000) DEFAULT NULL,
  `not_before_time` int(11) unsigned NOT NULL,
  `target_datatype` varchar(30) NOT NULL,
  `method` varchar(50) NOT NULL,
  `data_code` varchar(30) DEFAULT NULL,
  `altcode` varchar(50) DEFAULT NULL,
  `args_hash` text,
  `process_pid` int(8) unsigned DEFAULT NULL,
  `worker_id` int(3) unsigned DEFAULT '1',
  `auto_retried` int(1) DEFAULT '0',
  PRIMARY KEY (`code`,`server_id`),
  KEY `status` (`status`,`not_before_time`,`target_datatype`),
  KEY `target_datatype` (`target_datatype`),
  KEY `not_before_time` (`not_before_time`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `background_tasks`
--

LOCK TABLES `background_tasks` WRITE;
/*!40000 ALTER TABLE `background_tasks` DISABLE KEYS */;
INSERT INTO `background_tasks` VALUES (1,1,1477974601,1482554279,'Retry',NULL,'echernof',NULL,1477974601,'5_1','daily_routines','7_1','Mar16eric_instances7','None',NULL,1,0);
/*!40000 ALTER TABLE `background_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `base_table`
--

DROP TABLE IF EXISTS `base_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `base_table` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `base_table`
--

LOCK TABLES `base_table` WRITE;
/*!40000 ALTER TABLE `base_table` DISABLE KEYS */;
/*!40000 ALTER TABLE `base_table` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `database_servers`
--

DROP TABLE IF EXISTS `database_servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `database_servers` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL,
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `hostname` varchar(150) NOT NULL DEFAULT '127.0.0.1',
  `status` varchar(12) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `database_servers`
--

LOCK TABLES `database_servers` WRITE;
/*!40000 ALTER TABLE `database_servers` DISABLE KEYS */;
INSERT INTO `database_servers` VALUES (1,1,'10_1:1_1','Development Database','127.0.0.1','Active'),(2,1,'top','Production Database','127.0.0.1','Active');
/*!40000 ALTER TABLE `database_servers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `datatype_fields`
--

DROP TABLE IF EXISTS `datatype_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datatype_fields` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `table_column` varchar(40) NOT NULL,
  `field_type` varchar(40) NOT NULL DEFAULT 'short_text',
  `priority` int(3) unsigned DEFAULT '1',
  `is_required` enum('No','Yes') NOT NULL DEFAULT 'No',
  `max_length` int(4) unsigned NOT NULL DEFAULT '30',
  `instructions` text,
  `default_value` varchar(200) DEFAULT NULL,
  `option_values` text,
  `force_alphanumeric` enum('No','Yes') DEFAULT 'No',
  `virtual_field` enum('No','Yes') DEFAULT 'No',
  `sort_column` varchar(40) DEFAULT NULL,
  `search_tool_heading` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatype_fields`
--

LOCK TABLES `datatype_fields` WRITE;
/*!40000 ALTER TABLE `datatype_fields` DISABLE KEYS */;
INSERT INTO `datatype_fields` VALUES (4,1,'6_1:1_1','Contact Email','contact_email','email_address',6,'Yes',100,'Should be for subject-matter expert / developer(s) of this Application.  Instances will have contact emails for users to contact for support.',NULL,NULL,'No','No',NULL,NULL),(5,1,'6_1:1_1','Description','description','long_text',7,'Yes',100,'Will be added to the HTML meta tags; also available in API mode.',NULL,NULL,'No','No',NULL,NULL),(6,1,'6_1:1_1','Data-Lock Lifetime','lock_lifetime','single_select',9,'No',12,'Application-wide default for data locks, in minutes.  Overridden in the Tool create/update forms.','Active','0,5,10,20,30','No','No',NULL,NULL),(7,1,'6_1:5_1','Hostname','hostname','short_text',2,'Yes',250,'FQDN, i.e. host.domain.com. Must be configured in your web server as an SSL-only virtual host.',NULL,NULL,'No','No',NULL,NULL),(8,1,'6_1:5_1','Database Server','database_server_id','single_select',6,'No',30,'Be sure to use the \'Setup MySQL Tables\' tool to manage the database for this Instance.','1',NULL,'No','No',NULL,NULL),(9,1,'6_1:5_1','MySQL Database Name','database_name','short_text_clean',7,'Yes',50,'Be sure this is unique between Applications!  Can be shared between Instances, but that will cause them share data.  Useful when creating a multi-app-server Instance.',NULL,NULL,'No','No',NULL,NULL),(10,1,'6_1:5_1','Status','status','active_status_select',1,'No',12,'Must be set to \'Active\' to be usable.','Active',NULL,'No','No',NULL,NULL),(12,1,'6_1:5_1','Required Access Roles','access_roles','access_roles_select',9,'No',100,'Use to require membership in Access Roles within this Instance in order to load the Instance\'s UI; must still have required Access Roles for Tools.  Set to \'Open\' if you want at least one top-level Tool to be open to all users.',NULL,NULL,'No','No',NULL,NULL),(13,1,'6_1:5_1','Contact Email','contact_email','email_address',4,'Yes',100,'Used for error messages; best if it points to a support team address for larger Applications.',NULL,NULL,'No','No',NULL,NULL),(14,1,'6_1:5_1','Description','description','long_text',5,'No',100,'Use to override Description field in parent Application.',NULL,NULL,'No','No',NULL,NULL),(15,1,'6_1:4_1','Hostname / IP Address','hostname','short_text',2,'Yes',150,'Be sure it is reachable from all Plack servers. Should be unique among other Database Server records.',NULL,NULL,'No','No',NULL,NULL),(16,1,'6_1:4_1','Status','status','active_status_select',1,'No',12,'Must be Active to be usable.','Active',NULL,'No','No',NULL,NULL),(18,1,'6_1:8_1','URI Path Segment','uri_path_base','short_text_clean',1,'No',200,'One-word or very-short lowercase phrase for this Tool.  Works with Tool \'location\' to build URIs. Underscores are OK. Take care to create unique URI\'s.',NULL,NULL,'No','No',NULL,NULL),(19,1,'6_1:8_1','Tool.pm Sub-Class','perl_module','single_select',2,'Yes',200,'Must exist under omnitool::applications::APP_CODE_DIRECTORY::tools .  See docs in tool.pm for capabilities.  Use \'Get Sub-Class\' in Manage Tools to generate a starter/example sub-class.','None',NULL,'Yes','No',NULL,NULL),(20,1,'6_1:8_1','Access Roles','access_roles','access_roles_select',18,'No',0,NULL,'','','Yes','No',NULL,NULL),(21,1,'6_1:8_1','Description','description','long_text',15,'No',100,'Useful for API mode and in Tool catalogs.',NULL,NULL,'Yes','No',NULL,NULL),(28,1,'6_1:6_1','MySQL Table Name','table_name','short_text_clean',1,'Yes',60,'Contains the records for this Datatype.  Make sure its unique for this Application.',NULL,NULL,'No','No',NULL,NULL),(30,1,'6_1:6_1','Can-Contain Datatypes','containable_datatypes','multi_select_plain',2,'No',100,'Allows Datatypes to be used when creating children for this Datatype.  Be sure to keep accurate.',NULL,NULL,'No','No',NULL,NULL),(31,1,'6_1:6_1','Package (Supporting) Module','perl_module','single_select',3,'No',100,'Looks in omnitool::applications::APP_CODE_DIR::datatypes.  Use \'Get Sub-Class\' under Manage Datatypes to generate starter OmniClass sub-class modules.',NULL,NULL,'No','No',NULL,NULL),(32,1,'6_1:6_1','Description / Form Instructions','description','long_text',4,'No',100,'Will appear at the top of create/update forms.',NULL,NULL,'No','No',NULL,NULL),(33,1,'6_1:6_1','Metainfo Table','metainfo_table','single_select',5,'Yes',20,'Every record has \'metainfo\' to track parent/child data, create/update times, and lock status.  Most Datatypes can share the Instance Database-wide table (\'DB Table\'), but you can scale your Application by selecting \'Own Table\' to separate metainfo for Datatypes which will have many records.  Changing this option requires that you move existing records BEFORE creating new records to avoid primary key problems.','Own Table','DB Table,Own Table,No Metainfo','No','No',NULL,NULL),(34,1,'6_1:6_1','Show Name Field','show_name','yes_no_select',10,'No',3,'Determines if \'Name\' field is shown for the create/update forms.  If \'Yes,\' Name field is the first field displayed and is a required field.','Yes',NULL,'No','No',NULL,NULL),(35,1,'6_1:6_1','Log Change History','extended_change_history','yes_no_select',12,'No',3,'If \'Yes,\' changes will be logged to the Instance Database\'s standard \'update_history\' table.  Use for only the most important Datatypes.','No',NULL,'No','No',NULL,NULL),(36,1,'6_1:6_1','Archive Deleted Records','archive_deletes','yes_no_select',13,'No',3,'If \'Yes,\' deleted records will be saved into the Instance Database\'s standard \'deleted_data\' table for possible restore.  Use for only the most important data, and utilize an alternative method for Datatypes which will have many records.','No',NULL,'No','No',NULL,NULL),(37,1,'6_1:7_1','Field Type','field_type','single_select',1,'No',40,'Represent field behaviors in OmniClass\'s form_maker.pm module along with the \'form_elements.tt\' system-wide Jemplate, as well as the type of database column..  ** Only one \'rich_long_text\' per Datatype! **','short_text','access_roles_select,active_status_select,check_boxes,color_picker,email_address,file_upload,font_awesome_select,hidden_field,high_decimal,high_integer,long_text,low_decimal,low_integer,month_name,multi_select_ordered,multi_select_plain,password,phone_number,radio_buttons,rich_long_text,short_text,short_text_clean,short_text_encrypted,short_text_autocomplete,short_text_tags,simple_date,single_select,street_address,web_url,yes_no_select','No','No',NULL,NULL),(38,1,'6_1:7_1','MySQL Table Column','table_column','short_text_clean',2,'Yes',40,'Be sure to use  \'Setup MySQL Tables\' under Manage Instances to alter tables for new columns.',NULL,NULL,'Yes','No',NULL,NULL),(39,1,'6_1:7_1','Display Priority','priority','low_integer',3,'No',3,'Numeric/sortable value.','1',NULL,'No','No',NULL,NULL),(40,1,'6_1:7_1','Field is Required','is_required','yes_no_select',4,'No',3,'If set to \'Yes,\' create/update forms will not pass validation if blank values are sent.','No',NULL,'No','No',NULL,NULL),(41,1,'6_1:7_1','Force Value to Alphanumeric','force_alphanumeric','yes_no_select',5,'No',3,'If set to \'Yes,\' field can only accept letters, numbers, dashes, and underscores; all other characters will be ignored.',NULL,NULL,'No','No',NULL,NULL),(42,1,'6_1:7_1','Maximum Field Length','max_length','high_integer',6,'No',4,'For simple text fields.','100',NULL,'No','No',NULL,NULL),(43,1,'6_1:7_1','Field Instructions','instructions','long_text',7,'No',100,'Will appear below the field in create/update forms.',NULL,NULL,'No','No',NULL,NULL),(44,1,'6_1:7_1','Default Value','default_value','short_text',8,'No',200,'Used for \'create\' forms.',NULL,NULL,'No','No',NULL,NULL),(45,1,'6_1:7_1','Option Values','option_values','long_text',9,'No',100,'Options for single-/multi-selects, checkboxes, and radio buttons.  Can be a comma-separated list of values or a series of name=value pairs on separate lines.  Also, to use a related set of OmniClass records, specify \'table_name.display_field\'.  That will present options with values of the foreign records\' data_codes and then the display field for the options names -- loads all of the foreign records.  Use \'options_FIELD_NAME\' hook for more complex options preparation.',NULL,NULL,'No','No',NULL,NULL),(46,1,'6_1:9_1','Username','username','short_text',1,'Yes',25,'AKA the \'login\'.',NULL,NULL,'No','No',NULL,NULL),(47,1,'6_1:9_1','Password','password','password',2,'No',250,'Leave blank to keep previous value on update.  Can not be retrieved.',NULL,NULL,'No','No',NULL,NULL),(49,1,'6_1:12_1','Description','description','long_text',1,'No',0,NULL,'','','No','No',NULL,NULL),(51,1,'6_1:8_1','Keep Warm While in Background','keep_warm','single_select',28,'No',8,'If \'Yes,\' the DIV for this Tool will be kept in memory when not displayed, for quick loading upon return to the Tool.  Use sparingly, only for most important Tools.','No','No,Yes,Never','Yes','No',NULL,NULL),(52,1,'6_1:8_1','Icon Glyph (Font Awesome)','icon_fa_glyph','font_awesome_select',8,'Yes',100,'Used in navigation menus.','fa-wrench',NULL,'Yes','No',NULL,NULL),(53,1,'6_1:1_1','Application\'s Custom Code Base Directory','app_code_directory','single_select',2,'No',60,'Should exist under $OTHOME/code/omnitool/applications and contain four subdirectories:  \'datatypes\' for OmniClass sub-classes, \'tools\' for Tool.pm sub-classes, \'javascript\' for Tools\' custom JS classes, and \'jemplates\' for Tools\' custom Jemplate files.','None',NULL,'No','No',NULL,NULL),(56,1,'6_1:8_1','Priority','priority','low_integer',9,'Yes',3,'Sets display order for this Tool\'s link in navigation menus.  Best to set in bulk via \'Order Tools.\'','1',NULL,'Yes','No',NULL,NULL),(57,1,'6_1:8_1','Button Name','button_name','short_text',6,'Yes',20,'Short name for Tool to display in navigation links. Limit 15 characters.',NULL,NULL,'Yes','No',NULL,NULL),(58,1,'6_1:13_1','Mode Type','mode_type','single_select',1,'No',50,'Directly relates to Jemplate template to use.  Displayed options are the Jemplate files from omnitool::static_files::tool_mode_templates; select \'Custom\' to use a specific Jemplate in your Application\'s code directory.  If you choose \'Complex_Details_Plus_Form\' for a \'standard_actions\' Tool, then please be sure that the parent object\'s OmniClass package has a view_details() subroutine.','Table',NULL,'No','No',NULL,NULL),(59,1,'6_1:13_1','Custom Type Name','custom_type_name','short_text',2,'No',35,'If using a Custom Template, the name of the Tool Mode to display in the Change Mode menu.',NULL,NULL,'Yes','No',NULL,NULL),(61,1,'6_1:13_1','Display Priority','priority','low_integer',4,'No',3,'Sets the order in which the Tool Mode will be displayed in the Change Mode menu; first Mode by priority will be the default display.','No',NULL,'No','No',NULL,NULL),(62,1,'6_1:13_1','Fields to Include','fields_to_include','multi_select_ordered',7,'No',3,'For Search Tools only; indicates Datatype Fields which will be utilized in the Search Results.',NULL,NULL,'No','No',NULL,NULL),(63,1,'6_1:13_1','Default Sort Field','default_sort_column','single_select',8,'No',3,'For Search Tools only, and primarily relates to Table View.','No',NULL,'No','No',NULL,NULL),(64,1,'6_1:13_1','Default Display Order Direction','default_sort_direction','single_select',9,'No',12,'For Search Tools only, and relates to Default Sort Field.','Ascending','Ascending,Descending','No','No',NULL,NULL),(65,1,'6_1:13_1','Access Roles','access_roles','access_roles_select',11,'No',3,NULL,'0','','No','No',NULL,NULL),(67,1,'6_1:14_1','Match Field','match_field','single_select',2,'No',50,'Checks after all virtual field hooks completed.',NULL,NULL,'No','No',NULL,NULL),(68,1,'6_1:14_1','Match Type','match_type','single_select',3,'No',30,NULL,'Does Match','Does Match,Does NOT Match','No','No',NULL,NULL),(69,1,'6_1:14_1','Match String','match_string','short_text',4,'No',150,'Will be evaluated via a case-insensitive regex, so Perl regular expression syntax is OK.',NULL,NULL,'No','No',NULL,NULL),(70,1,'6_1:14_1','Apply Color','apply_color','color_picker',5,'No',40,'Will be loaded into {record_color} key in {metainfo} hash for this record, if rule matches.','99ffcc','ffffff=White\nffcccc=Red\nffffcc=Yello\n99ffcc=Green\nbddfed=Blue\nc2c2c2=Silver','No','No',NULL,NULL),(71,1,'6_1:14_1','Priority','priority','low_integer',6,'No',2,'Numeric value to determine order of evaluation; stops after the first match, so set to low number for higher priority.','1',NULL,'No','No',NULL,NULL),(72,1,'6_1:15_1','Match Against DB Column','applies_to_table_column','short_text',2,'No',200,'Enter the database column name if matching a column in the Target Datatype\'s database name. If matching a foreign table, also use \'Matches\' Relationship to Tool Datatype\' to designate the column to search against. Not used for Keyword fields.',NULL,NULL,'No','No',NULL,NULL),(73,1,'6_1:15_1','Matches\' Relationship to Tool Datatype','matches_relate_to_tool_dt','short_text',4,'No',200,'Use \'Direct\' for searches which match against a column in the Target Datatype\'s database table; otherwise use \'database_name.table_name.column_name\' notation for foreign-key relationships','Direct',NULL,'No','No',NULL,NULL),(74,1,'6_1:15_1','Menu Type','menu_type','single_select',5,'No',20,'Only \'Single-Select\' and \'Month Chooser\' menus allowed in the Quick Search area; all others must be displayed in the Advanced Search modal.  Multiple keyword fields are encouraged to let folks search against multiple specific fields.   If using \'Month Chooser,\' specify \'MonthsBack,MonthsForward\' like \'24,12\' in \'Menu Options List\' field below, and then set a column named with \'time\' or \'date\' in \'Match Against DB Column\'.','Single-Select','Single-Select,Month Chooser,Multi-Select,Keyword,Date Range,Keyword Tags','No','No',NULL,NULL),(75,1,'6_1:15_1','Menu Options Type','menu_options_type','single_select',8,'No',50,'Provide comma-separated or name/value in the \'Menu Options List\' field below; the method name should go into \'Custom Options Method\', and if using \'SQL Command\' (not recommended, use \'SQL Command\' and \'SQL Bind Values\' below. ','Comma-Separated List','Comma-Separated List,Name/Value Pairs,Method,SQL Command,Relationship','No','No',NULL,NULL),(76,1,'6_1:15_1','Menu Options List','menu_options','long_text',10,'No',40,'Use when \'Menu Options Type\' is set to \'Comma-Separated List\' or \'Name/Value Pairs\'.  For comma-separated options, do not add spaces around the columns and only use columns for separation.  For name/value pairs, enter each pair on a separate line, with \'=\' separating the name and value.  For Keyword fields, use Nave/Value pairs, and format the Value as \'match_column::table_nam::primary_table_column::relationship_column\' if on a remote table.',NULL,NULL,'No','No',NULL,NULL),(77,1,'6_1:15_1','Priority','priority','low_integer',7,'No',2,'Sets the display order; the Quick-Search field will include the first two menus set as \'Quick-Search\'.','1',NULL,'No','No',NULL,NULL),(78,1,'6_1:15_1','Trigger Other Menu(s)','trigger_menu','multi_select_plain',15,'No',10,'If you select one or more menus, choosing an option from this menu will cause the options for the target menu(s) to be rebuilt.  Only use for Single-Select menus in the Advanced Search Modal, and only if you have some intelligent options-building methods for the target menu.  The target menu\'s option-building method should look for this menu\'s selected value in the \'source_value\' param.',NULL,NULL,'No','No',NULL,NULL),(79,1,'6_1:8_1','Target Datatype','target_datatype','single_select',4,'Yes',30,'Primary type of data upon which this Tool will act. For Search Tools, will be the the type of records to find; for Action Tools, will be the type of the single record which is the target data.',NULL,NULL,'Yes','No',NULL,NULL),(80,1,'6_1:8_1','Search Re-Query Interval (Seconds)','query_interval','single_select',26,'No',30,'Controls search results auto-refresh; use sparingly as this creates extra load on the servers.',NULL,'0,30,60,120,180,240,300,600','Yes','No',NULL,NULL),(81,1,'6_1:8_1','Tool Type','tool_type','single_select',3,'Yes',30,'Determine the type of display and execution.  \'Search\' tools can only be displayed as \'Screen,\' which is the main display area in the browser.  \'Action\' Tools are more free-form and are often forms or other data-modifiers.  Action Tools can be display in the main Screen area, as Modals (pseudo pop-ups), and as Message notifications.  See docs in tool.pm for more info.','Search - Screen','Search - Screen,Action - Screen,Action - Modal,Action - Message Display','No','No',NULL,NULL),(82,1,'6_1:8_1','Is Locking Action','is_locking','yes_no_select',24,'No',3,'For Action Tools only. Will prevent other users from opening accessing this record via other Action Tool where Is-Locking is also set to Yes.','No','No,Yes','No','No',NULL,NULL),(84,1,'6_1:8_1','Action Link Type','link_type','single_select',7,'Yes',30,'Sets the navigation area where the Tool\'s link shall be displayed.  \'Menubar\' refers to the main Application menu.  \'Inline / Data Row\' is for Search Tools and loads links into the search results\' actions menu.  \'Quick Actions\' loads the menu on the left side of the Quick Search area above the main Tool display area.  \'Hidden / None\' will not display links.','Inline / Data Row','Menubar,Inline / Data Row,Quick Actions,Hidden / None','Yes','No',NULL,NULL),(85,1,'6_1:8_1','Link Match String','link_match_string','short_text',21,'No',30,'Used with \'Link Match Field\' above to limit display of Inline Links for Search Tools\' results.  Leave blank to always show Tool link.  Uses Perl regexp syntax, with a ! as the first character to do a negative match.',NULL,NULL,'Yes','No',NULL,NULL),(90,1,'6_1:8_1','Default Mode','default_mode','single_select',14,'No',200,'Applicable if there are multiple Tool Mode Configs set up for this Tool.',NULL,NULL,'Yes','No',NULL,NULL),(91,1,'6_1:13_1','Custom Template Filename','custom_template','short_text',3,'No',200,'Filename of the Jemplate template file if you selected \'Custom\' for Mode Type.  File must exist in omnitool::applications::APP_CODE_DIRECTORY::jemplates.',NULL,NULL,'No','No',NULL,NULL),(92,1,'6_1:15_1','Display Area','display_area','single_select',1,'No',30,'Can have up to three Quick-Search menus; all others will appear in the Advanced Search modal.','Advanced Search','Quick Search,Advanced Search','No','No',NULL,NULL),(93,1,'6_1:15_1','Custom Options Method','menu_options_method','short_text',9,'No',30,'Name of method within the OmniClass sub-class for the Target Datatype of this Tool.  Please see notes for these hooks in OmniClass docs.   \n<br/>\nFor \'Relationship options type, provide the the MySQL table name and column name to display, i.e. \'someother_table.display_field\'.  If you leave off the \'.display_field\', that will default to \'.name\'.  The relationship value is always the data_code from that table.',NULL,NULL,'Yes','No',NULL,NULL),(94,1,'6_1:15_1','SQL Command','sql_cmd','long_text',11,'No',200,'SQL command to generate options if the Menu Options Type is set to \'SQL Command\'.  Very much not recommended and be sure to use placeholders.',NULL,NULL,'No','No',NULL,NULL),(95,1,'6_1:15_1','SQL Bind Values','sql_bind_values','long_text',12,'No',30,'ALWAYS use placeholders in your SQL commands.  This is the list of values to use for the placeholders in the SQL command.  Separate values with commas or semicolons, and no spaces.',NULL,NULL,'No','No',NULL,NULL),(96,1,'6_1:15_1','Default Option Value','default_option_value','short_text',13,'No',60,'Will be utilized in default search.',NULL,NULL,'No','No',NULL,NULL),(97,1,'6_1:15_1','Search Operator','search_operator','single_select',3,'No',10,'How the match value(s) will be tested against the match column.  Multi-Select menus must be \'in\' or \'not in\'; Date Range menus are always \'between.\'','=','=,!=,<,>,>=,<=,like,not like,regexp,not regexp,in,not in','No','No',NULL,NULL),(99,1,'6_1:8_1','Load Tree Objects','load_trees','yes_no_select',27,'No',3,NULL,'No','No,Yes','Yes','No',NULL,NULL),(100,1,'6_1:8_1','Javascript Class','javascript_class','single_select',5,'No',100,'JavaScript file which should reside in omnitool::applications::APP_CODE_DIR::javascript.  Will be loaded when user visits the Application Instance.','None',NULL,'Yes','No',NULL,NULL),(103,1,'6_1:13_1','Run JS Function on Load','execute_function_on_load','short_text',5,'No',100,'Name of JavaScript function to execute when the Jemplate loads. No ()\'s or arguments. Should exist in the JavaScript Class File associated with this Tool, or within another JavaScript class for another Tool in this Application.  Receives the \'tool_id\' parameter as an argument\n<br/><br/>\nFor a Calendar display, use \'start_calendar\'.  If you are using the standard \'Table\' mode and wish to render it as a rich JQuery DataTable, place \'make_data_table\' here.  <b>For any forms, if you specify a function, be sure it invokes \'interactive_form_elements\' and pass the \'tool_id\' as an argument.</b>\n<br/><br/>\nFor the \'complex data\' template, the best option is the \'complex_data_tab_remembering\' function to have the tab position auto-remembered.','None',NULL,'No','No',NULL,NULL),(104,1,'6_1:8_1','Link Match Field','link_match_field','single_select',20,'No',100,'If \'Action Link Type\' is set to \'Inline / Data Row,\' use this and \'Link Match String\' to require a match in the target record to open this subordinate Tool.  Does not have to be a displayed field.','Name',NULL,'Yes','No',NULL,NULL),(105,1,'6_1:8_1','Data-Lock Lifetimes (Minutes)','lock_lifetime','single_select',25,'No',2,'Screen will auto-close once lock time expires.',NULL,'0,5,10,20,30','Yes','No',NULL,NULL),(106,1,'6_1:6_1','Data-Lock Lifetimes (Minutes)','lock_lifetime','single_select',11,'No',2,'Used when no lock lifetime is specified, i.e. in scripts.  Tools will usually have a lock lifetime set.',NULL,'0,5,10,20,30','No','No',NULL,NULL),(107,1,'6_1:8_1','Message is Sticky?','message_is_sticky','yes_no_select',23,'No',3,'If Tool is a \'Message Display\' and this is set to \'Yes,\' message popup will stay open until user closes it.','No',NULL,'Yes','No',NULL,NULL),(108,1,'6_1:8_1','Message Display Time','message_time','single_select',22,'No',100,'If Tool is a \'Message Display\' and \'Message is Sticky\' is set to \'No\' above, determines how long the message will display before auto-closing.','20','10=10 seconds\n15=15 seconds\n20=20 seconds\n30=30 seconds\n60=1 minute\n90=90 seconds\n120=Two minutes','Yes','No',NULL,NULL),(113,1,'6_1:7_1','Is Virtual Field (Hook)','virtual_field','yes_no_select',1,'No',3,'If set to \'Yes,\' is generated by Datatype\'s OmniClass sub-class and should have a method named for the MySQL Table Column, with \'field_\' pre-pended, i.e. \'field_birthday\' for a table column of \'birthday.  Virtual Fields will not appear in create/update forms. Please see notes on these hooks in the OmniClass docs.','No',NULL,'No','No',NULL,NULL),(114,1,'6_1:8_1','Tool Name','enhanced_name','long_text',19,'No',100,NULL,NULL,NULL,'No','Yes','name',NULL),(115,1,'6_1:5_1','Instance Link','instance_link','short_text',16,'No',100,NULL,NULL,NULL,'No','Yes',NULL,NULL),(117,1,'6_1:12_1','Status','status','active_status_select',2,'No',100,NULL,'Active',NULL,'No','No',NULL,NULL),(118,1,'6_1:1_1','Status','status','active_status_select',1,'No',100,'Must be set to \'Active\' for Application to be usable.','Active',NULL,'No','No',NULL,NULL),(119,1,'6_1:1_1','UI Skeleton Template','ui_template','single_select',3,'Yes',40,'Should be a Template Toolkit file meant to be processed on the server-side.  Filenames must end in \'.tt\'.\n\nOptions are from $OTPERL/static_files/skeletons as well as the \'skeletons\' sub-directory in your Application Code Directory.\n\nNote that you can save a \'application_extra_skeleton_classes.tt\' template under your Application\'s \'javascripts\' directory and have that added to the bottom of your skeleton template.','default.tt',NULL,'No','No',NULL,NULL),(120,1,'6_1:12_1','Used in Applications','used_in_applications','multi_select_plain',3,'No',100,NULL,NULL,NULL,'No','No',NULL,NULL),(121,1,'6_1:12_1','Match Hash Key','match_hash_key','short_text',4,'No',100,'Key to match against in the \'access_info\' hash which the custom \'session_hooks\' modules will add to the user session.',NULL,NULL,'Yes','No',NULL,NULL),(122,1,'6_1:12_1','Match Value','match_value','short_text',6,'No',100,'Target value to qualify the \'Match Hash Key\' entry against via the \'Match Operator\' in order to include a user in this Access Role.',NULL,NULL,'No','No',NULL,NULL),(123,1,'6_1:12_1','Match Operator','match_operator','single_select',5,'No',100,'Type of match to perform; \'contains\' is a case-insensitive regular expression.','Equals','Equals,Not Equals,Contains,Does Not Contain','No','No',NULL,NULL),(124,1,'6_1:9_1','Hard-Set Access Roles','hard_set_access_roles','multi_select_plain',3,'No',100,'Use to guarantee membership in the selected Access Roles, for the App Instances shown.  Use for smaller systems.',NULL,NULL,'No','No',NULL,NULL),(125,1,'6_1:5_1','\"Switch-Into\" Access Roles','switch_into_access_roles','multi_select_plain',11,'No',100,'Select Access Roles from other Instances to allow users of those Instances to see the links to \'switch to\' this Application Instance (upper-right, next to the User menu).',NULL,NULL,'No','No',NULL,NULL),(126,1,'6_1:5_1','File Storage Method','file_storage_method','single_select',14,'No',100,'Use the \'File location\' field to specify the File System path, or Swift Store URL and credentials.','File System','File System,Swift Store','No','No',NULL,NULL),(127,1,'6_1:5_1','File Location','file_location','short_text_encrypted',15,'No',200,'If using \'File System\' for File Storage Method, specify the path on your server which will be the base for storing files in this instance, i.e. /export/webapps/files/some_instance.\n<br/>If using \'Swift Store\' for File Storage Method, specify as: AuthV1.0url|username|scret-api-key.  <br/>Only 1.0 Auth supported at this time for Swift.',NULL,NULL,'No','No',NULL,NULL),(129,1,'6_1:5_1','DB Server / DB Name','database_info','short_text',17,'No',100,NULL,NULL,NULL,'No','Yes',NULL,NULL),(132,1,'6_1:13_1','Max Number of Results to Return','max_results','single_select',10,'No',100,'For Search Tools Only.','No Max','No Max,25,50,100,250,500','No','No',NULL,NULL),(133,1,'6_1:5_1','Cross-Hostname URI','uri_base_value','short_text',3,'Yes',100,'One word / segment only.  Can not begin with \'tool\' or \'ui\'.  Accessing this URI within any of your configured virtual hosts / hostnames will work the same as if you accessed this Instance via its hostname above.',NULL,NULL,'Yes','No',NULL,NULL),(134,1,'6_1:1_1','Share Datatypes With Another App','share_my_datatypes','single_select',8,'No',100,'Allows the selected Application\'s Instances to use the Datatypes defined under this Application.  Very useful if multiple Applications are going to write into the same databases, to use different tools to manage shared datasets.','None',NULL,'No','No',NULL,NULL),(135,1,'6_1:5_1','Info for Sending Email','email_sending_info','short_text_encrypted',13,'No',200,'Format: email.server.com|username|password|SSL/TLS\n<br/>Last part can be left off for plain (port 25) SMTP.\n<br/>Leave off username/password if not needed.\n<br/>Use \'Gmail\' for server hostname if using Google Mail.',NULL,NULL,'No','No',NULL,NULL),(138,1,'6_1:6_1','Process Count for BG Tasks & Email','support_email_and_tasks','single_select',8,'No',3,'Set to 1 or greater to allow background tasks and emails to be created for this Datatype.  If set to \'No,\' the add_task() and add_outbound_email() methods will not work.  Number determines how many background processes will be spawned per worker node.  Almost all Datatypes are well-served by just one process, so select 2 or more very carefully.','No','No,1,2,3,4,5,6,7,8','No','No',NULL,NULL),(140,1,'6_1:5_1','Pause Background Tasks','pause_background_tasks','yes_no_select',12,'No',3,'If set to \'Yes\', background task processing will not occur.  Use for code launches.','No',NULL,'No','No',NULL,NULL),(141,1,'6_1:5_1','UI Logo','ui_logo','short_text',8,'Yes',60,'Will be displayed in the header.  Must be a PNG with \'*.png\' suffix. 30 x 30 is best size.  Provide a URI path relative to the root of your server, if you do not like Ginger\'s lovely face.','/ui_icons/ginger_face.png',NULL,'No','No',NULL,NULL),(144,1,'6_1:1_1','App-Wide Search JS Function','appwide_search_function','short_text',10,'No',100,'Use if you want an Application-wide search box in the upper-right (breadcrumbs area).  Otherwise leave as \'None\'.  If filled-in, breadcrumbs.tt will include a search field that will trigger this function.  Include the function in a \'application_wide_functions.js\' class under your Application\'s \'javascripts\' directory.','None',NULL,'No','No',NULL,NULL),(145,1,'6_1:1_1','App-Wide Search Name','appwide_search_name','short_text',11,'No',100,'Use in concert with \'App-Wide Search JS Function\' above; will be the placeholder text for the app-wide search box. ','None',NULL,'No','No',NULL,NULL),(146,1,'6_1:7_1','Alternative Column for Sorting','sort_column','short_text_clean',12,'No',40,'For Virtual Fields only; used when sorting in OmniClass loads in place of the virtual fields.  Likely will be a DB column, but may be a second hash key in the {records} hash.',NULL,NULL,'Yes','No',NULL,NULL),(147,1,'6_1:8_1','Use Inline Actions from Parent Search','share_parent_inline_action_tools','yes_no_select',13,'No',3,'For Action Tools only.  Great for \'View Details\' Tools where you may want to jump to other Action Tools for a record.   (Can be used for any Action - Screen Tool -- very handy feature.)','No',NULL,'No','No',NULL,NULL),(148,1,'6_1:15_1','Instructions','instructions','long_text',14,'No',30,'Used for Advanced Search Form.',NULL,NULL,'No','No',NULL,NULL),(149,1,'6_1:1_1','App-Wide Quick Search Tool URI','appwide_quickstart_tool_uri','short_text',12,'No',100,'Use if you want to provide a \'Quick Start\' button in the upper-right, next to the app-wide search.  This is mean to load a modal of quick-start links for the users.','None',NULL,'No','No',NULL,NULL),(150,1,'6_1:18_1','Username','username','short_text',2,'Yes',20,NULL,NULL,NULL,'Yes','No',NULL,NULL),(151,1,'6_1:18_1','Tied to IP Addresses','tied_to_ip_address','long_text',4,'Yes',100,'One IP address per line for each client machine which will utilize this API key.',NULL,NULL,'No','No',NULL,NULL),(152,1,'6_1:18_1','Expiration Date','expiration_date','simple_date',5,'No',100,'Leave blank to auto-set to 90 days from today.',NULL,NULL,'No','No',NULL,NULL),(153,1,'6_1:18_1','API Key String','api_key_string','short_text',6,'No',100,'Leave blank to auto-generate.',NULL,NULL,'No','No',NULL,NULL),(154,1,'6_1:18_1','Status','status','active_status_select',1,'No',100,NULL,'Active',NULL,'No','No',NULL,NULL),(155,1,'6_1:8_1','Display Description?','display_description','yes_no_select',17,'No',3,'If \'Yes,\' Description will be displayed above Tool Controls area.','No','No,Yes','No','No',NULL,NULL),(156,1,'6_1:8_1','Require Quick Search Keyword','require_quick_search_keyword','yes_no_select',12,'No',3,'If set to \'Yes,\' Search will not execute without the keyword.  Useful if you are matching in the SQL and/or have a larger dataset.','No',NULL,'No','No',NULL,NULL),(157,1,'6_1:15_1','Support \'Any/All\' Option','support_any_all_option','yes_no_select',6,'No',3,'Set to \'No\' to require a choice.','Yes',NULL,'No','No',NULL,NULL),(158,1,'6_1:6_1','Account for Incoming Emails','incoming_email_account','short_text',9,'No',30,'Should be a user account on your server.  The suffix/domain will be the Instance Hostname.  Please see omnitool/scripts/email_receive.pl',NULL,NULL,'Yes','No',NULL,NULL),(159,1,'6_1:8_1','Menus Required for Search','menus_required_for_search','single_select',10,'No',3,'If set above zero,\' Search will not execute unless the user selects an option for at least that number of search menus.  Please make sure you have that many menus.','No','0,1,2,3,4','No','No',NULL,NULL),(160,1,'6_1:7_1','Alt. Heading for Search Tools','search_tool_heading','short_text',11,'No',60,'Heading name to use for search results.  If blank, the field name will search as the heading.',NULL,NULL,'No','No',NULL,NULL),(161,1,'6_1:6_1','Skip \'Children\' Column Write','skip_children_column','yes_no_select',6,'No',3,'If \'Yes,\' will not be included in the \'children\' metainfo column for parent record.  Will cause this type of data to not work with omniclass_tree.  Use for data where there may be thousands and thousands of records.','No',NULL,'No','No',NULL,NULL),(162,1,'6_1:6_1','Altcodes are Unique','altcodes_are_unique','yes_no_select',7,'No',3,'Set to \'No\' if the \'altcode\' values (for the metainfo table) will NOT be reliably unique for each record.','Yes',NULL,'No','No',NULL,NULL),(163,1,'6_1:13_1','Single-Record Jemplate Block','single_record_jemplate_block','short_text',12,'No',100,'If you wish to enable single-record refresh for subordinate modal and message tools, then provide the base name of the BLOCK section in this Jemplate which will handle each record individually.  For the Table.tt Jemplate, it would be \'the_result_table_row\'.  \n<br/><br/>\nIf you leave this blank, closing a subordinate (inline-action) modal or message action tool will cause a refresh of all loaded data, which is just fine for 99% of tools.  Certain high-traffic Search tools may want to use this \'refresh-one-record\' feature.',NULL,NULL,'No','No',NULL,NULL),(164,1,'6_1:18_1','Tied to IP Addresses','tied_to_ip_address_display','short_text',3,'No',100,NULL,NULL,NULL,'No','Yes',NULL,NULL),(165,1,'6_1:8_1','Display Tool Controls?','display_tool_controls','yes_no_select',16,'No',3,'If \'Yes,\' Screen tools will have the Tool Controls area in the main display area.  Required for search options and print/refresh.  Should be Yes almost all of the time.  ','Yes',NULL,'No','No',NULL,NULL),(166,1,'6_1:5_1','Public Mode Instance','public_mode','yes_no_select',10,'No',3,'BE CAREFUL:  This turns OFF authentication for this Application Instance.  Only use this if all your Tools for the parent Application are set to \'Open Access\' and if those Tools are just for information display.','No',NULL,'No','No',NULL,NULL),(167,1,'6_1:13_1','Display a Chart','display_a_chart','single_select',6,'No',20,'Will cause a simple chart to be rendered using the the first included field as the X-Axis (labels) and the second field for the Y-Axis (values).  If you use this, be sure to set \'Run JS Function on Load\' function either be \'render_tool_chart\' or a function which will call to \'render_tool_chart\'.  Please see charting_json in tools/searcher.pm as well as example_tool_subclass.tt.\n','No','No,Pie Chart,Bar Chart,Line Chart','No','No',NULL,NULL),(168,1,'6_1:9_1','Require Password Change on Next Login','require_password_change','yes_no_select',4,'No',3,NULL,NULL,NULL,'No','No',NULL,NULL),(169,1,'6_1:9_1','Password Set date','password_set_date','simple_date',5,'Yes',100,'Date of last password change.  Passwords must be changed every 90 days.',NULL,NULL,'No','No',NULL,NULL),(170,1,'6_1:1_1','Navigation Placement in UI','ui_navigation_placement','single_select',4,'No',15,'Used for default.tt to place the \'sidebar\' where the Tools\' links will be displayed.','Left Side','Left Side,Top','No','No',NULL,NULL),(171,1,'6_1:1_1','Ace Admin Skin for UI','ui_ace_skin','single_select',5,'No',15,'Used in default.tt to select a color scheme for Ace Admin.','No Skin','No Skin,Skin 1, Skin 2,Skin 3','No','No',NULL,NULL),(173,1,'6_1:1_1','Application Name','enhanced_name','short_text',1,'No',100,NULL,NULL,NULL,'No','Yes',NULL,NULL),(174,1,'6_1:8_1','Supports Advanced Sorting','supports_advanced_sorting','yes_no_select',11,'No',3,'For Searching tools only; allows users to sort records by up to four columns, in varying directions.','No',NULL,'No','No',NULL,NULL),(175,1,'6_1:13_1','Single-Record Refresh Mode','single_record_refresh_mode','yes_no_select',13,'No',3,'If you have enabled single-record reload above, this will change the background search refresh to only update modified records.  Drawback: background searches will not bring in new records, so use with caution.','No',NULL,'No','No',NULL,NULL);
/*!40000 ALTER TABLE `datatype_fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `datatypes`
--

DROP TABLE IF EXISTS `datatypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datatypes` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `table_name` varchar(60) DEFAULT '',
  `containable_datatypes` mediumtext,
  `perl_module` varchar(200) DEFAULT 'none',
  `lock_lifetime` enum('0','5','10','20','30') DEFAULT '0',
  `description` mediumtext,
  `metainfo_table` enum('DB Table','Own Table','No Metainfo') DEFAULT 'DB Table',
  `show_name` varchar(3) DEFAULT 'Yes',
  `extended_change_history` varchar(3) DEFAULT 'No',
  `archive_deletes` varchar(3) DEFAULT 'No',
  `support_email_and_tasks` varchar(3) DEFAULT NULL,
  `incoming_email_account` varchar(30) DEFAULT NULL,
  `skip_children_column` varchar(3) DEFAULT NULL,
  `altcodes_are_unique` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatypes`
--

LOCK TABLES `datatypes` WRITE;
/*!40000 ALTER TABLE `datatypes` DISABLE KEYS */;
INSERT INTO `datatypes` VALUES (1,1,'1_1:1_1','Application','applications','6_1,5_1,8_1','applications',NULL,'Applications represent the combination of Datatypes, Tools configurations, and custom code (sub-classes for OmniClass and Tool.pm plus Jemplates).  ','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(4,1,'1_1:1_1','Database Server','database_servers',NULL,'database_servers',NULL,'All Database Servers should have replicated copies of the OmniTool Admin databases but their own copy of the \'otstatedata\' database.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(5,1,'1_1:1_1','Application Instance','instances',NULL,'instances',NULL,'Application Instances represent uses of the configuration, logic, and code defined for their parent Applications.  Each Application Instance may have its own domain name, database server connection, and database name.  This allows you to serve Instances on separate Plack and MySQL servers, and to allow different groups to use Applications in independently.','DB Table','Yes','No','No','1','calo','No','Yes'),(6,1,'1_1:1_1','Datatype','datatypes','7_1','datatypes',NULL,'Datatypes represent individual MySQL tables in the Instance\'s database, as well as configurations used in OmniClass objects.  These are very similar to DBI::Class configs.\n\nAfter you set up your Datatypes, be sure to use the \'Setup MySQL Tables\' tool under Manage Instances to create or update the Datatype table.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(7,1,'1_1:1_1','Datatype Field','datatype_fields',NULL,'datatype_fields',NULL,'Datatype Fields represent either (a) a column in the Datatype\'s MySQL table or (b) a method in your OmniClass sub-class.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(8,1,'1_1:1_1','Tool','tools','14_1,8_1,15_1,13_1','tools',NULL,'Tools represent controllers to drive actions completed by OmniClass objects.  This is how you expose features and functions to your users.  ','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(9,1,'1_1:1_1','OmniTool User','omnitool_users',NULL,'omnitool_users',NULL,'OmniTool Users are shared across all the Applications tied to this OmniTool Admin database.  Users can log into any Instance tied to this OmniTool Admin database, though they may not have access to any Tools in an Instance.  If your Application Instance uses a third-party method to authenticate users, these internal OmniTool Users records will be checked first.\n<br/><br/>\n<b>NOTE: Once a user authenticates via one OmniTool Admin database, they can operate as that username for ALL Applications on your system, across all your OmniTool Admin databases.</b>  Keep your usernames unique or plan your Access Roles accordingly.','DB Table','Yes','No','No','No',NULL,'No','Yes'),(10,1,'1_1:1_1','Organizer','organizers','','None','0','','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(12,1,'1_1:1_1','Access Role','access_roles',NULL,'access_roles',NULL,'Access Roles are used to control user permissions to access Tools in the associated Applications.  You can hard-set users\' membership in Access Roles in the Add or Update User form under Manage Users, and that is appropriate for smaller systems. For larger, multi-Instance Applications, you will need to create a \'session_hooks.pm\' module under each Applications\' code directory, and have that module build a \'access_data\' sub-hash to go into the users\' sessions.  This routine should be able to pull different data based on the current Instance, and that data will be tested against the \'Match Hash Key\' / \'Match Operator\' / \'Match Value\' fields to grant membership in the Access Roles.  Please see the notes in session.pm for more details.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(13,1,'1_1:1_1','Tool View Mode Config','tool_mode_configs',NULL,'tool_mode_configs',NULL,'For All Tools; Tool Mode Configs represent Jemplate display views for this Tool. If there are multiple Tool Modes set up, a \'Change View\' menu will appear in the Quick-Search area above the main Tool display; that works for \'Screen\' Tools; Modals should have just one view.','DB Table','Yes','No','No','No',NULL,'No','Yes'),(14,1,'1_1:1_1','Record-Color Rule','record_coloring_rules',NULL,'record_coloring_rules',NULL,'For Search Tools only. These rules will set a value for the {record_color} entry in the {metainfo} hash for each found record for your search.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(15,1,'1_1:1_1','Tool Filter Menu','tool_filter_menus',NULL,'tool_filter_menus',NULL,'For Search Tools only; Tool Filter Menus help you set up both the Quick Search and Advanced Search forms for this Tool.','DB Table','Yes','No','No',NULL,NULL,'No','Yes'),(18,1,'1_1:1_1','OmniTool User API Key','user_api_keys',NULL,'user_api_keys',NULL,'Allows users to authenticate via a key for the purposes of writing programs to access OT6 outside of the Web UI.','Own Table','No','No','No','No',NULL,'No','Yes');
/*!40000 ALTER TABLE `datatypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deleted_data`
--

DROP TABLE IF EXISTS `deleted_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deleted_data` (
  `code` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `data_code` varchar(30) NOT NULL DEFAULT '0',
  `datatype` varchar(30) NOT NULL,
  `delete_time` int(11) NOT NULL DEFAULT '0',
  `deleter` varchar(30) NOT NULL,
  `data_record` longblob,
  `metainfo_record` longblob,
  PRIMARY KEY (`code`,`server_id`),
  KEY `data_code` (`data_code`),
  KEY `data_code_2` (`data_code`,`datatype`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deleted_data`
--

LOCK TABLES `deleted_data` WRITE;
/*!40000 ALTER TABLE `deleted_data` DISABLE KEYS */;
/*!40000 ALTER TABLE `deleted_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `email_incoming`
--

DROP TABLE IF EXISTS `email_incoming`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email_incoming` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `mime_message` longblob,
  `status` enum('New','Locked','Done','Error') DEFAULT NULL,
  `error_message` varchar(1000) DEFAULT NULL,
  `create_time` int(11) unsigned DEFAULT NULL,
  `recipient` varchar(100) DEFAULT NULL,
  `process_pid` int(8) unsigned DEFAULT NULL,
  `worker_id` int(3) unsigned DEFAULT '1',
  PRIMARY KEY (`code`,`server_id`),
  KEY `status` (`status`,`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_incoming`
--

LOCK TABLES `email_incoming` WRITE;
/*!40000 ALTER TABLE `email_incoming` DISABLE KEYS */;
/*!40000 ALTER TABLE `email_incoming` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `email_outbound`
--

DROP TABLE IF EXISTS `email_outbound`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email_outbound` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `create_timestamp` int(11) unsigned DEFAULT NULL,
  `send_timestamp` int(11) unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `target_datatype` varchar(30) NOT NULL,
  `from_address` varchar(200) DEFAULT NULL,
  `to_addresses` text,
  `subject` varchar(200) DEFAULT NULL,
  `message_body` longtext,
  `attached_files` text,
  `process_pid` int(8) unsigned DEFAULT NULL,
  `worker_id` int(3) unsigned DEFAULT '1',
  PRIMARY KEY (`code`,`server_id`),
  KEY `status` (`status`,`target_datatype`),
  KEY `status_2` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_outbound`
--

LOCK TABLES `email_outbound` WRITE;
/*!40000 ALTER TABLE `email_outbound` DISABLE KEYS */;
/*!40000 ALTER TABLE `email_outbound` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `email_sent`
--

DROP TABLE IF EXISTS `email_sent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `email_sent` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `send_timestamp` int(11) unsigned DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `from_address` varchar(200) DEFAULT NULL,
  `to_addresses` text,
  `subject` varchar(200) DEFAULT NULL,
  `attached_files` text,
  PRIMARY KEY (`code`,`server_id`),
  KEY `status` (`status`,`send_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `email_sent`
--

LOCK TABLES `email_sent` WRITE;
/*!40000 ALTER TABLE `email_sent` DISABLE KEYS */;
/*!40000 ALTER TABLE `email_sent` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `instances`
--

DROP TABLE IF EXISTS `instances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instances` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `contact_email` varchar(100) DEFAULT NULL,
  `description` text,
  `hostname` varchar(250) DEFAULT '',
  `database_server_id` varchar(30) DEFAULT NULL,
  `database_name` varchar(50) DEFAULT NULL,
  `status` varchar(12) DEFAULT '',
  `access_roles` text,
  `switch_into_access_roles` text,
  `email_sending_info` text,
  `file_storage_method` varchar(100) DEFAULT NULL,
  `file_location` text,
  `uri_base_value` varchar(100) DEFAULT NULL,
  `pause_background_tasks` varchar(3) DEFAULT NULL,
  `ui_logo` varchar(60) DEFAULT 'ginger_face.png',
  `public_mode` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instances`
--

LOCK TABLES `instances` WRITE;
/*!40000 ALTER TABLE `instances` DISABLE KEYS */;
INSERT INTO `instances` VALUES (1,1,'1_1:1_1','OmniTool Core System Admin (Dev)','ericschernoff@gmail.com',NULL,'admin.omnitool.org','1','omnitool','Active','Open',NULL,NULL,'File System',NULL,'sysadmin','No','/ui_icons/ginger_face.png','No'),(8,1,'1_1:1_1','OmniTool Core System Admin (Prod)','ericschernoff@gmail.com','CALO production interface to sysadmin tools.','admin-prod.omnitool.org','2','omnitool','Inactive','Open',NULL,'C3VKjliEo9p6dPcJ95msgOfYQx+zb7GW9+g1HXEr18M=','File System',NULL,'sysadmin_prod','No','/ui_icons/ginger_face.png','No'),(9,1,'1_1:1_1','Sample Applications Admin','ericschernoff@gmail.com','Administrative area for Sample Applications.','sample-apps-admin.omnitool.org','1','omnitool_samples','Active','Open','1_1::1_1,10_1::1_1',NULL,'File System',NULL,'sample_apps_admin','No','/ui_icons/ginger_face.png','No'),(10,1,'1_1:1_1','Admin for Omnitool.org','ericschernoff@gmail.com',NULL,'apps-admin.omnitool.org','1','omnitool_applications','Active','Open','1_1::1_1,9_1::1_1',NULL,'File System',NULL,'apps_admin','No','/ui_icons/ginger_face.png','No');
/*!40000 ALTER TABLE `instances` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `metainfo`
--

DROP TABLE IF EXISTS `metainfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metainfo` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `altcode` varchar(50) NOT NULL,
  `data_code` varchar(30) NOT NULL,
  `the_type` varchar(30) NOT NULL,
  `table_name` varchar(60) NOT NULL DEFAULT '',
  `originator` varchar(25) NOT NULL,
  `create_time` int(11) unsigned NOT NULL,
  `updater` varchar(25) NOT NULL,
  `update_time` int(11) unsigned NOT NULL,
  `lock_user` varchar(30) NOT NULL DEFAULT 'None',
  `lock_expire` int(11) DEFAULT NULL,
  `parent` varchar(30) NOT NULL,
  `children` text,
  `is_draft` enum('No','Yes') NOT NULL DEFAULT 'No',
  `thumbnail_file` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`),
  KEY `altcode` (`altcode`),
  KEY `data_code` (`data_code`)
) ENGINE=InnoDB AUTO_INCREMENT=447 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metainfo`
--

LOCK TABLES `metainfo` WRITE;
/*!40000 ALTER TABLE `metainfo` DISABLE KEYS */;
INSERT INTO `metainfo` VALUES (1,1,'app01','1_1','1_1','applications','eric',1431574093,'omnitool_admin',1503332576,'None',0,'top','6_1:1_1,6_1:4_1,6_1:5_1,6_1:6_1,6_1:7_1,6_1:8_1,6_1:9_1,6_1:10_1,6_1:12_1,5_1:1_1,8_1:1_1,8_1:2_1,6_1:13_1,6_1:14_1,6_1:15_1,8_1:9_1,8_1:63_1,8_1:72_1,6_1:18_1,8_1:79_1,5_1:8_1,5_1:9_1,5_1:10_1,5_1:11_1','No',0),(3,1,'application','1_1','6_1','datatypes','eric',1431660502,'eric',1506393469,'None',0,'1_1:1_1','7_1:4_1,7_1:5_1,7_1:6_1,7_1:53_1,7_1:118_1,7_1:119_1,7_1:134_1,7_1:144_1,7_1:145_1,7_1:149_1,7_1:170_1,7_1:171_1,7_1:173_1','No',0),(4,1,'db_server','4_1','6_1','datatypes','eric',1431660506,'eric',1454387848,'None',0,'1_1:1_1','7_1:15_1,7_1:16_1','No',0),(5,1,'instance','5_1','6_1','datatypes','eric',1431660508,'echernof',1499487257,'None',0,'1_1:1_1','7_1:7_1,7_1:8_1,7_1:9_1,7_1:10_1,7_1:12_1,7_1:13_1,7_1:14_1,7_1:115_1,7_1:125_1,7_1:126_1,7_1:127_1,7_1:129_1,7_1:133_1,7_1:135_1,7_1:140_1,7_1:141_1,7_1:166_1','No',0),(6,1,'datatype','6_1','6_1','datatypes','eric',1431660511,'eric',1486528885,'echernof',1486529778,'1_1:1_1','7_1:28_1,7_1:30_1,7_1:31_1,7_1:32_1,7_1:33_1,7_1:34_1,7_1:35_1,7_1:36_1,7_1:106_1,7_1:138_1,7_1:158_1,7_1:161_1,7_1:162_1','No',0),(7,1,'datatype_field','7_1','6_1','datatypes','eric',1431660513,'eric',1477669657,'None',0,'1_1:1_1','7_1:37_1,7_1:38_1,7_1:39_1,7_1:40_1,7_1:41_1,7_1:42_1,7_1:43_1,7_1:44_1,7_1:45_1,7_1:113_1,7_1:146_1,7_1:160_1','No',0),(8,1,'screen','8_1','6_1','datatypes','eric',1431660515,'eric',1518140549,'None',0,'1_1:1_1','7_1:18_1,7_1:19_1,7_1:20_1,7_1:21_1,7_1:51_1,7_1:52_1,7_1:56_1,7_1:57_1,7_1:79_1,7_1:80_1,7_1:81_1,7_1:82_1,7_1:83_1,7_1:84_1,7_1:85_1,7_1:90_1,7_1:99_1,7_1:100_1,7_1:104_1,7_1:105_1,7_1:107_1,7_1:108_1,7_1:114_1,7_1:147_1,7_1:155_1,7_1:156_1,7_1:159_1,7_1:165_1,7_1:174_1','No',0),(9,1,'ot_user','9_1','6_1','datatypes','eric',1431660517,'omnitool_admin',1512314782,'None',0,'1_1:1_1','7_1:46_1,7_1:47_1,7_1:124_1,7_1:168_1,7_1:169_1','No',0),(10,1,'organizer','10_1','6_1','datatypes','eric',1431660519,'eric',1431660519,'None',0,'1_1:1_1',NULL,'No',0),(14,1,'access_groups','12_1','6_1','datatypes','eric',1431743676,'eric',1454556962,'None',0,'1_1:1_1','7_1:49_1,7_1:117_1,7_1:120_1,7_1:121_1,7_1:122_1,7_1:123_1','No',0),(22,1,'dtf22','49_1','7_1','datatype_fields','eric',1431832876,'eric',1454555412,'None',0,'6_1:12_1',NULL,'No',0),(23,1,'dtf23','4_1','7_1','datatype_fields','eric',1431832879,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(24,1,'dtf24','5_1','7_1','datatype_fields','eric',1431832879,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(25,1,'dtf25','6_1','7_1','datatype_fields','eric',1431832879,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(29,1,'dtf29','15_1','7_1','datatype_fields','eric',1431832900,'eric',1453671927,'None',0,'6_1:4_1',NULL,'No',0),(30,1,'dtf30','16_1','7_1','datatype_fields','eric',1431832900,'eric',1453671947,'None',0,'6_1:4_1',NULL,'No',0),(31,1,'dtf31','7_1','7_1','datatype_fields','eric',1431832900,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(32,1,'dtf32','8_1','7_1','datatype_fields','eric',1431832900,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(33,1,'dtf33','9_1','7_1','datatype_fields','eric',1431832900,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(34,1,'dtf34','10_1','7_1','datatype_fields','eric',1431832908,'echernof',1499487275,'omnitool_admin',1503500466,'6_1:5_1',NULL,'No',0),(36,1,'dtf36','12_1','7_1','datatype_fields','eric',1431832908,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(37,1,'dtf37','13_1','7_1','datatype_fields','eric',1431832908,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(38,1,'dtf38','14_1','7_1','datatype_fields','eric',1431832908,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(39,1,'dtf39','28_1','7_1','datatype_fields','eric',1431832913,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(41,1,'dtf41','30_1','7_1','datatype_fields','eric',1431832913,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(42,1,'dtf42','31_1','7_1','datatype_fields','eric',1431832913,'echernof',1498751521,'None',0,'6_1:6_1',NULL,'No',0),(43,1,'dtf43','32_1','7_1','datatype_fields','eric',1431832913,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(44,1,'dtf44','33_1','7_1','datatype_fields','eric',1431832918,'omnitool_admin',1500847085,'None',0,'6_1:6_1',NULL,'No',0),(45,1,'dtf45','34_1','7_1','datatype_fields','eric',1431832918,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(46,1,'dtf46','35_1','7_1','datatype_fields','eric',1431832918,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(47,1,'dtf47','36_1','7_1','datatype_fields','eric',1431832918,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(48,1,'dtf48','37_1','7_1','datatype_fields','eric',1431832924,'echernof',1493391807,'None',0,'6_1:7_1',NULL,'No',0),(49,1,'dtf49','38_1','7_1','datatype_fields','eric',1431832924,'eric',1453673178,'None',0,'6_1:7_1',NULL,'No',0),(50,1,'dtf50','39_1','7_1','datatype_fields','eric',1431832924,'eric',1453673262,'None',0,'6_1:7_1',NULL,'No',0),(51,1,'dtf51','40_1','7_1','datatype_fields','eric',1431832924,'eric',1453672941,'None',0,'6_1:7_1',NULL,'No',0),(52,1,'dtf52','41_1','7_1','datatype_fields','eric',1431832924,'eric',1453673069,'None',0,'6_1:7_1',NULL,'No',0),(53,1,'dtf53','42_1','7_1','datatype_fields','eric',1431832924,'eric',1453673124,'None',0,'6_1:7_1',NULL,'No',0),(54,1,'dtf54','43_1','7_1','datatype_fields','eric',1431832928,'eric',1453673101,'None',0,'6_1:7_1',NULL,'No',0),(55,1,'dtf55','44_1','7_1','datatype_fields','eric',1431832928,'eric',1453672814,'None',0,'6_1:7_1',NULL,'No',0),(56,1,'dtf56','45_1','7_1','datatype_fields','eric',1431832928,'omnitool_admin',1512443538,'None',0,'6_1:7_1',NULL,'No',0),(58,1,'dtf58','18_1','7_1','datatype_fields','eric',1431832928,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(59,1,'dtf59','19_1','7_1','datatype_fields','eric',1431832932,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(60,1,'dtf60','20_1','7_1','datatype_fields','eric',1431832932,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(61,1,'dtf61','21_1','7_1','datatype_fields','eric',1431832932,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(62,1,'dtf62','46_1','7_1','datatype_fields','eric',1431832932,'eric',1453673377,'None',0,'6_1:9_1',NULL,'No',0),(63,1,'dtf63','47_1','7_1','datatype_fields','eric',1431832932,'eric',1453673349,'None',0,'6_1:9_1',NULL,'No',0),(64,1,'app_inst01','1_1','5_1','instances','eric',1431833255,'eric',1500265848,'None',0,'1_1:1_1',NULL,'No',0),(66,1,'','1_1','10_1','organizers','eric',1431833431,'eric',1431833431,'None',0,'top','4_1:1_1','No',0),(67,1,'db01','1_1','4_1','database_servers','eric',1431833666,'echernof',1486742577,'None',0,'10_1:1_1',NULL,'No',0),(68,1,'','2_1','10_1','organizers','eric',1431834307,'eric',1431834307,'None',0,'top',NULL,'No',0),(69,1,'','3_1','10_1','organizers','eric',1431834307,'eric',1431834307,'None',0,'top','9_1:1_1','No',0),(72,1,'dtf72','51_1','7_1','datatype_fields','eric',1432220684,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(73,1,'dtf73','52_1','7_1','datatype_fields','eric',1432220696,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(75,1,'May15eric_datatypefields53','53_1','7_1','datatype_fields','eric',1432239128,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(78,1,'May15eric_datatypefields56','56_1','7_1','datatype_fields','eric',1432498938,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(79,1,'May15eric_datatypefields57','57_1','7_1','datatype_fields','eric',1432523975,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(81,1,'May15eric_tools1','1_1','8_1','tools','eric',1433126057,'echernof',1467395746,'None',0,'1_1:1_1','8_1:3_1,13_1:4_1,8_1:28_1','No',0),(82,1,'May15eric_tools2','2_1','8_1','tools','eric',1433129040,'echernof',1478116034,'None',0,'1_1:1_1','13_1:1_1,13_1:2_1,16_1:1_1,8_1:6_1,8_1:7_1,8_1:8_1,8_1:26_1,8_1:27_1,8_1:39_1,8_1:44_1,8_1:90_1','No',0),(83,1,'Jun15eric_tools1','3_1','8_1','tools','eric',1433204054,'eric',1449350052,'None',0,'8_1:1_1','13_1:3_1','No',0),(84,1,'Jun15eric_datatypes13','13_1','6_1','datatypes','eric',1434327995,'echernof',1523590551,'None',0,'1_1:1_1','7_1:58_1,7_1:59_1,7_1:61_1,7_1:62_1,7_1:63_1,7_1:64_1,7_1:65_1,7_1:91_1,7_1:103_1,7_1:132_1,7_1:163_1,7_1:167_1,7_1:175_1','No',0),(85,1,'Jun15eric_datatypes14','14_1','6_1','datatypes','eric',1434328896,'eric',1453669250,'None',0,'1_1:1_1','7_1:67_1,7_1:68_1,7_1:69_1,7_1:70_1,7_1:71_1','No',0),(86,1,'Jun15eric_datatypes15','15_1','6_1','datatypes','eric',1434328922,'eric',1470107538,'echernof',1490909410,'1_1:1_1','7_1:72_1,7_1:73_1,7_1:74_1,7_1:75_1,7_1:76_1,7_1:77_1,7_1:78_1,7_1:92_1,7_1:93_1,7_1:94_1,7_1:95_1,7_1:96_1,7_1:97_1,7_1:148_1,7_1:157_1','No',0),(87,1,'Jun15eric_datatypefields58','58_1','7_1','datatype_fields','eric',1434330596,'omnitool_admin',1511674368,'None',0,'6_1:13_1',NULL,'No',0),(88,1,'Jun15eric_datatypefields59','59_1','7_1','datatype_fields','eric',1434330596,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(90,1,'Jun15eric_datatypefields61','61_1','7_1','datatype_fields','eric',1434330596,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(91,1,'Jun15eric_datatypefields62','62_1','7_1','datatype_fields','eric',1434330596,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(92,1,'Jun15eric_datatypefields63','63_1','7_1','datatype_fields','eric',1434330597,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(93,1,'Jun15eric_datatypefields64','64_1','7_1','datatype_fields','eric',1434330597,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(94,1,'Jun15eric_datatypefields65','65_1','7_1','datatype_fields','eric',1434330597,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(96,1,'Jun15eric_datatypefields67','67_1','7_1','datatype_fields','eric',1434330949,'eric',1453673646,'None',0,'6_1:14_1',NULL,'No',0),(97,1,'Jun15eric_datatypefields68','68_1','7_1','datatype_fields','eric',1434330949,'eric',1434330949,'None',0,'6_1:14_1',NULL,'No',0),(98,1,'Jun15eric_datatypefields69','69_1','7_1','datatype_fields','eric',1434330949,'eric',1453673626,'None',0,'6_1:14_1',NULL,'No',0),(99,1,'Jun15eric_datatypefields70','70_1','7_1','datatype_fields','eric',1434330949,'eric',1453673584,'None',0,'6_1:14_1',NULL,'No',0),(100,1,'Jun15eric_datatypefields71','71_1','7_1','datatype_fields','eric',1434330949,'eric',1453673527,'None',0,'6_1:14_1',NULL,'No',0),(101,1,'Jun15eric_datatypefields72','72_1','7_1','datatype_fields','eric',1434331572,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(102,1,'Jun15eric_datatypefields73','73_1','7_1','datatype_fields','eric',1434331572,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(103,1,'Jun15eric_datatypefields74','74_1','7_1','datatype_fields','eric',1434331572,'omnitool_admin',1506305991,'None',0,'6_1:15_1',NULL,'No',0),(104,1,'Jun15eric_datatypefields75','75_1','7_1','datatype_fields','eric',1434331572,'omnitool_admin',1506305967,'None',0,'6_1:15_1',NULL,'No',0),(105,1,'Jun15eric_datatypefields76','76_1','7_1','datatype_fields','eric',1434331572,'omnitool_admin',1518453595,'None',0,'6_1:15_1',NULL,'No',0),(106,1,'Jun15eric_datatypefields77','77_1','7_1','datatype_fields','eric',1434331572,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(107,1,'Jun15eric_datatypefields78','78_1','7_1','datatype_fields','eric',1434331572,'echernof',1493047311,'None',0,'6_1:15_1',NULL,'No',0),(108,1,'Jun15eric_datatypefields79','79_1','7_1','datatype_fields','eric',1434421899,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(109,1,'Jun15eric_datatypefields80','80_1','7_1','datatype_fields','eric',1434509888,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(110,1,'Oct15eric_datatypefields81','81_1','7_1','datatype_fields','eric',1445632786,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(111,1,'Oct15eric_datatypefields82','82_1','7_1','datatype_fields','eric',1445632786,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(112,1,'Oct15eric_datatypefields83','83_1','7_1','datatype_fields','eric',1445632786,'eric',1445632786,'None',0,'6_1:8_1',NULL,'No',0),(113,1,'Oct15eric_datatypefields84','84_1','7_1','datatype_fields','eric',1445632786,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(114,1,'Oct15eric_datatypefields85','85_1','7_1','datatype_fields','eric',1445632786,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(121,1,'Nov15eric_datatypefields90','90_1','7_1','datatype_fields','eric',1447276733,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(122,1,'Nov15eric_datatypefields91','91_1','7_1','datatype_fields','eric',1447303603,'omnitool_admin',1504105087,'None',0,'6_1:13_1',NULL,'No',0),(123,1,'Nov15eric_datatypefields92','92_1','7_1','datatype_fields','eric',1447732716,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(124,1,'Nov15eric_datatypefields93','93_1','7_1','datatype_fields','eric',1447796375,'omnitool_admin',1507414825,'None',0,'6_1:15_1',NULL,'No',0),(125,1,'Nov15eric_datatypefields94','94_1','7_1','datatype_fields','eric',1447797776,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(126,1,'Nov15eric_datatypefields95','95_1','7_1','datatype_fields','eric',1447798830,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(127,1,'Nov15eric_tools4','4_1','8_1','tools','eric',1447805342,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:28_1','No',0),(129,1,'Nov15eric_toolmodeconfigs1','1_1','13_1','tool_mode_configs','eric',1447907689,'omnitool_admin',1506393497,'None',0,'8_1:2_1',NULL,'No',0),(130,1,'Nov15eric_toolmodeconfigs2','2_1','13_1','tool_mode_configs','eric',1447907689,'omnitool_admin',1506393511,'None',0,'8_1:2_1',NULL,'No',0),(131,1,'Nov15eric_datatypefields96','96_1','7_1','datatype_fields','eric',1448035161,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(132,1,'Nov15eric_datatypefields97','97_1','7_1','datatype_fields','eric',1448035161,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(134,1,'Nov15eric_datatypefields99','99_1','7_1','datatype_fields','eric',1448080920,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(135,1,'Nov15eric_searchtooloptions1','1_1','16_1','search_tool_options','eric',1448144056,'eric',1448144056,'None',0,'8_1:2_1',NULL,'No',0),(136,1,'Nov15eric_datatypefields100','100_1','7_1','datatype_fields','eric',1448305585,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(139,1,'Nov15eric_datatypefields103','103_1','7_1','datatype_fields','eric',1448305679,'omnitool_admin',1500846380,'None',0,'6_1:13_1',NULL,'No',0),(140,1,'Nov15eric_toolmodeconfigs3','3_1','13_1','tool_mode_configs','eric',1448334008,'eric',1448334008,'None',0,'8_1:3_1',NULL,'No',0),(141,1,'Nov15eric_tools6','6_1','8_1','tools','eric',1448384397,'eric',1509251280,'None',0,'8_1:2_1','8_1:4_1,16_1:2_1,8_1:14_1,8_1:15_1,8_1:23_1,8_1:24_1,13_1:38_1,13_1:59_1,8_1:56_1,8_1:74_1,13_1:84_1,8_1:88_1,8_1:91_1,8_1:92_1,8_1:94_1','No',0),(142,1,'Nov15eric_tools7','7_1','8_1','tools','eric',1448384493,'eric',1489183171,'None',0,'8_1:2_1','16_1:3_1,13_1:6_1,8_1:11_1,8_1:12_1,8_1:13_1,8_1:16_1,8_1:17_1,8_1:36_1,8_1:42_1,13_1:46_1,8_1:53_1,8_1:62_1,8_1:73_1,8_1:76_1,8_1:93_1','No',0),(143,1,'Nov15eric_tools8','8_1','8_1','tools','eric',1448384493,'eric',1453684882,'None',0,'8_1:2_1','16_1:4_1,13_1:7_1,8_1:10_1,8_1:29_1,8_1:30_1,8_1:41_1,8_1:43_1,8_1:45_1,8_1:60_1,8_1:61_1','No',0),(144,1,'Nov15eric_searchtooloptions2','2_1','16_1','search_tool_options','eric',1448384808,'eric',1448384808,'None',0,'8_1:6_1',NULL,'No',0),(145,1,'Nov15eric_searchtooloptions3','3_1','16_1','search_tool_options','eric',1448384831,'eric',1448384831,'None',0,'8_1:7_1',NULL,'No',0),(146,1,'Nov15eric_searchtooloptions4','4_1','16_1','search_tool_options','eric',1448384879,'eric',1448384879,'None',0,'8_1:8_1',NULL,'No',0),(147,1,'Nov15eric_searchtooloptions5','5_1','16_1','search_tool_options','eric',1448384910,'eric',1448384910,'None',0,'8_1:1_1',NULL,'No',0),(148,1,'Nov15eric_toolmodeconfigs4','4_1','13_1','tool_mode_configs','eric',1448385123,'eric',1448385123,'None',0,'8_1:1_1',NULL,'No',0),(150,1,'Nov15eric_toolmodeconfigs6','6_1','13_1','tool_mode_configs','eric',1448385193,'echernof',1475774645,'None',0,'8_1:7_1',NULL,'No',0),(151,1,'Nov15eric_toolmodeconfigs7','7_1','13_1','tool_mode_configs','eric',1448385217,'eric',1456328916,'None',0,'8_1:8_1',NULL,'No',0),(152,1,'Nov15eric_tools9','9_1','8_1','tools','eric',1448592679,'omnitool_admin',1512314813,'None',0,'1_1:1_1','16_1:6_1,13_1:8_1,8_1:25_1,8_1:35_1,8_1:66_1,8_1:67_1,8_1:68_1,8_1:79_1','No',0),(153,1,'Nov15eric_searchtooloptions6','6_1','16_1','search_tool_options','eric',1448592749,'eric',1448592749,'None',0,'8_1:9_1',NULL,'No',0),(154,1,'Nov15eric_toolmodeconfigs8','8_1','13_1','tool_mode_configs','eric',1448592830,'eric',1449622803,'None',0,'8_1:9_1',NULL,'No',0),(155,1,'Nov15eric_tools10','10_1','8_1','tools','eric',1448593540,'echernof',1492708275,'None',0,'8_1:8_1','16_1:7_1,13_1:9_1,8_1:31_1,8_1:32_1,8_1:58_1,8_1:69_1','No',0),(156,1,'Nov15eric_searchtooloptions7','7_1','16_1','search_tool_options','eric',1448593555,'eric',1448593555,'None',0,'8_1:10_1',NULL,'No',0),(157,1,'Nov15eric_toolmodeconfigs9','9_1','13_1','tool_mode_configs','eric',1448593560,'eric',1453671296,'None',0,'8_1:10_1',NULL,'No',0),(158,1,'Nov15eric_tools11','11_1','8_1','tools','eric',1448594225,'echernof',1467167936,'None',0,'8_1:7_1','16_1:8_1,13_1:10_1,8_1:19_1,8_1:20_1,8_1:37_1,8_1:70_1,8_1:75_1','No',0),(159,1,'Nov15eric_tools12','12_1','8_1','tools','eric',1448594225,'eric',1474662098,'None',0,'8_1:7_1','16_1:9_1,13_1:11_1,8_1:33_1,8_1:34_1,8_1:40_1,8_1:78_1,8_1:87_1','No',0),(160,1,'Nov15eric_tools13','13_1','8_1','tools','eric',1448594225,'eric',1453685365,'None',0,'8_1:7_1','16_1:10_1,13_1:12_1,8_1:21_1,8_1:22_1,8_1:38_1,8_1:57_1','No',0),(161,1,'Nov15eric_searchtooloptions8','8_1','16_1','search_tool_options','eric',1448594288,'eric',1448594288,'None',0,'8_1:11_1',NULL,'No',0),(162,1,'Nov15eric_searchtooloptions9','9_1','16_1','search_tool_options','eric',1448594309,'eric',1448594309,'None',0,'8_1:12_1',NULL,'No',0),(163,1,'Nov15eric_searchtooloptions10','10_1','16_1','search_tool_options','eric',1448594324,'eric',1448594324,'None',0,'8_1:13_1',NULL,'No',0),(164,1,'Nov15eric_toolmodeconfigs10','10_1','13_1','tool_mode_configs','eric',1448594411,'eric',1448594411,'None',0,'8_1:11_1',NULL,'No',0),(165,1,'Nov15eric_toolmodeconfigs11','11_1','13_1','tool_mode_configs','eric',1448594480,'eric',1451943240,'None',0,'8_1:12_1',NULL,'No',0),(166,1,'Nov15eric_toolmodeconfigs12','12_1','13_1','tool_mode_configs','eric',1448594515,'eric',1448594515,'None',0,'8_1:13_1',NULL,'No',0),(167,1,'Nov15eric_datatypefields104','104_1','7_1','datatype_fields','eric',1448678078,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(170,1,'Dec15eric_datatypefields105','105_1','7_1','datatype_fields','eric',1449009256,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(171,1,'Dec15eric_datatypefields106','106_1','7_1','datatype_fields','eric',1449009268,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(172,1,'Dec15eric_tools14','14_1','8_1','tools','eric',1449035676,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:14_1','No',0),(173,1,'Dec15eric_toolmodeconfigs14','14_1','13_1','tool_mode_configs','eric',1449035738,'eric',1449035738,'None',0,'8_1:14_1',NULL,'No',0),(174,1,'Dec15eric_tools15','15_1','8_1','tools','eric',1449038215,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:15_1','No',0),(175,1,'Dec15eric_toolmodeconfigs15','15_1','13_1','tool_mode_configs','eric',1449038238,'eric',1449038238,'None',0,'8_1:15_1',NULL,'No',0),(176,1,'Dec15eric_tools16','16_1','8_1','tools','eric',1449128236,'eric',1449890556,'None',0,'8_1:7_1','13_1:16_1','No',0),(177,1,'Dec15eric_toolmodeconfigs16','16_1','13_1','tool_mode_configs','eric',1449128312,'eric',1449128312,'None',0,'8_1:16_1',NULL,'No',0),(178,1,'Dec15eric_tools17','17_1','8_1','tools','eric',1449129641,'eric',1450118201,'None',0,'8_1:7_1','13_1:17_1','No',0),(179,1,'Dec15eric_toolmodeconfigs17','17_1','13_1','tool_mode_configs','eric',1449129662,'eric',1449129662,'None',0,'8_1:17_1',NULL,'No',0),(181,1,'Dec15eric_tools19','19_1','8_1','tools','eric',1449345785,'echernof',1467167946,'None',0,'8_1:11_1','13_1:21_1','No',0),(182,1,'Dec15eric_tools20','20_1','8_1','tools','eric',1449345882,'echernof',1467167959,'None',0,'8_1:11_1','13_1:22_1','No',0),(183,1,'Dec15eric_tools21','21_1','8_1','tools','eric',1449346238,'eric',1449349327,'None',0,'8_1:13_1','13_1:25_1','No',0),(184,1,'Dec15eric_tools22','22_1','8_1','tools','eric',1449349392,'eric',1449349392,'None',0,'8_1:13_1','13_1:26_1','No',0),(185,1,'Dec15eric_tools23','23_1','8_1','tools','eric',1449349597,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:32_1','No',0),(186,1,'Dec15eric_tools24','24_1','8_1','tools','eric',1449349640,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:33_1','No',0),(187,1,'Dec15eric_tools25','25_1','8_1','tools','eric',1449349816,'eric',1449349816,'None',0,'8_1:9_1','13_1:36_1','No',0),(188,1,'Dec15eric_tools26','26_1','8_1','tools','eric',1449349962,'echernof',1498836782,'None',0,'8_1:2_1','13_1:30_1','No',0),(189,1,'Dec15eric_tools27','27_1','8_1','tools','eric',1449350008,'eric',1451967041,'None',0,'8_1:2_1','13_1:31_1','No',0),(190,1,'Dec15eric_tools28','28_1','8_1','tools','eric',1449350109,'eric',1454388717,'None',0,'8_1:1_1','13_1:27_1','No',0),(191,1,'Dec15eric_tools29','29_1','8_1','tools','eric',1449350157,'echernof',1492708275,'None',0,'8_1:8_1','13_1:34_1','No',0),(192,1,'Dec15eric_tools30','30_1','8_1','tools','eric',1449350203,'echernof',1492708275,'None',0,'8_1:8_1','13_1:35_1','No',0),(193,1,'Dec15eric_tools31','31_1','8_1','tools','eric',1449350285,'echernof',1463103909,'None',0,'8_1:10_1','13_1:19_1','No',0),(194,1,'Dec15eric_tools32','32_1','8_1','tools','eric',1449350386,'omnitool_admin',1524624687,'None',0,'8_1:10_1','13_1:20_1','No',0),(195,1,'Dec15eric_tools33','33_1','8_1','tools','eric',1449350768,'eric',1449350768,'None',0,'8_1:12_1','13_1:23_1','No',0),(196,1,'Dec15eric_tools34','34_1','8_1','tools','eric',1449350850,'eric',1449350850,'None',0,'8_1:12_1','13_1:24_1','No',0),(198,1,'Dec15eric_toolmodeconfigs19','19_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:31_1',NULL,'No',0),(199,1,'Dec15eric_toolmodeconfigs20','20_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:32_1',NULL,'No',0),(200,1,'Dec15eric_toolmodeconfigs21','21_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:19_1',NULL,'No',0),(201,1,'Dec15eric_toolmodeconfigs22','22_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449372078,'None',0,'8_1:20_1',NULL,'No',0),(202,1,'Dec15eric_toolmodeconfigs23','23_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:33_1',NULL,'No',0),(203,1,'Dec15eric_toolmodeconfigs24','24_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:34_1',NULL,'No',0),(204,1,'Dec15eric_toolmodeconfigs25','25_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:21_1',NULL,'No',0),(205,1,'Dec15eric_toolmodeconfigs26','26_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:22_1',NULL,'No',0),(206,1,'Dec15eric_toolmodeconfigs27','27_1','13_1','tool_mode_configs','eric',1449367907,'eric',1454388732,'None',0,'8_1:28_1',NULL,'No',0),(207,1,'Dec15eric_toolmodeconfigs28','28_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:4_1',NULL,'No',0),(208,1,'Dec15eric_toolmodeconfigs29','29_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:5_1',NULL,'No',0),(209,1,'Dec15eric_toolmodeconfigs30','30_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:26_1',NULL,'No',0),(210,1,'Dec15eric_toolmodeconfigs31','31_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:27_1',NULL,'No',0),(211,1,'Dec15eric_toolmodeconfigs32','32_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:23_1',NULL,'No',0),(212,1,'Dec15eric_toolmodeconfigs33','33_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:24_1',NULL,'No',0),(213,1,'Dec15eric_toolmodeconfigs34','34_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:29_1',NULL,'No',0),(214,1,'Dec15eric_toolmodeconfigs35','35_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:30_1',NULL,'No',0),(215,1,'Dec15eric_toolmodeconfigs36','36_1','13_1','tool_mode_configs','eric',1449367907,'eric',1449367907,'None',0,'8_1:25_1',NULL,'No',0),(217,1,'Dec15eric_tools35','35_1','8_1','tools','eric',1449369523,'eric',1449514163,'None',0,'8_1:9_1','13_1:37_1','No',0),(218,1,'Dec15eric_toolmodeconfigs37','37_1','13_1','tool_mode_configs','eric',1449369849,'eric',1449514265,'None',0,'8_1:35_1',NULL,'No',0),(219,1,'Dec15eric_databaseservers2','2_1','4_1','database_servers','eric',1449372989,'echernof',1474551975,'None',0,'top',NULL,'No',0),(220,1,'Dec15eric_toolmodeconfigs38','38_1','13_1','tool_mode_configs','eric',1449376540,'echernof',1459438335,'None',0,'8_1:6_1',NULL,'No',0),(222,1,'Dec15eric_tools36','36_1','8_1','tools','eric',1449547039,'eric',1453685313,'None',0,'8_1:7_1','13_1:39_1','No',0),(223,1,'Dec15eric_toolmodeconfigs39','39_1','13_1','tool_mode_configs','eric',1449547099,'eric',1449547099,'None',0,'8_1:36_1',NULL,'No',0),(224,1,'Dec15eric_tools37','37_1','8_1','tools','eric',1449577676,'echernof',1467167999,'None',0,'8_1:11_1','13_1:40_1','No',0),(225,1,'Dec15eric_toolmodeconfigs40','40_1','13_1','tool_mode_configs','eric',1449577739,'eric',1449577739,'None',0,'8_1:37_1',NULL,'No',0),(226,1,'Dec15eric_tools38','38_1','8_1','tools','eric',1449579473,'eric',1452224304,'None',0,'8_1:13_1','13_1:41_1','No',0),(227,1,'Dec15eric_toolmodeconfigs41','41_1','13_1','tool_mode_configs','eric',1449579503,'eric',1449579503,'None',0,'8_1:38_1',NULL,'No',0),(228,1,'Dec15eric_tools39','39_1','8_1','tools','eric',1449585269,'eric',1453684908,'None',0,'8_1:2_1','13_1:42_1','No',0),(229,1,'Dec15eric_toolmodeconfigs42','42_1','13_1','tool_mode_configs','eric',1449585370,'eric',1449585370,'None',0,'8_1:39_1',NULL,'No',0),(230,1,'Dec15eric_tools40','40_1','8_1','tools','eric',1449586254,'echernof',1460491248,'None',0,'8_1:12_1','13_1:43_1','No',0),(231,1,'Dec15eric_toolmodeconfigs43','43_1','13_1','tool_mode_configs','eric',1449586292,'eric',1449586292,'None',0,'8_1:40_1',NULL,'No',0),(232,1,'Dec15eric_tools41','41_1','8_1','tools','eric',1449586799,'echernof',1492708275,'None',0,'8_1:8_1','13_1:44_1','No',0),(233,1,'Dec15eric_toolmodeconfigs44','44_1','13_1','tool_mode_configs','eric',1449586847,'eric',1449587066,'None',0,'8_1:41_1',NULL,'No',0),(234,1,'Dec15eric_datatypefields107','107_1','7_1','datatype_fields','eric',1449587423,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(235,1,'Dec15eric_datatypefields108','108_1','7_1','datatype_fields','eric',1449587535,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(236,1,'Dec15eric_tools42','42_1','8_1','tools','eric',1449594073,'eric',1453685286,'None',0,'8_1:7_1',NULL,'No',0),(237,1,'Dec15eric_tools43','43_1','8_1','tools','eric',1449595710,'echernof',1492708275,'None',0,'8_1:8_1',NULL,'No',0),(238,1,'Dec15eric_tools44','44_1','8_1','tools','eric',1449626778,'eric',1449890668,'None',0,'8_1:2_1','13_1:45_1','No',0),(239,1,'Dec15eric_toolmodeconfigs45','45_1','13_1','tool_mode_configs','eric',1449626870,'eric',1449626870,'None',0,'8_1:44_1',NULL,'No',0),(240,1,'Dec15eric_toolmodeconfigs46','46_1','13_1','tool_mode_configs','eric',1449632436,'eric',1450152738,'None',0,'8_1:7_1',NULL,'No',0),(241,1,'Dec15eric_tools45','45_1','8_1','tools','eric',1449640637,'echernof',1492708275,'None',0,'8_1:8_1','13_1:47_1,13_1:82_1','No',0),(242,1,'Dec15eric_toolmodeconfigs47','47_1','13_1','tool_mode_configs','eric',1449640875,'omnitool_admin',1518580736,'None',0,'8_1:45_1',NULL,'No',0),(264,1,'Dec15eric_datatypefields113','113_1','7_1','datatype_fields','eric',1449777799,'eric',1453684539,'None',0,'6_1:7_1',NULL,'No',0),(267,1,'Dec15eric_tools53','53_1','8_1','tools','eric',1450119798,'eric',1453685331,'None',0,'8_1:7_1','13_1:58_1','No',0),(268,1,'Dec15eric_toolmodeconfigs58','58_1','13_1','tool_mode_configs','eric',1450120126,'eric',1450120126,'None',0,'8_1:53_1',NULL,'No',0),(269,1,'Dec15eric_datatypefields114','114_1','7_1','datatype_fields','eric',1450146138,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(270,1,'Dec15eric_datatypefields115','115_1','7_1','datatype_fields','eric',1450153209,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(271,1,'Dec15eric_toolmodeconfigs59','59_1','13_1','tool_mode_configs','eric',1450153490,'eric',1450153490,'None',0,'8_1:6_1',NULL,'No',0),(278,1,'Dec15eric_tools56','56_1','8_1','tools','eric',1450820047,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:62_1,13_1:63_1','No',0),(279,1,'Dec15eric_toolmodeconfigs62','62_1','13_1','tool_mode_configs','eric',1450901202,'eric',1450901202,'None',0,'8_1:56_1',NULL,'No',0),(280,1,'Dec15eric_toolmodeconfigs63','63_1','13_1','tool_mode_configs','eric',1450904103,'eric',1450904624,'None',0,'8_1:56_1',NULL,'No',0),(281,1,'Dec15eric_datatypefields117','117_1','7_1','datatype_fields','eric',1451533478,'eric',1454555530,'None',0,'6_1:12_1',NULL,'No',0),(282,1,'Jan16eric_datatypefields118','118_1','7_1','datatype_fields','eric',1451937890,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(285,1,'Jan16eric_datatypefields119','119_1','7_1','datatype_fields','eric',1452032298,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(289,1,'Jan16eric_tools57','57_1','8_1','tools','eric',1452323400,'eric',1454634293,'None',0,'8_1:13_1','13_1:72_1','No',0),(290,1,'Jan16eric_tools58','58_1','8_1','tools','eric',1452323478,'echernof',1463103909,'None',0,'8_1:10_1','13_1:68_1','No',0),(293,1,'Jan16eric_tools60','60_1','8_1','tools','eric',1452576434,'echernof',1492708275,'None',0,'8_1:8_1','13_1:65_1','No',0),(294,1,'Jan16eric_toolmodeconfigs65','65_1','13_1','tool_mode_configs','eric',1452576458,'eric',1452576458,'None',0,'8_1:60_1',NULL,'No',0),(296,1,'Jan16eric_tools61','61_1','8_1','tools','eric',1453339664,'echernof',1493806674,'None',0,'8_1:8_1','13_1:66_1','No',0),(297,1,'Jan16eric_toolmodeconfigs66','66_1','13_1','tool_mode_configs','eric',1453339727,'eric',1453340099,'None',0,'8_1:61_1',NULL,'No',0),(298,1,'Jan16eric_tools62','62_1','8_1','tools','eric',1453349702,'eric',1453685207,'None',0,'8_1:7_1','13_1:67_1','No',0),(299,1,'Jan16eric_toolmodeconfigs67','67_1','13_1','tool_mode_configs','eric',1453349738,'eric',1453349738,'None',0,'8_1:62_1',NULL,'No',0),(300,1,'Jan16eric_toolmodeconfigs68','68_1','13_1','tool_mode_configs','eric',1454216005,'eric',1454216005,'None',0,'8_1:58_1',NULL,'No',0),(304,1,'Feb16eric_tools63','63_1','8_1','tools','eric',1454554293,'echernof',1467395746,'None',0,'1_1:1_1','13_1:69_1,8_1:64_1,8_1:65_1,8_1:71_1','No',0),(305,1,'Feb16eric_toolmodeconfigs69','69_1','13_1','tool_mode_configs','eric',1454554334,'eric',1454554334,'None',0,'8_1:63_1',NULL,'No',0),(306,1,'Feb16eric_tools64','64_1','8_1','tools','eric',1454554439,'eric',1454554439,'None',0,'8_1:63_1','13_1:70_1','No',0),(307,1,'Feb16eric_tools65','65_1','8_1','tools','eric',1454554547,'echernof',1459534229,'None',0,'8_1:63_1','13_1:71_1','No',0),(308,1,'Feb16eric_toolmodeconfigs70','70_1','13_1','tool_mode_configs','eric',1454554614,'eric',1454554614,'None',0,'8_1:64_1',NULL,'No',0),(309,1,'Feb16eric_toolmodeconfigs71','71_1','13_1','tool_mode_configs','eric',1454554654,'eric',1454554654,'None',0,'8_1:65_1',NULL,'No',0),(310,1,'Feb16eric_datatypefields120','120_1','7_1','datatype_fields','eric',1454555018,'eric',1454555412,'None',0,'6_1:12_1',NULL,'No',0),(311,1,'Feb16eric_datatypefields121','121_1','7_1','datatype_fields','eric',1454555174,'omnitool_admin',1501300450,'None',0,'6_1:12_1',NULL,'No',0),(312,1,'Feb16eric_datatypefields122','122_1','7_1','datatype_fields','eric',1454555291,'eric',1454555412,'None',0,'6_1:12_1',NULL,'No',0),(313,1,'Feb16eric_datatypefields123','123_1','7_1','datatype_fields','eric',1454555376,'eric',1454565833,'None',0,'6_1:12_1',NULL,'No',0),(314,1,'Feb16eric_accessroles1','1_1','12_1','access_roles','eric',1454557022,'omnitool_admin',1503352328,'None',0,'top',NULL,'No',0),(315,1,'Feb16eric_datatypefields124','124_1','7_1','datatype_fields','eric',1454558413,'eric',1454564575,'None',0,'6_1:9_1',NULL,'No',0),(318,1,'Feb16eric_toolmodeconfigs72','72_1','13_1','tool_mode_configs','eric',1454634206,'eric',1454634309,'None',0,'8_1:57_1',NULL,'No',0),(319,1,'Feb16eric_datatypefields125','125_1','7_1','datatype_fields','eric',1454960073,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(320,1,'Feb16eric_tools66','66_1','8_1','tools','eric',1455050824,'eric',1455051776,'None',0,'8_1:9_1','13_1:73_1','No',0),(321,1,'Feb16eric_toolmodeconfigs73','73_1','13_1','tool_mode_configs','eric',1455050865,'eric',1455056179,'None',0,'8_1:66_1',NULL,'No',0),(322,1,'Feb16eric_tools67','67_1','8_1','tools','eric',1455073182,'eric',1455077618,'None',0,'8_1:9_1','13_1:74_1','No',0),(323,1,'Feb16eric_toolmodeconfigs74','74_1','13_1','tool_mode_configs','eric',1455077705,'eric',1455077859,'None',0,'8_1:67_1',NULL,'No',0),(328,1,'Feb16eric_datatypefields126','126_1','7_1','datatype_fields','eric',1455856424,'omnitool_admin',1523068116,'None',0,'6_1:5_1',NULL,'No',0),(329,1,'Feb16eric_datatypefields127','127_1','7_1','datatype_fields','eric',1455856456,'omnitool_admin',1523068163,'None',0,'6_1:5_1',NULL,'No',0),(331,1,'Feb16eric_datatypefields129','129_1','7_1','datatype_fields','eric',1456029700,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(336,1,'Feb16eric_tools68','68_1','8_1','tools','eric',1456480958,'eric',1456481110,'None',0,'8_1:9_1','13_1:76_1','No',0),(337,1,'Feb16eric_toolmodeconfigs76','76_1','13_1','tool_mode_configs','eric',1456481056,'eric',1456481056,'None',0,'8_1:68_1',NULL,'No',0),(338,1,'Feb16eric_datatypefields132','132_1','7_1','datatype_fields','eric',1456613471,'omnitool_admin',1500844042,'None',0,'6_1:13_1',NULL,'No',0),(339,1,'Mar16eric_datatypefields133','133_1','7_1','datatype_fields','eric',1457568022,'omnitool_admin',1501467943,'None',0,'6_1:5_1',NULL,'No',0),(340,1,'Mar16eric_datatypefields134','134_1','7_1','datatype_fields','eric',1457667875,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(341,1,'Mar16eric_datatypefields135','135_1','7_1','datatype_fields','eric',1457977055,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(344,1,'Mar16eric_datatypefields138','138_1','7_1','datatype_fields','eric',1458002710,'echernof',1486529178,'None',0,'6_1:6_1',NULL,'No',0),(346,1,'Mar16echernof_tools69','69_1','8_1','tools','echernof',1458833992,'echernof',1463103909,'None',0,'8_1:10_1','13_1:77_1','No',0),(347,1,'Mar16echernof_toolmodeconfigs77','77_1','13_1','tool_mode_configs','echernof',1458834032,'echernof',1458834032,'None',0,'8_1:69_1',NULL,'No',0),(349,1,'Mar16echernof_datatypefields140','140_1','7_1','datatype_fields','echernof',1459363539,'echernof',1499487275,'None',0,'6_1:5_1',NULL,'No',0),(350,1,'Apr16echernof_tools70','70_1','8_1','tools','echernof',1459481966,'echernof',1467167979,'None',0,'8_1:11_1','13_1:78_1','No',0),(351,1,'Apr16echernof_toolmodeconfigs78','78_1','13_1','tool_mode_configs','echernof',1459481985,'echernof',1459481985,'None',0,'8_1:70_1',NULL,'No',0),(352,1,'Apr16echernof_tools71','71_1','8_1','tools','echernof',1459490216,'echernof',1459490216,'None',0,'8_1:63_1','13_1:79_1','No',0),(353,1,'Apr16echernof_toolmodeconfigs79','79_1','13_1','tool_mode_configs','echernof',1459490233,'echernof',1459490233,'None',0,'8_1:71_1',NULL,'No',0),(354,1,'Apr16echernof_datatypefields141','141_1','7_1','datatype_fields','echernof',1459546416,'omnitool_admin',1500866755,'None',0,'6_1:5_1',NULL,'No',0),(357,1,'Apr16echernof_tools72','72_1','8_1','tools','echernof',1461551091,'echernof',1467395746,'None',0,'1_1:1_1','13_1:80_1,8_1:77_1,13_1:89_1','No',0),(358,1,'Apr16echernof_toolmodeconfigs80','80_1','13_1','tool_mode_configs','echernof',1461551116,'echernof',1461552850,'None',0,'8_1:72_1',NULL,'No',0),(360,1,'Apr16echernof_tools73','73_1','8_1','tools','echernof',1461725270,'echernof',1461725365,'None',0,'8_1:7_1','13_1:81_1','No',0),(361,1,'Apr16echernof_toolmodeconfigs81','81_1','13_1','tool_mode_configs','echernof',1461725301,'echernof',1461725301,'None',0,'8_1:73_1',NULL,'No',0),(362,1,'May16echernof_toolmodeconfigs82','82_1','13_1','tool_mode_configs','echernof',1462762576,'echernof',1462762576,'None',0,'8_1:45_1',NULL,'No',0),(363,1,'May16echernof_tools74','74_1','8_1','tools','echernof',1463154584,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:83_1,13_1:85_1','No',0),(364,1,'May16echernof_toolmodeconfigs83','83_1','13_1','tool_mode_configs','echernof',1463154607,'echernof',1463154612,'None',0,'8_1:74_1',NULL,'No',0),(365,1,'May16echernof_toolmodeconfigs84','84_1','13_1','tool_mode_configs','echernof',1463155756,'echernof',1463155756,'None',0,'8_1:6_1',NULL,'No',0),(366,1,'May16echernof_toolmodeconfigs85','85_1','13_1','tool_mode_configs','echernof',1463155869,'echernof',1463274029,'None',0,'8_1:74_1',NULL,'No',0),(367,1,'May16echernof_tools75','75_1','8_1','tools','echernof',1463538586,'echernof',1467167969,'None',0,'8_1:11_1','13_1:86_1','No',0),(368,1,'May16echernof_toolmodeconfigs86','86_1','13_1','tool_mode_configs','echernof',1463538613,'echernof',1463538613,'None',0,'8_1:75_1',NULL,'No',0),(369,1,'May16echernof_datatypefields144','144_1','7_1','datatype_fields','echernof',1463595899,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(370,1,'May16echernof_datatypefields145','145_1','7_1','datatype_fields','echernof',1463598439,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(371,1,'May16echernof_datatypefields146','146_1','7_1','datatype_fields','echernof',1463712193,'echernof',1463712765,'None',0,'6_1:7_1',NULL,'No',0),(372,1,'Jun16echernof_tools76','76_1','8_1','tools','echernof',1464925223,'echernof',1464925249,'None',0,'8_1:7_1','13_1:87_1','No',0),(373,1,'Jun16echernof_toolmodeconfigs87','87_1','13_1','tool_mode_configs','echernof',1464925249,'echernof',1464925249,'None',0,'8_1:76_1',NULL,'No',0),(374,1,'Jun16echernof_datatypefields147','147_1','7_1','datatype_fields','echernof',1465179673,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(375,1,'Jun16echernof_tools77','77_1','8_1','tools','echernof',1465498500,'omnitool_admin',1500347120,'None',0,'8_1:72_1','13_1:88_1','No',0),(376,1,'Jun16echernof_toolmodeconfigs88','88_1','13_1','tool_mode_configs','echernof',1465498661,'echernof',1465498661,'None',0,'8_1:77_1',NULL,'No',0),(377,1,'Jun16echernof_toolmodeconfigs89','89_1','13_1','tool_mode_configs','echernof',1465937803,'echernof',1465937803,'None',0,'8_1:72_1',NULL,'No',0),(378,1,'Jun16echernof_tools78','78_1','8_1','tools','echernof',1466190683,'echernof',1466190777,'None',0,'8_1:12_1','13_1:90_1','No',0),(379,1,'Jun16echernof_toolmodeconfigs90','90_1','13_1','tool_mode_configs','echernof',1466190777,'echernof',1466190777,'None',0,'8_1:78_1',NULL,'No',0),(380,1,'Jun16echernof_datatypefields148','148_1','7_1','datatype_fields','echernof',1466193728,'echernof',1490908810,'None',0,'6_1:15_1',NULL,'No',0),(381,1,'Jun16echernof_datatypefields149','149_1','7_1','datatype_fields','echernof',1467051819,'omnitool_admin',1503248288,'None',0,'6_1:1_1',NULL,'No',0),(382,1,'Jul16echernof_datatypes18','18_1','6_1','datatypes','echernof',1467386945,'echernof',1489686739,'echernof',1489687607,'1_1:1_1','7_1:150_1,7_1:151_1,7_1:152_1,7_1:153_1,7_1:154_1,7_1:164_1','No',0),(383,1,'Jul16echernof_datatypefields150','150_1','7_1','datatype_fields','echernof',1467386983,'echernof',1489687007,'None',0,'6_1:18_1',NULL,'No',0),(384,1,'Jul16echernof_datatypefields151','151_1','7_1','datatype_fields','echernof',1467387039,'echernof',1489687007,'None',0,'6_1:18_1',NULL,'No',0),(385,1,'Jul16echernof_datatypefields152','152_1','7_1','datatype_fields','echernof',1467387094,'echernof',1489687007,'None',0,'6_1:18_1',NULL,'No',0),(386,1,'Jul16echernof_datatypefields153','153_1','7_1','datatype_fields','echernof',1467387128,'echernof',1489687007,'None',0,'6_1:18_1',NULL,'No',0),(387,1,'Jul16echernof_tools79','79_1','8_1','tools','echernof',1467387242,'echernof',1467603973,'None',0,'1_1:1_1','13_1:91_1,8_1:80_1,8_1:81_1,8_1:82_1,15_1:7_1,8_1:83_1,8_1:84_1,8_1:85_1,8_1:86_1','No',0),(388,1,'Jul16echernof_toolmodeconfigs91','91_1','13_1','tool_mode_configs','echernof',1467387257,'echernof',1489686776,'None',0,'8_1:79_1',NULL,'No',0),(389,1,'Jul16echernof_tools80','80_1','8_1','tools','echernof',1467387350,'echernof',1467398494,'None',0,'8_1:79_1','13_1:92_1','No',0),(390,1,'Jul16echernof_tools81','81_1','8_1','tools','echernof',1467387397,'echernof',1467398494,'None',0,'8_1:79_1','13_1:93_1','No',0),(391,1,'Jul16echernof_tools82','82_1','8_1','tools','echernof',1467387447,'echernof',1467824548,'None',0,'8_1:79_1','13_1:94_1','No',0),(392,1,'Jul16echernof_toolmodeconfigs92','92_1','13_1','tool_mode_configs','echernof',1467387483,'echernof',1467387490,'None',0,'8_1:80_1',NULL,'No',0),(393,1,'Jul16echernof_toolmodeconfigs93','93_1','13_1','tool_mode_configs','echernof',1467387511,'echernof',1467387511,'None',0,'8_1:81_1',NULL,'No',0),(394,1,'Jul16echernof_toolmodeconfigs94','94_1','13_1','tool_mode_configs','echernof',1467387555,'echernof',1467387555,'None',0,'8_1:82_1',NULL,'No',0),(395,1,'Jul16echernof_datatypefields154','154_1','7_1','datatype_fields','echernof',1467387592,'echernof',1489687007,'None',0,'6_1:18_1',NULL,'No',0),(396,1,'Jul16echernof_toolfiltermenus7','7_1','15_1','tool_filter_menus','echernof',1467387704,'echernof',1467387704,'None',0,'8_1:79_1',NULL,'No',0),(397,1,'Jul16echernof_tools83','83_1','8_1','tools','echernof',1467393554,'echernof',1467398494,'None',0,'8_1:79_1',NULL,'No',0),(399,1,'Jul16echernof_tools84','84_1','8_1','tools','echernof',1467396620,'echernof',1467398494,'None',0,'8_1:79_1','13_1:95_1','No',0),(400,1,'Jul16echernof_toolmodeconfigs95','95_1','13_1','tool_mode_configs','echernof',1467396642,'echernof',1467396642,'None',0,'8_1:84_1',NULL,'No',0),(401,1,'Jul16echernof_tools85','85_1','8_1','tools','echernof',1467397718,'echernof',1467398494,'None',0,'8_1:79_1','13_1:96_1','No',0),(402,1,'Jul16echernof_toolmodeconfigs96','96_1','13_1','tool_mode_configs','echernof',1467397753,'echernof',1467397753,'None',0,'8_1:85_1',NULL,'No',0),(403,1,'Jul16echernof_tools86','86_1','8_1','tools','echernof',1467398129,'echernof',1467398494,'None',0,'8_1:79_1','13_1:97_1','No',0),(404,1,'Jul16echernof_toolmodeconfigs97','97_1','13_1','tool_mode_configs','echernof',1467398159,'echernof',1467398159,'None',0,'8_1:86_1',NULL,'No',0),(405,1,'Jul16echernof_datatypefields155','155_1','7_1','datatype_fields','echernof',1467429348,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(406,1,'Jul16echernof_datatypefields156','156_1','7_1','datatype_fields','echernof',1468463702,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(407,1,'Aug16echernof_datatypefields157','157_1','7_1','datatype_fields','echernof',1470107538,'echernof',1490908810,'None',NULL,'6_1:15_1',NULL,'No',0),(408,1,'Aug16echernof_datatypefields158','158_1','7_1','datatype_fields','echernof',1470336163,'echernof',1486529178,'None',NULL,'6_1:6_1',NULL,'No',0),(409,1,'Sep16echernof_datatypefields159','159_1','7_1','datatype_fields','echernof',1474383141,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(410,1,'Sep16echernof_instances8','8_1','5_1','instances','echernof',1474551945,'omnitool_admin',1500266787,'None',0,'1_1:1_1',NULL,'No',0),(412,1,'Sep16echernof_tools87','87_1','8_1','tools','echernof',1474662098,'echernof',1474662176,'None',NULL,'8_1:12_1','13_1:98_1','No',0),(413,1,'Sep16echernof_toolmodeconfigs98','98_1','13_1','tool_mode_configs','echernof',1474662176,'echernof',1474662176,'None',NULL,'8_1:87_1',NULL,'No',0),(414,1,'Oct16echernof_datatypefields160','160_1','7_1','datatype_fields','echernof',1477669657,'echernof',1477669657,'None',NULL,'6_1:7_1',NULL,'No',0),(415,1,'Nov16echernof_tools88','88_1','8_1','tools','echernof',1477972986,'omnitool_admin',1509254251,'None',NULL,'8_1:6_1',NULL,'No',0),(418,1,'Nov16echernof_tools90','90_1','8_1','tools','echernof',1478116034,'echernof',1478116144,'None',0,'8_1:2_1','13_1:100_1','No',0),(419,1,'Nov16echernof_toolmodeconfigs100','100_1','13_1','tool_mode_configs','echernof',1478116047,'echernof',1478116051,'None',0,'8_1:90_1',NULL,'No',0),(420,1,'Nov16echernof_omnitoolusers1','1_1','9_1','omnitool_users','echernof',1478402436,'omnitool_admin',1510633167,'None',0,'top',NULL,'No',0),(421,1,'Dec16echernof_tools91','91_1','8_1','tools','echernof',1481231218,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:101_1','No',0),(422,1,'Dec16echernof_toolmodeconfigs101','101_1','13_1','tool_mode_configs','echernof',1481231259,'echernof',1481231259,'None',NULL,'8_1:91_1',NULL,'No',0),(423,1,'Dec16echernof_tools92','92_1','8_1','tools','echernof',1482548564,'omnitool_admin',1509254251,'None',0,'8_1:6_1','13_1:102_1','No',0),(424,1,'Dec16echernof_toolmodeconfigs102','102_1','13_1','tool_mode_configs','echernof',1482550485,'echernof',1482550485,'None',NULL,'8_1:92_1',NULL,'No',0),(425,1,'Jan17echernof_datatypefields161','161_1','7_1','datatype_fields','echernof',1483940367,'echernof',1486529178,'None',NULL,'6_1:6_1',NULL,'No',0),(426,1,'Feb17echernof_datatypefields162','162_1','7_1','datatype_fields','echernof',1486528885,'echernof',1486529178,'None',NULL,'6_1:6_1',NULL,'No',0),(427,1,'Feb17echernof_datatypefields163','163_1','7_1','datatype_fields','echernof',1486529139,'omnitool_admin',1500844042,'None',NULL,'6_1:13_1',NULL,'No',0),(428,1,'Mar17echernof_tools93','93_1','8_1','tools','echernof',1489183171,'echernof',1489462260,'None',0,'8_1:7_1','13_1:103_1','No',0),(429,1,'Mar17echernof_toolmodeconfigs103','103_1','13_1','tool_mode_configs','echernof',1489183207,'echernof',1489183207,'None',NULL,'8_1:93_1',NULL,'No',0),(430,1,'Mar17echernof_datatypefields164','164_1','7_1','datatype_fields','echernof',1489686739,'echernof',1489687007,'None',NULL,'6_1:18_1',NULL,'No',0),(431,1,'May17echernof_datatypefields165','165_1','7_1','datatype_fields','echernof',1495573877,'omnitool_admin',1518140593,'None',0,'6_1:8_1',NULL,'No',0),(432,1,'Jul17echernof_datatypefields166','166_1','7_1','datatype_fields','echernof',1499487257,'echernof',1499487275,'None',NULL,'6_1:5_1',NULL,'No',0),(433,1,'Jul17eric_instances9','9_1','5_1','instances','eric',1500265958,'omnitool_admin',1501216714,'None',0,'1_1:1_1',NULL,'No',0),(434,1,'Jul17eric_instances10','10_1','5_1','instances','eric',1500266062,'omnitool_admin',1500517940,'None',0,'1_1:1_1',NULL,'No',0),(435,1,'Jul17omnitool_admin_datatypefields167','167_1','7_1','datatype_fields','omnitool_admin',1500843550,'omnitool_admin',1500844042,'None',NULL,'6_1:13_1',NULL,'No',0),(436,1,'Jul17omnitool_admin_datatypefields168','168_1','7_1','datatype_fields','omnitool_admin',1501389847,'omnitool_admin',1501389847,'None',NULL,'6_1:9_1',NULL,'No',0),(437,1,'Jul17omnitool_admin_datatypefields169','169_1','7_1','datatype_fields','omnitool_admin',1501389886,'omnitool_admin',1501389908,'None',0,'6_1:9_1',NULL,'No',0),(439,1,'Aug17omnitool_admin_datatypefields170','170_1','7_1','datatype_fields','omnitool_admin',1503248184,'omnitool_admin',1503248288,'None',NULL,'6_1:1_1',NULL,'No',0),(440,1,'Aug17omnitool_admin_datatypefields171','171_1','7_1','datatype_fields','omnitool_admin',1503248264,'omnitool_admin',1503248288,'None',NULL,'6_1:1_1',NULL,'No',0),(442,1,'Sep17omnitool_admin_datatypefields173','173_1','7_1','datatype_fields','omnitool_admin',1506393469,'omnitool_admin',1506393469,'None',NULL,'6_1:1_1',NULL,'No',0),(444,1,'Oct17omnitool_admin_toolmodeconfigs104','104_1','13_1','tool_mode_configs','omnitool_admin',1509251355,'omnitool_admin',1509251355,'None',NULL,'8_1:94_1',NULL,'No',0),(445,1,'Feb18omnitool_admin_datatypefields174','174_1','7_1','datatype_fields','omnitool_admin',1518140549,'omnitool_admin',1518140593,'None',NULL,'6_1:8_1',NULL,'No',0),(446,1,'Apr18omnitool_admin_datatypefields175','175_1','7_1','datatype_fields','omnitool_admin',1523590551,'omnitool_admin',1523590605,'None',0,'6_1:13_1',NULL,'No',0);
/*!40000 ALTER TABLE `metainfo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `omnitool_users`
--

DROP TABLE IF EXISTS `omnitool_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `omnitool_users` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `username` varchar(35) NOT NULL,
  `password` varchar(250) NOT NULL,
  `hard_set_access_roles` text,
  `require_password_change` varchar(3) DEFAULT NULL,
  `password_set_date` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `omnitool_users`
--

LOCK TABLES `omnitool_users` WRITE;
/*!40000 ALTER TABLE `omnitool_users` DISABLE KEYS */;
INSERT INTO `omnitool_users` VALUES (1,1,'top','OmniTool Admin','omnitool_admin','{X-PBKDF2}HMACSHA3+512:AADDUA:ruGdiBTqlFMnWLkTBmnRqDDeXDO99PpMJ1hz7F1Y:dG1mVqH4XqLM0UwDsrgQ5RHZVI/mUdGP6R05TemyDKYFoVUf3VQSBtRTtCi5f0dDNeJHxfNbOU6SSiCjBKfYkA==','10_1::1_1,11_1::1_1,1_1::1_1,8_1::1_1,9_1::1_1,12_1::1_1','No','2018-07-21');
/*!40000 ALTER TABLE `omnitool_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizers`
--

DROP TABLE IF EXISTS `organizers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `organizers` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `parent` varchar(30) NOT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizers`
--

LOCK TABLES `organizers` WRITE;
/*!40000 ALTER TABLE `organizers` DISABLE KEYS */;
INSERT INTO `organizers` VALUES (1,1,'Database Servers','top'),(2,1,'Access Groups','top'),(3,1,'OmniTool Users','top');
/*!40000 ALTER TABLE `organizers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `record_coloring_rules`
--

DROP TABLE IF EXISTS `record_coloring_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `record_coloring_rules` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `match_field` varchar(50) DEFAULT NULL,
  `match_type` enum('Does Match','Does NOT Match') DEFAULT NULL,
  `match_string` varchar(150) NOT NULL,
  `apply_color` varchar(40) NOT NULL DEFAULT 'Gray',
  `priority` int(2) unsigned DEFAULT '0',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `record_coloring_rules`
--

LOCK TABLES `record_coloring_rules` WRITE;
/*!40000 ALTER TABLE `record_coloring_rules` DISABLE KEYS */;
/*!40000 ALTER TABLE `record_coloring_rules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `running_background_tasks`
--

DROP TABLE IF EXISTS `running_background_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `running_background_tasks` (
  `worker_id` int(10) NOT NULL,
  `process_id` int(10) NOT NULL,
  `datatype_id` varchar(30) NOT NULL,
  PRIMARY KEY (`worker_id`,`process_id`),
  KEY `datatype_id` (`datatype_id`,`worker_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `running_background_tasks`
--

LOCK TABLES `running_background_tasks` WRITE;
/*!40000 ALTER TABLE `running_background_tasks` DISABLE KEYS */;
/*!40000 ALTER TABLE `running_background_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `search_tool_options`
--

DROP TABLE IF EXISTS `search_tool_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_tool_options` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `target_datatype` varchar(30) NOT NULL,
  `query_interval` enum('0','30','60','120','300','600') NOT NULL DEFAULT '60',
  `load_trees` enum('No','Yes') DEFAULT 'No',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `search_tool_options`
--

LOCK TABLES `search_tool_options` WRITE;
/*!40000 ALTER TABLE `search_tool_options` DISABLE KEYS */;
INSERT INTO `search_tool_options` VALUES (1,1,'8_1:2_1','Application Search','1_1','0','No'),(2,1,'8_1:6_1','Application Instance Search','5_1','0','No'),(3,1,'8_1:7_1','Tool Search','8_1','0','No'),(4,1,'8_1:8_1','Datatype Search','6_1','0','No'),(5,1,'8_1:1_1','Database Search','4_1','0','No'),(6,1,'8_1:9_1','User Search','9_1','0','No'),(7,1,'8_1:10_1','User Search','7_1','0','No'),(8,1,'8_1:11_1','User Search','13_1','0','No'),(9,1,'8_1:12_1','User Search','15_1','0','No'),(10,1,'8_1:13_1','User Search','14_1','0','No');
/*!40000 ALTER TABLE `search_tool_options` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stored_files`
--

DROP TABLE IF EXISTS `stored_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stored_files` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `location` varchar(100) NOT NULL,
  `filename` varchar(100) NOT NULL,
  `suffix` varchar(12) NOT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `updated` int(11) unsigned DEFAULT NULL,
  `size_in_kb` int(11) unsigned DEFAULT NULL,
  `tied_to_record_type` varchar(30) DEFAULT NULL,
  `tied_to_record_id` varchar(30) DEFAULT NULL,
  `tied_to_record_field` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `tied_to_record` (`tied_to_record_type`,`tied_to_record_id`,`tied_to_record_field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stored_files`
--

LOCK TABLES `stored_files` WRITE;
/*!40000 ALTER TABLE `stored_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `stored_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tool_filter_menus`
--

DROP TABLE IF EXISTS `tool_filter_menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tool_filter_menus` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `applies_to_table_column` varchar(200) NOT NULL DEFAULT 'name',
  `matches_relate_to_tool_dt` varchar(200) NOT NULL DEFAULT 'Direct',
  `display_area` enum('Quick Search','Advanced Search') DEFAULT 'Advanced Search',
  `menu_type` varchar(50) DEFAULT 'Single-Select',
  `menu_options_type` enum('Comma-Separated List','Name/Value Pairs','Method','SQL Command') DEFAULT 'Comma-Separated List',
  `menu_options` mediumtext,
  `menu_options_method` varchar(30) DEFAULT NULL,
  `sql_cmd` mediumtext,
  `sql_bind_values` text,
  `search_operator` varchar(10) NOT NULL DEFAULT '=',
  `default_option_value` varchar(60) DEFAULT NULL,
  `priority` int(2) unsigned DEFAULT '0',
  `trigger_menu` varchar(300) DEFAULT NULL,
  `instructions` mediumtext,
  `support_any_all_option` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_filter_menus`
--

LOCK TABLES `tool_filter_menus` WRITE;
/*!40000 ALTER TABLE `tool_filter_menus` DISABLE KEYS */;
INSERT INTO `tool_filter_menus` VALUES (7,1,'8_1:79_1','Status','status','Direct','Quick Search','Single-Select','Comma-Separated List','Active,Inactive',NULL,NULL,NULL,'=','Active',1,NULL,NULL,'Yes');
/*!40000 ALTER TABLE `tool_filter_menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tool_mode_configs`
--

DROP TABLE IF EXISTS `tool_mode_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tool_mode_configs` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `mode_type` varchar(50) DEFAULT NULL,
  `custom_template` varchar(200) DEFAULT NULL,
  `custom_type_name` varchar(35) DEFAULT NULL,
  `execute_function_on_load` varchar(100) DEFAULT 'None',
  `priority` int(2) DEFAULT '1',
  `fields_to_include` text,
  `default_sort_column` varchar(20) DEFAULT NULL,
  `default_sort_direction` varchar(12) DEFAULT NULL,
  `access_roles` text,
  `max_results` varchar(100) DEFAULT NULL,
  `single_record_jemplate_block` varchar(100) DEFAULT NULL,
  `display_a_chart` varchar(20) DEFAULT NULL,
  `single_record_refresh_mode` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_mode_configs`
--

LOCK TABLES `tool_mode_configs` WRITE;
/*!40000 ALTER TABLE `tool_mode_configs` DISABLE KEYS */;
INSERT INTO `tool_mode_configs` VALUES (1,1,'8_1:2_1','Table View','Table',NULL,NULL,'None',1,'173_1,5_1,4_1',NULL,'Ascending','','No Max',NULL,'No',NULL),(2,1,'8_1:2_1','Widgets View','Widgets',NULL,NULL,'None',2,'173_1,4_1,118_1,5_1',NULL,'Ascending','','No Max',NULL,'No',NULL),(3,1,'8_1:3_1','Form View','ScreenForm_DisplayInstructions','','','None',1,'name,contact_email','name','','0','No Max',NULL,'No',NULL),(4,1,'8_1:1_1','Table View','Table','','','None',1,'Name,15_1,16_1','name','','0','No Max',NULL,'No',NULL),(6,1,'8_1:7_1','Table View','Table',NULL,NULL,'None',1,'114_1,81_1,84_1',NULL,'Ascending','','No Max',NULL,'No',NULL),(7,1,'8_1:8_1','Table View','Table',NULL,NULL,'None',1,'Name,28_1','28_1','Ascending','','No Max',NULL,'No',NULL),(8,1,'8_1:9_1','Table View','Table',NULL,NULL,'None',1,'46_1,Name','46_1','Ascending',NULL,'No Max',NULL,'No',NULL),(9,1,'8_1:10_1','Table View','Table',NULL,NULL,'None',1,'Name,38_1,113_1','Name','Ascending',NULL,'No Max',NULL,'No',NULL),(10,1,'8_1:11_1','Table View','Table','','',NULL,1,'Name,58_1','Name','','0','No Max',NULL,'No',NULL),(11,1,'8_1:12_1','Table View','Table',NULL,NULL,'None',1,'Name,72_1,75_1','Name','Ascending',NULL,'No Max',NULL,'No',NULL),(12,1,'8_1:13_1','Table View','Table','','',NULL,1,'Name,70_1','Name','','0','No Max',NULL,'No',NULL),(14,1,'8_1:14_1','Message View','MessageView','','',NULL,1,'','Name','','0','No Max',NULL,'No',NULL),(15,1,'8_1:15_1','Modal View','MessageModal','','',NULL,1,'','Name','','0','No Max',NULL,'No',NULL),(16,1,'8_1:16_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(17,1,'8_1:17_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(19,1,'8_1:31_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(20,1,'8_1:32_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(21,1,'8_1:19_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(22,1,'8_1:20_1','Full Screen Form','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(23,1,'8_1:33_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(24,1,'8_1:34_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(25,1,'8_1:21_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(26,1,'8_1:22_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(27,1,'8_1:28_1','Full Screen Form','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,'Name','Ascending',NULL,'No Max',NULL,'No',NULL),(28,1,'8_1:4_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(29,1,'8_1:5_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(30,1,'8_1:26_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(31,1,'8_1:27_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(32,1,'8_1:23_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(33,1,'8_1:24_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(34,1,'8_1:29_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(35,1,'8_1:30_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(36,1,'8_1:25_1','Full Screen Form','ScreenForm_DisplayInstructions','','','None',1,'','Name','','0','No Max',NULL,'No',NULL),(37,1,'8_1:35_1','Full Screen Form','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(38,1,'8_1:6_1','Table View','Table',NULL,NULL,'None',1,'Name,129_1,115_1,10_1',NULL,'Ascending','','No Max',NULL,'No',NULL),(39,1,'8_1:36_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',NULL,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(40,1,'8_1:37_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(41,1,'8_1:38_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(42,1,'8_1:39_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(43,1,'8_1:40_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(44,1,'8_1:41_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,'',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(45,1,'8_1:44_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(46,1,'8_1:7_1','Widgets View','Widgets',NULL,NULL,'None',2,'Name,114_1,81_1,19_1',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(47,1,'8_1:45_1','Details View','Complex_Details',NULL,NULL,'complex_data_tab_remembering',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(58,1,'8_1:53_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',NULL,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(59,1,'8_1:6_1','JSON View','JSONShow',NULL,NULL,'None',NULL,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(62,1,'8_1:56_1','JSON-View','JSONShow',NULL,NULL,'None',2,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(63,1,'8_1:56_1','Table Maker View','Custom','make_tables.tt','Table Manager','None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(65,1,'8_1:60_1','Modal View','MessageModal',NULL,NULL,'None',1,'Name',NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(66,1,'8_1:61_1','Generate Sub-Class','Custom','generate_subclasses.tt','Generate Sub-Class','None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(67,1,'8_1:62_1','Generate Sub-Class','Custom','generate_subclasses.tt','Generate Sub-Class','None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(68,1,'8_1:58_1','Modal View','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(69,1,'8_1:63_1','Table View','Table',NULL,NULL,'None',NULL,'Name,117_1','Name','Ascending',NULL,'No Max',NULL,'No',NULL),(70,1,'8_1:64_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(71,1,'8_1:65_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending',NULL,'No Max',NULL,'No',NULL),(72,1,'8_1:57_1','Message Modal','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(73,1,'8_1:66_1','Flush User Session Form','ModalForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(74,1,'8_1:67_1','View User Access','Custom','view_users_access.tt','View User Access','None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(76,1,'8_1:68_1','Message Modal','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(77,1,'8_1:69_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(78,1,'8_1:70_1','Message Modal','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(79,1,'8_1:71_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(80,1,'8_1:72_1','Form Results View','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(81,1,'8_1:73_1','Delete View','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(82,1,'8_1:45_1','JSON View','JSONShow',NULL,NULL,'None',2,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(83,1,'8_1:74_1','JSON View','JSONShow',NULL,NULL,'None',2,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(84,1,'8_1:6_1','Form Results View','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(85,1,'8_1:74_1','Results View','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(86,1,'8_1:75_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(87,1,'8_1:76_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(88,1,'8_1:77_1','Search Display','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(89,1,'8_1:72_1','JSON View','JSONShow',NULL,NULL,'None',2,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(90,1,'8_1:78_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(91,1,'8_1:79_1','Table View','Table',NULL,'Table View','None',1,'150_1,164_1,152_1',NULL,'Ascending','','No Max',NULL,'No',NULL),(92,1,'8_1:80_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(93,1,'8_1:81_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(94,1,'8_1:82_1','Confirmation Modal','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(95,1,'8_1:84_1','Form View','ModalForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(96,1,'8_1:85_1','Form View','ModalForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(97,1,'8_1:86_1','View Details','BasicDetailsModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(98,1,'8_1:87_1','MessageModal','MessageModal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(100,1,'8_1:90_1','Results Form','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(101,1,'8_1:91_1','Modal Form View','ModalForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(102,1,'8_1:92_1','Paragraphs Modal','Paragraphs_Plus_a_Link_Modal',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(103,1,'8_1:93_1','Form-View','ScreenForm_DisplayInstructions',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL),(104,1,'8_1:94_1','Results','Results_SearchForm',NULL,NULL,'None',1,NULL,NULL,'Ascending','','No Max',NULL,'No',NULL);
/*!40000 ALTER TABLE `tool_mode_configs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tools`
--

DROP TABLE IF EXISTS `tools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tools` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'Not Named',
  `access_roles` text,
  `perl_module` varchar(200) DEFAULT 'None',
  `uri_path_base` varchar(200) DEFAULT NULL,
  `javascript_class` varchar(100) DEFAULT 'None',
  `default_mode` varchar(30) DEFAULT NULL,
  `description` text,
  `tool_type` enum('Search - Screen','Action - Screen','Action - Modal','Action - Message Display') DEFAULT 'Search - Screen',
  `keep_warm` varchar(8) DEFAULT NULL,
  `icon_fa_glyph` varchar(100) DEFAULT 'fa-wrench',
  `button_name` varchar(20) NOT NULL,
  `link_type` enum('Menubar','Inline / Data Row','Quick Actions','Hidden / None') DEFAULT 'Menubar',
  `link_match_string` varchar(100) DEFAULT NULL,
  `link_match_field` varchar(100) DEFAULT NULL,
  `priority` int(3) unsigned DEFAULT '1',
  `is_locking` enum('No','Yes') DEFAULT 'No',
  `lock_lifetime` enum('0','5','10','20','30') DEFAULT '0',
  `target_datatype` varchar(30) DEFAULT NULL,
  `query_interval` enum('0','30','60','120','300','600') DEFAULT '0',
  `load_trees` enum('No','Yes') DEFAULT 'No',
  `message_is_sticky` enum('No','Yes') DEFAULT 'No',
  `message_time` int(2) DEFAULT '20',
  `share_parent_inline_action_tools` varchar(3) DEFAULT NULL,
  `display_description` varchar(3) DEFAULT NULL,
  `require_quick_search_keyword` varchar(3) DEFAULT NULL,
  `menus_required_for_search` varchar(3) DEFAULT NULL,
  `display_tool_controls` varchar(3) DEFAULT NULL,
  `supports_advanced_sorting` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=95 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tools`
--

LOCK TABLES `tools` WRITE;
/*!40000 ALTER TABLE `tools` DISABLE KEYS */;
INSERT INTO `tools` VALUES (1,1,'1_1:1_1','Manage Database Servers','1_1','None','db_servers','None','4_1','Manage connections to available database servers in this OmniTool system.','Search - Screen','No','fa-database','Database Servers','Menubar',NULL,NULL,4,'No',NULL,'4_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(2,1,'1_1:1_1','OmniTool Administration','1_1','None','ot_admin','None','1_1','Allows admins to create Applications and manage the Tools, Datatypes, and Instances for those Applications.  See docs in dispatcher.pm.','Search - Screen','No','fa-sliders','OT Admin','Menubar',NULL,NULL,1,'No',NULL,'1_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(3,1,'8_1:1_1','Create a Database Server',NULL,'standard_data_actions','create','None','3_1',NULL,'Action - Screen',NULL,'fa-plus','Create DB Svr','Quick Actions',NULL,NULL,1,NULL,NULL,'4_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(4,1,'8_1:6_1','Flush Datatype Cache',NULL,'flush_datatype_hashes','flush_dt_cache','None',NULL,NULL,'Action - Message Display','No','fa-random','Flush DT Cache','Inline / Data Row',NULL,NULL,3,'No',NULL,'5_1','60','No','No',10,'No',NULL,'No','0','Yes',NULL),(6,1,'8_1:2_1','Manage Application Instances',NULL,'None','app_instances','None','38_1','Allows admins to create and update Instances of the parent Application.','Search - Screen','No','fa-desktop','Manage Instances','Inline / Data Row',NULL,NULL,4,'No',NULL,'5_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(7,1,'8_1:2_1','Manage Tools',NULL,'tool_manager','tools_mgr','None','6_1','Allows admins to create and configure Tools, including display, access and search behavior.','Search - Screen','Never','fa-sitemap','Manage Tools','Inline / Data Row',NULL,NULL,2,'No',NULL,'8_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(8,1,'8_1:2_1','Manage Datatypes',NULL,'None','datatype_mgr','None','7_1','Allows admins to create and manage Datatypes, which are the configurations which drive OmniClass objects.','Search - Screen','No','fa-copy','Manage Datatypes','Inline / Data Row',NULL,NULL,3,'No',NULL,'6_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(9,1,'1_1:1_1','Manage OmniTool Users','1_1','None','otusers','None','8_1','Manage users\' credentials for this OmniTool system.  Users can log into any Instance tied to this OmniTool Admin database, though they may not have access to any Tools in an Instance.  This database will be checked first in case of any authentication plugins.  \n\n<b>NOTE: Once a user authenticates via one OmniTool Admin database, they can operate as that username for ALL Applications on your system, across all your OmniTool Admin databases.</b>  Keep your usernames unique or plan your Access Roles accordingly.','Search - Screen','Yes','fa-users','Manage Users','Menubar',NULL,NULL,2,'No',NULL,'9_1',NULL,'No','No',10,'No','Yes','No',NULL,'Yes',NULL),(10,1,'8_1:8_1','Manage Datatype Fields',NULL,'None','datatype_fields','None','9_1','Allows admins to create and manage the fields under the Datatype definitions, including database table columns and virtual fields driven by Perl methods.','Search - Screen','No','fa-file-o','Manage DT Fields','Inline / Data Row',NULL,NULL,4,'No',NULL,'7_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(11,1,'8_1:7_1','Manage Tool View Mode Configs','','None','mode_configs','None',NULL,'Allows admins to create and manage Display Modes for tools (aka \'views\'), which tie to Jemplate templates.','Search - Screen','No','fa-gear','Tool View Modes','Inline / Data Row',NULL,NULL,3,'No',NULL,'13_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(12,1,'8_1:7_1','Manage Tool Filter Menus',NULL,'None','filter_menus','None',NULL,'Allows admins to create and manage the search filter menus/options for Search Tools.','Search - Screen','No','fa-search','Filter Menus','Inline / Data Row',NULL,NULL,4,'No',NULL,'15_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(13,1,'8_1:7_1','Manage Record Color Rules',NULL,'None','record_color_rules','None',NULL,'Allows admins to create and and mange the rules which set the {record_color} entry in the {metainfo} hash for records found via Search Tools.','Search - Screen','No','fa-paint-brush','Record Coloring','Inline / Data Row',NULL,NULL,5,'No',NULL,'14_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(14,1,'8_1:6_1','Active Sessions Count','0','active_sessions','active_session_count',NULL,'','','Action - Message Display','No','fa-tachometer','Active Sessions Cnt','Inline / Data Row','','',2,'No','10','5_1','0','No','No',10,'No',NULL,'No','0','Yes',NULL),(15,1,'8_1:6_1','Flush User Sessions',NULL,'flush_sessions','flush_sessions','None',NULL,NULL,'Action - Message Display','No','fa-recycle','Flush Sessions','Inline / Data Row',NULL,NULL,4,'No','10','5_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(16,1,'8_1:7_1','Create a Tool',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen','No','fa-plus','Create a Tool','Quick Actions',NULL,NULL,6,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(17,1,'8_1:7_1','Update a Tool',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen','No','fa-pencil','Update Tool','Inline / Data Row',NULL,NULL,1,'Yes','10','8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(19,1,'8_1:11_1','Create a Tool View Mode Config','','standard_data_actions','create','None',NULL,NULL,'Action - Screen','No','fa-plus','Create a View Mode','Quick Actions',NULL,NULL,1,'No',NULL,'13_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(20,1,'8_1:11_1','Update a Tool View Mode Config','','standard_data_actions','update','None',NULL,NULL,'Action - Screen','No','fa-pencil','Update View Mode','Inline / Data Row',NULL,NULL,1,'Yes','10','13_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(21,1,'8_1:13_1','Create Record Color Rule',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen',NULL,'fa-plus','Create Rule','Quick Actions',NULL,NULL,1,NULL,NULL,'14_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(22,1,'8_1:13_1','Update Row Color Rule',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen',NULL,'fa-pencil','Update Rule','Inline / Data Row',NULL,NULL,1,'Yes','10','14_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(23,1,'8_1:6_1','Create Application Instance',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen',NULL,'fa-plus','Create Instance','Quick Actions',NULL,NULL,1,NULL,NULL,'5_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(24,1,'8_1:6_1','Update Application Instance',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen',NULL,'fa-pencil','Update Instance','Inline / Data Row',NULL,NULL,5,'Yes','10','5_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(25,1,'8_1:9_1','Create a User',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen',NULL,'fa-plus','Create User','Quick Actions',NULL,NULL,1,NULL,NULL,'9_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(26,1,'8_1:2_1','Create an Application','1_1','standard_data_actions','create','None',NULL,NULL,'Action - Screen','No','fa-plus','Create an App','Quick Actions',NULL,NULL,6,'No',NULL,'1_1',NULL,'No','No',10,'Yes','No','No',NULL,'Yes',NULL),(27,1,'8_1:2_1','Update an Application',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen','No','fa-pencil','Update App','Inline / Data Row',NULL,NULL,1,'Yes','10','1_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(28,1,'8_1:1_1','Update Database Server',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen','No','fa-pencil','Update DB Srvr','Inline / Data Row',NULL,NULL,1,'Yes','10','4_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(29,1,'8_1:8_1','Create a Datatype',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen','No','fa-plus','Create Datatype','Quick Actions',NULL,NULL,2,'No',NULL,'6_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(30,1,'8_1:8_1','Update a Datatype',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen',NULL,'fa-pencil','Update Datatype','Inline / Data Row',NULL,NULL,3,'Yes','10','6_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(31,1,'8_1:10_1','Create a Datatype Field',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen',NULL,'fa-plus','Create DT Field','Quick Actions',NULL,NULL,1,NULL,NULL,'7_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(32,1,'8_1:10_1','Update a Datatype Field','','standard_data_actions','update','None',NULL,NULL,'Action - Screen','Never','fa-pencil','Update DT Field','Inline / Data Row',NULL,NULL,2,'Yes','10','7_1',NULL,'No','No',10,'Yes','No','No',NULL,'Yes','No'),(33,1,'8_1:12_1','Create a Filter Menu',NULL,'standard_data_actions','create','None',NULL,NULL,'Action - Screen',NULL,'fa-plus','Create a Menu','Quick Actions',NULL,NULL,1,NULL,NULL,'15_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(34,1,'8_1:12_1','Update a Tool Filter Menu',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen',NULL,'fa-pencil','Update Menu','Inline / Data Row',NULL,NULL,1,'Yes','10','15_1','0',NULL,'No',10,'Yes',NULL,'No','0','Yes',NULL),(35,1,'8_1:9_1','Update a User',NULL,'standard_data_actions','update','None',NULL,NULL,'Action - Screen','No','fa-pencil','Update User','Inline / Data Row',NULL,NULL,1,'Yes','10','9_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(36,1,'8_1:7_1','Order Subordinate Tools',NULL,'order_items','order_tools','options_play',NULL,'Sets the display order of the links for this Tool\'s subordinate Tools.','Action - Screen','No','fa-unsorted','Order Tools','Inline / Data Row',NULL,NULL,1,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(37,1,'8_1:11_1','Order Tool View Modes','','order_items','order_tool_mode_configs','options_play',NULL,NULL,'Action - Screen','No','fa-unsorted','Order View Modes','Quick Actions',NULL,NULL,10,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(38,1,'8_1:13_1','Order Record-Coloring Rules',NULL,'order_items','order_record_coloring_rules','options_play',NULL,NULL,'Action - Screen','No','fa-unsorted','Order Rules','Quick Actions',NULL,NULL,12,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(39,1,'8_1:2_1','Order Tools',NULL,'order_items','order_tools','options_play',NULL,'Control the display order of Tool links under the parent Tool.','Action - Screen','No','fa-unsorted','Order Tools','Inline / Data Row',NULL,NULL,5,'No',NULL,'1_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(40,1,'8_1:12_1','Order Filter Menus','','order_items','order_tool_filter_menus','options_play',NULL,NULL,'Action - Screen','No','fa-unsorted','Order Menus','Quick Actions',NULL,NULL,1,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(41,1,'8_1:8_1','Order Datatype Fields',NULL,'order_items','order_datatype_fields',NULL,NULL,'Controls the order of the fields\' display in the create/update form for this Datatype.','Action - Screen','No','fa-unsorted','Order Fields','Inline / Data Row',NULL,NULL,5,'Yes',NULL,'6_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(42,1,'8_1:7_1','Flush Parent App\'s Sessions',NULL,'flush_sessions','flush_sessions','None',NULL,'Flushes the cached user sessions for all the Instances of the parent Application for this Tool.  Required for Tools configuration changes to take effect.','Action - Message Display','No','fa-recycle','Flush Sessions','Inline / Data Row',NULL,NULL,1,'No',NULL,'8_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(43,1,'8_1:8_1','Flush Parent App\'s Datatype Hash',NULL,'flush_datatype_hashes','flush_dthash','None',NULL,'Clears the Datatype Information hash which is cached on each Instance of this Application; required for put Datatype changes into effect. ','Action - Message Display','No','fa-recycle','Flush DT Hash','Quick Actions',NULL,NULL,7,'No',NULL,'6_1',NULL,'No','No',10,'No',NULL,'No','0','Yes',NULL),(44,1,'8_1:2_1','Create a Tool',NULL,'standard_data_actions','tool_create','None',NULL,NULL,'Action - Screen','No','fa-file','Create Tool','Inline / Data Row',NULL,NULL,1,'No',NULL,'8_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(45,1,'8_1:8_1','View Datatype','','view_dt','view_datatype','None',NULL,NULL,'Action - Screen','No','fa-binoculars','View DT','Inline / Data Row',NULL,NULL,1,'No',NULL,'6_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(53,1,'8_1:7_1','Move Tool',NULL,'move_tool','move_tool','None',NULL,'Moves this Tool to be under another parent Tool.','Action - Screen','No','fa-truck','Move Tool','Inline / Data Row',NULL,NULL,5,'Yes','5','8_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(56,1,'8_1:6_1','Setup MySQL Tables',NULL,'make_tables','make_tables','None','63_1',NULL,'Action - Screen','No','fa-database','MySQL Tables','Inline / Data Row',NULL,NULL,6,'Yes','20','5_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(57,1,'8_1:13_1','Delete Record Color Rule','','standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete Rule','Inline / Data Row',NULL,NULL,3,'No',NULL,'14_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(58,1,'8_1:10_1','Delete Datatype Field',NULL,'standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete Field','Inline / Data Row',NULL,NULL,4,'No',NULL,'7_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(60,1,'8_1:8_1','Delete a Datatype',NULL,'standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete Datatype','Inline / Data Row',NULL,NULL,8,'Yes',NULL,'6_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(61,1,'8_1:8_1','Generate OmniClass Package','','generate_subclasses','subclass','None',NULL,'Generates starter/example code for a OmniClass.pm sub-class for use with this Datatype.','Action - Modal','No','fa-code','Get Package','Inline / Data Row',NULL,NULL,6,'No',NULL,'6_1',NULL,'No','No',15,'No','No','No',NULL,'Yes',NULL),(62,1,'8_1:7_1','Generate Sub-Class',NULL,'generate_subclasses','subclass','None',NULL,'Generates starter/example code for a Tool.pm sub-class for use with this Tool.','Action - Modal','No','fa-code','Get Sub-Class','Inline / Data Row',NULL,NULL,4,'No',NULL,'8_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(63,1,'1_1:1_1','Manage Access Roles','1_1','None','roles','None',NULL,'Allows the OT admin to set up access roles (groups) which are used to control access to Tools.','Search - Screen','No','fa-lock','Access Roles','Menubar',NULL,NULL,3,'No',NULL,'12_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(64,1,'8_1:63_1','Create Access Role',NULL,'standard_data_actions','create','None',NULL,'Allows the admin to create an Access Role','Action - Screen','No','fa-plus','Create Role','Quick Actions',NULL,NULL,1,'No',NULL,'12_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(65,1,'8_1:63_1','Update a Role','','standard_data_actions','update','None',NULL,'Allows the OmniTool Admin to update an Access Role.','Action - Screen','No','fa-pencil','Update Role','Inline / Data Row',NULL,NULL,1,'Yes','10','12_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(66,1,'8_1:9_1','Flush One User\'s Sessions','','flush_user_sessions','flush_user_sessions','None','73_1',NULL,'Action - Modal','No','fa-recycle','Flush User Sessions','Quick Actions',NULL,NULL,2,'No',NULL,'5_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(67,1,'8_1:9_1','View a User\'s Access Profile','','view_users_access','view_user_access','None',NULL,NULL,'Action - Screen','No','fa-binoculars','View User\'s Access','Quick Actions',NULL,NULL,4,'No',NULL,'9_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(68,1,'8_1:9_1','Delete User','','standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete','Inline / Data Row',NULL,NULL,3,'No',NULL,'9_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(69,1,'8_1:10_1','Create-From DT Field','1_1','standard_data_actions','create_from','None',NULL,NULL,'Action - Screen','No','fa-plus','Create-From','Inline / Data Row',NULL,NULL,3,'No',NULL,'7_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(70,1,'8_1:11_1','Delete a Tool View Mode Config','','standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete View Mode','Inline / Data Row',NULL,NULL,3,'No',NULL,'13_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(71,1,'8_1:63_1','Create Access Role From Another','','standard_data_actions','create_from','None',NULL,NULL,'Action - Screen','No','fa-plus','Create-From','Inline / Data Row',NULL,NULL,2,'No',NULL,'12_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(72,1,'1_1:1_1','View Perl Module Documentation','1_1','view_module_documentation','view_module_docs','None',NULL,NULL,'Action - Screen','No','fa-book','View Perl Docs','Menubar',NULL,NULL,6,'No',NULL,'1_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(73,1,'8_1:7_1','Delete Tool','1_1','standard_delete','delete','None',NULL,'Allows Admins to delete Tools','Action - Modal','No','fa-eraser','Delete Tool','Inline / Data Row',NULL,NULL,10,'No',NULL,'8_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(74,1,'8_1:6_1','View Background Tasks','1_1','background_tasks','background_tasks','None',NULL,'Allows OT Admins to see the last 20-200 background tasks for each Datatype which supports such tasks.  Can set Error tasks to Retry.','Action - Screen','No','fa-object-group','Background Tasks','Inline / Data Row',NULL,NULL,7,'No',NULL,'5_1','60','No','No',15,'Yes',NULL,'No','0','Yes',NULL),(75,1,'8_1:11_1','Create a Tool View Mode From Another','1_1','standard_data_actions','create_from','None',NULL,'Allows an OmniTool Admin to create a Tool Mode based on a pre-existing Tool Mode Config.','Action - Screen','No','fa-copy','Create-From','Inline / Data Row',NULL,NULL,2,'No',NULL,'13_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(76,1,'8_1:7_1','Create a Tool From Another','1_1','standard_data_actions','create_from','None',NULL,'Makes it easy to create a new Tool from a pre-existing Tool.','Action - Screen','No','fa-copy','Create-From','Inline / Data Row',NULL,NULL,2,'No',NULL,'8_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(77,1,'8_1:72_1','Find Class by Subroutine','1_1','find_class_by_sub','find_class_by_sub','None',NULL,'Allows developers to find modules which contain subroutines.\n<br/>Depends on provided code map.  To update that to include your modules, you will need to run:  \n<code>\n<br/>/usr/local/bin/umlclass.pl -o /opt/omnitool/configs/ot6_modules.yml -r /opt/omnitool/code/omnitool/\n</code>\n<br/><br/>\nFor that to work, you will need to do this first:\n<code>\n<br/>apt-get install libxml2-dev graphviz\n<br/>cpanm --force UML::Class::Simple\n<br/>rm /opt/omnitool/configs/ot6_modules.yml\n</code>','Action - Screen','No','fa-search','Find Class By Sub','Menubar',NULL,NULL,1,'No',NULL,'1_1',NULL,'No','No',15,'Yes','Yes','No',NULL,'Yes',NULL),(78,1,'8_1:12_1','Create a Filter Menu From Another','','standard_data_actions','create_from','None',NULL,NULL,'Action - Screen','No','fa-plus','Create-From','Inline / Data Row',NULL,NULL,1,'No',NULL,'15_1',NULL,'No','No',10,'Yes',NULL,'No','0','Yes',NULL),(79,1,'1_1:1_1','Manage User API Keys','Open','manage_api_keys','user_api_keys','None',NULL,'API keys allow your scripts to authenticate on your behalf from specific servers.  Once you create a key, please use the \'View Details\' option next to it to obtain a copy of the key string.','Search - Screen','No','fa-key','Manage API Keys','Menubar',NULL,NULL,5,'No',NULL,'18_1',NULL,'No','No',15,'No','Yes','No','0','Yes',NULL),(80,1,'8_1:79_1','Create API Key (Admin)','1_1','standard_data_actions','create','None',NULL,'Allows OmniTool Admins to create keys for users.','Action - Screen','No','fa-plus','Admin Create API Key','Quick Actions',NULL,NULL,1,'No',NULL,'18_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(81,1,'8_1:79_1','Update API Key (Admin)','1_1','standard_data_actions','update','None',NULL,'Allows OmniTool Admins to update keys for users.','Action - Screen','No','fa-edit','Admin Update API Key','Inline / Data Row',NULL,NULL,2,'Yes',NULL,'18_1',NULL,'No','No',15,'Yes',NULL,'No','0','Yes',NULL),(82,1,'8_1:79_1','Delete API Key','Open','standard_delete','delete','None',NULL,'Allows OmniTool Admins to remove API Keys altogether.','Action - Modal','No','fa-eraser','Delete API Key','Inline / Data Row',NULL,NULL,6,'No',NULL,'18_1',NULL,'No','No',NULL,'No','No','No','0','Yes',NULL),(83,1,'8_1:79_1','Renew API Key','Open','renew_api_key','renew_api_key','None',NULL,'Sets the expiration date of a API key to 90 days from today.','Action - Message Display','No','fa-calendar','Renew Key','Inline / Data Row',NULL,NULL,4,'No',NULL,'18_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(84,1,'8_1:79_1','Create API Key (User)','Open','create_api_key','create_key','None',NULL,'Allows OmniTool users to create their API keys.','Action - Modal','No','fa-plus','Create API Key','Quick Actions',NULL,NULL,5,'No',NULL,'18_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(85,1,'8_1:79_1','Update API Key (User)','Open','update_api_key','update_key','None',NULL,'Allows OmniTool users to update their API keys.','Action - Modal','No','fa-pencil','Update API Key','Inline / Data Row',NULL,NULL,7,'No',NULL,'18_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(86,1,'8_1:79_1','View API Key Details','Open','basic_data_view','view_key','None',NULL,'Shows users the details of their API keys.','Action - Modal','No','fa-binoculars','View Details','Inline / Data Row',NULL,NULL,3,'No',NULL,'18_1',NULL,'No','No',15,'No',NULL,'No','0','Yes',NULL),(87,1,'8_1:12_1','Delete Filter Menu','1_1','standard_delete','delete','None',NULL,NULL,'Action - Modal','No','fa-eraser','Delete','Inline / Data Row',NULL,NULL,3,'No',NULL,'15_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(88,1,'8_1:6_1','Start Daily Background Tasks','1_1','start_background_tasks','start_daily_bg_tasks','None',NULL,'Kicks off the daily background tasks for a specific application instance.','Action - Message Display','No','fa-play','Start Daily BG Task','Inline / Data Row',NULL,NULL,10,'No',NULL,'5_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(90,1,'8_1:2_1','Generate Helper Modules','1_1','generate_application_helpers','generate_helpers','None',NULL,'Allows system admins to generate Application-level helper modules from templates.','Action - Screen','No','fa-stumbleupon','Generate Helpers','Inline / Data Row',NULL,NULL,5,'No',NULL,'1_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(91,1,'8_1:6_1','Deploy Admin DB to Production','1_1','deploy_admin_database','deploy_admin_database','None',NULL,'Allows OT Admins to copy an OmniTool Admin database into production safely, which includes ignoring the background tasks, API Keys, and tools_options tables.','Action - Modal','No','fa-rocket','Deploy to Prod','Inline / Data Row','dev.*: omnitool','129_1',11,'Yes',NULL,'5_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(92,1,'8_1:6_1','Generate Worker Crontab','1_1','generate_crontab','generate_worker_crontab','None',NULL,'Generates an example crontab for workers performing background tasks for this Instance.','Action - Modal','No','fa-simplybuilt','Generate Crontab','Inline / Data Row',NULL,NULL,9,'No',NULL,'5_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(93,1,'8_1:7_1','One-Click CRUD Tools Creator','1_1','oneclick_crud','one_click_crud','None',NULL,NULL,'Action - Screen','No','fa-tachometer','One-Click CRUD','Quick Actions',NULL,NULL,11,'No',NULL,'8_1',NULL,'No','No',20,'No','No','No',NULL,'Yes',NULL),(94,1,'8_1:6_1','Background Task Health Check','','health_check','health_check','None',NULL,'Displays the number of background tasks and emails waiting to be processed by this instance.  Completed/Error numbers are for items processed within the past hour.','Action - Screen','No','fa-stethoscope','Health Check','Inline / Data Row',NULL,NULL,8,'No',NULL,'5_1',NULL,'No','No',20,'No','Yes','No',NULL,'Yes',NULL);
/*!40000 ALTER TABLE `tools` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tools_display_options_cached`
--

DROP TABLE IF EXISTS `tools_display_options_cached`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tools_display_options_cached` (
  `object_name` varchar(250) CHARACTER SET latin1 NOT NULL,
  `expiration_time` int(15) unsigned NOT NULL DEFAULT '0',
  `cached_hash` longblob,
  `username` varchar(35) CHARACTER SET latin1 DEFAULT NULL,
  `tool_id` varchar(35) NOT NULL,
  PRIMARY KEY (`object_name`),
  KEY `expiration_time` (`expiration_time`),
  KEY `username` (`username`,`tool_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tools_display_options_cached`
--

LOCK TABLES `tools_display_options_cached` WRITE;
/*!40000 ALTER TABLE `tools_display_options_cached` DISABLE KEYS */;
INSERT INTO `tools_display_options_cached` VALUES ('omnitool_admin1523067521134147424022C95AA5DF_10_1',1523672963,'\n\0\0\0\n1_1_32_1\0\0\0return_tool_id\n9_1\0\0\0	tool_mode\0\0\0advanced_search_filters\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\ninstance\0\0\0altcode\0\0\0\nFeb16eric_datatypefields125\ndtf37\nMar16eric_datatypefields133\nFeb16eric_datatypefields129\ndtf32\ndtf38\nFeb16eric_datatypefields127\nFeb16eric_datatypefields126\ndtf31\nDec15eric_datatypefields115\ndtf33\nMar16echernof_datatypefields140\nJul17echernof_datatypefields166\ndtf36\ndtf34\nApr16echernof_datatypefields141\nMar16eric_datatypefields135\0\0\0\raltcodes_keys\n	Ascending\0\0\0sort_direction\nsysadmin\0\0\0uri_base\0\0\0\rquick_keyword\n\r1523067521204\0\0\0_\nName\0\0\0sort_column','omnitool_admin','10_1'),('omnitool_admin1523067521134147424022C95AA5DF_24_1',1523673696,'\n\0\0\0\n33_1\0\0\0	tool_mode\nNov17omnitool_admin_instances12\0\0\0altcode\n1_1_6_1\0\0\0return_tool_id\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\n\r1523067521202\0\0\0_','omnitool_admin','24_1'),('omnitool_admin1523067521134147424022C95AA5DF_2_1',1523673580,'\n\0\0\0\n\0\0\0\napp01\0\0\0\raltcodes_keys\n	Ascending\0\0\0sort_direction\nsysadmin\0\0\0uri_base\n\r1523067521199\0\0\0_\n1_1_8_1\0\0\0return_tool_id\0\0\0\rquick_keyword\n1_1\0\0\0	tool_mode\0\0\0advanced_search_filters\0\0\0sort_column\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id','omnitool_admin','2_1'),('omnitool_admin1523067521134147424022C95AA5DF_32_1',1523672963,'\n\0\0\0\n20_1\0\0\0	tool_mode\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\nFeb16eric_datatypefields127\0\0\0altcode','omnitool_admin','32_1'),('omnitool_admin1523067521134147424022C95AA5DF_43_1',1523672966,'\n\0\0\0\n1_1_8_1\0\0\0return_tool_id\0\0\0	tool_mode\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\napp01\0\0\0altcode','omnitool_admin','43_1'),('omnitool_admin1523067521134147424022C95AA5DF_6_1',1523673586,'\n\0\0\0\0\0\0sort_column\0\0\0\rquick_keyword\nsysadmin\0\0\0uri_base\n38_1\0\0\0	tool_mode\0\0\0\nNov17omnitool_admin_instances12\nAug17omnitool_admin_instances11\nJul17eric_instances10\nJul17eric_instances9\nSep16echernof_instances8\n\napp_inst01\0\0\0\raltcodes_keys\napp01\0\0\0altcode\n	Ascending\0\0\0sort_direction\0\0\0advanced_search_filters\n\r1523067521200\0\0\0_\n1_1_2_1\0\0\0return_tool_id\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id','omnitool_admin','6_1'),('omnitool_admin1523067521134147424022C95AA5DF_74_1',1523672333,'\n\0\0\0\nsysadmin\0\0\0uri_base\n\r1523067521201\0\0\0_\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\nJul17eric_instances9\0\0\0altcode\n1_1_6_1\0\0\0return_tool_id\n85_1\0\0\0	tool_mode','omnitool_admin','74_1'),('omnitool_admin1523067521134147424022C95AA5DF_8_1',1523672967,'\n\0\0\0\n,omnitool_admin1523067521134147424022C95AA5DF\0\0\0client_connection_id\0\0\0advanced_search_filters\n7_1\0\0\0	tool_mode\n1_1_8_1\0\0\0return_tool_id\0\0\0\r\n\raccess_groups\napplication\ninstance\n	db_server\ndatatype\ndatatype_field\not_user\nJul16echernof_datatypes18\n	organizer\nJun15eric_datatypes14\nscreen\nJun15eric_datatypes15\nJun15eric_datatypes13\0\0\0\raltcodes_keys\napp01\0\0\0altcode\0\0\0\rquick_keyword\nsysadmin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\n28_1\0\0\0sort_column\n\r1523067521203\0\0\0_','omnitool_admin','8_1'),('omnitool_admin1523068902564427685A90ED44CA46_24_1',1523673703,'\n\0\0\0\nnone\0\0\0return_tool_id\nNov17omnitool_admin_instances12\0\0\0altcode\n\r1523068902163\0\0\0_\nsysadmin\0\0\0uri_base\n,omnitool_admin1523068902564427685A90ED44CA46\0\0\0client_connection_id\n33_1\0\0\0	tool_mode','omnitool_admin','24_1'),('omnitool_admin152306891132CDBA377D9749D9CEB6_24_1',1523673712,'\n\0\0\0\nNov17omnitool_admin_instances12\0\0\0altcode\n\r1523068911115\0\0\0_\n33_1\0\0\0	tool_mode\n,omnitool_admin152306891132CDBA377D9749D9CEB6\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\nnone\0\0\0return_tool_id','omnitool_admin','24_1'),('omnitool_admin152306893086D81F00895967893655_24_1',1523673839,'\n\0\0\0\n,omnitool_admin152306893086D81F00895967893655\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\n33_1\0\0\0	tool_mode\nnone\0\0\0return_tool_id\nNov17omnitool_admin_instances12\0\0\0altcode\n\r1523068930049\0\0\0_','omnitool_admin','24_1'),('omnitool_admin152306893086D81F00895967893655_2_1',1523673957,'\n\0\0\0\n\nsysadmin\0\0\0uri_base\n,omnitool_admin152306893086D81F00895967893655\0\0\0client_connection_id\n1_1_6_1\0\0\0return_tool_id\0\0\0\rquick_keyword\n1_1\0\0\0	tool_mode\0\0\0\napp01\0\0\0\raltcodes_keys\0\0\0sort_column\n\r1523068930051\0\0\0_\0\0\0advanced_search_filters\n	Ascending\0\0\0sort_direction','omnitool_admin','2_1'),('omnitool_admin152306893086D81F00895967893655_6_1',1523673839,'\n\0\0\0\0\0\0\rquick_keyword\n1_1_24_1\0\0\0return_tool_id\n,omnitool_admin152306893086D81F00895967893655\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0advanced_search_filters\napp01\0\0\0altcode\n\r1523068930050\0\0\0_\0\0\0sort_column\n38_1\0\0\0	tool_mode\0\0\0\nNov17omnitool_admin_instances12\nAug17omnitool_admin_instances11\nJul17eric_instances10\nJul17eric_instances9\nSep16echernof_instances8\n\napp_inst01\0\0\0\raltcodes_keys','omnitool_admin','6_1'),('omnitool_admin15235905261BE192DD9553B264969E_10_1',1524195407,'\n\0\0\0\nJun15eric_datatypes13\0\0\0altcode\n\r1523590526059\0\0\0_\nsysadmin\0\0\0uri_base\0\0\0\rquick_keyword\n	Ascending\0\0\0sort_direction\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\nName\0\0\0sort_column\0\0\0\r\n\ZJun15eric_datatypefields65\n\ZNov15eric_datatypefields91\n\ZJun15eric_datatypefields59\n\ZJun15eric_datatypefields64\n\ZJun15eric_datatypefields63\n\ZJun15eric_datatypefields61\n%Jul17omnitool_admin_datatypefields167\n\ZJun15eric_datatypefields62\nFeb16eric_datatypefields132\n\ZJun15eric_datatypefields58\nNov15eric_datatypefields103\nFeb17echernof_datatypefields163\n%Apr18omnitool_admin_datatypefields175\0\0\0\raltcodes_keys\n9_1\0\0\0	tool_mode\0\0\0advanced_search_filters\n1_1_32_1\0\0\0return_tool_id','omnitool_admin','10_1'),('omnitool_admin15235905261BE192DD9553B264969E_2_1',1524195421,'\n\0\0\0\n\0\0\0\rquick_keyword\n\r1523590526057\0\0\0_\n1_1\0\0\0	tool_mode\nsysadmin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0\napp01\0\0\0\raltcodes_keys\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\0\0\0advanced_search_filters\0\0\0sort_column\n1_1_8_1\0\0\0return_tool_id','omnitool_admin','2_1'),('omnitool_admin15235905261BE192DD9553B264969E_32_1',1524195406,'\n\0\0\0\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\nsysadmin\0\0\0uri_base\n20_1\0\0\0	tool_mode\n%Apr18omnitool_admin_datatypefields175\0\0\0altcode','omnitool_admin','32_1'),('omnitool_admin15235905261BE192DD9553B264969E_43_1',1524195419,'\n\0\0\0\napp01\0\0\0altcode\n1_1_8_1\0\0\0return_tool_id\0\0\0	tool_mode\nsysadmin\0\0\0uri_base\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id','omnitool_admin','43_1'),('omnitool_admin15235905261BE192DD9553B264969E_56_1',1524195494,'\n\0\0\0\n\napp_inst01\0\0\0altcode\n1_1_56_1\0\0\0return_tool_id\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\n63_1\0\0\0	tool_mode\nsysadmin\0\0\0uri_base\ntool_mode_configs\0\0\0display\n\r1523590526063\0\0\0_\n\n13_1:175_1\0\0\0add_datatype_table_column','omnitool_admin','56_1'),('omnitool_admin15235905261BE192DD9553B264969E_69_1',1524195351,'\n\0\0\0\nFeb17echernof_datatypefields163\0\0\0altcode','omnitool_admin','69_1'),('omnitool_admin15235905261BE192DD9553B264969E_6_1',1524195495,'\n\0\0\0\n1_1_56_1\0\0\0return_tool_id\napp01\0\0\0altcode\0\0\0\nNov17omnitool_admin_instances12\nAug17omnitool_admin_instances11\nJul17eric_instances10\nJul17eric_instances9\nSep16echernof_instances8\n\napp_inst01\0\0\0\raltcodes_keys\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\0\0\0advanced_search_filters\0\0\0sort_column\n38_1\0\0\0	tool_mode\nsysadmin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0\rquick_keyword\n\r1523590526062\0\0\0_','omnitool_admin','6_1'),('omnitool_admin15235905261BE192DD9553B264969E_8_1',1524195421,'\n\0\0\0\nsysadmin\0\0\0uri_base\n7_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\n\r1523590526058\0\0\0_\0\0\0\rquick_keyword\napp01\0\0\0altcode\n1_1_8_1\0\0\0return_tool_id\n,omnitool_admin15235905261BE192DD9553B264969E\0\0\0client_connection_id\0\0\0advanced_search_filters\n28_1\0\0\0sort_column\0\0\0\r\n\raccess_groups\napplication\ninstance\n	db_server\ndatatype\ndatatype_field\not_user\nJul16echernof_datatypes18\n	organizer\nJun15eric_datatypes14\nscreen\nJun15eric_datatypes15\nJun15eric_datatypes13\0\0\0\raltcodes_keys','omnitool_admin','8_1'),('omnitool_admin15245412716559A7991A214272C935_2_1',1525146072,'\n\0\0\0\n\0\0\0sort_column\n,omnitool_admin15245412716559A7991A214272C935\0\0\0client_connection_id\n	Ascending\0\0\0sort_direction\nsysadmin\0\0\0uri_base\n\r1524541271075\0\0\0_\n1_1\0\0\0	tool_mode\nnone\0\0\0return_tool_id\0\0\0\rquick_keyword\0\0\0\napp01\0\0\0\raltcodes_keys\0\0\0advanced_search_filters','omnitool_admin','2_1'),('omnitool_admin15246242357E2F630923D04B3001A5_2_1',1525229036,'\n\0\0\0\n\n\r1524624477795\0\0\0_\nnone\0\0\0return_tool_id\n,omnitool_admin15246242357E2F630923D04B3001A5\0\0\0client_connection_id\0\0\0\rquick_keyword\n1_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\0\0\0sort_column\nsysadmin\0\0\0uri_base\0\0\0\napp01\0\0\0\raltcodes_keys\0\0\0advanced_search_filters','omnitool_admin','2_1'),('omnitool_admin15246246609CFBA0428BEA7AD5A95C_17_1',1525229488,'\n\0\0\0\nsysadmin\0\0\0uri_base\n17_1\0\0\0	tool_mode\n,omnitool_admin15246246609CFBA0428BEA7AD5A95C\0\0\0client_connection_id\nDec15eric_tools32\0\0\0altcode','omnitool_admin','17_1'),('omnitool_admin15246246609CFBA0428BEA7AD5A95C_2_1',1525229461,'\n\0\0\0\n\nsysadmin\0\0\0uri_base\0\0\0\rquick_keyword\nnone\0\0\0return_tool_id\n,omnitool_admin15246246609CFBA0428BEA7AD5A95C\0\0\0client_connection_id\0\0\0\napp01\0\0\0\raltcodes_keys\0\0\0advanced_search_filters\0\0\0sort_column\n	Ascending\0\0\0sort_direction\n1_1\0\0\0	tool_mode\n\r1524624903409\0\0\0_','omnitool_admin','2_1'),('omnitool_admin15246246609CFBA0428BEA7AD5A95C_7_1',1525229488,'\n\0\0\0\n\r1524624903410\0\0\0_\n6_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\0\0\0sort_column\0\0\0\nMar16echernof_tools69\nJan16eric_tools58\nDec15eric_tools32\nDec15eric_tools31\0\0\0\raltcodes_keys\0\0\0advanced_search_filters\n,omnitool_admin15246246609CFBA0428BEA7AD5A95C\0\0\0client_connection_id\nNov15eric_tools10\0\0\0altcode\n1_1_17_1\0\0\0return_tool_id\0\0\0\rquick_keyword\nsysadmin\0\0\0uri_base','omnitool_admin','7_1');
/*!40000 ALTER TABLE `tools_display_options_cached` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tools_display_options_saved`
--

DROP TABLE IF EXISTS `tools_display_options_saved`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tools_display_options_saved` (
  `object_name` varchar(250) CHARACTER SET latin1 NOT NULL,
  `expiration_time` int(15) unsigned NOT NULL DEFAULT '0',
  `cached_hash` longblob,
  `username` varchar(35) CHARACTER SET latin1 DEFAULT NULL,
  `tool_id` varchar(35) NOT NULL,
  `saved_name` varchar(100) CHARACTER SET latin1 DEFAULT NULL,
  `default_for_tool` enum('No','Yes') DEFAULT 'No',
  `default_for_instance` enum('No','Yes') DEFAULT 'No',
  PRIMARY KEY (`object_name`),
  KEY `expiration_time` (`expiration_time`),
  KEY `username` (`username`,`tool_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tools_display_options_saved`
--

LOCK TABLES `tools_display_options_saved` WRITE;
/*!40000 ALTER TABLE `tools_display_options_saved` DISABLE KEYS */;
/*!40000 ALTER TABLE `tools_display_options_saved` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `update_history`
--

DROP TABLE IF EXISTS `update_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `update_history` (
  `code` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `data_code` varchar(30) NOT NULL,
  `datatype` varchar(30) NOT NULL,
  `updater` varchar(25) NOT NULL,
  `update_time` int(11) NOT NULL DEFAULT '0',
  `changes` longtext,
  PRIMARY KEY (`code`,`server_id`),
  KEY `data_code` (`data_code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `update_history`
--

LOCK TABLES `update_history` WRITE;
/*!40000 ALTER TABLE `update_history` DISABLE KEYS */;
INSERT INTO `update_history` VALUES (1,1,'4_1','2_1','eric',1431828737,'Name/Title was modified:\nOld Value: \nNew Value: Melanie\n------\nType was modified:\nOld Value: \nNew Value: Wife');
/*!40000 ALTER TABLE `update_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_api_keys`
--

DROP TABLE IF EXISTS `user_api_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_api_keys` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `username` varchar(20) DEFAULT NULL,
  `tied_to_ip_address` mediumtext,
  `expiration_date` varchar(10) DEFAULT NULL,
  `api_key_string` varchar(100) DEFAULT NULL,
  `status` varchar(8) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_api_keys`
--

LOCK TABLES `user_api_keys` WRITE;
/*!40000 ALTER TABLE `user_api_keys` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_api_keys` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_api_keys_metainfo`
--

DROP TABLE IF EXISTS `user_api_keys_metainfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_api_keys_metainfo` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `altcode` varchar(50) NOT NULL,
  `data_code` varchar(30) NOT NULL,
  `the_type` varchar(30) NOT NULL,
  `table_name` varchar(60) NOT NULL DEFAULT '',
  `originator` varchar(25) NOT NULL,
  `create_time` int(11) unsigned NOT NULL,
  `updater` varchar(25) NOT NULL,
  `update_time` int(11) unsigned NOT NULL,
  `lock_user` varchar(30) NOT NULL DEFAULT 'None',
  `lock_expire` int(11) DEFAULT NULL,
  `parent` varchar(30) NOT NULL,
  `children` text,
  `is_draft` enum('No','Yes') NOT NULL DEFAULT 'No',
  `thumbnail_file` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`),
  KEY `altcode` (`altcode`),
  KEY `data_code` (`data_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_api_keys_metainfo`
--

LOCK TABLES `user_api_keys_metainfo` WRITE;
/*!40000 ALTER TABLE `user_api_keys_metainfo` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_api_keys_metainfo` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-07-21 17:14:44
