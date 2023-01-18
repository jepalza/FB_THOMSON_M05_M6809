'******************************************
' Funciones de lectura/escritura de RAM/ROM
'*******************************************
Sub pokeb(PT As integer, PV As Integer)

	' para el Thomson Mo5, emulamos los dos bancos de video
	' ambos de &h2000 bytes (8000 bytes), uno para el color y otro para el pixel
	' sobran 192bytes por banco, que se pueden usar en basic ;-)
	If (PT<&h2000) Then 
		 RAM(PT+BancoVideo)=PV:exit Sub 
	EndIf
	
	
	If PT And &hA7c0 Then 
		
		' las direcciones A7C0,C1,C2,C3 son de control de la PIA-1 (teclado,cinta,video)
		' A7C0-1 son PIA PORT A-B
		' A7C2-3 son PIA CONTROL A-B
		
	   ' este es el registro de la PIA-1 que controla los bancos de video
		' primer o segundo banco de video, segun estado del Bit 1 de A7C0	
		If (PT=&hA7C0) Then
			If (cra1 And &h04)=&h04 Then 
			  If (PV And &h01)=&h01 Then
			  	  BancoVideo=&h00000 ' primer banco para los pixeles
			  Else
			  	  BancoVideo=&h10000 ' segundo banco para el color
			  EndIf
	        ora1=(ora1 And (dra1 Xor &hff)) Or (PV And dra1)
	        PV=ora1
			Else
	   	  dra1=PV
			End If
		EndIf
		
		If pt=&ha7c1 Then
			orb1=(orb1 And &h80) Or (pv And &h7f)
			pv=orb1
		EndIf
		
		If pt=&ha7c2 Then
			cra1=(cra1 And &hd0) Or (pv And &h7f)
			pv=cra1
		EndIf
		
		If pt=&ha7c3 Then
			crb1=(crb1 And &hd0) Or (pv And &h7f)
			pv=crb1
		EndIf
	
	End If
	
   	
	If PT>&hafff Then Exit Sub ' ROM no escribible en un Thomson Mo5
	RAM(PT)=PV 
End Sub

Function peekb(PT As integer) As Integer	
	PV = RAM(PT) 

	' para el Thomson Mo5, emulamos los dos bancos de video
	' ambos de &h2000 bytes (8000 bytes), uno para el color y otro para el pixel
	' sobran 192bytes por banco, que se pueden usar en basic ;-)
	If (PT<&h2000) Then 
		 Return RAM(PT+BancoVideo) And &hff
	EndIf
   
   
 If PT And &hA7C0 Then  
 	
	   ' Output Register B (ORB) salida de datos de la PIA1, para el teclado
	   If PT=&ha7c1 Then
	       If Teclas(orb1 And &h7e) Then
	          orb1=orb1 And &h7f        
	          Return orb1
	       Else
	          orb1=orb1 Or &h80
	          Return orb1
	       EndIf
	   EndIf
	   
	   ' Control Register A (CRA) de la PIA1, cambiamos su estado cada vez que se lee
	   If pt=&ha7c2 Then
			cra1=&hd0 Or (pv And &h7f) 
			pv=cra1
	   EndIf      
	   ' Control Register B (CRB) de la PIA1, cambiamos su estado cada vez que se lee
	   If pt=&ha7c3 Then
			crb1=&hd0 Or (pv And &h7f)
			pv=crb1
	   EndIf
	   
	   ' miramos el mando de juegos
	   If pt=&ha7cc then
	   		pv=0
				If MultiKey(SC_UP)    Then pv+=&H01 '&hFE
				If MultiKey(SC_DOWN)  Then pv+=&H02 '&hFD
				If MultiKey(SC_LEFT)  Then pv+=&H04 '&hFB
				If MultiKey(SC_RIGHT) Then pv+=&H08 '&hF7
				pv=pv Xor 255 ' guardamos directamente en RAM, en lugar de usar ORA en PIA2
	   End If
	   
	   ' y el boton de disparo
	   If pt=&ha7cd Then			
				pv=0
				if Multikey(SC_CONTROL) Then pv=pv or &H40 '&hBF
				pv=pv Xor 255 ' guardamos directamente en RAM, en lugar de usar ORB en PIA2
	   End If
	   
 End If
 
 
	Return PV
End Function




'*******************************************
' cogemos o ponemos dos bytes (word)
Sub pokew(PT As integer, PV As Integer) 
	pokeb(PT  ,(PV Shr 8) )
	pokeb(PT+1, PV And &hff)
End Sub

Function peekw(PT As integer) As Integer
	PV = peekb(PT+1) Or ( peekb(PT) Shl 8 )
	Return PV
End Function
'*******************************************




'*******************************************
' coge un byte o palabra segun el modo de direccionamiento
Function peekxb() As Integer 
	Return peekb(get_modob())
End Function

Function peekxw() As Integer 
   Return peekw(get_modow())
End Function
'*******************************************





'*******************************************
' coge un byte o palabra e incrementa PC
Function get_byte() As Integer
  PV = peekb(PC)
  PC += 1
  Return PV And &hff
end Function

function get_word() As Integer
  PV = peekw(PC)
  PC += 2
  Return PV And &hffff
end Function
'******************************************





' rutinas de obtencion de datos en 8 o 16bits
function get_rd() As Integer    
	PR = ((ra And &hff) shl 8) or (rb And &hff)
	Return PR 'And &hffff
End Function

sub set_rd(vt As Integer) 
	ra = (vt shr 8) And &hff
	rb =  vt And &hff
End Sub

Function nib5(PV As integer) As Integer
	If (PV and &h10) Then nib5 = (PV or &hffe0) Else nib5 = (PV and &h000f)
End Function

Function get_CC() As Integer
  PV=(ccc or (ccv shl 1) or (ccz shl 2) or (ccn Shl 3) _ 
                             Or(cci shl 4) or (cch shl 5) or (ccf Shl 6) or (cce Shl 7))   
  Return PV And &hff            
end function

Sub set_CC(PV As Integer)

  ccc = cogebit(PV, &h01)
  ccv = cogebit(PV, &h02)
  ccz = cogebit(PV, &h04)
  ccn = cogebit(PV, &h08)
  cci = cogebit(PV, &h10)
  cch = cogebit(PV, &h20)
  ccf = cogebit(PV, &h40)
  cce = cogebit(PV, &h80)

End Sub




' ****************************************************************
'                        rutinas PUSH y PULL 
' ****************************************************************

Sub Push(d1 As integer, d2 As integer, PR As Integer)
	
	' nota: el orden aqui es importante: no alteralo, ya que se almacena segun va (como en FIFO)
	If (PR And &h80) Then d1 -= 2 : pokew(d1, PC     ) : cicloscpu += 2
	If (PR And &h40) Then d1 -= 2 : pokew(d1, d2     ) : cicloscpu += 2 ' U o S segun sea PSHS o PSHU	
	if (PR And &h20) Then d1 -= 2 : pokew(d1, ry     ) : cicloscpu += 2
	if (PR And &h10) Then d1 -= 2 : pokew(d1, rx     ) : cicloscpu += 2
	
	if (PR And &h08) Then d1 -= 1 : pokeb(d1, rDP    ) : cicloscpu += 1	
	If (PR and &h04) Then d1 -= 1 : pokeb(d1, rb     ) : cicloscpu += 1	
	If (PR and &h02) Then d1 -= 1 : pokeb(d1, ra     ) : cicloscpu += 1	
   If (PR and &h01) Then d1 -= 1 : pokeb(d1, get_CC()): cicloscpu += 1
    
   d1temp=d1 ' devolvemos el estado final de la pila (Bien sea U o S)
   'd2temp=d2 ' y el valor de U o S segun se lo pida D2 (no se altera, por lo que lo anulo por ahora)
    
End Sub

Sub Pull(d1 As integer, d2 As integer, PR As Integer)
' en realidad, la variable D2 no sirve de nada como dato de entrada
' ya que, la leemos aqui, y la devolvemos en d2temp
' pero queda mas claro y mas real asi construido
' vamos, que queda igual a PUSH y queda mas "vistoso"

	' nota: el orden aqui es importante: no alteralo, ya que se recupera segun va
	if (PR And &h01) Then set_CC(peekb(d1)): d1 += 1 : cicloscpu += 1
	if (PR And &h02) Then ra   = peekb(d1) : d1 += 1 : cicloscpu += 1
	if (PR and &h04) Then rb   = peekb(d1) : d1 += 1 : cicloscpu += 1
	if (PR And &h08) Then rDP  = peekb(d1) : d1 += 1 : cicloscpu += 1
	
	if (PR And &h10) Then rx   = peekw(d1) : d1 += 2 : cicloscpu += 2
	if (PR And &h20) Then ry   = peekw(d1) : d1 += 2 : cicloscpu += 2
	if (PR And &h40) Then d2   = peekw(d1) : d1 += 2 : cicloscpu += 2  ' U o S segun sea PSHS o PSHU
	if (PR And &h80) Then PC   = peekw(d1) : d1 += 2 : cicloscpu += 2
	
   d1temp=d1 ' devolvemos el estado final de la pila (Bien sea U o S)
   d2temp=d2 ' y el valor de U o S segun se lo pida D2

end Sub
