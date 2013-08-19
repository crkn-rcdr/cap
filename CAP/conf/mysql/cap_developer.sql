-- MySQL dump 10.13  Distrib 5.5.24, for osx10.6 (i386)
--
-- Host: localhost    Database: cap_pristine
-- ------------------------------------------------------
-- Server version	5.5.24

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
-- Table structure for table `contributor`
--

DROP TABLE IF EXISTS `contributor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contributor` (
  `portal_id` varchar(64) NOT NULL DEFAULT '',
  `institution_id` int(11) NOT NULL DEFAULT '0',
  `lang` varchar(2) NOT NULL DEFAULT '',
  `url` text,
  `description` text,
  `logo` tinyint(1) NOT NULL DEFAULT '0',
  `logo_filename` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`portal_id`,`institution_id`,`lang`),
  KEY `institution_id` (`institution_id`),
  CONSTRAINT `contributor_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `contributor_ibfk_2` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contributor`
--

LOCK TABLES `contributor` WRITE;
/*!40000 ALTER TABLE `contributor` DISABLE KEYS */;
/*!40000 ALTER TABLE `contributor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `counter_log`
--

DROP TABLE IF EXISTS `counter_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `counter_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `institution_id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `document` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `institution_id` (`institution_id`),
  CONSTRAINT `counter_log_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `counter_log`
--

LOCK TABLES `counter_log` WRITE;
/*!40000 ALTER TABLE `counter_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `counter_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cron_log`
--

DROP TABLE IF EXISTS `cron_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cron_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `completed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action` varchar(64) NOT NULL,
  `ok` tinyint(1) DEFAULT NULL,
  `message` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cron_log`
--

LOCK TABLES `cron_log` WRITE;
/*!40000 ALTER TABLE `cron_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `cron_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `discounts`
--

DROP TABLE IF EXISTS `discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(16) NOT NULL,
  `portal_id` varchar(64) DEFAULT NULL,
  `percentage` int(11) DEFAULT NULL,
  `expires` datetime DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `discounts_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `discounts`
--

LOCK TABLES `discounts` WRITE;
/*!40000 ALTER TABLE `discounts` DISABLE KEYS */;
/*!40000 ALTER TABLE `discounts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title_id` int(11) NOT NULL,
  `identifier` varchar(64) NOT NULL,
  `sequence` int(11) DEFAULT '1',
  `label` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `title_id_2` (`title_id`,`identifier`),
  KEY `title_id` (`title_id`),
  KEY `identifier` (`identifier`),
  KEY `sequence` (`sequence`),
  CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`title_id`) REFERENCES `titles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents`
--

LOCK TABLES `documents` WRITE;
/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `feedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `submitted` datetime DEFAULT NULL,
  `feedback` text,
  `resolved` datetime DEFAULT NULL,
  `comments` text,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback`
--

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `image_resources`
--

DROP TABLE IF EXISTS `image_resources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `image_resources` (
  `image_id` int(11) NOT NULL DEFAULT '0',
  `lang` varchar(2) NOT NULL DEFAULT '',
  `resource` enum('title','description') NOT NULL DEFAULT 'title',
  `value` text,
  PRIMARY KEY (`image_id`,`lang`,`resource`),
  CONSTRAINT `image_resources_ibfk_1` FOREIGN KEY (`image_id`) REFERENCES `images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `image_resources`
--

LOCK TABLES `image_resources` WRITE;
/*!40000 ALTER TABLE `image_resources` DISABLE KEYS */;
/*!40000 ALTER TABLE `image_resources` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `filename` varchar(128) NOT NULL,
  `content_type` varchar(32) NOT NULL,
  `height` int(11) NOT NULL,
  `width` int(11) NOT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filename` (`filename`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `images_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `images`
--

LOCK TABLES `images` WRITE;
/*!40000 ALTER TABLE `images` DISABLE KEYS */;
/*!40000 ALTER TABLE `images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `info`
--

DROP TABLE IF EXISTS `info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `info` (
  `name` varchar(32) NOT NULL,
  `value` varchar(64) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `info`
--

LOCK TABLES `info` WRITE;
/*!40000 ALTER TABLE `info` DISABLE KEYS */;
INSERT INTO `info` VALUES ('version','76',NULL);
/*!40000 ALTER TABLE `info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institution`
--

DROP TABLE IF EXISTS `institution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(16) DEFAULT NULL,
  `name` varchar(128) NOT NULL DEFAULT 'New Institution',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institution`
--

LOCK TABLES `institution` WRITE;
/*!40000 ALTER TABLE `institution` DISABLE KEYS */;
/*!40000 ALTER TABLE `institution` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institution_alias`
--

DROP TABLE IF EXISTS `institution_alias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution_alias` (
  `institution_id` int(11) NOT NULL,
  `lang` varchar(2) NOT NULL,
  `name` text NOT NULL,
  PRIMARY KEY (`institution_id`,`lang`),
  CONSTRAINT `institution_alias_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institution_alias`
--

LOCK TABLES `institution_alias` WRITE;
/*!40000 ALTER TABLE `institution_alias` DISABLE KEYS */;
/*!40000 ALTER TABLE `institution_alias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institution_ipaddr`
--

DROP TABLE IF EXISTS `institution_ipaddr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution_ipaddr` (
  `cidr` varchar(64) NOT NULL,
  `institution_id` int(11) NOT NULL,
  `start` bigint(20) unsigned NOT NULL,
  `end` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`cidr`),
  KEY `institution_id` (`institution_id`),
  KEY `start` (`start`),
  KEY `end` (`end`),
  CONSTRAINT `institution_ipaddr_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institution_ipaddr`
--

LOCK TABLES `institution_ipaddr` WRITE;
/*!40000 ALTER TABLE `institution_ipaddr` DISABLE KEYS */;
/*!40000 ALTER TABLE `institution_ipaddr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institution_mgmt`
--

DROP TABLE IF EXISTS `institution_mgmt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution_mgmt` (
  `user_id` int(11) NOT NULL,
  `institution_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`,`institution_id`),
  KEY `institution_id` (`institution_id`),
  CONSTRAINT `institution_mgmt_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `institution_mgmt_ibfk_2` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institution_mgmt`
--

LOCK TABLES `institution_mgmt` WRITE;
/*!40000 ALTER TABLE `institution_mgmt` DISABLE KEYS */;
/*!40000 ALTER TABLE `institution_mgmt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institution_subscription`
--

DROP TABLE IF EXISTS `institution_subscription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution_subscription` (
  `institution_id` int(11) NOT NULL DEFAULT '0',
  `portal_id` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`institution_id`,`portal_id`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `institution_subscription_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`),
  CONSTRAINT `institution_subscription_ibfk_2` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institution_subscription`
--

LOCK TABLES `institution_subscription` WRITE;
/*!40000 ALTER TABLE `institution_subscription` DISABLE KEYS */;
/*!40000 ALTER TABLE `institution_subscription` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `labels`
--

DROP TABLE IF EXISTS `labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `labels` (
  `field` varchar(32) NOT NULL DEFAULT '',
  `code` varchar(32) NOT NULL DEFAULT '',
  `lang` varchar(2) NOT NULL DEFAULT '',
  `label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`field`,`code`,`lang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `labels`
--

LOCK TABLES `labels` WRITE;
/*!40000 ALTER TABLE `labels` DISABLE KEYS */;
/*!40000 ALTER TABLE `labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `language`
--

DROP TABLE IF EXISTS `language`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `language` (
  `code` varchar(32) NOT NULL DEFAULT '',
  `lang` varchar(2) NOT NULL DEFAULT '',
  `label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`code`,`lang`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `language`
--

LOCK TABLES `language` WRITE;
/*!40000 ALTER TABLE `language` DISABLE KEYS */;
/*!40000 ALTER TABLE `language` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `media_type`
--

DROP TABLE IF EXISTS `media_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `media_type` (
  `code` varchar(32) NOT NULL DEFAULT '',
  `lang` varchar(2) NOT NULL DEFAULT '',
  `label` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`code`,`lang`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `media_type`
--

LOCK TABLES `media_type` WRITE;
/*!40000 ALTER TABLE `media_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `media_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outbound_link`
--

DROP TABLE IF EXISTS `outbound_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `outbound_link` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `portal_id` varchar(64) DEFAULT NULL,
  `contributor` varchar(16) DEFAULT NULL,
  `document` varchar(128) DEFAULT NULL,
  `url` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `outbound_link_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbound_link`
--

LOCK TABLES `outbound_link` WRITE;
/*!40000 ALTER TABLE `outbound_link` DISABLE KEYS */;
/*!40000 ALTER TABLE `outbound_link` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document_id` int(11) NOT NULL,
  `sequence` int(11) DEFAULT '1',
  `label` text,
  `transcription_user_id` int(11) DEFAULT NULL,
  `review_user_id` int(11) DEFAULT NULL,
  `transcription_status` enum('not_transcribed','locked_for_transcription','awaiting_review','locked_for_review','transcribed','transcribed_with_corrections') NOT NULL DEFAULT 'not_transcribed',
  `transcription` text,
  `type` enum('unknown','control','single_page','start_page','end_page','middle_page') NOT NULL DEFAULT 'unknown',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `document_id_2` (`document_id`,`sequence`),
  KEY `document_id` (`document_id`),
  KEY `sequence` (`sequence`),
  KEY `transcription_status` (`transcription_status`),
  KEY `transcription_user_id` (`transcription_user_id`),
  KEY `review_user_id` (`review_user_id`),
  CONSTRAINT `pages_ibfk_1` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `pages_ibfk_2` FOREIGN KEY (`transcription_user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `pages_ibfk_3` FOREIGN KEY (`review_user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pages`
--

LOCK TABLES `pages` WRITE;
/*!40000 ALTER TABLE `pages` DISABLE KEYS */;
/*!40000 ALTER TABLE `pages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user_id` int(11) NOT NULL,
  `completed` datetime DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT '0.00',
  `description` text,
  `returnto` text,
  `foreignid` int(11) DEFAULT NULL,
  `token` text,
  `message` text,
  `processor` enum('paypal') DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment`
--

LOCK TABLES `payment` WRITE;
/*!40000 ALTER TABLE `payment` DISABLE KEYS */;
/*!40000 ALTER TABLE `payment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal`
--

DROP TABLE IF EXISTS `portal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal` (
  `id` varchar(64) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT '0',
  `supports_users` tinyint(1) NOT NULL DEFAULT '0',
  `supports_subscriptions` tinyint(1) NOT NULL DEFAULT '0',
  `supports_institutions` tinyint(1) NOT NULL DEFAULT '0',
  `supports_transcriptions` tinyint(1) NOT NULL DEFAULT '0',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal`
--

LOCK TABLES `portal` WRITE;
/*!40000 ALTER TABLE `portal` DISABLE KEYS */;
INSERT INTO `portal` VALUES ('canadiana',1,1,0,0,0,'2013-04-19 15:14:34');
/*!40000 ALTER TABLE `portal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal_access`
--

DROP TABLE IF EXISTS `portal_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal_access` (
  `portal_id` varchar(64) NOT NULL,
  `level` int(11) NOT NULL,
  `preview` int(11) NOT NULL DEFAULT '0',
  `content` int(11) NOT NULL DEFAULT '0',
  `metadata` int(11) NOT NULL DEFAULT '0',
  `resize` int(11) NOT NULL DEFAULT '0',
  `download` int(11) NOT NULL DEFAULT '0',
  `purchase` int(11) NOT NULL DEFAULT '0',
  `searching` int(11) NOT NULL DEFAULT '0',
  `browse` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`portal_id`,`level`),
  CONSTRAINT `portal_access_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal_access`
--

LOCK TABLES `portal_access` WRITE;
/*!40000 ALTER TABLE `portal_access` DISABLE KEYS */;
INSERT INTO `portal_access` VALUES ('canadiana',0,-1,-1,-1,-1,-1,-1,0,0),('canadiana',1,-1,-1,-1,-1,-1,-1,0,0),('canadiana',2,-1,-1,-1,-1,-1,-1,0,0);
/*!40000 ALTER TABLE `portal_access` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal_feature`
--

DROP TABLE IF EXISTS `portal_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal_feature` (
  `portal_id` varchar(64) NOT NULL DEFAULT '',
  `feature` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`portal_id`,`feature`),
  KEY `portal_id` (`portal_id`),
  KEY `feature` (`feature`),
  CONSTRAINT `portal_feature_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal_feature`
--

LOCK TABLES `portal_feature` WRITE;
/*!40000 ALTER TABLE `portal_feature` DISABLE KEYS */;
/*!40000 ALTER TABLE `portal_feature` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal_host`
--

DROP TABLE IF EXISTS `portal_host`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal_host` (
  `id` varchar(32) NOT NULL,
  `portal_id` varchar(64) DEFAULT NULL,
  `canonical` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `canonical_host` (`id`,`canonical`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `portal_host_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal_host`
--

LOCK TABLES `portal_host` WRITE;
/*!40000 ALTER TABLE `portal_host` DISABLE KEYS */;
INSERT INTO `portal_host` VALUES ('secure','canadiana',NULL);
/*!40000 ALTER TABLE `portal_host` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal_lang`
--

DROP TABLE IF EXISTS `portal_lang`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal_lang` (
  `portal_id` varchar(64) NOT NULL,
  `lang` varchar(2) NOT NULL,
  `priority` int(11) NOT NULL DEFAULT '0',
  `title` varchar(128) DEFAULT 'NEW PORTAL',
  `description` text,
  PRIMARY KEY (`portal_id`,`lang`),
  UNIQUE KEY `portal_id` (`portal_id`,`lang`),
  KEY `portal_id_2` (`portal_id`),
  CONSTRAINT `portal_lang_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal_lang`
--

LOCK TABLES `portal_lang` WRITE;
/*!40000 ALTER TABLE `portal_lang` DISABLE KEYS */;
INSERT INTO `portal_lang` VALUES ('canadiana','en',10,'Canadiana',NULL),('canadiana','fr',0,'Canadiana',NULL);
/*!40000 ALTER TABLE `portal_lang` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portal_subscriptions`
--

DROP TABLE IF EXISTS `portal_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portal_subscriptions` (
  `id` varchar(32) NOT NULL,
  `portal_id` varchar(64) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `portal_subscriptions_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portal_subscriptions`
--

LOCK TABLES `portal_subscriptions` WRITE;
/*!40000 ALTER TABLE `portal_subscriptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `portal_subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portals_titles`
--

DROP TABLE IF EXISTS `portals_titles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portals_titles` (
  `portal_id` varchar(64) NOT NULL DEFAULT '',
  `title_id` int(11) NOT NULL DEFAULT '0',
  `hosted` tinyint(1) DEFAULT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`portal_id`,`title_id`),
  KEY `title_id` (`title_id`),
  KEY `modified` (`updated`),
  KEY `updated` (`updated`),
  CONSTRAINT `portals_titles_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `portals_titles_ibfk_2` FOREIGN KEY (`title_id`) REFERENCES `titles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portals_titles`
--

LOCK TABLES `portals_titles` WRITE;
/*!40000 ALTER TABLE `portals_titles` DISABLE KEYS */;
/*!40000 ALTER TABLE `portals_titles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promocode`
--

DROP TABLE IF EXISTS `promocode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `promocode` (
  `id` varchar(32) NOT NULL,
  `expires` datetime DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promocode`
--

LOCK TABLES `promocode` WRITE;
/*!40000 ALTER TABLE `promocode` DISABLE KEYS */;
/*!40000 ALTER TABLE `promocode` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `request_log`
--

DROP TABLE IF EXISTS `request_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `request_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `institution_id` int(11) DEFAULT NULL,
  `time` datetime NOT NULL,
  `session` varchar(40) NOT NULL,
  `session_count` int(11) NOT NULL,
  `portal` varchar(64) NOT NULL,
  `view` varchar(64) NOT NULL,
  `action` varchar(64) NOT NULL,
  `args` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `institution_id` (`institution_id`),
  KEY `time_index` (`time`),
  KEY `session_index` (`session`),
  KEY `action_index` (`action`),
  CONSTRAINT `request_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `request_log_ibfk_2` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `request_log`
--

LOCK TABLES `request_log` WRITE;
/*!40000 ALTER TABLE `request_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `request_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `search_log`
--

DROP TABLE IF EXISTS `search_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `request_id` int(11) NOT NULL,
  `query` varchar(256) DEFAULT NULL,
  `results` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `request_id` (`request_id`),
  CONSTRAINT `search_log_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `request_log` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `search_log`
--

LOCK TABLES `search_log` WRITE;
/*!40000 ALTER TABLE `search_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `search_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` char(72) NOT NULL,
  `session_data` text,
  `expires` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slide`
--

DROP TABLE IF EXISTS `slide`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `slide` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `portal` varchar(64) NOT NULL,
  `slideshow` varchar(64) NOT NULL,
  `sort` int(11) NOT NULL,
  `url` varchar(512) NOT NULL,
  `thumb_url` varchar(512) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `slideshow_portal` (`portal`,`slideshow`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slide`
--

LOCK TABLES `slide` WRITE;
/*!40000 ALTER TABLE `slide` DISABLE KEYS */;
/*!40000 ALTER TABLE `slide` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slide_description`
--

DROP TABLE IF EXISTS `slide_description`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `slide_description` (
  `slide_id` int(11) NOT NULL,
  `lang` varchar(2) NOT NULL,
  `description` text,
  PRIMARY KEY (`slide_id`,`lang`),
  CONSTRAINT `slide_description_ibfk_1` FOREIGN KEY (`slide_id`) REFERENCES `slide` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slide_description`
--

LOCK TABLES `slide_description` WRITE;
/*!40000 ALTER TABLE `slide_description` DISABLE KEYS */;
/*!40000 ALTER TABLE `slide_description` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stats_usage_institution`
--

DROP TABLE IF EXISTS `stats_usage_institution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stats_usage_institution` (
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `month_starting` date NOT NULL,
  `institution_id` int(11) NOT NULL,
  `searches` int(11) DEFAULT NULL,
  `sessions` int(11) DEFAULT NULL,
  `page_views` int(11) DEFAULT NULL,
  `requests` int(11) DEFAULT NULL,
  PRIMARY KEY (`month_starting`,`institution_id`),
  KEY `institution_id` (`institution_id`),
  CONSTRAINT `stats_usage_institution_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_usage_institution`
--

LOCK TABLES `stats_usage_institution` WRITE;
/*!40000 ALTER TABLE `stats_usage_institution` DISABLE KEYS */;
/*!40000 ALTER TABLE `stats_usage_institution` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stats_usage_portal`
--

DROP TABLE IF EXISTS `stats_usage_portal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stats_usage_portal` (
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `month_starting` date NOT NULL,
  `portal_id` varchar(64) NOT NULL,
  `searches` int(11) DEFAULT NULL,
  `sessions` int(11) DEFAULT NULL,
  `page_views` int(11) DEFAULT NULL,
  `requests` int(11) DEFAULT NULL,
  PRIMARY KEY (`month_starting`,`portal_id`),
  KEY `portal_id` (`portal_id`),
  CONSTRAINT `stats_usage_portal_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_usage_portal`
--

LOCK TABLES `stats_usage_portal` WRITE;
/*!40000 ALTER TABLE `stats_usage_portal` DISABLE KEYS */;
/*!40000 ALTER TABLE `stats_usage_portal` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscription`
--

DROP TABLE IF EXISTS `subscription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subscription` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user_id` int(11) NOT NULL,
  `portal_id` varchar(64) NOT NULL,
  `completed` datetime DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `product` varchar(32) DEFAULT NULL,
  `discount_code` varchar(16) DEFAULT NULL,
  `discount_amount` decimal(10,2) DEFAULT NULL,
  `old_expire` datetime DEFAULT NULL,
  `new_expire` datetime DEFAULT NULL,
  `old_level` int(11) DEFAULT NULL,
  `new_level` int(11) DEFAULT NULL,
  `payment_id` int(11) DEFAULT NULL,
  `note` text,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `payment_id` (`payment_id`),
  KEY `subscription_ibfk_3` (`portal_id`),
  CONSTRAINT `subscription_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `subscription_ibfk_2` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`id`),
  CONSTRAINT `subscription_ibfk_3` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscription`
--

LOCK TABLES `subscription` WRITE;
/*!40000 ALTER TABLE `subscription` DISABLE KEYS */;
/*!40000 ALTER TABLE `subscription` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `terms`
--

DROP TABLE IF EXISTS `terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `terms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent` int(11) DEFAULT NULL,
  `sortkey` varchar(256) DEFAULT NULL,
  `term` text,
  PRIMARY KEY (`id`),
  KEY `sortkey` (`sortkey`(255)),
  KEY `parent` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `terms`
--

LOCK TABLES `terms` WRITE;
/*!40000 ALTER TABLE `terms` DISABLE KEYS */;
/*!40000 ALTER TABLE `terms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `titles`
--

DROP TABLE IF EXISTS `titles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `titles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `institution_id` int(11) NOT NULL,
  `identifier` varchar(64) NOT NULL,
  `label` text NOT NULL,
  `level` int(11) NOT NULL DEFAULT '0',
  `transcribable` tinyint(1) NOT NULL DEFAULT '0',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `institution_id` (`institution_id`,`identifier`),
  KEY `identifier` (`identifier`),
  KEY `modified` (`updated`),
  KEY `updated` (`updated`),
  CONSTRAINT `titles_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `titles`
--

LOCK TABLES `titles` WRITE;
/*!40000 ALTER TABLE `titles` DISABLE KEYS */;
/*!40000 ALTER TABLE `titles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `titles_terms`
--

DROP TABLE IF EXISTS `titles_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `titles_terms` (
  `title_id` int(11) NOT NULL DEFAULT '0',
  `term_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`title_id`,`term_id`),
  KEY `term_id` (`term_id`),
  CONSTRAINT `titles_terms_ibfk_1` FOREIGN KEY (`title_id`) REFERENCES `titles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `titles_terms_ibfk_2` FOREIGN KEY (`term_id`) REFERENCES `terms` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `titles_terms`
--

LOCK TABLES `titles_terms` WRITE;
/*!40000 ALTER TABLE `titles_terms` DISABLE KEYS */;
/*!40000 ALTER TABLE `titles_terms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `email` varchar(128) DEFAULT NULL,
  `password` varchar(50) NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `token` varchar(128) DEFAULT NULL,
  `confirmed` int(11) NOT NULL DEFAULT '0',
  `active` int(11) NOT NULL DEFAULT '1',
  `created` datetime NOT NULL,
  `last_login` datetime DEFAULT NULL,
  `credits` int(11) NOT NULL DEFAULT '0',
  `can_transcribe` tinyint(1) DEFAULT '1',
  `can_review` tinyint(1) DEFAULT '1',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_2` (`username`),
  UNIQUE KEY `username_3` (`username`),
  UNIQUE KEY `username` (`email`),
  UNIQUE KEY `email` (`email`),
  KEY `token` (`token`),
  KEY `updated` (`updated`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'admin','admin@c7a.ca','f08c37500dbca982f1fb5a85d702d2c126ecf8e7kqY+9t+5Yq','Administrator','',1,1,'2013-01-01 00:00:00',NULL,0,1,1,'2013-08-12 13:14:03');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_document`
--

DROP TABLE IF EXISTS `user_document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_document` (
  `user_id` int(11) NOT NULL,
  `document` varchar(160) NOT NULL,
  `acquired` datetime DEFAULT NULL,
  PRIMARY KEY (`user_id`,`document`),
  CONSTRAINT `user_document_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_document`
--

LOCK TABLES `user_document` WRITE;
/*!40000 ALTER TABLE `user_document` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_document` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_roles` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `role_id` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_roles_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `cap_core`.`roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,'administrator');
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_subscription`
--

DROP TABLE IF EXISTS `user_subscription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_subscription` (
  `user_id` int(11) NOT NULL,
  `portal_id` varchar(64) NOT NULL DEFAULT '',
  `expires` datetime NOT NULL,
  `permanent` int(11) NOT NULL DEFAULT '0',
  `reminder_sent` int(11) NOT NULL DEFAULT '0',
  `expiry_logged` datetime DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `level` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`portal_id`),
  KEY `user_id` (`user_id`),
  KEY `portal_id` (`portal_id`),
  KEY `level` (`level`),
  CONSTRAINT `user_subscription_portalid_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_subscription_userid_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_subscription`
--

LOCK TABLES `user_subscription` WRITE;
/*!40000 ALTER TABLE `user_subscription` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_subscription` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_discounts`
--

DROP TABLE IF EXISTS `users_discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_discounts` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `discount_id` int(11) NOT NULL DEFAULT '0',
  `subscription_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`discount_id`),
  KEY `discount_id` (`discount_id`),
  KEY `subscription_id` (`subscription_id`),
  CONSTRAINT `users_discounts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `discounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `users_discounts_ibfk_2` FOREIGN KEY (`discount_id`) REFERENCES `discounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `users_discounts_ibfk_3` FOREIGN KEY (`subscription_id`) REFERENCES `subscription` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_discounts`
--

LOCK TABLES `users_discounts` WRITE;
/*!40000 ALTER TABLE `users_discounts` DISABLE KEYS */;
/*!40000 ALTER TABLE `users_discounts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-08-16 14:02:03
