
proc options option=encoding;
run;
/* ENCODING=UTF-8    Specifies the default character-set encoding for the SAS session. */

libname b '/folders/myfolders/sbi_kolokwium/b';

/* przepisuje zbiory zeby mialy kodowanie sesji i ladne znaki */

libname c '/folders/myfolders/sbi_kolokwium' inencoding='any';
data b.czytelnik;
set c.czytelnik;
run;

data b.wypozyczenia;
set c.wypozyczenia;
run;

data b.ksiazka;
set c.ksiazka;
run;
/* na kolokwium nie bedzie takich problemow z kodowaniem */



/* Grupa 2 */

/* Zad 1*/

	/* 4GL */
	
	data b.ZAD1;
	set b.czytelnik;
	where aktywny=0 
		and data_zapisu between '01jan2007'd and '30jun2007'd;
	keep czytelnik_nazwisko czytelnik_imie adres data_zapisu;
	run;

	/* SQL */
	
	proc sql;
	create table b.ZAD1 as
		select czytelnik_nazwisko,
			czytelnik_imie,
			adres,
			data_zapisu
		from b.czytelnik
		where aktywny=0 
			and data_zapisu between '01jan2007'd and '30jun2007'd;
	quit;
	
/* Zad 2 */

	/* 4GL */
	
	proc sort data=b.czytelnik out=czytelnik_sorted;
	by adres;
	run;
	
	data b.ZAD2;
	set czytelnik_sorted;
	where substr(czytelnik_imie,length(czytelnik_imie),1)<>'a';
	by adres;
	if first.adres then liczba_czytelnikow=0;
	liczba_czytelnikow+1;
	if last.adres then output;
	keep adres liczba_czytelnikow;
	run;
	
	/* SQL */
	
	proc sql;
	create table b.ZAD2 as
		select adres, count(*) as liczba_czytelnikow
		from b.czytelnik
		where substr(czytelnik_imie,length(czytelnik_imie),1)<>'a'
		group by adres;
	quit;
	
	
/* Zad 3 */

	/* 4 GL */
	
	/* dodanie kolumny kategoria */
	data ksiazka_kategoria;
	length kategoria $ 16;
	set b.ksiazka;
	where jezyk = 'POL';
	if rok_wydania <= 1980 then kategoria = 'wydane do 1980';
	else if rok_wydania <= 2000 then kategoria = 'wydane 1980-2000';
	else kategoria = 'wydane po 2000';
	run;
	
	/* sortowanie przed grupowaniem */
	proc sort data=ksiazka_kategoria;
	by kategoria;
	run;

	/* grupowanie i zliczanie */
	data b.ZAD3;
	set ksiazka_kategoria;
	by kategoria;
	if first.kategoria then do;
		ilosc = 0;
		wartosc = 0;
	end;
	ilosc+1;
	wartosc+cena;
	if last.kategoria then output;
	keep kategoria ilosc wartosc;
	run;
	
	/* finalne sortowanie */
	proc sort data=b.ZAD3;
	by wartosc;
	run;

	/* SQL */
	
	proc sql;
	create table b.ZAD3 as
	select 
		case 
			when rok_wydania <= 1980 then 'wydane do 1980'
			when rok_wydania <= 2000 then 'wydane 1980-2000'
			else 'wydane po 2000'
		end as kategoria,
		count(*) as ilosc,
		sum(cena) as wartosc
	from b.ksiazka
	where jezyk = 'POL'
	group by calculated kategoria
	order by 3;
	quit;
	

/* Zad 4 */

	/* 4 GL */
	
	/* sortowanie przed merge */
	proc sort data=b.wypozyczenia out=wypozyczenia_sorted;
	by ksiazka_sygnatura;
	run;
	proc sort data=b.ksiazka out=ksiazka_sorted;
	by sygnatura;
	run;
	
	/* zlaczenie zbiorow */
	data wypozyczenia_ksiazka;
	merge ksiazka_sorted (where=(rok_wydania < 1960) in=a)
		wypozyczenia_sorted (rename=(ksiazka_sygnatura=sygnatura) in=b);
	by sygnatura;
	if a = b;
	run;
	
	/* sortowanie przed grupowaniem */
	proc sort data=wypozyczenia_ksiazka;
	by tytul autor_nazwisko;
	run;
	
	/* grupowanie i zliczanie */
	data b.ZAD4;
	set wypozyczenia_ksiazka;
	by tytul autor_nazwisko;
	if first.tytul then do;
		wypozyczenia = 0;
		nieoddane = 0;
	end;
	wypozyczenia+1;
	if data_oddania=. then nieoddane+1;
	if last.tytul then output;
	keep tytul autor_nazwisko wypozyczenia nieoddane;
	run;

	/* SQL */
	
	proc sql;
	create table b.ZAD4 as
		select k.tytul,
			k.autor_nazwisko,
			count(*) as wypozyczenia,
			sum(case when data_oddania=. then 1 else 0 end) as nieoddane
		from b.wypozyczenia w
		join b.ksiazka k
			on w.ksiazka_sygnatura = k.sygnatura
			and k.rok_wydania < 1960
		group by 1,2;
	quit;


Sas
/* tworzenie biblioteki */
libname s "C:\Users\STUDENT\Desktop\SBI" ;
/* SAS 4GL - przetwarzanie wierszowe */
/*1*/
/* pobierz dane z tabeli CARS, dokonujšc selekcji wierszy
tylko dla pojazdów Audi */
data s.AUDI ; /* data- uwtórz tabelę */
set sashelp.cars ; /* set- pobierz z*/
where make='Audi' ;
run ; /* znacznik konca bloku kodu */
/* 2 */
/* wybierz audi lub bmw oraz zachowaj tylko
kolumny make, model, invoice */
data s.audi_bmw; /*(keep=make Model Invoice)*/
set sashelp.cars ;
where make ='Audi' or make='BMW';
/*where make in ('Audi', 'BMW');*/
keep make Model Invoice; /*drop */
run;
;
/* 3 */
/* znajdz najdrozsze auto w tabeli, na podstawie
kolumny invoice */
/* najpierw sortowanie */
proc sort data=sashelp.cars
out=s.cars_sort (keep=make Model Invoice);
by descending invoice;
run;
data s.cars_sort;
set s.cars_sort ;
IF _N_<=5 ; /*_N_ - numerator */
run;
/* 4*/
/* jak zliczyć wartosc wszystkich pojazdów
w tabeli cars */
data s.wartosc_cars ;
set sashelp.cars end=koniec ;
/* znacznik konca tabeli*/
wartosc+invoice;
keep make model wartosc invoice;
if koniec then output;
/* zrzucę ostatni wiersz w tabeli*/
run;
/* 5 */
/* przetwarzanie w grupach */
/* podaj liczbę pojazdów w podziale na markę */
data s.liczba_pojazdow ;
set sashelp.cars ;
by make ; /* group by */
/* uwaga - dane musza być posortowane
wg danej kolumny*/
if first.make then liczba_pojazdow=0;
liczba_pojazdow + 1;if last.make then output;
/*if last.make;*/
keep make liczba_pojazdow ;
run;
/* 6 */
/* grupowanie */
/* podaj wartosc pojazdów w podziale na markę */
data s.wartosc_pojazdow ;
set sashelp.cars ;
by make ;
if first.make then wartosc_pojazdow=0;
wartosc_pojazdow + invoice;
if last.make then output;
keep make wartosc_pojazdow ;
run;
/*7*/
/* podaj ilosc i wartosc */
data s.wartosc_pojazdow ;
set sashelp.cars ;
by make ;
if first.make then do ;
liczba_pojazdow =0;
wartosc_pojazdow=0;
end;
liczba_pojazdow + 1;
wartosc_pojazdow + invoice;
if last.make then output;
keep make wartosc_pojazdow liczba_pojazdow ;
run;
/* ********************************************* */
/* Ćwiczenie - 07/10/2018 */
/* Temat: if then else */
/* 1 - Zadanie */
/* na podstawie kolumny invoce chcemy podzielić pojazdy na kategorie */
data s.kategoria_cenowa;
set sashelp.cars;
length kategoria $7;
if invoice<30000 then kategoria = 'tanie';
else if invoce<60000 then kategoria = 'srednie';
else kategoria = 'drogie';
keep make Model Invoice kategoria;
run;
/*2 */
/* na podstawie tabeli kategoria_cenowa zlicz pojazdy w kazdej kategorii cenowej
*/
proc sort data=s.kategoria_cenowa;
by kategoria;
run;
data s.liczba_pojazdow_zlicz;
set s.kategoria_cenowa;
by kategoria;
if first.kategoria then licz_pojazdy=0;
licz_pojazdy +1;
if last.kategoria then output;keep kategoria licz_pojazdy;
run;
/* 3 */
/* na podstawie kolumny invoce utwórz nowa kolumne nowa_cena ktora stanowi 90%
wartoci invoce, nowš cene zaokršglić do mc setnych */
data s.nowa_cena;
set sashelp.cars;
nowa_cena = ROUND(invoice * 0.9, 0.01);
keep make model Invoice nowa_cena;
format nowa_cena dollar12.2; /* forma wywietlania kolumny */
run;
/* daty w SAS */
/* 4 */
data s.daty;
dzis=today();
fromat dzis ddmmyy10.;
/* format dzis date9.; */ /* różne sš opcie */
wiek = dzis - '25JAN1995'd;/* zapis daty jako stalej */
dzien = day(dzis);
dzien_tyg = weekday(dzis);
mies = month(dzis);
kw = qtr(dzis);
run;
/*******************************************/
/* łšczenie tabel */
/******************************************/
/* wygenerujemy przykładowe tabele*/
/* tabla 1 */
data s.tabela_A;
do id=1 to 1000;
klomna_A='ABC';
output;
end;
run;
/* tabela 2 */
data s.tabela_B;
do identyfikator=1 to 15000 by 10;
klomna_B='BBB';
output;
end;
run;
/* INFO - klucz do łšczenia tabel musi mięć tę samš nazwę */
/* INFO - tabele do lšczenia muszš być w ten sam sposób posortowane po kloumnie
kluczu */
/* merge - łšczenie */
proc sort data=s.tabela_A;
by id;
run;
proc sort data=s.tabela_B;
by identyfikator;
run;
data s.marged;
merge s.tabela_A (in=a)
s.tabela_B (rename=(identyfikator=ID) in=b);
by id;
/* kolumna do łšczenia */
if a = b;
/* mechanizm łšczenia */ /* lub a=1 and b=1 */
run;/***************************************/
/* dane biblioteka */
libname b "C:\Users\STUDENT\Desktop\BIBL";
/* ustal czytelnikow ktorze nie oddali ksišzki */
/* ustal imie, nazwisko, miasto czytelnika */
proc sort data=b.CZYTELNIK;
by id;
run;
proc sort data=b.WYPOZYCZENIA;
by CZYTELNIK_ID;
run;
data b.czrna_lista;
retain CZYTELNIK_NAZWISKO CZYTELNIK_IMIE ADRES KSIAZKA_SYGNATURA;
merge b.CZYTELNIK (in=c)
b.WYPOZYCZENIA (rename=(CZYTELNIK_ID=ID) in=w where=(DATA_ODDANIA=.)
);
by ID;
if c=w;
keep CZYTELNIK_NAZWISKO CZYTELNIK_IMIE ADRES KSIAZKA_SYGNATURA;
run;
/******************************/
/* 21/10/2018 */
/*1*/
/* wybrac to 5 czytelnikow z najwiesza liczba wypozyczen */
data b.top_5 ;
set b.wypozyczenia;
by czytelnik_id;
if first.czytelnik_id then licz_ks=0;
licz_ks +1;
if last.czytelnik_id;
keep czytelnik_id licz_ks;
run;
proc sort data= b.top_5;
by descending licz_ks ;
run;
data b.top_5;
set b.top_5;
/*if _N_<=5 then output;*/
if _N_=5 then call symput('top5', licz_ks);
run;
data b.top_5;
set b.top_5;
if _N_<=5 or licz_ks>= &top5.;
run;
/* Połacz tabelą czytelnik - imie, nazwisko, adres*/
proc sort data= b.top_5;
by czytelnik_id;
run;
data b.top_5_czytelnicy;
merge b.czytelnik (in=c)
b.top_5(in=t rename=(czytelnik_id=id));by id;
if c=t;
keep Czytelnik_imie czytelnik_nazwisko adres licz_ks;
run;
/*2*/
/* Na podstawie imienia(tab:czytelnik) ustalić płec czytelnikow i zliczyc
ksiazki w podziale na plec*/
data b.plec ;
set b.czytelnik;
if substr(Czytelnik_imie,length(Czytelnik_imie),1)='a' then
plec='K';
else plec='M';
keep id Czytelnik_imie plec;
run;
proc sort data= b.plec;
by plec;
run;
data b.plec_wynik ;
set b.plec;
by plec;
if first.plec then licz_ks=0;
licz_ks +1;
if last.plec;
keep plec licz_ks;
run;
/*************************/
/* SAS SQL */
proc sql;
create table b.czytelnik_gdynia as
select *
from b.czytelnik
where adres='Gdynia';
/*quit;*/
/* Case - when*/
proc sql;
create table b.podzial_ksiazek as
select tytul, autor_nazwisko, rok_wydania,
case when rok_wydania<=1980 then 'stare'
when rok_wydania<=2000 then 'wspolczesne'
else 'najnowsze'
end as kategoria
from b.ksiazka;
/* ustal najdrozsza ksiazke w tabeli*/
/*Podaj tytul autora i cene*/
/*a*/
proc sql;
select autor_nazwisko, tytul, cena
from b.ksiazka
where cena= (select max(cena) from b.ksiazka);
/*b*/
proc sql;
select autor_nazwisko, tytul, cena
from b.ksiazka
having cena=max(cena) ;
/*C*/
proc sql outobs=1;select autor_nazwisko, tytul, cena
from b.ksiazka
order by cena desc;
/*7*/
/*ustal liczbe czytelników z kazdym z miast i podaj udzial procentowy*/
/*Misto liczba czytelników, udzial procentowy*/
proc sql;
create table b.udzial_czytelnikow as
select adres, count(*) as liczba_czytelnikow),
(select count(*) from b.czytelnik) as total,
count(*)/(select count(*) from b.czytelnik) as udzial_pct format percent8.2
from b.czytelnik
group by /*ades*/ 1;
	
