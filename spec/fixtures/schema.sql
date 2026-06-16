/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alerts` (
  `alert_id` mediumint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL DEFAULT '',
  `criteria` varchar(255) NOT NULL DEFAULT '',
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `registrationtoken` varchar(34) NOT NULL DEFAULT '',
  `confirmed` tinyint(1) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL DEFAULT '0000-01-01 00:00:00',
  `recommended` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`alert_id`),
  KEY `email` (`email`),
  KEY `confirmed` (`confirmed`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `anonvotes` (
  `epobject_id` int unsigned NOT NULL DEFAULT '0',
  `yes_votes` int unsigned NOT NULL DEFAULT '0',
  `no_votes` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`epobject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_key` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` mediumint NOT NULL,
  `api_key` char(24) NOT NULL,
  `commercial` tinyint(1) NOT NULL,
  `created` datetime NOT NULL,
  `disabled` datetime DEFAULT NULL,
  `reason` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `api_key` (`api_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_stats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `api_key` char(24) NOT NULL,
  `ip_address` varchar(16) NOT NULL,
  `query_time` datetime NOT NULL,
  `query` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `api_key` (`api_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bills` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL DEFAULT '',
  `url` varchar(255) NOT NULL DEFAULT '',
  `lords` tinyint(1) NOT NULL DEFAULT '0',
  `session` varchar(50) NOT NULL DEFAULT '',
  `standingprefix` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `title` (`title`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaigners` (
  `campaigner_id` mediumint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL DEFAULT '',
  `postcode` varchar(255) NOT NULL DEFAULT '',
  `constituency` varchar(100) NOT NULL DEFAULT '',
  `token` varchar(255) NOT NULL DEFAULT '',
  `confirmed` tinyint(1) NOT NULL DEFAULT '0',
  `signup_date` datetime NOT NULL,
  PRIMARY KEY (`campaigner_id`),
  KEY `email` (`email`),
  KEY `confirmed` (`confirmed`),
  KEY `constituency` (`constituency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaigners_sent_email` (
  `campaigner_id` int NOT NULL,
  `email_name` varchar(100) NOT NULL,
  UNIQUE KEY `campaigner_id` (`campaigner_id`,`email_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `commentreports` (
  `report_id` int NOT NULL AUTO_INCREMENT,
  `comment_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `body` text,
  `reported` datetime DEFAULT NULL,
  `resolved` datetime DEFAULT NULL,
  `resolvedby` int DEFAULT NULL,
  `locked` datetime DEFAULT NULL,
  `lockedby` int DEFAULT NULL,
  `upheld` tinyint(1) NOT NULL DEFAULT '0',
  `firstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `comment_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL DEFAULT '0',
  `epobject_id` int NOT NULL DEFAULT '0',
  `body` text,
  `posted` datetime DEFAULT NULL,
  `modflagged` datetime DEFAULT NULL,
  `visible` tinyint(1) NOT NULL DEFAULT '0',
  `original_gid` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`comment_id`),
  KEY `user_id` (`user_id`,`epobject_id`,`visible`),
  KEY `epobject_id` (`epobject_id`,`visible`),
  KEY `visible` (`visible`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `consinfo` (
  `constituency` varchar(100) NOT NULL DEFAULT '',
  `data_key` varchar(100) NOT NULL DEFAULT '',
  `data_value` text NOT NULL,
  UNIQUE KEY `consinfo_constituency_data_key` (`constituency`,`data_key`),
  KEY `constituency` (`constituency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `constituency` (
  `name` varchar(100) NOT NULL DEFAULT '',
  `main_name` tinyint(1) NOT NULL DEFAULT '0',
  `from_date` date NOT NULL DEFAULT '0000-01-01',
  `to_date` date NOT NULL DEFAULT '9999-12-31',
  `cons_id` int DEFAULT NULL,
  KEY `from_date` (`from_date`),
  KEY `to_date` (`to_date`),
  KEY `name` (`name`),
  KEY `constituency` (`cons_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `editqueue` (
  `edit_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `edit_type` int DEFAULT NULL,
  `epobject_id_l` int DEFAULT NULL,
  `epobject_id_h` int DEFAULT NULL,
  `glossary_id` int DEFAULT NULL,
  `time_start` datetime DEFAULT NULL,
  `time_end` datetime DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `body` text,
  `submitted` datetime DEFAULT NULL,
  `editor_id` int DEFAULT NULL,
  `approved` tinyint(1) DEFAULT NULL,
  `decided` datetime DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`edit_id`),
  KEY `approved` (`approved`),
  KEY `glossary_id` (`glossary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `epobject` (
  `epobject_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `body` mediumtext,
  `type` int DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `modified` datetime DEFAULT NULL,
  PRIMARY KEY (`epobject_id`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gidredirect` (
  `gid_from` char(60) DEFAULT NULL,
  `gid_to` char(60) DEFAULT NULL,
  `hdate` date NOT NULL DEFAULT '0000-01-01',
  `major` int DEFAULT NULL,
  UNIQUE KEY `gid_from` (`gid_from`),
  KEY `gid_to` (`gid_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `glossary` (
  `glossary_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `body` text,
  `wikipedia` varchar(255) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `last_modified` datetime DEFAULT NULL,
  `type` int DEFAULT NULL,
  `visible` tinyint DEFAULT NULL,
  PRIMARY KEY (`glossary_id`),
  KEY `visible` (`visible`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hansard` (
  `epobject_id` int NOT NULL DEFAULT '0',
  `gid` varchar(100) DEFAULT NULL,
  `htype` int NOT NULL DEFAULT '0',
  `speaker_id` int NOT NULL DEFAULT '0',
  `major` int NOT NULL DEFAULT '0',
  `section_id` int NOT NULL DEFAULT '0',
  `subsection_id` int NOT NULL DEFAULT '0',
  `hpos` int NOT NULL DEFAULT '0',
  `hdate` date NOT NULL DEFAULT '0000-01-01',
  `htime` time DEFAULT NULL,
  `source_url` varchar(255) NOT NULL DEFAULT '',
  `minor` int DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `modified` datetime DEFAULT NULL,
  PRIMARY KEY (`epobject_id`),
  UNIQUE KEY `gid` (`gid`),
  KEY `epobject_id` (`epobject_id`),
  KEY `subsection_id` (`subsection_id`),
  KEY `section_id` (`section_id`),
  KEY `hdate` (`hdate`),
  KEY `speaker_id` (`speaker_id`),
  KEY `hansard_speaker_id_hdate_hpos` (`speaker_id`,`hdate`,`hpos`),
  KEY `major` (`major`),
  KEY `htype` (`htype`),
  KEY `majorhdate` (`major`,`hdate`),
  KEY `modified` (`modified`),
  KEY `source_url` (`source_url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `indexbatch` (
  `indexbatch_id` int NOT NULL AUTO_INCREMENT,
  `created` datetime DEFAULT NULL,
  PRIMARY KEY (`indexbatch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `member` (
  `member_id` int NOT NULL DEFAULT '0',
  `house` int DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(255) NOT NULL DEFAULT '',
  `constituency` varchar(100) NOT NULL DEFAULT '',
  `party` varchar(100) NOT NULL DEFAULT '',
  `entered_house` date NOT NULL DEFAULT '1000-01-01',
  `left_house` date NOT NULL DEFAULT '9999-12-31',
  `entered_reason` enum('unknown','general_election','by_election','changed_party','reinstated','appointed','devolution','election','accession','regional_election','replaced_in_region','became_presiding_officer') NOT NULL DEFAULT 'unknown',
  `left_reason` enum('unknown','still_in_office','general_election','general_election_standing','general_election_not_standing','changed_party','died','declared_void','resigned','disqualified','became_peer','devolution','dissolution','retired','regional_election','became_presiding_officer') NOT NULL DEFAULT 'unknown',
  `person_id` int NOT NULL DEFAULT '0',
  `title` varchar(50) NOT NULL DEFAULT '',
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `first_name` (`first_name`,`last_name`,`constituency`,`entered_house`,`left_house`),
  KEY `person_id` (`person_id`),
  KEY `constituency` (`constituency`),
  KEY `house` (`house`),
  KEY `left_house_house` (`left_house`,`house`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `memberinfo` (
  `member_id` int NOT NULL DEFAULT '0',
  `data_key` varchar(100) NOT NULL DEFAULT '',
  `data_value` text NOT NULL,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `memberinfo_member_id_data_key` (`member_id`,`data_key`),
  KEY `member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mentions` (
  `mention_id` int NOT NULL AUTO_INCREMENT,
  `gid` varchar(100) DEFAULT NULL,
  `type` int NOT NULL,
  `date` date DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `mentioned_gid` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`mention_id`),
  UNIQUE KEY `all_values` (`gid`,`type`,`date`,`url`,`mentioned_gid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `moffice` (
  `moffice_id` int NOT NULL AUTO_INCREMENT,
  `dept` varchar(100) NOT NULL DEFAULT '',
  `position` varchar(200) NOT NULL DEFAULT '',
  `from_date` date NOT NULL DEFAULT '1000-01-01',
  `to_date` date NOT NULL DEFAULT '9999-12-31',
  `person` int DEFAULT NULL,
  `source` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`moffice_id`),
  KEY `person` (`person`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pbc_members` (
  `id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL DEFAULT '0',
  `chairman` tinyint(1) NOT NULL DEFAULT '0',
  `bill_id` int NOT NULL DEFAULT '0',
  `sitting` varchar(4) NOT NULL DEFAULT '',
  `attending` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `member_id` (`member_id`),
  KEY `bill_id` (`bill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personinfo` (
  `person_id` int NOT NULL DEFAULT '0',
  `data_key` varchar(100) NOT NULL DEFAULT '',
  `data_value` text NOT NULL,
  `lastupdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `personinfo_person_id_data_key` (`person_id`,`data_key`),
  KEY `person_id` (`person_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `postcode_lookup` (
  `postcode` varchar(10) NOT NULL DEFAULT '',
  `name` varchar(100) NOT NULL DEFAULT '',
  KEY `postcode` (`postcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `search_query_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `query_string` text,
  `page_number` int DEFAULT NULL,
  `count_hits` int DEFAULT NULL,
  `ip_address` text,
  `query_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `query_time` (`query_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `titles` (
  `title` varchar(190) NOT NULL DEFAULT '',
  PRIMARY KEY (`title`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` mediumint NOT NULL AUTO_INCREMENT,
  `firstname` varchar(255) NOT NULL DEFAULT '',
  `lastname` varchar(255) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT '',
  `password` varchar(102) NOT NULL DEFAULT '',
  `lastvisit` datetime NOT NULL DEFAULT '0000-01-01 00:00:00',
  `registrationtime` datetime NOT NULL DEFAULT '0000-01-01 00:00:00',
  `registrationip` varchar(20) DEFAULT NULL,
  `status` enum('Viewer','User','Moderator','Administrator','Superuser') DEFAULT 'Viewer',
  `emailpublic` tinyint(1) NOT NULL DEFAULT '0',
  `optin` tinyint(1) NOT NULL DEFAULT '0',
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `constituency` varchar(255) NOT NULL DEFAULT '',
  `registrationtoken` varchar(24) NOT NULL DEFAULT '',
  `confirmed` tinyint(1) NOT NULL DEFAULT '0',
  `url` varchar(255) NOT NULL DEFAULT '',
  `api_key` char(24) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `api_key` (`api_key`),
  KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `uservotes` (
  `user_id` int unsigned NOT NULL DEFAULT '0',
  `epobject_id` int NOT NULL DEFAULT '0',
  `vote` tinyint(1) NOT NULL DEFAULT '0',
  KEY `epobject_id` (`epobject_id`,`vote`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `video_timestamps` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gid` varchar(100) NOT NULL,
  `user_id` int DEFAULT NULL,
  `atime` time NOT NULL,
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `whenstamped` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `gid_user_id` (`gid`,`user_id`),
  KEY `gid` (`gid`),
  KEY `deleted` (`deleted`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

