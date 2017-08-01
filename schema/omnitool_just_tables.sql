-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: localhost    Database: omnitool
-- ------------------------------------------------------
-- Server version	5.7.19-0ubuntu0.16.04.1-log

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
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
) ENGINE=InnoDB AUTO_INCREMENT=170 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
) ENGINE=InnoDB AUTO_INCREMENT=438 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=104 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-08-01 11:44:06
