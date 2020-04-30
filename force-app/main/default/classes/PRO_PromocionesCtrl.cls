public with sharing class PRO_PromocionesCtrl {

	String periodicidadList {get;set;}

	public PRO_PromocionesCtrl() {
		
	}

	public String getPeriodicidadList(){
	   Schema.DescribeFieldResult fieldResult = Promocion__c.Periodicidad__c.getDescribe();
	   List<Object> listOpciones = new List<Object>();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple){
	   		Map<String, String> option = new Map<String, String>();
			option.put('Name', f.getLabel());
			option.put('Value', f.getValue());
			listOpciones.add(option);
	   }    

	   String opciones = JSON.serialize(listOpciones); 
	   return opciones;
	}

	@RemoteAction
	public static Object getOfertaConceptoPagos(){
		
		List<OfertaConceptoPagos__c> listaOCP = new List<OfertaConceptoPagos__c>();
		
		listaOCP = [Select id, name, monto__c from OfertaConceptoPagos__c];
		
		return listaOCP;
	}

	@RemoteAction
	public static Object getConceptsOfCatalog(){

		List<Catalogo__c> lstConceptos = new List<Catalogo__c>();
		Map<String, Object> mapResponse = new Map<String, Object>();

		try{						

			lstConceptos = [SELECT  Id,
							Name,
							RecordType.Name,
							ConceptoOE__c,
							HeredarCantidadPagosColegiaturaOE__c,
							HeredarCantidadPagosInscripcionOE__c
							FROM Catalogo__c 
							Where RecordType.Name = 'Concepto de pago'
							AND ConceptoOE__c = false];

			if( lstConceptos != null && lstConceptos.size() > 0 ){

				mapResponse.put('state','Success');
				mapResponse.put('data',lstConceptos);

				return mapResponse;

			}else{

				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón conceptos del tipo de registro Concepto de pago.');
				return mapResponse;

			}

		}catch(DmlException ex){

			String error = 'Exception Promociones-getConceptsOfCatalog linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();
			
			mapResponse.put('state','Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;
		}		

	}

	@RemoteAction
	public static Object getLetrasBeca(){
		
		Map<String, Object> mapResponse = new Map<String, Object>();
		List<Negocio__c> configPersonalizada = [SELECT Id, LetraBeca__c FROM Negocio__c WHERE SetupOwner.Name = 'IEU'];	
		List<String> lstLetras = new List<String>();

		if( configPersonalizada != null && configPersonalizada.size() > 0 ){

			lstLetras = configPersonalizada[0].LetraBeca__c.split(';');
			mapResponse.put('state','Success');
			mapResponse.put('data',lstLetras);	

		}else{

			mapResponse.put('state','Null');
			mapResponse.put('response','No se encontrarón letras en la configuración personalizada Negocio__c con SetupOwner.Name == "IEU"');	

		}
					
		return mapResponse;
	}

	@RemoteAction
	public static Object getPeriodos(){

		List<Periodo__c> lstPeriodos = new List<Periodo__c>();
		Map<String, Object> mapResponse = new Map<String, Object>();

		try{	
			
			List<Negocio__c> configPersonalizada = [SELECT Id, MostrarPeriodoInactivo__c FROM Negocio__c WHERE SetupOwner.Name = 'IEU'];	

			String periodoActivo = '';

			if( configPersonalizada != null && configPersonalizada.size() > 0){

				if( configPersonalizada[0].MostrarPeriodoInactivo__c != null ){

					periodoActivo = ( configPersonalizada[0].MostrarPeriodoInactivo__c == true ) ? 'Inactivo' : 'Activo';

					lstPeriodos = [SELECT Id, Name, FechaInicioReal__c, FechaInicio__c, FechaFin__c FROM Periodo__c WHERE Activo__c =: periodoActivo ORDER BY FechaInicioReal__c DESC];

					if( lstPeriodos != null && lstPeriodos.size() > 0){

						mapResponse.put('state','Success');
						mapResponse.put('data',lstPeriodos);				
						return mapResponse;

					}else{

						mapResponse.put('state','Null');
						mapResponse.put('response','No se encontrarón registros de periodos.');
						return mapResponse;

					}

				}else{

					mapResponse.put('state','Null');
					mapResponse.put('response','No se encontro periodos, no existe la bandera MostrarPeriodoInactivo__c en la configuración personalizada Negocio__c con SetupOwner.Name == "IEU"');	
					return mapResponse;

				}

			}else{

				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontro registro en la configuración personalizada Negocio__c con SetupOwner.Name == "IEU"');	
				return mapResponse;

			}

		}catch(DmlException ex){

			String error = 'Exception Promociones-getPeriodos linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();
			
			mapResponse.put('state','Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;
		}		

	}

	@RemoteAction
	public static Map<String, Object> getOfertasEducativasPromotion(String periodo,String modalidad,String plantel,String nivel,String programa,String concepto,String noPagos){

		Map<String,Object> mapResponse = new Map<String,Object>();

		try{
			String query = 'SELECT Id, Name, Estatus__c,OfertaEducativa__r.NumeroColegiaturas__c, OfertaEducativa__r.NumeroInscripciones__c, OfertaEducativa__r.Periodo__r.Name, OfertaEducativa__r.Modalidad__r.Name, OfertaEducativa__r.Plantel__r.Name, OfertaEducativa__r.Nivel__r.Name, OfertaEducativa__r.Programa__r.Name FROM Grupo__c';
			
			String whereClause = '';
			
			/* if( concepto != '' && noPagos != '' ){

				Decimal pagos = decimal.valueOf(noPagos);

				if( concepto == 'Colegiatura' ){
					whereClause +=  ' OfertaEducativa__r.NumeroColegiaturas__c = '+pagos ;
				}else if( concepto == 'Inscripción' ){
					whereClause +=  ' OfertaEducativa__r.NumeroInscripciones__c = '+pagos ;
				}
				whereClause += String.isBlank(periodo) 	 ? '' : ' AND OfertaEducativa__r.Periodo__c = \''+periodo+'\' ';

			}else{ */

				whereClause += String.isBlank(periodo) 	 ? '' : 'OfertaEducativa__r.Periodo__c = \''+periodo+'\' ';
				whereClause += String.isBlank(modalidad) 	 ? '' : ' AND OfertaEducativa__r.Modalidad__c = \''	+modalidad+'\' ';
				whereClause += String.isBlank(plantel)  ? '' : ' AND OfertaEducativa__r.Plantel__c = \''+plantel+'\' ';
				whereClause += String.isBlank(nivel) ? '' : ' AND OfertaEducativa__r.Nivel__c = \''	+nivel+'\' ';
				whereClause += String.isBlank(programa) ? '' : ' AND OfertaEducativa__r.Programa__c = \''+programa+'\' ';

			// }
						
			query += ' WHERE '+ whereClause;

			System.debug('getOfertasEducativasPromotion query:'+query);
			
			List<Grupo__c> lstPromociones = (List<Grupo__c>)Database.query(query);

			if( lstPromociones != null && lstPromociones.size() > 0 ){
				
				mapResponse.put('state','Success');
				mapResponse.put('data',lstPromociones);
				
				return mapResponse;	

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón Ofertas Educativas filtradas.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getOfertasEducativasPromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Object getDataPerPeriod(String periodo){
		
		List<Grupo__c> lstGroup = new List<Grupo__c>();
		Map<String,Object> mapResponse = new Map<String,Object>();
		
		lstGroup = [SELECT 
					Id,Name,
					OfertaEducativa__c,
					OfertaEducativa__r.NumeroColegiaturas__c,
					OfertaEducativa__r.NumeroInscripciones__c,
					OfertaEducativa__r.Plantel__r.Name,
					OfertaEducativa__r.Plantel__r.Id,
					OfertaEducativa__r.Nivel__r.Name,
					OfertaEducativa__r.Nivel__r.Id,
					OfertaEducativa__r.Modalidad__r.Name,
					OfertaEducativa__r.Modalidad__r.Id,
					OfertaEducativa__r.Programa__r.Name,
					OfertaEducativa__r.Programa__r.Id,
					OfertaEducativa__r.Periodo__r.Name,
					OfertaEducativa__r.Periodo__r.Id
					FROM Grupo__c 
					WHERE OfertaEducativa__r.Periodo__c =: periodo];

		try{

			if( lstGroup != null && lstGroup.size() > 0){

				mapResponse.put('state','Success');
				mapResponse.put('data',lstGroup);
				
				return mapResponse;	

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón registros con ese periodo.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getDataPerPeriod linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();
			
			mapResponse.put('state','Exception');
			 mapResponse.put('response', (Object)error);

			return mapResponse;
		}
		
	}

	@RemoteAction
	public static Object getDataConceptoPago(String ofeEdu){
		System.debug('ofeEdu' + ofeEdu);
		List<OfertaConceptoPagos__c> listOfeConPag = new List<OfertaConceptoPagos__c>();
		Map<String,Object> mapResponse = new Map<String,Object>();
		
		listOfeConPag = [SELECT Id, Name, Monto__c, ConceptoPago__r.Name, OfertaEducativa__c 
					FROM OfertaConceptoPagos__c 
					WHERE OfertaEducativa__c =: ofeEdu
					AND (ConceptoPago__r.HeredarCantidadPagosColegiaturaOE__c = true OR ConceptoPago__r.HeredarCantidadPagosInscripcionOE__c = true)];
		System.debug('listOfeConPag' + listOfeConPag);

		try{

			if( listOfeConPag != null && listOfeConPag.size() > 0){

				mapResponse.put('state','Success');
				mapResponse.put('data',listOfeConPag);
				
				return mapResponse;	

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón registros de concepto para la oferta.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getDataPerPeriod linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();
			
			mapResponse.put('state','Exception');
			 mapResponse.put('response', (Object)error);

			return mapResponse;
		}
		
	}

	@RemoteAction
	public static Map<String, Object> getPromociones(String periodo,String modalidad,List<String> plantel,List<String> nivel,List<String> programa,List<String> letra){

		System.debug('periodo:'+periodo);
		System.debug('modalidad:'+modalidad);
		System.debug('plantel:'+plantel);
		System.debug('nivel:'+nivel);
		System.debug('programa:'+programa);
		System.debug('letra:'+letra);

		Map<String,Object> mapResponse = new Map<String,Object>();

		try{

			String query = 'SELECT Id, Name,CantidadPago__c, Promocion__c,ImporteConcepto__c, ' + 
							'Promocion__r.Name, Promocion__r.MostrarFichaPago__c,Promocion__r.AcumularDescuentos__c, Promocion__r.AplicaOtrasPromociones__c, Promocion__r.Estatus__c,Promocion__r.FechaFinVigencia__c, '+ 
							'Promocion__r.FechaInicioVigencia__c, Promocion__r.RequiereAutorizacion__c, Promocion__r.RequiereAprobacionCreacion__c, Promocion__r.SeleccionarCantidadPagosOE__c, Promocion__r.PorcentajeDescuento__c, '+ 
							'Promocion__r.ImporteConcepto__c, Promocion__r.DisponibleLandingPage__c,Promocion__r.DisponibleEjecutivo__c, Promocion__r.ConceptoFijo__c, Promocion__r.PagoUnico__c, Promocion__r.NombreConcepto__c, ' + 
							'Promocion__r.Periodicidad__c, Promocion__r.RequierePromocionCero__c, Promocion__r.NombreConcepto__r.Name, Promocion__r.DescripcionComercial__c, Promocion__r.PagoDiferido__c, Promocion__r.CantidadPago__c, Promocion__r.MostrarImporteLeadOportunidad__c, '+ 
							'Periodo__c, Periodo__r.Name, Periodo__r.FechaFin__c, Modalidad__c, Modalidad__r.Name, Plantel__c, Plantel__r.Name, Nivel__c, Nivel__r.Name, Programa__c, Programa__r.Name, Letra__c ' + 
							'FROM ConfiguradorPromocion__c ';
			
			String whereClause = '';

			whereClause += String.isBlank(periodo) 	 ? '' : 'Periodo__r.Name = \''			+	periodo+'\' ';

			whereClause += String.isBlank(modalidad) 	 ? '' : ' AND Modalidad__r.Name = \''	+	modalidad+'\' ';

			if( letra != null && letra.size() > 0 ){
								
				for(Integer le = 0 ; letra.size() > le ; le++){

					if(le == 0){

						if(letra.size() == 1){
							
							whereClause += ' AND (Letra__c includes (\''+letra[le]+'\') ) ';

						}else if(letra.size() > 1){

							whereClause += ' AND (Letra__c includes (\''+letra[le]+'\')';

						}
						
					}else{

						whereClause += ' OR Letra__c includes (\''+letra[le]+'\') ';

					}
				}

				if(letra.size() > 1){
					whereClause += ') ';
				}				
				
			}
			
			if( plantel != null && plantel.size() > 0 ){

				for(Integer p = 0 ; plantel.size() > p ; p++){

					if(p == 0){

						if(plantel.size() == 1){
							
							whereClause += ' AND (Plantel__r.Name = \''+plantel[p]+'\') ';

						}else if(plantel.size() > 1){

							whereClause += ' AND (Plantel__r.Name = \''+plantel[p]+'\' ';

						}
						
					}else{

						whereClause += ' OR Plantel__r.Name = \''+plantel[p]+'\' ';

					}
				}

				if(plantel.size() > 1){
					whereClause += ') ';
				}
			}

			if( nivel != null && nivel.size() > 0 ){

				for(Integer n = 0 ; nivel.size() > n ; n++){

					if(n == 0){

						if(nivel.size() == 1){
							
							whereClause += ' AND (Nivel__r.Name = \''+nivel[n]+'\') ';

						}else if(nivel.size() > 1){

							whereClause += ' AND (Nivel__r.Name = \''+nivel[n]+'\' ';

						}
						

					}else{

						whereClause += ' OR Nivel__r.Name = \''+nivel[n]+'\' ';
						
					}
				}
				if(nivel.size() > 1){

					whereClause += ') ';

				}
			}

			if( programa != null && programa.size() > 0 ){

				for(Integer pr = 0 ; programa.size() > pr ; pr++){

					if(pr == 0){

						if(programa.size() == 1){

							whereClause += ' AND (Programa__r.Name = \''+programa[pr]+'\') ';

						}else if(programa.size() > 1){

							whereClause += ' AND (Programa__r.Name = \''+programa[pr]+'\' ';

						}

					}else{

						whereClause += ' OR Programa__r.Name = \''+programa[pr]+'\' ';
						
					}
				}

				if(programa.size() > 1){

					whereClause += ') ';

				}
			}
			
			query += ' WHERE '+ whereClause + ' ORDER BY LastModifiedDate Desc';

			System.debug('getPromociones query:'+query);
			
			List<ConfiguradorPromocion__c> lstPromociones = (List<ConfiguradorPromocion__c>)Database.query(query);

			System.debug('-------------------->'+lstPromociones);
			//RJP
			map<Promocion__c,list<ConfiguradorPromocion__c>> mapPromocion_Configuradores = new map<Promocion__c,list<ConfiguradorPromocion__c>> ();
			list<WrapperPromocionMapa> lstWPromocionMapa = new list<WrapperPromocionMapa>();
			
			if( lstPromociones != null && lstPromociones.size() > 0 ){
				//RJP:Mejorar esta consulta			
				List<OEPromocionOtorgada__c> lstOEPOtorgada = [select PromocionConfigurada__c,PromocionConfigurada__r.Promocion__c from OEPromocionOtorgada__c Where PromocionConfigurada__c IN: lstPromociones AND (Lead__c != null OR Oportunidad__c != null)];
				List<WrapperTablaPromocion> lstWPromocion = new List<WrapperTablaPromocion>();
				Map<String,SObject> mapPromoOtorgadas =  new Map<String,SObject>();
				if( lstOEPOtorgada != null && lstOEPOtorgada.size() > 0 ){
					for(OEPromocionOtorgada__c promoOtorgada : lstOEPOtorgada ){
						if(!mapPromoOtorgadas.containsKey(promoOtorgada.PromocionConfigurada__r.Promocion__c)){
							mapPromoOtorgadas.put(promoOtorgada.PromocionConfigurada__r.Promocion__c, promoOtorgada);
						}
						
					}
				}

				for( ConfiguradorPromocion__c confPromo : lstPromociones ){
					if(!mapPromocion_Configuradores.containsKey(confPromo.Promocion__r)){
						mapPromocion_Configuradores.put(confPromo.Promocion__r, new list<ConfiguradorPromocion__c>());
					}
					mapPromocion_Configuradores.get(confPromo.Promocion__r).add(confPromo);

					WrapperTablaPromocion wPromocion = new WrapperTablaPromocion();
					wPromocion.editable = !mapPromoOtorgadas.containsKey(confPromo.Id);
					wPromocion.promocion = confPromo;
					lstWPromocion.add(wPromocion);
				}

				mapResponse.put('state','Success');
				mapResponse.put('data',lstWPromocion);
				
				//RJP:nueva configuracion
				for(Promocion__c promo : mapPromocion_Configuradores.keySet()){
						WrapperPromocionMapa wpm =  new WrapperPromocionMapa();
						wpm.promocion = promo;
						wpm.editable = !mapPromoOtorgadas.containsKey(promo.Id);
						wpm.configuradores = mapPromocion_Configuradores.get(promo);
						lstWPromocionMapa.add(wpm);
				}	
				mapResponse.put('dataPromoConfiguradores',lstWPromocionMapa);
				
				return mapResponse;	

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón promociones filtradas.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getPromociones linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Map<String, Object> getPromocionesConvivencias(String periodo,String modalidad,String plantel,String nivel,String programa,String letra,String concepto,String tipo){

		System.debug('periodo:'+periodo);
		System.debug('modalidad:'+modalidad);
		System.debug('plantel:'+plantel);
		System.debug('nivel:'+nivel);
		System.debug('programa:'+programa);
		System.debug('letra:'+letra);
		System.debug('concepto:'+concepto);
		System.debug('tipo:'+tipo);

		Map<String,Object> mapResponse = new Map<String,Object>();

		try{

			String query = 'SELECT Id, Name, CantidadPago__c, Promocion__c, Promocion__r.Name,Promocion__r.AplicaOtrasPromociones__c, Promocion__r.AcumularDescuentos__c, Promocion__r.Estatus__c, Promocion__r.FechaFinVigencia__c,  Promocion__r.RequiereAutorizacion__c, Periodo__c, Periodo__r.Name, Periodo__r.FechaFin__c, Modalidad__c, Modalidad__r.Name, Plantel__c, Plantel__r.Name, Nivel__c, Nivel__r.Name, Programa__c, Programa__r.Name FROM ConfiguradorPromocion__c';

			string whereClause = '';

			whereClause += String.isBlank(periodo) 	 ? '' : ' Periodo__c = \''+	periodo+'\' ';
			whereClause += String.isBlank(modalidad) ? '' : ' AND Modalidad__c = \''+modalidad+'\' ';
			whereClause += String.isBlank(plantel)  ? '' : ' AND Plantel__c = \''+plantel+'\' ';
			whereClause += String.isBlank(nivel) ? '' : ' AND Nivel__c = \''+nivel+'\' ';
			whereClause += String.isBlank(programa) ? '' : ' AND Programa__c = \''	+programa+'\' ';

				
			List<String> lstLetras = letra.split(';');
/*
			if( lstLetras.size() > 0 ){

				for(Integer le = 0 ; lstLetras.size() > le ; le++){

					if(le == 0){

						if(lstLetras.size() == 1){
							
							whereClause += ' AND (Letra__c includes (\''+lstLetras[le]+'\') ) ';

						}else if(lstLetras.size() > 1){

							whereClause += ' AND (Letra__c includes (\''+lstLetras[le]+'\')';

						}
						
					}else{

						whereClause += ' OR Letra__c includes (\''+lstLetras[le]+'\') ';

					}
				}

				if(lstLetras.size() > 1){
					whereClause += ') ';
				}				

			}	*/					

			if( tipo == 'Descuento' ){

				whereClause += ' AND Promocion__r.NombreConcepto__r.Name =\''+concepto+'\' ';
			}

			query += ' WHERE '+ whereClause;

			System.debug('$$$$getPromocionesConvivencias query:'+query);
			
			List<ConfiguradorPromocion__c> lstCPromociones = (List<ConfiguradorPromocion__c>)Database.query(query);

			System.debug('-------------------->'+lstCPromociones);
			if( lstCPromociones != null && lstCPromociones.size() > 0 ){

				List<OEPromocionOtorgada__c> lstOEPOtorgada = [select PromocionConfigurada__c from OEPromocionOtorgada__c Where PromocionConfigurada__c IN: lstCPromociones AND (Lead__c != null OR Oportunidad__c != null)];

				system.debug('$$$$ lstOEPOtorgada'+ lstOEPOtorgada);
				List<WrapperTablaPromocion> lstWPromocion = new List<WrapperTablaPromocion>();

				Map<String,SObject> mapPromoOtorgadas =  new Map<String,SObject>();

				if( lstOEPOtorgada != null && lstOEPOtorgada.size() > 0 ){

					for(OEPromocionOtorgada__c promoOtorgada : lstOEPOtorgada ){
						   
						if(!mapPromoOtorgadas.containsKey(promoOtorgada.PromocionConfigurada__c)){
							
							mapPromoOtorgadas.put(promoOtorgada.PromocionConfigurada__c, promoOtorgada);
					   
						}
						
					}

				}
				
				for( ConfiguradorPromocion__c confPromo : lstCPromociones ){

					WrapperTablaPromocion wPromocion = new WrapperTablaPromocion();
					wPromocion.editable = !mapPromoOtorgadas.containsKey(confPromo.Id);
					wPromocion.promocion = confPromo;
					lstWPromocion.add(wPromocion);
					System.debug('$$$$ lstWPromocion' + lstWPromocion);
				}
				
				mapResponse.put('state','Success');
				mapResponse.put('data',lstWPromocion);
				System.debug('$$$$ mapResponse' + mapResponse);
				return mapResponse;	

			}else{

				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón convivencias con los mismos criterios.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getPromocionesConvivencias linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}
	}

	@RemoteAction
	public static Map<String, Object> getPromotionConvivencia(String promotionID,String tipo){

		System.debug('getPromotionConvivencia:' + promotionID);

		Map<String, Object> mapResponse = new Map<String, Object>();    	

		try{

			List<OEPromocionConvivencia__c> lstPromoConvivencia = new List<OEPromocionConvivencia__c>();
			String tipoRegistro = ( tipo == 'Descuento') ? 'Promociones con Descuentos Acumulables' : 'Aplica con otras Promociones'; 
			system.debug('$$$$ tipoRegistro'+ tipoRegistro);
			lstPromoConvivencia = [select Id, Name, Promocion__c,Promocion__r.Promocion__c,Promocion__r.Promocion__r.Name, PromocionConvive__c,PromocionConvive__r.Promocion__c,PromocionConvive__r.Promocion__r.Name from OEPromocionConvivencia__c where Promocion__c =: promotionID AND RecordType.Name =: tipoRegistro ];
			system.debug('$$$$ lstPromoConvivencia'+ lstPromoConvivencia);
			if( lstPromoConvivencia != null && lstPromoConvivencia.size() > 0 ){
				system.debug('$$$$ entre promocionesconvivencia');
				mapResponse.put('state', 'Success');
				mapResponse.put('data', (Object)lstPromoConvivencia);
				System.debug('$$$$ respuesta' + mapResponse);

				return mapResponse;

			}else{

				mapResponse.put('state', 'Null');
				mapResponse.put('response', 'No se encontrarón convivencias de la promoción elegida.');
				system.debug('$$$$ mapResponse'+ mapResponse);
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getPromotionConvivencia linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}
		
	@RemoteAction
	public static Map<String,Object> getOEPromotionDescuento(){

		Map<String, Object> mapResponse = new Map<String, Object>();
		List<OEPromocionDescuento__c> oePromotionDescuento = new List<OEPromocionDescuento__c>(); 

		try{
			DateTime dt = DateTime.now() -25;
			//String formattedDt = dt.format('2019-08-01\'T\'00:22:57.000\'Z\'');

			oePromotionDescuento = [select Id,
									Promocion__c,
									NumeroPago__c,
									PorcentajeDescuento__c,
									Promocion__r.PromocionConfigurada__r.Promocion__r.Name,
									Promocion__r.PromocionConfigurada__r.Promocion__c,
									Promocion__r.OfertaEducativa__c,
									Promocion__r.Grupo__c
									from OEPromocionDescuento__c  where CreatedDate >: dt];

			if( oePromotionDescuento != null && oePromotionDescuento.size() > 0){

				mapResponse.put('state','Success');
				mapResponse.put('data',oePromotionDescuento);
				
				return mapResponse;

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón registros OEPromocionDescuento__c = '+oePromotionDescuento);
				
				return mapResponse;

			}

		}catch(Exception ex){
			
			String error = 'Exception Promociones-getOEPromotionDescuento linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;
		}

	}

	@RemoteAction
	public static Map<String, Object> upsertPromotion(String jsonPromotion){
		System.debug('Entre en la funcion upsertPromotion **********');
		System.debug('upsertPromotion:' + jsonPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();
		Promocion__c promocion = new Promocion__c(); 

		try{

			promocion = (Promocion__c)JSON.deserialize(jsonPromotion,Promocion__c.class);
			System.debug('Promocion__c: ' + promocion);
            System.debug('$$$$ promocion cantidad pagos' + promocion.CantidadPago__c);
            
            

            upsert promocion;

			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)promocion);
			System.debug('respuesta' + mapResponse);
			return mapResponse;

		}catch(Exception ex){

			String error = 'Exception Promociones-upsertPromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Map<String, Object> upsertOEPromotion(String jsonPromotion){
		System.debug('Entre en la funcion upsertOEPromotion **********');
		System.debug('upsertOEPromotion:' + jsonPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();
		List<OEPromocion__c> oePromocion = new List<OEPromocion__c>(); 

		try{

			oePromocion = (List<OEPromocion__c>)JSON.deserialize(jsonPromotion,List<OEPromocion__c>.class);
			System.debug('Promocion__c: ' + oePromocion);

            upsert oePromocion;

			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)oePromocion);
			System.debug('respuesta' + mapResponse);

			return mapResponse;
			
		}catch(Exception ex){

			String error = 'Exception Promociones-upsertOEPromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Map<String, Object> upsertOEPromotionDescuento(String jsonPromotion){
		System.debug('Entre en la funcion upsertOEPromotionDescuento **********');
		System.debug('upsertOEPromotionDescuento:' + jsonPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();
		List<OEPromocionDescuento__c> oePromocion = new List<OEPromocionDescuento__c>(); 

		try{

			oePromocion = (List<OEPromocionDescuento__c>)JSON.deserialize(jsonPromotion,List<OEPromocionDescuento__c>.class);
			System.debug('OEPromocionDescuento__c: ' + oePromocion);  

			//update OEPromocion;
			upsert oePromocion;

			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)oePromocion);
			System.debug('respuesta' + mapResponse);

			return mapResponse;
			
		}catch(Exception ex){

			String error = 'Exception Promociones-upsertOEPromotionDescuento linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

 	@RemoteAction
	public static Map<String, Object> upsertPromotionAndConfigurator(String jsonPromotion,List<ConfiguradorPromocion__c> jsonConfigurator,String configuradorPromocionID,String concepto,Boolean aprobacion){
		System.debug('Entre en la funcion upsertPromotionAndConfigurator **********');
		System.debug('upsertPromotionAndConfigurator:ConfiguradorPromocion__c:'+jsonConfigurator);
		System.debug('upsertPromotionAndConfigurator || jsonPromotion: ' + jsonPromotion);
        
		Map<String, Object> mapResponse = new Map<String, Object>();
		Promocion__c promocion = new Promocion__c();
		List<ConfiguradorPromocion__c> confPromocion = new List<ConfiguradorPromocion__c>();
		
		Set<Id> periodos = new Set<Id>();
		Set<Id> modalidades = new Set<Id>();
		Set<Id> planteles = new Set<Id>();
		Set<Id> niveles = new Set<Id>();
		Set<Id> programas = new Set<Id>();

		Savepoint sp = Database.setSavepoint();

		try{

			promocion = (Promocion__c)JSON.deserialize(jsonPromotion,Promocion__c.class);
			System.debug('upsertPromotionAndConfigurator || Promocion__c: ' + promocion);
			Catalogo__c catalogo =  [SELECT Id, Name, HeredarCantidadPagosColegiaturaOE__c, HeredarCantidadPagosInscripcionOE__c  FROM Catalogo__c WHERE Id =: promocion.NombreConcepto__c];
			System.debug('upsertPromotionAndConfigurator || catalogo: ' + catalogo);
            //System.debug('upsertPromotionAndConfigurator || Promocion.Id :' + promocion.Id);
			//update promocion;
            upsert promocion;

            List<ConfiguradorPromocion__c> pC = [select CantidadPago__c,Concepto__c,  EnviadoERP__c, EnviadoERPFecha__c, Id, IdInterno__c, ImporteConcepto__c,  Letra__c, LetraTodas__c, Modalidad__c, ModalidadTodas__c, ModificadoERP__c, Name, Nivel__c, NivelTodos__c, Periodo__c, Plantel__c, PlantelTodos__c, Programa__c, ProgramaTodos__c from ConfiguradorPromocion__c where promocion__c = :promocion.Id];
            System.debug('$$$$   pC ' + pC);
            if(pC.size() > 0 && pC != null){
                for(ConfiguradorPromocion__c cP : pC){

                    if( ((catalogo.Name == 'Colegiatura' || catalogo.Name == 'Reinscripción') && promocion.SeleccionarCantidadPagosOE__c == true)
					|| promocion.SeleccionarCantidadPagosOE__c == true ){
                        System.debug('upsertPromotionAndConfigurator::EsColegiaturaInscripcion1');
                        if( !periodos.contains(cP.Periodo__c) ){
                            periodos.add(cP.Periodo__c);
                        }
    
                        if( !modalidades.contains(cP.Modalidad__c) ){
                            modalidades.add(cP.Modalidad__c);
                        }
    
                        if( !planteles.contains(cP.Plantel__c) ){
                            planteles.add(cP.Plantel__c);
                        }
    
                        if( !niveles.contains(cP.Nivel__c) ){
                            niveles.add(cP.Nivel__c);
                        }
    
                        if( !programas.contains(cP.Programa__c) ){
                            programas.add(cP.Programa__c);
                        }
    
                    }
    
                    //cp.Promocion__c = promocion.Id;
                    cp.CantidadPago__c = promocion.CantidadPago__c;
                    cp.ImporteConcepto__c = promocion.ImporteConcepto__c;
                    cp.Concepto__c = catalogo.Name;
                    confPromocion.add(cP);
                    System.debug('jsonConfigurator::cp' + cp);
                }
            }else{
                for(ConfiguradorPromocion__c cP : jsonConfigurator){

                    if( ((catalogo.Name == 'Colegiatura' || catalogo.Name == 'Reinscripción') && promocion.SeleccionarCantidadPagosOE__c == true)
					|| promocion.SeleccionarCantidadPagosOE__c == true ){
                        System.debug('upsertPromotionAndConfigurator::EsColegiaturaInscripcion1');
                        if( !periodos.contains(cP.Periodo__c) ){
                            periodos.add(cP.Periodo__c);
                        }
    
                        if( !modalidades.contains(cP.Modalidad__c) ){
                            modalidades.add(cP.Modalidad__c);
                        }
    
                        if( !planteles.contains(cP.Plantel__c) ){
                            planteles.add(cP.Plantel__c);
                        }
    
                        if( !niveles.contains(cP.Nivel__c) ){
                            niveles.add(cP.Nivel__c);
                        }
    
                        if( !programas.contains(cP.Programa__c) ){
                            programas.add(cP.Programa__c);
                        }
    
                    }
    
                    cp.Promocion__c = promocion.Id;
                    cp.CantidadPago__c = promocion.CantidadPago__c;
                    cp.ImporteConcepto__c = promocion.ImporteConcepto__c;
                    cp.Concepto__c = catalogo.Name;
                    confPromocion.add(cP);
                    System.debug('jsonConfigurator::cp3' + cp);
                }
            }
			


			
			/* if(((catalogo.Name == 'Colegiatura' || catalogo.Name == 'Reinscripción') && promocion.SeleccionarCantidadPagosOE__c == true)
			|| promocion.SeleccionarCantidadPagosOE__c == true ){
				System.debug('upsertPromotionAndConfigurator::EsColegiaturaInscripcion2');
                System.debug('$$$$ programas' + programas);
				List<OfertaEducativa__c> ofertaE = [select Periodo__c, Modalidad__c, Plantel__c, Nivel__c, Programa__c, NumeroColegiaturas__c, NumeroInscripciones__c from OfertaEducativa__c WHERE Periodo__c IN: periodos AND Modalidad__c IN: modalidades AND Plantel__c IN: planteles AND Nivel__c IN: niveles AND Programa__c IN: programas];
				
                System.debug('$$$$ ofertaE' + ofertaE);
				promocion.PagoDiferido__c = false;
				promocion.PagoUnico__c = false;
				
				map<String,OfertaEducativa__c> mapOfertaEducativa = new map<String,OfertaEducativa__c>();
				for(OfertaEducativa__c oe : ofertaE){
					String keymap = '' + oe.Periodo__c +oe.Modalidad__c + oe.Plantel__c +  oe.Nivel__c + oe.Programa__c;
					if(!mapOfertaEducativa.containsKey(keymap)){
						mapOfertaEducativa.put(keymap,oe);
					}
				}

				
				System.debug('upsertPromotionAndConfigurator::mapOfertaEducativa' + mapOfertaEducativa);
                System.debug('$$$$ confPromocion' + confPromocion);
				if( ofertaE != null && ofertaE.size() > 0){

					for( ConfiguradorPromocion__c confPromo : confPromocion ){
						string keyConfigurado = '' + confPromo.Periodo__c +confPromo.Modalidad__c + confPromo.Plantel__c +  confPromo.Nivel__c + confPromo.Programa__c;
						system.debug('$$$$ cantidad pagos ' + confPromo.Promocion__r.NombreConcepto__c );	
                        if(catalogo.Name == confPromo.Concepto__c){
								if(mapOfertaEducativa.containsKey(keyConfigurado)){
									confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroColegiaturas__c;
								}
							}
							/*if(catalogo.Id == confPromo.Promocion__r.NombreConcepto__c){
								if(mapOfertaEducativa.containsKey(keyConfigurado)){
									confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroInscripciones__c;
								}
							}*

					}
					
				}

			}  */
			if(   ((catalogo.Name == 'Colegiatura' || catalogo.Name == 'Reinscripción') && promocion.SeleccionarCantidadPagosOE__c == true)
				|| promocion.SeleccionarCantidadPagosOE__c == true ){
				System.debug('upsertPromotionAndConfigurator::EsColegiaturaInscripcion2');
				List<OfertaEducativa__c> ofertaE = [select Periodo__c, Modalidad__c, Plantel__c, Nivel__c, Programa__c, NumeroColegiaturas__c, NumeroInscripciones__c from OfertaEducativa__c WHERE Periodo__c IN: periodos AND Modalidad__c IN: modalidades AND Plantel__c IN: planteles AND Nivel__c IN: niveles AND Programa__c IN: programas];

				promocion.PagoDiferido__c = false;
				promocion.PagoUnico__c = false;
				
				map<String,OfertaEducativa__c> mapOfertaEducativa = new map<String,OfertaEducativa__c>();
				for(OfertaEducativa__c oe : ofertaE){
					String keymap = '' + oe.Periodo__c +oe.Modalidad__c + oe.Plantel__c +  oe.Nivel__c + oe.Programa__c;
					if(!mapOfertaEducativa.containsKey(keymap)){
						mapOfertaEducativa.put(keymap,oe);
					}
				}
				System.debug('upsertPromotionAndConfigurator::mapOfertaEducativa' + mapOfertaEducativa);
				if( ofertaE != null && ofertaE.size() > 0){

					for( ConfiguradorPromocion__c confPromo : confPromocion ){
						string keyConfigurado = '' + confPromo.Periodo__c +confPromo.Modalidad__c + confPromo.Plantel__c +  confPromo.Nivel__c + confPromo.Programa__c;
							if(catalogo.Name == 'Colegiatura'){
								if(mapOfertaEducativa.containsKey(keyConfigurado)){
									confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroColegiaturas__c;
								}
							}
							else if(catalogo.Name == 'Reinscripción'){
								if(mapOfertaEducativa.containsKey(keyConfigurado)){
									confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroInscripciones__c;
								}
							}
							else{
								if(catalogo.HeredarCantidadPagosColegiaturaOE__c == true){
									if(mapOfertaEducativa.containsKey(keyConfigurado)){
										confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroColegiaturas__c;
									}
								}
								if(catalogo.HeredarCantidadPagosInscripcionOE__c == true){
									if(mapOfertaEducativa.containsKey(keyConfigurado)){
										confPromo.CantidadPago__c = mapOfertaEducativa.get(keyConfigurado).NumeroInscripciones__c;
									}
								}
							}

					}
					
				}

			} 

			System.debug('ConfiguradorPromocion__c: ' + confPromocion); 
			
            
           		//update confPromocion;
				upsert confPromocion;     
            
            

			// if( configuradorPromocionID != null 
			// && configuradorPromocionID != '' 
			// && configuradorPromocionID.length() > 0 ){

			// 	ConfiguradorPromocion__c configuradorPromo = [SELECT Id,Name,(SELECT Id,Name FROM OEPromociones__r),(SELECT Id,Name FROM OE_Promociones_Convivencia1__r) FROM ConfiguradorPromocion__c WHERE Id =: configuradorPromocionID];
								
			// 	if( configuradorPromo != null ){ 

			// 		List<OEPromocionConvivencia__c> lstOPC = new List<OEPromocionConvivencia__c>();

			// 		for(OEPromocionConvivencia__c opc : configuradorPromo.OE_Promociones_Convivencia1__r){
			// 			lstOPC.add(opc);
			// 		}

			// 		List<OEPromocion__c> lstOEP = new List<OEPromocion__c>(); 

			// 		for(OEPromocion__c oep : configuradorPromo.OEPromociones__r){
			// 			lstOEP.add(oep);
			// 		}

			// 		if( lstOPC != null && lstOPC.size() > 0){
			// 			delete lstOPC;
			// 		}

			// 		if( lstOEP != null && lstOEP.size() > 0){
			// 			delete lstOEP;
			// 		}

			// 		delete configuradorPromo;

			// 	}

			// }

			/*if(aprobacion){
				Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
				approvalRequest.setComments(comentarios);
				approvalRequest.setObjectId(oppApp.Id);
				approvalRequest.setProcessDefinitionNameOrId('Registro_en_dias_de_gracia');
				approvalRequest.setSkipEntryCriteria(true);
			
				Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
				System.debug('offer submitted for approval successfully: '+approvalResult.isSuccess());
			}*/

			mapResponse.put('state', 'Success');
			mapResponse.put('responsePromocion', (Object)promocion);
			System.debug('respuesta' + mapResponse);

			return mapResponse;

		}catch(Exception ex){

			Database.rollback(sp);

			//throw ex;
			String error = 'Exception Promociones-upsertPromotionAndConfigurator linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('message', ex.getMessage());
			mapResponse.put('stackTrace', ex.getStackTraceString());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Map<String, Object> deleteOEPromotion(String jsonPromotion){
		
		System.debug('deleteOEPromotion:' + jsonPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();
		List<OEPromocion__c> oeP = new List<OEPromocion__c>();
		try{

			oeP = (List<OEPromocion__c>)JSON.deserialize(jsonPromotion,List<OEPromocion__c>.class);
			System.debug('OEPromocion__c: ' + oeP);

			delete oeP;

			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)oeP);
			System.debug('respuesta' + mapResponse);
			return mapResponse;

		}catch(Exception ex){

			String error = 'Exception Promociones-deleteOEPromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}
	
	@RemoteAction
	public static Map<String, Object> deletePromotion(String jsonPromotion){
		
		System.debug('deletePromotion:' + jsonPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();        
		Promocion__c promocion = new Promocion__c();

		try{

			promocion = (Promocion__c)JSON.deserialize(jsonPromotion,Promocion__c.class);
			System.debug('Promocion__c: ' + promocion);    

			list<ConfiguradorPromocion__c> listCP = [SELECT Id FROM ConfiguradorPromocion__c WHERE Promocion__c =: promocion.Id];

			delete listCP;
			delete promocion;

			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)promocion);
			System.debug('respuesta' + mapResponse);
			return mapResponse;

		}catch(Exception ex){

			String error = 'Exception Promociones-deletePromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Map<String, Object> deleteConfigPromotion(String idConfigPromotion){
		System.debug('idConfigPromotion:' + idConfigPromotion);
		Map<String, Object> mapResponse = new Map<String, Object>();        
		ConfiguradorPromocion__c configPromocion = new ConfiguradorPromocion__c(Id = idConfigPromotion);
		try{
			delete configPromocion;
			mapResponse.put('state', 'Success');
			mapResponse.put('response', (Object)configPromocion);
			System.debug('respuesta' + mapResponse);
			return mapResponse;

		}catch(Exception ex){
			String error = 'Exception Promociones-deletePromotion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();
			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);
			return mapResponse;
		}
	}

	@RemoteAction
	public static Map<String, Object> upsertPromotionConvivencia(List<OEPromocionConvivencia__c> jsonPromotion,List<OEPromocionConvivencia__c> existentPromotions,String tipo,String promocionPadre){

		System.debug('upsertPromotionConvivencia jsonPromotion:' + jsonPromotion);
		System.debug('upsertPromotionConvivencia existentPromotions:' + existentPromotions);
		System.debug('upsertPromotionConvivencia tipo:' + tipo);

		Map<String, Object> mapResponse = new Map<String, Object>();
		List<OEPromocionConvivencia__c> confPromocion = new List<OEPromocionConvivencia__c>();
		Map<Id,Id> mapEntrante = new Map<Id,Id>();
		Map<Id,Id> mapExistente = new Map<Id,Id>();
		Id recordTypeIdV = null;

		try{

			//Asignar que tipo de registro es 
			if( tipo == 'Promocion'){
				recordTypeIdV = Schema.SObjectType.OEPromocionConvivencia__c.getRecordTypeInfosByName().get('Aplica con otras Promociones').getRecordTypeId();
			}else if( tipo == 'Descuento' ){
				recordTypeIdV = Schema.SObjectType.OEPromocionConvivencia__c.getRecordTypeInfosByName().get('Promociones con Descuentos Acumulables').getRecordTypeId();
			}
			

			Set<Id> lstToDelete = new Set<Id>();

			if( existentPromotions != null 
			&& existentPromotions.size() > 0 
			&& jsonPromotion != null 
			&& jsonPromotion.size() > 0 ){

				for( OEPromocionConvivencia__c toSave : jsonPromotion ){

					if( !mapEntrante.containsKey(toSave.PromocionConvive__c ) ){
						mapEntrante.put(toSave.PromocionConvive__c, toSave.Promocion__c);
					}					
				}

				for( OEPromocionConvivencia__c existente : existentPromotions ){
					
					if( !mapExistente.containsKey(existente.PromocionConvive__c ) ){
						mapExistente.put(existente.PromocionConvive__c, existente.Id);
					}	
				}

				if( mapExistente != null 
				&& mapExistente.size() > 0 
				&& mapEntrante != null 
				&& mapEntrante.size() > 0 ){

					Set<Id> keyExistente = mapExistente.keySet();

					for( Id existentePromo : keyExistente ){

						if(!mapEntrante.containsKey(existentePromo)){

							lstToDelete.add(mapExistente.get(existentePromo));

						}

					}
				}
			}

			System.debug('lstToDelete:'+lstToDelete);

			if( lstToDelete != null && lstToDelete.size() > 0 ){

				List<OEPromocionConvivencia__c> lstDelete = [SELECT Id FROM OEPromocionConvivencia__c WHERE Id IN: lstToDelete];

				if( lstDelete != null && lstDelete.size() > 0 ){

					delete lstDelete;
					
				}
			}

			if( jsonPromotion != null && jsonPromotion.size() > 0){

				for(OEPromocionConvivencia__c pC : jsonPromotion){

					if( pC.Id == null ){

						OEPromocionConvivencia__c promoConvivencia = new OEPromocionConvivencia__c();

						promoConvivencia.Promocion__c = pC.Promocion__c;
						promoConvivencia.PromocionConvive__c = pC.PromocionConvive__c;
						promoConvivencia.RecordTypeId = recordTypeIdV;

						confPromocion.add(promoConvivencia);

					}
					
				}

				System.debug('confPromocion:'+confPromocion);

				upsert confPromocion;
				
				
				mapResponse.put('response', (Object)confPromocion);

			}else if( jsonPromotion != null && jsonPromotion.size() == 0 ){

				List<OEPromocionConvivencia__c> lstDelete = [SELECT Id FROM OEPromocionConvivencia__c WHERE Promocion__c =: promocionPadre];

				if( lstDelete != null && lstDelete.size() > 0 ){

					delete lstDelete;

					mapResponse.put('response', (Object)lstDelete);

					System.debug('respuesta' + mapResponse);
				}

			}

			mapResponse.put('state', 'Success');        	
			return mapResponse;

		}catch(Exception ex){

			String error = 'Exception Promociones-upsertPromotionConvivencia linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('cause', ex.getCause());
			mapResponse.put('lineNumber', ex.getLineNumber());
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	@RemoteAction
	public static Object getGruposPromocion(String periodo,String modalidad,List<String> plantel,List<String> nivel,List<String> programa){

		System.debug('periodo:'+periodo);
		System.debug('modalidad:'+modalidad);
		System.debug('plantel:'+plantel);
		System.debug('nivel:'+nivel);
		System.debug('programa:'+programa);

		Map<String,Object> mapResponse = new Map<String,Object>();
		Map<String,Map<String,List<WrapperGrupoPromocion>>> mapWGrupoPromocion = new Map<String,Map<String,List<WrapperGrupoPromocion>>>();

		try{
			String query = 'SELECT Id, Promocion__r.OfertaEducativa__c, Promocion__r.OfertaEducativa__r.Name, Promocion__r.OfertaEducativa__r.Periodo__r.Name, Promocion__r.OfertaEducativa__r.Modalidad__r.Name, Promocion__r.OfertaEducativa__r.Plantel__r.Name, Promocion__r.OfertaEducativa__r.Nivel__r.Name, Promocion__r.OfertaEducativa__r.Programa__r.Name, Promocion__r.Grupo__r.Name, Promocion__r.Grupo__r.Estatus__c, Promocion__c, Promocion__r.PromocionConfigurada__r.Promocion__r.Name, Promocion__r.PromocionConfigurada__r.Promocion__r.NombreConcepto__r.Name, NumeroPago__c, PorcentajeDescuento__c FROM OEPromocionDescuento__c';
			DateTime dt = DateTime.now();
			String formattedDt = dt.format('2019-07-01\'T\'00:22:57.000\'Z\'');
			String whereClause = 'CreatedDate > ' + formattedDt + ' AND ';


			whereClause += String.isBlank(periodo) 	 ? '' : 'Promocion__r.OfertaEducativa__r.Periodo__r.Name = \''			+	periodo+'\' ';
		
			whereClause += String.isBlank(modalidad) 	 ? '' : ' AND Promocion__r.OfertaEducativa__r.Modalidad__r.Name = \''	+	modalidad+'\' ';

			if( plantel != null && plantel.size() > 0 ){

				for(Integer p = 0 ; plantel.size() > p ; p++){

					if(p == 0){

						if(plantel.size() == 1){
							
							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Plantel__r.Name = \''+plantel[p]+'\') ';

						}else if(plantel.size() > 1){

							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Plantel__r.Name = \''+plantel[p]+'\' ';

						}
						
					}else{

						whereClause += ' OR Promocion__r.OfertaEducativa__r.Plantel__r.Name = \''+plantel[p]+'\' ';

					}
				}

				if(plantel.size() > 1){
					whereClause += ') ';
				}
				system.debug('$$$$ query mio' + query);
			}

			if( nivel != null && nivel.size() > 0 ){

				for(Integer n = 0 ; nivel.size() > n ; n++){

					if(n == 0){

						if(nivel.size() == 1){
							
							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Nivel__r.Name = \''+nivel[n]+'\') ';

						}else if(nivel.size() > 1){

							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Nivel__r.Name = \''+nivel[n]+'\' ';

						}
						

					}else{

						whereClause += ' OR Promocion__r.OfertaEducativa__r.Nivel__r.Name = \''+nivel[n]+'\' ';
						
					}
				}
				if(nivel.size() > 1){

					whereClause += ') ';

				}
				system.debug('$$$$ query mio2' + query);
			}

			if( programa != null && programa.size() > 0 ){

				for(Integer pr = 0 ; programa.size() > pr ; pr++){

					if(pr == 0){

						if(programa.size() == 1){

							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Programa__r.Name = \''+programa[pr]+'\') ';

						}else if(programa.size() > 1){

							whereClause += ' AND (Promocion__r.OfertaEducativa__r.Programa__r.Name = \''+programa[pr]+'\' ';

						}

					}else{

						whereClause += ' OR Promocion__r.OfertaEducativa__r.Programa__r.Name = \''+programa[pr]+'\' ';
						
					}
				}

				if(programa.size() > 1){

					whereClause += ') ';

				}
				system.debug('$$$$ query mio3' + query);
			}
			
			query += ' WHERE '+ whereClause;
			

			System.debug('$$$$ getGruposPromocion query:'+query);
			
			List<OEPromocionDescuento__c> lstPromociones = (List<OEPromocionDescuento__c>)Database.query(query);
			system.debug('$$$$ lstPromociones mio' + lstPromociones);

			if( lstPromociones != null && lstPromociones.size() > 0){
				
				/*WrapperPromocion*/

				// IdOEPromocion , Grupo , List<Wrapper>

				//Recorro todos los conceptos de Pagos con su OEPromocion
				for(OEPromocionDescuento__c promoDescuento : lstPromociones){

					//Si no existe la OEPromocion
					if(!mapWGrupoPromocion.containsKey(promoDescuento.Promocion__r.OfertaEducativa__c)){

						//Creo 1Nivel del mapa
						mapWGrupoPromocion.put(promoDescuento.Promocion__r.OfertaEducativa__c,new Map<String,List<WrapperGrupoPromocion>>());

						//Instancio 2doNivel
						Map<String,List<WrapperGrupoPromocion>> w2doNivel = mapWGrupoPromocion.get(promoDescuento.Promocion__r.OfertaEducativa__c);						

						//Instancio Primer elemento de lista del 3nivel List<WrapperGrupoPromocion>
						WrapperGrupoPromocion wGP = new WrapperGrupoPromocion();

						wGP.periodo = promoDescuento.Promocion__r.OfertaEducativa__r.Periodo__r.Name ;
						wGP.modalidad = promoDescuento.Promocion__r.OfertaEducativa__r.Modalidad__r.Name ;
						wGP.plantel = promoDescuento.Promocion__r.OfertaEducativa__r.Plantel__r.Name ;
						wGP.nivel = promoDescuento.Promocion__r.OfertaEducativa__r.Nivel__r.Name ;
						wGP.programa = promoDescuento.Promocion__r.OfertaEducativa__r.Programa__r.Name ;
						wGP.clave = promoDescuento.Promocion__r.Grupo__r.Name ;
						wGP.estatus = promoDescuento.Promocion__r.Grupo__r.Estatus__c ;

						//Instancio la primer Promocion del grupo List<WrapperPromocion>
						WrapperPromocion wP = new WrapperPromocion();

						wP.nombrePromocion = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.Name ;
						wP.concepto = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.NombreConcepto__r.Name;
						
						//Instancio concepto de Pagos WrapperPagoDescuento
						WrapperPagoDescuento wPD = new WrapperPagoDescuento();
						wPD.noPago = promoDescuento.NumeroPago__c;
						wPD.porcentajeDescuento = promoDescuento.PorcentajeDescuento__c;
						
						//Instancio lista concepto de Pago List<WrapperPagoDescuento>
						List<WrapperPagoDescuento> lstWPD = new List<WrapperPagoDescuento>();
						//Agrego a la lista el concepto pago 
						lstWPD.add(wPD);

						//Agrego a la Promocion la lista de Pagos
						wP.conceptoPagos = lstWPD;

						List<WrapperPromocion> lstwP = new List<WrapperPromocion>();
						lstwP.add(wP);

						wGP.promocion = lstwP;

						//Instancio la lista de GrupoPromocion List<WrapperGrupoPromocion>
						List<WrapperGrupoPromocion> w3Nivel = new List<WrapperGrupoPromocion>();

						//Agrego el grupo promocion a la lista
						w3Nivel.add(wGP);

						//Agrego la lista de Grupo Promocion al mapa de ese Grupo
						w2doNivel.put(promoDescuento.Promocion__r.Grupo__r.Name,w3Nivel);
						
						system.debug('$$$$ w2doNivel if inical' + w2doNivel);
					}else{

						Map<String,List<WrapperGrupoPromocion>> w2doNivel = mapWGrupoPromocion.get(promoDescuento.Promocion__r.OfertaEducativa__c);

						if(!w2doNivel.containsKey(promoDescuento.Promocion__r.Grupo__r.Name)){

							//Instancio el grupo de la OE
							WrapperGrupoPromocion wGP = new WrapperGrupoPromocion();

							wGP.periodo = promoDescuento.Promocion__r.OfertaEducativa__r.Periodo__r.Name ;
							wGP.modalidad = promoDescuento.Promocion__r.OfertaEducativa__r.Modalidad__r.Name ;
							wGP.plantel = promoDescuento.Promocion__r.OfertaEducativa__r.Plantel__r.Name ;
							wGP.nivel = promoDescuento.Promocion__r.OfertaEducativa__r.Nivel__r.Name ;
							wGP.programa = promoDescuento.Promocion__r.OfertaEducativa__r.Programa__r.Name ;
							wGP.clave = promoDescuento.Promocion__r.Grupo__r.Name ;
							wGP.estatus = promoDescuento.Promocion__r.Grupo__r.Estatus__c ;

							//instancio primer promocion de List<WrapperPromocion>
							WrapperPromocion wP = new WrapperPromocion();

							wP.nombrePromocion = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.Name;
							wP.concepto = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.NombreConcepto__r.Name ;
							
							//Instancio concepto de Pagos WrapperPagoDescuento
							WrapperPagoDescuento wPD = new WrapperPagoDescuento();
							wPD.noPago = promoDescuento.NumeroPago__c;
							wPD.porcentajeDescuento = promoDescuento.PorcentajeDescuento__c;
							
							//Instancio lista concepto de Pago List<WrapperPagoDescuento>
							List<WrapperPagoDescuento> lstWPD = new List<WrapperPagoDescuento>();
							//Agrego a la lista el concepto pago 
							lstWPD.add(wPD);

							//Agrego a la lista de Promocion la lista de Pagos
							wP.conceptoPagos = lstWPD;

							//Agrego promocion a la lista
							List<WrapperPromocion> lstwP = new List<WrapperPromocion>();
							lstwP.add(wP);

							//agrego lista de Promocion al grupo
							wGP.promocion = lstwP;

							//Agrego el grupo a lista de grupos
							List<WrapperGrupoPromocion> w3Nivel = new List<WrapperGrupoPromocion>();
							w3Nivel.add(wGP);
							
							//Agrego lista de grupo al Grupo							
							w2doNivel.put(promoDescuento.Promocion__r.Grupo__r.Name,w3Nivel);
							system.debug('$$$$ w2doNivel if segundo dentro else' + w2doNivel);
						}else{

							//Existe Grupo
							List<WrapperGrupoPromocion> w3Nivel = w2doNivel.get(promoDescuento.Promocion__r.Grupo__r.Name);							

							//Bandera para agregar la promocion
							boolean existePromocion = false;	

							//Recorro todos los grupos promocion
							for(WrapperGrupoPromocion wGP : w3Nivel){

								//Contiene al menos una promocion
								if( wGP.promocion != null && wGP.promocion.size() > 0){

									//recorro promociones
									for(WrapperPromocion wP : wGP.promocion){

										//Si la promocion existente es igual a la promoción iterada
										if(wP.nombrePromocion != null 
										&& wP.nombrePromocion == promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.Name){

											//Valido que la promocion contenga conceptos Pagos
											if( wP.conceptoPagos != null 
											&& wP.conceptoPagos.size() > 0){

												Boolean existePago = false;

												for(WrapperPagoDescuento wPD : wP.conceptoPagos){
																									
													if(wPD.noPago == promoDescuento.NumeroPago__c){

														existePago = true;
													}																						
												}

												if(!existePago){

													WrapperPagoDescuento wIPD = new WrapperPagoDescuento();
													wIPD.noPago = promoDescuento.NumeroPago__c;
													wIPD.porcentajeDescuento = promoDescuento.PorcentajeDescuento__c;

													wP.conceptoPagos.add(wIPD);
												}												

											}

											existePromocion = true;
										}

									}

									if(!existePromocion){

										WrapperPromocion wP = new WrapperPromocion();

										wP.nombrePromocion = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.Name;
										wP.concepto = promoDescuento.Promocion__r.PromocionConfigurada__r.Promocion__r.NombreConcepto__r.Name;

										WrapperPagoDescuento wPD = new WrapperPagoDescuento();

										wPD.noPago = promoDescuento.NumeroPago__c;
										wPD.porcentajeDescuento = promoDescuento.PorcentajeDescuento__c;
										
										List<WrapperPagoDescuento> lstWPD = new List<WrapperPagoDescuento>();
										lstWPD.add(wPD);

										wP.conceptoPagos = lstWPD;
										wGP.promocion.add(wP);										

									}

								}

							} 							

						}

					}

				}

				/*WrapperPromocion*/

				
				mapResponse.put('state','Success');
				mapResponse.put('data',mapWGrupoPromocion);
				system.debug('$$$$ mapResponse if inical' + mapResponse);
				
				return mapResponse;	

			}else{
					
				mapResponse.put('state','Null');
				mapResponse.put('response','No se encontrarón Grupos con Promociones filtrados.');
				
				return mapResponse;

			}

		}catch(Exception ex){

			String error = 'Exception Promociones-getGruposPromocion linea:'+ex.getLineNumber()+ ' motivo:'+ex.getCause()+ '/'+ ex.getMessage();

			mapResponse.put('state', 'Exception');
			mapResponse.put('response', (Object)error);

			return mapResponse;

		}

	}

	public class WrapperTablaPromocion{

		public Boolean editable {get;set;}
		public ConfiguradorPromocion__c promocion {get;set;}
		public Object mapPromocion_Configuradores {get;set;}

		public WrapperTablaPromocion(){
			editable = true;
			promocion = new ConfiguradorPromocion__c();
		}

	}

	public class WrapperGrupoPromocion{

		public String periodo {get;set;}
		public String modalidad {get;set;}
		public String plantel {get;set;}
		public String nivel {get;set;}
		public String programa {get;set;}
		public String clave {get;set;}
		public String estatus {get;set;}
		public List<WrapperPromocion> promocion {get;set;}

		public WrapperGrupoPromocion(){

			periodo = '';
			modalidad = '';
			plantel = '';
			nivel = '';
			programa = '';
			clave = '';
			estatus = '';
			promocion = new List<WrapperPromocion>();

		}
	}

	public class WrapperPromocion{

		public String nombrePromocion {get;set;}
		public String concepto {get;set;}
		public List<WrapperPagoDescuento> conceptoPagos {get;set;}	

		public WrapperPromocion(){

			nombrePromocion = ''; 
			concepto = '';
			conceptoPagos = new List<WrapperPagoDescuento>();

		}

	}

	public class WrapperPromocionMapa{
		public Promocion__c promocion {get;set;}
		public List<ConfiguradorPromocion__c> configuradores {get;set;}
		public Boolean editable {get;set;}
		public WrapperPromocionMapa (){
			promocion =  new Promocion__c();
			configuradores = new List<ConfiguradorPromocion__c>();
			editable = true;
		}
	} 

	public class WrapperPagoDescuento{
		public Decimal noPago {get;set;}
		public Decimal porcentajeDescuento {get;set;}

		public WrapperPagoDescuento(){
			noPago = 0.0;
			porcentajeDescuento = 0.0;

		}
	}

}