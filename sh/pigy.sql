
CREATE TABLE IF NOT EXISTS `d_account` (
  `id` int(11) unsigned NOT NULL COMMENT '系统编号，对应d_user表的uid',
  `pid` varchar(50) NOT NULL COMMENT '平台下发的id',
  `sdkid` int(11) unsigned NOT NULL COMMENT 'sdkid',
  `password` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `pid_sdkid` (`pid`,`sdkid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='帐号表';

-- 正在导出表  metoo.d_account 的数据：~12 rows (大约)
DELETE FROM `d_account`;
/*!40000 ALTER TABLE `d_account` DISABLE KEYS */;
INSERT INTO `d_account` (`id`, `pid`, `sdkid`) VALUES
	(1, '188', 1),
	(2, '189', 1),
	(3, '190', 1),
	(4, '191', 1),
	(5, '192', 1),
	(6, '193', 1),
	(7, '194', 1),
	(8, '195', 1),
	(9, '196', 1),
	(10, '197', 1),
	(11, '198', 1),
	(12, '199', 1);
/*!40000 ALTER TABLE `d_account` ENABLE KEYS */;

CREATE TABLE IF NOT EXISTS `d_room` (
    `id` INT(10) UNSIGNED NOT NULL,
    `game` SMALLINT(5) UNSIGNED NOT NULL,
    `server` VARCHAR(50) NOT NULL COLLATE 'utf8_unicode_ci',
    `creator` INT(10) UNSIGNED NULL DEFAULT NULL,
    `status` tinyint default 0,
    PRIMARY KEY (`id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=MyISAM
;

CREATE TABLE IF NOT EXISTS `d_user` (
    `uid` INT(10) UNSIGNED NOT NULL,
    `room` INT(10) UNSIGNED NOT NULL DEFAULT 0,
    `money` BIGINT(20) UNSIGNED NOT NULL,
    `nick` VARCHAR(128) NULL DEFAULT NULL COLLATE 'utf8_unicode_ci',
    PRIMARY KEY (`uid`)
)
COLLATE='utf8_unicode_ci'
ENGINE=MyISAM
;

