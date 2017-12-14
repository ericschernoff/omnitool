-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: localhost    Database: omnitool_applications
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
  `status` varchar(8) DEFAULT NULL,
  `used_in_applications` text,
  `match_hash_key` varchar(100) DEFAULT NULL,
  `match_operator` varchar(100) DEFAULT NULL,
  `match_value` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `access_roles`
--

LOCK TABLES `access_roles` WRITE;
/*!40000 ALTER TABLE `access_roles` DISABLE KEYS */;
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
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `status` varchar(8) DEFAULT NULL,
  `app_code_directory` varchar(60) DEFAULT NULL,
  `ui_template` varchar(40) DEFAULT 'default.tt',
  `contact_email` varchar(100) DEFAULT NULL,
  `description` mediumtext,
  `share_my_datatypes` varchar(100) DEFAULT NULL,
  `lock_lifetime` varchar(12) DEFAULT NULL,
  `appwide_search_function` varchar(100) DEFAULT NULL,
  `appwide_search_name` varchar(100) DEFAULT NULL,
  `appwide_quickstart_tool_uri` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `applications`
--

LOCK TABLES `applications` WRITE;
/*!40000 ALTER TABLE `applications` DISABLE KEYS */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `background_tasks`
--

LOCK TABLES `background_tasks` WRITE;
/*!40000 ALTER TABLE `background_tasks` DISABLE KEYS */;
/*!40000 ALTER TABLE `background_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `database_servers`
--

DROP TABLE IF EXISTS `database_servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `database_servers` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `status` varchar(8) DEFAULT NULL,
  `hostname` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `database_servers`
--

LOCK TABLES `database_servers` WRITE;
/*!40000 ALTER TABLE `database_servers` DISABLE KEYS */;
INSERT INTO `database_servers` VALUES (1,1,'top','Development Server','Active','127.0.0.1');
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
  `field_type` varchar(40) DEFAULT NULL,
  `virtual_field` varchar(3) DEFAULT NULL,
  `table_column` varchar(40) DEFAULT NULL,
  `priority` int(3) DEFAULT NULL,
  `is_required` varchar(3) DEFAULT NULL,
  `force_alphanumeric` varchar(3) DEFAULT NULL,
  `max_length` int(10) DEFAULT NULL,
  `instructions` mediumtext,
  `default_value` varchar(200) DEFAULT NULL,
  `option_values` mediumtext,
  `search_tool_heading` varchar(60) DEFAULT NULL,
  `sort_column` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatype_fields`
--

LOCK TABLES `datatype_fields` WRITE;
/*!40000 ALTER TABLE `datatype_fields` DISABLE KEYS */;
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
  `table_name` varchar(60) DEFAULT NULL,
  `containable_datatypes` text,
  `perl_module` varchar(100) DEFAULT NULL,
  `description` mediumtext,
  `metainfo_table` varchar(20) DEFAULT NULL,
  `skip_children_column` varchar(3) DEFAULT NULL,
  `altcodes_are_unique` varchar(3) DEFAULT NULL,
  `support_email_and_tasks` varchar(3) DEFAULT NULL,
  `incoming_email_account` varchar(30) DEFAULT NULL,
  `show_name` varchar(3) DEFAULT NULL,
  `lock_lifetime` varchar(2) DEFAULT NULL,
  `extended_change_history` varchar(3) DEFAULT NULL,
  `archive_deletes` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatypes`
--

LOCK TABLES `datatypes` WRITE;
/*!40000 ALTER TABLE `datatypes` DISABLE KEYS */;
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
-- Table structure for table `instances`
--

DROP TABLE IF EXISTS `instances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instances` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `server_id` int(11) unsigned NOT NULL DEFAULT '1',
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `status` varchar(8) DEFAULT NULL,
  `hostname` varchar(250) DEFAULT NULL,
  `uri_base_value` varchar(100) DEFAULT NULL,
  `contact_email` varchar(100) DEFAULT NULL,
  `description` mediumtext,
  `database_server_id` varchar(30) DEFAULT NULL,
  `database_name` varchar(50) DEFAULT NULL,
  `ui_logo` varchar(60) DEFAULT 'ginger_face.png',
  `access_roles` text,
  `public_mode` varchar(3) DEFAULT NULL,
  `switch_into_access_roles` text,
  `pause_background_tasks` varchar(3) DEFAULT NULL,
  `email_sending_info` text,
  `file_storage_method` varchar(100) DEFAULT NULL,
  `file_location` text,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instances`
--

LOCK TABLES `instances` WRITE;
/*!40000 ALTER TABLE `instances` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metainfo`
--

LOCK TABLES `metainfo` WRITE;
/*!40000 ALTER TABLE `metainfo` DISABLE KEYS */;
INSERT INTO `metainfo` VALUES (1,1,'Jul17omnitool_admin_databaseservers1','1_1','4_1','database_servers','omnitool_admin',1500266247,'omnitool_admin',1500266247,'None',0,'top',NULL,'No',0),(2,1,'Jul17omnitool_admin_omnitoolusers1','1_1','9_1','omnitool_users','omnitool_admin',1500431615,'omnitool_admin',1500431615,'None',NULL,'top',NULL,'No',0);
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
  `username` varchar(25) DEFAULT NULL,
  `password` varchar(250) DEFAULT NULL,
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
INSERT INTO `omnitool_users` VALUES (1,1,'top','OmniTool Admin','omnitool_admin','6e3e7cc8708d07b6019193d486415e85d7c288390ddc327d9af174b2',NULL,'No',curdate());
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
  `parent` varchar(30) NOT NULL,
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizers`
--

LOCK TABLES `organizers` WRITE;
/*!40000 ALTER TABLE `organizers` DISABLE KEYS */;
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
  `match_type` varchar(30) DEFAULT NULL,
  `match_string` varchar(150) DEFAULT NULL,
  `apply_color` varchar(40) DEFAULT NULL,
  `priority` int(3) DEFAULT NULL,
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
  `display_area` varchar(30) DEFAULT NULL,
  `applies_to_table_column` varchar(200) DEFAULT NULL,
  `search_operator` varchar(10) DEFAULT NULL,
  `matches_relate_to_tool_dt` varchar(200) DEFAULT NULL,
  `menu_type` varchar(20) DEFAULT NULL,
  `support_any_all_option` varchar(3) DEFAULT NULL,
  `priority` int(3) DEFAULT NULL,
  `menu_options_type` varchar(150) DEFAULT NULL,
  `menu_options_method` varchar(30) DEFAULT NULL,
  `menu_options` mediumtext,
  `sql_cmd` mediumtext,
  `sql_bind_values` mediumtext,
  `default_option_value` varchar(60) DEFAULT NULL,
  `instructions` mediumtext,
  `trigger_menu` text,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_filter_menus`
--

LOCK TABLES `tool_filter_menus` WRITE;
/*!40000 ALTER TABLE `tool_filter_menus` DISABLE KEYS */;
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
  `custom_type_name` varchar(35) DEFAULT NULL,
  `custom_template` varchar(200) DEFAULT NULL,
  `priority` int(3) DEFAULT NULL,
  `fields_to_include` text,
  `access_roles` text,
  `max_results` varchar(100) DEFAULT NULL,
  `default_sort_direction` varchar(12) DEFAULT NULL,
  `default_sort_column` varchar(3) DEFAULT NULL,
  `execute_function_on_load` varchar(100) DEFAULT NULL,
  `single_record_jemplate_block` varchar(100) DEFAULT NULL,
  `display_a_chart` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_mode_configs`
--

LOCK TABLES `tool_mode_configs` WRITE;
/*!40000 ALTER TABLE `tool_mode_configs` DISABLE KEYS */;
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
  `name` varchar(100) NOT NULL DEFAULT 'not named',
  `uri_path_base` varchar(200) DEFAULT NULL,
  `perl_module` varchar(200) DEFAULT NULL,
  `javascript_class` varchar(100) DEFAULT NULL,
  `button_name` varchar(20) DEFAULT NULL,
  `icon_fa_glyph` varchar(30) DEFAULT NULL,
  `priority` int(3) DEFAULT NULL,
  `link_type` varchar(30) DEFAULT NULL,
  `target_datatype` varchar(30) DEFAULT NULL,
  `tool_type` varchar(30) DEFAULT NULL,
  `menus_required_for_search` varchar(3) DEFAULT NULL,
  `require_quick_search_keyword` varchar(3) DEFAULT NULL,
  `share_parent_inline_action_tools` varchar(3) DEFAULT NULL,
  `default_mode` varchar(200) DEFAULT NULL,
  `description` mediumtext,
  `display_tool_controls` varchar(3) DEFAULT NULL,
  `display_description` varchar(3) DEFAULT NULL,
  `access_roles` text,
  `link_match_field` varchar(100) DEFAULT NULL,
  `link_match_string` varchar(30) DEFAULT NULL,
  `message_time` varchar(100) DEFAULT NULL,
  `message_is_sticky` varchar(3) DEFAULT NULL,
  `is_locking` varchar(3) DEFAULT NULL,
  `lock_lifetime` varchar(2) DEFAULT NULL,
  `query_interval` varchar(30) DEFAULT NULL,
  `load_trees` varchar(3) DEFAULT NULL,
  `keep_warm` varchar(8) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tools`
--

LOCK TABLES `tools` WRITE;
/*!40000 ALTER TABLE `tools` DISABLE KEYS */;
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
INSERT INTO `tools_display_options_cached` VALUES ('omnitool_admin150026623891595C41F2D52B361F6B_1_1',1500871048,'\n\0\0\0	\nname\0\0\0sort_column\n\0\0\0\0sort_direction\0\0\0\rquick_keyword\n\napps_admin\0\0\0uri_base\0\0\0\n$Jul17omnitool_admin_databaseservers1\0\0\0\raltcodes_keys\n\r1500266237718\0\0\0_\n10_1_3_1\0\0\0return_tool_id\n,omnitool_admin150026623891595C41F2D52B361F6B\0\0\0client_connection_id\n4_1\0\0\0	tool_mode','omnitool_admin','1_1'),('omnitool_admin150026623891595C41F2D52B361F6B_28_1',1500871069,'\n\0\0\0\n\napps_admin\0\0\0uri_base\n10_1_1_1\0\0\0return_tool_id\n\r1500266237720\0\0\0_\n$Jul17omnitool_admin_databaseservers1\0\0\0altcode\n27_1\0\0\0	tool_mode\n,omnitool_admin150026623891595C41F2D52B361F6B\0\0\0client_connection_id','omnitool_admin','28_1'),('omnitool_admin150026623891595C41F2D52B361F6B_2_1',1500871039,'\n\0\0\0	\n1_1\0\0\0	tool_mode\n,omnitool_admin150026623891595C41F2D52B361F6B\0\0\0client_connection_id\n\r1500266237717\0\0\0_\nnone\0\0\0return_tool_id\0\0\0\0\0\0\0\raltcodes_keys\n\napps_admin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0\rquick_keyword\0\0\0sort_column','omnitool_admin','2_1'),('omnitool_admin150026642969B1B18EFD8C830C4C35_1_1',1500871236,'\n\0\0\0	\n\0\0\0\0sort_direction\0\0\0\rquick_keyword\nname\0\0\0sort_column\n4_1\0\0\0	tool_mode\n,omnitool_admin150026642969B1B18EFD8C830C4C35\0\0\0client_connection_id\n\r1500266428815\0\0\0_\n	10_1_28_1\0\0\0return_tool_id\0\0\0\n$Jul17omnitool_admin_databaseservers1\0\0\0\raltcodes_keys\n\napps_admin\0\0\0uri_base','omnitool_admin','1_1'),('omnitool_admin150026642969B1B18EFD8C830C4C35_28_1',1500871236,'\n\0\0\0\n\napps_admin\0\0\0uri_base\nnone\0\0\0return_tool_id\n\r1500266428814\0\0\0_\n27_1\0\0\0	tool_mode\n,omnitool_admin150026642969B1B18EFD8C830C4C35\0\0\0client_connection_id\n$Jul17omnitool_admin_databaseservers1\0\0\0altcode','omnitool_admin','28_1'),('omnitool_admin1500269297042F77305F24917C8BF4_1_1',1500874098,'\n\0\0\0	\nnone\0\0\0return_tool_id\0\0\0\n$Jul17omnitool_admin_databaseservers1\0\0\0\raltcodes_keys\nname\0\0\0sort_column\n\r1500269296119\0\0\0_\n4_1\0\0\0	tool_mode\0\0\0\rquick_keyword\n\0\0\0\0sort_direction\n\napps_admin\0\0\0uri_base\n,omnitool_admin1500269297042F77305F24917C8BF4\0\0\0client_connection_id','omnitool_admin','1_1'),('omnitool_admin1500269297042F77305F24917C8BF4_2_1',1500874102,'\n\0\0\0	\0\0\0\0\0\0\0\raltcodes_keys\n10_1_1_1\0\0\0return_tool_id\0\0\0sort_column\n1_1\0\0\0	tool_mode\n\r1500269296120\0\0\0_\0\0\0\rquick_keyword\n\napps_admin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\n,omnitool_admin1500269297042F77305F24917C8BF4\0\0\0client_connection_id','omnitool_admin','2_1'),('omnitool_admin150034822368762B88D0E8F899CD9C_2_1',1500953024,'\n\0\0\0	\n,omnitool_admin150034822368762B88D0E8F899CD9C\0\0\0client_connection_id\nnone\0\0\0return_tool_id\n\napps_admin\0\0\0uri_base\0\0\0sort_column\0\0\0\rquick_keyword\n\r1500348222887\0\0\0_\n	Ascending\0\0\0sort_direction\n1_1\0\0\0	tool_mode\0\0\0\0\0\0\0\raltcodes_keys','omnitool_admin','2_1'),('omnitool_admin150043158414787E4CDABEC7F8262E_2_1',1501036386,'\n\0\0\0	\0\0\0\0\0\0\0\raltcodes_keys\0\0\0\rquick_keyword\n\r1500431580381\0\0\0_\n1_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\n,omnitool_admin150043158414787E4CDABEC7F8262E\0\0\0client_connection_id\0\0\0sort_column\nnone\0\0\0return_tool_id\n\napps_admin\0\0\0uri_base','omnitool_admin','2_1'),('omnitool_admin150043158414787E4CDABEC7F8262E_68_1',1501036428,'\n\0\0\0\n76_1\0\0\0	tool_mode\n1\0\0\0confirm\n10_1_9_1\0\0\0return_tool_id\n\napps_admin\0\0\0uri_base\n\"Jul17omnitool_admin_omnitoolusers2\0\0\0altcode\n\r1500431580384\0\0\0_\n,omnitool_admin150043158414787E4CDABEC7F8262E\0\0\0client_connection_id','omnitool_admin','68_1'),('omnitool_admin150043158414787E4CDABEC7F8262E_9_1',1501036431,'\n\0\0\0	\n,omnitool_admin150043158414787E4CDABEC7F8262E\0\0\0client_connection_id\n	Ascending\0\0\0sort_direction\n\napps_admin\0\0\0uri_base\n10_1_9_1\0\0\0return_tool_id\n46_1\0\0\0sort_column\n\r1500431580382\0\0\0_\0\0\0\rquick_keyword\0\0\0\n\"Jul17omnitool_admin_omnitoolusers1\0\0\0\raltcodes_keys\n8_1\0\0\0	tool_mode','omnitool_admin','9_1'),('omnitool_admin15008453989FF65DC9853CDD2997BD_2_1',1501450199,'\n\0\0\0	\n1_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\nnone\0\0\0return_tool_id\n\r1500845398313\0\0\0_\n,omnitool_admin15008453989FF65DC9853CDD2997BD\0\0\0client_connection_id\0\0\0\rquick_keyword\0\0\0sort_column\0\0\0\0\0\0\0\raltcodes_keys\n\napps_admin\0\0\0uri_base','omnitool_admin','2_1'),('omnitool_admin15008454416499EFB9E11D5942F57A_2_1',1501450241,'\n\0\0\0	\n\napps_admin\0\0\0uri_base\0\0\0\0\0\0\0\raltcodes_keys\n	Ascending\0\0\0sort_direction\0\0\0sort_column\n\r1500845440838\0\0\0_\0\0\0\rquick_keyword\n1_1\0\0\0	tool_mode\n,omnitool_admin15008454416499EFB9E11D5942F57A\0\0\0client_connection_id\nnone\0\0\0return_tool_id','omnitool_admin','2_1'),('omnitool_admin1500953158D54AF3A0BA3918AF39B4_2_1',1501557958,'\n\0\0\0	\nnone\0\0\0return_tool_id\0\0\0\rquick_keyword\n1_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\0\0\0\0\0\0\0\raltcodes_keys\0\0\0sort_column\n\r1500953160337\0\0\0_\n\napps_admin\0\0\0uri_base\n,omnitool_admin1500953158D54AF3A0BA3918AF39B4\0\0\0client_connection_id','omnitool_admin','2_1'),('omnitool_admin15011215022E862A3CBFA82B7ABDE4_2_1',1501726303,'\n\0\0\0	\n1_1\0\0\0	tool_mode\n\napps_admin\0\0\0uri_base\0\0\0\0\0\0\0\raltcodes_keys\n\r1501121508284\0\0\0_\n,omnitool_admin15011215022E862A3CBFA82B7ABDE4\0\0\0client_connection_id\nnone\0\0\0return_tool_id\n	Ascending\0\0\0sort_direction\0\0\0\rquick_keyword\0\0\0sort_column','omnitool_admin','2_1'),('omnitool_admin15012155140BCC4709A7D093D87868_2_1',1501820314,'\n\0\0\0	\0\0\0\rquick_keyword\nnone\0\0\0return_tool_id\n1_1\0\0\0	tool_mode\n	Ascending\0\0\0sort_direction\n,omnitool_admin15012155140BCC4709A7D093D87868\0\0\0client_connection_id\n\r1501215512187\0\0\0_\0\0\0\0\0\0\0\raltcodes_keys\0\0\0sort_column\n\napps_admin\0\0\0uri_base','omnitool_admin','2_1'),('omnitool_admin150121667839B6143404A3148637A2_2_1',1501821478,'\n\0\0\0	\n1_1\0\0\0	tool_mode\nnone\0\0\0return_tool_id\n\r1501216676135\0\0\0_\0\0\0\0\0\0\0\raltcodes_keys\n,omnitool_admin150121667839B6143404A3148637A2\0\0\0client_connection_id\0\0\0\rquick_keyword\n\napps_admin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0sort_column','omnitool_admin','2_1'),('omnitool_admin150129309928099016C05157688494_26_1',1501898090,'\n\0\0\0\n\r1501293099213\0\0\0_\n10_1_2_1\0\0\0return_tool_id\n30_1\0\0\0	tool_mode\n,omnitool_admin150129309928099016C05157688494\0\0\0client_connection_id\n\napps_admin\0\0\0uri_base','omnitool_admin','26_1'),('omnitool_admin150129309928099016C05157688494_2_1',1501898241,'\n\0\0\0	\n	Ascending\0\0\0sort_direction\n,omnitool_admin150129309928099016C05157688494\0\0\0client_connection_id\n\r1501293099212\0\0\0_\n	10_1_26_1\0\0\0return_tool_id\n1_1\0\0\0	tool_mode\0\0\0\0\0\0\0\raltcodes_keys\n\napps_admin\0\0\0uri_base\0\0\0\rquick_keyword\0\0\0sort_column','omnitool_admin','2_1'),('omnitool_admin15012975686CDB6B2D69359B1F050E_2_1',1501903316,'\n\0\0\0	\n1_1\0\0\0	tool_mode\n,omnitool_admin15012975686CDB6B2D69359B1F050E\0\0\0client_connection_id\n\r1501297567735\0\0\0_\0\0\0sort_column\0\0\0\0\0\0\0\raltcodes_keys\n	Ascending\0\0\0sort_direction\n\napps_admin\0\0\0uri_base\0\0\0\rquick_keyword\n	10_1_72_1\0\0\0return_tool_id','omnitool_admin','2_1'),('omnitool_admin150138685161069658476A976D46A1_2_1',1501991652,'\n\0\0\0	\n	Ascending\0\0\0sort_direction\nnone\0\0\0return_tool_id\n1_1\0\0\0	tool_mode\0\0\0\0\0\0\0\raltcodes_keys\n\r1501386850056\0\0\0_\n\napps_admin\0\0\0uri_base\n,omnitool_admin150138685161069658476A976D46A1\0\0\0client_connection_id\0\0\0\rquick_keyword\0\0\0sort_column','omnitool_admin','2_1'),('omnitool_admin150145942079188F208915FACD8180_2_1',1502064220,'\n\0\0\0	\n1_1\0\0\0	tool_mode\n\napps_admin\0\0\0uri_base\n	Ascending\0\0\0sort_direction\0\0\0\rquick_keyword\n\r1501459423391\0\0\0_\0\0\0sort_column\nnone\0\0\0return_tool_id\0\0\0\0\0\0\0\raltcodes_keys\n,omnitool_admin150145942079188F208915FACD8180\0\0\0client_connection_id','omnitool_admin','2_1');
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `update_history`
--

LOCK TABLES `update_history` WRITE;
/*!40000 ALTER TABLE `update_history` DISABLE KEYS */;
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
  `status` varchar(8) DEFAULT NULL,
  `username` varchar(20) DEFAULT NULL,
  `tied_to_ip_address` mediumtext,
  `expiration_date` varchar(10) DEFAULT NULL,
  `api_key_string` varchar(100) DEFAULT NULL,
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

-- Dump completed on 2017-07-30 22:27:15
