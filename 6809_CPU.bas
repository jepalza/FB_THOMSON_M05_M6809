' emulador 6809:
'  registros A,B,DP como 8bits (y suma en D de A*256+B)
'  registros X,Y,U,S como 16bits
'  PC para direccion en curso
'  estados: E-F-H-I-N-Z-V-C (registro CC)
' 
' direcciones ROM de inicio e interrupciones:
'  FFF0-1 -> Reserved by Motorola ...  :o            
'  FFF2-3 -> Instruction interrupt vector (SWI3) 
'  FFF4-5 -> Instruction interrupt vector (SWI2) 
'  FFF6-7 -> Fast hardware int. vector    (FIRQ)   
'  FFF8-9 -> Hardware interrupt vector    (IRQ)    
'  FFFA-B -> Onstruction interrupt vector (SWI)  
'  FFFC-D -> Non-maskable interrupt vector(NMI)
'  FFFE-F -> Reset vector, start program  (RST)  


#Include "6809_VAR.BAS" ' variables y declaraciones
#Include "6809_TMM.BAS" ' ciclos de ejecucion, modos de memoria y nombres de instrucciones
#Include "6809_MEM.BAS" ' operaciones de memoria
#Include "6809_BIT.BAS" ' operaciones de bits
#Include "6809_DIR.BAS" ' modos de direccionamiento
#Include "6809_INS.BAS" ' instrucciones generales




Function m6809_execute() As Integer


  vd = get_byte() ' cogemos la instruccion (e incrementamos PC en +1)
 
  cicloscpu = opcycles(vd) ' cogemos los ciclos empleados
  addrmode  = addrmod(vd)  ' cogemos el modo de direccionamiento
 
   m6809_RunINS(vd) 
   
  return cicloscpu

end Function


' funciones de reset, interrupciones y testeo de BIT's
sub m6809_reset()
	
  ra = 0
  rb = 0
  rDP = 0
  	
  rx = 0
  ry = 0
  ru = 0
  rs = 0
  
  set_CC(0)
  
  ' estado de interrupciones IRQ y FIRQ deshabilitados
  ccf = 1
  cci = 1
  
  PC = peekw(&hfffe) ' rom

End Sub


sub m6809_firq()

  if ccf=0 Then 
  	 cce = 0
    Push(rs, ru, &h81)
    rs=d1temp
    cci = 1
    ccf = 1
    PC = peekw(&hfff6) ' rom
    cicloscpu = 12
  End If
  
End Sub
  
sub m6809_irq()

  if cci=0 Then 
  	 cce = 1
    Push(rs, ru, &hff)
    rs=d1temp
    cci = 1
    PC = peekw(&hfff8) 'rom
    cicloscpu = 21
  End If
  
End Sub

sub m6809_NMI()

  	 cce = 1
    Push(rs, ru, &h81)
    rs=d1temp
    cci = 1
    ccf = 1
    PC = peekw(&hfffc) 'rom
    cicloscpu = 21
  
End Sub

Sub m6809_RunINS(vr As Integer)
	
 Select Case vr
  Case 1
 	 Cintas()	' saltamos al lector de cintas, al trampear la rom del Mo5
  Case 0,96,112
    neg ()
  Case 3,99,115
    com ()
  Case 4,100,116
    lsr ()
  Case 6,102,118
    ror ()
  Case 7,103,119
    asr ()
  Case 8,104,120
    asl ()
  Case 9,105,121
    rol ()
  Case 10,106,122
    dec ()
  Case 12,108,124
    inc ()
  Case 13,109,125
    tst ()
  Case 14,110,126
    jmp ()
  Case 15,111,127
    clr ()
  Case 16
    grupo2()
  Case 17
    grupo3()
  Case 18
    nop ()
  Case 19
    syn ()
  Case 22
    lbra()
  Case 23
    lbsr()
  Case 25
    daa ()
  Case 26
    orcc()
  Case 28
    andc()
  Case 29
    sex ()
  Case 30
    exg ()
  Case 31
    tfr ()
  Case 32
    bra ()
  Case 33
    brn ()
  Case 34
    bhi ()
  Case 35
    bls ()
  Case 36
    bcc ()
  Case 37
    bcs ()
  Case 38
    bne ()
  Case 39
    beq ()
  Case 40
    bvc ()
  Case 41
    bvs ()
  Case 42
    bpl ()
  Case 43
    bmi ()
  Case 44
    bge ()
  Case 45
    blt ()
  Case 46
    bgt ()
  Case 47
    ble ()
  Case 48
    leax()
  Case 49
    leay()
  Case 50
    leas()
  Case 51
    leau()
  Case 52
    pshs()
  Case 53
    puls()
  Case 54
    pshu()
  Case 55
    pulu()
  Case 57
    rts ()
  Case 58
    abx ()
  Case 59
    rti ()
  Case 60
    cwai()
  Case 61
    mul ()
  Case 63
    swi ()
  Case 64
    nega()
  Case 67
    coma()
  Case 68
    lsra()
  Case 70
    rora()
  Case 71
    asra()
  Case 72
    asla()
  Case 73
    rola()
  Case 74
    deca()
  Case 76
    inca()
  Case 77
    tsta()
  Case 79
    clra()
  Case 80
    negb()
  Case 83
    comb()
  Case 84
    lsrb()
  Case 86
    rorb()
  Case 87
    asrb()
  Case 88
    aslb()
  Case 89
    rolb()
  Case 90
    decb()
  Case 92
    incb()
  Case 93
    tstb()
  Case 95
    clrb()
  Case 128,144,160,176
    suba()
  Case 129,145,161,177
    cmpa()
  Case 130,146,162,178
    sbca()
  Case 131,147,163,179
    subd()
  Case 132,148,164,180
    anda()
  Case 133,149,165,181
    bita()
  Case 134,150,166,182
    lda ()
  Case 136,152,168,184
    eora()
  Case 137,153,169,185
    adca()
  Case 138,154,170,186
    ora ()
  Case 139,155,171,187
    adda()
  Case 140,156,172,188
    cmpx()
  Case 141
    bsr ()
  Case 142,158,174,190
    ldx ()
  Case 151,167,183
    sta ()
  Case 157,173,189
    jsr ()
  Case 159,175,191
    stx ()
  Case 192,208,224,240
    subb()
  Case 193,209,225,241
    cmpb()
  Case 194,210,226,242
    sbcb()
  Case 195,211,227,243
    addd()
  Case 196,212,228,244
    andb()
  Case 197,213,229,245
    bitb()
  Case 198,214,230,246
    ldb ()
  Case 200,216,232,248
    eorb()
  Case 201,217,233,249
    adcb()
  Case 202,218,234,250
    orb ()
  Case 203,219,235,251
    addb()
  Case 204,220,236,252
    ldd ()
  Case 206,222,238,254
    ldu ()
  Case 215,231,247
    stb ()
  Case 221,237,253
    std ()
  Case 223,239,255
    stu ()
  Case 289
    lbrn()
  Case 290
    lbhi()
  Case 291
    lbls()
  Case 292
    lbcc()
  Case 293
    lbcs()
  Case 294
    lbne()
  Case 295
    lbeq()
  Case 296
    lbvc()
  Case 297
    lbvs()
  Case 298
    lbpl()
  Case 299
    lbmi()
  Case 300
    lbge()
  Case 301
    lblt()
  Case 302
    lbgt()
  Case 303
    lble()
  Case 319
    swi2()
  Case 387,403,419,435
    cmpd()
  Case 396,412,428,444
    cmpy()
  Case 398,414,430,446
    ldy ()
  Case 415,431,447
    sty ()
  Case 462,478,494,510
    lds ()
  Case 479,495,511
    sts ()
  Case 575
    swi3()
  Case 643,659,675,684,691,700
    cmpu()
  Case 652,668
    cmps()
  Case else
    nulo()
 End Select
 
End Sub

