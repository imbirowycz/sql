
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
	