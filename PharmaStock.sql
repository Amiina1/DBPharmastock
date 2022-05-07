create database PharmaStock
drop database PharmaStock
use PharmaStock

create table Medicament (
	NumMedicament int primary key, 
	Designation varchar(250), 
	Forme varchar(250), 
	DatePeremption Date, 
	StockActuel int,
	StockMin int
)

create table Medecin (
	NumMedecin int primary key, 
	NomMd  varchar(250), 
	PrenomMd varchar(250), 
	Specialite varchar(250), 
	LoginMd varchar(250) unique, 
	PassMd varchar(250)
)

create table Pharmacien (
	NumPharmacien int primary key, 
	NomPh varchar(250), 
	PrénomPh varchar(250), 
	LoginPh varchar(250) unique, 
	PassPh varchar(250)
)

create table Patient (
	NumPatient int primary key,
	NomP varchar(250), 
	PrenomP varchar(250), 
	DateNaissance Date
)

create table Ordonnance (
	NumOrdonnance int primary key identity , 
	Numpatient int  constraint fk_ordonnance_patient
					foreign key(Numpatient)
					references Patient(NumPatient)
					on update cascade 
					on delete cascade,

	NumMedecin int constraint fk_ordonnance_medecin
					foreign key(NumMedecin)
					references Medecin(NumMedecin)
					on update cascade 
					on delete cascade, 
	DateOrdonnance Date
)

create table DetailOrdonnance (
	NumOrdonnance int constraint fk_detailOrdonnance_ordonnance
						foreign key(NumOrdonnance)
						references Ordonnance(NumOrdonnance)
						on update cascade 
						on delete cascade,
	NumMedicament int constraint fk_detailOrdonnance_medicament
						foreign key(NumMedicament)
						references Medicament(NumMedicament)
						on update cascade 
						on delete cascade,
	QttePrescrite int
)
---------------------------------------------------------------------------------------------------------------------
--Q1
create table Medicament (
	NumMedicament int primary key, 
	Designation varchar(250), 
	Forme varchar(250), 
	DatePeremption Date, 
	StockActuel int,
	StockMin int
)

create table Medecin (
	NumMedecin int primary key, 
	NomMd  varchar(250), 
	PrenomMd varchar(250), 
	Specialite varchar(250), 
	LoginMd varchar(250) unique, 
	PassMd varchar(250)
)

create table Pharmacien (
	NumPharmacien int primary key, 
	NomPh varchar(250), 
	PrénomPh varchar(250), 
	LoginPh varchar(250) unique, 
	PassPh varchar(250)
)

create table Patient (
	NumPatient int primary key,
	NomP varchar(250), 
	PrenomP varchar(250), 
	DateNaissance Date
)

create table Ordonnance (
	NumOrdonnance int primary key identity , 
	Numpatient int,
	NumMedecin int,
	DateOrdonnance Date
)

create table DetailOrdonnance (
	NumOrdonnance int,
	NumMedicament int ,
	QttePrescrite int
)
---------------------------------------------------------------------------------------------------------------------
--Q2)
--Table Ordonnance
alter table Ordonnance
add constraint fk_ordonnance_patient
					foreign key(Numpatient)
					references Patient(NumPatient)
					on update cascade
					on delete cascade

alter table Ordonnance
add constraint fk_ordonnance_medecin
					foreign key(NumMedecin)
					references Medecin(NumMedecin)
					on update cascade 
					on delete cascade
--Table NumOrdonnance
alter table DetailOrdonnance
add constraint fk_detailOrdonnance_ordonnance
					foreign key(NumOrdonnance)
					references Ordonnance(NumOrdonnance)
					on update cascade 
					on delete cascade

alter table DetailOrdonnance
add constraint fk_detailOrdonnance_medicament
						foreign key(NumMedicament)
						references Medicament(NumMedicament)
						on update cascade 
						on delete cascade

--Q2/a)
alter table Medicament
add constraint check_Forme check (Forme in('comprimés','gélules', 'sirop', 'spray', 'pommade'))

--Q2/b)
alter table Medicament
add constraint check_StockActuel check (StockActuel >= StockMin)

--Q2/c)
alter table Medecin
add constraint	check_PassMd check (PassMd is not null)

alter table Pharmacien
add constraint	check_PassPh check (PassPh is not null)

alter table Pharmacien
add constraint	check_PassPh check (len(PassPh) != 0)

---------------------------------------------------------------------------------------------------------------------
--Ordonnance => Medecin / Patient / DetailOrdonnance
--   وصفة طبية => طبيب / مريض / وصفة طبية تفصيلية    
--Detail Ordonnance => Medicament
--      تفاصيل الوصفة => الدواء

---------------------------------------------------------------------------------------------------------------------
--Q3)
select top 5 Me.NumMedicament,Designation from Medicament Me
inner join DetailOrdonnance Do on Do.NumMedicament = Me.NumMedicament
group by Me.NumMedicament,Designation
order by QttePrescrite desc
---------------------------------------------------------------------------------------------------------------------
--Q4)
create function getCountOrdonnance(@nomMedcin varchar(250))
returns int
as
begin
	declare @countOrdenance int 
	select @countOrdenance=count(NumOrdonnance) from Ordonnance Dr
	inner join Medecin Md on Md.NumMedecin = Dr.NumMedecin
	where NomMd like @nomMedcin

	return  @countOrdenance
end
--execute
select dbo.getCountOrdonnance('abdelali')
---
declare @count int
set @count = dbo.getCountOrdonnance('abdelali')
print @count
---------------------------------------------------------------------------------------------------------------------
--Q5)
--M1
create procedure medcineListe(@specialite varchar(250))
as 
begin
	select Md.NumMedecin from Medecin Md
	inner join Ordonnance Dr on Dr.NumMedecin = Md.NumMedecin
	where MONTH(getdate()) = MONTH(DateOrdonnance)
	group by Md.NumMedecin
	having count(NumOrdonnance) >= 50
	and Specialite = @specialites
end
--M1
create procedure medcineListe2(@specialite varchar(250))
as 
begin
	select * from Medecin Md
	where NumMedecin in(
		select NumMedecin from Ordonnance
		where MONTH(GETDATE()) = MONTH(DateOrdonnance)
		group by NumMedecin 
		having(NumMedecin) >= 50
		and Specialite like @specialite
	)
end


---------------------------------------------------------------------------------------------------------------------
--Q6)
create trigger  mettreAjour
on DetailOrdonnance 
for insert
as
begin
	declare @numOrdonnance int,
			@numMedicament int ,
			@numPatient int,
			@moi int ,
			@total int,
			@qtte int

	select @numOrdonnance = NumOrdonnance from inserted
	select @numMedicament = NumMedicament from inserted
	select @qtte = qttePrescrite from inserted

	select @numPatient = NumPatient , 
		   @moi = Month(DateOrdonnance) from Ordonnance
		   where NumOrdonnance = @numOrdonnance 

	select @total = sum(QttePrescrite) from DetailOrdonnance Do
	inner join Ordonnance Ord on  Ord.NumMedecin = Do.NumMedicament
	where Numpatient = @numPatient 
	and NumMedicament =  @numMedicament
	and Month(DateOrdonnance) = @moi

	if(@total > 20) 
		rollback
	else
		update Medicament set StockActuel -= @qtte 
		where NumMedicament = @numMedicament			
end

---------------------------------------------------------------------------------------------------------------------
--Q7)
create proc DiminuStockMin @Taux real
as begin
update Medicament set StockMin *= (1 - @Taux/100) where NumMedicament not in ( select NumMedicament from DetailOrdonnance )
end
---------------------------------------------------------------------------------------------------------------------