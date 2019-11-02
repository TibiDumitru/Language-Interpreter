# Language-Interpreter

a) Realizarea unui mod de a retine informatiile specifice fiecarei clasa
	------------------------------------------------------------------------
		Pentru realizarea acestui subpunct a fost utilizat Map-ul din 
	Haskell, astfel un Classtate reprezinta un Map, fapt evident in 
	initializarea unui Classtate gol. Cheia este reprezentata de o lista de
	String, iar valoarea reprezinta tipul, adica Var / Func (variabila sau
	functie). Cheia am ales sa fie reprezentata de identificatorii pentru
	variabila sau functia respectiva, aceste detalii fiind unice pentru
	fiecare. In cazul unei variabile aceasta lista va contine numele si
	tipul, pe cand in cazul functiei va contine numele, tipul returnat si
	tipurile celor n parametri.
		Astfel, pentru inserare se tine cont de reprezentarea definita pentru
	cheie si pentru valoare. Acelasi lucru si pentru gasirea valorilor, unde
	a fost utilizata functia filter din Map, pentru a gasi toate variabilele
	din map, respectiv toate functiile.

	b) Realizarea functiilor de parsare si interpretare
	---------------------------------------------------
		In primul rand, a fost definita o clasa: tipul Class care contine un
	String ce reprezinta numele clasei, un String ce reprezinta clasa parinte
	a clasei curente si un ClassState, map ce contine informatiile clasei.
		Astfel, programul (Program) va fi definit ca o lista de clase, iar 
	Instruction reprezinta o linie citita ca input care reprezinta o comanda
	si trebuie interpretata. Deci initEmptyProgram va returna o lista vida.
		Dupa ce au fost definite Program si Instruction, a fost realizata 
	functia parse care are singurul scop de a imparti input-ul primit in linii
	(un split dupa '\n').
	! Pentru split-uri au fost utilizate functii din Data.List (lines, words).
		Urmeaza interpretarea fiecarei instructiuni, lucru realizat in functia
	interpret, care primeste o instructiune de interpretat si programul pana 
	in acel moment. In cazul in care programul (containerul de clase) pana in
	acel moment este gol (se apeleaza functia de interpretare prima data), se
	adauga la program clasa "Global" si se continua interpretarea. Astfel, 
	sunt 3 cazuri mari de analizat:
			- cazul in care primul cuvant din instuctiune este "class", adica
	se declara o clasa; in acest caz se verifica daca aceasta exista deja, caz
	in care se ignora si de asemenea, se verifica daca exista o informatie 
	explicita despre parinte, caz in care se seteaza campul parinte, iar in 
	caz contrar, va avea implicit parinte clasa Global. Dupa setarea tuturor
	campurilor, clasa este adaugata la containerul pentru program.
			- cazul in care primul cuvant din instructiune este "newvar",
	adica se declara o variabila; prima verificare care trebuie facuta este
	daca tipul variabilei este unul valid, aceasta realizandu-se prin 
	verificarea apartenentei la lista de clase a programului. Daca tipul este
	unul valid, se cauta clasa Global si se face un update in campul de tip
	ClassState al acesteia, unde se adauga variabila. Astfel, toate variabilele
	se gasesc in clasa Global. Pentru extragerea cuvintelor cheie din aceasta
	instructiune a fost mai intai inlocuit '=' cu ' ', pentru ca apoi sa fie
	realizat un simplu split dupa spatii.
			- cazul "otherwise": este vorba despre o functie. Se cauta clasa
	ceruta si se fac verificarile de tip (atat tipul returnat, cat si tipurile
	parametrilor reprezinta clase valide); daca sunt indeplinite conditiile
	mentionate, se adauga in campul info (de tip ClassState) al clasei gasite
	functia curenta (lista alcatuita din nume, tip returnat si tipurile celor
	n parametri).
		Dupa ce au fost interpretate toate instructiunile, functiile care 
	returneaza clasele, parintele unei clase, variabilele sau functiile, se
	rezuma la o simpla parcurgere a programului si gasirea clasei cautate. De 
	exemplu, pentru a obtine variabilele din program se cauta clasa Global si
	se apeleaza functia de la subpunctul a) pentru campul de tip ClassState,
	pentru a obtine o lista de variabile (nume si tip pentru fiecare).

	c) Inferenta de tip pentru o expresie
	-------------------------------------
		Primul pas a fost realizarea inferentei de tip pentru o variabila, caz
	in care se verifica daca variabila este una valida, apoi i se returneaza
	tipul.
		Pentru inferenta de tip in cazul unei functii, au fost concepute o 
	serie de functii ajutatoare:
			- getClassForF - functie care cauta clasa din care face parte
	functia primita ca parametru; aceasta cauta in clasa curenta si se apeleaza
	mereu recursiv cu clasa parinte pana cand gaseste functia; daca se ajunge 
	la clasa Global (parintele cel mai de sus), inseamna ca nu exista, se va
	returna Nothing. Dar ce inseamna ca s-a gasit o functie?
			- auxCheck - functie care raspunde la intrebarea de mai sus, 
	fiind cea care realizeaza verificarile necesare si anume: functia are
	numele dupa care a fost cautata, iar parametrii se potrivesc.
			- checkParam - functia care verifica daca parametrii se potrivesc,
	adica realizeaza inferenta pentru fiecare expresie din apelul de functie 
	si verifica daca rezultatul se potriveste cu parametrul corespunzator din
	functia gasita; verficarea trebuie facuta pentru toti parametrii.
		Astfel, ramane de facut doar verificarea de apartenenta a variabilei,
	apoi se gaseste clasa din care face parte functia data (cu ajutorul
	tuturor functiilor detaliate mai sus) si se extrage functia, apoi tipul
	returnat de ea, acesta reprezentand rezultatul inferentei.

