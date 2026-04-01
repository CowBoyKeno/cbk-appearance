CREATE TABLE IF NOT EXISTS `cbk_appearance` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `player_identifier` VARCHAR(80) NOT NULL,
  `appearance_json` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_sa_appearance_player_identifier` (`player_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
