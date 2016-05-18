/**
 *  Model_5.1
 *  Author: Alessandro
 *  Description: 
 */

model Model51

/* Insert your model definition here */
global
{
	file shape_file_cinema <- file("../includes/ridottissimo/cinema_geo.shp");
	file shape_file_sport_center <- file("../includes/ridottissimo/impianti_sportivi_geo.shp");
	file shape_file_museum <- file("../includes/ridottissimo/musei_geo.shp");
	file shape_file_hospital <- file("../includes/ridottissimo/ospedali_geo.shp");
	file shape_file_school <- file("../includes/ridottissimo/scuole2.shp");
	file shape_file_ASL <- file("../includes/ridottissimo/sedi_asl_geo2.shp");
	file shape_file_university <- file("../includes/ridottissimo/universita_geo.shp");
	file shape_file_theater <- file("../includes/ridottissimo/teatri_geo.shp");
	file shape_file_stops <- file("../includes/ridottissimo/transport_points_4.shp");

	file csv_edges_list <- csv_file("../includes/ultimate_edges_list_ext_noint.csv", ",");
	matrix edge_list_matrix <- matrix(csv_edges_list); //utile per il ciclo di assegnazione

	file csv_orario <- csv_file("../includes/orari.csv", ",");
	matrix<int> orario <- matrix<int> (csv_orario);

	file csv_affinity <- csv_file("../includes/affinity.csv", ",");
	matrix<float> affinity <- matrix<float> (csv_affinity);

	file csv_mobility <- csv_file("../includes/mobility3.csv", ",");
	matrix<float> mobility <- matrix<float> (csv_mobility);

	file csv_raggiungibile <- csv_file("../includes/ridottissimo/raggiungibili.csv", ",");
	matrix<int> raggiungibili <- matrix<int> (csv_raggiungibile);

	file csv_pesi <- csv_file("../includes/ridottissimo/pesi.csv", ";");
	matrix<int> Pesi <- matrix<int> (csv_pesi);

	file csv_betweenness <- csv_file("../includes/ridottissimo/betweenness.csv", ",");
	matrix<float> bwn <- matrix<float> (csv_betweenness);

	graph grafo;
	int fascia_oraria update: int(time / 4) mod 10;
	int macro_fascia update: int(time / 10) mod 4;
	int day update: int(time / 40) + 1;
	int multa;
//	bool salva <- true update:(time < 2000?((time mod 150 =0)? true:false):((time mod 800 =0)? true:false));
	int n_controllori;
	int n_passenger<-15000;
	float ticket;
	float dimenticanza <- 0.9862327;
	float dimenticanza2 <- 0.9986;
	float abbonamento;
	float betw_max;
	float scala;
	int index <- 0;
	float reset_time <- 1460000.0;
	list<bus_stop> active_stops;
	string salvataggio <- "./exports/11_11/";
	reflex doomsday when: time = reset_time
	{
		index <- index +1;
		ask wedge
		{
			penality <- 1.0;
			avg_penality <- list_with(4, 1.0);
			score<-0.0;
			avg_score <- list_with(4, 0.0);
		}
		ask passenger
		{
			flag_abbonamento <- false;
			avg_risk <- 0.0;
			num_viaggi <- 0.0;
//			avg_risk_balance <- 0.0;
			viaggi <- 0.0 as_matrix ({ 5, 3 });
			risk <- 0.0 as_matrix ({ 5, 3 });
			titolo_viaggio<-0;
		}
		ask GTKIRA
		{
			target_list <- list_with(4, n_controllori among wedge);
			utility <- 0.0;
			total_risk <- 0.0;
		}
		ask Smith
		{
			score <- list_with(4, 0);
			loop macro_fascia2 from: 0 to: 3
			{
				do acquire_new_targets(macro_fascia2, true);
			}
		}
		time <- 0.0;
		write "reset_globale";
	}
	reflex shouldHalt when: cycle = 10*reset_time
	{
		write "halting";
    	do halt;
	}
	init
	{
		//write fit_abbonamento;
		index<-0;
		n_controllori <- 4;
		multa <- 50;
		fascia_oraria <- 0;
		ticket <- 1.5;
		abbonamento <- 40.0;
		scala <- 29782 / n_passenger; //RIDOTTISSIMO 56239 RIDOTTO 320000
		create building from: shape_file_cinema with: [type:: 0, id::int(read("ID_CINEMA")) - 1, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_sport_center with: [type:: 1, id::int(read("ID_R_IMP_T")) + 47, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_museum with: [type:: 2, id::int(read("ID_TIPOPTO")) + 749, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_hospital with: [type:: 3, id::int(read("ID_OSPEDAL")) + 834, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_school with: [type:: 4, id::int(read("ID_PT_INGR")) + 796, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_ASL with: [type:: 5, id::int(read("ID_ASL")) + 1493, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_university with: [type:: 6, id::int(read("ID_UNIVERS")) + 1504, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create building from: shape_file_theater with: [type:: 7, id::int(read("ID_R_PUNTO")) + 1537, location::{ float(read("XCOORD")) / 100, float(read("YCOORD")) / 100, 0 }];
		create bus_stop from: shape_file_stops with: [code::int(read("ref")), location::{ float(read("XCOORD")) / 100 - 8460, float(read("YCOORD")) / 100 - 56300, 0
		}, fattore_scelta::list_with(6, 0.0)];
		write "bus_stop creati";
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

		write "passenger creati";
		loop j from: 0 to: length(rows_list(edge_list_matrix)) - 1
		{
//			int arrivo2 <- int(edge_list_matrix[1, j]);
//			int partenza2 <- int(edge_list_matrix[0, j]);
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
		grafo <- directed(as_edge_graph(wedge));
		ask wedge
		{
			do set_betweenness;
		}

		write "inizializzazione variabili bus_stop";
		betw_max <- max(wedge collect each.btw);

		// set_appeal_matrix lo faccio qui e non nell'init della specie perchè alla fine dell'init cancello 
		ask bus_stop
		{
			do set_appeal_matrix;
		}

		write "inizio raggiungibili";
		ask bus_stop
		{
			do set_raggiungibili;
			do trova_vicini_geografici;
			do trova_out_edges;
			list_raggiungibili <- list_raggiungibili - [0];
			stop_raggiungibili <- bus_stop where (each.code in list_raggiungibili); //assegnazione reale
			list_raggiungibili <- nil;
		} //se scommenti questa ricorda di andare a rimuovere l'if nel reflex movimento, ogni fermata nella lista allora sarà raggiungibile
		write "removing duplicates";
		write "fine raggiugibili";
		Pesi <- nil;
		raggiungibili <- nil;
		edge_list_matrix <- nil;
		create GTKIRA;
		active_stops <- bus_stop where(each.stop_raggiungibili != [each]);
	}
}

species building
{
	int id;
	int type;
	aspect base
	{
		draw square(2) color: # red;
	}

}

species bus_stop
{

	int code; //codice fermata
	int popolazione_old update: popolazione;
	int popolazione;
	list<wedge> out_edges;
	list<bus_stop> vicini_geo;
	list<int> list_raggiungibili;
	list<bus_stop> stop_raggiungibili;
	list<float> fattore_scelta; //exp (-popolazione/proiezione) per ogni tipo di utente (lista 6 float)
	matrix<int> appeal_matrix <- 0 as_matrix ({ 10, 6 }); //Matrice di contenimento dei pesi definiti da fascia e utente
	action set_raggiungibili
	{
		self.list_raggiungibili <- list<int> (rows_list(raggiungibili) first_with (each[0] = self.code));
	}

	action trova_out_edges
	{
		out_edges <- (wedge where (each.partenza = self));
	}

	action trova_vicini_geografici
	{
		vicini_geo <- bus_stop where (each distance_to self < 2.5);
	}

	action set_appeal_matrix
	{
		int riga <- int(columns_list(Pesi)[0] first_with (each = self.code));
		loop colonna from: 1 to: 10
		{
			loop riga_int from: 1 to: 6
			{
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
		draw square(1.5) color: # pink;
	}

}

species wedge
{
	init
	{
		fascia_btwn <- min([2,int(self.btw * 3 / betw_max)]);
	}

	int popolazione_old update: popolazione; //eseguito prima del riflesso: il valore di popolazione viene salvato qui//**new
	int popolazione; //agenti che viaggiano sull'edge. Posto a 0 ogni inizio turno dal reflex (così viene posto a 0 dopo che popolazione_old copia il valore)
	bus_stop partenza;
	bus_stop arrivo;
	float penality <- 1.0 update: 1.0;
	list<float> avg_penality <- list_with(4, 1.0);
	float btw;
	int fascia_btwn max:4;
	float score;
	list<float> avg_score <- list_with(4, 0.0);
	int peso;
	int saturation_index max:4; // update: min([3,int(48*popolazione/25*peso)]);											
	aspect base
	{
		draw shape color:(penality=1.0? #black:#red);
	}

	reflex update_variables
	{
		saturation_index <- int(floor(48*4*(scala/100)) * (self.popolazione_old / self.peso)); //vale per ridottissimo
		score <- (btw / betw_max) ^ (1.0 / 3.0) * popolazione_old / (exp(2.131 * saturation_index) + 1);
		popolazione <- 0;
		avg_score[macro_fascia] <- avg_score[macro_fascia] + score / 70;
		//lo score medio viene valutato ogni 280 step, quindi aggiungo lo score già diviso per 280
	}

	action set_betweenness
	{ //se la trovalasua
		self.btw <- float((rows_list(bwn) where ((each[0]) = float(wedge index_of self)))[0][1]);
	}

}

species passenger skills: [moving]
{
	bus_stop the_target;
	bus_stop fermata;
	bool flag_abbonamento <- false;
	bool flag_movimento <- false update: false;
	float avg_risk <- 0.0;
//	float avg_risk_balance <- 0.0 update:0.0;//misura di quanto è cambiato il rischio medio nell'ultimo turno				**NEW
	float avg_mobility;
	float num_viaggi <- 0.0;
	matrix<float> viaggi <- 0.0 as_matrix ({ 5, 3 });	
	matrix<float> risk;
	int type;
	int titolo_viaggio min: 0 update: titolo_viaggio - 1;
	int travel_mode update: 3; // 0-> viaggio alternativo; 1 -> viaggio senza ticket; 2-> viaggio con ticket; 3 -> il flip (mobility) ha dato croce)
	path percorso <- path(0) update: path(0); //ogni inizio turno il percorso va azzerato!

	reflex decisione_abbonamento when: (every(40) and titolo_viaggio < 40) //**new
	{
		if (1200*self.avg_mobility*min([(self.avg_risk/max([1,self.num_viaggi]))*multa,ticket]) > abbonamento) //AGGIUNGERE GAUSSIANA
		{
			titolo_viaggio <- 1200;
			GTKIRA[0].utility <- GTKIRA[0].utility + abbonamento; //utility i soldi
			flag_abbonamento <- true;
		} 
		else
		{
			flag_abbonamento <- false;
		}

	}
	//40% in più della tua mobility che tu ti muova
	reflex movimento when: flip((1 + 0.4 * signum(titolo_viaggio)) * mobility[fascia_oraria, type])
	{
		flag_movimento <- true;
		if fermata = bus_stop[147] or bus_stop[431] or bus_stop[430] or bus_stop[285] or bus_stop[143] or bus_stop[406]
		{
			fermata <- any(bus_stop);
			location <- fermata.location;
		}

		fermata <- (fermata.vicini_geo)[rnd_choice(fermata.vicini_geo collect each.fattore_scelta[type])]; //scelta fermata tra i vicini
		if (fermata in active_stops)
		{
			the_target <- (fermata.stop_raggiungibili-fermata)[rnd_choice((fermata.stop_raggiungibili - fermata) collect each.fattore_scelta[type])]; //scelta meta viaggio
		}
		else
		{
//			write "inactive";
			fermata <- any(active_stops);
			the_target <- (fermata.stop_raggiungibili-fermata)[rnd_choice((fermata.stop_raggiungibili - fermata) collect each.fattore_scelta[type])];
		}
		percorso <- path_between(grafo, fermata.location, the_target.location);
		  //1 - prob che non ti controlli nessuno
		float risk_max <- 1 - mul(list<wedge> (percorso.edges) collect (1 - (risk[each.saturation_index, each.fascia_btwn] / (max([1,viaggi[each.saturation_index, each.fascia_btwn]])))));
/*NEW */float avg_risk_old <- avg_risk/max([1,num_viaggi]); //occhio: è già diviso per numero viaggi				   **NEW
		avg_risk <- dimenticanza * avg_risk + risk_max;
		num_viaggi <- num_viaggi * dimenticanza + 1;
/*NEW *///avg_risk_balance <- avg_risk/num_viaggi - avg_risk_old; //positivo: rischio medio aumentato, negativo: rischio diminuito
		list<float> utility <- list_with(3, 0.0);
		utility[0] <- exp(-length(percorso.edges)); //NV
		utility[1] <- 1 - exp(-length(percorso.edges) / (risk_max * multa + 0.001)); //VST
		utility[2] <- 1 - exp(-length(percorso.edges) / ticket) + self.titolo_viaggio; //VCT <- aggiungere bonus abbonamento?
		travel_mode <- utility index_of (max(utility)); //l'utility massima viene assegnata a travel_mode
		
		if (travel_mode = 2 and titolo_viaggio = 0)
		{
			self.titolo_viaggio <- 3;
			GTKIRA[0].utility <- GTKIRA[0].utility + ticket;
		}
		if (travel_mode != 0)
		{
			ask list<wedge> (percorso.edges)
			{
				popolazione <- popolazione + 1;
			}
				loop edgesi over: percorso.edges
				{
					risk[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] <- dimenticanza2 * risk[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn];
					viaggi[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] <- dimenticanza2 * viaggi[wedge(edgesi).saturation_index, wedge(edgesi).fascia_btwn] + 1;
				}
			}

			fermata <- the_target;
			location <- fermata.location;
			fermata.popolazione <- fermata.popolazione + 1;
	}
	aspect base
	{
		if (travel_mode != 3)
		{
			draw sphere(0.75) color: travel_mode != 1 ? # yellow : # tan;
		}

	}

}

species GTKIRA
{
	list<list<wedge>> target_list <- list_with(4, n_controllori among wedge);
	float utility;
	float total_risk <- 0.0 update: sum(passenger collect (each.avg_risk/max([each.num_viaggi,1]))); 					   //NEW!
//	float risk_balance <- 0.0 update: risk_balance + sum(passenger collect each.avg_risk_balance);
	action update_target_list(int macro_fascia1)
	{
			target_list[macro_fascia1] <- copy_between(wedge sort_by (-each.avg_score[macro_fascia1]*each.avg_penality[macro_fascia1]), 0, 10 * n_controllori);
	}

	reflex creation when: time = 0 and index =0
	{
		write "controllori creati";
		create Smith number: n_controllori;
	}
	
	reflex evaluation when: every(280)
	{
		utility <- utility - n_controllori * 625;
	 //considerando un costo mensile di 2500€ a controllore, la GTT versa 625€ a controllore a settimana
		save
		[
			time,
			length(passenger where (each.travel_mode = 2)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]), 
			length(passenger where (each.travel_mode = 1)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]), 
			length(passenger where (each.travel_mode = 0)) * 100 / max([1,(length(passenger where(each.flag_movimento = true)))]),
			length(passenger where (each.flag_movimento = true)) * 100 / n_passenger,
			passenger count (each.flag_abbonamento = true),
			total_risk
		]
		 to:(salvataggio +"ticket_trend_b_"+  n_passenger +"_"+index + ".csv") type: "csv";
		ask wedge
		{
			penality <- 1.0;
			avg_penality <- avg_penality collect (each > 0.9 ? 1.0 : each + 0.1); //list_with(4, 1.0);
		}
		loop macro_fascia3 from: 0 to: 3
		//questo loop aggiunge penalità ai wedge controllati che non cambieranno e dà nuovi targets
		{
			ask Smith where (each.score[macro_fascia3] > mean(Smith collect each.score[macro_fascia3]))
			//bisogna che i target che non cambiano (quelli dei controllori migliori) conservino la penalità nello score! altrimenti si finirà per assegnare gli
			//stessi target ai controllori in settimane diverse. Questo ask chiede ai controllori migliori di aggiungere penalità ai wedge che loro controllavano
			//(e che continueranno a controllare)
			{
				ask wedge where (each = targets[macro_fascia3])
				{
					ask wedge at_distance 1.0
					{
						avg_penality[macro_fascia3] <- max([avg_penality[macro_fascia3] - 0.5, 0.0]);
					}

				}

			}
			//Muove smith scarsi
			ask Smith where (each.score[macro_fascia3] <= mean(Smith collect each.score[macro_fascia3]))
			{
				ask wedge where (each = targets[macro_fascia3]) //Aggiungo penalità ai wedge che hanno reso poco
				{
					avg_penality[macro_fascia3] <- max([avg_penality[macro_fascia3] - 0.5, 0.0]);
				}
				if flip(0.5)
				{
					do acquire_new_targets(macro_fascia3, true);
				} 
				else
				{
					do acquire_new_targets(macro_fascia3, false);
				}

			}
			do update_target_list(macro_fascia3);
		}

		ask Smith
		{
			score <- list_with(4, 0);
		}

		ask wedge
		{
			avg_score <- list_with(4, 0.0);
		}
	}

	action crea_agente_smith
	{
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
	action acquire_new_targets (int a, bool random) //a è la macrofascia oraria per cui va acquisito il nuovo target 
	{
		if random = false {targets[a] <- GTKIRA[0].target_list[a][0];}
		else {targets[a] <- any(wedge where (each.avg_penality[a] = 1.0)); }
		ask targets[a]
		{
			avg_penality[a] <- max([avg_penality[a] - 0.9, 0.0]);
			ask wedge at_distance 1.0
			{
				avg_penality[a] <- max([avg_penality[a] - 0.5, 0.0]);
			}
		}
		ask GTKIRA[0]{do update_target_list(a);}
	}

	reflex turn_shift when: (cycle mod 10 = 0)
	{
		location <- targets[macro_fascia].location;
	}

	reflex movimento 

	{
		float path_score <- targets[macro_fascia].score;
		float path_score_max <- path_score;
		list<wedge> available <- [];
		loop fermate over: targets[macro_fascia].arrivo.vicini_geo
		{
			available <- available + fermate.out_edges;
		}

		loop wedge2 over: copy_between(available sort_by (-each.score * each.penality), 0, min([3, length(available)]))
		{
			path_score <- path_score + wedge2.score * wedge2.penality;
			list<wedge> available2 <- [];
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

							loop wedge7 over: copy_between(available6 sort_by (- each.score * each.penality), 0, min([3, length(available6)]))
							{
								path_score <- path_score + wedge7.score * wedge7.penality;
								if (path_score > path_score_max)
								{
									percorso <- [targets[macro_fascia]] + [wedge2] + [wedge3] + [wedge4] + [wedge5] + [wedge6] + [wedge7];
									path_score_max <- path_score;
								}

							}

						}

					}

				}

			}

		}

		ask wedge where (each in self.percorso) //penalizzazione wedge già percorsi

		{
			self.penality <- 0.5 * self.penality;
		}

		ask GTKIRA[0] //riordino la lista di target dopo le penalizzazioni

		{
			self.target_list[macro_fascia] <- self.target_list[macro_fascia] sort_by (-each.avg_score[macro_fascia]);
		}

	}

	reflex verification
	{
		list<list<int>> morosi <- nil;
		loop edge over: percorso
		{//popolazione/peso sono gli agenti che erano su quell'edge. Peso va diviso per 2
			
			ask (int(48*edge.popolazione/edge.peso)) among passenger where (each.flag_movimento = true and edge in each.percorso.edges)
			{
				morosi <- morosi + (passenger where (each.flag_movimento = true and edge in each.percorso.edges and each.titolo_viaggio=0)) collect [int(each), int(edge)];
				self.risk[edge.saturation_index, edge.fascia_btwn] <- min([self.risk[edge.saturation_index, edge.fascia_btwn] + 1,self.viaggi[edge.saturation_index, edge.fascia_btwn]]);
			}
		}
		self.score[macro_fascia] <- self.score[macro_fascia] + multa*min([4,length(morosi)]);
		GTKIRA[0].utility <- GTKIRA[0].utility + multa*min([4,length(morosi)]);
		ask 4 among morosi collect (passenger[each[0]])
		{
			wedge edge <- wedge[(morosi first_with (each[0]=passenger index_of self))[1]];
			ask (3 among passenger)
			{
				self.risk[edge.saturation_index, edge.fascia_btwn] <- min([self.risk[edge.saturation_index, edge.fascia_btwn] + 0.5,self.viaggi[edge.saturation_index, edge.fascia_btwn]]);
				self.viaggi[edge.saturation_index, edge.fascia_btwn]<-1+ self.viaggi[edge.saturation_index, edge.fascia_btwn];
			}
			//self.risk[edge.saturation_index, edge.fascia_btwn] <- 1+self.risk[edge.saturation_index, edge.fascia_btwn];
			self.titolo_viaggio <- 3;
			self.travel_mode <- 2;
		}
	}

	aspect base
	{
		draw sphere(0.85) color: # green;
	}

}

experiment graphExp type: gui
{
	float seed <- 10.0 parameter:true;
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
	    display chart refresh_every: 1 																					//NEW
	    {
			chart "Charles_the_chart" type: series background: rgb("lightGray") style: exploded 
			{
				data "Risk (magnified 10x)" value: 10*GTKIRA[0].total_risk/n_passenger color: rgb("red");
				data "Abbonati" value:length(passenger where (each.titolo_viaggio > 3))/ n_passenger  color: rgb("green");
			}
		}
	}

}
experiment stabilita type: batch repeat: 4 until: n_controllori >10 keep_seed: false {}

