-- MySQL dump 10.13  Distrib 5.5.28, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: cap
-- ------------------------------------------------------
-- Server version	5.5.28-0ubuntu0.12.04.2

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
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `terms`
--

LOCK TABLES `terms` WRITE;
/*!40000 ALTER TABLE `terms` DISABLE KEYS */;
INSERT INTO `terms` VALUES (18,NULL,'oop-debates-en','English'),(19,18,'1-soc','Senate of Canada'),(20,19,'p01','1st Parliament'),(21,20,'s05','5th Session'),(22,NULL,'oop-debates-fr','Français'),(23,22,'1-sdc','Sénat du Canada'),(24,23,'p08','8e Législature'),(25,24,'s01','1re Session'),(26,18,'2-hoc','House of Commons'),(27,26,'p03','3rd Parliament'),(28,27,'s02','2nd Session'),(29,22,'2-cdc','Chambre des communes'),(30,29,'p03','3e Législature'),(31,30,'s02','2e Session');
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `institution_id` (`institution_id`,`identifier`),
  KEY `identifier` (`identifier`),
  CONSTRAINT `titles_ibfk_1` FOREIGN KEY (`institution_id`) REFERENCES `institution` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `titles`
--

LOCK TABLES `titles` WRITE;
/*!40000 ALTER TABLE `titles` DISABLE KEYS */;
INSERT INTO `titles` VALUES (14,4,'debates_SOC0105','Senate Debates, 1st Parliament, 5th Session'),(15,4,'debates_SDC0801','Débats du Sénat, 8e Parliament, 1re Session'),(16,4,'debates_HOC0302','House of Commons Debates, 3rd Parliament, 2nd Session'),(17,4,'debates_CDC0302','Débats de la Chambre des communes, 3e Parliament, 2e Session');
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
INSERT INTO `titles_terms` VALUES (14,18),(16,18),(14,19),(14,20),(14,21),(15,22),(17,22),(15,23),(15,24),(15,25),(16,26),(16,27),(16,28),(17,29),(17,30),(17,31);
/*!40000 ALTER TABLE `titles_terms` ENABLE KEYS */;
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
  PRIMARY KEY (`portal_id`,`title_id`),
  KEY `title_id` (`title_id`),
  CONSTRAINT `portals_titles_ibfk_1` FOREIGN KEY (`portal_id`) REFERENCES `portal` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `portals_titles_ibfk_2` FOREIGN KEY (`title_id`) REFERENCES `titles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portals_titles`
--

LOCK TABLES `portals_titles` WRITE;
/*!40000 ALTER TABLE `portals_titles` DISABLE KEYS */;
INSERT INTO `portals_titles` VALUES ('parl',14,1),('parl',15,1),('parl',16,1),('parl',17,1);
/*!40000 ALTER TABLE `portals_titles` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-03-05 12:23:55
