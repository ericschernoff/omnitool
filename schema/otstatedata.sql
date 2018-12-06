-- MySQL dump 10.13  Distrib 5.7.24, for Linux (x86_64)
--
-- Host: localhost    Database: otstatedata
-- ------------------------------------------------------
-- Server version	5.7.24-0ubuntu0.18.04.1-log

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
-- Table structure for table `authenticated_users`
--

DROP TABLE IF EXISTS `authenticated_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `authenticated_users` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rand_string` char(16) NOT NULL,
  `username` varchar(100) NOT NULL,
  `remote_ip` varchar(40) NOT NULL,
  `login_time` int(11) unsigned NOT NULL,
  `timezone_name` varchar(50) DEFAULT NULL,
  `require_password_change` char(10) DEFAULT 'No',
  PRIMARY KEY (`code`),
  KEY `code_hostname` (`rand_string`,`code`),
  KEY `user_info` (`username`,`login_time`)
) ENGINE=InnoDB AUTO_INCREMENT=524 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `datatype_hashes`
--

DROP TABLE IF EXISTS `datatype_hashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `datatype_hashes` (
  `hostname` varchar(50) NOT NULL DEFAULT '',
  `dthash` longblob,
  PRIMARY KEY (`hostname`),
  KEY `hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hash_cache`
--

DROP TABLE IF EXISTS `hash_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hash_cache` (
  `object_name` varchar(250) NOT NULL,
  `expiration_time` int(15) unsigned NOT NULL DEFAULT '0',
  `cached_hash` longblob,
  PRIMARY KEY (`object_name`),
  KEY `expiration_time` (`expiration_time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hostname_info_cache`
--

DROP TABLE IF EXISTS `hostname_info_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hostname_info_cache` (
  `hostname_or_uri` varchar(50) NOT NULL,
  `omnitool_admin_database` varchar(50) NOT NULL,
  `app_instance_id` varchar(40) NOT NULL,
  `hostname` varchar(100) NOT NULL,
  `public_mode` varchar(3) DEFAULT 'No',
  PRIMARY KEY (`hostname_or_uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `login_attempts_counter`
--

DROP TABLE IF EXISTS `login_attempts_counter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `login_attempts_counter` (
  `remote_ip` varchar(30) NOT NULL,
  `last_attempt_time` int(11) NOT NULL,
  `attempts_count` int(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`remote_ip`),
  KEY `remote_ip` (`remote_ip`,`last_attempt_time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `omnitool_sessions`
--

DROP TABLE IF EXISTS `omnitool_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `omnitool_sessions` (
  `code` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` char(100) NOT NULL,
  `app_instance` varchar(25) NOT NULL,
  `hostname` varchar(60) NOT NULL,
  `last_access` int(11) NOT NULL,
  `session` longblob,
  PRIMARY KEY (`code`),
  KEY `session_lookup` (`username`,`app_instance`,`hostname`),
  KEY `session_ageout` (`username`,`app_instance`,`hostname`,`last_access`)
) ENGINE=InnoDB AUTO_INCREMENT=594 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `screen_reader_users`
--

DROP TABLE IF EXISTS `screen_reader_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `screen_reader_users` (
  `username` varchar(20) NOT NULL,
  `screen_reader_mode` enum('Enabled','Disabled') DEFAULT 'Enabled',
  PRIMARY KEY (`username`)
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

-- Dump completed on 2018-12-06 16:26:47
