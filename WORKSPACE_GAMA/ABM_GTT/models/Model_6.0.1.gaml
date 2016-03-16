/**
 *  Model_5.1
 *  Author: Alessandro
 *  Description: 
 */

model Model6

/* Insert your model definition here */
global
{
	// Posizione luoghi d'interesse a Torino
	file shape_file_cinema <- file("../includes/ridottissimo/cinema_geo.shp");
	file shape_file_sport_center <- file("../includes/ridottissimo/impianti_sportivi_geo.shp");
	file shape_file_museum <- file("../includes/ridottissimo/musei_geo.shp");
	file shape_file_hospital <- file("../includes/ridottissimo/ospedali_geo.shp");
	file shape_file_school <- file("../includes/ridottissimo/scuole2.shp");
	file shape_file_ASL <- file("../includes/ridottissimo/sedi_asl_geo2.shp");
	file shape_file_university <- file("../includes/ridottissimo/universita_geo.shp");
	file shape_file_theater <- file("../includes/ridottissimo/teatri_geo.shp");
	// Definiamo i nodi della rete di trasporti di Torino, con codice fermata e locazione geografica in 2D
	file shape_file_stops <- file("../includes/ridottissimo/transport_points_4.shp");
	// Edges della nostra rete di trasporti
	file csv_edges_list <- csv_file("../includes/ultimate_edges_list_ext_noint.csv", ",");
	matrix edge_list_matrix <- matrix(csv_edges_list); //utile per il ciclo di assegnazione
	// Matrice dell'attività degli edifici per fascia oraria.
	file csv_orario <- csv_file("../includes/orari.csv", ",");
	matrix<int> orario <- matrix<int> (csv_orario);
	// Matrice dell'attrazione degli edifici a seconda del tipo utente
	file csv_affinity <- csv_file("../includes/affinity.csv", ",");
	matrix<float> affinity <- matrix<float> (csv_affinity);
	// Mmatrice delle probabilità di muoversi di ogni utente a seconda della fascia oraria
	file csv_mobility <- csv_file("../includes/mobility3.csv", ",");
	matrix<float> mobility <- matrix<float> (csv_mobility);
	// Per ogni fermata: lista di tutte le fermate raggiungibili in mezz'ora
	file csv_raggiungibile <- csv_file("../includes/ridottissimo/raggiungibili.csv", ",");
	matrix<int> raggiungibili <- matrix<int> (csv_raggiungibile);
	// Per ogni fermata: matrice di attrazione di ogni utente, a seconda dell'orario, creata in base agli edifici d'interesse a meno di 500 metri
	file csv_pesi <- csv_file("../includes/ridottissimo/pesi.csv", ";");
	matrix<int> Pesi <- matrix<int> (csv_pesi);
	// Betweenness calcolate per ogni edge della rete
	file csv_betweenness <- csv_file("../includes/ridottissimo/betweenness.csv", ",");
	matrix<float> bwn <- matrix<float> (csv_betweenness);

	bool input_csv <- false;
	graph grafo;
	float time_offset <- 0.0;
	// 40 cicli al giorno di mezz'ora
	int fascia_oraria update: int(time / 4) mod 10; // 10 fasce oraria di 2 ore ciascuna (per interessi)
	int macro_fascia update: int(time / 10) mod 4; // 4 macrofasce orarie di 5 ore (strategia controllori)
	int day update: int(time / 40) + 1; // Update giornaliero
	int multa;
//	bool salva <- true update:(time < 2000?((time mod 150 =0)? true:false):((time mod 800 =0)? true:false));
	int n_controllori<-4;
	int n_passenger<-15000; // Tutti gli utenti presenti nel modello
	float ticket;
	// Ad ogni viaggio, il peso di un controllo viene moltiplicato per il  float dimenticanza, o dimenticanza2
	float dimenticanza <- 0.9862327;
	float dimenticanza2 <- 0.9986;
	float abbonamento;
	float betw_max;
	float scala;
	float Flip <-0.5;
	int index <- 0; // Codice numero esperimento a 0
	list<bus_stop> active_stops;
	// File in cui vengono salvati eventuali file durante l' experiment
	string salvataggio <- "./exports/15_11/"; // File in cui vengono salvati eventuali file durante l' experiment
init
	{
		//write fit_abbonamento;
		index<-rnd(10000); // Codice numero esperimento a 0
		multa <- 50; // Costo multa
		fascia_oraria <- 0; // Inizializzazione fascia oraria a 0
		ticket <- 1.5; // Costo biglietto
		abbonamento <- 40.0; // Costo abbonamento mensile
		// scala serve per il saturation_index e dipende dalla grandezza della rete: se RIDOTTISSIMO 56239, se RIDOTTO 320000 
		scala <- 29782 / n_passenger;
		// Creazione degli agenti relativi ai luighi d'interesse con codice identificativo
		// e posizione geografica (riscalati di un fattore 0.01 per la visualizzazione grafica
		create building from: shape_file_cinema with: [type:: 0, id::int(read("ID_CINEMA")) - 1, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_sport_center with: [type:: 1, id::int(read("ID_R_IMP_T")) + 47, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_museum with: [type:: 2, id::int(read("ID_TIPOPTO")) + 749, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_hospital with: [type:: 3, id::int(read("ID_OSPEDAL")) + 834, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_school with: [type:: 4, id::int(read("ID_PT_INGR")) + 796, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_ASL with: [type:: 5, id::int(read("ID_ASL")) + 1493, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_university with: [type:: 6, id::int(read("ID_UNIVERS")) + 1504, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_theater with: [type:: 7, id::int(read("ID_R_PUNTO")) + 1537, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		// Creazione bus_stop con cosice identificativo e posizione geografica
		// (Riscalati di un fattore 0.01 e traslati per la visualizzazione grafica)
		// presi dallo shape_file di GTT
		create bus_stop from: shape_file_stops with: 
		[
			code::int(read("ref")), 
			location::{ float(read("XCOORD")) / 100 - 8460, 
			float(read("YCOORD")) / 100 - 56300, 0}, 
			fattore_scelta::list_with(6, 0.0)
		]; // Ciascuno ha una lista nulla lunga 6, utile per l'interesse della femrata
		write "bus_stop creati";
		// Creazione utenti
		// set_appeal_matrix lo faccio qui e non nell'init della specie perchè alla fine dell'init cancello 
		if input_csv = true
		{
			time <- time_offset;
			file fileCSVpasseggeri <- file(salvataggio + "passenger_population" + int(time_offset) + ".csv");
			matrix initiop <- matrix (fileCSVpasseggeri);
	
			file fileCSVSmith <- file(salvataggio + "Smith_population" + int(time_offset) + ".csv");
			matrix initioS <- matrix (fileCSVSmith);
	
			file fileCSVGTKIRA <- file(salvataggio + "GTKIRA_population" + int(time_offset) + ".csv");
			matrix initioG <- matrix (fileCSVGTKIRA);

			file fileCSVwedge <- file(salvataggio + "wedge_population" + int(time_offset) + ".csv");
			matrix initiow <- matrix (fileCSVwedge);
			matrix<string> initio2p <- (initiop - first(rows_list(initiop))) as_matrix({length(columns_list(initiop)),length(rows_list(initiop))-1});
			loop row over: rows_list(initio2p) //where(each!=first(rows_list(initiop)))//[list<int>(columns_list(initiop)[0]-';#')]
			{
				create passenger
				{
					avg_mobility <- float(row[1]);
					avg_risk <- float(row[2]);
					fermata <- bus_stop[int((list(row[4])-[' ','as' ,'bus_stop'])[0])];
					flag_abbonamento <- bool(row[5]);
					flag_movimento <- false;
					location <- fermata.location;
					num_viaggi <- float(row[10]);
					risk <- matrix<float> ((list(row[12])-['[',']',',',' as matrix']) as_matrix({5,3}));
					titolo_viaggio <- int(row[15]);
					travel_mode <-3;
					type <- int(row[17]);
					viaggi <- matrix<float> ((list(row[18])-['[',']',',', ' as matrix']) as_matrix({5,3}));
				}
			}
			n_passenger <- length(passenger);
			write "passenger creati";
			matrix<string> initio2w <- (initiow - first(rows_list(initiow))) as_matrix({length(columns_list(initiow)),length(rows_list(initiow))-1});
			loop row over: rows_list(initio2w)
			{
				create wedge
				{
            	    partenza <- bus_stop[int((list(row[8])-[' ','as' ,'bus_stop'])[0])];
					arrivo <- bus_stop[int((list(row[1])-[' ','as' ,'bus_stop'])[0])];
   		            avg_penality <- list<float>(list(row[2]) - ['[', ']',',']);
   		            avg_score <- list<float>(list(row[3]) - ['[', ']',',']);
    	            btw <- float(row[4]);
    	            fascia_btwn <- int(row[5]);
					penality <- float(row[9]);
					peso <- int(row[10]);
					popolazione <- int(row[11]);
					popolazione_old <- int(row[12]);
					saturation_index <- int(row[13]);
					score <- float(row[14]);
					shape <- line([partenza.location, arrivo.location],0.15);
             	}
			}

			write "wedge creati";
			betw_max <- max(wedge collect each.btw); // Seleziona la betweenness maggiore

			matrix<string> initio2S <- (initioS - first(rows_list(initioS))) as_matrix({length(columns_list(initioS)),length(rows_list(initioS))-1});
			loop row over: rows_list(initioS) where(each!=rows_list(initioS)[0])
			{
				create Smith
				{
					score <- list<int>(list(row[4]) - ['[', ']',',']);
					targets <- list<wedge>(list<int>(list(row[5])-['[',']',',']));
				}
			}	

			matrix<string> initio2G <- (initioG - first(rows_list(initioG))) as_matrix({length(columns_list(initioG)),length(rows_list(initioG))-1});
			loop row over: rows_list(initio2G)
			{
				list fr_row <- list<int>(list(row[3])-['[',']',',',' ','as', 'wedge']);
				list<list<int>> t_list <- list_with(4, list_with(10*length(Smith),1)); //aggiustare con 10*n_controllori
				loop i from:0 to:3
				{
					loop j from:0 to:10*length(Smith)-1
					{
						t_list[i][j]<-fr_row[10*i+j];
					}
				}
			
				create GTKIRA
				{
					target_list <- list<list<wedge>>(t_list);
					total_risk <- float(row[4]);
					utility <- float(row[5]);
				}
			}
			write "ci sono";
			create Smith number: n_controllori - length(Smith);
		}
		else
		{
			index <- rnd(10000);
			time <- 0.0;
			create passenger number: n_passenger
			{
				bus_stop locazione <- one_of(bus_stop);
				the_target <- one_of(bus_stop);
				location <- locazione.location;
				fermata <- locazione;
				type <- rnd(5);
				risk <- 0.00 as_matrix ({ 5, 3 }); //colonne:saturation_index, righe:betweenness
				avg_mobility <- mean(list<float> (rows_list(mobility)[type]));
			}	
			loop j from: 0 to: length(rows_list(edge_list_matrix)) - 1
			{
//				int arrivo2 <- int(edge_list_matrix[1, j]);
//				int partenza2 <- int(edge_list_matrix[0, j]);
				if ((bus_stop where (each.code = int(edge_list_matrix[0, j]))) != [] and (bus_stop where (each.code = int(edge_list_matrix[1, j]))) != [])
				{
					create wedge
					{
						arrivo <- (bus_stop where (each.code = int(edge_list_matrix[1, j])))[0];
						partenza <- (bus_stop where (each.code = int(edge_list_matrix[0, j])))[0];
						peso <- (int(edge_list_matrix[2, j]));
						shape <- line([partenza.location, arrivo.location],0.15);
						popolazione_old <- rnd(30);
					}
				}
			}

			write "wedge creati";
			ask wedge
			{
				do set_betweenness;
			}
			betw_max <- max(wedge collect each.btw); // Seleziona la betweenness maggiore
			create GTKIRA;
			create Smith number: n_controllori;
		}

		grafo <- directed(as_edge_graph(wedge)); // Mette gli edges nel grafo che disegneremo
		ask bus_stop
		{
			do set_appeal_matrix; // metto matrici di pesi nei corrispettivi bus_stop
		}

		write "inizio raggiungibili";
		ask bus_stop
		{
			do set_raggiungibili; // Ad ogni fermata assegna la lista delle fermate raggiungibili in mezz'ora
			do trova_vicini_geografici; // Per ogni fermata seleziona tutte le fermate lontane meno di 250 metri
			do trova_out_edges;
			list_raggiungibili <- list_raggiungibili - [0]; // Togliamo le liste nulle
			// INFINE
			// In stop_raggiungibili metto solo le bus_stop che sono effettivamente esistenti tra le bus_stop
			stop_raggiungibili <- bus_stop where (each.code in list_raggiungibili); //assegnazione reale
			list_raggiungibili <- nil; // Tanto non ci serve più
		}
		write "removing duplicates";
		write "fine raggiugibili";
		// Pulizie di primavera a novembre
		Pesi <- nil;
		raggiungibili <- nil;
		edge_list_matrix <- nil;
		// active_stops sono le bus_stop che non raggiungono solo se stesse.
		active_stops <- bus_stop where(each.stop_raggiungibili != [each]); // ridotto la rete ==> fermate scollegate ==> cancellazione fermate di troppo

	}
}

species building
{
	int id;
	int type;
	aspect base
	{
		draw square(2) color: # red; // gli edifici saranno rappresentati come quadrati rossi
	}

}

species bus_stop
{

	int code; //codice fermata
	int popolazione_old update: popolazione; // popolazione_old è il numero di utenti presenti sulla fermata al turno precedente
	int popolazione;
	list<wedge> out_edges;
	list<bus_stop> vicini_geo;
	list<int> list_raggiungibili;
	list<bus_stop> stop_raggiungibili;
	list<float> fattore_scelta; //exp (-popolazione/proiezione) per ogni tipo di utente (lista 6 float)
	matrix<int> appeal_matrix <- 0 as_matrix ({ 10, 6 }); //Matrice di contenimento dei pesi definiti da fascia e utente
	action set_raggiungibili // ad ogni fermata assegna la lista delle fermate raggiungibili in mezz'ora
	{ // (first_with prende il primo di una lista)
		self.list_raggiungibili <- list<int> (rows_list(raggiungibili) first_with (each[0] = self.code));
	}

	action trova_out_edges
	{ // Trova i wedge con solo partenza al loro interno
		out_edges <- (wedge where (each.partenza = self));
	}

	action trova_vicini_geografici
	{ // Per ogni bus_stop seleziona tutte le fermate lontane meno di 250 metri
		vicini_geo <- bus_stop where (each distance_to self < 2.5);
	}

	action set_appeal_matrix
	{
		// Metto ogni matrice dei pesi nella corrispettiva bus_stop
		int riga <- int(columns_list(Pesi)[0] first_with (each = self.code));
		loop colonna from: 1 to: 10
		{
			loop riga_int from: 1 to: 6
			{	// (i - 1 perché in pesi l'indice 0,0 è il codice di fermata e 0,i e 0,j sono nulli)
				self.appeal_matrix[colonna - 1, riga_int - 1] <- Pesi[colonna, riga + riga_int];
			}

		}

	}

	reflex update_fattore_scelta
	{
	//ho creato un vettore con exp (-popolazione/proiezione[tipo, ora] per ogni tipo)
		fattore_scelta <- columns_list(appeal_matrix)[fascia_oraria] collect (exp(-popolazione_old / (int((each)) + 0.00001)) + 0.0001);
		popolazione <- 0;
	}

	aspect base
	{
		draw square(1.5) color: # pink; // bus_stop saranno rappresentate ocn quadratini rosa
	}

}

species wedge
{
	init
	{
		fascia_btwn <- 0;//min([2,int(self.btw * 3 / betw_max)]);
		shape <- line([partenza.location, arrivo.location],0.15*(1+0.5*fascia_btwn));
		
	}

	int popolazione_old update: popolazione; // come per bus_stop popolazione_old è il numero di utenti presenti sulla fermata al turno precedente
	int popolazione; //agenti che viaggiano sull'edge. Posto a 0 ogni inizio turno dal reflex (così viene posto a 0 dopo che popolazione_old copia il valore)
	bus_stop partenza;
	bus_stop arrivo;
	float penality <- 1.0 update: 1.0; // Ogni turno viene aggiornato ad 1 (sarà utilizzato dai controllori smith)
	list<float> avg_penality <- list_with(4, 1.0); // Diviso in 4 macrofasce (sarà utilizzato da GTKIRA)
	float btw;
	int fascia_btwn max:4;
	float score;
	list<float> avg_score <- list_with(4, 0.0); // Sarà usato dai controllori
	int peso;
	int saturation_index max:4; // update: min([3,int(48*popolazione/25*peso)]);
	aspect base
	{
		draw shape color:(penality=1.0? #black:#red); // Colora di rosso se è controllata, altrimenti nero.
	}

	reflex update_variables
	{
		// saturation_index valuta quanto un pullman sia pieno
		// prediamo la popolazione presente su quell'edge e la dividiamo per il numero di tratte
		//e poi lo riscaliamo per avere dei pullman rapportabili alla realtà.
		saturation_index <- int(floor(48*4*(scala/100)) * (self.popolazione_old / self.peso)); //vale per ridottissimo
		// Serve a GTKIRA per gestire i controlli
		score <- (btw / betw_max) * exp(-3.25)*3.25^(saturation_index)/fact(saturation_index);
		popolazione <- 0; // Azzeriamo popolazione per ricominciare ad agiungerla dopo
		// Assegna ad ogni macrofascia uno score ad ogni edge, per stipare quanto sia interessante da controllare
		avg_score[macro_fascia] <- avg_score[macro_fascia] + score / 70;/////////////////////////////////////////////////////////////////////////
		//lo score medio viene valutato ogni 280 step, quindi aggiungo lo score già diviso per 280
	}

	action set_betweenness
	{
		// Mette in btw di ogni agente wedge la betweenness corrispondente calcolata precedemntemente
		self.btw <- float((rows_list(bwn) where ((each[0]) = float(wedge index_of self)))[0][1]);
	}

}

species passenger skills: [moving]
{
	bus_stop the_target;
	bus_stop fermata;
	bool flag_abbonamento <- false; // Inizialmente senza abbonamento
	bool flag_movimento <- false update: false; // Tutti i turni azzeriamo il movimento, poi lo studiamo tutti i turni
	float avg_risk <- 0.0; // Inizialmente il rischio d'incontrare un controllore è messo a zero, salirà con i controlli.
//	float avg_risk_balance <- 0.0 update:0.0;//misura di quanto è cambiato il rischio medio nell'ultimo turno				**NEW
	float avg_mobility;
	float num_viaggi <- 0.0; // Inizialmente assumiamo che non siano stati fatti viaggi
	// Matirce che consideta 5 fasce di saturazione di una tratta e 3 fasce di betweenness
	matrix<float> viaggi <- 0.0 as_matrix ({ 5, 3 });	
	matrix<float> risk;
	int type;
	// Se l'utente acquista un biglietto o abbonamento titolo_viaggio diventerà più grande, qui 
	// lo diminuiamo di uno ad ogni ciclo, per simulare il passaggio del tempo e la scadenza del titolo di viaggio.
	int titolo_viaggio min: 0 update: titolo_viaggio - 1;
	// Ad ogni inizio turno pone a tre travel_mode ==> viaggia, e poi studierà cosa fare.
	int travel_mode update: 3; // 0-> viaggio alternativo; 1 -> viaggio senza ticket; 2-> viaggio con ticket; 3 -> il flip (mobility) ha dato croce)
	path percorso <- path(0) update: path(0); //ogni inizio turno il percorso va azzerato!

	reflex decisione_abbonamento when: (every(40) and titolo_viaggio < 40)
	{
		// Qui ogni l'utende decide se fare l'abbonamento (e fa questa decisione una volta al giorno (every(40) e se non ha 
		// ancora un abbonamento per il giorno dopo.
		//
		// L'abboanamento dura un mese (1200 cigli)
		// Valuta razionalmente se costa di meno fare un abbonamento mensile, oppure viaggiare alla giornata
		// comparando il prezzo dell'abbonamento con il minimo tra prezzo di fare biglietti singoli o probabilità
		// di rpednere la multa per il costo delle multa, considerando il numero dei viaggi che pensa di fare nel
		// prossimo mese
		if (1200*self.avg_mobility*min([(self.avg_risk/max([1,self.num_viaggi]))*multa,ticket]) > abbonamento) //AGGIUNGERE GAUSSIANA
		{
			// Se si decide di fare l'abbonamento titolo viaggio ci mette un mese per azzerarsi
			titolo_viaggio <- 1200;
			GTKIRA[0].utility <- GTKIRA[0].utility + abbonamento; // GTKIRA prende soldi
			flag_abbonamento <- true; // variabile "ho/non ho abbonamento"
		} 
		else
		{
			flag_abbonamento <- false; // variabile "ho/non ho abbonamento"
		}

	}
	// L'utente decide se muoversi utilizzando un flip
	// Se ha un titolo di viaggio viaggia con 0.4*(probabilità di viaggiare senza titolo) in più di probabilità
	reflex movimento when: flip((1 + 0.4 * signum(titolo_viaggio)) * mobility[fascia_oraria, type])
	{
		flag_movimento <- true; // Varibile del movimento
		// Nel tagliare la rete per rimpicciolirla queste fermate sono rimaste isolate
		// quindi mandiamo in posiizioni random gli utenti che si trovano in queste fermate.
		if fermata = bus_stop[147] or bus_stop[431] or bus_stop[430] or bus_stop[285] or bus_stop[143] or bus_stop[406]
		{
			fermata <- any(bus_stop);
			location <- fermata.location;
		}
		// L'utente sceglie random di andare "a piedi" in una fermata vicina geograficamente che sarà la sua partenza.
		fermata <- (fermata.vicini_geo)[rnd_choice(fermata.vicini_geo collect each.fattore_scelta[type])];
		if (fermata in active_stops) // Tutele da errori!
		{
			// Sceglie la fermata di arrivo dell'utente a random tra quelle che distano meno di 30 minuti
			the_target <- (fermata.stop_raggiungibili-fermata)[rnd_choice((fermata.stop_raggiungibili - fermata) collect each.fattore_scelta[type])]; //scelta meta viaggio
		}
		else
		{
			// Se quella fermata da problemi l'utente verrà teletrasportato a random su un altra fermata e
			// verrà rifatta la scelta.
			fermata <- any(active_stops);
			the_target <- (fermata.stop_raggiungibili-fermata)[rnd_choice((fermata.stop_raggiungibili - fermata) collect each.fattore_scelta[type])];
		}
		percorso <- path_between(grafo, fermata.location, the_target.location); // Usiamo il grafo di Gama per definire il percorso
		  //1 - prob che non ti controlli nessuno (probabilità calcolata moltiplicando le frequenze mediate nel tempo
		  // che su ciascuno degli edge presenti sulla tratta si venga controllati)
		float risk_max <- 1 - mul(list<wedge> (percorso.edges) collect (1 - (risk[each.saturation_index, each.fascia_btwn] / (max([1,viaggi[each.saturation_index, each.fascia_btwn]])))));
		// Paura generale che ogni utente prenda una multa al di là del posto in cui si trovi, per scelta abbonamento
		float avg_risk_old <- avg_risk/max([1,num_viaggi]); //occhio: è già diviso per numero viaggi
		// Utente dipende con una legge di potenza ogni volta che viaggia e ogni volta si somma l'eventuale nuovo controllo
		avg_risk <- dimenticanza * avg_risk + risk_max;
		// Ci si dimentica anche dei viaggi fatti per non sottostimare il rischio generale
		num_viaggi <- num_viaggi * dimenticanza + 1;
		//avg_risk_balance <- avg_risk/num_viaggi - avg_risk_old; //positivo: rischio medio aumentato, negativo: rischio diminuito
		list<float> utility <- list_with(3, 0.0);
		// Qui calcoliamo le utility di viaggiare con biglietto, senza o non viaggiare
		utility[0] <- exp(-length(percorso.edges)); //NonViaggio
		utility[1] <- 1 - exp(-length(percorso.edges) / (risk_max * multa + 0.001)); //ViaggioSenzaTicket
		utility[2] <- 1 - exp(-length(percorso.edges) / ticket) + self.titolo_viaggio; //ViaggioConTicket <- aggiungere bonus abbonamento?/////////////////////////////////////////////////////////////////////////////////////////
		travel_mode <- utility index_of (max(utility)); // L'indice dell'utility massima viene assegnata a travel_mode
		
		if (travel_mode = 2 and titolo_viaggio = 0)
		{ // 2 = voglio viaggiare e non voglio fare il portoghese, 0 = non ho il biglietto, ma me lo faccio
			self.titolo_viaggio <- 3; // Durata biglietto a 1 ora e mezza
			GTKIRA[0].utility <- GTKIRA[0].utility + ticket; // GTKIRA prende i soldi del biglietto
		}
		if (travel_mode != 0)
		{ // Ora si parte!!
			ask list<wedge> (percorso.edges)
			{
				popolazione <- popolazione + 1; //Ogni wedge aumenta di unità la popolazione se fa parte del percorso di un utente
			}
				loop edgesi over: percorso.edges
				{
					// L'utente fa un calcolo approssimativo di quanto un ognuno degli edge è rischioso.
					// Anque qui abbiamo una dimenticanza che diminuisce il rischio nel tempo.
					risk[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] <- dimenticanza2 * risk[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn];
					viaggi[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] <- dimenticanza2 * viaggi[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] + 1;
				}
			}

			fermata <- the_target; // Il target diventa la fermata di partenza
			location <- fermata.location;// + {rnd(1),rnd(1)}; // Aggiorniamo la location
			fermata.popolazione <- fermata.popolazione + 1; // contiamo gli utenti in ogni fermata alla fine del turno.
	}
	aspect base
	{
		if (travel_mode != 3)
		{ // Utenti saranno cerchi gialli, mentre cambiano colore se fanno i portoghesi.
			draw sphere(0.75) color: travel_mode != 1 ? # yellow : # tan;
		}

	}

}

species GTKIRA
{ // GTKIRA è l'azienda che controlla i movimenti dei controllori e tiene sotto controllo entrate e uscite (utility).
	list<list<wedge>> target_list <- list_with(4, n_controllori among wedge);
	float utility;
	// Calcola il rischio totale come somma del rischio medio su tutti i passeggeri.
	// nota: avg_risk è la somma dei rischi occumulati nei viaggi, quindi è ancora da dividere per il numero di viaggi.
	float total_risk <- 0.0 update: sum(passenger collect (each.avg_risk/max([each.num_viaggi,1])));
//	float risk_balance <- 0.0 update: risk_balance + sum(passenger collect each.avg_risk_balance);
	action update_target_list(int macro_fascia1)
	{ // All'inizio di ogni macrofascia di 5 ore sceglie i nuovi percorsi dei controllori.
		// Mettiamo in target_list i wedge messi in ordine decrescente (il segno meno) a seconda della quantità
		// di multe fatte su di esso.
		target_list[macro_fascia1] <- wedge sort_by (-each.avg_score[macro_fascia1]*each.avg_penality[macro_fascia1]);
	}

	reflex creation when: time = 0 and index =0
	{ // Creiamo gli agenti Smith all'inizio del modello.
		write "controllori creati";
		create Smith number: n_controllori;
	}
	
	reflex evaluation when: every(280)
	{	// Ogni 280 giri (1 settimana), GTKIRA paga i controllori, salva su csv i dati salienti,
		// ricalcola la penality media su ogni wedge, imposta nuovi target da controllare ai controllori
		// che rendono meno e penalizza i wedge che sono controllati (per non fari finire tutti i controllori
		// su un unico wedge).

		// Considerando un costo mensile di 2500€ a controllore, la GTT versa 625€ a controllore a settimana.
		utility <- utility - n_controllori * 625;
	 
		save
		[ // [0]tempo, [1]percentuale passeggeri viaggianti col biglietto, [2]Senza biglietto, [3]a piedi,
		  // [4]Utenti abbonati, [5]Soldi accumulati dall'azienda GTKIRA, [6]Rischio totale.
			time,
			length(passenger where (each.travel_mode = 2)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]), 
			length(passenger where (each.travel_mode = 1)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]), 
			length(passenger where (each.travel_mode = 0)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]),
			length(passenger where (each.flag_movimento = true)) * 100 / n_passenger,
			passenger count (each.flag_abbonamento = true), // Non normalizzato al numero di utenti.
			GTKIRA[0].utility,
			total_risk // Non normalizzato al numero di utenti.
		]
		 to:(salvataggio +"ticket_trend_"+index+"_"+ n_controllori + ".csv") type: "csv"; // Nome file
		ask wedge
		{ // Se il wedge ha avg_panelity minore di 0.9, aggiungo 0.1, se è maggiore di 0.9 viene messo ad 1.
			avg_penality <- avg_penality collect (each > 0.9 ? 1.0 : each + 0.1); // avg_penality varia sempre tra 0 e 1.
		}
		loop macro_fascia3 from: 0 to: 3
		{ //questo loop aggiunge penalità ai wedge controllati che non cambieranno e dà nuovi targets
			ask Smith where (each.score[macro_fascia3] > mean(Smith collect each.score[macro_fascia3]))
			// Bisogna che i target che non cambiano (quelli dei controllori migliori) conservino la penalità nello score!
			// Altrimenti si finirà per assegnare gli stessi target ai controllori in settimane diverse.
			// Questo ask chiede ai controllori migliori di aggiungere penalità ai wedge che loro controllavano
			// (e che continueranno a controllare).
			{ // Per tutti i wedge che saranno controllati dagli agenti Smith
				ask wedge where (each = targets[macro_fascia3])
				{
					ask wedge at_distance 1.0
					{ // Penalizza wedge che controlli e quelli vicini senza farlo scendere sotto lo 0.
						avg_penality[macro_fascia3] <- max([avg_penality[macro_fascia3] - 0.5, 0.0]);
					}

				}

			}
			ask Smith where (each.score[macro_fascia3] <= mean(Smith collect each.score[macro_fascia3]))
			{ // Muove agenti Smith che funzionano peggio
				ask wedge where (each = targets[macro_fascia3])
				{ // Aggiungo penalità ai wedge che saranno controllati dai controllori migliori.
					avg_penality[macro_fascia3] <- max([avg_penality[macro_fascia3] - 0.5, 0.0]); // mai sotto 0.
				}
				do acquire_new_targets(macro_fascia3, flip(Flip)); 
			}
			do update_target_list(macro_fascia3);
		}

		ask Smith
		{ // Riazzera il numero di agenti controllati.
			score <- list_with(4, 0);
		}

		ask wedge
		{ // Riazzera il numero di volte che il wedge è stato controllato.
			avg_score <- list_with(4, 0.0);
		}
	}

	action crea_agente_smith
	{ // GTKIRA is the god. It creates the Smith's.
		create Smith;
	}

}

species Smith
{
	init
	{
		loop macro_fascia2 from: 0 to: 3
		{
			do acquire_new_targets(macro_fascia2, true);
		}
	}

	list<int> score <- list_with(4, 0);
	list<wedge> percorso;
	list<wedge> targets <- list_with(4, wedge(0));
	action acquire_new_targets (int a, bool random) // a è la macrofascia oraria per cui va acquisito il nuovo target.
	{ // Questa action assegna un nuovo target ad un controllore.
		// Se scegliamo di non farlo random, viene assegnato il migliore target per la fascia data.
		if random = false {targets[a] <- GTKIRA[0].target_list[a][0];}

		else // Se c'è una scelta random...
		{
			if wedge where (each.avg_penality[a] = 1.0) != []
			{ // Questo è un controllo per assicurarsi che c'è almeno un wedge che non è stato
			  // controllato nelle scorse settimane.
			// Scegliamo uno di questi wedge e lo mettiamo in targets[a].
			targets[a] <- any(wedge where (each.avg_penality[a] = 1.0));
			}
			else {targets[a] <-any(wedge);} // Se non si trovano wedge non penalizzati, si sceglie un target a caso.
		}

		ask targets[a]
		{
			// Diminuisce di molto la penalità media del target selezionato con minimo a zero.
			avg_penality[a] <- max([avg_penality[a] - 0.9, 0.0]);
			ask wedge at_distance 1.0
			{ // Penalizziamo un po' anche i wedge topologicamente vicini al wedge che si controllerà.
				avg_penality[a] <- max([avg_penality[a] - 0.5, 0.0]); // Non li vogliamo tutti vicini.
			}
		}
		ask GTKIRA[0]{do update_target_list(a);}
	}

	reflex turn_shift when: (cycle mod 10 = 0) // Ogni 5 ore
	{ // Mettiamo il controllore sulla fermata selezionata da acquire_new_targets al tempo giusto.
		location <- targets[macro_fascia].location;
	}

	reflex movimento
	{ // Sceglie il percorso che il controllore deve fare
		// Consideriamo adesso gli score, che rappresentano quante multe sono state fatte in una tratta
		// nel tempo ==> i controllori andranno più spesso su quelli con score maggiore.
		float path_score <- targets[macro_fascia].score;
		float path_score_max <- path_score;
		list<wedge> available <- [];

		loop fermate over: targets[macro_fascia].arrivo.vicini_geo
		{ // Prendiamo i wedge che partono da tutti i vicini geografici, delle fermate geograficamente
		  // vicine al target.
			available <- available + fermate.out_edges;
		}

		// Selezioniamo i percorsi possibili, li ordiniamo per score e penality e prendiamo al più 3 wedge.
		loop wedge2 over: copy_between(available sort_by (-each.score * each.penality), 0, min([3, length(available)]))
		{ // Valuta tutti i percorsi possibili da fare con dei for nestati e infine sceglie quello migliore.
			path_score <- path_score + wedge2.score * wedge2.penality; // Valutiamo lo score di ogni percorso.
			list<wedge> available2 <- [];
			// Rifacciamo la stessa cosa per 5 volte (per ottenere un percorso lungo 7 wedge),
			// ogni volta aggiornando path_score. Infine selezioneremo quello col path_score maggiore.
			loop fermate over: wedge2.arrivo.vicini_geo
			{
				available2 <- available2 + fermate.out_edges;
			}

			loop wedge3 over: copy_between(available2 sort_by (-each.score * each.penality), 0, min([3, length(available2)]))
			{
				path_score <- path_score + wedge3.score * wedge3.penality;
				list<wedge> available3 <- [];
				loop fermate over: wedge3.arrivo.vicini_geo
				{
					available3 <- available3 + fermate.out_edges;
				}

				loop wedge4 over: copy_between(available3 sort_by (- each.score * each.penality), 0, min([3, length(available3)]))
				{
					path_score <- path_score + wedge4.score * wedge4.penality;
					list<wedge> available4 <- [];
					loop fermate over: wedge4.arrivo.vicini_geo
					{
						available4 <- available4 + fermate.out_edges;
					}

					loop wedge5 over: copy_between(available4 sort_by (- each.score * each.penality), 0, min([3, length(available4)]))
					{
						path_score <- path_score + wedge5.score * wedge5.penality;
						list<wedge> available5 <- [];
						loop fermate over: wedge5.arrivo.vicini_geo
						{
							available5 <- available5 + fermate.out_edges;
						}

						loop wedge6 over: copy_between(available5 sort_by (- each.score * each.penality), 0, min([3, length(available5)]))
						{
							path_score <- path_score + wedge6.score * wedge6.penality;
							list<wedge> available6 <- [];
							loop fermate over: wedge6.arrivo.vicini_geo
							{
								available6 <- available6 + fermate.out_edges;
							}
							if available6 != []
							{
								wedge wedge7 <- (available6 sort_by (-each.score*each.penality))[0];
								if path_score + wedge7.score*wedge7.penality > path_score_max
								{
									path_score_max <- path_score + wedge7.score*wedge7.penality;
									percorso <- [targets[macro_fascia]] + [wedge2] + [wedge3] + [wedge4] + [wedge5] + [wedge6] + [wedge7];
								}
							}
						path_score <- path_score - wedge6.score * wedge6.penality;
						}
					path_score <- path_score - wedge5.score * wedge5.penality;
					}
				path_score <- path_score - wedge4.score * wedge4.penality;
				}
			path_score <- path_score - wedge3.score * wedge3.penality;
			}
		path_score <- path_score - wedge2.score * wedge2.penality;
		}

		ask wedge where (each in self.percorso)
		{ // Penalizza i wedge controllati, quindi tolto il target, tenderà a non ripete più spesso gli stessi percorsi.
			self.penality <- 0.5 * self.penality; 
		}
	}

	reflex verification
	{ // Qui il controllore fa le multe e viene aggiornato il rischio di quelli che sono passati sui suoi wedge.
		
		list<list<int>> controllati <- nil;
		loop edge over: percorso // Per tutti i wedge su cui passa il controllore in un giro (mezz'ora)...
		{
			list<passenger> controllati2 <- (int(48*edge.popolazione/edge.peso) among passenger where (each.flag_movimento = true and edge in each.percorso.edges));
			ask controllati2
			{
				 self.risk[edge.saturation_index, edge.fascia_btwn] <- min([self.risk[edge.saturation_index, edge.fascia_btwn] + 1,self.viaggi[edge.saturation_index, edge.fascia_btwn]]);
			}
			// 48*popolazione/peso sono gli agenti che sono sul wedge nella stessa mezz'ora del controllore
			// e approssimiamo che il controllore controlla tutti quelli in un solo pullman.
				// Metto in morosi i passeggeri controllati che non hanno il biglietto.
			controllati <- controllati + controllati2 collect([int(each), int(edge)]);
				// Aumento il rischio di tutti quelli controllati.
		}
		list<list<int>> morosi <- controllati where (passenger[each[0]].titolo_viaggio =0);
		ask 4 among (morosi collect (passenger[each[0]]))
		{ // Multa massimo 4 controllori in mezz'ora
			// passenger salva il wedge in cui è stato controllato, per comunicarlo agli amici.
			wedge edge <- wedge[(morosi first_with (each[0]=passenger index_of self))[1]];
			ask (3 among passenger)
			{ // Avverte tre amici e loro e come se avessero incontrato mezzo controllore (0.5 incontro).
				// Da a tre amici il saturation index del wedge su cui è stato controllato
				self.risk[edge.saturation_index, edge.fascia_btwn] <- min([self.risk[edge.saturation_index, edge.fascia_btwn] + 0.5,self.viaggi[edge.saturation_index, edge.fascia_btwn]]);
				// e da la fascia betweenness.
				self.viaggi[edge.saturation_index, edge.fascia_btwn]<-1+ self.viaggi[edge.saturation_index, edge.fascia_btwn];
			}
			//self.risk[edge.saturation_index, edge.fascia_btwn] <- 1+self.risk[edge.saturation_index, edge.fascia_btwn];
			// Correggiamo lo stato di viaggio degli agenti multati
			self.titolo_viaggio <- 3;
			self.travel_mode <- 2;
		}
		self.score[macro_fascia] <- self.score[macro_fascia] + multa*min([4,length(morosi)]);
		GTKIRA[0].utility <- GTKIRA[0].utility + multa*min([4,length(morosi)]);
	}

	aspect base
	{
		draw sphere(0.85) color: # green;
	}

}

experiment graphExp type: gui
{	
	output
	{
		display graphView type: opengl
		{
//			species bus_stop aspect: base;
            species wedge aspect: base;
            species passenger aspect:base;
			species Smith aspect: base;
			//                  species building aspect:base;
		}
	    display chart refresh_every:10																				//NEW
	    {
			chart "Charles_the_chart" type: series background: rgb("lightGray") style: exploded 
			{
				data "Risk (magnified 10x)" value: 10*GTKIRA[0].total_risk/n_passenger color: rgb("red");
				data "Abbonati" value:length(passenger where (each.titolo_viaggio > 3))/ n_passenger  color: rgb("green");
			}
		}
	}

}
experiment Flipbatch type: batch repeat: 1 until: time =  72000 + time_offset keep_seed: true 
{
		
		parameter 'flip' var: Flip among: [0.5, 1.0];
		parameter 'start_time' var: time_offset <- 146001.0;
		parameter 'input_csv' var: input_csv<- true;
		parameter 'percorso' var:salvataggio <- "./exports/19_11/";
}

experiment Stability type: batch repeat:1 until: time = 20000 keep_seed:false
{
		parameter 'input_csv' var: input_csv<- false;
		parameter 'percorso' var:salvataggio <- "./exports/1_12/";
		
}

experiment Breakeven type: batch repeat: 10 until: time = 20000 + time_offset keep_seed: false
{
	parameter 'flip' var: Flip <- 0.5;
	parameter 'start_time' var: time_offset <- 146001.0;
	parameter 'input_csv' var: input_csv<- true;
	parameter 'percorso' var:salvataggio <- "./exports/26_11/";
	parameter 'n_controllori' var:n_controllori <- 1;	
	
}