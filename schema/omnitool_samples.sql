-- MySQL dump 10.13  Distrib 5.7.23, for Linux (x86_64)
--
-- Host: localhost    Database: omnitool_samples
-- ------------------------------------------------------
-- Server version	5.7.23-0ubuntu0.18.04.1-log

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
  `ui_navigation_placement` varchar(15) DEFAULT NULL,
  `ui_ace_skin` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `applications`
--

LOCK TABLES `applications` WRITE;
/*!40000 ALTER TABLE `applications` DISABLE KEYS */;
INSERT INTO `applications` VALUES (1,1,'top','OmniTool Website','Active','sample_apps','default.tt','eric@weaverstreetsystems.com','OmniTool is a comprehensive platform for the rapid development of web application suites.  It is designed to simplify and speed up the development process, reducing code requirements to only the specific features and logic for the target application.  OmniTool makes life easier for developers.','None',NULL,'None','None','None','Left Side','No Skin'),(2,1,'top','Sample Tools','Active','sample_apps','default.tt','eric@weaverstreetsystems.com','A few sample tools demonstrating how OmniTool can be used.','None','10','None','None','None','Left Side','No Skin');
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
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatype_fields`
--

LOCK TABLES `datatype_fields` WRITE;
/*!40000 ALTER TABLE `datatype_fields` DISABLE KEYS */;
INSERT INTO `datatype_fields` VALUES (1,1,'6_1:2_1','Author','single_select','No','author',1,'No','No',70,NULL,NULL,NULL,NULL,NULL),(2,1,'6_1:2_1','Volume','short_text','No','volume',2,'No','No',10,NULL,NULL,NULL,NULL,NULL),(3,1,'6_1:2_1','ISBN Number','short_text','No','isbn_number',3,'Yes','Yes',20,NULL,NULL,NULL,NULL,NULL),(4,1,'6_1:2_1','Description','long_text','No','description',5,'No','No',100,NULL,NULL,NULL,NULL,NULL),(5,1,'6_1:2_1','Publication Date','short_text','No','pubdate',6,'No','No',30,NULL,NULL,NULL,NULL,NULL),(6,1,'6_1:2_1','Author Name','short_text','Yes','author_name',7,'No','No',100,NULL,NULL,NULL,NULL,NULL),(7,1,'6_1:2_1','Purchased From','single_select','No','purchased_from',4,'No','No',15,NULL,'Amazon','Amazon,B&N,Unknown',NULL,NULL),(8,1,'6_1:5_1','Date','simple_date','No','date',1,'Yes','No',100,NULL,NULL,NULL,NULL,NULL),(9,1,'6_1:6_1','Weight','low_decimal','No','weight',2,'Yes','No',100,NULL,NULL,NULL,NULL,NULL),(10,1,'6_1:6_1','Date','simple_date','No','date',1,'Yes','No',100,NULL,NULL,NULL,NULL,NULL),(11,1,'6_1:6_1','For Whom','single_select','No','for_whom',3,'Yes','No',100,NULL,NULL,'Eric,Ginger,Polly',NULL,NULL),(12,1,'6_1:7_1','Age','low_integer','No','age',1,'Yes','No',100,NULL,NULL,NULL,NULL,NULL),(13,1,'6_1:7_1','Type','single_select','No','dependent_type',2,'No','No',15,NULL,'Dog','Dog,Person',NULL,NULL),(14,1,'6_1:7_1','Medical Needs','long_text','No','medical_needs',3,'No','No',100,NULL,NULL,NULL,NULL,NULL),(15,1,'6_1:8_1','Amount','low_decimal','No','amount',4,'No','No',100,NULL,NULL,NULL,NULL,NULL),(16,1,'6_1:8_1','Expense Type','single_select','No','expense_type',1,'No','No',20,NULL,NULL,'Essential,Luxury',NULL,NULL),(17,1,'6_1:8_1','Long-Term Contract','yes_no_select','No','contract',5,'No','No',100,NULL,NULL,NULL,NULL,NULL),(19,1,'6_1:8_1','Dependent','short_text_autocomplete','No','dependent',2,'No','No',100,NULL,NULL,NULL,NULL,NULL),(20,1,'6_1:8_1','Vendor','single_select','No','vendor',3,'No','No',100,NULL,NULL,NULL,NULL,NULL),(21,1,'6_1:8_1','Expense Type','short_text','Yes','expense_type_styled',6,'No','No',100,NULL,NULL,NULL,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `datatypes`
--

LOCK TABLES `datatypes` WRITE;
/*!40000 ALTER TABLE `datatypes` DISABLE KEYS */;
INSERT INTO `datatypes` VALUES (1,1,'1_1:1_1','Book','books',NULL,NULL,NULL,'Own Table','No','Yes','1','eric','Yes',NULL,'No','No'),(2,1,'1_1:2_1','Book','books',NULL,'books',NULL,'Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No'),(4,1,'1_1:2_1','Author','authors',NULL,NULL,NULL,'Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No'),(5,1,'1_1:2_1','US Holiday','us_holidays',NULL,NULL,NULL,'Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No'),(6,1,'1_1:2_1','Weigh-In','weigh_ins',NULL,NULL,NULL,'Own Table','No','Yes','No',NULL,'No',NULL,'No','No'),(7,1,'1_1:2_1','Dependent','dependents',NULL,NULL,'Represents individuals who I have to feed every day.','Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No'),(8,1,'1_1:2_1','Budget Item','budget_items',NULL,'budget_items',NULL,'Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No'),(9,1,'1_1:2_1','Vendor','vendors',NULL,NULL,NULL,'Own Table','No','Yes','No',NULL,'Yes',NULL,'No','No');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instances`
--

LOCK TABLES `instances` WRITE;
/*!40000 ALTER TABLE `instances` DISABLE KEYS */;
INSERT INTO `instances` VALUES (1,1,'1_1:1_1','OmniTool.Org','Active','www.omnitool.org','home','eric@weaverstreetsystems.com','OmniTool is a comprehensive platform for the rapid development of web application suites.  It is designed to simplify and speed up the development process, reducing code requirements to only the specific features and logic for the target application.  OmniTool makes life easier for developers.','1','sample_tools','/ui_icons/ginger_face.png','Open','Yes','Open','No','0KQNZHlxWJ2RSQzPqkzCjA==','File System',NULL),(2,1,'1_1:2_1','Sample Tools','Active','sample-tools.omnitool.org','sample_tools','ericschernoff@gmail.com','Instance to allow access to sample tools to help familiarize you with this system.','1','sample_tools','/ui_icons/ginger_face.png','Open','No',NULL,'No',NULL,'File System',NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=152 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `metainfo`
--

LOCK TABLES `metainfo` WRITE;
/*!40000 ALTER TABLE `metainfo` DISABLE KEYS */;
INSERT INTO `metainfo` VALUES (1,1,'Jul17omnitool_admin_databaseservers1','1_1','4_1','database_servers','omnitool_admin',1500266232,'omnitool_admin',1500266232,'None',NULL,'top',NULL,'No',0),(2,1,'Jul17omnitool_admin_applications1','1_1','1_1','applications','omnitool_admin',1500349621,'omnitool_admin',1532207767,'None',0,'top','5_1:1_1,6_1:1_1,8_1:28_1,8_1:29_1,8_1:30_1,8_1:31_1,8_1:32_1,8_1:33_1,8_1:35_1,8_1:48_1','No',0),(3,1,'Jul17omnitool_admin_instances1','1_1','5_1','instances','omnitool_admin',1500349700,'omnitool_admin',1532494888,'None',0,'1_1:1_1',NULL,'No',0),(4,1,'Jul17omnitool_admin_datatypes1','1_1','6_1','datatypes','omnitool_admin',1500350065,'omnitool_admin',1501123198,'None',0,'1_1:1_1',NULL,'No',0),(5,1,'Jul17omnitool_admin_tools1','1_1','8_1','tools','omnitool_admin',1500350123,'omnitool_admin',1501476915,'None',0,'8_1:35_1','13_1:1_1','No',0),(6,1,'Jul17omnitool_admin_toolmodeconfigs1','1_1','13_1','tool_mode_configs','omnitool_admin',1500350155,'omnitool_admin',1500350168,'None',0,'8_1:1_1',NULL,'No',0),(7,1,'Jul17omnitool_admin_omnitoolusers1','1_1','9_1','omnitool_users','omnitool_admin',1500431664,'omnitool_admin',1500431664,'None',NULL,'top',NULL,'No',0),(8,1,'Jul17omnitool_admin_applications2','2_1','1_1','applications','omnitool_admin',1500434063,'omnitool_admin',1532207779,'None',0,'top','6_1:2_1,8_1:2_1,5_1:2_1,8_1:7_1,6_1:4_1,8_1:8_1,6_1:5_1,8_1:11_1,6_1:6_1,8_1:15_1,8_1:19_1,6_1:7_1,8_1:20_1,6_1:8_1,8_1:40_1,6_1:9_1','No',0),(9,1,'Jul17omnitool_admin_datatypes2','2_1','6_1','datatypes','omnitool_admin',1500434132,'omnitool_admin',1500696438,'None',0,'1_1:2_1','7_1:1_1,7_1:2_1,7_1:3_1,7_1:4_1,7_1:5_1,7_1:6_1,7_1:7_1','No',0),(10,1,'Jul17omnitool_admin_datatypefields1','1_1','7_1','datatype_fields','omnitool_admin',1500434167,'omnitool_admin',1500696454,'None',0,'6_1:2_1',NULL,'No',0),(11,1,'Jul17omnitool_admin_datatypefields2','2_1','7_1','datatype_fields','omnitool_admin',1500434194,'omnitool_admin',1500696454,'None',NULL,'6_1:2_1',NULL,'No',0),(12,1,'Jul17omnitool_admin_datatypefields3','3_1','7_1','datatype_fields','omnitool_admin',1500434235,'omnitool_admin',1500696454,'None',NULL,'6_1:2_1',NULL,'No',0),(13,1,'Jul17omnitool_admin_datatypefields4','4_1','7_1','datatype_fields','omnitool_admin',1500434257,'omnitool_admin',1500696454,'None',NULL,'6_1:2_1',NULL,'No',0),(14,1,'Jul17omnitool_admin_datatypefields5','5_1','7_1','datatype_fields','omnitool_admin',1500434280,'omnitool_admin',1500696454,'None',0,'6_1:2_1',NULL,'No',0),(15,1,'Jul17omnitool_admin_tools2','2_1','8_1','tools','omnitool_admin',1500434385,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:2_1,8_1:3_1,8_1:4_1,8_1:5_1,8_1:6_1,13_1:7_1,13_1:8_1,15_1:1_1,15_1:2_1,15_1:3_1,8_1:23_1','No',0),(16,1,'Jul17omnitool_admin_toolmodeconfigs2','2_1','13_1','tool_mode_configs','omnitool_admin',1500434385,'omnitool_admin',1500695496,'None',0,'8_1:2_1',NULL,'No',0),(17,1,'Jul17omnitool_admin_tools3','3_1','8_1','tools','omnitool_admin',1500434385,'omnitool_admin',1500864449,'None',NULL,'8_1:2_1','13_1:3_1','No',0),(18,1,'Jul17omnitool_admin_toolmodeconfigs3','3_1','13_1','tool_mode_configs','omnitool_admin',1500434385,'omnitool_admin',1500434385,'None',NULL,'8_1:3_1',NULL,'No',0),(19,1,'Jul17omnitool_admin_tools4','4_1','8_1','tools','omnitool_admin',1500434385,'omnitool_admin',1500864449,'None',NULL,'8_1:2_1','13_1:4_1','No',0),(20,1,'Jul17omnitool_admin_toolmodeconfigs4','4_1','13_1','tool_mode_configs','omnitool_admin',1500434385,'omnitool_admin',1500434385,'None',NULL,'8_1:4_1',NULL,'No',0),(21,1,'Jul17omnitool_admin_tools5','5_1','8_1','tools','omnitool_admin',1500434385,'omnitool_admin',1500864449,'None',0,'8_1:2_1','13_1:5_1','No',0),(22,1,'Jul17omnitool_admin_toolmodeconfigs5','5_1','13_1','tool_mode_configs','omnitool_admin',1500434385,'omnitool_admin',1500434385,'None',NULL,'8_1:5_1',NULL,'No',0),(23,1,'Jul17omnitool_admin_instances2','2_1','5_1','instances','omnitool_admin',1500434622,'omnitool_admin',1500866769,'None',0,'1_1:2_1',NULL,'No',0),(24,1,'Jul17omnitool_admin_tools6','6_1','8_1','tools','omnitool_admin',1500464416,'omnitool_admin',1500864449,'None',NULL,'8_1:2_1','13_1:6_1','No',0),(25,1,'Jul17omnitool_admin_toolmodeconfigs6','6_1','13_1','tool_mode_configs','omnitool_admin',1500464442,'omnitool_admin',1500464442,'None',NULL,'8_1:6_1',NULL,'No',0),(26,1,'Jul17omnitool_admin_toolmodeconfigs7','7_1','13_1','tool_mode_configs','omnitool_admin',1500488569,'omnitool_admin',1500695281,'None',0,'8_1:2_1',NULL,'No',0),(27,1,'Jul17omnitool_admin_toolmodeconfigs8','8_1','13_1','tool_mode_configs','omnitool_admin',1500488589,'omnitool_admin',1500695517,'None',0,'8_1:2_1',NULL,'No',0),(28,1,'Jul17omnitool_admin_tools7','7_1','8_1','tools','omnitool_admin',1500518310,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:9_1','No',0),(29,1,'Jul17omnitool_admin_toolmodeconfigs9','9_1','13_1','tool_mode_configs','omnitool_admin',1500518385,'omnitool_admin',1500518385,'None',0,'8_1:7_1',NULL,'No',0),(31,1,'Jul17omnitool_admin_datatypes4','4_1','6_1','datatypes','omnitool_admin',1500693731,'omnitool_admin',1500693731,'None',NULL,'1_1:2_1',NULL,'No',0),(32,1,'Jul17omnitool_admin_tools8','8_1','8_1','tools','omnitool_admin',1500693761,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:10_1,8_1:9_1,8_1:10_1','No',0),(33,1,'Jul17omnitool_admin_toolmodeconfigs10','10_1','13_1','tool_mode_configs','omnitool_admin',1500693761,'omnitool_admin',1500693761,'None',NULL,'8_1:8_1',NULL,'No',0),(34,1,'Jul17omnitool_admin_tools9','9_1','8_1','tools','omnitool_admin',1500693761,'omnitool_admin',1500693761,'None',0,'8_1:8_1','13_1:11_1','No',0),(35,1,'Jul17omnitool_admin_toolmodeconfigs11','11_1','13_1','tool_mode_configs','omnitool_admin',1500693761,'omnitool_admin',1500845021,'None',0,'8_1:9_1',NULL,'No',0),(36,1,'Jul17omnitool_admin_tools10','10_1','8_1','tools','omnitool_admin',1500693761,'omnitool_admin',1500693761,'None',NULL,'8_1:8_1','13_1:12_1','No',0),(37,1,'Jul17omnitool_admin_toolmodeconfigs12','12_1','13_1','tool_mode_configs','omnitool_admin',1500693761,'omnitool_admin',1500845050,'None',0,'8_1:10_1',NULL,'No',0),(38,1,'Jul17omnitool_admin_datatypefields6','6_1','7_1','datatype_fields','omnitool_admin',1500695220,'omnitool_admin',1500696454,'None',NULL,'6_1:2_1',NULL,'No',0),(39,1,'Jul17omnitool_admin_datatypefields7','7_1','7_1','datatype_fields','omnitool_admin',1500696438,'omnitool_admin',1500696454,'None',NULL,'6_1:2_1',NULL,'No',0),(40,1,'Jul17omnitool_admin_toolfiltermenus1','1_1','15_1','tool_filter_menus','omnitool_admin',1500696622,'omnitool_admin',1500697017,'None',NULL,'8_1:2_1',NULL,'No',0),(41,1,'Jul17omnitool_admin_toolfiltermenus2','2_1','15_1','tool_filter_menus','omnitool_admin',1500696838,'omnitool_admin',1500697017,'None',NULL,'8_1:2_1',NULL,'No',0),(42,1,'Jul17omnitool_admin_toolfiltermenus3','3_1','15_1','tool_filter_menus','omnitool_admin',1500697006,'omnitool_admin',1501552002,'None',0,'8_1:2_1',NULL,'No',0),(43,1,'Jul17omnitool_admin_datatypes5','5_1','6_1','datatypes','omnitool_admin',1500698505,'omnitool_admin',1500698534,'None',NULL,'1_1:2_1','7_1:8_1','No',0),(44,1,'Jul17omnitool_admin_datatypefields8','8_1','7_1','datatype_fields','omnitool_admin',1500698534,'omnitool_admin',1500698534,'None',NULL,'6_1:5_1',NULL,'No',0),(45,1,'Jul17omnitool_admin_tools11','11_1','8_1','tools','omnitool_admin',1500698788,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:13_1,8_1:12_1,8_1:13_1,8_1:14_1,13_1:17_1','No',0),(46,1,'Jul17omnitool_admin_toolmodeconfigs13','13_1','13_1','tool_mode_configs','omnitool_admin',1500698788,'omnitool_admin',1500698788,'None',NULL,'8_1:11_1',NULL,'No',0),(47,1,'Jul17omnitool_admin_tools12','12_1','8_1','tools','omnitool_admin',1500698788,'omnitool_admin',1500698788,'None',NULL,'8_1:11_1','13_1:14_1','No',0),(48,1,'Jul17omnitool_admin_toolmodeconfigs14','14_1','13_1','tool_mode_configs','omnitool_admin',1500698788,'omnitool_admin',1500698788,'None',NULL,'8_1:12_1',NULL,'No',0),(49,1,'Jul17omnitool_admin_tools13','13_1','8_1','tools','omnitool_admin',1500698788,'omnitool_admin',1500737471,'None',0,'8_1:11_1','13_1:15_1','No',0),(50,1,'Jul17omnitool_admin_toolmodeconfigs15','15_1','13_1','tool_mode_configs','omnitool_admin',1500698788,'omnitool_admin',1500737794,'None',0,'8_1:13_1',NULL,'No',0),(51,1,'Jul17omnitool_admin_tools14','14_1','8_1','tools','omnitool_admin',1500698788,'omnitool_admin',1500698788,'None',NULL,'8_1:11_1','13_1:16_1','No',0),(52,1,'Jul17omnitool_admin_toolmodeconfigs16','16_1','13_1','tool_mode_configs','omnitool_admin',1500698788,'omnitool_admin',1500698788,'None',NULL,'8_1:14_1',NULL,'No',0),(53,1,'Jul17omnitool_admin_toolmodeconfigs17','17_1','13_1','tool_mode_configs','omnitool_admin',1500737201,'omnitool_admin',1500737371,'None',0,'8_1:11_1',NULL,'No',0),(54,1,'Jul17omnitool_admin_datatypes6','6_1','6_1','datatypes','omnitool_admin',1500738695,'omnitool_admin',1500738786,'None',0,'1_1:2_1','7_1:9_1,7_1:10_1,7_1:11_1','No',0),(55,1,'Jul17omnitool_admin_datatypefields9','9_1','7_1','datatype_fields','omnitool_admin',1500738717,'omnitool_admin',1500738779,'None',NULL,'6_1:6_1',NULL,'No',0),(56,1,'Jul17omnitool_admin_datatypefields10','10_1','7_1','datatype_fields','omnitool_admin',1500738730,'omnitool_admin',1500738779,'None',NULL,'6_1:6_1',NULL,'No',0),(57,1,'Jul17omnitool_admin_datatypefields11','11_1','7_1','datatype_fields','omnitool_admin',1500738767,'omnitool_admin',1500738779,'None',NULL,'6_1:6_1',NULL,'No',0),(58,1,'Jul17omnitool_admin_tools15','15_1','8_1','tools','omnitool_admin',1500738817,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:18_1,8_1:16_1,8_1:17_1,8_1:18_1,15_1:4_1','No',0),(59,1,'Jul17omnitool_admin_toolmodeconfigs18','18_1','13_1','tool_mode_configs','omnitool_admin',1500738817,'omnitool_admin',1500844219,'None',0,'8_1:15_1',NULL,'No',0),(60,1,'Jul17omnitool_admin_tools16','16_1','8_1','tools','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:15_1','13_1:19_1','No',0),(61,1,'Jul17omnitool_admin_toolmodeconfigs19','19_1','13_1','tool_mode_configs','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:16_1',NULL,'No',0),(62,1,'Jul17omnitool_admin_tools17','17_1','8_1','tools','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:15_1','13_1:20_1','No',0),(63,1,'Jul17omnitool_admin_toolmodeconfigs20','20_1','13_1','tool_mode_configs','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:17_1',NULL,'No',0),(64,1,'Jul17omnitool_admin_tools18','18_1','8_1','tools','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:15_1','13_1:21_1','No',0),(65,1,'Jul17omnitool_admin_toolmodeconfigs21','21_1','13_1','tool_mode_configs','omnitool_admin',1500738817,'omnitool_admin',1500738817,'None',NULL,'8_1:18_1',NULL,'No',0),(66,1,'Jul17omnitool_admin_toolfiltermenus4','4_1','15_1','tool_filter_menus','omnitool_admin',1500738979,'omnitool_admin',1500739033,'None',0,'8_1:15_1',NULL,'No',0),(67,1,'Jul17omnitool_admin_tools19','19_1','8_1','tools','omnitool_admin',1500740001,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:22_1,13_1:23_1','No',0),(68,1,'Jul17omnitool_admin_toolmodeconfigs22','22_1','13_1','tool_mode_configs','omnitool_admin',1500740074,'omnitool_admin',1500754461,'None',0,'8_1:19_1',NULL,'No',0),(69,1,'Jul17omnitool_admin_toolmodeconfigs23','23_1','13_1','tool_mode_configs','omnitool_admin',1500740095,'omnitool_admin',1500743557,'None',0,'8_1:19_1',NULL,'No',0),(70,1,'Jul17omnitool_admin_datatypes7','7_1','6_1','datatypes','omnitool_admin',1500847062,'omnitool_admin',1501162826,'None',NULL,'1_1:2_1','7_1:12_1,7_1:13_1,7_1:14_1','No',0),(71,1,'Jul17omnitool_admin_datatypefields12','12_1','7_1','datatype_fields','omnitool_admin',1500847141,'omnitool_admin',1500847141,'None',NULL,'6_1:7_1',NULL,'No',0),(72,1,'Jul17omnitool_admin_datatypefields13','13_1','7_1','datatype_fields','omnitool_admin',1500847168,'omnitool_admin',1500847168,'None',NULL,'6_1:7_1',NULL,'No',0),(73,1,'Jul17omnitool_admin_tools20','20_1','8_1','tools','omnitool_admin',1500847194,'omnitool_admin',1501553541,'None',0,'1_1:2_1','13_1:24_1,8_1:21_1,8_1:22_1,13_1:27_1,13_1:28_1,8_1:34_1,13_1:41_1','No',0),(74,1,'Jul17omnitool_admin_toolmodeconfigs24','24_1','13_1','tool_mode_configs','omnitool_admin',1500847194,'omnitool_admin',1500847347,'None',0,'8_1:20_1',NULL,'No',0),(75,1,'Jul17omnitool_admin_tools21','21_1','8_1','tools','omnitool_admin',1500847194,'omnitool_admin',1500847194,'None',NULL,'8_1:20_1','13_1:25_1','No',0),(76,1,'Jul17omnitool_admin_toolmodeconfigs25','25_1','13_1','tool_mode_configs','omnitool_admin',1500847194,'omnitool_admin',1500847194,'None',NULL,'8_1:21_1',NULL,'No',0),(77,1,'Jul17omnitool_admin_tools22','22_1','8_1','tools','omnitool_admin',1500847194,'omnitool_admin',1500847194,'None',NULL,'8_1:20_1','13_1:26_1','No',0),(78,1,'Jul17omnitool_admin_toolmodeconfigs26','26_1','13_1','tool_mode_configs','omnitool_admin',1500847194,'omnitool_admin',1500847194,'None',NULL,'8_1:22_1',NULL,'No',0),(79,1,'Jul17omnitool_admin_toolmodeconfigs27','27_1','13_1','tool_mode_configs','omnitool_admin',1500847371,'omnitool_admin',1500847371,'None',0,'8_1:20_1',NULL,'No',0),(80,1,'Jul17omnitool_admin_toolmodeconfigs28','28_1','13_1','tool_mode_configs','omnitool_admin',1500847384,'omnitool_admin',1500847384,'None',NULL,'8_1:20_1',NULL,'No',0),(81,1,'Jul17omnitool_admin_tools23','23_1','8_1','tools','omnitool_admin',1500864379,'omnitool_admin',1500864449,'None',NULL,'8_1:2_1','13_1:29_1','No',0),(82,1,'Jul17omnitool_admin_toolmodeconfigs29','29_1','13_1','tool_mode_configs','omnitool_admin',1500864398,'omnitool_admin',1500864398,'None',NULL,'8_1:23_1',NULL,'No',0),(96,1,'Jul17omnitool_admin_tools28','28_1','8_1','tools','omnitool_admin',1500951728,'omnitool_admin',1501604496,'None',0,'1_1:1_1','13_1:34_1','No',0),(97,1,'Jul17omnitool_admin_toolmodeconfigs34','34_1','13_1','tool_mode_configs','omnitool_admin',1500951747,'omnitool_admin',1500951747,'None',NULL,'8_1:28_1',NULL,'No',0),(98,1,'Jul17omnitool_admin_tools29','29_1','8_1','tools','omnitool_admin',1501035593,'omnitool_admin',1534706249,'None',0,'1_1:1_1','13_1:35_1','No',0),(99,1,'Jul17omnitool_admin_toolmodeconfigs35','35_1','13_1','tool_mode_configs','omnitool_admin',1501035703,'omnitool_admin',1501035703,'None',NULL,'8_1:29_1',NULL,'No',0),(100,1,'Jul17omnitool_admin_tools30','30_1','8_1','tools','omnitool_admin',1501036229,'omnitool_admin',1501604496,'None',0,'1_1:1_1','13_1:36_1','No',0),(101,1,'Jul17omnitool_admin_toolmodeconfigs36','36_1','13_1','tool_mode_configs','omnitool_admin',1501036270,'omnitool_admin',1501036270,'None',NULL,'8_1:30_1',NULL,'No',0),(102,1,'Jul17omnitool_admin_tools31','31_1','8_1','tools','omnitool_admin',1501036422,'omnitool_admin',1501604496,'None',0,'1_1:1_1','13_1:37_1','No',0),(103,1,'Jul17omnitool_admin_toolmodeconfigs37','37_1','13_1','tool_mode_configs','omnitool_admin',1501036512,'omnitool_admin',1501036512,'None',NULL,'8_1:31_1',NULL,'No',0),(104,1,'Jul17omnitool_admin_tools32','32_1','8_1','tools','omnitool_admin',1501036644,'omnitool_admin',1501604496,'None',0,'1_1:1_1','13_1:38_1','No',0),(105,1,'Jul17omnitool_admin_toolmodeconfigs38','38_1','13_1','tool_mode_configs','omnitool_admin',1501036754,'omnitool_admin',1501036754,'None',0,'8_1:32_1',NULL,'No',0),(106,1,'Jul17omnitool_admin_tools33','33_1','8_1','tools','omnitool_admin',1501043141,'omnitool_admin',1501604496,'None',0,'1_1:1_1','13_1:39_1','No',0),(107,1,'Jul17omnitool_admin_toolmodeconfigs39','39_1','13_1','tool_mode_configs','omnitool_admin',1501043203,'omnitool_admin',1501123406,'None',0,'8_1:33_1',NULL,'No',0),(108,1,'Jul17omnitool_admin_tools34','34_1','8_1','tools','omnitool_admin',1501162701,'omnitool_admin',1501164931,'None',0,'8_1:20_1','13_1:40_1','No',0),(109,1,'Jul17omnitool_admin_toolmodeconfigs40','40_1','13_1','tool_mode_configs','omnitool_admin',1501162755,'omnitool_admin',1501164352,'None',0,'8_1:34_1',NULL,'No',0),(110,1,'Jul17omnitool_admin_datatypefields14','14_1','7_1','datatype_fields','omnitool_admin',1501162826,'omnitool_admin',1501162826,'None',NULL,'6_1:7_1',NULL,'No',0),(111,1,'Jul17omnitool_admin_toolmodeconfigs41','41_1','13_1','tool_mode_configs','omnitool_admin',1501165004,'omnitool_admin',1501165059,'None',0,'8_1:20_1',NULL,'No',0),(113,1,'Jul17omnitool_admin_tools35','35_1','8_1','tools','omnitool_admin',1501469530,'omnitool_admin',1501604496,'None',0,'1_1:1_1','8_1:1_1,13_1:43_1,8_1:36_1,8_1:37_1,8_1:38_1,8_1:39_1','No',0),(115,1,'Jul17omnitool_admin_toolmodeconfigs43','43_1','13_1','tool_mode_configs','omnitool_admin',1501470779,'omnitool_admin',1501470779,'None',NULL,'8_1:35_1',NULL,'No',0),(116,1,'Jul17omnitool_admin_tools36','36_1','8_1','tools','omnitool_admin',1501473814,'omnitool_admin',1501476915,'None',0,'8_1:35_1','13_1:44_1','No',0),(117,1,'Jul17omnitool_admin_toolmodeconfigs44','44_1','13_1','tool_mode_configs','omnitool_admin',1501473847,'omnitool_admin',1501473847,'None',NULL,'8_1:36_1',NULL,'No',0),(118,1,'Jul17omnitool_admin_tools37','37_1','8_1','tools','omnitool_admin',1501474406,'omnitool_admin',1501481341,'None',0,'8_1:35_1','13_1:45_1','No',0),(119,1,'Jul17omnitool_admin_toolmodeconfigs45','45_1','13_1','tool_mode_configs','omnitool_admin',1501474494,'omnitool_admin',1501474494,'None',NULL,'8_1:37_1',NULL,'No',0),(120,1,'Jul17omnitool_admin_tools38','38_1','8_1','tools','omnitool_admin',1501476583,'omnitool_admin',1501477152,'None',0,'8_1:35_1','13_1:46_1','No',0),(121,1,'Jul17omnitool_admin_toolmodeconfigs46','46_1','13_1','tool_mode_configs','omnitool_admin',1501476606,'omnitool_admin',1501476606,'None',NULL,'8_1:38_1',NULL,'No',0),(122,1,'Jul17omnitool_admin_tools39','39_1','8_1','tools','omnitool_admin',1501477909,'omnitool_admin',1501478265,'None',0,'8_1:35_1','13_1:47_1','No',0),(123,1,'Jul17omnitool_admin_toolmodeconfigs47','47_1','13_1','tool_mode_configs','omnitool_admin',1501478061,'omnitool_admin',1501478061,'None',NULL,'8_1:39_1',NULL,'No',0),(124,1,'Jul17omnitool_admin_datatypes8','8_1','6_1','datatypes','omnitool_admin',1501553384,'omnitool_admin',1501556867,'None',0,'1_1:2_1','7_1:15_1,7_1:16_1,7_1:17_1,7_1:19_1,7_1:20_1,7_1:21_1','No',0),(125,1,'Jul17omnitool_admin_datatypefields15','15_1','7_1','datatype_fields','omnitool_admin',1501553411,'omnitool_admin',1501556881,'None',0,'6_1:8_1',NULL,'No',0),(126,1,'Jul17omnitool_admin_datatypefields16','16_1','7_1','datatype_fields','omnitool_admin',1501553447,'omnitool_admin',1501556881,'None',NULL,'6_1:8_1',NULL,'No',0),(127,1,'Jul17omnitool_admin_datatypefields17','17_1','7_1','datatype_fields','omnitool_admin',1501553470,'omnitool_admin',1501556881,'None',NULL,'6_1:8_1',NULL,'No',0),(128,1,'Jul17omnitool_admin_tools40','40_1','8_1','tools','omnitool_admin',1501553517,'omnitool_admin',1501556232,'None',0,'1_1:2_1','13_1:48_1,8_1:41_1,8_1:42_1,8_1:43_1,8_1:44_1,13_1:53_1,8_1:45_1','No',0),(129,1,'Jul17omnitool_admin_toolmodeconfigs48','48_1','13_1','tool_mode_configs','omnitool_admin',1501553517,'omnitool_admin',1501556908,'None',0,'8_1:40_1',NULL,'No',0),(130,1,'Jul17omnitool_admin_tools41','41_1','8_1','tools','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:40_1','13_1:49_1','No',0),(131,1,'Jul17omnitool_admin_toolmodeconfigs49','49_1','13_1','tool_mode_configs','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:41_1',NULL,'No',0),(132,1,'Jul17omnitool_admin_tools42','42_1','8_1','tools','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:40_1','13_1:50_1','No',0),(133,1,'Jul17omnitool_admin_toolmodeconfigs50','50_1','13_1','tool_mode_configs','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:42_1',NULL,'No',0),(134,1,'Jul17omnitool_admin_tools43','43_1','8_1','tools','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:40_1','13_1:51_1','No',0),(135,1,'Jul17omnitool_admin_toolmodeconfigs51','51_1','13_1','tool_mode_configs','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:43_1',NULL,'No',0),(136,1,'Jul17omnitool_admin_tools44','44_1','8_1','tools','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:40_1','13_1:52_1','No',0),(137,1,'Jul17omnitool_admin_toolmodeconfigs52','52_1','13_1','tool_mode_configs','omnitool_admin',1501553517,'omnitool_admin',1501553517,'None',NULL,'8_1:44_1',NULL,'No',0),(138,1,'Jul17omnitool_admin_toolmodeconfigs53','53_1','13_1','tool_mode_configs','omnitool_admin',1501553680,'omnitool_admin',1501553680,'None',NULL,'8_1:40_1',NULL,'No',0),(139,1,'Jul17omnitool_admin_datatypes9','9_1','6_1','datatypes','omnitool_admin',1501556210,'omnitool_admin',1501556210,'None',NULL,'1_1:2_1',NULL,'No',0),(140,1,'Jul17omnitool_admin_tools45','45_1','8_1','tools','omnitool_admin',1501556232,'omnitool_admin',1501556249,'None',0,'8_1:40_1','13_1:54_1,8_1:46_1,8_1:47_1','No',0),(141,1,'Jul17omnitool_admin_toolmodeconfigs54','54_1','13_1','tool_mode_configs','omnitool_admin',1501556232,'omnitool_admin',1501556232,'None',NULL,'8_1:45_1',NULL,'No',0),(142,1,'Jul17omnitool_admin_tools46','46_1','8_1','tools','omnitool_admin',1501556232,'omnitool_admin',1501556232,'None',NULL,'8_1:45_1','13_1:55_1','No',0),(143,1,'Jul17omnitool_admin_toolmodeconfigs55','55_1','13_1','tool_mode_configs','omnitool_admin',1501556232,'omnitool_admin',1501556232,'None',NULL,'8_1:46_1',NULL,'No',0),(144,1,'Jul17omnitool_admin_tools47','47_1','8_1','tools','omnitool_admin',1501556232,'omnitool_admin',1501556232,'None',NULL,'8_1:45_1','13_1:56_1','No',0),(145,1,'Jul17omnitool_admin_toolmodeconfigs56','56_1','13_1','tool_mode_configs','omnitool_admin',1501556232,'omnitool_admin',1501556232,'None',NULL,'8_1:47_1',NULL,'No',0),(147,1,'Jul17omnitool_admin_datatypefields19','19_1','7_1','datatype_fields','omnitool_admin',1501556683,'omnitool_admin',1501556881,'None',NULL,'6_1:8_1',NULL,'No',0),(148,1,'Jul17omnitool_admin_datatypefields20','20_1','7_1','datatype_fields','omnitool_admin',1501556701,'omnitool_admin',1501556881,'None',NULL,'6_1:8_1',NULL,'No',0),(149,1,'Jul17omnitool_admin_datatypefields21','21_1','7_1','datatype_fields','omnitool_admin',1501556867,'omnitool_admin',1501556881,'None',NULL,'6_1:8_1',NULL,'No',0),(150,1,'Aug17omnitool_admin_tools48','48_1','8_1','tools','omnitool_admin',1501604367,'omnitool_admin',1501604817,'None',0,'1_1:1_1','13_1:57_1','No',0),(151,1,'Aug17omnitool_admin_toolmodeconfigs57','57_1','13_1','tool_mode_configs','omnitool_admin',1501604421,'omnitool_admin',1501604421,'None',NULL,'8_1:48_1',NULL,'No',0);
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
INSERT INTO `omnitool_users` VALUES (1,1,'top','OmniTool Admin','omnitool_admin','{X-PBKDF2}HMACSHA3+512:AADDUA:xcoMaPDcGSC3PA6uhR4TsOot8EqCbnRSuxQjOdps:+6JaOErTHNwHfWgmcdilp9efrlQ0YN+Jmk0tHPe+iWCszGf4FodnLoynL6DCFkRB9vL4nNRXiJFvERq2lFprkg==',NULL,'No','2018-07-24');
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_filter_menus`
--

LOCK TABLES `tool_filter_menus` WRITE;
/*!40000 ALTER TABLE `tool_filter_menus` DISABLE KEYS */;
INSERT INTO `tool_filter_menus` VALUES (1,1,'8_1:2_1','Purchased From','Quick Search','purchased_from','=','Direct','Single-Select','Yes',2,'Comma-Separated List',NULL,'Amazon,B&N,Unknown',NULL,NULL,NULL,NULL,NULL),(2,1,'8_1:2_1','Author Name','Advanced Search','author','=','Direct','Single-Select','Yes',3,'Method','author_filter_menu',NULL,NULL,NULL,NULL,NULL,NULL),(3,1,'8_1:2_1','Keyword Match','Advanced Search','description','regexp','Direct','Keyword','No',1,'Name/Value Pairs',NULL,'Title=name\nDescription=description',NULL,NULL,NULL,NULL,NULL),(4,1,'8_1:15_1','For Whom','Quick Search','for_whom','=','Direct','Single-Select','Yes',1,'Comma-Separated List',NULL,'Ginger,Polly,Eric',NULL,NULL,'Ginger',NULL,NULL);
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
  `single_record_refresh_mode` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_mode_configs`
--

LOCK TABLES `tool_mode_configs` WRITE;
/*!40000 ALTER TABLE `tool_mode_configs` DISABLE KEYS */;
INSERT INTO `tool_mode_configs` VALUES (1,1,'8_1:1_1','Results','Results_SearchForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(2,1,'8_1:2_1','Table View','Table',NULL,NULL,1,'Name,6_1,3_1,5_1,2_1','','100','Ascending',NULL,'None',NULL,'No',NULL),(3,1,'8_1:3_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(4,1,'8_1:4_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(5,1,'8_1:5_1','Message Modal','MessageModal',NULL,NULL,1,'','','No Max','Ascending','No','',NULL,'No',NULL),(6,1,'8_1:6_1','Modal Form','ModalForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(7,1,'8_1:2_1','Datatable','Table',NULL,NULL,2,'Name,6_1,3_1,5_1,2_1','','100','Ascending',NULL,'make_data_table',NULL,'No',NULL),(8,1,'8_1:2_1','Widgets','WidgetsV3',NULL,NULL,3,'Name,6_1,3_1,5_1,2_1,4_1','','50','Ascending',NULL,'None',NULL,'No',NULL),(9,1,'8_1:7_1','Results Form','Results_SearchForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(10,1,'8_1:8_1','Table View','Table',NULL,NULL,1,'Name','','No Max','Ascending','No','None',NULL,'No',NULL),(11,1,'8_1:9_1','Form View','ScreenForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,NULL,NULL,'No',NULL),(12,1,'8_1:10_1','Form View','ScreenForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(13,1,'8_1:11_1','Table View','Table',NULL,NULL,1,'Name,8_1','','No Max','Ascending','No','None',NULL,'No',NULL),(14,1,'8_1:12_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(15,1,'8_1:13_1','Form View','ModalForm',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(16,1,'8_1:14_1','Message Modal','MessageModal',NULL,NULL,1,'','','No Max','Ascending','No','',NULL,'No',NULL),(17,1,'8_1:11_1','Calendar','Calendar',NULL,NULL,1,'Name,8_1','','No Max','Ascending',NULL,'start_calendar',NULL,'No',NULL),(18,1,'8_1:15_1','Table View','Table',NULL,NULL,1,'11_1,9_1,10_1','','No Max','Descending',NULL,'None',NULL,'Bar Chart',NULL),(19,1,'8_1:16_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(20,1,'8_1:17_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(21,1,'8_1:18_1','Message Modal','MessageModal',NULL,NULL,1,'','','No Max','Ascending','No','',NULL,'No',NULL),(22,1,'8_1:19_1','MultiTables - Standard','Results_SearchForm_MultiTables',NULL,NULL,1,NULL,'Open','No Max','Ascending',NULL,'form_plus_data_tables',NULL,'No',NULL),(23,1,'8_1:19_1','MultiTables - Wide Search Form','Results_SearchForm_MultiTables_Horizantial',NULL,NULL,2,NULL,'Open','No Max','Ascending',NULL,'form_plus_data_tables',NULL,'No',NULL),(24,1,'8_1:20_1','Table / Pie Chart','Table',NULL,NULL,1,'Name,12_1,13_1','','No Max','Ascending',NULL,'None',NULL,'Pie Chart',NULL),(25,1,'8_1:21_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(26,1,'8_1:22_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(27,1,'8_1:20_1','Table / Bar Chart','Table',NULL,NULL,2,'Name,12_1,13_1','','No Max','Ascending',NULL,'None',NULL,'Bar Chart',NULL),(28,1,'8_1:20_1','Table / Line Chart','Table',NULL,NULL,3,'Name,12_1,13_1','','No Max','Ascending',NULL,'None',NULL,'Line Chart',NULL),(29,1,'8_1:23_1','Complex Details','Complex_Details',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(34,1,'8_1:28_1','HTML','JustHTML',NULL,NULL,NULL,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(35,1,'8_1:29_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(36,1,'8_1:30_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(37,1,'8_1:31_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(38,1,'8_1:32_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(39,1,'8_1:33_1','Form View','ScreenForm_DisplayInstructions',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(40,1,'8_1:34_1','View Details','Complex_Details',NULL,NULL,1,'12_1,13_1,14_1','','No Max','Ascending',NULL,'None',NULL,'No',NULL),(41,1,'8_1:20_1','Table / Pie Chart / Age-by-Type','Table',NULL,NULL,2,'13_1,12_1,Name','','No Max','Ascending',NULL,'None',NULL,'Pie Chart',NULL),(43,1,'8_1:35_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(44,1,'8_1:36_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(45,1,'8_1:37_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(46,1,'8_1:38_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(47,1,'8_1:39_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL),(48,1,'8_1:40_1','Table View','Table',NULL,NULL,1,'Name,15_1,21_1','','No Max','Ascending',NULL,'None',NULL,'No',NULL),(49,1,'8_1:41_1','Complex Details','Complex_Details',NULL,NULL,1,'15_1,16_1,17_1','','No Max','Ascending','No','None',NULL,'No',NULL),(50,1,'8_1:42_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(51,1,'8_1:43_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(52,1,'8_1:44_1','Message Modal','MessageModal',NULL,NULL,1,'','','No Max','Ascending','No','',NULL,'No',NULL),(53,1,'8_1:40_1','Cost by Type','Table',NULL,NULL,2,'16_1,15_1,Name','','No Max','Ascending',NULL,'None',NULL,'Pie Chart',NULL),(54,1,'8_1:45_1','Table View','Table',NULL,NULL,1,'Name','','No Max','Ascending','No','None',NULL,'No',NULL),(55,1,'8_1:46_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(56,1,'8_1:47_1','Form View','ScreenForm',NULL,NULL,1,'','','No Max','Ascending','No','None',NULL,'No',NULL),(57,1,'8_1:48_1','HTML View','JustHTML',NULL,NULL,1,NULL,'','No Max','Ascending',NULL,'None',NULL,'No',NULL);
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
  `supports_advanced_sorting` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`code`,`server_id`),
  KEY `parent` (`parent`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tools`
--

LOCK TABLES `tools` WRITE;
/*!40000 ALTER TABLE `tools` DISABLE KEYS */;
INSERT INTO `tools` VALUES (1,1,'8_1:35_1','Very Thrilling Perl Module Documentation','view_documentation','view_module_documentation','None','Module Docs','fa-book',4,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,NULL,'No','No','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(2,1,'1_1:2_1','Search Books','books','search_books','None','Search Books','fa-book',1,'Menubar','2_1','Search - Screen',NULL,'No','No','8_1','My wife loves books, so I came up with this Tool to keep track of them, so that I don\'t accidentally buy one she already has.  \n<br/><br/>\nThis Tool demonstrates simple CRUD, multiple views, and an alternative way to add data.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(3,1,'8_1:2_1','Create a Book','create','standard_data_actions','None','Create a Book','fa-plus',1,'Quick Actions','2_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(4,1,'8_1:2_1','Update a Book','update','standard_data_actions','None','Update a Book','fa-edit',3,'Inline / Data Row','2_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(5,1,'8_1:2_1','Delete a Book','delete','standard_delete','None','Delete a Book','fa-eraser',5,'Inline / Data Row','2_1','Action - Modal',NULL,'No','No',NULL,NULL,'No','No','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(6,1,'8_1:2_1','Add Book via ISBN Number','add_via_isbn','add_via_isbn','None','Add via ISBN','fa-google-plus',4,'Quick Actions','2_1','Action - Modal',NULL,'No','No',NULL,NULL,'Yes','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(7,1,'1_1:2_1','Lookup Book by ISBN','isbn_lookup','isbn_lookup','None','ISBN Lookup','fa-google',2,'Menubar','2_1','Action - Screen',NULL,'No','No',NULL,'Searches Google Books for the ISBN Number you provide using WWW::Scraper::ISBN.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(8,1,'1_1:2_1','Manage Authors','author','None','None','Manage Authors','fa-user',4,'Menubar','4_1','Search - Screen',NULL,'No','No',NULL,NULL,'Yes','No','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(9,1,'8_1:8_1','Create a Author','create','standard_data_actions','None','Create a Author','fa-plus',1,'Quick Actions','4_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(10,1,'8_1:8_1','Update a Author','update','standard_data_actions','None','Update a Author','fa-edit',1,'Inline / Data Row','4_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(11,1,'1_1:2_1','Manage US Holidays','usholiday','None','None','US Holidays','fa-calendar',5,'Menubar','5_1','Search - Screen',NULL,'No','No','17_1','Example of a Calendar tool.  When setting up calendars, configure the Tool View Mode to use the \'Calendar.tt. Jemplate, plus set \'start_calendar\' for \'Run JS Function on Load\', and finally, set the \'Fields to Include\' so that the Name/Title field is first and the date or date/time field is second.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(12,1,'8_1:11_1','Create a US Holiday','create','standard_data_actions','None','Create a US Holiday','fa-plus',1,'Quick Actions','5_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(13,1,'8_1:11_1','Update a US Holiday','update','standard_data_actions','None','Update a US Holiday','fa-edit',1,'Inline / Data Row','5_1','Action - Modal',NULL,'No','Yes',NULL,NULL,'Yes','No','Open',NULL,NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(14,1,'8_1:11_1','Delete a US Holiday','delete','standard_delete','None','Delete a US Holiday','fa-eraser',2,'Inline / Data Row','5_1','Action - Modal','No','No','No',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(15,1,'1_1:2_1','Manage Weigh-Ins','weighin','weighins','None','Weigh-Ins','fa-line-chart',6,'Menubar','6_1','Search - Screen',NULL,'No','No',NULL,'Demonstrates charting and low_decimel fields.  Also, I need to be on a diet.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(16,1,'8_1:15_1','Create a Weigh-In','create','standard_data_actions','None','Create a Weigh-In','fa-plus',1,'Quick Actions','6_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(17,1,'8_1:15_1','Update a Weigh-In','update','standard_data_actions','None','Update a Weigh-In','fa-edit',1,'Inline / Data Row','6_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(18,1,'8_1:15_1','Delete a Weigh-In','delete','standard_delete','None','Delete a Weigh-In','fa-eraser',2,'Inline / Data Row','6_1','Action - Modal','No','No','No',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(19,1,'1_1:2_1','Display Books By Author','display_books_by_author','books_by_author','None','Books By Author','fa-user-plus',3,'Menubar','2_1','Action - Screen',NULL,'No','No',NULL,'Demo of displaying results in multiple separate tables.  More useful when breaking up statistics into different views.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(20,1,'1_1:2_1','Dependents / Charts','dependent','None','None','Dependents Charts','fa-pie-chart',7,'Menubar','7_1','Search - Screen',NULL,'No','No',NULL,'Very simple CRUD tool with NO custom code; meant to demonstrate the simple chart displays (via Chart.JS).  Switch the view mode below to see each type of chart.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(21,1,'8_1:20_1','Create a Dependent','create','standard_data_actions','None','Create a Dependent','fa-plus',1,'Quick Actions','7_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(22,1,'8_1:20_1','Update a Dependent','update','standard_data_actions','None','Update a Dependent','fa-edit',1,'Inline / Data Row','7_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(23,1,'8_1:2_1','View Details','view_details','view_details','None','View Details','fa-search',2,'Inline / Data Row','2_1','Action - Screen',NULL,'No','Yes',NULL,'Quick example of viewing details for a record.','Yes','Yes','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(28,1,'1_1:1_1','OmniTool is an Awesome Web Application Framework!','welcome','present_web_documents','None','Welcome','fa-home',1,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n\n<div class=\"clearfix\">\n	OK, so everyone says that their application platform is awesome, and maybe I\'m biased. \n	What makes this platform so nice? Well, for starters:\n</div>\n\n<div style=\"float: right; margin-left: 10px\" class=\"hidden-480\">\n	<center>\n	<a href=\"https://github.com/ericschernoff/omnitool\" class=\"btn btn-white btn-info btn-lg align-center\"><i class=\"fa fa-github\"></i> View on GitHub</a>\n<br/>\n<a href=\"/#/tools/screencasts\" class=\"btn btn-white btn-info btn-lg align-center\"><i class=\"fa fa-tv\"></i> Jump to Demos</a>\n	</center>\n	<img src=\"https://www.omnitool.org/non_ace_assets/doc_images/screen_shot1.png\"> \n	<br>\n	<img src=\"https://www.omnitool.org/non_ace_assets/doc_images/screen_shot2.png\">\n</div>\n\n<div>\n<p>\n<ul>\n<li>\n	<b><font color=\"#4986e7\">All the UI work is done.</font></b> \n	This system includes a (pretty) complete mobile-responsive UI. \n	Only the most unique apps will require you to write a little bit of HTML \n	and JavaScript, and you might never have to write CSS again. \n</li>\n<li>\n	<font color=\"#4986e7\"><b>You may never write SQL again.</b></font>\n	The core modules handle all the SELECT queries, data modification, and \n	even schema-building. \n</li>\n<li>\n	<b><font color=\"#4986e7\">You only write the code for your specific situation, \n	and many apps will require zero code.</font> </b>\n	Many features are available via options in the Admin UI, and you can make \n	a lot happen with just a little bit of code.  You can make apps as \n	complex and powerful as you like.\n</li>\n<li>\n	<b><font color=\"#4986e7\">Apps and datatypes are set up via web forms, \n	not complex configuration files.</font></b>\n	OK, maybe there are a lot of fields in these forms, but they are well-documented\n	and super-complete.\n</li>\n<li>\n	<b><font color=\"#4986e7\">Every application you create is API-enabled from \n	the start.</font></b>\n	All your features are automatically available to that API. There is no extra \n	work required on your part. In fact, the main Web UI is actually an API client.\n</li>\n<li>\n	<b><font color=\"#4986e7\">Create many private instances of your applications. </font></b>\n	This allows different groups or organizations to use your applications in their own \n	single-tenant databases with their own authorization controls. Your application instances \n	can be run across many database and application servers.\n</li>\n<li>\n	<b><font color=\"#4986e7\">Extensive documentation and examples to get you \n	started. </font></b>\n	This would be even better if it were all proofreadificated, but it\'s not two bad.\n</li>\n<li>\n	<b><font color=\"#4986e7\">Best of all, it\'s written in super-fun Perl! </font></b>\n	Perl 5.22 and higher, in fact. What a wonderful programming language, which you either \n	already love or just can\'t wait to learn, and this fantastic system makes for a wonderful \n	excuse. Don\'t worry, the whole thing isn\'t one big regular expression.\n</li>\n</ul>\n</p>\n<p>\n	OmniTool is meant to save experienced developers a lot of time when building suites of \n	business and resource management tools. I admit that it would need a bit ore UI work (HTML/CSS) \n	to be a great platform for public-facing apps, although this lovely website is built on \n	it.\n</p>\n<p>\n	To see what this is all aboue, please watch my awkward demos on the <a href=\"#/tools/screencasts\">Screencasts</a> \n	page to see this system in action. The <a href=\"#/tools/how_to_install\">Install Guide</a> will reveal the somewhat-easy \n	setup process, and the <a href=\"#/tools/admin_overview\">Admin Overview</a> will get you started with the Admin UI. \n	When you are feeling ready, please check out <a href=\"#/tools/adding_custom_code\">how to add your custom code</a> \n	to start really having fun. \n</p>\n<p>\n	If you have any questions at all, please <a href=\"#/tools/contact_form\">contact me</a>.  All feedback, bugs, and proofreading tips are \n	welcomed.\n</p>\n<p>	\n	FYI, OmniTool is distributed under the MIT license. Enjoy!\n</p>\n\n</div>\n\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(29,1,'1_1:1_1','Our Relatively Easy Installation Process','how_to_install','present_web_documents','None','Install Guide','fa-coffee',6,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nI have developed and run OmniTool on Ubuntu 16.04 and 18.04 servers, and I have\nbeen very happy with the results.  The instructions below are for Ubuntu 18.04, \nbut you are more than welcome to get it to work on FreeBSD, RHEL, CentOS, etc.\nPlease do <a href=\"#/tools/contact_form\">send me your notes to change or extend these instructions.</a>\n</p>\n<p>\nIf you do choose to use an OS other than Ubuntu 16+, please make sure to use Perl 5.24+,\nMySQL 5.7+ (or MariaDB 10.3+) and Apache 2.4+.  (The \'+\' means \'or higher\' in case that\'s\nnot obvious.) \n</p>\n\n<p>\nBecome the superuser to run all the commands below:\n<pre class=\"prettyprint\">\nsudo su -\n</pre>\n</p>\n\n<p>\nI always start with a fresh Ubuntu install on a new VM.  First step is to install\nthe prerequisite packages:\n<pre class=\"prettyprint\">\napt install build-essential zlib1g-dev libssl-dev cpanminus perl-doc mysql-server libmysqlclient-dev apache2 libxml2-dev\n</pre>\n</p>\n\n<p>\nAt this point, please make sure you can connect to the MySQL server that you intend to use via\n\'mysql -uDB_USER -p\' where \'DB_USER\' is probably \'root\' at this point.  \nFor Ubuntu 16.04, you should be able to log in using the password you set above.  However, \nfor Ubuntu 18.04, you\'ll need to \n<pre class=\"prettyprint\">\nmysql_secure_installation\n</pre>\nPlease see <a href=\"https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04\">this article\non Digital Ocean\' and <a href=\"https://stackoverflow.com/questions/37879448/mysql-fails-on-mysql-error-1524-hy000-plugin-auth-socket-is-not-loaded\">this StackOverflow answer.</a>\nI do end up doing \'chown mysql /var/run/mysqld\' as well as \"update user set plugin=\"mysql_native_password\" where User=\'root\';\".\n</p>\n<p>\nIf you want to set up dedicated MySQL user (i.e. not \'root\'), please do that now.\n</p>\n\n<p>\nAlso, while this is NOT a security advice document, please adjust your sshd_config to not permit\nroot logins, to run on a non-standard port, and to allow key-based authentication only, \nchanging these lines:\n<pre class=\"prettyprint\">\nPort SOME_HIGH_PORT_NUMBER\nPermitRootLogin no\nPubkeyAuthentication yes\nPasswordAuthentication no\n</pre>\nMake sure there is not a second \'PermitRootLogin\' line snuck in there.  FYI, OVH.net tacks one on the end\n</p>\n\n<p>\nI like to set up a nice firewall:\n<pre class=\"prettyprint\">\napt install ufw\nufw default allow outgoing\nufw default deny incoming\nufw allow SSHD_PORT_NUMBER_FROM_ABOVE/tcp\nufw allow 80/tcp\nufw allow 443/tcp\nufw enable\n</pre>\nYou might already have \'ufw\' from above.  This only allows in your SSH, HTTP, and HTTPS connections.\nModify as you see fit, especially SSHD_PORT_NUMBER_FROM_ABOVE please ;)\n</p>\n\n<p>\nNext, you will need to enable a few Apache modules:\n<pre class=\"prettyprint\">\n	a2enmod proxy ssl headers proxy_http rewrite\n</pre>\n\n<p>\nNext, use App::cpanminus to install the omnitool::installer module and script, along with all the CPAN modules required to run OmniTool:\n<pre class=\"prettyprint\">\n	cpanm omnitool::installer\n</pre>\nIt\'s possible that the ISBN scraper module for the sample tools may give you a problem, so you might need to run as\n\'cpanm --force omnitool::installer\'\n\n</p>\n\n<p class=\"center\">\n	<a href=\"https://github.com/ericschernoff/omnitool-installer\" class=\"btn btn-white btn-info btn-lg align-center\"><i class=\"fa fa-github\"></i> View the omnitool::installer module on GitHub</a>\n</p>\n\n<p>\nAnd now you have the \'omnitool_installer\' command.  The best and safest way to use this command is to create an installation config file, and then run the installer against that config.  These two steps are:\n<pre class=\"prettyprint\">\nomnitool_installer --save-config-file-only=/some/path/ot_install.config\n\nomnitool_installer --config-file=/some/path/ot_install.config	\n</pre>\n\nPlease update that \'/some/path/ot_install.config\' of course ;)  Please also delete or otherwise protect that file once the installation is done, as it contains plaintext passwords.\n\n</p>\n\n<p>\nOnce that installation completes, it will list out several \'next steps,\' tailored to your enviroment.  Most of these are very simple.  \n</p>\n\n<p>\nTwo notes for the Apache config:\n<ol>\n<li>You likely will need an SSL certificate, and self-signing cert info is here: \n	<a href=\"https://httpd.apache.org/docs/2.4/ssl/ssl_faq.html#selfcert\">https://httpd.apache.org/docs/2.4/ssl/ssl_faq.html#selfcert</a> </li>\n<li>If you are not on Ubtuntu 18.04, you may need to uncomment the \'Listen 443\' directive from /opt/omnitool/configs/omnitool_apache.conf.</li>\n\n</ol>\n</p>\n\n<p>\nIf you have any questions about this, please reach out via the <a href=\"#/tools/contact_form\">Contact Form.</a>\n</p>\n\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(30,1,'1_1:1_1','Action-Packed Video Demos','screencasts','present_web_documents','None','Screencasts','fa-tv',3,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nAs it happens, the type of person who spends his free time writing a Web app framework is usually not very good at creating demo videos, and I am no exception.  Just think, these are the ones I kept!\n</p>\n\n<p>\n<iframe width=\"853\" height=\"480\" src=\"https://www.youtube.com/embed/FLgh5vJ1ZkU?rel=0\" frameborder=\"0\" allowfullscreen></iframe>\n</p>\n<p>\n<iframe width=\"853\" height=\"480\" src=\"https://www.youtube.com/embed/YDsq9vivERQ?rel=0\" frameborder=\"0\" allowfullscreen></iframe>\n</p>\n<p>\n<iframe width=\"853\" height=\"480\" src=\"https://www.youtube.com/embed/qPNDErRBzcc?rel=0\" frameborder=\"0\" allowfullscreen></iframe>\n</p>\n</div>\n','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(31,1,'1_1:1_1','Super-Fun Overview of the Admin UI','admin_overview','present_web_documents','None','Admin Overview','fa-cogs',7,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nDevelopers and admins will use the OmniTool Administration Web UI to build and manage the applications they deliver with this system.  This document is an attempt at a briefish overview of how to get started with the Administration UI.  There are many more notes and pointers embedded in the instructions in all the Admin forms.  Please read those carefully.\n</p>\n<p>\nSome key points to start off:\n<ul>\n<li>Let\'s just call it \'OT Admin\' for the rest of this document, shall we?</li>\n<li>Your end users will not see the OT Admin apps.  They will only see the web apps you build and authorize for them.</li>\n<li>To make things less confusing, the UI for the OT Admin apps has a different color scheme than for your end-user-facing applications.</li>\n<li>OT Admin is itself a web application built on OmniTool, so it will act a lot like the apps you build. In particular, the OT Admin app has multiple instances that control multiple admin databases.</li>\n<li>Please build your applications in the OT Admin instance which is named for your domain (i.e. mine is called \'OmniTool.Org Admin\').  This will be available at https://your.otdomain.ext/apps_admin</li>\n</ul>\n</p>\n<p>\nThe components of an OmniTool web app include:\n<ul>\n<li>Datatype: A Model configuration which represents a database table and is brought to life by OmniClass.  </li>\n<li>Tool:  A Controller configuration which represents a Web screen and/or an API entry point, and generally allows the end users to interact with the Datatypes.  Brought to life by Tool.pm.  There are two kinds of Tools:  \'Searching\' Tools are for searching and displaying records, and \'Action\' Tools allow you to operate on or with a specific record (or take any action, really).</li>\n<li>Jemplate and JavaScript Class:  The client-side code which provides the View for the Web UI. Assigned to the Tools via OT Admin, and built in your favorite text editor.</li>\n<li>Application  The combination of Datatypes and Tools and Templates to make a useful system.  Can have as few as one of each component or many hundreds of all of the components.  </li>\n<li>Application Instance:  A presentation of an Application, including resource allocation.  Represents the assignment of a URI and a MySQL database which will be used to host the application.  This allows each Instance to be hosted on a separate server and have its own exclusive database (or share one or another).</li>\n</ul>\n</p>\n\n<p>\nWith that in mind, here are the basic steps to setting up your first Application with a Datatype and some Tools:\n<ol>\n<li>Log into your domain\'s OT Admin instance at https://your.otdomain.ext/apps_admin  .  The OmniTool Administration tool will load by default.  It is also the top link in the left sidebar.  </li>\n<br/>\n<li>Click on the \'Create an App\' button in the upper-left of the main area.  Follow the instructions very carefully on that form.  You can take the defaults for most of those fields, and especially the \'App-Wide\' fields are for once your application is more developed.</li>\n<br/>\n<li>Once you submit the form, you will see your new application listed on the main screen. Please click \'Manage Instances\' in its \'Actions\' menu, and then click \'Create Instance\'.  For now, please pay particular attention to the first half of the form, down to \'MySQL Database Name\'.  </li>\n<br/>\n<li>After you submit that form, please click on \'MySQL Tables\' next to your new instance, and then click on the \'Create Database\' button on that screen.  </li>\n<br/>\n<li>Click on the lock icon on the left to load the \'Manage Access Roles\' tool.  Click \'Create Role,\' and make sure to provide an Access Role Name, and select your new Application for \'Used in Applications.\'</li>\n<br/>\n<li>Click on the people icon (second one from top) to load the \'Manage Users\' tool, and select \'Create a User\' under the \'Quick Actions\' menu.  Please fill in all four fields, and be sure to set the \'Hard-Set Access Roles\' to your new Access Role.</li>\n<br/>\n<li>Next, please click \'OT Admin\' in the sidebar.  Click on \'Manage Datatypes\' next to your new Application and on the next screen, select \'Create a Datatype\' from the \'Quick Actions\' menu.</li>\n<br/>\n<li>The first two fields are the most important in the \'Create a Datatype\' form.  Pretty please name your datatype in singular form and the MySQL table in plural form, i.e. \'Song\' and \'songs\'.  Please do read all the instructions on this form.</li>\n<br/>\n<li>After you submit that form, please select \'Manage DT Fields\' next to your new Datatype, and then click the \'Create DT Button\' on that new screen.</li>\n<br/>\n<li>Don\'t be shocked, but I am asking you to read the form instructions very carefully.  The key fields are \'Datatype Field Name,\' \'Field Type,\' and \'MySQL Table Column.\'  </li>\n<br/>\n<li>Repeat using the \'Create DT Button\' to create all the Datatype Fields that you will need.  Don\'t worry about \'Display Priority\' while creating these fields, because of the next step.</li>\n<br/>\n<li>In the gray breadcrumbs area above, please click on \'Manage Datatypes (Your App Name)\'.  Next to your new datatype, please select \'Order Fields\'.  Please use that little form to sort your fields.</li>\n<br/>\n<li>Select \'Flush DT Hash\' from the \'Quick Actions\' menu.</li>\n<br/>\n<li>Once again, please click on \'OT Admin,\' and click on \'Manage Tools\' next your new application.</li>\n<br/>\n<li>Click on \'One-Click CRUD\' under \'Quick Actions.\'</li>\n<br/>\n<li>Please select your new datatype, then select a few fields to display.  Maybe add the Delete tool to the \'Sub-Tools to Create.\'  Please select the Access Role you created above.</li>\n<br/>\n<li>Click on \'OT Admin\' above, then select \'Manage Instances\' next to your Application.  Click on the second link under \'Instance Link\'.  This will load your new Application Instance!</li>\n</ol>\n</p>\n<p>\nSo now, you probably see the no-access screen  This is likely because you are logged in as \'omnitool_admin\'.  You could go back and create an \'omnitool_admin\' user, assigned to your new Access Role.  If you do that, use the \'Flush User Sessions\' tool under \'Quick Actions\' in Manage Users to flush your omnitool_admin session. Alternatively, you can use the \'Sign Out\' link under your name in the upper-right, and then log in as the new user.  Another option is to load the instance in another browser, so you can stay logged-in as \'omnitool_admin\' in your main browser.\n</p>\n<p>\nI know that seemed like a lot of steps.  It gets faster the more you do it ;)\n</p>\n<p>\nNow you have a basic set of Tools, which you can customize to a great deal.  Please explore all the options under \'Manage Tools\' to customize these Tools, starting with the top Tool.  Tools are organized hierarchically, so you can browse into them by clicking on their name.  You can accomplish a good deal with just the Manage Tools forms, particularly via the \'Tool View Modes\' features.  Your Tools can have as many View Modes as you like. \n</p>\n<p>\nTo \"publish\" changes to your Tools, click on \'Flush Sessions\' next to any Tool under Manage Tools.  To publish Datatype changes, use \'Flush DT Hash\' under Manage Datatypes.\n</p>\n<p>\nYou do not have to use \'One-Click CRUD\' every time you create a new Tool.  It is great if you are making a Search-Create-Edit set of Tools, but if you have a standalone Tool, there is a \'Create a Tool\' link under \'Quick Actions\' at every level of \'Manage Tools\'. If you want to create a new Tool at the top level of an application, please there is a \'Create Tool\' button in the Application\'s \'Actions\'  menu.  Every new Tool will need at least one View Mode configured under \'Tool View Modes.\'\n</p>\n<p>\nRegarding Application Instances and their hostnames, you will need to assign both a Cross-Hostname URI and a Hostname to the Application.  The Cross-Hostname URI will  be the \'base path\' for the Application Instance on your web server, so that:\n</p>\n<p style=\"margin-left: 50px\">\n	https://www.your-ot-server.com/dogs\n	<br/>https://www.your-ot-server.com/cats\n	<br/>https://www.your-ot-server.com/fish\n</p>\n<p>\nCan be three separate Instances of a \"Pet\" Application.  This requires you to only buy one regular SSL certificate, and it can be easier for your DevOps team (or so they tell me.)  Alternatively, you could allow access via separate hostnames:\n</p>\n<p style=\"margin-left: 50px\">\n	https://dogs.your-ot-server.com\n	<br/>https://cats.your-ot-server.com\n	<br/>https://fish.your-ot-server.com\n</p>\n<p>\nYou would need to set up the hostnames or a wildcard hostname in Apache.  The hostnames do not have to share a domain name, but a wildcard SSL cert is a lot more affordable than one certificate per domain.\n</p>\n<p>\nThe hostname option is best for hosting on several web servers.  (Yes, you could also configure Apache for each hostname to go to a separate Plack server based on the base URI, and that would be going the extra mile.)\n</p>\n<p>\nRegarding users and authorization, you will almost certainly want users to have different access rights between different Application Instances.  If you have 100 users or less, then manually managing the OmniTool Users and their assigned Access Roles can be practical.  However, it is much better to use the \'auth_helper.pm\' module to use an external service for authentication, and custom logic for membership in Access Roles.  Let\'s discuss that in the next doc, \"Add Custom Perl Packages and Take Flight\".\n</p>\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(32,1,'1_1:1_1','Project Info and Acknowledgements','project_info','present_web_documents','None','Project Info','fa-legal',5,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nI hope that you can find this project useful in some way.  It would be fantastic for you to build a masterpiece on\ntop of this system, but even if some small bit of the code provides you an idea or a working example, \nthat would be really great too.  \n</p>\n\n<p class=\"h3\">\nGetting Involved and To-Do\'s\n</p>\n<p>\nIf you find this project useful or interesting, please get involved!  It would be fantastic to\nhave more developers involved, but all types of help and feedback is appreciated.  \nPlease <a href=\"#/tools/contact_form\">contact me</a> to get started.  Some particular to-do\nitems are:\n<ul>\n	<li>Developing additional UI skeletons for diferent types of apps.</li>\n	<li>Developing more Jemplate templates for Tools Views</li>\n	<li>Installation instructions and testing for FreeBSD, Fedora, RHEL, and others</li>\n	<li>Documentation improvement and proofreading</li>\n</ul>\n</p>\n\n<p class=\"h3\">\nAcknowledgements\n</p>\n<p>\nI am very appreciative to my employer, Cisco Systems, Inc., for allowing this software to be released to\nthe community as open source. (IP Central ID: 153330984).\n</p>\n<p>\nMany thanks to Mohsen Hosseini for allowing me to include his most excellent Ace Admin Bootstrap template as part\nof this software.  His excellent work builds on the also-great jQuery and Bootstrap libraries.\n</p>\n<p>\nThis software depends on many terrific CPAN modules, some of which are listed below.  Of particular note\nis the most excellent <a href=\"http://www.jemplate.net/\">Jemplate</a> module, which allows you to use\nTemplate Toolkit in JavaScript.  Fantastic! Really an elegant solution to front-end templating.\n</p>\n<p>\nThank you to my wife and friends for listening to me babble on about the various incarnations of OmniTool since 2001.  \n</p>\n\n<p class=\"h3\">\n	Key Technologies\n</p>\n\n<p>\nHere are some of the key technologies supporting OmniTool, linked to their documentation:\n<ul>\n	<li><a href=\"https://perldoc.perl.org/\">Perl 5.22 (or 5.24)</a></li>\n	<li><a href=\"http://www.template-toolkit.org/docs/index.html\">Template Toolkit 2.26</a></li>\n	<li><a href=\"http://www.jemplate.net/\">Jemplate 0.30</a></li>\n	<li><a href=\"http://plackperl.org/\">Plack 1.0044</a></li>\n	<li><a href=\"http://dbi.perl.org/docs/\">DBI 1.636</a></li>\n	<li><a href=\"http://search.cpan.org/~drolsky/DateTime-1.43/lib/DateTime.pm\">DateTime 1.43</a></li>\n	<li><a href=\"http://getbootstrap.com/components/\">Bootstrap 3.3.5</a></li>\n	<li><a href=\"http://api.jquery.com/\">jQuery 2.1.4</a></li>\n	<li><a href=\"https://dev.mysql.com/doc/refman/5.7/en/\">MySQL 5.7</a></li>\n	<li><a href=\"http://httpd.apache.org/docs/2.4/\">Apache 2.4</a></li>\n</ul>\n</p>\n\n<p class=\"h3\">\nLicense\n</p>\n<p>\nMIT License\n<br/><br/>\nCopyright (c) 2017 Eric Chernoff\n<br/><br/>\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n<br/><br/>\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n<br/><br/>\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n</p>\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(33,1,'1_1:1_1','Contact Form','contact_form','contact_form','None','Contact Form','fa-phone',4,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,NULL,'No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(34,1,'8_1:20_1','View Details','view_details','view_details','None','View Details','fa-search',1,'Inline / Data Row','7_1','Action - Screen',NULL,'No','Yes',NULL,'Example of a basic view details screen using the default get_basic_details_hash() routines rather than a custom view_details() OmniClass method.','Yes','Yes','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(35,1,'1_1:1_1','Add Custom Code and Take Flight','adding_custom_code','present_web_documents','None','Add Custom Code','fa-plane',8,'Menubar','1_1','Action - Screen',NULL,'No','No','43_1','<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nSorry-not-sorry for the dramatic title.  You will un-lock a lot of very cool features with just a little bit of custom code.  Hopefully, this system helps to keep your coding to a minimum (once you get the hang of it).\n</p>\n\n<p>\nThe pages under this section will hopefully give you enough information to get started.  If you run into any questions, please <a href=\"#/tools/contact_form\">feel free to contact me.</a>\n</p>\n\n<ol>\n<li>\n	<a href=\"#/tools/adding_custom_code/custom_perl_modules\">How to Write Custom Perl Modules (and Be a Hero!)</a>\n</li>\n<br/>\n<li>\n	<a href=\"#/tools/adding_custom_code/ui_tool_views\">UI Development: Tool View Modes are the Real Fun!</a>\n</li>\n<br/>\n<li>\n	<a href=\"#/tools/adding_custom_code/ui_javascript\">UI Development: Adding JavaScript to the Mix</a>\n</li>\n<br/>\n<li>\n	<a href=\"#/tools/adding_custom_code/view_documentation\">Very Thrilling Perl Module Documentation</a>\n</li>\n</ol>\n\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(36,1,'8_1:35_1','UI Development: Tool View Modes are the Real Fun!','ui_tool_views','present_web_documents','None','UI: Tool View Modes','fa-html5',2,'Menubar','1_1','Action - Screen',NULL,'No','No','44_1','<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nThe main opportunity to do UI development in OmniTool is create Tool View Modes.  These define how the results data for your Tool will be display in the main portion of the screen.  For this doc, let\'s call them \'View Modes.\'\n</p>\n<p>\nThere are several options for configuring your View Modes, but the bottom line is that a View Mode represents the use of a Jemplate template for the Tool.  The Jemplate JavaScript library allows you to use Template-Toolkit templates in the web browser as front-end templates.  Please see\n<a href=\"http://www.jemplate.net/\">http://www.jemplate.net/</a> and <a href=\"http://www.template-toolkit.org/docs/index.html\">http://www.template-toolkit.org/docs/index.html</a> for more on these technologies.\n</p>\n<p>\nYou can create and manage View Modes by navigating to \'Manage Tools\' in OT Admin, and selecting \'Tool View Modes\' next to the target Tool.  Please check out the instructions in the create/update form for View Modes, but key fields are \'Name,\' \'Mode Type\', and \'Display Priority\'.  With these, you can use one of the prebuilt Jemplates for your View Mode with no special coding.  The other key field is \"Fields to Include,\" which tells Searching Tools which Datatype Fields to send to the Jemplate.\n</p>\n<p>\nOne great aspect of View Modes is that each Tool can be assigned multiple View Modes.  This allows your Tools to be used in different ways by different people.  For example, a Searching Tool may have several View Modes all using the Table Jemplate, but each one may have different \'Fields to Include\" selected.  This allows you to satisfy your pickiest user\'s requests without subjecting the other users to their specialized View Modes.\n</p>\n<p>\nYou can easily include basic charts for your Search Tools.  To do so, order the \'Fields to Display\' so that the X-Axis (label) field is first, and Y-Axis (value) is second.  You can include any other fields after those, but they are not included in the chart.  Then select a chart type for \'Display a Chart.\'  This is good for very basic charting, but you can program as advanced a chart as you like; please see the \"Display Charts for Search Results\" section of the Perl Module docs for omnitool::tool.  Charting uses ChartJS.\n</p>\n<p>\nSome other advanced features of View Modes:\n<ul>\n<li>You can have a JavaScript function called after your View Mode is loaded.  This allows you to add any UI feature you like to your View Mode.  This is discussed more in the \"UI Development: Adding JavaScript\" page.</li>\n<br/>\n<li>You can restrict access to specific View Modes.  For example, you may allow all users with access to a Tool see the Table View Mode, but only admins should see the JSONShow View Mode.</li>\n<br/>\n<li>You can define a \'Single-Record Jemplate Block\'.  The Table and WidgetsV3 prebuilt Jemplates already support this feature.  With this, if you open a message or modal Inline Tool on a specific data record, then only that record will be reloaded when the message or modal closes.  This reduces screen refreshes for the most active Tools.</li>\n</ul>\n</p>\n<p>\nBelow are the list of prebuilt Jemplates, in order from most-used/simplest to least-used/most-complex:\n</p>\n<p style=\"margin-left: 20px\">\n<u>Table</u>\n<br/>This is the go-to way to display results for Searching Tools in a good old-fashioned table.  You can use \'make_data_table\' in the \'Run JS Function on Load\' to make it into a DataTables table.\n<br/><br/>\n\n<u>ScreenForm</u>\n<br/>This is the go-to form display method.  Meant for forms that are in the main content area.  Solid vertical Bootstrap form layout.  With this and the Table Jemplate, you can handle most of your CRUD functions.\n<br/><br/>\n\n<u>WidgetsV3</u>\n<br/>This is also for Searching Tools.  It shows wide widgets, and is very good if you are showing long text for longer virtual fields.\n<br/><br/>\n\n<u>Complex_Details</u>\n<br/>Allows you to display full details for a record.  With a custom \'view_details\' method for your OmniClass Package, you can have multiple tabs showing simple details, long text, searchable tables, and a nice activity log.\n<br/><br/>\n\n<u>Complex_Details_Printable</u>\n<br/>Version of Complex_Details without tabs, meant for printing.\n<br/><br/>\n\n<u>ScreenForm_DisplayInstructions</u>\n<br/>Version of ScreenForm which displays the fields\' instructions below the fields, rather than hidden behind popover question-marks.  Useful if you really want people to read your instructions (OT Admin).\n<br/><br/>\n\n<u>ScreenForm_TwoColumn</u>\n<br/>Version of ScreenForm that displays the form in two-columns.  Sometimes takes adjusting your form\'s field order to get it to work right.\n<br/><br/>\n\n<u>ModalForm</u>\n<br/>This allows you to display forms in a modal.  Useful for shorter (1-4 field) forms.\n<br/><br/>\n\n<u>MessageModal</u>\n<br/>Used to display some simple text inside a modal, as well as presenting \'Are You Sure?\' confirmation boxes.\n<br/><br/>\n\n<u>Results_SearchForm</u>\n<br/>Used to have a simple search form that displays results below.  Not for Searching Tools that search OmniClass data records, but more for Action Tools that take a keyword and do some calculations or search external resources.\n<br/><br/>\n\n<u>Results_SearchForm_MultiTables</u>\n<br/>Similar to Results_SearchForm, but allows you to show separate tables, broken up by some data point.  See the \'Books by Author\' sample tool.\n<br/><br/>\n\n<u>Results_SearchForm_MultiTables_Horizantial</u>\n<br/>Version of Results_SearchForm_MultiTables that puts the search form across the top and opens up more horizontal space.\n<br/><br/>\n\n<u>Results_Modal</u>\n<br/>Displays a results table in a modal.  No searching; meant for Inline Tools that find data underneath a particular record.\n<br/><br/>\n\n<u>Paragraphs_Plus_a_Link_Modal</u>\n<br/>Displays separate paragraphs, followed by a link, in a modal form.\n<br/><br/>\n\n<u>JustHTML</u>\n<br/>Used if you are sending out a glob of HTML.  Used for this website, but not recommended for real Applications.\n<br/><br/>\n\n<u>Complex_Details_Plus_Form</u>\n<br/>Allows you to display a form to update or interact with an OmniClass record while also displaying the full details of that record in a second table.  Example use is for an \'update support case\' Tool where you are posting a case update but also need the case details at your fingertips.\n<br/><br/>\n\n<u>FormToDetails</u>\n<br/>Allows you to display a form, and upon submission, display details of the affected OmniClass record(s).  Example would be submitting an restaurant order and then seeing a confirmation of the order details.\n<br/><br/>\n\n<u>JSONShow</u>\n<br/>Displays the JSON data sent by the Tool.  Very useful for debugging.\n<br/><br/>\n\n<u>JSONSearchForm</u>\n<br/>Similar to Results_SearchForm, except the results are shown as JSON.  Useful for developing and troubleshooting API-specific Tools.\n<br/><br/>\n\n<u>Calendar</u>\nUsed for Searching Tools to show events.  Order the \'Fields to Display\' options so the text-to-display is first, followed by the event date.  Use \'start_calendar\' in \'Run JS Function on Load\'.\n<br/><br/>\n\n<u>MessageView</u>\n<br/>Display simple messages with titles in the main screen.\n<br/><br/>\n\n<u>Widgets / WidgetsV2 / Widgets_Directory</u>\n<br/>These are Jemplates to display results form Searching Tools.  They are less exciting that WidgetsV3.tt but also simpler.  Widgets_Directory is good for displaying a photo or icon with each record.\n<br/><br/>\n\n<u>BasicDetails / BasicDetailsModal</u>\n<br/>Very basic display of details.  Replaced by Complex_Details.  Likely to be removed in future versions.\n<br/><br/>\n\n<u>Spreadsheet_FormV1</u>\n<br/>The first view for batch-entry forms that made me happy.  Allows you to display multiple horizontal forms on one screen.  Requires a custom Tool.pm sub-class to work.\n<br/><br/>\n\n<u>Complex_Details_Plus_SpreadsheetForm</u>\n<br/>Combination of Spreadsheet_FormV1 and Complex_Details_Plus_Form.  Example might be an employee timecard where details for the employee are also displayed.\n<br/><br/>\n\n<u>Complex_Details_Plus_SubRecords</u>\n<br/>Very wild template where you can embed WidgetV3.tt display of sub-records under a tab.  Requires a fair amount of custom coding.\n<br/><br/>\n\n<u>Network_Diagram</u>\n<br/>Jemplate that allows for network diagram editing.  Network diagrams can be embedded in Complex Details.  This part is somewhat alpha, and I will include instructions in a future release.\n</p>\n<p>\nI have found that these Jemplates cover 90% of <u>my</u> requirements.  The other 10% of Tools are more unique, and so you are able to write a custom Jemplate.  Just create that new Jemplate, save it to \'code/omnitool/applications/your_app_code_dir/jemplates\', then select \'Custom\' for the \'Mode Type,\' and then enter the file name for the \'Custom Template\' field, and value for \'Custom Type Name\'.\n</p>\n<p>\nUse the prebuilt Jemplate as examples when creating your Jemplate.  Keep in mind:\n<ul>\n<li>The Jemplates actually get processed twice.  You are writing a Template-Toolkit template that will be processed on the server to be sent out as a Jemplate to be processed on the client.  You can use [* *] tags to put in logic for the server-side, and [% %] tags for the client side.</li>\n<br/>\n<li>Many Tool-specific Jemplates will only have client-side tags, but when you want multiple Tools to share a Jemplate, the server-side stuff comes in handy.</li>\n<br/>\n<li>Searching Tools are very different from Action Tools.  I recommend using the JSONShow Tool View Mode on your Tool to see what kind of JSON structure it sends, and the Developer Tools feature for your browser to look at similar Tools.</li>\n</ul>\n</p>\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(37,1,'8_1:35_1','UI Development: Adding JavaScript to the Mix','ui_javascript','present_web_documents','None','UI: JavaScript','fa-jsfiddle',3,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nYou can add JavaScript functions to your Tool View Modes and enable all sorts of great UI features.  There are several handy JS functions bundled with the UI, and you are definitely able to add in your own.\n</p>\n<p>\nSave your custom JavaScript class/script files to \'code/omnitool/applications/your_app_code_directory/javascript\'. Then you can associate a JS file with one of your the Tools using the \'JavaScript Class\' drop-down in the Tool create/update form in Manage Tools.  Note:  If a JavaScript Class is associated with one Tool, it\'s functions are available to all the other Tools in the same Application.\n</p>\n<p>\nYou can invoke your custom JS functions one of two ways:\n</p>\n<p>\n<ol>\n<li>Most common:  Enter the function name in the \"Run JS Function on Load\" field when creating or updating a Tool View Mode.  Only provide the name; it will automatically receive the active Tool\'s \'tool_id\' as an argument.  This allows easy access to the active Tool\'s JS object, discussed below.</li>\n<br/>\n<li>You can add buttons and links with onClick events in your custom Tool View Mode Jemplate.  Your buttons can access functions in the UI\'s core JavaScript as well as JavaScript you provide.  You can pass any arguments you wish, and I would recommend passing the tool_id parameter, which you can reference as [%the_tool_id%] in the Jemplate.</li>\n</ol>\n</p>\n<p>\nThe OmniTool UI comes with its own JavaScript framework in the \'omnitool_routines.js\' and \'omnitool_toolobj.js\' files under code/omnitool/static_files/javascript .\n</p>\n<p class=\"h4\">omnitool_routines.js</p>\n<p>\nThe \'omnitool_routines.js\' file is the primary traffic director for the UI.  It handles initiation of the UI on page load, and it responds with omnitool_controller() when the location hash changes.  (Oh, did I mention this whole thing is a single page application? You probably already noticed.)  You will not need to interact with many of the functions in this file, but several may be useful:\n<br/>\n<ul>\n<li>jemplate_binding\n<br/>This is a rich JS object that you can use to bind DIV\'s to Jemplates and render them on demand.  To create this object, pass the ID of the DIV which will display the rendered Jemplate, then the URI to retrieve the Jemplate (often under \'/ui/\'), then a unique name for the Jemplate, and then a URI for the JSON data to use processing that Jemplate.  If you set that last URI to \'none,\' then the object will be created, and will not try to render the Jemplate.\n<br/><br/>\nWe store jemplate_binding objects in the global \'jemplate_bindings\' associative array for portability and reuse.\n<br/><br/>\nExample object creation:\n<pre class=\"prettyprint\">\njemplate_bindings[\'my_jemplate\'] = new jemplate_binding(\'target_div_id\', \'/ui/some_jemplate\', \'jemplate_name.tt\', \'/tool/some_tols_uri/special_method_for_json\');\n</pre>\nNow you can use the following methods for that object:\n<br/><br/>\n<ul style=\"margin-left: 20px\">\n<li>process_json_uri\n<br/>This method will load / re-load the JSON via the \'json_data_uri\' attribute (fourth arg in \'new\' call), and then render the Jemplate.  If you set that fourth argument to \'none,\' then you will need to set a valid \'json_data_uri\' attribute before calling this.\n<br/>\n<pre class=\"prettyprint\">\njemplate_bindings[\'my_jemplate\'].json_data_uri = \'/tool/some_tool_uri/json_producing_method\'; // only if \'none\' before.\njemplate_bindings[\'my_jemplate\'].process_json_uri();\n</pre>\n\n</li>\n<br/>\n<li>process_json_data\n<br/>This method will accept a data object and render the loaded Jemplate against it.  So you can use this without changing a \'none\' json_data_uri, since no callback is made to the server.\n<br/>\n<pre class=\"prettyprint\">\njemplate_bindings[\'my_jemplate\'].process_json_data(data);\n</pre>\n</li>\n\n<li>process_any_div\nOne utility feature we have is the jemplate_bindings[\'process_any_div\'] object.  This allows you to apply a block from any loaded Jemplate to any DIV you like.  This is meant for retrieving special JSON data that gets loaded into smaller DIV\'s.  Usually, your Tool View Mode\'s Jemplate would have the BLOCK that you would use with this feature.\n<br/><br/>\nLet\'s say you have your JSON data loaded into the creatively-named \'json_data\' var.  You can use this \'process_any_div\' feature like so:\n<pre class=\"prettyprint\">\n// set the Jemplate BLOCK to use\njson_data.block_name = \'Some Block Name\';\n// set the target DIV\njemplate_bindings[\'process_any_div\'].element_id = \'#target_div_id\';\n// process that DIV with our BLOCK and data\njemplate_bindings[\'process_any_div\'].process_json_data(json_data);\n</pre>\n</ul>\n</li>\n</ul>\n</p>\n\n<p>\nOther useful functions from omnitool_rountines.js include:\n\n<br/>\n<ul>\n<li>query_tool\n<br/>This is the ONLY way you should send direct requests back to the OmniTool server.  Yes, you can use the other request-making Tool methods described below, but those make use of this query_tool function.  This function accepts an OmniTool URI plus a key-value object for the POST parameters to send.  It adds all the necessary bits to send the request properly.  Because of the asynchronous nature of JS, it returns a promise for a response, and since you want to process that response, the example is:\n<pre class=\"prettyprint\">\n$.when( query_tool(\'/tool/some_tools_uri/special_method\', { best_dog: ginger } ) ).done(function(data) {\n	// do something with data here.\n});\n</pre>\n</li>\n<br/>\n\n<li>show_or_hide_element\n<br/>This will show or hide any element.  Just pass in the element\'s ID to hide it; if you wish to show the element, pass in the element\'s ID plus some HTML content.\n<pre class=\"prettyprint\">\nshow_or_hide_elment(some_div_id, some_html); // will show a div with the sent HTML\n</pre>\n</li>\n<br/>\n\n<li>open_system_modal\n<br/>This will open a modal using the system_modals.tt Jemplate.  Pass in a suitable data object.  Example:\n<pre class=\"prettyprint\">\nopen_system_modal({\n	modal_title_icon: \'fa-fontawesome-icon\',\n	modal_title:  \'Title For Modal\',\n	simple_message: \'some html text here\'.\n});\n</pre>\n<br/>Please see the mark up in system_modals.tt for all that you can put into the object for open_system_modal().\n</li>\n<br/>\n\n<li>create_gritter_notice\n<br/>This will create a pop-over message to the upper-right of the screen.  Requires a data object with at least a \'title\' value.\n<pre class=\"prettyprint\">\ncreate_gritter_notice({\n	title: \'Message Title\',\n	message: \'Message text here\',\n	error_message:\'Error message text here\',\n	is_sticky: true, // if set to true, the gritter message will not auto-close\n	time: milliseconds, // if blank, defaults to 10000, aka 10 seconds.\n});\n</pre>\n</li>\n\n<br/>\n<li>interactive_form_elements\n<br/>This empowers the fields and submission of a just-displayed form.  This should be used anytime a form is loaded.  If your Tool View Mode calls a Jemplate with \'Form\' in the name, this function is run by default. However, if you specify a separate \'Run JS Function on Load\', and there is a displayed form, than your custom function needs to call interactive_form_elements(tool_id).  You also sometimes need to call this after modifying a form.\n</li>\n<br/>\n\n<li>make_data_table / make_data_table_no_export_buttons\n<br/>These functions will take regular tables and convert them into DataTables.  Please see <a href=\"https://www.datatables.net/\">https://www.datatables.net/</a> .  Be sure to pass the \'tool_id\' argument for either.  The \'no_export_buttons\' version prevents the Excel/CSV export buttons.\n</li>\n<br/>\n\n<li>form_plus_data_table / form_plus_data_tables\nThese run both interactive_form_elements(tool_id) and make_data_table(tool_id).  They should be used in combination with Complex_Details_Plus_Form.tt\n</li>\n<br/>\n\n<li>complex_tabs_with_diagram / interactive_form_plus_diagram\n<br/>These are used when one of your complex details tabs is a network diagram.  They work OK for me, but I am not ready to really sell you on this one.  Because the rest of this system is so perfect in comparison.\n</li>\n</ul>\n</p>\n\n<p class=\"h4\">omnitool_toolobj.js</p>\n<p>\nThe \'omnitool_toolobj.js\' file provides the Tool class, which is the client-side of Tool.pm.  The omnitool_controller() function creates / loads the Tool objects when the hash changes, and those new objects load up all the needed bits for the Tool to be displayed.\n</p>\n<p>\nGenerally, you do not need to worry about the loading / hiding of Tools in the UI.  However, you may want to call some of the methods for a currently-active Tool.\n</p>\n<p>\nAs Tool objects are created, they are kept in the global associative array named \'tool_objects,\' keyed by the \'tool_id; value. That value is included as \'the_tool_id\' in results from \'send_json_data.\'  There is another global associative array named \'the_active_tool_ids,\' which will have a a key for \'modal\' and for \'screen\'.  So if you know your Tool is definitely a screen, your custom JavaScript functions should be able to run Tool methods like so:\n<pre class=\"prettyprint\">\nvar my_tool_id = the_active_tool_ids[\'screen\'];\ntool_objects[my_tool_id].some_function_name();\n</pre>\n</p>\n<p>\nThese methods include:\n<ul>\n<li>refresh_json_data\nCalls back to the \'send_json_data\' URI for the Tool and re-renders the current Jemplate with the new data.  \"Refreshes the display\" is what I should have said.  No arguments required.\n<pre class=\"prettyprint\">\ntool_objects[my_tool_id].refresh_json_data();\n</pre>\n\n<li>auto_complete_fields\n<br/>Empowers the auto-suggesting of auto-complete fields.  Requires the name of the server-side method to run plus the jQuery object for the field.  That server-side method should return an array of suggestions.\n<pre class=\"prettyprint\">\ntool_objects[my_tool_id].auto_complete_fields(\'auto_suggest_method\',$(\'#some_field\'));\n</pre>\n</li>\n<br/>\n\n<li>tag_auto_complete_fields\n<br/>Empowers auto-suggesting \'tag\' auto-completes the same way auto-complete fields work.  I sometimes use these tags, but I kind hate them.  They are like obnoxious multi-selects.\n</li>\n<br/>\n\n<li>trigger_menu\n<br/>Allows for a selection in one single-select menu to drive population of the options for another menu.  Called from an \'onChange\' attribute from the \'source\' single-select.  Calls back to the server for the options, so you\'ll need a custom method in your Tool.pm sub-class for this.\n<pre class=\"prettyprint\">\ntool_objects[my_tool_id].trigger_menu(\'target_menu_id\',selected_value_in_source_menu,\'server_side_method_name\');\n</pre>\n</li>\n<br/>\n\n<li>process_action_uri\n<br/>Simple function to send GET commands to the server and reprocess the active Jemplate with the resulting data. Useful for when you want to commit an action, but not update the jemplate binding URI.  This expects the server to send back the complete JSON for a Tool, plus a \'message\' value indicating the results of the action.\n<pre class=\"prettyprint\">\ntool_objects[my_tool_id].process_action_uri(action_uri);\n</pre>\n</li>\n<br/>\n	\n<li>fetch_uploaded_file\n<br/>Simple function to invoke the \'send_file\' Tool.pm method to cause a download of a file attached to an OmniClass record.  If the target record\'s Datatype has only one \'file\' field defined, you only need to send the \"altcode\" for the target record.  (This is most of the time.)\n<pre class=\"prettyprint\">\ntool_objects[my_tool_id].fetch_uploaded_file(\'some_data_altcode\');\n\ntool_objects[my_tool_id].fetch_uploaded_file(\'some_data_altcode\',\'specific_field_db_column\');\n</pre>\n</li>\n</ul>\n</p>\n</div>\n','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(38,1,'8_1:35_1','How to Write Custom Perl Modules (and Be a Hero!)','custom_perl_modules','present_web_documents','None','Custom Perl Modules','fa-code',1,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nThis page will go over the types of Perl classes you can create, and how to get started.  There are much more detailed coding instructions in the <a href=\"#/tools/adding_custom_code/view_documentation\">Perl Module Documentation</a>. Once you install, please do check out the examples under omnitool::applications::sample_tools.\n</p>\n<p>\nThis is probably a good time to say that custom code should be saved under the \'code/omnitool/applications\' directory, below the root directory you chose for OmniTool.  The \'system\' code is under \'distribution/omnitool\' with strategic symlinks to \'code/omnitool\'.  You should have your git repo start under \'code/omnitool/applications\'.\n</p>\n<p>\nThere are four general types of custom Perl classes you can create:\n<p>\n<b>1. OmniClass Packages</b>\n</p>\n<p>\nOmniClass Packages are all sub-classes to the main OmniClass module.  These allow you to set up:\n<ul style=\"margin-left 50px\">\n<li>Virtual fields for richer data display.</li>\n<li>Custom hooks to modify the processes for loading and saving data.</li>\n<li>Routines to provide custom options for your single-select and multi-select menus</li>\n<li>Routines to provide auto-suggest lists for your auto-complete/suggest text fields.</li>\n<li>Routines for background tasks.</li>\n<li>Routines for processing incoming emails.</li>\n<li>Methods to do anything you like with or to the records for that Datatype.</li>\n</ul>\n</p>\n<p>\nThat last one is a bit open-ended.  These OmniClass Packages represent your data and will be the primary actors in your apps.  In addition to all the standard actions that OmniClass provides, your key Datatypes will need their own capabilities, to be called from the Tools.pm sub-classes (next topic).\n</p>\n<p>\nFor instance, if you have an OmniClass Package named Dogs.pm for the \'Dog\' Datatype, it may include pre_save() and post_save(), but it will likely also include methods named bark() and go_for_a_walk().  The DogOwners.pm OmniClass Package would have methods named feed_the_dogs() and clean_up_the_foyer_for_the_thousandth_time().\n</p>\n<p>\nTo create an OmniClass Package, please navigate to OT Admin, then select \'Manage Datatypes\' for your Application, then select \'Get Package\' for the target Datatype.  A modal will appear, and then please click the link for \'Generate OmniClass Package for \"XYZ\" Datatype\' to view the starter code.  Please copy and paste it into an appropriately-named module under \'omnitool::applications::YOUR_APP_DIRECTORY::datatypes\'.  The generated code will include the needed skeleton, plus examples for all the standard types of methods in a docs section under \"__END__\".\n</p>\n<p>\nFor much, much more detail on what you can do, please go to the <a href=\"#/tools/adding_custom_code/view_documentation\">Perl Module Documentation</a> and click on \'View\' for \'omnitool::omniclass\' and especially read the \'Hooks & Datatype-Specific Sub-Classes (\"OmniClass Packages\")\' section.\n</p>\n<p>\n<b>2. Tool.pm Sub-Classes</b>\n</p>\n<p>\nThese will allow you to create very feature-rich Applications.  All of your custom code for Tools.pm sub-classes should be in the prescribed hook methods.  \n</p>\n<p>\nUnless it is for a standard data action (create, update, delete, view), a new Action Tool will require a custom Tool.pm sub-class to implement its functionality.  Searching tools often need custom sub-classes to provide custom search filter menus, and pre-/post- search logic.\n</p>\n<p>\nTo create a Tool.pm sub-class, please navigate to the target Tool via \'Manage Tools\' in OT Admin, and select \'Get Sub-Class\' for the Tool.  A modal will appear, and then please click the link for \'Generate OmniClass Package for \"XYZ\" Tool\' to view the starter code.  Please copy and paste it into an appropriately-named module under \'omnitool::applications::YOUR_APP_DIRECTORY::tools\'.  Like for the OmniClass Packages, this  generated code will include the needed skeleton, plus examples for all the standard types of methods in a docs section under \"__END__\".\n</p>\n<p>\nFor much, much more detail on what you can do, please go to the <a href=\"#/tools/adding_custom_code/view_documentation\">Perl Module Documentation</a> and click on \'View\' for \'omnitool::tool\' and especially read the five sections starting with \'Writing Tool.pm Sub-Classes Overview\'.\n</p>\n<p>\n<b>3. Application Helper Modules</b>\n</p>\n<p>\nThere are currently four types of Application Helper modules you can use:\n</p>\n<p style=\"margin-left 50px\">\n<u>auth_helper.pm</u>\n<br/>This allows you to use another authentication database or service to test usernames and passwords.  If you use this, you do not need to use \'Manage Users\'.  The actual code to interface with that external service is up to you.  I set up a separate class to interact with my employer\'s SSO system, and then just call that module from auth_helper.pm.  Once your user authenticates, they will get a cookie that\'s good for 24 hours, so auth_helper.pm is not called often.\n<br/><br/>\n2. custom_session.pm\n<br/>This allows you to (a) put additional information about a user into their sessions, such as their name or phone number and (b) more importantly, build the \'access_info\' hash which is used to allow/deny membership to Access Roles.  This will usually rely on SQL queries and maybe info from your company directory.  (Please put the business logic in your database as much as possible!)  You must use this \'fetch_access_info()\' method if you are using auth_helper.pm!  \n<br/><br/>\n3. extra_luggage.pm\n<br/>This is where you add extra objects and data to the %$luggage structure that will be everywhere in the system.  Please see the docs for \'omnitool::common::luggage\' in <a href=\"#/tools/adding_custom_code/view_documentation\">Perl Module Documentation</a>.\n<br/><br/>\n4. daily_routines.pm\n<br/>As hinted to above (and discussed in detail in the OmniClass docs), you can have background tasks for specific Datatypes.  You may also want a set of Instance-wide tasks to run every day to act on a global basis.  Often, this is used to spawn many background tasks on a schedule or a specific day of the week/month.  This helper module enables you to run those Instance-wide daily tasks.  Set up the code you need in here, and then use the \'Start Daily BG Tasks\' option next to the target Instance under Manage Instances.\n</p>\n<p>\nTo generate these helpers, click \'Get Helpers\' next to your Application in OT Admin and click the \'Generate\' link next to each type of helper.  Please copy and paste to the appropriate spot under \'code/omnitool/applications\'.\n</p>\n<p>\n<b>4. Classes/modules with interact with your organization\'s other systems.</b>\n</p>\n<p>\nYour organization likely has other systems with which you will want OmniTool to interact.   The preferred way to accommodate this is to set up a \'your_company\' directory under \'code/omnitool\' and build interface classes there, which will be called from your OmniClass Packages.  \n</p>\n<p>\nIt\'s a good idea to construct these classes with %$luggage but not pass in OmniClass objects.  The idea is to keep these interfaces as generic as possible, so that you can use them across your applications.\n</p>\n<p>\nAt my work, I have an \'omnitool::cisco\' namespace, and in there, I have \'omnitool::cisco::company_directory\' that I use to look up information on my co-workers and pass back to the requesting OmniClass Packages.\n</p>\n<p>\nFinally a few stray thoughts:\n<ul style=\"margin-left 50px\">\n<li>The omnitool::common::db object includes a \'hash_cache()\' method which is extremely useful at times.  Please view the docs for omnitool::common::db in, you guessed it, <a href=\"#/tools/adding_custom_code/view_documentation\">Perl Module Documentation</a>.</li>\n<li>The best way to debug is with the \'logger()\' method in the utility_belt.pm class, as you can\'t output to the screen.</li>\n<li>OK, that\'s not 100% true.  You can set the \'OT_DEVELOPER\' environmental var to have error messages shown on the screen, but that\'s for Dev servers please.</li>\n</ul>\n</p>\n\n</div>','No','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(39,1,'8_1:35_1','Perl Code Conventions (Diary of an Overprotective Parent)','code_conventions','present_web_documents','None','Code Conventions','fa-child',5,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n<p>\nOK, I get it.  You are a fully-realized, vital individual who will do things your own way.  With that in mind, I am\npressing ahead in including this document.\n</p>\n<p>\nI really hope for this system to be maintainable and easy-to-follow.  To that end, I have followed the following \'rules\' \nand encourage you to do the same.  Any code that gets pushed into the master branch will/should follow these guidelines.\n</p>\n<p>\nHere goes:\n<p>\n<ol>\n<li>All subroutine names, variable names and hash keys should:\n	<UL>\n	<LI>Be all lowercase</LI>\n	<LI>Have_underscores_separating_words; no camelCase</LI>\n	<LI>Spell-out clearly what is in the variable and avoid funny nicknames and shorthand\n		<ul>\n		<li>Nicknames should be memorable and related to what the item is.</li>\n		<li>If you are going to be witty, actually be witty ;)</li>\n		</ul>\n	</LI>\n	</UL>\n	<br/>\n	Good variable examples:\n	<br/>\n<pre class=\"prettyprint\">\n$$luggage{application_instance} = \'1_1\';\n\n$this_documents_name = \'code_conventions.txt\';	\n</pre>\n</li>\n<br/>\n<li>The \'->\' notation is reserved for accessing methods/attributes of objects and should\n	not be used for accessing values in plain/unblessed hashes.  Hopefully, this makes\n	it easier to tell if something is just a data structure or has been blessed into\n	an object:\n<pre class=\"prettyprint\">\n# plain data structure / hash\nprint $$family{daughter}[1]{name}; \n\n# object for family, with a method for printing the second daughter\'s name\n$family->print_daughter_name(2); \n</pre>\n</li>\n<br/>\n<li>Always use the curly brackets {} for object variable names, so that you can tell\nthe difference between a variable and a method:\n<pre class=\"prettyprint\">\n$object->{definitely_a_variable} = 1;\n$object->{definitely_an_array}[0] = 1;\n$object->this_is_a_method();\n</pre>\n</li>\n<br/>\n<li>MySQL table names are always plurals of the data they represent.\n	Use plural form of datatype name, i.e. \'family_members\' for \'Family Member\' datatype\n</li>\n<br/>\n<li>Extensive comments and notes!  The perldoc notes under omniclass.pm is a great example.\n	Bonus points if you proofreaded them.  Please consider documentation to be required for\n	any module in the main omnitool:: namespace or under omnitool::common.\n</li>\n<br/>\n<li>All SQL commands/code must be contained in modules under omnitool::common or omnitool::omniclass.\n	The \'common\' modules are meant to be system-level and often un before the %$luggage or user\n	session is constructed.  These common modules are the only appropriate place to manage data not\n	represented by OmniClass Datatypes, and that should be only a very, very specific types of data.\n	The OmniClass modules must contain SQL, since that\'s where we actually load/save the data.\n	Note: SQL does not belong in the OmniClass Packages, only under omnitool::omniclass.\n</li>\n<br/>\n<li>No HTML, CSS, or JavaScript embedded in the Perl!  All of that goes under omnitool::static_files.\n	Another way to say this:  The only other language allowed in your Perl code is SQL, subject\n	to rule #4 above.\n</li>\n<br/>\n<li>No code golf -- limit complex one-liners unless they provide a speed boost.  Try to keep code\n	as readable as possible, and use consistent indents to indicate which scope you are within.\n</li>\n<br/>\n<li>This is an object-oriented system, with the exception of omnitool::common::pack_luggage.</li>\n</ol>\n</p>\n</div>\n','Yes','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(40,1,'1_1:2_1','Manage Budget Items','budgetitem','None','None','Budget Items','fa-money',8,'Inline / Data Row','8_1','Search - Screen',NULL,'No','No',NULL,NULL,'Yes','No','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(41,1,'8_1:40_1','View Budget Item Details','view_details','view_details','None','View Details','fa-search',1,'Inline / Data Row','8_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(42,1,'8_1:40_1','Create a Budget Item','create','standard_data_actions','None','Create a Budget Item','fa-plus',1,'Quick Actions','8_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(43,1,'8_1:40_1','Update a Budget Item','update','standard_data_actions','None','Update a Budget Item','fa-edit',1,'Inline / Data Row','8_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(44,1,'8_1:40_1','Delete a Budget Item','delete','standard_delete','None','Delete a Budget Item','fa-eraser',2,'Inline / Data Row','8_1','Action - Modal','No','No','No',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(45,1,'8_1:40_1','Manage Vendors','vendor','None','None','Vendors','fa-wrench',1,'Menubar','9_1','Search - Screen',NULL,'No','No',NULL,NULL,'Yes','No','Open',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No'),(46,1,'8_1:45_1','Create a Vendor','create','standard_data_actions','None','Create a Vendor','fa-plus',1,'Quick Actions','9_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','No',NULL,NULL,'No','No','No'),(47,1,'8_1:45_1','Update a Vendor','update','standard_data_actions','None','Update a Vendor','fa-edit',1,'Inline / Data Row','9_1','Action - Screen','No','No','Yes',NULL,NULL,'Yes','No','Open','Name',NULL,'20','No','Yes',NULL,NULL,'No','No','No'),(48,1,'1_1:1_1','Official Readme and Description','readme_notes','present_web_documents','None','Official Readme','fa-book',2,'Menubar','1_1','Action - Screen',NULL,'No','No',NULL,'<div class=\"bigger-125 width-75\" style=\"margin: auto\">\n\n<p class=\"h2\">NAME</p>\n\n<p>\nOmniTool - Build web application suites very quickly and with minimal code.\n</p>\n\n<p class=\"h2\">SYNOPSIS</p>\n\n<p>\n<pre class=\"prettyPrint\">\nuse omnitool;\n\n$luggage = omnitool->get_everything_ready(\n	\'username\' => \'someones_username\',\n	\'hostname\' => \'hostname-to-an-omnitool.application.omnitool.com\',\n);\n\n# %$luggage now contains a user session, utility belt, object factory, and\n# more goodies used to write a program to operate on your application.\n\n# The rest is OO, like so:\n\n$dogs = $$luggage{object_factory}->omniclass_object( \'dt\' => \'dogs\' );\n\n$dogs->search(\n	\'search_options\' => [\n		{ \'name\' => \'Ginger\' },\n		{ \'age\' => 17, \'operator\' => \'>\' },\n	],\n	\'auto_load\' => 1,\n);\n\nif ($dog->{search_results_found}) {\n\n	print \"The first dog I found is .\"$dogs->{data}{name}.\"\\n\";\n\n	$dogs->perform_trick(\'roll-over\');\n\n}\n</pre>\n</p>\nThis is an example of what a test script might look like. The vast majority of your real-world use will be run via the included main.psgi and background_tasks.pl.\n</p>\n\n<p class=\"h2\">SUMMARY / DESCRIPTION</p>\n<p>\nOmniTool is a comprehensive platform for the rapid development of web application suites. It is designed to simplify and speed up the development process, reducing code requirements to only the specific features and logic for the target application. The resulting applications are mobile-responsive and API-enabled with no extra work by the developers.\n</p>\n<p>\nThe OmniTool Administration UI allows developers to design object models (datatypes), specify the behavior of controllers (tools), manage display views (templates), import custom code (sub-classes), and configure the authentication and authorization logic. These actions are all completed via straight-forward and well-documented web forms. Most changes to application behavior are implemented without code changes and can be deployed instantly.\n</p>\n<p>\nThe configurations of tools, datatypes, templates, and custom sub-classes combine to form OmniTool Applications, which are put into use via separate Application Instances. Each Application Instance may (often will) have a separate database, will use separate logic to authorize users, and can have a separate application server. This allows for horizontal scaling as well as single-tenancy for each organization making use of a given Application.\n</p>\n<p>\nA key differentiator for OmniTool is the inclusion of a complete mobile-responsive User Interface. This UI kit provides a login form, all navigation, view bookmarking, and all search controls. For most applications, there will be no need to develop HTML templates or JavaScript for new applications, as the standard view mode templates are capable to handle search results, record-details display, forms inputs, modal views, pop-up messages, and more.\n</p>\n<p>\nEvery application developed with OmniTool is automatically equipped with a client API without any special code. Users are able to provision API keys that can be used to access their tools to submit requests to OmniTool. These keys are tied to IP addresses and require periodic renewal (which can be indefinitely extended by the administrators). Because all OmniTool applications receive d ata via POST and return data via JSON objects, it is very straight-forward to write an API client for any tool in the system. Example libraries are provided.\n</p>\n<p>\nAdditional facilities within OmniTool include: background task management and execution, inbound email processing, outbound email creation, and a large library of utility functions to aid with many common tasks.\n</p>\n<p>\nOmniTool is an object-oriented system, written in Modern(ish) Perl using Plack for delivery. Application-specific code is written as sub-classes to tools and datatypes, so that all of the common facilities are always available. The client-side code is developed with HTML5, Bootstrap, clean JavaScript, jQuery, and Jemplates. All data is stored in well-normalized MySQL 5.7+ / MariaDB 10.3+ databases. OmniTool is meant to run on Linux or FreeBSD, and the installation process has been tested most on Ubuntu 16.04 as of this writing. OmniTool is a extremely well-documented system with many examples in the extensive developer guides.\n</p>\n\n<p class=\"h2\">TARGET AUDIENCE / USES</p>\n<p>\nFolks who install and run OmniTool will be experienced LAMP developers who are looking to save a lot of time. Anyone with a web browser will be able to make use of the applications that you build and publish with this software, but building and administering these applications will require development expertise.\n</p>\n<p>\nThis is a great system for small-to-medium organizations or departments within larger organizations. The well-defined UI and \'more-is-more\' functionality do tighten its focus a bit, although building alternative UI\'s is quite possible for the industrious. I think this system is perfect for building apps to manage resources, processes, and requests.\n</p>\n<p>\nThere are three usage modes for the applicatins you build in OmniTool:\n</p>\n<p style=\"margin-left: 50px\">\n<b>Web UI (HTML):</b> Easiest way for everyone to use your app. Mobile-responsive, and really shines on tablets.\n<br/><br/>\n<b>API:</b> Allows users to set up their own programs to send requests via POST\'s and receive JSON back. Very nice for extending your application across your organization and beyond.\n<br/><br/>\n<b>Perl Scripts:</b> Maybe you just want to manage your datatypes via the Admin UI and then write your scripts to make use of these databases. Would be the least fun, but there is plenty of utilities here to have some fun.\n</p>\n\n<p class=\"h2\">DEVELOPER\'S OVERVIEW</p>\n<p>\nAll of the main modules have Pod documentation within them, so this is just an overview. The main parts of this code / system are:\n</p>\n<p style=\"margin-left: 50px\">\n<b>omnitool::omniclass</b>, which I obnoxiously refer to as \'The OmniClass.\' This is meant to be the \'Model\' piece, and its objects are instances of Datatypes, which are object definitions configured in the OmniTool Admin UI. This class handles all the database functions (search, load, save) as well as producing forms. Special functons driven by your data should be developed in sub-classes for OmniClass, all the way from small hooks to massage data for presentation up to large actions to impact other data and systems. Please see \'perldoc omnitool::omniclass\' for lots more information. FYI, \"OmniClass Sub-Class\" was so obnoxious, I have to call them \"OmniClass Packages\"; this is only marginally better, I know.\n<br/><br/>\n<b>omnitool::tool</b>, which I refer to as \'Tool.pm\', provides the \'Controller\' piece. This module brings to life the Tools which are configured in the OmniTool Admin UI, and those Tools are meant to command OmniClass and its packages. Like OmniClass, Tool.pm is a base class which provides a lot of functionality, and your Tool.pm sub-classes are where you build the custom applications. Please see \'perldoc omnitool::tool\' for lots more information.\n<br/><br/>\n<b>omnitool::static_files::</b> is our collection of JavaScript classes and Template-Toolkit templates that combine to form our \'View\' piece for the Web UI. We use the excellent Jemplate library to utilize Template-Toolkit on the client-side, allowing us to fully separate the data from the presentation, sending all data to the client via JSON. This makes it possible to have a fully-functional API mode outside of the Web UI, automatically available for each new Tool configured. ** Note: yes, I am keeping these \'static\' files here within the Perl code, because (a) this is very much custom code which will be maintained as part of this single system, (b) it will be served to the clients via omnitool::common::ui and (c) I believe the \'htdocs\' directory is for very static documents, image files and third-party HTML/JS/CSS/image libraries like ACE. *** Second note: I did start using the \'we\' and \'us\' lingo in this section. If you read this far, you are definitely involved.\n<br/><br/>\n<b>omnitool::common::</b>, is the Perl name-space for our utility and glue modules which provide the routines Tool.pm and OmniClass both rely upon as well as to make this system actually function as a application framework. Database functions, user sessions, UI producing, and template processing all happen in here, among other important work.\n</p>\n<p>\nConceptually, OmniTool is meant to power \'Applications,\' which consist of:\n</p>\n<p style=\"margin-left: 50px\">\n<b>Datatypes</b> - OmniClass configurations create/maintained via the OT Admin Web UI.\n<br/><br/>\n<b>Tools</b> - Tool.pm configurations create/maintained via the OT Admin Web UI.\n<br/><br/>\n<b>Custom Code</b> - Your sub-classes for OmniClass.pm and Tool.pm plus any custom templates and JavaScript developed to support your Tools.\n</p>\n<p>\nThese three ingredients allow for functional Tools, and to make them usable, you create \'Instances,\' sometimes referred to as \'Application Instances.\' Instance definitions consist of:\n</p>\n<p style=\"margin-left: 50px\">\nA web hostname, which should point to a virtual host on an Apache or nginix server which will reverse proxy over to the Perl/Plack app server running this very script.\n<br/><br/>\nA connection to a MySQL database server. This server should have everything it needs to serve the data needs of this OmniTool Application.\n<br/><br/>\nA database on the target MySQL database server which will house all the data for this Application Instance.\n</p>\n<p>\nThis separation of Application configs, code and logic from Instance delivery / storage configuration allows two important features:\n</p>\n<p style=\"margin-left: 50px\">\nApplications may be utilized by multiple groups or teams of people without those separate groups having to share data. (\'Single-tenant\' databases is the term, I believe.)\n<br/><br/>\nScalability. All your Instances may be served via one HTTPS server and one database server, or you could have one HTTPS server, many Plack/Perl servers and a few database servers. If you are brave enoughto have Galera multi-master replication set up for your MySQL server, you can set up one Application Instance per DB master server, all connecting to the same database name. (Or you can just use a load balancer and have one instance.)\n<br/><br/>\nTo have separate Database servers, all of your OmniTool Admin databases (omnitool / omnitool_*) must be replicated among all the servers in your OmniTool system. Each database server should have its own, unique copy of otstatedata, with only the table structures being kept in sync between otstatedata DB\'s.\n</p>\n<p>\nPlease note that the OmniTool Administration Application will itself have multiple Instances, so you are able to separate Application/Datatype/Tools configuration data very nicely. You will be required to build your apps out in a second OT Admin instance, and not in the base Instance tied to the \'omnitool\' database. This makes it easy to accept upgrades and share your work.\n</p>\n<p class=\"h2\">TECHNOLOGIES USED</p>\n<p>\nThis system requires Perl 5.22 or better in the 5.x line. It also expects MySQL 5.7 or higher. This system also requires the full Plack suite, which is detailed here: -Lhttp://plackperl.org as well as the great docs in CPAN.\n</p>\n<p>For templating, we rely on Template Toolkit on the server side and the amazing Jemplate Perl/JavaScript library. Please see http://www.template-toolkit.org and http://www.jemplate.net . Please see the notes in omnitool::common::utility_belt for the template_process() and jemplate_process() methods for more info on how we use these, as well as the notes in omnitool::tool on Tool Modes.\n</p>\n<p>For the HTML, CSS, and much of the JavaScript, we have the most excellent Ace Admin Template from www.wrapbootstrap.com. OmniTool uses version 1.3.4 of that package, with no plans to update at this time. We are using Bootstrap 3.3.5, which seems to work just great. The Ace Admin files are kept at $OTHOME/htdocs/omnitool/ace.\n</p>\n<p>\nAs of this writing, the system has been most tested on Ubuntu 16.04, but the code should work well on recent versions of FreeBSD, RHEL, Fedora, or CentOS.\n</p>\n<p class=\"h2\">ACKNOWLEDGEMENTS</p>\n<p>\nI am very appreciative to my employer, Cisco Systems, Inc., for allowing this software to be released to the community as open source. (IP Central ID: 153330984).\n</p>\n<p>\nI am also grateful to Mohsen Hosseini for allowing me to include his most excellent Ace Admin as part of this software.\n</p>\n<p class=\"h2\">LICENSE</p>\n<p>\nMIT License\n</p>\n<p>\nCopyright (c) 2017 Eric Chernoff\n</p>\n<p>\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n</p>\n<p>\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n</p>\n<p>\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n</p>\n</div>','Yes','No','',NULL,NULL,'20','No','No',NULL,NULL,'No','No','No');
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
INSERT INTO `tools_display_options_cached` VALUES ('omnitool_admin1534702878A44F215B85166FF55700_17_1',1535311049,_binary '\n\0\0\0\nJul17omnitool_admin_tools29\0\0\0altcode\n,omnitool_admin1534702878A44F215B85166FF55700\0\0\0client_connection_id\n17_1\0\0\0	tool_mode�\0\0\0options_were_reset\nsample_apps_admin\0\0\0uri_base','omnitool_admin','17_1'),('omnitool_admin1534702878A44F215B85166FF55700_2_1',1535307679,_binary '\n\0\0\0\0\0\0sort_column\n1_1\0\0\0	tool_mode\n,omnitool_admin1534702878A44F215B85166FF55700\0\0\0client_connection_id\nsample_apps_admin\0\0\0uri_base\0\0\0\n!Jul17omnitool_admin_applications2\n!Jul17omnitool_admin_applications1\0\0\0\raltcodes_keys\n\r1534702889256\0\0\0_\0\0\0\rquick_keyword\nnone\0\0\0return_tool_id\n	Ascending\0\0\0sort_direction\0\0\0advanced_search_filters�\0\0\0options_were_reset','omnitool_admin','2_1'),('omnitool_admin1534702878A44F215B85166FF55700_42_1',1535311052,_binary '\n\0\0\0\nJul17omnitool_admin_tools32\0\0\0altcode\n9_1_7_1\0\0\0return_tool_id\n,omnitool_admin1534702878A44F215B85166FF55700\0\0\0client_connection_id\nsample_apps_admin\0\0\0uri_base\0\0\0	tool_mode�\0\0\0options_were_reset','omnitool_admin','42_1'),('omnitool_admin1534702878A44F215B85166FF55700_7_1',1535311052,_binary '\n\0\0\0\nsample_apps_admin\0\0\0uri_base\n\r1534702889257\0\0\0_\n!Jul17omnitool_admin_applications1\0\0\0altcode\n9_1_7_1\0\0\0return_tool_id\0\0\0sort_column\n	Ascending\0\0\0sort_direction\n,omnitool_admin1534702878A44F215B85166FF55700\0\0\0client_connection_id\n6_1\0\0\0	tool_mode\0\0\0advanced_search_filters�\0\0\0options_were_reset\0\0\0\nAug17omnitool_admin_tools48\nJul17omnitool_admin_tools32\nJul17omnitool_admin_tools29\nJul17omnitool_admin_tools28\0\0\0\raltcodes_keys\ninstall\0\0\0\rquick_keyword','omnitool_admin','7_1');
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

-- Dump completed on 2018-08-19 15:20:31
