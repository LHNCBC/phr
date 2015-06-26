-- MySQL dump 10.13  Distrib 5.6.13, for Linux (x86_64)
--
-- Host: phr-master-build    Database: lm_proto1_development
-- ------------------------------------------------------
-- Server version	5.6.16

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
-- Table structure for table `action_params`
--

DROP TABLE IF EXISTS `action_params`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `action_params` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `current_url` varchar(255) DEFAULT NULL,
  `conditions` varchar(255) DEFAULT NULL,
  `handler` varchar(255) DEFAULT NULL,
  `redirect_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `answer_lists`
--

DROP TABLE IF EXISTS `answer_lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `answer_lists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `list_name` varchar(255) DEFAULT NULL,
  `list_desc` varchar(255) DEFAULT NULL,
  `code_system` varchar(255) DEFAULT NULL,
  `has_score` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12018 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `answers`
--

DROP TABLE IF EXISTS `answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `answer_text` varchar(255) DEFAULT NULL,
  `answer_string_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18099 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audits`
--

DROP TABLE IF EXISTS `audits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `auditable_id` int(11) DEFAULT NULL,
  `auditable_type` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_type` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `audited_changes` text,
  `version` int(11) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `association_id` int(11) DEFAULT NULL,
  `association_type` varchar(255) DEFAULT NULL,
  `remote_address` varchar(255) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `auditable_index` (`auditable_id`,`auditable_type`),
  KEY `user_index` (`user_id`,`user_type`),
  KEY `index_audits_on_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auto_increments`
--

DROP TABLE IF EXISTS `auto_increments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auto_increments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_name` varchar(255) DEFAULT NULL,
  `min_auto_increment` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `autosave_tmps`
--

DROP TABLE IF EXISTS `autosave_tmps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `autosave_tmps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `profile_id` varchar(255) DEFAULT NULL,
  `data_table` longtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `form_name` varchar(255) DEFAULT NULL,
  `test_panel` tinyint(1) DEFAULT '0',
  `base_rec` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_autosave_tmps_on_user_id_and_profile_id_and_form_name` (`user_id`,`profile_id`,`form_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `class_cache_versions`
--

DROP TABLE IF EXISTS `class_cache_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `class_cache_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `class_name` varchar(255) DEFAULT NULL,
  `form_name` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `classifications`
--

DROP TABLE IF EXISTS `classifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `classifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `p_id` int(11) DEFAULT NULL,
  `class_name` varchar(255) DEFAULT NULL,
  `class_code` varchar(255) DEFAULT NULL,
  `sequence` int(11) DEFAULT NULL,
  `list_description_id` int(11) DEFAULT NULL,
  `class_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_classifications_on_class_code_and_class_type_id` (`class_code`,`class_type_id`),
  UNIQUE KEY `index_classifications_on_class_name_and_p_id` (`class_name`,`p_id`)
) ENGINE=InnoDB AUTO_INCREMENT=199 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clinical_maps`
--

DROP TABLE IF EXISTS `clinical_maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clinical_maps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lookup_field` varchar(255) DEFAULT NULL,
  `clinician_text` varchar(255) DEFAULT NULL,
  `patient_text` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comparison_operators`
--

DROP TABLE IF EXISTS `comparison_operators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comparison_operators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `display_value` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `taffy_db_operator` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `operator_type` varchar(255) DEFAULT NULL,
  `active_record_operator` varchar(255) DEFAULT NULL,
  `active_record_query_string` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comparison_operators_predefined_fields`
--

DROP TABLE IF EXISTS `comparison_operators_predefined_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comparison_operators_predefined_fields` (
  `comparison_operator_id` int(11) DEFAULT NULL,
  `predefined_field_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_classes`
--

DROP TABLE IF EXISTS `data_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_code` varchar(255) DEFAULT NULL,
  `classification_id` int(11) DEFAULT NULL,
  `sequence` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_data_classes_on_sequence_and_classification_id` (`sequence`,`classification_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6211 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_edits`
--

DROP TABLE IF EXISTS `data_edits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_edits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `data_table` varchar(255) DEFAULT NULL,
  `backup_file` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=497 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `date_reminders`
--

DROP TABLE IF EXISTS `date_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `date_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `db_table_description_id` int(11) DEFAULT NULL,
  `record_id_in_user_table` int(11) DEFAULT NULL,
  `reminder_type` varchar(255) DEFAULT NULL,
  `reminder_item` varchar(255) DEFAULT NULL,
  `date_type` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `reminder_status` varchar(255) DEFAULT NULL,
  `hide_me` int(11) DEFAULT '0',
  `calculate_date` varchar(255) DEFAULT NULL,
  `calculate_date_HL7` varchar(255) DEFAULT NULL,
  `calculate_date_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=380 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `db_field_descriptions`
--

DROP TABLE IF EXISTS `db_field_descriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `db_field_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `db_table_description_id` int(11) DEFAULT NULL,
  `data_column` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `regex_validator_id` int(11) DEFAULT NULL,
  `required` tinyint(1) DEFAULT NULL,
  `max_responses` int(11) DEFAULT '0',
  `data_size` int(11) DEFAULT NULL,
  `default_value` text,
  `field_type` varchar(255) DEFAULT NULL,
  `units_of_measure` varchar(255) DEFAULT NULL,
  `predefined_field_id` int(11) DEFAULT NULL,
  `list_code_column` varchar(255) DEFAULT NULL,
  `html_parse_level` int(11) DEFAULT '0',
  `merge_user_list_data` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `virtual` tinyint(1) DEFAULT '0',
  `omit_from_field_lists` tinyint(1) DEFAULT '0',
  `is_major_item` tinyint(1) DEFAULT '0',
  `display_name` varchar(255) DEFAULT NULL,
  `item_master_table` varchar(255) DEFAULT NULL,
  `list_identifier` varchar(255) DEFAULT NULL,
  `list_conditions` varchar(255) DEFAULT NULL,
  `fields_saved` varchar(255) DEFAULT NULL,
  `list_join_string` varchar(255) DEFAULT NULL,
  `match_list_value` tinyint(1) DEFAULT NULL,
  `controlling_field_id` int(11) DEFAULT NULL,
  `list_values_for_field` varchar(255) DEFAULT NULL,
  `abs_min` varchar(255) DEFAULT NULL,
  `abs_max` varchar(255) DEFAULT NULL,
  `stored_yes` varchar(255) DEFAULT NULL,
  `stored_no` varchar(255) DEFAULT NULL,
  `list_master_table` varchar(255) DEFAULT NULL,
  `major_item_ids` varchar(255) DEFAULT NULL,
  `list_field_help_column` varchar(255) DEFAULT NULL,
  `list_field_tooltip_column` varchar(255) DEFAULT NULL,
  `current_value_for_field` varchar(255) DEFAULT NULL,
  `current_item_for_field` varchar(255) DEFAULT NULL,
  `item_table_has_unique_codes` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_db_field_descriptions_on_controlling_field_id` (`controlling_field_id`),
  KEY `index_db_field_descriptions_on_data_column` (`data_column`),
  KEY `index_db_field_descriptions_on_data_column_and_id` (`data_column`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=255 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `db_table_descriptions`
--

DROP TABLE IF EXISTS `db_table_descriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `db_table_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data_table` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `access_level` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `has_record_id` tinyint(1) DEFAULT '1',
  `parent_table_id` int(11) DEFAULT NULL,
  `parent_table_foreign_key` varchar(255) DEFAULT NULL,
  `omit_from_tables_list` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_db_table_descriptions_on_data_table` (`data_table`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `deleted_profiles`
--

DROP TABLE IF EXISTS `deleted_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deleted_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `id_shown` varchar(255) DEFAULT NULL,
  `archived` tinyint(1) DEFAULT NULL,
  `selected_panels` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `drug_name_route_codes`
--

DROP TABLE IF EXISTS `drug_name_route_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drug_name_route_codes` (
  `code` int(11) DEFAULT NULL,
  `long_code` varchar(255) DEFAULT NULL,
  UNIQUE KEY `index_drug_name_route_codes_on_code` (`code`),
  UNIQUE KEY `index_drug_name_route_codes_on_long_code` (`long_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `drug_name_routes`
--

DROP TABLE IF EXISTS `drug_name_routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drug_name_routes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `text` varchar(2048) DEFAULT NULL,
  `route` varchar(255) DEFAULT NULL,
  `suppress` tinyint(1) DEFAULT '0',
  `synonyms` varchar(255) DEFAULT NULL,
  `drug_class_codes` varchar(255) DEFAULT NULL,
  `ingredient_rxcuis` varchar(255) DEFAULT NULL,
  `generic_id` int(11) DEFAULT NULL,
  `is_brand` tinyint(1) DEFAULT NULL,
  `route_codes` varchar(255) DEFAULT NULL,
  `code_is_old` tinyint(1) DEFAULT '0',
  `old_codes` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `index_drug_name_routes_on_code` (`code`),
  KEY `index_drug_name_routes_on_text` (`text`(255))
) ENGINE=InnoDB AUTO_INCREMENT=616720 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `drug_routes`
--

DROP TABLE IF EXISTS `drug_routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drug_routes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `retired` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_drug_routes_on_name` (`name`),
  KEY `index_drug_routes_on_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `drug_strength_forms`
--

DROP TABLE IF EXISTS `drug_strength_forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drug_strength_forms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `drug_name_route_id` int(11) DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  `rxcui` int(11) DEFAULT NULL,
  `amount_list_name` varchar(255) DEFAULT NULL,
  `strength` varchar(255) DEFAULT NULL,
  `form` varchar(255) DEFAULT NULL,
  `suppress` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_drug_strength_forms_on_drug_name_route_id_and_suppress` (`drug_name_route_id`,`suppress`),
  KEY `index_drug_strength_forms_on_drug_name_route_id` (`drug_name_route_id`),
  KEY `index_drug_strength_forms_on_rxcui` (`rxcui`)
) ENGINE=InnoDB AUTO_INCREMENT=1401672 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `expression_conditions`
--

DROP TABLE IF EXISTS `expression_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `expression_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `expression_name` varchar(255) DEFAULT NULL,
  `condition_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `field_conditions`
--

DROP TABLE IF EXISTS `field_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `field_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_id` int(11) DEFAULT NULL,
  `field_id` int(11) DEFAULT NULL,
  `cond_id` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `defining_field` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `field_descriptions`
--

DROP TABLE IF EXISTS `field_descriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `field_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_id` int(11) DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `target_field` varchar(255) DEFAULT NULL,
  `control_type` varchar(255) DEFAULT NULL,
  `regex_validator_id` int(11) DEFAULT NULL,
  `control_type_detail` varchar(2048) DEFAULT NULL,
  `required` tinyint(1) DEFAULT NULL,
  `max_responses` int(11) DEFAULT '0',
  `group_header_id` int(11) DEFAULT NULL COMMENT 'ID of the header for a group of fields',
  `help_text` text,
  `data_size` int(11) DEFAULT NULL,
  `default_value` text,
  `field_type` varchar(255) DEFAULT NULL,
  `instructions` text,
  `units_of_measure` varchar(255) DEFAULT NULL,
  `predefined_field_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `list_code_column` varchar(255) DEFAULT NULL,
  `html_parse_level` int(11) DEFAULT '0',
  `controlled_edit` tinyint(1) DEFAULT '0',
  `edit_allowed_fields` varchar(255) DEFAULT NULL,
  `controlled_edit_menu` varchar(255) DEFAULT NULL,
  `controlled_edit_actions` varchar(255) DEFAULT NULL,
  `min_err_msg` varchar(255) DEFAULT NULL,
  `max_err_msg` varchar(255) DEFAULT NULL,
  `width` varchar(255) DEFAULT NULL,
  `min_width` varchar(255) DEFAULT NULL,
  `merge_user_list_data` varchar(255) DEFAULT NULL,
  `editor` int(11) DEFAULT '0',
  `db_field_description_id` int(11) DEFAULT NULL,
  `editor_params` varchar(255) DEFAULT NULL,
  `cet_no_dup` tinyint(1) DEFAULT '0',
  `auto_fill` tinyint(1) DEFAULT '1',
  `data_req_output` varchar(4096) DEFAULT NULL,
  `cet_no_dup_check` varchar(255) DEFAULT NULL,
  `list_field_help_column` varchar(255) DEFAULT NULL,
  `list_field_tooltip_column` varchar(255) DEFAULT NULL,
  `in_hdr_only` tinyint(1) DEFAULT '0',
  `suggestion_mode` int(11) DEFAULT '0',
  `wrap` tinyint(1) DEFAULT '0',
  `radio_group_param` varchar(255) DEFAULT NULL,
  `show_rowid` tinyint(1) DEFAULT NULL,
  `show_max_responses` tinyint(1) DEFAULT NULL,
  `auto_add_row` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_field_descriptions_on_form_id` (`form_id`),
  KEY `index_field_descriptions_on_group_header_id` (`group_header_id`),
  KEY `index_field_descriptions_on_db_field_description_id` (`db_field_description_id`),
  KEY `index_field_descriptions_on_target_field_and_form_id` (`target_field`,`form_id`),
  KEY `index_field_descriptions_on_control_type_and_form_id` (`control_type`,`form_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2323 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `field_expressions`
--

DROP TABLE IF EXISTS `field_expressions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `field_expressions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_id` int(11) DEFAULT NULL,
  `field_id` int(11) DEFAULT NULL,
  `exp_id` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `condition_name` varchar(255) DEFAULT NULL,
  `defining_field` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `field_validation_conditions`
--

DROP TABLE IF EXISTS `field_validation_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `field_validation_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_validation_id` int(11) DEFAULT NULL,
  `cond_string` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `field_validations`
--

DROP TABLE IF EXISTS `field_validations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `field_validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_description_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `form_builder_maps`
--

DROP TABLE IF EXISTS `form_builder_maps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `form_builder_maps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_name` varchar(255) NOT NULL,
  `check_box` tinyint(1) DEFAULT '0',
  `cne` tinyint(1) DEFAULT '0',
  `cwe` tinyint(1) DEFAULT '0',
  `cx` tinyint(1) DEFAULT '0',
  `dt` tinyint(1) DEFAULT '0',
  `dtm` tinyint(1) DEFAULT '0',
  `ft` tinyint(1) DEFAULT '0',
  `group_header` tinyint(1) DEFAULT '0',
  `display_only` tinyint(1) DEFAULT '0',
  `nm` tinyint(1) DEFAULT '0',
  `nm_plus` tinyint(1) DEFAULT '0',
  `st` tinyint(1) DEFAULT '0',
  `tx` tinyint(1) DEFAULT '0',
  `image` tinyint(1) DEFAULT '0',
  `button` tinyint(1) DEFAULT '0',
  `check_box_display` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forms`
--

DROP TABLE IF EXISTS `forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_name` varchar(255) DEFAULT NULL,
  `form_title` varchar(255) DEFAULT NULL,
  `sub_forms` varchar(255) DEFAULT NULL COMMENT 'The names of any sub_forms this form may call.  Separate each form name with a single space.',
  `form_description` varchar(255) DEFAULT NULL,
  `vsplit` tinyint(1) DEFAULT '1',
  `access_level` int(11) DEFAULT NULL,
  `form_style` varchar(255) DEFAULT NULL,
  `data_view` int(11) DEFAULT NULL COMMENT '1=patient-oriented terminology; 0=clinician-oriented terminology',
  `form_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `header_type` varchar(1) DEFAULT 'S',
  `show_banner_on_popup` tinyint(1) DEFAULT '0',
  `show_form_title` tinyint(1) DEFAULT '1',
  `form_js` varchar(4096) DEFAULT NULL,
  `uses_data_model` tinyint(1) DEFAULT '0',
  `has_panel_data` tinyint(1) DEFAULT '0',
  `autosaves` tinyint(1) DEFAULT '0',
  `show_toolbar` tinyint(1) DEFAULT '1',
  `sub_title` varchar(510) DEFAULT NULL,
  `preload_fragment_cache` tinyint(1) DEFAULT NULL,
  `delay_navsetup` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_forms_on_form_name` (`form_name`),
  KEY `index_forms_on_access_level` (`access_level`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forms_rule_sets`
--

DROP TABLE IF EXISTS `forms_rule_sets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forms_rule_sets` (
  `form_id` int(11) DEFAULT NULL,
  `rule_set_id` int(11) DEFAULT NULL,
  KEY `index_forms_rule_sets_on_form_id` (`form_id`),
  KEY `index_forms_rule_sets_on_rule_set_id` (`rule_set_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gopher_term_synonyms`
--

DROP TABLE IF EXISTS `gopher_term_synonyms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gopher_term_synonyms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gopher_term_id` int(11) DEFAULT NULL,
  `term_synonym` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gopher_term_synonyms_on_gopher_term_id` (`gopher_term_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4571 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gopher_terms`
--

DROP TABLE IF EXISTS `gopher_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gopher_terms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key_id` varchar(255) DEFAULT NULL,
  `primary_name` varchar(255) DEFAULT NULL,
  `gopher_term_class` varchar(255) DEFAULT NULL,
  `icd9_code_id` int(11) DEFAULT NULL,
  `word_synonyms_old` varchar(255) DEFAULT NULL,
  `excluded_from_cms` tinyint(1) DEFAULT '0',
  `consumer_name` varchar(255) DEFAULT NULL,
  `term_class` varchar(255) DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `document_weight` float DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_procedure` tinyint(1) DEFAULT '0',
  `old_primary_name` varchar(255) DEFAULT NULL,
  `included_in_phr` tinyint(1) DEFAULT '0',
  `sct_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gopher_terms_on_key_id` (`key_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5884 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gopher_terms_mplus_hts`
--

DROP TABLE IF EXISTS `gopher_terms_mplus_hts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gopher_terms_mplus_hts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gopher_to_mesh_id` int(11) DEFAULT NULL,
  `gopher_key_id` varchar(255) DEFAULT NULL,
  `gopher_primary_name` varchar(255) DEFAULT NULL,
  `urlid` varchar(255) DEFAULT NULL,
  `mplus_page_title` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gopher_terms_to_mplus_health_topics_on_gopher_primary_name` (`gopher_primary_name`),
  KEY `index_gopher_terms_mplus_hts_on_gopher_key_id` (`gopher_key_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4935 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gopher_to_meshes`
--

DROP TABLE IF EXISTS `gopher_to_meshes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gopher_to_meshes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gopher_term_id` int(11) DEFAULT NULL,
  `gopher_key_id` varchar(255) DEFAULT NULL,
  `gopher_primary_name` varchar(255) DEFAULT NULL,
  `mesh_dnumber` varchar(255) DEFAULT NULL,
  `mesh_concept_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gopher_to_meshes_on_gopher_primary_name` (`gopher_primary_name`),
  KEY `index_gopher_to_meshes_on_mesh_dnumber` (`mesh_dnumber`)
) ENGINE=InnoDB AUTO_INCREMENT=3343 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `health_reminders`
--

DROP TABLE IF EXISTS `health_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `health_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_shown` varchar(255) DEFAULT NULL,
  `msg_key` varchar(255) DEFAULT NULL,
  `msg` text,
  `latest` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_date_reminders`
--

DROP TABLE IF EXISTS `hist_date_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_date_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `db_table_description_id` int(11) DEFAULT NULL,
  `record_id_in_user_table` int(11) DEFAULT NULL,
  `reminder_type` varchar(255) DEFAULT NULL,
  `reminder_item` varchar(255) DEFAULT NULL,
  `date_type` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `reminder_status` varchar(255) DEFAULT NULL,
  `hide_me` int(11) DEFAULT '0',
  `calculate_date` varchar(255) DEFAULT NULL,
  `calculate_date_HL7` varchar(255) DEFAULT NULL,
  `calculate_date_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_obr_orders`
--

DROP TABLE IF EXISTS `hist_obr_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_obr_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `obr2_placer_order_number` varchar(255) DEFAULT NULL,
  `obr3_filler_order_number` varchar(255) DEFAULT NULL,
  `obr4_service_ident` varchar(255) DEFAULT NULL,
  `obr13_relevant_clinical_info` varchar(255) DEFAULT NULL,
  `obr36_scheduled_datetime` varchar(255) DEFAULT NULL,
  `loinc_num` varchar(255) DEFAULT NULL,
  `test_place` varchar(255) DEFAULT NULL,
  `test_date` varchar(255) DEFAULT NULL,
  `test_date_ET` bigint(20) DEFAULT NULL,
  `test_date_HL7` varchar(255) DEFAULT NULL,
  `summary` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `panel_name` varchar(255) DEFAULT NULL,
  `test_date_time` varchar(255) DEFAULT NULL,
  `single_test` tinyint(1) DEFAULT '0',
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_obx_observations`
--

DROP TABLE IF EXISTS `hist_obx_observations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_obx_observations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `obr_order_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `obx2_value_type` varchar(255) DEFAULT NULL,
  `obx3_1_obs_ident` varchar(255) DEFAULT NULL,
  `obx3_3_obs_ident` varchar(255) DEFAULT NULL,
  `obx3_2_obs_ident` varchar(255) DEFAULT NULL,
  `obx5_value` varchar(255) DEFAULT NULL,
  `obx5_1_value_if_coded` varchar(255) DEFAULT NULL,
  `obx5_3_value_if_coded` varchar(255) DEFAULT NULL,
  `obx5_value_if_text_report` text,
  `obx6_1_unit` varchar(255) DEFAULT NULL,
  `obx6_2_unit` varchar(255) DEFAULT NULL,
  `obx6_3_unit` varchar(255) DEFAULT NULL,
  `obx7_reference_ranges` varchar(255) DEFAULT NULL,
  `obx8_abnormal_flags` varchar(255) DEFAULT NULL,
  `obx11_result_status_code` varchar(10) DEFAULT NULL,
  `obx19_analysis_datetime` varchar(255) DEFAULT NULL,
  `obx23_performing_organization` varchar(255) DEFAULT NULL,
  `obx24_performing_address` varchar(255) DEFAULT NULL,
  `obx25_performing_director` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  `code_system` varchar(255) DEFAULT NULL,
  `loinc_num` varchar(255) DEFAULT NULL,
  `is_panel` tinyint(1) DEFAULT NULL,
  `test_date` varchar(255) DEFAULT NULL,
  `test_date_ET` bigint(20) DEFAULT NULL,
  `test_date_HL7` varchar(255) DEFAULT NULL,
  `test_normal_high` varchar(255) DEFAULT NULL,
  `test_normal_low` varchar(255) DEFAULT NULL,
  `required_in_panel` tinyint(1) DEFAULT NULL,
  `unit_code` varchar(255) DEFAULT NULL,
  `test_danger_high` varchar(255) DEFAULT NULL,
  `test_danger_low` varchar(255) DEFAULT NULL,
  `value_real` varchar(255) DEFAULT NULL,
  `last_value` varchar(255) DEFAULT NULL,
  `lastvalue_date` varchar(255) DEFAULT NULL,
  `last_date` varchar(255) DEFAULT NULL,
  `last_date_ET` bigint(20) DEFAULT NULL,
  `last_date_HL7` varchar(255) DEFAULT NULL,
  `is_panel_hdr` tinyint(1) DEFAULT NULL,
  `disp_level` int(11) DEFAULT NULL,
  `value_score` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `test_date_time` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_allergies`
--

DROP TABLE IF EXISTS `hist_phr_allergies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_allergies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `allergy_type_C` varchar(255) DEFAULT NULL,
  `reaction_C` varchar(255) DEFAULT NULL,
  `reaction_date_HL7` varchar(255) DEFAULT NULL,
  `reaction_date_ET` bigint(20) DEFAULT NULL,
  `allergy_name_C` varchar(255) DEFAULT NULL,
  `allergy_type` varchar(255) DEFAULT NULL,
  `reaction_date` varchar(255) DEFAULT NULL,
  `reaction` varchar(2048) DEFAULT NULL,
  `allergy_name` varchar(255) DEFAULT NULL,
  `allergy_type_uid` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `allergy_comment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_conditions`
--

DROP TABLE IF EXISTS `hist_phr_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `present` varchar(255) DEFAULT NULL,
  `when_started_HL7` varchar(255) DEFAULT NULL,
  `problem_C` varchar(255) DEFAULT NULL,
  `when_started_ET` bigint(20) DEFAULT NULL,
  `present_C` varchar(255) DEFAULT NULL,
  `prob_desc` varchar(2048) DEFAULT NULL,
  `problem` varchar(255) DEFAULT NULL,
  `when_started` varchar(255) DEFAULT NULL,
  `cond_stop` varchar(255) DEFAULT NULL,
  `cond_stop_ET` bigint(20) DEFAULT NULL,
  `cond_stop_HL7` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_doctor_questions`
--

DROP TABLE IF EXISTS `hist_phr_doctor_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_doctor_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `question_status` varchar(255) DEFAULT NULL,
  `date_entered_ET` bigint(20) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `category_C` varchar(255) DEFAULT NULL,
  `question_status_C` varchar(255) DEFAULT NULL,
  `date_entered_HL7` varchar(255) DEFAULT NULL,
  `question_answer` varchar(2048) DEFAULT NULL,
  `question` varchar(2048) DEFAULT NULL,
  `date_entered` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_drugs`
--

DROP TABLE IF EXISTS `hist_phr_drugs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_drugs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `drug_strength_form_C` varchar(255) DEFAULT NULL,
  `why_stopped` varchar(255) DEFAULT NULL,
  `expire_date_ET` bigint(20) DEFAULT NULL,
  `drug_use_status` varchar(255) DEFAULT NULL,
  `expire_date_HL7` varchar(255) DEFAULT NULL,
  `drug_use_status_C` varchar(255) DEFAULT NULL,
  `name_and_route` varchar(255) DEFAULT NULL,
  `why_stopped_C` varchar(255) DEFAULT NULL,
  `expire_date` varchar(255) DEFAULT NULL,
  `drug_strength_form` varchar(255) DEFAULT NULL,
  `instructions` varchar(2048) DEFAULT NULL,
  `stopped_date` varchar(255) DEFAULT NULL,
  `stopped_date_ET` bigint(20) DEFAULT NULL,
  `stopped_date_HL7` varchar(255) DEFAULT NULL,
  `name_and_route_C` varchar(255) DEFAULT '',
  `drug_start` varchar(255) DEFAULT NULL,
  `drug_start_ET` bigint(20) DEFAULT NULL,
  `drug_start_HL7` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_immunizations`
--

DROP TABLE IF EXISTS `hist_phr_immunizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_immunizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `vaccine_date_ET` bigint(20) DEFAULT NULL,
  `vaccine_date_HL7` varchar(255) DEFAULT NULL,
  `vaccine_date` varchar(255) DEFAULT NULL,
  `immune_duedate_HL7` varchar(255) DEFAULT NULL,
  `immune_name_C` varchar(255) DEFAULT NULL,
  `imm_type` varchar(255) DEFAULT NULL,
  `immune_duedate` varchar(255) DEFAULT NULL,
  `immune_name` varchar(255) DEFAULT NULL,
  `immune_duedate_ET` bigint(20) DEFAULT NULL,
  `imm_comment` varchar(2048) DEFAULT NULL,
  `imm_type_C` varchar(255) DEFAULT NULL,
  `imm_type_uid` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_medical_contacts`
--

DROP TABLE IF EXISTS `hist_phr_medical_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_medical_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `medcon_type` varchar(255) DEFAULT NULL,
  `medcon_type_C` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `next_appt` varchar(255) DEFAULT NULL,
  `next_appt_ET` bigint(20) DEFAULT NULL,
  `next_appt_HL7` varchar(255) DEFAULT NULL,
  `comments` varchar(2048) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `next_appt_time` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_notes`
--

DROP TABLE IF EXISTS `hist_phr_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `note_date` varchar(255) DEFAULT NULL,
  `note_date_ET` bigint(20) DEFAULT NULL,
  `note_date_HL7` varchar(255) DEFAULT NULL,
  `note_text` varchar(2048) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phr_surgical_histories`
--

DROP TABLE IF EXISTS `hist_phr_surgical_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phr_surgical_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `surgery_comments` varchar(2048) DEFAULT NULL,
  `surgery_type` varchar(255) DEFAULT NULL,
  `surgery_when_HL7` varchar(255) DEFAULT NULL,
  `surgery_type_C` varchar(255) DEFAULT NULL,
  `surgery_when` varchar(255) DEFAULT NULL,
  `surgery_when_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_phrs`
--

DROP TABLE IF EXISTS `hist_phrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_phrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `birth_date` varchar(255) DEFAULT NULL,
  `pregnant` varchar(255) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `pseudonym` varchar(255) DEFAULT NULL,
  `pregnant_C` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `birth_date_HL7` varchar(255) DEFAULT NULL,
  `race_or_ethnicity` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `gender_C` varchar(255) DEFAULT NULL,
  `birth_date_ET` bigint(20) DEFAULT NULL,
  `race_or_ethnicity_C` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hist_reminder_options`
--

DROP TABLE IF EXISTS `hist_reminder_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hist_reminder_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `orig_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `db_table_description_id` int(11) DEFAULT NULL,
  `reminder_type` varchar(255) DEFAULT NULL,
  `item_column` varchar(255) DEFAULT NULL,
  `due_date_column` varchar(255) DEFAULT NULL,
  `due_date_type` varchar(255) DEFAULT NULL,
  `cutoff_days` int(11) DEFAULT NULL,
  `query_condition` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icd9_codes`
--

DROP TABLE IF EXISTS `icd9_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icd9_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(10) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_procedure` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17283 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `installation_changes`
--

DROP TABLE IF EXISTS `installation_changes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `installation_changes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_name` varchar(255) DEFAULT NULL,
  `column_name` varchar(255) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `value` text,
  `installation` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `latest_obx_records`
--

DROP TABLE IF EXISTS `latest_obx_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `latest_obx_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `loinc_num` varchar(255) DEFAULT NULL,
  `first_obx_id` int(11) DEFAULT NULL,
  `last_obx_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `latest_obx_records_uniq_id_lnum` (`profile_id`,`loinc_num`)
) ENGINE=InnoDB AUTO_INCREMENT=4369 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `list_answers`
--

DROP TABLE IF EXISTS `list_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `list_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `answer_list_id` int(11) DEFAULT NULL,
  `answer_id` int(11) DEFAULT NULL,
  `code_ref` varchar(255) DEFAULT NULL,
  `sequence_num` int(11) DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11219 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `list_descriptions`
--

DROP TABLE IF EXISTS `list_descriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `list_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `display_name` varchar(255) DEFAULT NULL,
  `item_master_table` varchar(255) DEFAULT NULL,
  `item_name_field` varchar(255) DEFAULT NULL,
  `item_code_field` varchar(255) DEFAULT NULL,
  `list_master_table` varchar(255) DEFAULT NULL,
  `list_identifier` varchar(255) DEFAULT NULL,
  `list_conditions` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `list_details`
--

DROP TABLE IF EXISTS `list_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `list_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `display_name` varchar(255) DEFAULT NULL,
  `control_type_template` varchar(255) DEFAULT NULL,
  `id_column` varchar(255) DEFAULT NULL,
  `text_column` varchar(255) DEFAULT NULL,
  `hl7_id` varchar(255) DEFAULT NULL,
  `id_header` varchar(255) DEFAULT NULL,
  `text_header` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1013 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `locks`
--

DROP TABLE IF EXISTS `locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_name` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_locks_on_resource_name` (`resource_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loinc_field_rules`
--

DROP TABLE IF EXISTS `loinc_field_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `loinc_field_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_description_id` int(11) DEFAULT NULL,
  `loinc_item_id` int(11) DEFAULT NULL,
  `rule_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1741 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loinc_items`
--

DROP TABLE IF EXISTS `loinc_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `loinc_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `loinc_num` varchar(7) DEFAULT NULL,
  `component` varchar(255) DEFAULT NULL,
  `property` varchar(255) DEFAULT NULL,
  `time_aspct` varchar(255) DEFAULT NULL,
  `loinc_system` varchar(255) DEFAULT NULL,
  `scale_typ` varchar(255) DEFAULT NULL,
  `method_typ` varchar(255) DEFAULT NULL,
  `shortname` varchar(255) DEFAULT NULL,
  `long_common_name` varchar(255) DEFAULT NULL,
  `datatype` varchar(255) DEFAULT NULL,
  `relatednames2` varchar(4000) DEFAULT NULL,
  `related_names` varchar(255) DEFAULT NULL,
  `base_name` varchar(255) DEFAULT NULL,
  `unitsrequired` varchar(255) DEFAULT NULL,
  `example_units` varchar(255) DEFAULT NULL,
  `norm_range` varchar(255) DEFAULT NULL,
  `loinc_class` varchar(255) DEFAULT NULL,
  `common_tests` varchar(255) DEFAULT NULL,
  `classtype` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `map_to` varchar(255) DEFAULT NULL,
  `answerlist_id` int(11) DEFAULT NULL,
  `loinc_version` varchar(10) DEFAULT NULL,
  `phr_display_name` varchar(255) DEFAULT NULL,
  `consumer_name` varchar(255) DEFAULT NULL,
  `help_url` varchar(255) DEFAULT NULL,
  `help_text` varchar(255) DEFAULT NULL,
  `hl7_v2_type` varchar(255) DEFAULT NULL,
  `hl7_v3_type` varchar(255) DEFAULT NULL,
  `curated_range_and_units` varchar(255) DEFAULT NULL,
  `is_panel` tinyint(1) DEFAULT '0',
  `has_top_level_panel` tinyint(1) DEFAULT '0',
  `excluded_from_phr` tinyint(1) DEFAULT '0',
  `included_in_phr` tinyint(1) DEFAULT '0',
  `is_searchable` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_loinc_items_on_loinc_num` (`loinc_num`),
  KEY `loinc_items_loinc_num_index` (`loinc_num`)
) ENGINE=InnoDB AUTO_INCREMENT=59112 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loinc_names`
--

DROP TABLE IF EXISTS `loinc_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `loinc_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `loinc_num` varchar(255) DEFAULT NULL,
  `loinc_num_w_type` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `display_name_w_type` varchar(255) DEFAULT NULL,
  `type_code` int(11) DEFAULT NULL,
  `type_name` varchar(255) DEFAULT NULL,
  `component` varchar(255) DEFAULT NULL,
  `short_name` varchar(255) DEFAULT NULL,
  `long_common_name` varchar(255) DEFAULT NULL,
  `related_names` varchar(255) DEFAULT NULL,
  `consumer_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_loinc_names_on_loinc_num` (`loinc_num`),
  KEY `loinc_names_loinc_num_index` (`loinc_num`)
) ENGINE=InnoDB AUTO_INCREMENT=6069 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loinc_panels`
--

DROP TABLE IF EXISTS `loinc_panels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `loinc_panels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `p_id` int(11) DEFAULT NULL,
  `loinc_item_id` int(11) DEFAULT NULL,
  `loinc_num` varchar(7) DEFAULT NULL,
  `sequence_num` int(11) DEFAULT NULL,
  `observation_required_in_panel` varchar(1) DEFAULT NULL,
  `answer_required` tinyint(1) DEFAULT NULL,
  `type_of_entry` varchar(1) DEFAULT NULL,
  `default_value` varchar(255) DEFAULT NULL,
  `observation_required_in_phr` varchar(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `loinc_panels_loinc_num_index` (`loinc_num`),
  KEY `index_loinc_panels_on_p_id` (`p_id`)
) ENGINE=InnoDB AUTO_INCREMENT=21315 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loinc_units`
--

DROP TABLE IF EXISTS `loinc_units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `loinc_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `loinc_item_id` int(11) DEFAULT NULL,
  `loinc_num` varchar(7) DEFAULT NULL,
  `unit` varchar(255) DEFAULT NULL,
  `norm_range` varchar(255) DEFAULT NULL,
  `norm_high` varchar(255) DEFAULT NULL,
  `norm_low` varchar(255) DEFAULT NULL,
  `danger_high` varchar(255) DEFAULT NULL,
  `danger_low` varchar(255) DEFAULT NULL,
  `source_type` varchar(255) DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `loinc_units_loinc_num_index` (`loinc_num`)
) ENGINE=InnoDB AUTO_INCREMENT=5927 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mplus_drugs`
--

DROP TABLE IF EXISTS `mplus_drugs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mplus_drugs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `urlid` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `name_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_mplus_drugs_on_urlid_and_name_type` (`urlid`,`name_type`)
) ENGINE=InnoDB AUTO_INCREMENT=4269 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `obr_orders`
--

DROP TABLE IF EXISTS `obr_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `obr_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `obr2_placer_order_number` varchar(255) DEFAULT NULL,
  `obr3_filler_order_number` varchar(255) DEFAULT NULL,
  `obr4_service_ident` varchar(255) DEFAULT NULL,
  `obr13_relevant_clinical_info` varchar(255) DEFAULT NULL,
  `obr36_scheduled_datetime` varchar(255) DEFAULT NULL,
  `loinc_num` varchar(255) DEFAULT NULL,
  `test_place` varchar(255) DEFAULT NULL,
  `test_date` varchar(255) DEFAULT NULL,
  `test_date_ET` bigint(20) DEFAULT NULL,
  `test_date_HL7` varchar(255) DEFAULT NULL,
  `summary` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `panel_name` varchar(255) DEFAULT NULL,
  `test_date_time` varchar(255) DEFAULT NULL,
  `single_test` tinyint(1) DEFAULT '0',
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `obr_orders_loinc_num_index` (`loinc_num`),
  KEY `index_obr_orders_on_profile_id` (`profile_id`),
  KEY `index_obr_orders_on_test_date_hl7` (`test_date_HL7`)
) ENGINE=InnoDB AUTO_INCREMENT=2780 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER maintain_max_id_after_delete_on_obr_orders
BEFORE DELETE on obr_orders
FOR EACH ROW
BEGIN
  DECLARE max_id INT;
  DECLARE auto_rec_count INT;
  DECLARE stored_auto_inc_val INT;
  DECLARE new_auto_inc_val INT;
  SELECT max(id) INTO max_id FROM obr_orders;
  IF OLD.id = max_id THEN
    SET new_auto_inc_val = max_id + 1;
    
    SELECT count(*) FROM auto_increments WHERE table_name='obr_orders' INTO auto_rec_count; 
    IF auto_rec_count != 0 THEN
      SELECT min_auto_increment from auto_increments WHERE table_name='obr_orders' INTO stored_auto_inc_val;
      IF new_auto_inc_val > stored_auto_inc_val THEN
        UPDATE auto_increments SET min_auto_increment=new_auto_inc_val WHERE table_name='obr_orders';
      END IF;
    ELSE
      INSERT INTO auto_increments SET table_name='obr_orders', min_auto_increment=new_auto_inc_val;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `obx_observations`
--

DROP TABLE IF EXISTS `obx_observations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `obx_observations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `obr_order_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `obx2_value_type` varchar(255) DEFAULT NULL,
  `obx3_1_obs_ident` varchar(255) DEFAULT NULL,
  `obx3_3_obs_ident` varchar(255) DEFAULT NULL,
  `obx3_2_obs_ident` varchar(255) DEFAULT NULL,
  `obx5_value` varchar(255) DEFAULT NULL,
  `obx5_1_value_if_coded` varchar(255) DEFAULT NULL,
  `obx5_3_value_if_coded` varchar(255) DEFAULT NULL,
  `obx5_value_if_text_report` text,
  `obx6_1_unit` varchar(255) DEFAULT NULL,
  `obx6_2_unit` varchar(255) DEFAULT NULL,
  `obx6_3_unit` varchar(255) DEFAULT NULL,
  `obx7_reference_ranges` varchar(255) DEFAULT NULL,
  `obx8_abnormal_flags` varchar(255) DEFAULT NULL,
  `obx11_result_status_code` varchar(10) DEFAULT NULL,
  `obx19_analysis_datetime` varchar(255) DEFAULT NULL,
  `obx23_performing_organization` varchar(255) DEFAULT NULL,
  `obx24_performing_address` varchar(255) DEFAULT NULL,
  `obx25_performing_director` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  `code_system` varchar(255) DEFAULT NULL,
  `loinc_num` varchar(255) DEFAULT NULL,
  `is_panel` tinyint(1) DEFAULT NULL,
  `test_date` varchar(255) DEFAULT NULL,
  `test_date_ET` bigint(20) DEFAULT NULL,
  `test_date_HL7` varchar(255) DEFAULT NULL,
  `test_normal_high` varchar(255) DEFAULT NULL,
  `test_normal_low` varchar(255) DEFAULT NULL,
  `required_in_panel` tinyint(1) DEFAULT NULL,
  `unit_code` varchar(255) DEFAULT NULL,
  `test_danger_high` varchar(255) DEFAULT NULL,
  `test_danger_low` varchar(255) DEFAULT NULL,
  `value_real` varchar(255) DEFAULT NULL,
  `last_value` varchar(255) DEFAULT NULL,
  `lastvalue_date` varchar(255) DEFAULT NULL,
  `last_date` varchar(255) DEFAULT NULL,
  `last_date_ET` bigint(20) DEFAULT NULL,
  `last_date_HL7` varchar(255) DEFAULT NULL,
  `is_panel_hdr` tinyint(1) DEFAULT NULL,
  `disp_level` int(11) DEFAULT NULL,
  `value_score` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `test_date_time` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `obx_observations_ln_index` (`loinc_num`),
  KEY `obx_observations_lastvalue_index` (`loinc_num`,`profile_id`,`obx5_value`,`test_date_ET`),
  KEY `obx_for_trigger_idx` (`profile_id`,`loinc_num`,`latest`,`obx5_value`,`test_date_ET`),
  KEY `index_obx_observations_on_obr_order_id` (`obr_order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14014 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER latest_obx_after_insert 
AFTER INSERT ON obx_observations
FOR EACH ROW
BEGIN
  DECLARE p_id_ INT;
  DECLARE l_num_ VARCHAR(255);

  DECLARE first_id INT;
  DECLARE last_id INT;
  DECLARE existing_rec_id INT;
  
  SET p_id_ = NEW.profile_id;
  SET l_num_ = NEW.loinc_num;

  
  SELECT id INTO first_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET ASC limit 1;

  
  SELECT id INTO last_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET DESC limit 1;

  
  SELECT id INTO existing_rec_id
  FROM latest_obx_records
  WHERE profile_id=p_id_ AND loinc_num=l_num_;

  
  IF existing_rec_id IS NULL
  THEN
    IF first_id IS NOT NULL AND last_id IS NOT NULL
    THEN
      INSERT INTO latest_obx_records (profile_id,loinc_num,first_obx_id,last_obx_id) VALUES(p_id_,l_num_,first_id,last_id);
    END IF;
  
  ELSE
    UPDATE latest_obx_records SET first_obx_id=first_id, last_obx_id=last_id WHERE id=existing_rec_id;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER latest_obx_after_update 
AFTER UPDATE ON obx_observations
FOR EACH ROW
BEGIN
  DECLARE p_id_ INT;
  DECLARE l_num_ VARCHAR(255);

  DECLARE first_id INT;
  DECLARE last_id INT;
  DECLARE existing_rec_id INT;
  
  SET p_id_ = NEW.profile_id;
  SET l_num_ = NEW.loinc_num;

  
  SELECT id INTO first_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET ASC limit 1;

  
  SELECT id INTO last_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET DESC limit 1;

  
  SELECT id INTO existing_rec_id
  FROM latest_obx_records
  WHERE profile_id=p_id_ AND loinc_num=l_num_;

  
  IF existing_rec_id IS NULL
  THEN
    IF first_id IS NOT NULL AND last_id IS NOT NULL
    THEN
      INSERT INTO latest_obx_records (profile_id,loinc_num,first_obx_id,last_obx_id) VALUES(p_id_,l_num_,first_id,last_id);
    END IF;
  
  ELSE
    UPDATE latest_obx_records SET first_obx_id=first_id, last_obx_id=last_id WHERE id=existing_rec_id;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER latest_obx_after_delete
AFTER DELETE ON obx_observations
FOR EACH ROW
BEGIN
  DECLARE p_id_ INT;
  DECLARE l_num_ VARCHAR(255);

  DECLARE first_id INT;
  DECLARE last_id INT;
  DECLARE existing_rec_id INT;
  
  SET p_id_ = OLD.profile_id;
  SET l_num_ = OLD.loinc_num;

  
  SELECT id INTO first_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET ASC limit 1;

  
  SELECT id INTO last_id
  FROM obx_observations
  WHERE profile_id = p_id_ AND loinc_num = l_num_ AND latest=1 AND obx5_value is not NULL
  ORDER BY test_date_ET DESC limit 1;

  
  SELECT id INTO existing_rec_id
  FROM latest_obx_records
  WHERE profile_id=p_id_ AND loinc_num=l_num_;

  
  IF existing_rec_id IS NULL
  THEN
    IF first_id IS NOT NULL AND last_id IS NOT NULL
    THEN
      INSERT INTO latest_obx_records (profile_id,loinc_num,first_obx_id,last_obx_id) VALUES(p_id_,l_num_,first_id,last_id);
    END IF;
  
  ELSE
    
    IF first_id IS NOT NULL AND last_id IS NOT NULL
    THEN
      UPDATE latest_obx_records SET first_obx_id=first_id, last_obx_id=last_id WHERE id=existing_rec_id;
    
    ELSE
      DELETE FROM latest_obx_records
      WHERE profile_id = p_id_ AND loinc_num = l_num_;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `open_id_auth_associations`
--

DROP TABLE IF EXISTS `open_id_auth_associations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `open_id_auth_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `issued` int(11) DEFAULT NULL,
  `lifetime` int(11) DEFAULT NULL,
  `handle` varchar(255) DEFAULT NULL,
  `assoc_type` varchar(255) DEFAULT NULL,
  `server_url` blob,
  `secret` blob,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `open_id_auth_nonces`
--

DROP TABLE IF EXISTS `open_id_auth_nonces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `open_id_auth_nonces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timestamp` int(11) NOT NULL,
  `server_url` varchar(255) DEFAULT NULL,
  `salt` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `page_load_times`
--

DROP TABLE IF EXISTS `page_load_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `page_load_times` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `remote_ip` varchar(255) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `when_recorded` datetime DEFAULT NULL,
  `load_time` int(11) DEFAULT NULL,
  `apache_time` int(11) DEFAULT NULL,
  `rails_time` int(11) DEFAULT NULL,
  `view_time` int(11) DEFAULT NULL,
  `db_time` int(11) DEFAULT NULL,
  `rails_mode` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=132 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_allergies`
--

DROP TABLE IF EXISTS `phr_allergies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_allergies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `reaction_C` varchar(255) DEFAULT NULL,
  `reaction_date_HL7` varchar(255) DEFAULT NULL,
  `reaction_date_ET` bigint(20) DEFAULT NULL,
  `allergy_name_C` varchar(255) DEFAULT NULL,
  `reaction_date` varchar(255) DEFAULT NULL,
  `reaction` varchar(2048) DEFAULT NULL,
  `allergy_name` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `allergy_comment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_allergies_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=273 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_conditions`
--

DROP TABLE IF EXISTS `phr_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `present` varchar(255) DEFAULT NULL,
  `when_started_HL7` varchar(255) DEFAULT NULL,
  `problem_C` varchar(255) DEFAULT NULL,
  `when_started_ET` bigint(20) DEFAULT NULL,
  `present_C` varchar(255) DEFAULT NULL,
  `prob_desc` varchar(2048) DEFAULT NULL,
  `problem` varchar(255) DEFAULT NULL,
  `when_started` varchar(255) DEFAULT NULL,
  `cond_stop` varchar(255) DEFAULT NULL,
  `cond_stop_ET` bigint(20) DEFAULT NULL,
  `cond_stop_HL7` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_problems_headers_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=679 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_doctor_questions`
--

DROP TABLE IF EXISTS `phr_doctor_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_doctor_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `question_status` varchar(255) DEFAULT NULL,
  `date_entered_ET` bigint(20) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `category_C` varchar(255) DEFAULT NULL,
  `question_status_C` varchar(255) DEFAULT NULL,
  `date_entered_HL7` varchar(255) DEFAULT NULL,
  `question_answer` varchar(2048) DEFAULT NULL,
  `question` varchar(2048) DEFAULT NULL,
  `date_entered` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_doctor_questions_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=178 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_drugs`
--

DROP TABLE IF EXISTS `phr_drugs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_drugs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `drug_strength_form_C` varchar(255) DEFAULT NULL,
  `why_stopped` varchar(255) DEFAULT NULL,
  `expire_date_ET` bigint(20) DEFAULT NULL,
  `drug_use_status` varchar(255) DEFAULT NULL,
  `expire_date_HL7` varchar(255) DEFAULT NULL,
  `drug_use_status_C` varchar(255) DEFAULT NULL,
  `name_and_route` varchar(255) DEFAULT NULL,
  `why_stopped_C` varchar(255) DEFAULT NULL,
  `expire_date` varchar(255) DEFAULT NULL,
  `drug_strength_form` varchar(255) DEFAULT NULL,
  `instructions` varchar(2048) DEFAULT NULL,
  `stopped_date` varchar(255) DEFAULT NULL,
  `stopped_date_ET` bigint(20) DEFAULT NULL,
  `stopped_date_HL7` varchar(255) DEFAULT NULL,
  `name_and_route_C` varchar(255) DEFAULT '',
  `drug_start` varchar(255) DEFAULT NULL,
  `drug_start_ET` bigint(20) DEFAULT NULL,
  `drug_start_HL7` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_drugs_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=696 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_immunizations`
--

DROP TABLE IF EXISTS `phr_immunizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_immunizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `vaccine_date_ET` bigint(20) DEFAULT NULL,
  `vaccine_date_HL7` varchar(255) DEFAULT NULL,
  `vaccine_date` varchar(255) DEFAULT NULL,
  `immune_duedate_HL7` varchar(255) DEFAULT NULL,
  `immune_name_C` varchar(255) DEFAULT NULL,
  `immune_duedate` varchar(255) DEFAULT NULL,
  `immune_name` varchar(255) DEFAULT NULL,
  `immune_duedate_ET` bigint(20) DEFAULT NULL,
  `imm_comment` varchar(2048) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_immunizations_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=177 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_medical_contacts`
--

DROP TABLE IF EXISTS `phr_medical_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_medical_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `medcon_type` varchar(255) DEFAULT NULL,
  `medcon_type_C` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `next_appt` varchar(255) DEFAULT NULL,
  `next_appt_ET` bigint(20) DEFAULT NULL,
  `next_appt_HL7` varchar(255) DEFAULT NULL,
  `comments` varchar(2048) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `next_appt_time` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_notes`
--

DROP TABLE IF EXISTS `phr_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `note_date` varchar(255) DEFAULT NULL,
  `note_date_ET` bigint(20) DEFAULT NULL,
  `note_date_HL7` varchar(255) DEFAULT NULL,
  `note_text` varchar(2048) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phr_surgical_histories`
--

DROP TABLE IF EXISTS `phr_surgical_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phr_surgical_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `surgery_comments` varchar(2048) DEFAULT NULL,
  `surgery_type` varchar(255) DEFAULT NULL,
  `surgery_when_HL7` varchar(255) DEFAULT NULL,
  `surgery_type_C` varchar(255) DEFAULT NULL,
  `surgery_when` varchar(255) DEFAULT NULL,
  `surgery_when_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phr_surgical_histories_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=136 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phrs`
--

DROP TABLE IF EXISTS `phrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `birth_date` varchar(255) DEFAULT NULL,
  `pregnant` varchar(255) DEFAULT NULL,
  `due_date_HL7` varchar(255) DEFAULT NULL,
  `pseudonym` varchar(255) DEFAULT NULL,
  `pregnant_C` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `birth_date_HL7` varchar(255) DEFAULT NULL,
  `race_or_ethnicity` varchar(255) DEFAULT NULL,
  `due_date` varchar(255) DEFAULT NULL,
  `gender_C` varchar(255) DEFAULT NULL,
  `birth_date_ET` bigint(20) DEFAULT NULL,
  `race_or_ethnicity_C` varchar(255) DEFAULT NULL,
  `due_date_ET` bigint(20) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_phrs_on_profile_id_and_latest` (`profile_id`,`latest`)
) ENGINE=InnoDB AUTO_INCREMENT=3700 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `predefined_conditions`
--

DROP TABLE IF EXISTS `predefined_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `predefined_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `condition_name` varchar(255) DEFAULT NULL,
  `field_type` varchar(255) DEFAULT NULL,
  `operator` varchar(255) DEFAULT NULL,
  `comparison_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `predefined_expressions`
--

DROP TABLE IF EXISTS `predefined_expressions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `predefined_expressions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `expression_name` varchar(255) DEFAULT NULL,
  `expression` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `predefined_fields`
--

DROP TABLE IF EXISTS `predefined_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `predefined_fields` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `predef_type` varchar(255) DEFAULT NULL,
  `field_type` varchar(255) DEFAULT NULL,
  `control_type` varchar(255) DEFAULT NULL,
  `regex_validator_id` varchar(255) DEFAULT NULL,
  `control_type_detail` varchar(255) DEFAULT NULL,
  `group_header_id` int(11) DEFAULT NULL,
  `order_in_group` int(11) DEFAULT NULL,
  `required_in_group` tinyint(1) DEFAULT NULL,
  `help_text` text,
  `internal_size` int(11) DEFAULT NULL,
  `default_value` varchar(255) DEFAULT NULL,
  `units_of_measure` varchar(255) DEFAULT NULL,
  `search_table` varchar(255) DEFAULT NULL,
  `list_params` varchar(255) DEFAULT NULL,
  `display_size` int(11) DEFAULT NULL,
  `form_builder` tinyint(1) NOT NULL,
  `hl7_code` varchar(255) DEFAULT NULL,
  `rails_data_type` varchar(255) DEFAULT NULL,
  `fb_map_field` varchar(255) DEFAULT NULL,
  `display_only` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `profiles`
--

DROP TABLE IF EXISTS `profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_shown` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `archived` tinyint(1) DEFAULT '0',
  `selected_panels` varchar(2000) DEFAULT NULL,
  `last_updated_at` datetime DEFAULT NULL,
  `reminders_created_on` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_profiles_on_id_shown` (`id_shown`)
) ENGINE=InnoDB AUTO_INCREMENT=3684 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER maintain_max_id_after_delete_on_profiles
BEFORE DELETE on profiles
FOR EACH ROW
BEGIN
  DECLARE max_id INT;
  DECLARE auto_rec_count INT;
  DECLARE stored_auto_inc_val INT;
  DECLARE new_auto_inc_val INT;
  SELECT max(id) INTO max_id FROM profiles;
  IF OLD.id = max_id THEN
    SET new_auto_inc_val = max_id + 1;
    
    SELECT count(*) FROM auto_increments WHERE table_name='profiles' INTO auto_rec_count; 
    IF auto_rec_count != 0 THEN
      SELECT min_auto_increment from auto_increments WHERE table_name='profiles' INTO stored_auto_inc_val;
      IF new_auto_inc_val > stored_auto_inc_val THEN
        UPDATE auto_increments SET min_auto_increment=new_auto_inc_val WHERE table_name='profiles';
      END IF;
    ELSE
      INSERT INTO auto_increments SET table_name='profiles', min_auto_increment=new_auto_inc_val;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `profiles_users`
--

DROP TABLE IF EXISTS `profiles_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `profiles_users` (
  `user_id` int(11) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `access_level` int(11) NOT NULL DEFAULT '1',
  KEY `index_profiles_users_on_user_id` (`user_id`),
  KEY `index_profiles_users_on_profile_id` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `question_answers`
--

DROP TABLE IF EXISTS `question_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `question_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `qtype` int(11) DEFAULT NULL,
  `question` varchar(255) DEFAULT NULL,
  `answer` varchar(255) DEFAULT NULL,
  `asked` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=612 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regex_validators`
--

DROP TABLE IF EXISTS `regex_validators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regex_validators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `regex` varchar(255) DEFAULT NULL,
  `normalized_format` varchar(255) DEFAULT NULL,
  `error_message` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reminder_options`
--

DROP TABLE IF EXISTS `reminder_options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reminder_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `latest` tinyint(1) DEFAULT NULL,
  `db_table_description_id` int(11) DEFAULT NULL,
  `reminder_type` varchar(255) DEFAULT NULL,
  `item_column` varchar(255) DEFAULT NULL,
  `due_date_column` varchar(255) DEFAULT NULL,
  `due_date_type` varchar(255) DEFAULT NULL,
  `cutoff_days` int(11) DEFAULT NULL,
  `query_condition` varchar(255) DEFAULT NULL,
  `version_date` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=240 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `research_data`
--

DROP TABLE IF EXISTS `research_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `research_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `session_id` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `event_start` datetime DEFAULT NULL,
  `event_stop` datetime DEFAULT NULL,
  `event_time` datetime DEFAULT NULL,
  `captcha_mode` varchar(255) DEFAULT NULL,
  `captcha_source` varchar(255) DEFAULT NULL,
  `captcha_type` varchar(255) DEFAULT NULL,
  `login_old_session` varchar(255) DEFAULT NULL,
  `logout_type` varchar(255) DEFAULT NULL,
  `info_url` varchar(255) DEFAULT NULL,
  `form_name` varchar(255) DEFAULT NULL,
  `form_title` varchar(255) DEFAULT NULL,
  `reminder_url` varchar(255) DEFAULT NULL,
  `reminder_topic` varchar(255) DEFAULT NULL,
  `list_field_id` varchar(255) DEFAULT NULL,
  `list_start_val` varchar(255) DEFAULT NULL,
  `list_val_typed_in` varchar(255) DEFAULT NULL,
  `list_final_val` varchar(255) DEFAULT NULL,
  `list_input_method` varchar(255) DEFAULT NULL,
  `list_displayed_list` varchar(255) DEFAULT NULL,
  `list_used_list` tinyint(1) DEFAULT NULL,
  `list_on_list` tinyint(1) DEFAULT NULL,
  `list_expansion_method` varchar(255) DEFAULT NULL,
  `list_dup_warning` varchar(255) DEFAULT NULL,
  `list_suggestion_list` varchar(255) DEFAULT NULL,
  `list_used_suggestion` tinyint(1) DEFAULT NULL,
  `list_escape_key` tinyint(1) DEFAULT NULL,
  `list_scenario` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reviewed_reminders`
--

DROP TABLE IF EXISTS `reviewed_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reviewed_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) DEFAULT NULL,
  `reminder` text,
  `latest` tinyint(1) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `id_shown` varchar(255) DEFAULT NULL,
  `msg_key` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `routes`
--

DROP TABLE IF EXISTS `routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `routes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_action_descriptions`
--

DROP TABLE IF EXISTS `rule_action_descriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_action_descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `function_name` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `FFAR_only` tinyint(1) DEFAULT '0',
  `description` text,
  `tooltip` varchar(255) DEFAULT NULL,
  `parameters` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_actions`
--

DROP TABLE IF EXISTS `rule_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action` varchar(255) DEFAULT NULL,
  `parameters` varchar(4000) DEFAULT NULL,
  `affected_field` varchar(255) DEFAULT NULL,
  `rule_part_id` int(11) DEFAULT NULL,
  `rule_part_type` varchar(255) DEFAULT NULL,
  `action_C` varchar(255) DEFAULT NULL,
  `affected_field_C` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rule_actions_on_rule_part_id_and_rule_part_type` (`rule_part_id`,`rule_part_type`)
) ENGINE=InnoDB AUTO_INCREMENT=718 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_cases`
--

DROP TABLE IF EXISTS `rule_cases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_cases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_id` int(11) DEFAULT NULL,
  `sequence_num` int(11) DEFAULT NULL,
  `case_expression` varchar(255) DEFAULT NULL,
  `computed_value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=413 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_db_field_dependencies`
--

DROP TABLE IF EXISTS `rule_db_field_dependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_db_field_dependencies` (
  `db_field_description_id` int(11) DEFAULT NULL,
  `rule_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_dependencies`
--

DROP TABLE IF EXISTS `rule_dependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_dependencies` (
  `used_by_rule_id` int(11) DEFAULT NULL,
  `rule_id` int(11) DEFAULT NULL,
  KEY `index_rule_dependencies_on_rule_id` (`rule_id`),
  KEY `index_rule_dependencies_on_used_by_rule_id` (`used_by_rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_fetch_conditions`
--

DROP TABLE IF EXISTS `rule_fetch_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_fetch_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_fetch_id` int(11) DEFAULT NULL,
  `condition_type` varchar(255) DEFAULT NULL,
  `source_field` varchar(255) DEFAULT NULL,
  `source_field_C` varchar(255) DEFAULT NULL,
  `operator_1` varchar(255) DEFAULT NULL,
  `operator_1_C` int(11) DEFAULT NULL,
  `operator_2` varchar(255) DEFAULT NULL,
  `operator_2_C` varchar(255) DEFAULT NULL,
  `non_date_condition_value` varchar(255) DEFAULT NULL,
  `condition_date` date DEFAULT NULL,
  `condition_date_ET` bigint(20) DEFAULT NULL,
  `condition_date_HL7` varchar(255) DEFAULT NULL,
  `non_date_condition_value_C` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rule_fetch_conditions_on_rule_fetch_id` (`rule_fetch_id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_fetches`
--

DROP TABLE IF EXISTS `rule_fetches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_fetches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_id` int(11) DEFAULT NULL,
  `source_table` varchar(255) DEFAULT NULL,
  `source_table_C` int(11) DEFAULT NULL,
  `comparison_basis` varchar(255) DEFAULT NULL,
  `comparison_basis_C` varchar(255) DEFAULT NULL,
  `executable_fetch_query_ar` varchar(255) DEFAULT NULL,
  `executable_fetch_query_js` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rule_fetches_on_source_table_C` (`source_table_C`)
) ENGINE=InnoDB AUTO_INCREMENT=113 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_field_dependencies`
--

DROP TABLE IF EXISTS `rule_field_dependencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_field_dependencies` (
  `used_by_rule_id` int(11) DEFAULT NULL,
  `field_description_id` int(11) DEFAULT NULL,
  KEY `index_rule_field_dependencies_on_used_by_rule_id` (`used_by_rule_id`),
  KEY `index_rule_field_dependencies_on_field_description_id` (`field_description_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_labels`
--

DROP TABLE IF EXISTS `rule_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_labels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `rule_type` varchar(255) DEFAULT NULL,
  `rule_name` varchar(255) DEFAULT NULL,
  `rule_id` int(11) DEFAULT NULL,
  `property` varchar(255) DEFAULT NULL,
  `expression_text` varchar(255) DEFAULT NULL,
  `rule_name_C` int(11) DEFAULT NULL,
  `property_C` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=752 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rule_sets`
--

DROP TABLE IF EXISTS `rule_sets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rule_sets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `content` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rules`
--

DROP TABLE IF EXISTS `rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `expression` text,
  `js_function` text,
  `rule_type` int(11) DEFAULT '1',
  `editable` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_rules_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=671 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rules_forms`
--

DROP TABLE IF EXISTS `rules_forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rules_forms` (
  `form_id` int(11) DEFAULT NULL,
  `rule_id` int(11) DEFAULT NULL,
  KEY `index_rules_forms_on_form_id` (`form_id`),
  KEY `index_rules_forms_on_rule_id` (`rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rxhub_frequencies`
--

DROP TABLE IF EXISTS `rxhub_frequencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rxhub_frequencies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rxcui` int(11) DEFAULT NULL,
  `acc_count` int(11) DEFAULT NULL,
  `tty` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `strength` varchar(255) DEFAULT NULL,
  `new_dose_form` varchar(255) DEFAULT NULL,
  `display_name_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rxhub_frequencies_on_rxcui` (`rxcui`)
) ENGINE=InnoDB AUTO_INCREMENT=7084 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rxnorm_relations`
--

DROP TABLE IF EXISTS `rxnorm_relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rxnorm_relations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rxcui` varchar(255) DEFAULT NULL,
  `rxcui_type` varchar(255) DEFAULT NULL,
  `s_rxcui` varchar(255) DEFAULT NULL,
  `s_rxcui_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rxnorm_relations_on_rxcui_and_rxcui_type` (`rxcui`,`rxcui_type`)
) ENGINE=InnoDB AUTO_INCREMENT=31017 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rxnorm_to_mplus_drugs`
--

DROP TABLE IF EXISTS `rxnorm_to_mplus_drugs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rxnorm_to_mplus_drugs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rxcui` varchar(255) DEFAULT NULL,
  `urlid` varchar(255) DEFAULT NULL,
  `mplus_page_title` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rxnorm_to_mplus_drugs_on_rxcui` (`rxcui`)
) ENGINE=InnoDB AUTO_INCREMENT=33628 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rxterms_ingredients`
--

DROP TABLE IF EXISTS `rxterms_ingredients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rxterms_ingredients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `ing_rxcui` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `in_current_list` tinyint(1) DEFAULT '1',
  `code_is_old` tinyint(1) DEFAULT '0',
  `old_codes` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `index_rxterms_ingredients_on_ing_rxcui` (`ing_rxcui`),
  KEY `index_rxterms_ingredients_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=42954 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sample_texts`
--

DROP TABLE IF EXISTS `sample_texts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sample_texts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `field_id` int(11) DEFAULT NULL,
  `field_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `share_invitations`
--

DROP TABLE IF EXISTS `share_invitations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `share_invitations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `issuing_user_id` int(11) NOT NULL,
  `target_user_id` int(11) DEFAULT NULL,
  `target_email` varchar(255) NOT NULL,
  `date_issued` datetime NOT NULL,
  `expiration_date` datetime NOT NULL,
  `access_level` int(11) DEFAULT '3',
  `created_at` datetime DEFAULT NULL,
  `date_responded` datetime DEFAULT NULL,
  `issuer_name` varchar(255) NOT NULL,
  `target_name` varchar(255) NOT NULL,
  `response` varchar(255) DEFAULT NULL,
  `accept_key` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_share_invitations_on_accept_key` (`accept_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_errors`
--

DROP TABLE IF EXISTS `system_errors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `system_errors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `remote_ip` varchar(255) DEFAULT NULL,
  `exception` text,
  `count` int(11) DEFAULT '1',
  `last_email_time` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `referrer` varchar(255) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `is_browser_error` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `text_list_items`
--

DROP TABLE IF EXISTS `text_list_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `text_list_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text_list_id` int(11) DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `item_text` varchar(255) DEFAULT NULL,
  `item_help` varchar(1024) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `parent_item_id` int(11) DEFAULT NULL,
  `info_link` varchar(255) DEFAULT NULL,
  `sequence_num` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_text_list_items_on_text_list_id` (`text_list_id`),
  KEY `index_text_list_items_on_parent_item_id` (`parent_item_id`),
  KEY `index_text_list_items_on_code_and_text_list_id` (`code`,`text_list_id`),
  KEY `index_text_list_items_on_parent_item_id_and_code` (`parent_item_id`,`code`)
) ENGINE=InnoDB AUTO_INCREMENT=26828 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `text_lists`
--

DROP TABLE IF EXISTS `text_lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `text_lists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `list_name` varchar(255) DEFAULT NULL,
  `list_description` varchar(255) DEFAULT NULL,
  `list_label` varchar(255) DEFAULT NULL,
  `code_system` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_text_lists_on_list_name` (`list_name`)
) ENGINE=InnoDB AUTO_INCREMENT=148 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `text_templates`
--

DROP TABLE IF EXISTS `text_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `text_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `two_factors`
--

DROP TABLE IF EXISTS `two_factors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `two_factors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `cookie` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=517 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `united_health_frequencies`
--

DROP TABLE IF EXISTS `united_health_frequencies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `united_health_frequencies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rxcui` int(11) DEFAULT NULL,
  `generic_rxcui` int(11) DEFAULT NULL,
  `rxcui_count` int(11) DEFAULT NULL,
  `display_name_count` int(11) DEFAULT NULL,
  `tty` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_united_health_frequencies_on_rxcui` (`rxcui`)
) ENGINE=InnoDB AUTO_INCREMENT=26711 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usage_report_details`
--

DROP TABLE IF EXISTS `usage_report_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usage_report_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usage_report_id` int(11) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `event_time` datetime DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `data` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9157 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usage_reports`
--

DROP TABLE IF EXISTS `usage_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usage_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `storage_time` datetime DEFAULT NULL,
  `session_id` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `form_name` varchar(255) DEFAULT NULL,
  `exported` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8173 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usage_stats`
--

DROP TABLE IF EXISTS `usage_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usage_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `session_id` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `event_time` datetime(6) DEFAULT NULL,
  `data` text,
  `exported` tinyint(1) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_preferences`
--

DROP TABLE IF EXISTS `user_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `pref_key` varchar(255) DEFAULT NULL,
  `pref_value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `userid_guess_trials`
--

DROP TABLE IF EXISTS `userid_guess_trials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `userid_guess_trials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `trial` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `hashed_password` varchar(255) DEFAULT NULL,
  `salt` varchar(255) DEFAULT NULL,
  `admin` tinyint(1) DEFAULT NULL,
  `user_id` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `identity_url` varchar(255) DEFAULT NULL,
  `usertype` int(11) DEFAULT NULL,
  `answered` int(11) DEFAULT NULL,
  `password_trial` int(11) DEFAULT NULL,
  `lasttrial_at` datetime DEFAULT NULL,
  `account_type` varchar(1) DEFAULT 'R',
  `created_on` date DEFAULT NULL,
  `expiration_date` date DEFAULT NULL,
  `reset_key` varchar(255) DEFAULT NULL,
  `last_reset` datetime DEFAULT NULL,
  `reset_trial` int(11) DEFAULT NULL,
  `birth_date` varchar(255) DEFAULT NULL,
  `birth_date_HL7` varchar(255) DEFAULT NULL,
  `birth_date_ET` varchar(255) DEFAULT NULL,
  `pin` varchar(4) DEFAULT NULL,
  `answer_trial` smallint(6) DEFAULT NULL,
  `last_answer_trial_at` datetime DEFAULT NULL,
  `last_email_reminder` date DEFAULT NULL,
  `total_data_size` int(11) DEFAULT '0',
  `daily_data_size` int(11) DEFAULT '0',
  `daily_size_date` date DEFAULT '2000-01-01',
  `limit_lock` tinyint(1) DEFAULT '0',
  `used_for_demo` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_email` (`email`),
  UNIQUE KEY `index_users_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=129 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`lmericle`@`130.14.%`*/ /*!50003 TRIGGER maintain_max_id_after_delete_on_users
BEFORE DELETE on users
FOR EACH ROW
BEGIN
  DECLARE max_id INT;
  DECLARE auto_rec_count INT;
  DECLARE stored_auto_inc_val INT;
  DECLARE new_auto_inc_val INT;
  SELECT max(id) INTO max_id FROM users;
  IF OLD.id = max_id THEN
    SET new_auto_inc_val = max_id + 1;
    
    SELECT count(*) FROM auto_increments WHERE table_name='users' INTO auto_rec_count; 
    IF auto_rec_count != 0 THEN
      SELECT min_auto_increment from auto_increments WHERE table_name='users' INTO stored_auto_inc_val;
      IF new_auto_inc_val > stored_auto_inc_val THEN
        UPDATE auto_increments SET min_auto_increment=new_auto_inc_val WHERE table_name='users';
      END IF;
    ELSE
      INSERT INTO auto_increments SET table_name='users', min_auto_increment=new_auto_inc_val;
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `vaccines`
--

DROP TABLE IF EXISTS `vaccines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vaccines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `synonyms` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `versions`
--

DROP TABLE IF EXISTS `versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) NOT NULL,
  `item_id` int(11) NOT NULL,
  `event` varchar(255) NOT NULL,
  `whodunnit` varchar(255) DEFAULT NULL,
  `object` text,
  `object_changes` text,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_versions_on_item_type_and_item_id` (`item_type`,`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=266 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `word_synonyms`
--

DROP TABLE IF EXISTS `word_synonyms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `word_synonyms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `synonym_set` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=325 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-09-18  9:19:42
INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('100');

INSERT INTO schema_migrations (version) VALUES ('1000');

INSERT INTO schema_migrations (version) VALUES ('1001');

INSERT INTO schema_migrations (version) VALUES ('1002');

INSERT INTO schema_migrations (version) VALUES ('1003');

INSERT INTO schema_migrations (version) VALUES ('1004');

INSERT INTO schema_migrations (version) VALUES ('1005');

INSERT INTO schema_migrations (version) VALUES ('1006');

INSERT INTO schema_migrations (version) VALUES ('1007');

INSERT INTO schema_migrations (version) VALUES ('1008');

INSERT INTO schema_migrations (version) VALUES ('1009');

INSERT INTO schema_migrations (version) VALUES ('101');

INSERT INTO schema_migrations (version) VALUES ('1010');

INSERT INTO schema_migrations (version) VALUES ('1011');

INSERT INTO schema_migrations (version) VALUES ('1012');

INSERT INTO schema_migrations (version) VALUES ('1013');

INSERT INTO schema_migrations (version) VALUES ('1014');

INSERT INTO schema_migrations (version) VALUES ('1015');

INSERT INTO schema_migrations (version) VALUES ('1016');

INSERT INTO schema_migrations (version) VALUES ('1017');

INSERT INTO schema_migrations (version) VALUES ('1018');

INSERT INTO schema_migrations (version) VALUES ('1019');

INSERT INTO schema_migrations (version) VALUES ('102');

INSERT INTO schema_migrations (version) VALUES ('1020');

INSERT INTO schema_migrations (version) VALUES ('1021');

INSERT INTO schema_migrations (version) VALUES ('1022');

INSERT INTO schema_migrations (version) VALUES ('1023');

INSERT INTO schema_migrations (version) VALUES ('1024');

INSERT INTO schema_migrations (version) VALUES ('1025');

INSERT INTO schema_migrations (version) VALUES ('1026');

INSERT INTO schema_migrations (version) VALUES ('1027');

INSERT INTO schema_migrations (version) VALUES ('1028');

INSERT INTO schema_migrations (version) VALUES ('1029');

INSERT INTO schema_migrations (version) VALUES ('103');

INSERT INTO schema_migrations (version) VALUES ('1030');

INSERT INTO schema_migrations (version) VALUES ('1031');

INSERT INTO schema_migrations (version) VALUES ('1032');

INSERT INTO schema_migrations (version) VALUES ('1033');

INSERT INTO schema_migrations (version) VALUES ('1034');

INSERT INTO schema_migrations (version) VALUES ('1035');

INSERT INTO schema_migrations (version) VALUES ('1036');

INSERT INTO schema_migrations (version) VALUES ('1037');

INSERT INTO schema_migrations (version) VALUES ('1038');

INSERT INTO schema_migrations (version) VALUES ('1039');

INSERT INTO schema_migrations (version) VALUES ('104');

INSERT INTO schema_migrations (version) VALUES ('1040');

INSERT INTO schema_migrations (version) VALUES ('1041');

INSERT INTO schema_migrations (version) VALUES ('1042');

INSERT INTO schema_migrations (version) VALUES ('1043');

INSERT INTO schema_migrations (version) VALUES ('1044');

INSERT INTO schema_migrations (version) VALUES ('1045');

INSERT INTO schema_migrations (version) VALUES ('1046');

INSERT INTO schema_migrations (version) VALUES ('1047');

INSERT INTO schema_migrations (version) VALUES ('1048');

INSERT INTO schema_migrations (version) VALUES ('1049');

INSERT INTO schema_migrations (version) VALUES ('105');

INSERT INTO schema_migrations (version) VALUES ('1050');

INSERT INTO schema_migrations (version) VALUES ('1051');

INSERT INTO schema_migrations (version) VALUES ('1052');

INSERT INTO schema_migrations (version) VALUES ('1053');

INSERT INTO schema_migrations (version) VALUES ('1054');

INSERT INTO schema_migrations (version) VALUES ('1055');

INSERT INTO schema_migrations (version) VALUES ('1056');

INSERT INTO schema_migrations (version) VALUES ('1057');

INSERT INTO schema_migrations (version) VALUES ('1058');

INSERT INTO schema_migrations (version) VALUES ('1059');

INSERT INTO schema_migrations (version) VALUES ('106');

INSERT INTO schema_migrations (version) VALUES ('1060');

INSERT INTO schema_migrations (version) VALUES ('1061');

INSERT INTO schema_migrations (version) VALUES ('1062');

INSERT INTO schema_migrations (version) VALUES ('1063');

INSERT INTO schema_migrations (version) VALUES ('1064');

INSERT INTO schema_migrations (version) VALUES ('1065');

INSERT INTO schema_migrations (version) VALUES ('1066');

INSERT INTO schema_migrations (version) VALUES ('1067');

INSERT INTO schema_migrations (version) VALUES ('1068');

INSERT INTO schema_migrations (version) VALUES ('1069');

INSERT INTO schema_migrations (version) VALUES ('107');

INSERT INTO schema_migrations (version) VALUES ('1070');

INSERT INTO schema_migrations (version) VALUES ('1071');

INSERT INTO schema_migrations (version) VALUES ('1072');

INSERT INTO schema_migrations (version) VALUES ('1073');

INSERT INTO schema_migrations (version) VALUES ('1074');

INSERT INTO schema_migrations (version) VALUES ('1075');

INSERT INTO schema_migrations (version) VALUES ('1076');

INSERT INTO schema_migrations (version) VALUES ('1077');

INSERT INTO schema_migrations (version) VALUES ('1078');

INSERT INTO schema_migrations (version) VALUES ('1079');

INSERT INTO schema_migrations (version) VALUES ('108');

INSERT INTO schema_migrations (version) VALUES ('1080');

INSERT INTO schema_migrations (version) VALUES ('1081');

INSERT INTO schema_migrations (version) VALUES ('1082');

INSERT INTO schema_migrations (version) VALUES ('1083');

INSERT INTO schema_migrations (version) VALUES ('1084');

INSERT INTO schema_migrations (version) VALUES ('1085');

INSERT INTO schema_migrations (version) VALUES ('1086');

INSERT INTO schema_migrations (version) VALUES ('1087');

INSERT INTO schema_migrations (version) VALUES ('1088');

INSERT INTO schema_migrations (version) VALUES ('1089');

INSERT INTO schema_migrations (version) VALUES ('109');

INSERT INTO schema_migrations (version) VALUES ('1090');

INSERT INTO schema_migrations (version) VALUES ('1091');

INSERT INTO schema_migrations (version) VALUES ('1092');

INSERT INTO schema_migrations (version) VALUES ('1093');

INSERT INTO schema_migrations (version) VALUES ('1094');

INSERT INTO schema_migrations (version) VALUES ('1095');

INSERT INTO schema_migrations (version) VALUES ('1096');

INSERT INTO schema_migrations (version) VALUES ('1097');

INSERT INTO schema_migrations (version) VALUES ('1098');

INSERT INTO schema_migrations (version) VALUES ('1099');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('110');

INSERT INTO schema_migrations (version) VALUES ('1100');

INSERT INTO schema_migrations (version) VALUES ('1101');

INSERT INTO schema_migrations (version) VALUES ('1102');

INSERT INTO schema_migrations (version) VALUES ('1103');

INSERT INTO schema_migrations (version) VALUES ('1104');

INSERT INTO schema_migrations (version) VALUES ('1105');

INSERT INTO schema_migrations (version) VALUES ('1106');

INSERT INTO schema_migrations (version) VALUES ('1107');

INSERT INTO schema_migrations (version) VALUES ('1108');

INSERT INTO schema_migrations (version) VALUES ('1109');

INSERT INTO schema_migrations (version) VALUES ('111');

INSERT INTO schema_migrations (version) VALUES ('1110');

INSERT INTO schema_migrations (version) VALUES ('1111');

INSERT INTO schema_migrations (version) VALUES ('1112');

INSERT INTO schema_migrations (version) VALUES ('1113');

INSERT INTO schema_migrations (version) VALUES ('1114');

INSERT INTO schema_migrations (version) VALUES ('1115');

INSERT INTO schema_migrations (version) VALUES ('1116');

INSERT INTO schema_migrations (version) VALUES ('1117');

INSERT INTO schema_migrations (version) VALUES ('1118');

INSERT INTO schema_migrations (version) VALUES ('1119');

INSERT INTO schema_migrations (version) VALUES ('112');

INSERT INTO schema_migrations (version) VALUES ('1120');

INSERT INTO schema_migrations (version) VALUES ('1121');

INSERT INTO schema_migrations (version) VALUES ('1122');

INSERT INTO schema_migrations (version) VALUES ('1123');

INSERT INTO schema_migrations (version) VALUES ('1124');

INSERT INTO schema_migrations (version) VALUES ('1125');

INSERT INTO schema_migrations (version) VALUES ('1126');

INSERT INTO schema_migrations (version) VALUES ('1127');

INSERT INTO schema_migrations (version) VALUES ('1128');

INSERT INTO schema_migrations (version) VALUES ('1129');

INSERT INTO schema_migrations (version) VALUES ('113');

INSERT INTO schema_migrations (version) VALUES ('1130');

INSERT INTO schema_migrations (version) VALUES ('1131');

INSERT INTO schema_migrations (version) VALUES ('1132');

INSERT INTO schema_migrations (version) VALUES ('1133');

INSERT INTO schema_migrations (version) VALUES ('1134');

INSERT INTO schema_migrations (version) VALUES ('1135');

INSERT INTO schema_migrations (version) VALUES ('1136');

INSERT INTO schema_migrations (version) VALUES ('1137');

INSERT INTO schema_migrations (version) VALUES ('1138');

INSERT INTO schema_migrations (version) VALUES ('1139');

INSERT INTO schema_migrations (version) VALUES ('114');

INSERT INTO schema_migrations (version) VALUES ('1140');

INSERT INTO schema_migrations (version) VALUES ('1141');

INSERT INTO schema_migrations (version) VALUES ('1142');

INSERT INTO schema_migrations (version) VALUES ('1143');

INSERT INTO schema_migrations (version) VALUES ('1144');

INSERT INTO schema_migrations (version) VALUES ('1145');

INSERT INTO schema_migrations (version) VALUES ('1146');

INSERT INTO schema_migrations (version) VALUES ('1147');

INSERT INTO schema_migrations (version) VALUES ('1148');

INSERT INTO schema_migrations (version) VALUES ('1149');

INSERT INTO schema_migrations (version) VALUES ('115');

INSERT INTO schema_migrations (version) VALUES ('1150');

INSERT INTO schema_migrations (version) VALUES ('1151');

INSERT INTO schema_migrations (version) VALUES ('1152');

INSERT INTO schema_migrations (version) VALUES ('1153');

INSERT INTO schema_migrations (version) VALUES ('1154');

INSERT INTO schema_migrations (version) VALUES ('1155');

INSERT INTO schema_migrations (version) VALUES ('1156');

INSERT INTO schema_migrations (version) VALUES ('1157');

INSERT INTO schema_migrations (version) VALUES ('1158');

INSERT INTO schema_migrations (version) VALUES ('1159');

INSERT INTO schema_migrations (version) VALUES ('116');

INSERT INTO schema_migrations (version) VALUES ('1160');

INSERT INTO schema_migrations (version) VALUES ('1161');

INSERT INTO schema_migrations (version) VALUES ('1162');

INSERT INTO schema_migrations (version) VALUES ('1163');

INSERT INTO schema_migrations (version) VALUES ('1164');

INSERT INTO schema_migrations (version) VALUES ('1165');

INSERT INTO schema_migrations (version) VALUES ('1166');

INSERT INTO schema_migrations (version) VALUES ('1167');

INSERT INTO schema_migrations (version) VALUES ('1168');

INSERT INTO schema_migrations (version) VALUES ('1169');

INSERT INTO schema_migrations (version) VALUES ('117');

INSERT INTO schema_migrations (version) VALUES ('1170');

INSERT INTO schema_migrations (version) VALUES ('1171');

INSERT INTO schema_migrations (version) VALUES ('1172');

INSERT INTO schema_migrations (version) VALUES ('1173');

INSERT INTO schema_migrations (version) VALUES ('1174');

INSERT INTO schema_migrations (version) VALUES ('1175');

INSERT INTO schema_migrations (version) VALUES ('1176');

INSERT INTO schema_migrations (version) VALUES ('1177');

INSERT INTO schema_migrations (version) VALUES ('1178');

INSERT INTO schema_migrations (version) VALUES ('1179');

INSERT INTO schema_migrations (version) VALUES ('118');

INSERT INTO schema_migrations (version) VALUES ('1180');

INSERT INTO schema_migrations (version) VALUES ('1181');

INSERT INTO schema_migrations (version) VALUES ('1182');

INSERT INTO schema_migrations (version) VALUES ('1183');

INSERT INTO schema_migrations (version) VALUES ('1184');

INSERT INTO schema_migrations (version) VALUES ('1185');

INSERT INTO schema_migrations (version) VALUES ('1186');

INSERT INTO schema_migrations (version) VALUES ('1187');

INSERT INTO schema_migrations (version) VALUES ('1188');

INSERT INTO schema_migrations (version) VALUES ('1189');

INSERT INTO schema_migrations (version) VALUES ('119');

INSERT INTO schema_migrations (version) VALUES ('1190');

INSERT INTO schema_migrations (version) VALUES ('1191');

INSERT INTO schema_migrations (version) VALUES ('1192');

INSERT INTO schema_migrations (version) VALUES ('1193');

INSERT INTO schema_migrations (version) VALUES ('1194');

INSERT INTO schema_migrations (version) VALUES ('1195');

INSERT INTO schema_migrations (version) VALUES ('1196');

INSERT INTO schema_migrations (version) VALUES ('1197');

INSERT INTO schema_migrations (version) VALUES ('1198');

INSERT INTO schema_migrations (version) VALUES ('1199');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('120');

INSERT INTO schema_migrations (version) VALUES ('1200');

INSERT INTO schema_migrations (version) VALUES ('1201');

INSERT INTO schema_migrations (version) VALUES ('1202');

INSERT INTO schema_migrations (version) VALUES ('1203');

INSERT INTO schema_migrations (version) VALUES ('1204');

INSERT INTO schema_migrations (version) VALUES ('1205');

INSERT INTO schema_migrations (version) VALUES ('1206');

INSERT INTO schema_migrations (version) VALUES ('1207');

INSERT INTO schema_migrations (version) VALUES ('1208');

INSERT INTO schema_migrations (version) VALUES ('1209');

INSERT INTO schema_migrations (version) VALUES ('121');

INSERT INTO schema_migrations (version) VALUES ('1210');

INSERT INTO schema_migrations (version) VALUES ('1211');

INSERT INTO schema_migrations (version) VALUES ('1212');

INSERT INTO schema_migrations (version) VALUES ('1213');

INSERT INTO schema_migrations (version) VALUES ('1214');

INSERT INTO schema_migrations (version) VALUES ('1215');

INSERT INTO schema_migrations (version) VALUES ('1216');

INSERT INTO schema_migrations (version) VALUES ('1217');

INSERT INTO schema_migrations (version) VALUES ('1218');

INSERT INTO schema_migrations (version) VALUES ('1219');

INSERT INTO schema_migrations (version) VALUES ('122');

INSERT INTO schema_migrations (version) VALUES ('1220');

INSERT INTO schema_migrations (version) VALUES ('1221');

INSERT INTO schema_migrations (version) VALUES ('1222');

INSERT INTO schema_migrations (version) VALUES ('1223');

INSERT INTO schema_migrations (version) VALUES ('1224');

INSERT INTO schema_migrations (version) VALUES ('1225');

INSERT INTO schema_migrations (version) VALUES ('1226');

INSERT INTO schema_migrations (version) VALUES ('1227');

INSERT INTO schema_migrations (version) VALUES ('1228');

INSERT INTO schema_migrations (version) VALUES ('1229');

INSERT INTO schema_migrations (version) VALUES ('123');

INSERT INTO schema_migrations (version) VALUES ('1230');

INSERT INTO schema_migrations (version) VALUES ('1231');

INSERT INTO schema_migrations (version) VALUES ('1232');

INSERT INTO schema_migrations (version) VALUES ('1233');

INSERT INTO schema_migrations (version) VALUES ('1234');

INSERT INTO schema_migrations (version) VALUES ('1235');

INSERT INTO schema_migrations (version) VALUES ('1236');

INSERT INTO schema_migrations (version) VALUES ('1237');

INSERT INTO schema_migrations (version) VALUES ('1238');

INSERT INTO schema_migrations (version) VALUES ('1239');

INSERT INTO schema_migrations (version) VALUES ('124');

INSERT INTO schema_migrations (version) VALUES ('1240');

INSERT INTO schema_migrations (version) VALUES ('1241');

INSERT INTO schema_migrations (version) VALUES ('1242');

INSERT INTO schema_migrations (version) VALUES ('1243');

INSERT INTO schema_migrations (version) VALUES ('1244');

INSERT INTO schema_migrations (version) VALUES ('1245');

INSERT INTO schema_migrations (version) VALUES ('1246');

INSERT INTO schema_migrations (version) VALUES ('1247');

INSERT INTO schema_migrations (version) VALUES ('1248');

INSERT INTO schema_migrations (version) VALUES ('1249');

INSERT INTO schema_migrations (version) VALUES ('125');

INSERT INTO schema_migrations (version) VALUES ('1250');

INSERT INTO schema_migrations (version) VALUES ('1251');

INSERT INTO schema_migrations (version) VALUES ('1252');

INSERT INTO schema_migrations (version) VALUES ('1253');

INSERT INTO schema_migrations (version) VALUES ('1254');

INSERT INTO schema_migrations (version) VALUES ('1255');

INSERT INTO schema_migrations (version) VALUES ('1256');

INSERT INTO schema_migrations (version) VALUES ('1257');

INSERT INTO schema_migrations (version) VALUES ('1258');

INSERT INTO schema_migrations (version) VALUES ('1259');

INSERT INTO schema_migrations (version) VALUES ('126');

INSERT INTO schema_migrations (version) VALUES ('1260');

INSERT INTO schema_migrations (version) VALUES ('1261');

INSERT INTO schema_migrations (version) VALUES ('1262');

INSERT INTO schema_migrations (version) VALUES ('1263');

INSERT INTO schema_migrations (version) VALUES ('1264');

INSERT INTO schema_migrations (version) VALUES ('1265');

INSERT INTO schema_migrations (version) VALUES ('1266');

INSERT INTO schema_migrations (version) VALUES ('1267');

INSERT INTO schema_migrations (version) VALUES ('1268');

INSERT INTO schema_migrations (version) VALUES ('1269');

INSERT INTO schema_migrations (version) VALUES ('127');

INSERT INTO schema_migrations (version) VALUES ('1270');

INSERT INTO schema_migrations (version) VALUES ('1271');

INSERT INTO schema_migrations (version) VALUES ('1272');

INSERT INTO schema_migrations (version) VALUES ('1273');

INSERT INTO schema_migrations (version) VALUES ('1274');

INSERT INTO schema_migrations (version) VALUES ('1275');

INSERT INTO schema_migrations (version) VALUES ('1276');

INSERT INTO schema_migrations (version) VALUES ('1277');

INSERT INTO schema_migrations (version) VALUES ('1278');

INSERT INTO schema_migrations (version) VALUES ('1279');

INSERT INTO schema_migrations (version) VALUES ('128');

INSERT INTO schema_migrations (version) VALUES ('1280');

INSERT INTO schema_migrations (version) VALUES ('1281');

INSERT INTO schema_migrations (version) VALUES ('1282');

INSERT INTO schema_migrations (version) VALUES ('1283');

INSERT INTO schema_migrations (version) VALUES ('1284');

INSERT INTO schema_migrations (version) VALUES ('1285');

INSERT INTO schema_migrations (version) VALUES ('1286');

INSERT INTO schema_migrations (version) VALUES ('1287');

INSERT INTO schema_migrations (version) VALUES ('1288');

INSERT INTO schema_migrations (version) VALUES ('1289');

INSERT INTO schema_migrations (version) VALUES ('129');

INSERT INTO schema_migrations (version) VALUES ('1290');

INSERT INTO schema_migrations (version) VALUES ('1291');

INSERT INTO schema_migrations (version) VALUES ('1292');

INSERT INTO schema_migrations (version) VALUES ('1293');

INSERT INTO schema_migrations (version) VALUES ('1294');

INSERT INTO schema_migrations (version) VALUES ('1295');

INSERT INTO schema_migrations (version) VALUES ('1296');

INSERT INTO schema_migrations (version) VALUES ('1297');

INSERT INTO schema_migrations (version) VALUES ('1298');

INSERT INTO schema_migrations (version) VALUES ('1299');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('130');

INSERT INTO schema_migrations (version) VALUES ('1300');

INSERT INTO schema_migrations (version) VALUES ('1301');

INSERT INTO schema_migrations (version) VALUES ('1302');

INSERT INTO schema_migrations (version) VALUES ('1303');

INSERT INTO schema_migrations (version) VALUES ('1304');

INSERT INTO schema_migrations (version) VALUES ('1305');

INSERT INTO schema_migrations (version) VALUES ('1306');

INSERT INTO schema_migrations (version) VALUES ('1307');

INSERT INTO schema_migrations (version) VALUES ('1308');

INSERT INTO schema_migrations (version) VALUES ('1309');

INSERT INTO schema_migrations (version) VALUES ('131');

INSERT INTO schema_migrations (version) VALUES ('1310');

INSERT INTO schema_migrations (version) VALUES ('1311');

INSERT INTO schema_migrations (version) VALUES ('1312');

INSERT INTO schema_migrations (version) VALUES ('1313');

INSERT INTO schema_migrations (version) VALUES ('1314');

INSERT INTO schema_migrations (version) VALUES ('1315');

INSERT INTO schema_migrations (version) VALUES ('1316');

INSERT INTO schema_migrations (version) VALUES ('1317');

INSERT INTO schema_migrations (version) VALUES ('1318');

INSERT INTO schema_migrations (version) VALUES ('1319');

INSERT INTO schema_migrations (version) VALUES ('132');

INSERT INTO schema_migrations (version) VALUES ('1320');

INSERT INTO schema_migrations (version) VALUES ('1321');

INSERT INTO schema_migrations (version) VALUES ('1322');

INSERT INTO schema_migrations (version) VALUES ('1323');

INSERT INTO schema_migrations (version) VALUES ('1324');

INSERT INTO schema_migrations (version) VALUES ('1325');

INSERT INTO schema_migrations (version) VALUES ('1326');

INSERT INTO schema_migrations (version) VALUES ('1327');

INSERT INTO schema_migrations (version) VALUES ('1328');

INSERT INTO schema_migrations (version) VALUES ('1329');

INSERT INTO schema_migrations (version) VALUES ('133');

INSERT INTO schema_migrations (version) VALUES ('1330');

INSERT INTO schema_migrations (version) VALUES ('1331');

INSERT INTO schema_migrations (version) VALUES ('1332');

INSERT INTO schema_migrations (version) VALUES ('1333');

INSERT INTO schema_migrations (version) VALUES ('1334');

INSERT INTO schema_migrations (version) VALUES ('1335');

INSERT INTO schema_migrations (version) VALUES ('1336');

INSERT INTO schema_migrations (version) VALUES ('1337');

INSERT INTO schema_migrations (version) VALUES ('1338');

INSERT INTO schema_migrations (version) VALUES ('1339');

INSERT INTO schema_migrations (version) VALUES ('134');

INSERT INTO schema_migrations (version) VALUES ('1340');

INSERT INTO schema_migrations (version) VALUES ('1341');

INSERT INTO schema_migrations (version) VALUES ('1342');

INSERT INTO schema_migrations (version) VALUES ('1343');

INSERT INTO schema_migrations (version) VALUES ('1344');

INSERT INTO schema_migrations (version) VALUES ('1345');

INSERT INTO schema_migrations (version) VALUES ('1346');

INSERT INTO schema_migrations (version) VALUES ('1347');

INSERT INTO schema_migrations (version) VALUES ('1348');

INSERT INTO schema_migrations (version) VALUES ('1349');

INSERT INTO schema_migrations (version) VALUES ('135');

INSERT INTO schema_migrations (version) VALUES ('1350');

INSERT INTO schema_migrations (version) VALUES ('1351');

INSERT INTO schema_migrations (version) VALUES ('1352');

INSERT INTO schema_migrations (version) VALUES ('1353');

INSERT INTO schema_migrations (version) VALUES ('1354');

INSERT INTO schema_migrations (version) VALUES ('1355');

INSERT INTO schema_migrations (version) VALUES ('1356');

INSERT INTO schema_migrations (version) VALUES ('1357');

INSERT INTO schema_migrations (version) VALUES ('1358');

INSERT INTO schema_migrations (version) VALUES ('1359');

INSERT INTO schema_migrations (version) VALUES ('136');

INSERT INTO schema_migrations (version) VALUES ('1360');

INSERT INTO schema_migrations (version) VALUES ('1361');

INSERT INTO schema_migrations (version) VALUES ('1362');

INSERT INTO schema_migrations (version) VALUES ('1363');

INSERT INTO schema_migrations (version) VALUES ('1364');

INSERT INTO schema_migrations (version) VALUES ('1365');

INSERT INTO schema_migrations (version) VALUES ('1366');

INSERT INTO schema_migrations (version) VALUES ('1367');

INSERT INTO schema_migrations (version) VALUES ('1368');

INSERT INTO schema_migrations (version) VALUES ('1369');

INSERT INTO schema_migrations (version) VALUES ('137');

INSERT INTO schema_migrations (version) VALUES ('1370');

INSERT INTO schema_migrations (version) VALUES ('1371');

INSERT INTO schema_migrations (version) VALUES ('1372');

INSERT INTO schema_migrations (version) VALUES ('1373');

INSERT INTO schema_migrations (version) VALUES ('1374');

INSERT INTO schema_migrations (version) VALUES ('1375');

INSERT INTO schema_migrations (version) VALUES ('1376');

INSERT INTO schema_migrations (version) VALUES ('1377');

INSERT INTO schema_migrations (version) VALUES ('1378');

INSERT INTO schema_migrations (version) VALUES ('1379');

INSERT INTO schema_migrations (version) VALUES ('138');

INSERT INTO schema_migrations (version) VALUES ('1380');

INSERT INTO schema_migrations (version) VALUES ('1381');

INSERT INTO schema_migrations (version) VALUES ('1382');

INSERT INTO schema_migrations (version) VALUES ('1383');

INSERT INTO schema_migrations (version) VALUES ('1384');

INSERT INTO schema_migrations (version) VALUES ('1385');

INSERT INTO schema_migrations (version) VALUES ('1386');

INSERT INTO schema_migrations (version) VALUES ('1387');

INSERT INTO schema_migrations (version) VALUES ('1388');

INSERT INTO schema_migrations (version) VALUES ('1389');

INSERT INTO schema_migrations (version) VALUES ('139');

INSERT INTO schema_migrations (version) VALUES ('1390');

INSERT INTO schema_migrations (version) VALUES ('1391');

INSERT INTO schema_migrations (version) VALUES ('1392');

INSERT INTO schema_migrations (version) VALUES ('1393');

INSERT INTO schema_migrations (version) VALUES ('1394');

INSERT INTO schema_migrations (version) VALUES ('1395');

INSERT INTO schema_migrations (version) VALUES ('1396');

INSERT INTO schema_migrations (version) VALUES ('1397');

INSERT INTO schema_migrations (version) VALUES ('1398');

INSERT INTO schema_migrations (version) VALUES ('1399');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('140');

INSERT INTO schema_migrations (version) VALUES ('1400');

INSERT INTO schema_migrations (version) VALUES ('1401');

INSERT INTO schema_migrations (version) VALUES ('1402');

INSERT INTO schema_migrations (version) VALUES ('1403');

INSERT INTO schema_migrations (version) VALUES ('1404');

INSERT INTO schema_migrations (version) VALUES ('1405');

INSERT INTO schema_migrations (version) VALUES ('1406');

INSERT INTO schema_migrations (version) VALUES ('1407');

INSERT INTO schema_migrations (version) VALUES ('1408');

INSERT INTO schema_migrations (version) VALUES ('1409');

INSERT INTO schema_migrations (version) VALUES ('141');

INSERT INTO schema_migrations (version) VALUES ('1410');

INSERT INTO schema_migrations (version) VALUES ('1411');

INSERT INTO schema_migrations (version) VALUES ('1412');

INSERT INTO schema_migrations (version) VALUES ('1413');

INSERT INTO schema_migrations (version) VALUES ('1414');

INSERT INTO schema_migrations (version) VALUES ('1415');

INSERT INTO schema_migrations (version) VALUES ('1416');

INSERT INTO schema_migrations (version) VALUES ('1417');

INSERT INTO schema_migrations (version) VALUES ('1418');

INSERT INTO schema_migrations (version) VALUES ('1419');

INSERT INTO schema_migrations (version) VALUES ('142');

INSERT INTO schema_migrations (version) VALUES ('1420');

INSERT INTO schema_migrations (version) VALUES ('1421');

INSERT INTO schema_migrations (version) VALUES ('1422');

INSERT INTO schema_migrations (version) VALUES ('1423');

INSERT INTO schema_migrations (version) VALUES ('1424');

INSERT INTO schema_migrations (version) VALUES ('1425');

INSERT INTO schema_migrations (version) VALUES ('1427');

INSERT INTO schema_migrations (version) VALUES ('1428');

INSERT INTO schema_migrations (version) VALUES ('1429');

INSERT INTO schema_migrations (version) VALUES ('143');

INSERT INTO schema_migrations (version) VALUES ('1430');

INSERT INTO schema_migrations (version) VALUES ('1431');

INSERT INTO schema_migrations (version) VALUES ('1432');

INSERT INTO schema_migrations (version) VALUES ('1433');

INSERT INTO schema_migrations (version) VALUES ('1434');

INSERT INTO schema_migrations (version) VALUES ('1435');

INSERT INTO schema_migrations (version) VALUES ('1436');

INSERT INTO schema_migrations (version) VALUES ('1437');

INSERT INTO schema_migrations (version) VALUES ('1438');

INSERT INTO schema_migrations (version) VALUES ('1439');

INSERT INTO schema_migrations (version) VALUES ('144');

INSERT INTO schema_migrations (version) VALUES ('1440');

INSERT INTO schema_migrations (version) VALUES ('1441');

INSERT INTO schema_migrations (version) VALUES ('1442');

INSERT INTO schema_migrations (version) VALUES ('1443');

INSERT INTO schema_migrations (version) VALUES ('1444');

INSERT INTO schema_migrations (version) VALUES ('1445');

INSERT INTO schema_migrations (version) VALUES ('1446');

INSERT INTO schema_migrations (version) VALUES ('1447');

INSERT INTO schema_migrations (version) VALUES ('1448');

INSERT INTO schema_migrations (version) VALUES ('1449');

INSERT INTO schema_migrations (version) VALUES ('145');

INSERT INTO schema_migrations (version) VALUES ('1450');

INSERT INTO schema_migrations (version) VALUES ('1451');

INSERT INTO schema_migrations (version) VALUES ('1452');

INSERT INTO schema_migrations (version) VALUES ('1453');

INSERT INTO schema_migrations (version) VALUES ('1454');

INSERT INTO schema_migrations (version) VALUES ('1455');

INSERT INTO schema_migrations (version) VALUES ('1456');

INSERT INTO schema_migrations (version) VALUES ('1457');

INSERT INTO schema_migrations (version) VALUES ('1458');

INSERT INTO schema_migrations (version) VALUES ('1459');

INSERT INTO schema_migrations (version) VALUES ('146');

INSERT INTO schema_migrations (version) VALUES ('1460');

INSERT INTO schema_migrations (version) VALUES ('1461');

INSERT INTO schema_migrations (version) VALUES ('1462');

INSERT INTO schema_migrations (version) VALUES ('1463');

INSERT INTO schema_migrations (version) VALUES ('1464');

INSERT INTO schema_migrations (version) VALUES ('1465');

INSERT INTO schema_migrations (version) VALUES ('147');

INSERT INTO schema_migrations (version) VALUES ('148');

INSERT INTO schema_migrations (version) VALUES ('149');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('150');

INSERT INTO schema_migrations (version) VALUES ('151');

INSERT INTO schema_migrations (version) VALUES ('152');

INSERT INTO schema_migrations (version) VALUES ('153');

INSERT INTO schema_migrations (version) VALUES ('154');

INSERT INTO schema_migrations (version) VALUES ('155');

INSERT INTO schema_migrations (version) VALUES ('156');

INSERT INTO schema_migrations (version) VALUES ('157');

INSERT INTO schema_migrations (version) VALUES ('158');

INSERT INTO schema_migrations (version) VALUES ('159');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('160');

INSERT INTO schema_migrations (version) VALUES ('161');

INSERT INTO schema_migrations (version) VALUES ('162');

INSERT INTO schema_migrations (version) VALUES ('163');

INSERT INTO schema_migrations (version) VALUES ('164');

INSERT INTO schema_migrations (version) VALUES ('165');

INSERT INTO schema_migrations (version) VALUES ('166');

INSERT INTO schema_migrations (version) VALUES ('167');

INSERT INTO schema_migrations (version) VALUES ('168');

INSERT INTO schema_migrations (version) VALUES ('169');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('170');

INSERT INTO schema_migrations (version) VALUES ('171');

INSERT INTO schema_migrations (version) VALUES ('172');

INSERT INTO schema_migrations (version) VALUES ('173');

INSERT INTO schema_migrations (version) VALUES ('174');

INSERT INTO schema_migrations (version) VALUES ('175');

INSERT INTO schema_migrations (version) VALUES ('176');

INSERT INTO schema_migrations (version) VALUES ('177');

INSERT INTO schema_migrations (version) VALUES ('178');

INSERT INTO schema_migrations (version) VALUES ('179');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('180');

INSERT INTO schema_migrations (version) VALUES ('181');

INSERT INTO schema_migrations (version) VALUES ('182');

INSERT INTO schema_migrations (version) VALUES ('183');

INSERT INTO schema_migrations (version) VALUES ('184');

INSERT INTO schema_migrations (version) VALUES ('185');

INSERT INTO schema_migrations (version) VALUES ('186');

INSERT INTO schema_migrations (version) VALUES ('187');

INSERT INTO schema_migrations (version) VALUES ('188');

INSERT INTO schema_migrations (version) VALUES ('189');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('190');

INSERT INTO schema_migrations (version) VALUES ('191');

INSERT INTO schema_migrations (version) VALUES ('192');

INSERT INTO schema_migrations (version) VALUES ('193');

INSERT INTO schema_migrations (version) VALUES ('194');

INSERT INTO schema_migrations (version) VALUES ('195');

INSERT INTO schema_migrations (version) VALUES ('196');

INSERT INTO schema_migrations (version) VALUES ('197');

INSERT INTO schema_migrations (version) VALUES ('198');

INSERT INTO schema_migrations (version) VALUES ('199');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('200');

INSERT INTO schema_migrations (version) VALUES ('201');

INSERT INTO schema_migrations (version) VALUES ('202');

INSERT INTO schema_migrations (version) VALUES ('203');

INSERT INTO schema_migrations (version) VALUES ('204');

INSERT INTO schema_migrations (version) VALUES ('205');

INSERT INTO schema_migrations (version) VALUES ('206');

INSERT INTO schema_migrations (version) VALUES ('207');

INSERT INTO schema_migrations (version) VALUES ('208');

INSERT INTO schema_migrations (version) VALUES ('209');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('210');

INSERT INTO schema_migrations (version) VALUES ('211');

INSERT INTO schema_migrations (version) VALUES ('212');

INSERT INTO schema_migrations (version) VALUES ('213');

INSERT INTO schema_migrations (version) VALUES ('214');

INSERT INTO schema_migrations (version) VALUES ('215');

INSERT INTO schema_migrations (version) VALUES ('216');

INSERT INTO schema_migrations (version) VALUES ('217');

INSERT INTO schema_migrations (version) VALUES ('218');

INSERT INTO schema_migrations (version) VALUES ('219');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('220');

INSERT INTO schema_migrations (version) VALUES ('221');

INSERT INTO schema_migrations (version) VALUES ('222');

INSERT INTO schema_migrations (version) VALUES ('223');

INSERT INTO schema_migrations (version) VALUES ('224');

INSERT INTO schema_migrations (version) VALUES ('225');

INSERT INTO schema_migrations (version) VALUES ('226');

INSERT INTO schema_migrations (version) VALUES ('227');

INSERT INTO schema_migrations (version) VALUES ('228');

INSERT INTO schema_migrations (version) VALUES ('229');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('230');

INSERT INTO schema_migrations (version) VALUES ('231');

INSERT INTO schema_migrations (version) VALUES ('232');

INSERT INTO schema_migrations (version) VALUES ('233');

INSERT INTO schema_migrations (version) VALUES ('234');

INSERT INTO schema_migrations (version) VALUES ('235');

INSERT INTO schema_migrations (version) VALUES ('236');

INSERT INTO schema_migrations (version) VALUES ('237');

INSERT INTO schema_migrations (version) VALUES ('238');

INSERT INTO schema_migrations (version) VALUES ('239');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('240');

INSERT INTO schema_migrations (version) VALUES ('241');

INSERT INTO schema_migrations (version) VALUES ('242');

INSERT INTO schema_migrations (version) VALUES ('243');

INSERT INTO schema_migrations (version) VALUES ('244');

INSERT INTO schema_migrations (version) VALUES ('245');

INSERT INTO schema_migrations (version) VALUES ('246');

INSERT INTO schema_migrations (version) VALUES ('247');

INSERT INTO schema_migrations (version) VALUES ('248');

INSERT INTO schema_migrations (version) VALUES ('249');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('250');

INSERT INTO schema_migrations (version) VALUES ('251');

INSERT INTO schema_migrations (version) VALUES ('252');

INSERT INTO schema_migrations (version) VALUES ('253');

INSERT INTO schema_migrations (version) VALUES ('254');

INSERT INTO schema_migrations (version) VALUES ('255');

INSERT INTO schema_migrations (version) VALUES ('256');

INSERT INTO schema_migrations (version) VALUES ('257');

INSERT INTO schema_migrations (version) VALUES ('258');

INSERT INTO schema_migrations (version) VALUES ('259');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('260');

INSERT INTO schema_migrations (version) VALUES ('261');

INSERT INTO schema_migrations (version) VALUES ('262');

INSERT INTO schema_migrations (version) VALUES ('263');

INSERT INTO schema_migrations (version) VALUES ('264');

INSERT INTO schema_migrations (version) VALUES ('265');

INSERT INTO schema_migrations (version) VALUES ('266');

INSERT INTO schema_migrations (version) VALUES ('267');

INSERT INTO schema_migrations (version) VALUES ('268');

INSERT INTO schema_migrations (version) VALUES ('269');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('270');

INSERT INTO schema_migrations (version) VALUES ('271');

INSERT INTO schema_migrations (version) VALUES ('272');

INSERT INTO schema_migrations (version) VALUES ('273');

INSERT INTO schema_migrations (version) VALUES ('274');

INSERT INTO schema_migrations (version) VALUES ('275');

INSERT INTO schema_migrations (version) VALUES ('276');

INSERT INTO schema_migrations (version) VALUES ('277');

INSERT INTO schema_migrations (version) VALUES ('278');

INSERT INTO schema_migrations (version) VALUES ('279');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('280');

INSERT INTO schema_migrations (version) VALUES ('281');

INSERT INTO schema_migrations (version) VALUES ('282');

INSERT INTO schema_migrations (version) VALUES ('283');

INSERT INTO schema_migrations (version) VALUES ('284');

INSERT INTO schema_migrations (version) VALUES ('285');

INSERT INTO schema_migrations (version) VALUES ('286');

INSERT INTO schema_migrations (version) VALUES ('287');

INSERT INTO schema_migrations (version) VALUES ('288');

INSERT INTO schema_migrations (version) VALUES ('289');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('290');

INSERT INTO schema_migrations (version) VALUES ('291');

INSERT INTO schema_migrations (version) VALUES ('292');

INSERT INTO schema_migrations (version) VALUES ('293');

INSERT INTO schema_migrations (version) VALUES ('294');

INSERT INTO schema_migrations (version) VALUES ('295');

INSERT INTO schema_migrations (version) VALUES ('296');

INSERT INTO schema_migrations (version) VALUES ('297');

INSERT INTO schema_migrations (version) VALUES ('298');

INSERT INTO schema_migrations (version) VALUES ('299');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('300');

INSERT INTO schema_migrations (version) VALUES ('301');

INSERT INTO schema_migrations (version) VALUES ('302');

INSERT INTO schema_migrations (version) VALUES ('303');

INSERT INTO schema_migrations (version) VALUES ('304');

INSERT INTO schema_migrations (version) VALUES ('305');

INSERT INTO schema_migrations (version) VALUES ('306');

INSERT INTO schema_migrations (version) VALUES ('307');

INSERT INTO schema_migrations (version) VALUES ('308');

INSERT INTO schema_migrations (version) VALUES ('309');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('310');

INSERT INTO schema_migrations (version) VALUES ('311');

INSERT INTO schema_migrations (version) VALUES ('312');

INSERT INTO schema_migrations (version) VALUES ('313');

INSERT INTO schema_migrations (version) VALUES ('314');

INSERT INTO schema_migrations (version) VALUES ('315');

INSERT INTO schema_migrations (version) VALUES ('316');

INSERT INTO schema_migrations (version) VALUES ('317');

INSERT INTO schema_migrations (version) VALUES ('318');

INSERT INTO schema_migrations (version) VALUES ('319');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('320');

INSERT INTO schema_migrations (version) VALUES ('321');

INSERT INTO schema_migrations (version) VALUES ('322');

INSERT INTO schema_migrations (version) VALUES ('323');

INSERT INTO schema_migrations (version) VALUES ('324');

INSERT INTO schema_migrations (version) VALUES ('325');

INSERT INTO schema_migrations (version) VALUES ('326');

INSERT INTO schema_migrations (version) VALUES ('327');

INSERT INTO schema_migrations (version) VALUES ('328');

INSERT INTO schema_migrations (version) VALUES ('329');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('330');

INSERT INTO schema_migrations (version) VALUES ('331');

INSERT INTO schema_migrations (version) VALUES ('332');

INSERT INTO schema_migrations (version) VALUES ('333');

INSERT INTO schema_migrations (version) VALUES ('334');

INSERT INTO schema_migrations (version) VALUES ('335');

INSERT INTO schema_migrations (version) VALUES ('336');

INSERT INTO schema_migrations (version) VALUES ('337');

INSERT INTO schema_migrations (version) VALUES ('338');

INSERT INTO schema_migrations (version) VALUES ('339');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('340');

INSERT INTO schema_migrations (version) VALUES ('341');

INSERT INTO schema_migrations (version) VALUES ('342');

INSERT INTO schema_migrations (version) VALUES ('343');

INSERT INTO schema_migrations (version) VALUES ('344');

INSERT INTO schema_migrations (version) VALUES ('345');

INSERT INTO schema_migrations (version) VALUES ('346');

INSERT INTO schema_migrations (version) VALUES ('347');

INSERT INTO schema_migrations (version) VALUES ('348');

INSERT INTO schema_migrations (version) VALUES ('349');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('350');

INSERT INTO schema_migrations (version) VALUES ('351');

INSERT INTO schema_migrations (version) VALUES ('352');

INSERT INTO schema_migrations (version) VALUES ('353');

INSERT INTO schema_migrations (version) VALUES ('354');

INSERT INTO schema_migrations (version) VALUES ('355');

INSERT INTO schema_migrations (version) VALUES ('356');

INSERT INTO schema_migrations (version) VALUES ('357');

INSERT INTO schema_migrations (version) VALUES ('358');

INSERT INTO schema_migrations (version) VALUES ('359');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('360');

INSERT INTO schema_migrations (version) VALUES ('361');

INSERT INTO schema_migrations (version) VALUES ('362');

INSERT INTO schema_migrations (version) VALUES ('363');

INSERT INTO schema_migrations (version) VALUES ('364');

INSERT INTO schema_migrations (version) VALUES ('365');

INSERT INTO schema_migrations (version) VALUES ('366');

INSERT INTO schema_migrations (version) VALUES ('367');

INSERT INTO schema_migrations (version) VALUES ('368');

INSERT INTO schema_migrations (version) VALUES ('369');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('370');

INSERT INTO schema_migrations (version) VALUES ('371');

INSERT INTO schema_migrations (version) VALUES ('372');

INSERT INTO schema_migrations (version) VALUES ('373');

INSERT INTO schema_migrations (version) VALUES ('374');

INSERT INTO schema_migrations (version) VALUES ('375');

INSERT INTO schema_migrations (version) VALUES ('376');

INSERT INTO schema_migrations (version) VALUES ('377');

INSERT INTO schema_migrations (version) VALUES ('378');

INSERT INTO schema_migrations (version) VALUES ('379');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('380');

INSERT INTO schema_migrations (version) VALUES ('381');

INSERT INTO schema_migrations (version) VALUES ('382');

INSERT INTO schema_migrations (version) VALUES ('383');

INSERT INTO schema_migrations (version) VALUES ('384');

INSERT INTO schema_migrations (version) VALUES ('385');

INSERT INTO schema_migrations (version) VALUES ('386');

INSERT INTO schema_migrations (version) VALUES ('387');

INSERT INTO schema_migrations (version) VALUES ('388');

INSERT INTO schema_migrations (version) VALUES ('389');

INSERT INTO schema_migrations (version) VALUES ('39');

INSERT INTO schema_migrations (version) VALUES ('390');

INSERT INTO schema_migrations (version) VALUES ('391');

INSERT INTO schema_migrations (version) VALUES ('392');

INSERT INTO schema_migrations (version) VALUES ('393');

INSERT INTO schema_migrations (version) VALUES ('394');

INSERT INTO schema_migrations (version) VALUES ('395');

INSERT INTO schema_migrations (version) VALUES ('396');

INSERT INTO schema_migrations (version) VALUES ('397');

INSERT INTO schema_migrations (version) VALUES ('398');

INSERT INTO schema_migrations (version) VALUES ('399');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('400');

INSERT INTO schema_migrations (version) VALUES ('401');

INSERT INTO schema_migrations (version) VALUES ('402');

INSERT INTO schema_migrations (version) VALUES ('403');

INSERT INTO schema_migrations (version) VALUES ('404');

INSERT INTO schema_migrations (version) VALUES ('405');

INSERT INTO schema_migrations (version) VALUES ('406');

INSERT INTO schema_migrations (version) VALUES ('407');

INSERT INTO schema_migrations (version) VALUES ('408');

INSERT INTO schema_migrations (version) VALUES ('409');

INSERT INTO schema_migrations (version) VALUES ('41');

INSERT INTO schema_migrations (version) VALUES ('410');

INSERT INTO schema_migrations (version) VALUES ('411');

INSERT INTO schema_migrations (version) VALUES ('412');

INSERT INTO schema_migrations (version) VALUES ('413');

INSERT INTO schema_migrations (version) VALUES ('414');

INSERT INTO schema_migrations (version) VALUES ('415');

INSERT INTO schema_migrations (version) VALUES ('416');

INSERT INTO schema_migrations (version) VALUES ('417');

INSERT INTO schema_migrations (version) VALUES ('418');

INSERT INTO schema_migrations (version) VALUES ('419');

INSERT INTO schema_migrations (version) VALUES ('42');

INSERT INTO schema_migrations (version) VALUES ('420');

INSERT INTO schema_migrations (version) VALUES ('421');

INSERT INTO schema_migrations (version) VALUES ('422');

INSERT INTO schema_migrations (version) VALUES ('423');

INSERT INTO schema_migrations (version) VALUES ('424');

INSERT INTO schema_migrations (version) VALUES ('425');

INSERT INTO schema_migrations (version) VALUES ('426');

INSERT INTO schema_migrations (version) VALUES ('427');

INSERT INTO schema_migrations (version) VALUES ('428');

INSERT INTO schema_migrations (version) VALUES ('429');

INSERT INTO schema_migrations (version) VALUES ('43');

INSERT INTO schema_migrations (version) VALUES ('430');

INSERT INTO schema_migrations (version) VALUES ('431');

INSERT INTO schema_migrations (version) VALUES ('432');

INSERT INTO schema_migrations (version) VALUES ('433');

INSERT INTO schema_migrations (version) VALUES ('434');

INSERT INTO schema_migrations (version) VALUES ('435');

INSERT INTO schema_migrations (version) VALUES ('436');

INSERT INTO schema_migrations (version) VALUES ('437');

INSERT INTO schema_migrations (version) VALUES ('438');

INSERT INTO schema_migrations (version) VALUES ('439');

INSERT INTO schema_migrations (version) VALUES ('44');

INSERT INTO schema_migrations (version) VALUES ('440');

INSERT INTO schema_migrations (version) VALUES ('441');

INSERT INTO schema_migrations (version) VALUES ('442');

INSERT INTO schema_migrations (version) VALUES ('443');

INSERT INTO schema_migrations (version) VALUES ('444');

INSERT INTO schema_migrations (version) VALUES ('445');

INSERT INTO schema_migrations (version) VALUES ('446');

INSERT INTO schema_migrations (version) VALUES ('447');

INSERT INTO schema_migrations (version) VALUES ('448');

INSERT INTO schema_migrations (version) VALUES ('449');

INSERT INTO schema_migrations (version) VALUES ('45');

INSERT INTO schema_migrations (version) VALUES ('450');

INSERT INTO schema_migrations (version) VALUES ('451');

INSERT INTO schema_migrations (version) VALUES ('452');

INSERT INTO schema_migrations (version) VALUES ('453');

INSERT INTO schema_migrations (version) VALUES ('454');

INSERT INTO schema_migrations (version) VALUES ('455');

INSERT INTO schema_migrations (version) VALUES ('456');

INSERT INTO schema_migrations (version) VALUES ('457');

INSERT INTO schema_migrations (version) VALUES ('458');

INSERT INTO schema_migrations (version) VALUES ('459');

INSERT INTO schema_migrations (version) VALUES ('46');

INSERT INTO schema_migrations (version) VALUES ('460');

INSERT INTO schema_migrations (version) VALUES ('461');

INSERT INTO schema_migrations (version) VALUES ('462');

INSERT INTO schema_migrations (version) VALUES ('463');

INSERT INTO schema_migrations (version) VALUES ('464');

INSERT INTO schema_migrations (version) VALUES ('465');

INSERT INTO schema_migrations (version) VALUES ('466');

INSERT INTO schema_migrations (version) VALUES ('467');

INSERT INTO schema_migrations (version) VALUES ('468');

INSERT INTO schema_migrations (version) VALUES ('469');

INSERT INTO schema_migrations (version) VALUES ('47');

INSERT INTO schema_migrations (version) VALUES ('470');

INSERT INTO schema_migrations (version) VALUES ('471');

INSERT INTO schema_migrations (version) VALUES ('472');

INSERT INTO schema_migrations (version) VALUES ('473');

INSERT INTO schema_migrations (version) VALUES ('474');

INSERT INTO schema_migrations (version) VALUES ('475');

INSERT INTO schema_migrations (version) VALUES ('476');

INSERT INTO schema_migrations (version) VALUES ('477');

INSERT INTO schema_migrations (version) VALUES ('478');

INSERT INTO schema_migrations (version) VALUES ('479');

INSERT INTO schema_migrations (version) VALUES ('48');

INSERT INTO schema_migrations (version) VALUES ('480');

INSERT INTO schema_migrations (version) VALUES ('481');

INSERT INTO schema_migrations (version) VALUES ('482');

INSERT INTO schema_migrations (version) VALUES ('483');

INSERT INTO schema_migrations (version) VALUES ('484');

INSERT INTO schema_migrations (version) VALUES ('485');

INSERT INTO schema_migrations (version) VALUES ('486');

INSERT INTO schema_migrations (version) VALUES ('487');

INSERT INTO schema_migrations (version) VALUES ('488');

INSERT INTO schema_migrations (version) VALUES ('489');

INSERT INTO schema_migrations (version) VALUES ('49');

INSERT INTO schema_migrations (version) VALUES ('490');

INSERT INTO schema_migrations (version) VALUES ('491');

INSERT INTO schema_migrations (version) VALUES ('492');

INSERT INTO schema_migrations (version) VALUES ('493');

INSERT INTO schema_migrations (version) VALUES ('494');

INSERT INTO schema_migrations (version) VALUES ('495');

INSERT INTO schema_migrations (version) VALUES ('496');

INSERT INTO schema_migrations (version) VALUES ('497');

INSERT INTO schema_migrations (version) VALUES ('498');

INSERT INTO schema_migrations (version) VALUES ('499');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('50');

INSERT INTO schema_migrations (version) VALUES ('500');

INSERT INTO schema_migrations (version) VALUES ('501');

INSERT INTO schema_migrations (version) VALUES ('502');

INSERT INTO schema_migrations (version) VALUES ('503');

INSERT INTO schema_migrations (version) VALUES ('504');

INSERT INTO schema_migrations (version) VALUES ('505');

INSERT INTO schema_migrations (version) VALUES ('506');

INSERT INTO schema_migrations (version) VALUES ('507');

INSERT INTO schema_migrations (version) VALUES ('508');

INSERT INTO schema_migrations (version) VALUES ('509');

INSERT INTO schema_migrations (version) VALUES ('51');

INSERT INTO schema_migrations (version) VALUES ('510');

INSERT INTO schema_migrations (version) VALUES ('511');

INSERT INTO schema_migrations (version) VALUES ('512');

INSERT INTO schema_migrations (version) VALUES ('513');

INSERT INTO schema_migrations (version) VALUES ('514');

INSERT INTO schema_migrations (version) VALUES ('515');

INSERT INTO schema_migrations (version) VALUES ('516');

INSERT INTO schema_migrations (version) VALUES ('517');

INSERT INTO schema_migrations (version) VALUES ('518');

INSERT INTO schema_migrations (version) VALUES ('519');

INSERT INTO schema_migrations (version) VALUES ('52');

INSERT INTO schema_migrations (version) VALUES ('520');

INSERT INTO schema_migrations (version) VALUES ('521');

INSERT INTO schema_migrations (version) VALUES ('522');

INSERT INTO schema_migrations (version) VALUES ('523');

INSERT INTO schema_migrations (version) VALUES ('524');

INSERT INTO schema_migrations (version) VALUES ('525');

INSERT INTO schema_migrations (version) VALUES ('526');

INSERT INTO schema_migrations (version) VALUES ('527');

INSERT INTO schema_migrations (version) VALUES ('528');

INSERT INTO schema_migrations (version) VALUES ('529');

INSERT INTO schema_migrations (version) VALUES ('53');

INSERT INTO schema_migrations (version) VALUES ('530');

INSERT INTO schema_migrations (version) VALUES ('531');

INSERT INTO schema_migrations (version) VALUES ('532');

INSERT INTO schema_migrations (version) VALUES ('533');

INSERT INTO schema_migrations (version) VALUES ('534');

INSERT INTO schema_migrations (version) VALUES ('535');

INSERT INTO schema_migrations (version) VALUES ('536');

INSERT INTO schema_migrations (version) VALUES ('537');

INSERT INTO schema_migrations (version) VALUES ('538');

INSERT INTO schema_migrations (version) VALUES ('539');

INSERT INTO schema_migrations (version) VALUES ('54');

INSERT INTO schema_migrations (version) VALUES ('540');

INSERT INTO schema_migrations (version) VALUES ('541');

INSERT INTO schema_migrations (version) VALUES ('542');

INSERT INTO schema_migrations (version) VALUES ('543');

INSERT INTO schema_migrations (version) VALUES ('544');

INSERT INTO schema_migrations (version) VALUES ('545');

INSERT INTO schema_migrations (version) VALUES ('546');

INSERT INTO schema_migrations (version) VALUES ('547');

INSERT INTO schema_migrations (version) VALUES ('548');

INSERT INTO schema_migrations (version) VALUES ('549');

INSERT INTO schema_migrations (version) VALUES ('55');

INSERT INTO schema_migrations (version) VALUES ('550');

INSERT INTO schema_migrations (version) VALUES ('551');

INSERT INTO schema_migrations (version) VALUES ('552');

INSERT INTO schema_migrations (version) VALUES ('553');

INSERT INTO schema_migrations (version) VALUES ('554');

INSERT INTO schema_migrations (version) VALUES ('555');

INSERT INTO schema_migrations (version) VALUES ('556');

INSERT INTO schema_migrations (version) VALUES ('557');

INSERT INTO schema_migrations (version) VALUES ('558');

INSERT INTO schema_migrations (version) VALUES ('559');

INSERT INTO schema_migrations (version) VALUES ('56');

INSERT INTO schema_migrations (version) VALUES ('560');

INSERT INTO schema_migrations (version) VALUES ('561');

INSERT INTO schema_migrations (version) VALUES ('562');

INSERT INTO schema_migrations (version) VALUES ('563');

INSERT INTO schema_migrations (version) VALUES ('564');

INSERT INTO schema_migrations (version) VALUES ('565');

INSERT INTO schema_migrations (version) VALUES ('566');

INSERT INTO schema_migrations (version) VALUES ('567');

INSERT INTO schema_migrations (version) VALUES ('568');

INSERT INTO schema_migrations (version) VALUES ('569');

INSERT INTO schema_migrations (version) VALUES ('57');

INSERT INTO schema_migrations (version) VALUES ('570');

INSERT INTO schema_migrations (version) VALUES ('571');

INSERT INTO schema_migrations (version) VALUES ('572');

INSERT INTO schema_migrations (version) VALUES ('573');

INSERT INTO schema_migrations (version) VALUES ('574');

INSERT INTO schema_migrations (version) VALUES ('575');

INSERT INTO schema_migrations (version) VALUES ('576');

INSERT INTO schema_migrations (version) VALUES ('577');

INSERT INTO schema_migrations (version) VALUES ('578');

INSERT INTO schema_migrations (version) VALUES ('579');

INSERT INTO schema_migrations (version) VALUES ('58');

INSERT INTO schema_migrations (version) VALUES ('580');

INSERT INTO schema_migrations (version) VALUES ('581');

INSERT INTO schema_migrations (version) VALUES ('582');

INSERT INTO schema_migrations (version) VALUES ('583');

INSERT INTO schema_migrations (version) VALUES ('584');

INSERT INTO schema_migrations (version) VALUES ('585');

INSERT INTO schema_migrations (version) VALUES ('586');

INSERT INTO schema_migrations (version) VALUES ('587');

INSERT INTO schema_migrations (version) VALUES ('588');

INSERT INTO schema_migrations (version) VALUES ('589');

INSERT INTO schema_migrations (version) VALUES ('59');

INSERT INTO schema_migrations (version) VALUES ('590');

INSERT INTO schema_migrations (version) VALUES ('591');

INSERT INTO schema_migrations (version) VALUES ('592');

INSERT INTO schema_migrations (version) VALUES ('593');

INSERT INTO schema_migrations (version) VALUES ('594');

INSERT INTO schema_migrations (version) VALUES ('595');

INSERT INTO schema_migrations (version) VALUES ('596');

INSERT INTO schema_migrations (version) VALUES ('597');

INSERT INTO schema_migrations (version) VALUES ('598');

INSERT INTO schema_migrations (version) VALUES ('599');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('60');

INSERT INTO schema_migrations (version) VALUES ('600');

INSERT INTO schema_migrations (version) VALUES ('601');

INSERT INTO schema_migrations (version) VALUES ('602');

INSERT INTO schema_migrations (version) VALUES ('603');

INSERT INTO schema_migrations (version) VALUES ('604');

INSERT INTO schema_migrations (version) VALUES ('605');

INSERT INTO schema_migrations (version) VALUES ('606');

INSERT INTO schema_migrations (version) VALUES ('607');

INSERT INTO schema_migrations (version) VALUES ('608');

INSERT INTO schema_migrations (version) VALUES ('609');

INSERT INTO schema_migrations (version) VALUES ('61');

INSERT INTO schema_migrations (version) VALUES ('610');

INSERT INTO schema_migrations (version) VALUES ('611');

INSERT INTO schema_migrations (version) VALUES ('612');

INSERT INTO schema_migrations (version) VALUES ('613');

INSERT INTO schema_migrations (version) VALUES ('614');

INSERT INTO schema_migrations (version) VALUES ('615');

INSERT INTO schema_migrations (version) VALUES ('616');

INSERT INTO schema_migrations (version) VALUES ('617');

INSERT INTO schema_migrations (version) VALUES ('618');

INSERT INTO schema_migrations (version) VALUES ('619');

INSERT INTO schema_migrations (version) VALUES ('62');

INSERT INTO schema_migrations (version) VALUES ('620');

INSERT INTO schema_migrations (version) VALUES ('621');

INSERT INTO schema_migrations (version) VALUES ('622');

INSERT INTO schema_migrations (version) VALUES ('623');

INSERT INTO schema_migrations (version) VALUES ('624');

INSERT INTO schema_migrations (version) VALUES ('625');

INSERT INTO schema_migrations (version) VALUES ('626');

INSERT INTO schema_migrations (version) VALUES ('627');

INSERT INTO schema_migrations (version) VALUES ('628');

INSERT INTO schema_migrations (version) VALUES ('629');

INSERT INTO schema_migrations (version) VALUES ('63');

INSERT INTO schema_migrations (version) VALUES ('630');

INSERT INTO schema_migrations (version) VALUES ('631');

INSERT INTO schema_migrations (version) VALUES ('632');

INSERT INTO schema_migrations (version) VALUES ('633');

INSERT INTO schema_migrations (version) VALUES ('634');

INSERT INTO schema_migrations (version) VALUES ('635');

INSERT INTO schema_migrations (version) VALUES ('636');

INSERT INTO schema_migrations (version) VALUES ('637');

INSERT INTO schema_migrations (version) VALUES ('638');

INSERT INTO schema_migrations (version) VALUES ('639');

INSERT INTO schema_migrations (version) VALUES ('64');

INSERT INTO schema_migrations (version) VALUES ('640');

INSERT INTO schema_migrations (version) VALUES ('641');

INSERT INTO schema_migrations (version) VALUES ('642');

INSERT INTO schema_migrations (version) VALUES ('643');

INSERT INTO schema_migrations (version) VALUES ('644');

INSERT INTO schema_migrations (version) VALUES ('645');

INSERT INTO schema_migrations (version) VALUES ('646');

INSERT INTO schema_migrations (version) VALUES ('647');

INSERT INTO schema_migrations (version) VALUES ('648');

INSERT INTO schema_migrations (version) VALUES ('649');

INSERT INTO schema_migrations (version) VALUES ('65');

INSERT INTO schema_migrations (version) VALUES ('650');

INSERT INTO schema_migrations (version) VALUES ('651');

INSERT INTO schema_migrations (version) VALUES ('652');

INSERT INTO schema_migrations (version) VALUES ('653');

INSERT INTO schema_migrations (version) VALUES ('654');

INSERT INTO schema_migrations (version) VALUES ('655');

INSERT INTO schema_migrations (version) VALUES ('656');

INSERT INTO schema_migrations (version) VALUES ('657');

INSERT INTO schema_migrations (version) VALUES ('658');

INSERT INTO schema_migrations (version) VALUES ('659');

INSERT INTO schema_migrations (version) VALUES ('66');

INSERT INTO schema_migrations (version) VALUES ('660');

INSERT INTO schema_migrations (version) VALUES ('661');

INSERT INTO schema_migrations (version) VALUES ('662');

INSERT INTO schema_migrations (version) VALUES ('663');

INSERT INTO schema_migrations (version) VALUES ('664');

INSERT INTO schema_migrations (version) VALUES ('665');

INSERT INTO schema_migrations (version) VALUES ('666');

INSERT INTO schema_migrations (version) VALUES ('667');

INSERT INTO schema_migrations (version) VALUES ('668');

INSERT INTO schema_migrations (version) VALUES ('669');

INSERT INTO schema_migrations (version) VALUES ('67');

INSERT INTO schema_migrations (version) VALUES ('670');

INSERT INTO schema_migrations (version) VALUES ('671');

INSERT INTO schema_migrations (version) VALUES ('672');

INSERT INTO schema_migrations (version) VALUES ('673');

INSERT INTO schema_migrations (version) VALUES ('674');

INSERT INTO schema_migrations (version) VALUES ('675');

INSERT INTO schema_migrations (version) VALUES ('676');

INSERT INTO schema_migrations (version) VALUES ('677');

INSERT INTO schema_migrations (version) VALUES ('678');

INSERT INTO schema_migrations (version) VALUES ('679');

INSERT INTO schema_migrations (version) VALUES ('68');

INSERT INTO schema_migrations (version) VALUES ('680');

INSERT INTO schema_migrations (version) VALUES ('681');

INSERT INTO schema_migrations (version) VALUES ('682');

INSERT INTO schema_migrations (version) VALUES ('683');

INSERT INTO schema_migrations (version) VALUES ('684');

INSERT INTO schema_migrations (version) VALUES ('685');

INSERT INTO schema_migrations (version) VALUES ('686');

INSERT INTO schema_migrations (version) VALUES ('687');

INSERT INTO schema_migrations (version) VALUES ('688');

INSERT INTO schema_migrations (version) VALUES ('689');

INSERT INTO schema_migrations (version) VALUES ('69');

INSERT INTO schema_migrations (version) VALUES ('690');

INSERT INTO schema_migrations (version) VALUES ('691');

INSERT INTO schema_migrations (version) VALUES ('692');

INSERT INTO schema_migrations (version) VALUES ('693');

INSERT INTO schema_migrations (version) VALUES ('694');

INSERT INTO schema_migrations (version) VALUES ('695');

INSERT INTO schema_migrations (version) VALUES ('696');

INSERT INTO schema_migrations (version) VALUES ('697');

INSERT INTO schema_migrations (version) VALUES ('698');

INSERT INTO schema_migrations (version) VALUES ('699');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('70');

INSERT INTO schema_migrations (version) VALUES ('700');

INSERT INTO schema_migrations (version) VALUES ('701');

INSERT INTO schema_migrations (version) VALUES ('702');

INSERT INTO schema_migrations (version) VALUES ('703');

INSERT INTO schema_migrations (version) VALUES ('704');

INSERT INTO schema_migrations (version) VALUES ('705');

INSERT INTO schema_migrations (version) VALUES ('706');

INSERT INTO schema_migrations (version) VALUES ('707');

INSERT INTO schema_migrations (version) VALUES ('708');

INSERT INTO schema_migrations (version) VALUES ('709');

INSERT INTO schema_migrations (version) VALUES ('71');

INSERT INTO schema_migrations (version) VALUES ('710');

INSERT INTO schema_migrations (version) VALUES ('711');

INSERT INTO schema_migrations (version) VALUES ('712');

INSERT INTO schema_migrations (version) VALUES ('713');

INSERT INTO schema_migrations (version) VALUES ('714');

INSERT INTO schema_migrations (version) VALUES ('715');

INSERT INTO schema_migrations (version) VALUES ('716');

INSERT INTO schema_migrations (version) VALUES ('717');

INSERT INTO schema_migrations (version) VALUES ('718');

INSERT INTO schema_migrations (version) VALUES ('719');

INSERT INTO schema_migrations (version) VALUES ('72');

INSERT INTO schema_migrations (version) VALUES ('720');

INSERT INTO schema_migrations (version) VALUES ('721');

INSERT INTO schema_migrations (version) VALUES ('722');

INSERT INTO schema_migrations (version) VALUES ('723');

INSERT INTO schema_migrations (version) VALUES ('724');

INSERT INTO schema_migrations (version) VALUES ('725');

INSERT INTO schema_migrations (version) VALUES ('726');

INSERT INTO schema_migrations (version) VALUES ('727');

INSERT INTO schema_migrations (version) VALUES ('728');

INSERT INTO schema_migrations (version) VALUES ('729');

INSERT INTO schema_migrations (version) VALUES ('73');

INSERT INTO schema_migrations (version) VALUES ('730');

INSERT INTO schema_migrations (version) VALUES ('731');

INSERT INTO schema_migrations (version) VALUES ('732');

INSERT INTO schema_migrations (version) VALUES ('733');

INSERT INTO schema_migrations (version) VALUES ('734');

INSERT INTO schema_migrations (version) VALUES ('735');

INSERT INTO schema_migrations (version) VALUES ('736');

INSERT INTO schema_migrations (version) VALUES ('737');

INSERT INTO schema_migrations (version) VALUES ('738');

INSERT INTO schema_migrations (version) VALUES ('739');

INSERT INTO schema_migrations (version) VALUES ('74');

INSERT INTO schema_migrations (version) VALUES ('740');

INSERT INTO schema_migrations (version) VALUES ('741');

INSERT INTO schema_migrations (version) VALUES ('742');

INSERT INTO schema_migrations (version) VALUES ('743');

INSERT INTO schema_migrations (version) VALUES ('744');

INSERT INTO schema_migrations (version) VALUES ('745');

INSERT INTO schema_migrations (version) VALUES ('746');

INSERT INTO schema_migrations (version) VALUES ('747');

INSERT INTO schema_migrations (version) VALUES ('748');

INSERT INTO schema_migrations (version) VALUES ('749');

INSERT INTO schema_migrations (version) VALUES ('75');

INSERT INTO schema_migrations (version) VALUES ('750');

INSERT INTO schema_migrations (version) VALUES ('751');

INSERT INTO schema_migrations (version) VALUES ('752');

INSERT INTO schema_migrations (version) VALUES ('753');

INSERT INTO schema_migrations (version) VALUES ('754');

INSERT INTO schema_migrations (version) VALUES ('755');

INSERT INTO schema_migrations (version) VALUES ('756');

INSERT INTO schema_migrations (version) VALUES ('757');

INSERT INTO schema_migrations (version) VALUES ('758');

INSERT INTO schema_migrations (version) VALUES ('759');

INSERT INTO schema_migrations (version) VALUES ('76');

INSERT INTO schema_migrations (version) VALUES ('760');

INSERT INTO schema_migrations (version) VALUES ('761');

INSERT INTO schema_migrations (version) VALUES ('762');

INSERT INTO schema_migrations (version) VALUES ('763');

INSERT INTO schema_migrations (version) VALUES ('764');

INSERT INTO schema_migrations (version) VALUES ('765');

INSERT INTO schema_migrations (version) VALUES ('766');

INSERT INTO schema_migrations (version) VALUES ('767');

INSERT INTO schema_migrations (version) VALUES ('768');

INSERT INTO schema_migrations (version) VALUES ('769');

INSERT INTO schema_migrations (version) VALUES ('77');

INSERT INTO schema_migrations (version) VALUES ('770');

INSERT INTO schema_migrations (version) VALUES ('771');

INSERT INTO schema_migrations (version) VALUES ('772');

INSERT INTO schema_migrations (version) VALUES ('773');

INSERT INTO schema_migrations (version) VALUES ('774');

INSERT INTO schema_migrations (version) VALUES ('775');

INSERT INTO schema_migrations (version) VALUES ('776');

INSERT INTO schema_migrations (version) VALUES ('777');

INSERT INTO schema_migrations (version) VALUES ('778');

INSERT INTO schema_migrations (version) VALUES ('779');

INSERT INTO schema_migrations (version) VALUES ('78');

INSERT INTO schema_migrations (version) VALUES ('780');

INSERT INTO schema_migrations (version) VALUES ('781');

INSERT INTO schema_migrations (version) VALUES ('782');

INSERT INTO schema_migrations (version) VALUES ('783');

INSERT INTO schema_migrations (version) VALUES ('784');

INSERT INTO schema_migrations (version) VALUES ('785');

INSERT INTO schema_migrations (version) VALUES ('786');

INSERT INTO schema_migrations (version) VALUES ('787');

INSERT INTO schema_migrations (version) VALUES ('788');

INSERT INTO schema_migrations (version) VALUES ('789');

INSERT INTO schema_migrations (version) VALUES ('79');

INSERT INTO schema_migrations (version) VALUES ('790');

INSERT INTO schema_migrations (version) VALUES ('791');

INSERT INTO schema_migrations (version) VALUES ('792');

INSERT INTO schema_migrations (version) VALUES ('793');

INSERT INTO schema_migrations (version) VALUES ('794');

INSERT INTO schema_migrations (version) VALUES ('795');

INSERT INTO schema_migrations (version) VALUES ('796');

INSERT INTO schema_migrations (version) VALUES ('797');

INSERT INTO schema_migrations (version) VALUES ('798');

INSERT INTO schema_migrations (version) VALUES ('799');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('80');

INSERT INTO schema_migrations (version) VALUES ('800');

INSERT INTO schema_migrations (version) VALUES ('801');

INSERT INTO schema_migrations (version) VALUES ('802');

INSERT INTO schema_migrations (version) VALUES ('803');

INSERT INTO schema_migrations (version) VALUES ('804');

INSERT INTO schema_migrations (version) VALUES ('805');

INSERT INTO schema_migrations (version) VALUES ('806');

INSERT INTO schema_migrations (version) VALUES ('807');

INSERT INTO schema_migrations (version) VALUES ('808');

INSERT INTO schema_migrations (version) VALUES ('809');

INSERT INTO schema_migrations (version) VALUES ('81');

INSERT INTO schema_migrations (version) VALUES ('810');

INSERT INTO schema_migrations (version) VALUES ('811');

INSERT INTO schema_migrations (version) VALUES ('812');

INSERT INTO schema_migrations (version) VALUES ('813');

INSERT INTO schema_migrations (version) VALUES ('814');

INSERT INTO schema_migrations (version) VALUES ('815');

INSERT INTO schema_migrations (version) VALUES ('816');

INSERT INTO schema_migrations (version) VALUES ('817');

INSERT INTO schema_migrations (version) VALUES ('818');

INSERT INTO schema_migrations (version) VALUES ('819');

INSERT INTO schema_migrations (version) VALUES ('82');

INSERT INTO schema_migrations (version) VALUES ('820');

INSERT INTO schema_migrations (version) VALUES ('821');

INSERT INTO schema_migrations (version) VALUES ('822');

INSERT INTO schema_migrations (version) VALUES ('823');

INSERT INTO schema_migrations (version) VALUES ('824');

INSERT INTO schema_migrations (version) VALUES ('825');

INSERT INTO schema_migrations (version) VALUES ('826');

INSERT INTO schema_migrations (version) VALUES ('827');

INSERT INTO schema_migrations (version) VALUES ('828');

INSERT INTO schema_migrations (version) VALUES ('829');

INSERT INTO schema_migrations (version) VALUES ('83');

INSERT INTO schema_migrations (version) VALUES ('830');

INSERT INTO schema_migrations (version) VALUES ('831');

INSERT INTO schema_migrations (version) VALUES ('832');

INSERT INTO schema_migrations (version) VALUES ('833');

INSERT INTO schema_migrations (version) VALUES ('834');

INSERT INTO schema_migrations (version) VALUES ('835');

INSERT INTO schema_migrations (version) VALUES ('836');

INSERT INTO schema_migrations (version) VALUES ('837');

INSERT INTO schema_migrations (version) VALUES ('838');

INSERT INTO schema_migrations (version) VALUES ('839');

INSERT INTO schema_migrations (version) VALUES ('84');

INSERT INTO schema_migrations (version) VALUES ('840');

INSERT INTO schema_migrations (version) VALUES ('841');

INSERT INTO schema_migrations (version) VALUES ('842');

INSERT INTO schema_migrations (version) VALUES ('843');

INSERT INTO schema_migrations (version) VALUES ('844');

INSERT INTO schema_migrations (version) VALUES ('845');

INSERT INTO schema_migrations (version) VALUES ('846');

INSERT INTO schema_migrations (version) VALUES ('847');

INSERT INTO schema_migrations (version) VALUES ('848');

INSERT INTO schema_migrations (version) VALUES ('849');

INSERT INTO schema_migrations (version) VALUES ('85');

INSERT INTO schema_migrations (version) VALUES ('850');

INSERT INTO schema_migrations (version) VALUES ('851');

INSERT INTO schema_migrations (version) VALUES ('852');

INSERT INTO schema_migrations (version) VALUES ('853');

INSERT INTO schema_migrations (version) VALUES ('854');

INSERT INTO schema_migrations (version) VALUES ('855');

INSERT INTO schema_migrations (version) VALUES ('856');

INSERT INTO schema_migrations (version) VALUES ('857');

INSERT INTO schema_migrations (version) VALUES ('858');

INSERT INTO schema_migrations (version) VALUES ('859');

INSERT INTO schema_migrations (version) VALUES ('86');

INSERT INTO schema_migrations (version) VALUES ('860');

INSERT INTO schema_migrations (version) VALUES ('861');

INSERT INTO schema_migrations (version) VALUES ('862');

INSERT INTO schema_migrations (version) VALUES ('863');

INSERT INTO schema_migrations (version) VALUES ('864');

INSERT INTO schema_migrations (version) VALUES ('865');

INSERT INTO schema_migrations (version) VALUES ('866');

INSERT INTO schema_migrations (version) VALUES ('867');

INSERT INTO schema_migrations (version) VALUES ('868');

INSERT INTO schema_migrations (version) VALUES ('869');

INSERT INTO schema_migrations (version) VALUES ('87');

INSERT INTO schema_migrations (version) VALUES ('870');

INSERT INTO schema_migrations (version) VALUES ('871');

INSERT INTO schema_migrations (version) VALUES ('872');

INSERT INTO schema_migrations (version) VALUES ('873');

INSERT INTO schema_migrations (version) VALUES ('874');

INSERT INTO schema_migrations (version) VALUES ('875');

INSERT INTO schema_migrations (version) VALUES ('876');

INSERT INTO schema_migrations (version) VALUES ('877');

INSERT INTO schema_migrations (version) VALUES ('878');

INSERT INTO schema_migrations (version) VALUES ('879');

INSERT INTO schema_migrations (version) VALUES ('88');

INSERT INTO schema_migrations (version) VALUES ('880');

INSERT INTO schema_migrations (version) VALUES ('881');

INSERT INTO schema_migrations (version) VALUES ('882');

INSERT INTO schema_migrations (version) VALUES ('883');

INSERT INTO schema_migrations (version) VALUES ('884');

INSERT INTO schema_migrations (version) VALUES ('885');

INSERT INTO schema_migrations (version) VALUES ('886');

INSERT INTO schema_migrations (version) VALUES ('887');

INSERT INTO schema_migrations (version) VALUES ('888');

INSERT INTO schema_migrations (version) VALUES ('889');

INSERT INTO schema_migrations (version) VALUES ('89');

INSERT INTO schema_migrations (version) VALUES ('890');

INSERT INTO schema_migrations (version) VALUES ('891');

INSERT INTO schema_migrations (version) VALUES ('892');

INSERT INTO schema_migrations (version) VALUES ('893');

INSERT INTO schema_migrations (version) VALUES ('894');

INSERT INTO schema_migrations (version) VALUES ('895');

INSERT INTO schema_migrations (version) VALUES ('896');

INSERT INTO schema_migrations (version) VALUES ('897');

INSERT INTO schema_migrations (version) VALUES ('898');

INSERT INTO schema_migrations (version) VALUES ('899');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('90');

INSERT INTO schema_migrations (version) VALUES ('900');

INSERT INTO schema_migrations (version) VALUES ('901');

INSERT INTO schema_migrations (version) VALUES ('902');

INSERT INTO schema_migrations (version) VALUES ('903');

INSERT INTO schema_migrations (version) VALUES ('904');

INSERT INTO schema_migrations (version) VALUES ('905');

INSERT INTO schema_migrations (version) VALUES ('906');

INSERT INTO schema_migrations (version) VALUES ('907');

INSERT INTO schema_migrations (version) VALUES ('908');

INSERT INTO schema_migrations (version) VALUES ('909');

INSERT INTO schema_migrations (version) VALUES ('91');

INSERT INTO schema_migrations (version) VALUES ('910');

INSERT INTO schema_migrations (version) VALUES ('911');

INSERT INTO schema_migrations (version) VALUES ('912');

INSERT INTO schema_migrations (version) VALUES ('913');

INSERT INTO schema_migrations (version) VALUES ('914');

INSERT INTO schema_migrations (version) VALUES ('915');

INSERT INTO schema_migrations (version) VALUES ('916');

INSERT INTO schema_migrations (version) VALUES ('917');

INSERT INTO schema_migrations (version) VALUES ('918');

INSERT INTO schema_migrations (version) VALUES ('919');

INSERT INTO schema_migrations (version) VALUES ('92');

INSERT INTO schema_migrations (version) VALUES ('920');

INSERT INTO schema_migrations (version) VALUES ('921');

INSERT INTO schema_migrations (version) VALUES ('922');

INSERT INTO schema_migrations (version) VALUES ('923');

INSERT INTO schema_migrations (version) VALUES ('924');

INSERT INTO schema_migrations (version) VALUES ('925');

INSERT INTO schema_migrations (version) VALUES ('926');

INSERT INTO schema_migrations (version) VALUES ('927');

INSERT INTO schema_migrations (version) VALUES ('928');

INSERT INTO schema_migrations (version) VALUES ('929');

INSERT INTO schema_migrations (version) VALUES ('93');

INSERT INTO schema_migrations (version) VALUES ('930');

INSERT INTO schema_migrations (version) VALUES ('931');

INSERT INTO schema_migrations (version) VALUES ('932');

INSERT INTO schema_migrations (version) VALUES ('933');

INSERT INTO schema_migrations (version) VALUES ('934');

INSERT INTO schema_migrations (version) VALUES ('935');

INSERT INTO schema_migrations (version) VALUES ('936');

INSERT INTO schema_migrations (version) VALUES ('937');

INSERT INTO schema_migrations (version) VALUES ('938');

INSERT INTO schema_migrations (version) VALUES ('939');

INSERT INTO schema_migrations (version) VALUES ('94');

INSERT INTO schema_migrations (version) VALUES ('940');

INSERT INTO schema_migrations (version) VALUES ('941');

INSERT INTO schema_migrations (version) VALUES ('942');

INSERT INTO schema_migrations (version) VALUES ('943');

INSERT INTO schema_migrations (version) VALUES ('944');

INSERT INTO schema_migrations (version) VALUES ('945');

INSERT INTO schema_migrations (version) VALUES ('946');

INSERT INTO schema_migrations (version) VALUES ('947');

INSERT INTO schema_migrations (version) VALUES ('948');

INSERT INTO schema_migrations (version) VALUES ('949');

INSERT INTO schema_migrations (version) VALUES ('95');

INSERT INTO schema_migrations (version) VALUES ('950');

INSERT INTO schema_migrations (version) VALUES ('951');

INSERT INTO schema_migrations (version) VALUES ('952');

INSERT INTO schema_migrations (version) VALUES ('953');

INSERT INTO schema_migrations (version) VALUES ('954');

INSERT INTO schema_migrations (version) VALUES ('955');

INSERT INTO schema_migrations (version) VALUES ('956');

INSERT INTO schema_migrations (version) VALUES ('957');

INSERT INTO schema_migrations (version) VALUES ('958');

INSERT INTO schema_migrations (version) VALUES ('959');

INSERT INTO schema_migrations (version) VALUES ('96');

INSERT INTO schema_migrations (version) VALUES ('960');

INSERT INTO schema_migrations (version) VALUES ('961');

INSERT INTO schema_migrations (version) VALUES ('962');

INSERT INTO schema_migrations (version) VALUES ('963');

INSERT INTO schema_migrations (version) VALUES ('964');

INSERT INTO schema_migrations (version) VALUES ('965');

INSERT INTO schema_migrations (version) VALUES ('966');

INSERT INTO schema_migrations (version) VALUES ('967');

INSERT INTO schema_migrations (version) VALUES ('968');

INSERT INTO schema_migrations (version) VALUES ('969');

INSERT INTO schema_migrations (version) VALUES ('97');

INSERT INTO schema_migrations (version) VALUES ('970');

INSERT INTO schema_migrations (version) VALUES ('971');

INSERT INTO schema_migrations (version) VALUES ('972');

INSERT INTO schema_migrations (version) VALUES ('973');

INSERT INTO schema_migrations (version) VALUES ('974');

INSERT INTO schema_migrations (version) VALUES ('975');

INSERT INTO schema_migrations (version) VALUES ('976');

INSERT INTO schema_migrations (version) VALUES ('977');

INSERT INTO schema_migrations (version) VALUES ('978');

INSERT INTO schema_migrations (version) VALUES ('979');

INSERT INTO schema_migrations (version) VALUES ('98');

INSERT INTO schema_migrations (version) VALUES ('980');

INSERT INTO schema_migrations (version) VALUES ('981');

INSERT INTO schema_migrations (version) VALUES ('982');

INSERT INTO schema_migrations (version) VALUES ('983');

INSERT INTO schema_migrations (version) VALUES ('984');

INSERT INTO schema_migrations (version) VALUES ('985');

INSERT INTO schema_migrations (version) VALUES ('986');

INSERT INTO schema_migrations (version) VALUES ('987');

INSERT INTO schema_migrations (version) VALUES ('988');

INSERT INTO schema_migrations (version) VALUES ('989');

INSERT INTO schema_migrations (version) VALUES ('99');

INSERT INTO schema_migrations (version) VALUES ('990');

INSERT INTO schema_migrations (version) VALUES ('991');

INSERT INTO schema_migrations (version) VALUES ('992');

INSERT INTO schema_migrations (version) VALUES ('993');

INSERT INTO schema_migrations (version) VALUES ('994');

INSERT INTO schema_migrations (version) VALUES ('995');

INSERT INTO schema_migrations (version) VALUES ('996');

INSERT INTO schema_migrations (version) VALUES ('997');

INSERT INTO schema_migrations (version) VALUES ('998');

INSERT INTO schema_migrations (version) VALUES ('999');
