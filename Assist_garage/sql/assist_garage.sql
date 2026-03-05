-- Assist Garage schema patch
-- ใช้กับตาราง owned_vehicles ของ ESX

ALTER TABLE `owned_vehicles`
    ADD COLUMN IF NOT EXISTS `police` TINYINT(1) NOT NULL DEFAULT 0 AFTER `stored`,
    ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) NOT NULL DEFAULT '' AFTER `police`,
    ADD COLUMN IF NOT EXISTS `vehiclename` VARCHAR(100) NULL DEFAULT NULL AFTER `job`,
    ADD COLUMN IF NOT EXISTS `health_vehicles` LONGTEXT NULL AFTER `vehiclename`,
    ADD COLUMN IF NOT EXISTS `deposit` INT NULL DEFAULT NULL AFTER `health_vehicles`;

-- ค่าเริ่มต้น health_vehicles สำหรับข้อมูลเก่า
UPDATE `owned_vehicles`
SET `health_vehicles` = JSON_OBJECT('engine', 1000, 'body', 1000, 'fuel', 100)
WHERE `health_vehicles` IS NULL OR `health_vehicles` = '';

CREATE INDEX IF NOT EXISTS `idx_owned_vehicles_deposit` ON `owned_vehicles` (`deposit`);
CREATE INDEX IF NOT EXISTS `idx_owned_vehicles_owner_stored` ON `owned_vehicles` (`owner`, `stored`);
