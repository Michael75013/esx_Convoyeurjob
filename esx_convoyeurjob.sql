USE `essentialmode`;

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_banker','Banque',1),
	('bank_savings','Livret Bleu',0)
;

INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES
	('society_banker', 'Banquier', 1)
;

INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES
	('society_banker', 'Banquier', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('banker','Banquier')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('banker',0,'advisor','Banque-Stagiaire',600,'{}','{}'),
	('banker',1,'banker','Banque-Convoyeur',900,'{}','{}'),
	('banker',2,'business_banker',"Banque-Che d'équipe",1200,'{}','{}'),
	('banker',3,'viceboss','Banque-Adjoint',1450,'{}','{}'),
	('banker',4,'boss','Banque-Patron',1800,'{}','{}')
;
