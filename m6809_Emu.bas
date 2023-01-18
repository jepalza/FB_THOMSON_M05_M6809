' emulador de 6809 y de Thomson Mo5, por Joseba Epalza
'
' Esta basado en varias fuentes de la red, incluidos documentos oficiales y emuladores
' ya existentes, como el DCMOTO 

' modo de pantalla 800x600
Screen 19 ' 800x600
'Screen 12 ' 320x200
Locate 27,0
Print "          Emulador de Thomson Mo5, sobre un emulador de Motorola 6809"
Print "                 Todo ello programado enteramente en Basic 'Puro'"
Print "                 Version sin sonido, Joseba Epalza (Jepalza-2011)"

' necesario para el MULTIKEY
' ademas, si usamos compilacion FB, se necesita el "USING FB"
#include "fbgfx.bi"
#if __FB_LANG__ = "fb"
Using FB 
#EndIf

' necesarios para el "OpenDialog" y selecionar un fichero
'#Define WIN_INCLUDEALL
'#Include once "windows.bi"


	' para el FILEDIALOG
	#Include "windows.bi"
	#Include "win\commdlg.bi"
	Declare Function getname( byval hwndOwner as HWND, byval pszFile as zstring ptr, byval nMaxFile as integer) as Integer
	dim Shared As zstring * MAX_PATH file

' FILEDIALOG
function getname( byval hwndOwner as HWND, _
                  ByVal pszFile as zstring ptr, _
                  ByVal nMaxFile as integer) as integer

    dim as OPENFILENAME ofn

    ofn.lStructSize = sizeof(OPENFILENAME)
    ofn.hWndOwner = hwndOwner
    ofn.lpstrFilter = strptr(!"Cintas *.K7\0*.K7\0Cartuchos *.M5\0*.M5")
    ofn.lpstrFile = pszFile
    ofn.nMaxFile = nMaxFile
    ofn.lpstrTitle = @"Abrir cintas K7 o Cartuchos Mo5"
    ofn.Flags = OFN_FILEMUSTEXIST or OFN_LONGNAMES

    return GetOpenFileName( @ofn )

end Function
dim As zstring * MAX_PATH NombreK7
' ------------------------------------------------------------

' control de ciclos y tiempos para emulacion real
Dim Shared ciclos_ejecutados As Integer=0 ' almacena los ciclos ejecutados en EXECUTE
Dim Shared tiempo1 As Double
Dim Shared tiempo2 As Double

' variables  para lectura de ficheros, como la ROM
Dim linea As String*32
Dim ini As Integer ' inicio de la rom, para su lectura secuencial
Dim inirom As Integer
Dim contador As Integer

' ******************************
' *** nombre de ROM a emular ***
' ******************************
Dim nombreROM As String="MO5.ROM"
' ******************************



		' la variable mas importante, la de la RAM de 64k
		' (+8k de video extras para el Thomson Mo5)
		Dim Shared RAM(&h10000+&h2000) As Integer
		' Borramos la RAM a FF's (solo por precaucion)
		For ini=0 To &hffff+&h2000:ram(ini)=&hff:Next



' ****************************************************************************************
' ***********************   exclusivo par la emulacion de Thomson Mo5 ********************
' ****************************************************************************************

' variables temporales para el emulador de VIDEO de un Thomson Mo5
Dim AA As Integer
Dim BB As Integer
Dim CC As Integer
Dim DD As Integer
Dim EE As Integer
Dim FF As Integer
Dim XX As Integer
Dim YY As Integer
Dim SS As String

' para la emulacion del Thomson Mo5: Teclado, Mandos y lector de Cintas K7
Dim Shared Teclas(128) As Integer ' almacen de teclas pulsadas
Dim shared k7i As Integer=1 ' fichero secuencial de lectura de cinta
Dim Shared k7s As String*1  ' para leer un caracter de la a
Dim Shared k7c As Integer=0 ' para meter el codigo binario del caracter ASCII leido
Dim Shared k7b As Integer=0 ' para ir contando los bits leidos (bit no byte) 
Dim Shared TeclaStop As Integer=0 ' es para comprobar el estado de la tecla "STOP" del Mo5
Dim Shared BancoVideo As Integer=0 ' banco de video-pixel o video-color (0 o &x10000)
Dim Shared escala As Integer=2 ' factor de escala para mostrar el video, por defecto x2

' paleta de colores (16) de un Thomson Mo5 (tonos aproximados "a ojo")
Dim c1 As Integer=255
Dim c2 As Integer=160
Palette 0,0,0,0
Palette 1,c1,0,0
Palette 2,0,c1,0
Palette 3,c1,c1,0
Palette 4,0,0,c1
Palette 5,c1,0,c1
Palette 6,0,c1,c1
Palette 7,c1,c1,c1
Palette 8,c2,c2,c2
Palette 9,c1,c2,c2
Palette 10,c2,c1,c2
Palette 11,c1,c1,c2
Palette 12,c2,c2,c1
Palette 13,c1,c2,c1
Palette 14,c2,c1,c1
Palette 15,c1,c2,0

' registros de emulacion de una primera PIA 6821 (Thomson Mo5: teclado,cinta,video)
Dim Shared cra1 As Integer=&h00 ' control register A
Dim Shared crb1 As Integer=&h00 ' control register B
Dim Shared ora1 As Integer=&h00 ' out register A
Dim Shared orb1 As Integer=&h00 ' out register B
Dim Shared dra1 As Integer=&h5f ' direction register A
Dim Shared drb1 As Integer=&h7e ' direction register B
Dim Shared pia1 As Integer=&h00 ' parallel interface A
Dim Shared pib1 As Integer=&h00 ' parallel interface B

' registros de emulacion de una segunda PIA 6821 (Thomson Mo5: mandos de juego)
	' ....
	' nota: en lugar de emular una segunda PIA solo por la palanca de juegos
	' he preferido inyectar directamente los valores leidos del mando en la RAM
	' ganando velocidad y claridad de codigo


' ****************************************************************************************
' ***********************                                             ********************
' ****************************************************************************************



' Incluimos en este punto el emulador de 6809
' debe ir aqui, para que reconozca las variables anteriores
#Include "6809_CPU.bas" ' --> este a su vez, incluye TODOS los modulos del 6809


   ' leemos la BIOS (ROM) de un Thomson Mo5
	ini=1
	Open nombreROM For Binary Access read As 1
	inirom=Lof(1)
	inirom=65536-inirom 
	While Not Eof(1)
		Get #1,ini,linea
		For contador=1 To Len(linea)
			RAM(inirom)=Asc(Mid(linea,contador,1))
			inirom+=1
		Next
		ini+=len(linea)
	Wend
	'inirom=65536-Lof(1) ' apuntamos a su inicio, solo por si nos hace falta
	Close 1




' ****************** exclusivo del emulador Thomson Mo5 ******************
' con esta serie de trampeos en ROM, generamos
' una INS falsa (la &h01), que no existe, y
' en lugar de tratarla como NULL, que seria lo normal
' la tratamos como si fuera "CINTA()" (la rutina de lectura de cintas)
  
  ' trampeamos la rutina de arrancar motor de cinta
  ram(&hf18b)=&h39 '   RTS
  
  ' trampeamos rutina LOAD
  ram(&hf181)=&h01 ' iosb           
  ram(&hf182)=&h39 '   RTS
  
  ' trampeamos rutina SAVE
  ram(&hf1af)=&h01 ' iosb     
  ram(&hf1b0)=&h39 '   RTS
  
  ' trampeamos la rutina de BITS (Save/load)
  ram(&hf168)=&h01 ' iosb     
  ram(&hf169)=&h39 '   RTS
  
  ' estos son los estados por defecto de la primera PIA 6821
  ram(&ha7c0)=&h01
  ram(&ha7c1)=&h00
  ram(&ha7c2)=&h3e
  ram(&ha7c3)=&h04
  
  ' estos son los estados por defecto de la segunda PIA 6821 (mandos de juego a "cero")
  ram(&ha7cc)=&hff
  ram(&ha7cd)=&hff
  ram(&ha7ce)=&hff
  ram(&ha7cf)=&hff




' inicio de la emulacion
m6809_reset()


' abrimos un fichero de escritura, para la emulación de SAVE en caso de usarse
' OJO: si ya existe, lo sobreescribe y pone a "0"
Open "SaveMo5.k7" For  Binary Access write As 4



' bucle infinito de ejecuciones: solo sale con "ESC"
Var mm=0
Var md=0
Var estado=1/(1000000/60)
While 1 

  ' miramos el reloj antes de de entrar	
  tiempo1=Timer() 
  
  ' ejecutamos el M6809, una instruccion cada vez y sumamos los ciclos empleados
  md=m6809_execute() 
  ciclos_ejecutados += md
  
  ' volvemos a mirar el reloj
  tiempo2=Timer()
  
  ' y vemos si es mayor o menor que el esperado
  tiempo2=tiempo2-tiempo1
  'If tiempo2>(md*estado) Then Sleep (tiempo2-(md*estado),1) ' sin probar
  
  
   ' se ejecutan acciones HARDWARE cada 'x' ciclos
   If (ciclos_ejecutados > 30000) Then 
   	ciclos_ejecutados=0
   	
   	' teclas de FIN: OJO QUE SALE SIN PEDIR CONFIRMACION  
      If MultiKey(SC_ESCAPE) Then End             
   	
   	' Comprobamos interrupciones solo si el estado de CC lo permite
   	m6809_irq()  ' IRQ
   	m6809_firq() ' FIRQ
   	'm6809_NMI() ' NMI no enmascarable
      
		  ' pantalla Mo5 de 40x25 o 320x200, 16 colores    
		  ' emulacion de la pantalla de video (dos bancos de 8k)
		  XX=0:YY=00:EE=0 ' BB=400 en el modo 800x600, para poder depurar
		  For FF=0 To 7999 ' el Mo5 de Thomson, usa 8000+8000 bytes de pantalla: (320/8)x200=8000
		  	 CC=RAM(FF+&H10000) ' color
		    DD=RAM(FF) ' pixel
		    For contador=7 To 0 Step -1
		    	bb=Bit(dd,contador)'*-1
		    	If bb Then bb=cc Shr 4 Else bb=(cc And &h0f)
		      line (XX+ee,YY)-Step(1*escala,1*escala),bb,bf
		      XX+=1*escala
		    Next      
		    ee+=8*escala:XX=0
		    If ee>319*escala Then ee=0:YY+=1*escala
		  Next
		  
		   
         ' si hemos pulsado la tecla "STOP" dentro del Mo5, hacemos RESET en "caliente"
         If TeclaStop Then m6809_reset():TeclaStop=0 
               
			' emulacion del teclado de un Mo5 tratando de adaptarlo a un PC
			For aa=0 To 127:Teclas(aa)=0:Next ' borramos "buffer" cada vez que entramos, para no acumular teclas
			If MultiKey(SC_0) Then           Teclas(&h3C)=1
			If MultiKey(SC_1) Then           Teclas(&h5E)=1
			If MultiKey(SC_2) Then           Teclas(&h4E)=1
			If MultiKey(SC_3) Then           Teclas(&h3E)=1
			If MultiKey(SC_4) Then           Teclas(&h2E)=1
			If MultiKey(SC_5) Then           Teclas(&h1E)=1
			If MultiKey(SC_6) Then           Teclas(&h0E)=1
			If MultiKey(SC_7) Then           Teclas(&h0C)=1
			If MultiKey(SC_8) Then           Teclas(&h1C)=1
			If MultiKey(SC_9) Then           Teclas(&h2C)=1
			If MultiKey(SC_A) Then           Teclas(&h5A)=1 ' "Q" en el Mo5
			If MultiKey(SC_Z) Then           Teclas(&h4A)=1 ' "W" en el Mo5
			If MultiKey(SC_E) Then           Teclas(&h3A)=1
			If MultiKey(SC_R) Then           Teclas(&h2A)=1
			If MultiKey(SC_T) Then           Teclas(&h1A)=1
			If MultiKey(SC_Y) Then           Teclas(&h0A)=1
			If MultiKey(SC_U) Then           Teclas(&h08)=1
			If MultiKey(SC_I) Then           Teclas(&h18)=1
			If MultiKey(SC_O) Then           Teclas(&h28)=1
			If MultiKey(SC_P) Then           Teclas(&h38)=1
			If MultiKey(SC_Q) Then           Teclas(&h56)=1 ' "A" en el mo5
			If MultiKey(SC_S) Then           Teclas(&h46)=1
			If MultiKey(SC_D) Then           Teclas(&h36)=1
			If MultiKey(SC_F) Then           Teclas(&h26)=1
			If MultiKey(SC_G) Then           Teclas(&h16)=1
			If MultiKey(SC_H) Then           Teclas(&h06)=1
			If MultiKey(SC_J) Then           Teclas(&h04)=1
			If MultiKey(SC_K) Then           Teclas(&h14)=1
			If MultiKey(SC_L) Then           Teclas(&h24)=1
			If MultiKey(SC_W) Then           Teclas(&h60)=1 ' "Z" en el Mo5
			If MultiKey(SC_X) Then           Teclas(&h50)=1
			If MultiKey(SC_C) Then           Teclas(&h64)=1
			If MultiKey(SC_V) Then           Teclas(&h54)=1
			If MultiKey(SC_B) Then           Teclas(&h44)=1
			If MultiKey(SC_N) Then           Teclas(&h00)=1
			If MultiKey(SC_M) Then           Teclas(&h34)=1
			'---
			If MultiKey(SC_TAB)       Then   Teclas(&h6A)=1 ' "CNT"  funciona mal, pero funciona
			If MultiKey(SC_TILDE)     Then   Teclas(&h6E)=1: TeclaSTOP=1' "STOP" funciona "raro", tecla "\" en PC español
			If MultiKey(SC_BACKSPACE) Then   Teclas(&h6C)=1 ' "ACC"  no funciona, equivale a "BORRAR"
			'---
			If MultiKey(SC_COMMA)     Then   Teclas(&h10)=1 ' "," y "<"
			If MultiKey(SC_SLASH)     Then   Teclas(&h4c)=1 ' "-" y "="
			If MultiKey(SC_ENTER)     Then   Teclas(&h68)=1
			If MultiKey(SC_SPACE)     Then   Teclas(&h40)=1
			If MultiKey(SC_LSHIFT)    Then   Teclas(&h70)=1
			If MultiKey(SC_RSHIFT)    Then   Teclas(&h72)=1 ' TECLA SHIFT ESPECIAL COMANDOS "BASIC"
			If MultiKey(SC_INSERT)    Then   Teclas(&h12)=1 
			If MultiKey(SC_MULTIPLY)  Then   Teclas(&h58)=1 ' "*"
			If Multikey(SC_HOME)      Then   Teclas(&h66)=1 ' "RAZ" CLS en Mo5, "HOME" o "INICIO" en PC
			If MultiKey(SC_SEMICOLON) Then   Teclas(&h30)=1 ' "@" y "|" mapeada a la "Ñ" española
			If MultiKey(SC_PERIOD)    Then   Teclas(&h20)=1 ' "." y ">"
			If MultiKey(SC_DELETE)    Then   Teclas(&h02)=1 
			'---
			If MultiKey(SC_LEFTBRACKET)  Then Teclas(&h48)=1 ' "/" y "?"
			If MultiKey(SC_RIGHTBRACKET) Then Teclas(&h5C)=1 ' "+" y ";"
         ' cursores (tambien valen como mando de juegos, pero en otra rutina)
			If MultiKey(SC_UP)   Then Teclas(&h62)=1 
			If MultiKey(SC_LEFT) Then Teclas(&h52)=1
			If MultiKey(SC_RIGHT)Then Teclas(&h32)=1
			If MultiKey(SC_DOWN) Then Teclas(&h42)=1
			
			
			
			  ' cargar una cinta o cartucho si pulsamos "F4"
			  If MultiKey(SC_F4) Then
			  	getname( 0, @NombreK7, MAX_PATH )
			  	Close 3 ' nos aseguramos que este cerrado el canal 3
			  	k7i=1 ' ponemos a cero el contador de la cinta
			
			  	Open NombreK7 For Binary Access Read As 3  'abrimos la cinta o cartucho
			
				' si es un "Carchuto" (extension M5), lo leemos tal cual, "pisando" la zona BASIC
			   If UCase(Right(NombreK7,2))="M5" Then
			   	m6809_reset() ' inicializamos la CPU al completo
				   ini=1
					inirom=Lof(3) ' miramos el tamaño de la ROM
					inirom=65536-inirom-4096 ' y ajustamos la direccion de inicio de la misma
					While Not Eof(3)
					Get #3,ini,linea
					For contador=1 To Len(linea)
						RAM(inirom)=Asc(Mid(linea,contador,3))
						inirom+=1
					Next
					ini+=len(linea)
					Wend
					Close 3
			   End If
			  EndIf

   End If

  
' repetimos todo el proceso otra vez
Wend
' aqui solo llegamos al pulsar "ESC", o fin de emulacion



' DISPOSICION DE TECLADO ORIGINAL Mo5
' EN MI EMULADOR, EN LUGAR DE AZERTY ES QWERTY
' Y ALGUNOS DE LOS SIMBOLOS ESTAN EN EL LUGAR DEL TECLADO ESPAÑOL
' OTROS, COMO "/" LOS HE DEJADO EN SU SITIO, EN ESTE CASO LA TECLA "^'[" DEL PC ESPAÑOL
'
' STOP  1!  2"  3#  4$  5%  6&  7'  8(  9)  0  -=  +;  ACC      UP  DOWN
' CTRL    A   Z   E   R   T   Y   U   I   O   P  /?  *:        LEFT RIGHT
' RAZ       Q   S   D   F   G   H   J   K   L    M   ENTER        TOP
' SHIFT       W   X   C   V   B   N   ,<  .>  @^     BASIC      INS DEL
'                        SPACE

