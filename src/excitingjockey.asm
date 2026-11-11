; ==========================================================================
; EXCITING JOCKEY - Casio - MSX1 (1984) - ROM de 16 KB en 0x8000
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x08000


; ----------------------------------------------------------------------
; DATOS cabecera: "AB", INIT (0x8010) y el resto de la cabecera a cero
;   0x8000..0x8010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 8000
	defw 08010h,00000h,00000h,00000h,00000h,00000h,00000h	; 8002

; ======================================================================
; CODIGO 0x8010..0x8053  (67 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; INIT: la interrupcion en H.TIMI, SCREEN 2, el sonido callado y el bucle.
; ----------------------------------------------------------------------
init:		; El arranque
	di			;8010
	ld sp,0f300h		;8011   ; la pila, por debajo de la zona de trabajo de la BIOS
	im 1		;8014
	ld hl,0805bh		;8016   ; la interrupcion (0x805B)...
	ld (0fda0h),hl		;8019   ; ...en H.TIMI...
	ld a,0c3h		;801c   ; ...con su "jp"
	ld (0fd9fh),a		;801e
	ld a,000h		;8021   ; la interrupcion aun no hace nada
	ld (0f300h),a		;8023
	ei			;8026
	call vdp_registros		;8027   ; SCREEN 2: los ocho registros del VDP
	call sonido_calla		;802a   ; el sonido callado
	call estado_inicio		;802d   ; el estado del juego: 1, paso 1 (cargar los dibujos)
	di			;8030
	ld a,0ffh		;8031   ; la interrupcion ya trabaja...
	ld (0f300h),a		;8033
	ld a,000h		;8036   ; ...y no esta ocupada
	ld (0f301h),a		;8038
	ei			;803b
bucle:		; El bucle principal: solo 0xA2F5, todo lo demas va en la interrupcion
	call bucle_uno		;803c
	jp bucle		;803f
vdp_registros:		; Los ocho registros del VDP de 0x8053 (WRTVDP): SCREEN 2, sprites de 16 x 16
	ld hl,08053h		;8042   ; los valores...
	ld bc,00800h		;8045   ; ...ocho, desde el registro 0
L_8048:
	push bc			;8048
	ld b,(hl)			;8049
	call 00047h		;804a   ; WRTVDP
	pop bc			;804d
	inc hl			;804e
	inc c			;804f
	djnz L_8048		;8050
	ret			;8052

; ----------------------------------------------------------------------
; DATOS registros_vdp: SCREEN 2 (0x02, 0xA2), nombres en 0x1800, colores en
;   0x2000, patrones en 0x0000, sprites en 0x1B00 y 0x3800, borde negro
;   0x8053..0x805b  (8 bytes)
DATA_registros_vdp:
	defb 002h,0a2h,006h,0ffh,003h,036h,007h,001h	; 8053  .....6..

; ======================================================================
; CODIGO 0x805b..0x8308  (685 bytes)
; ======================================================================


interrupcion:		; La interrupcion (H.TIMI): un cuadro del juego, si el anterior ha acabado
	ld a,(0f300h)		;805b   ; ya trabaja?
	and a			;805e
	ret z			;805f
	ld a,(0f301h)		;8060   ; ocupada con el cuadro anterior?
	and a			;8063
	jp nz,interrupcion_tarde		;8064
	ld a,0ffh		;8067   ; ocupada
	ld (0f301h),a		;8069
	call cuadro		;806c   ; los sprites y la maquina de estados
	call carrera_cuadro		;806f   ; la carrera
	call sonido_cuadro		;8072   ; el sonido
	ld a,000h		;8075   ; libre
	ld (0f301h),a		;8077
	ret			;807a
interrupcion_tarde:		; El cuadro anterior no ha acabado: solo cuenta
	ld hl,(0f302h)		;807b   ; los cuadros perdidos (0xF302)
	inc hl			;807e
	ld (0f302h),hl		;807f
	ret			;8082
salta_tabla:		; Salta por la tabla de palabras que va detras del "call": A = 1, 2...; con A = 0 vuelve de quien llama
	ex (sp),hl			;8083   ; HL = la tabla (la vuelta del "call")
	push bc			;8084
	push hl			;8085
	ld hl,salta_tabla_va		;8086   ; la vuelta pasa a ser 0x8092
	ex (sp),hl			;8089
	ld c,a			;808a   ; C = A - 1
	dec c			;808b
	and a			;808c   ; A = 0?...
	ret nz			;808d
	pop bc			;808e   ; ...vuelve de quien ha llamado
	pop bc			;808f
	pop hl			;8090
	ret			;8091
salta_tabla_va:		; La palabra C de la tabla y salta alli
	ld b,000h		;8092
	sla c		;8094   ; C x 2
	add hl,bc			;8096
	ld a,(hl)			;8097   ; la direccion...
	inc hl			;8098
	ld h,(hl)			;8099
	ld l,a			;809a
	pop bc			;809b
	ex (sp),hl			;809c   ; ...en la pila: el "ret" salta
	ret			;809d
llena:		; Llena B bytes desde HL con A (B = 0: 256)
	ld (hl),a			;809e
	inc hl			;809f
	djnz llena		;80a0
	ret			;80a2
suma_paso:		; HL+1 += (HL) & 0x3F; devuelve en A el acarreo de los 6 bits (cuantas veces se pasa de 64)
	push hl			;80a3   ; lo de quien llama
	push de			;80a4
	push bc			;80a5
	push hl			;80a6   ; DE = HL + 1
	pop de			;80a7
	inc de			;80a8
	ld l,(hl)			;80a9   ; el paso...
	ld h,000h		;80aa   ; HL = el paso
	ld a,(de)			;80ac   ; ...mas los 6 bits bajos de la cuenta
	and 03fh		;80ad   ; los 6 bits bajos de la cuenta
	ld c,a			;80af
	ld b,h			;80b0
	add hl,bc			;80b1   ; la suma
	ld a,l			;80b2   ; la cuenta nueva
	ld (de),a			;80b3   ; a la cuenta
	add hl,hl			;80b4   ; los bits que pasan de 64...
	add hl,hl			;80b5   ; x 4: lo que pasa de 64, en H
	ld a,h			;80b6   ; ...en A
	pop bc			;80b7   ; lo de quien llama
	pop de			;80b8
	pop hl			;80b9
	ret			;80ba
tabla_umbral:		; A contra los cuatro umbrales de HL: el byte HL+3+n del primero que A no alcanza
	push bc			;80bb
	push hl			;80bc
	ld b,004h		;80bd   ; cuatro umbrales
	ld c,003h		;80bf   ; el resultado empieza en +3
L_80C1:
	cp (hl)			;80c1   ; menor que este?
	jr c,tabla_umbral_lee		;80c2
	inc c			;80c4   ; el siguiente
	inc hl			;80c5
	djnz L_80C1		;80c6
tabla_umbral_lee:		; Lee el byte
	ld b,000h		;80c8   ; BC = C
	pop hl			;80ca
	push hl			;80cb
	add hl,bc			;80cc   ; el byte HL + C
	ld a,(hl)			;80cd
	pop hl			;80ce
	pop bc			;80cf
	ret			;80d0
llena_filas:		; B grupos de 8 bytes desde HL con C (los colores de las casillas)
	ld a,008h		;80d1
llena_filas_uno:		; Un byte
	ld (hl),c			;80d3
	inc hl			;80d4   ; el siguiente
	dec a			;80d5
	jr nz,llena_filas_uno		;80d6   ; los 8
	djnz llena_filas		;80d8   ; los B grupos
	ret			;80da
pieza:		; Pone la pieza DE en el canal B y la hace sonar
	call canal		;80db
	ld (hl),e			;80de   ; el principio de la pieza
	inc hl			;80df
	ld (hl),d			;80e0
	inc hl			;80e1
	ld (hl),001h		;80e2   ; suena
	ret			;80e4
canal:		; HL = el canal B (0xF002 + B x 0x20), y lo deja en su estado inicial (0x8320)
	push bc			;80e5   ; lo de quien llama
	push de			;80e6
	ld hl,0f002h		;80e7   ; los canales desde 0xF002...
	ld a,b			;80ea   ; ...de 32 en 32 bytes
	rrca			;80eb   ; B x 32 (tres rrca)
	rrca			;80ec
	rrca			;80ed   ; B por 32
	ld e,a			;80ee   ; en DE
	ld d,000h		;80ef
	add hl,de			;80f1   ; el canal
	push hl			;80f2   ; HL, el canal...
	inc hl			;80f3   ; ...y desde +2...
	inc hl			;80f4   ; desde +2
	ex de,hl			;80f5
	ld hl,08320h		;80f6   ; ...30 bytes de 0x8320
	ld bc,0001eh		;80f9   ; 30 bytes
	ldir		;80fc
	pop hl			;80fe
	pop de			;80ff
	pop bc			;8100
	ret			;8101
sonido_calla:		; Calla el sonido: los tres canales a cero, el PSG sin ruido y los volumenes a 0
	xor a			;8102
	ld (0f000h),a		;8103   ; sin transporte
	ld b,a			;8106   ; el canal 0...
	call canal		;8107
	inc b			;810a
	call canal		;810b
	inc b			;810e
	call canal		;810f
	ld a,007h		;8112   ; el registro 7 del PSG (RDPSG)...
	call 00096h		;8114
	and 0c0h		;8117   ; ...los dos bits de los puertos se quedan...
	or 038h		;8119   ; ...los tonos apagados (0x38)...
	ld e,a			;811b
	ld a,007h		;811c
	call 00093h		;811e   ; ...WRTPSG
	xor a			;8121   ; los tres canales, callados
	ld (0f004h),a		;8122
	ld (0f024h),a		;8125
	ld (0f044h),a		;8128
	ld b,002h		;812b   ; tres volumenes
sonido_calla_vol:		; Un volumen a 0
	call canal_calla		;812d
	djnz sonido_calla_vol		;8130
canal_calla:		; El volumen del canal B a 0...
	xor a			;8132
volumen:		; ...y el volumen E en el registro 8 + B del PSG
	ld e,a			;8133
	ld a,008h		;8134   ; el registro de volumen del canal
	add a,b			;8136
	jp 00093h		;8137
sonido_cuadro:		; Un cuadro del motor: los tres canales, del 2 al 0
	ld b,002h		;813a
	ld ix,0f002h		;813c   ; empieza por el 2
sonido_cuadro_uno:		; Un canal
	call canal_cuadro		;8140
	ld de,00020h		;8143   ; el canal siguiente
	add ix,de		;8146
	ld a,(0f001h)		;8148   ; el numero de canal...
	ld b,a			;814b
	djnz sonido_cuadro_uno		;814c   ; ...uno menos
canal_cuadro:		; Un cuadro de un canal: el tempo, la nota y la envolvente
	ld a,b			;814e
	ld (0f001h),a		;814f   ; el canal en curso
	ld a,(ix+002h)		;8152   ; suena?
	and a			;8155
	ret z			;8156
	dec (ix+00eh)		;8157   ; el tempo: cada tantos cuadros...
	ret nz			;815a   ; ...aun no
	ld a,(ix+00dh)		;815b   ; el tempo...
	ld (ix+00eh),a		;815e   ; ...vuelve a su cuenta
	dec (ix+007h)		;8161   ; ...la nota acaba?...
	jr z,pieza_sigue		;8164
	dec (ix+006h)		;8166   ; ...se acaba lo que suena?
	jr z,canal_calla		;8169
	jp p,envolvente		;816b   ; a cero, no menos
	ld (ix+006h),000h		;816e
	ret			;8172
envolvente:		; La envolvente: el paso que toca segun lo que le queda a la nota, y su volumen de la tabla del canal
	ld a,(ix+00bh)		;8173
	cp 010h		;8176   ; acabada?
	ret z			;8178
	ld e,000h		;8179   ; lo que le queda...
	ld h,e			;817b
	ld l,(ix+006h)		;817c   ; ...por 16...
	add hl,hl			;817f
	add hl,hl			;8180
	add hl,hl			;8181
	add hl,hl			;8182
	ld d,(ix+005h)		;8183   ; ...entre la duracion
	ld c,b			;8186
	xor a			;8187
	ld b,008h		;8188   ; ocho bits
envolvente_div:		; La division, bit a bit
	push hl			;818a
	srl d		;818b   ; el divisor...
	rr e		;818d
	and a			;818f
	sbc hl,de		;8190   ; ...cabe?
	ccf			;8192
	jr nc,envolvente_bit		;8193
	ex (sp),hl			;8195
envolvente_bit:		; Un bit del cociente
	rla			;8196
	pop hl			;8197
	djnz envolvente_div		;8198
	ld b,c			;819a
	ld c,a			;819b
	ld a,010h		;819c   ; 16 menos el cociente: el paso de la envolvente
	sub c			;819e
envolvente_paso:		; El paso: el volumen esta en la mitad alta o baja del byte de la tabla
	ld (ix+00bh),a		;819f
	cp 010h		;81a2   ; 16: la envolvente se ha acabado
	ret z			;81a4
	srl a		;81a5   ; el paso entre 2: el byte...
	push af			;81a7   ; el paso par o impar
	ld e,a			;81a8
	ld d,000h		;81a9
	ld l,(ix+009h)		;81ab   ; ...de la envolvente
	ld h,(ix+00ah)		;81ae   ; la envolvente del canal
	add hl,de			;81b1
	pop af			;81b2
	ld a,(hl)			;81b3   ; el byte...
	jr c,envolvente_volumen		;81b4   ; impar: la mitad baja
	rrca			;81b6   ; ...su mitad alta o baja
	rrca			;81b7
	rrca			;81b8
	rrca			;81b9
envolvente_volumen:		; El volumen del paso por el volumen del canal, entre 16
	and 00fh		;81ba
	inc a			;81bc   ; el volumen de la envolvente...
	ld e,a			;81bd
	ld d,(ix+008h)		;81be   ; ...por el del canal
	xor a			;81c1
	ld c,008h		;81c2   ; ocho bits
envolvente_mult:		; La multiplicacion, bit a bit
	add a,a			;81c4
	rl e		;81c5
	jr nc,envolvente_mult_sig		;81c7
	add a,d			;81c9
envolvente_mult_sig:		; El bit siguiente
	dec c			;81ca
	jr nz,envolvente_mult		;81cb
	rrca			;81cd   ; entre 16
	rrca			;81ce
	rrca			;81cf
	rrca			;81d0
	and 00fh		;81d1
	jp volumen		;81d3
pieza_sigue:		; Los tres bytes siguientes de la pieza: una nota o una orden (0xF4 a 0xFF)
	call pieza_lee		;81d6
	and a			;81d9   ; una orden?
	jp p,nota_pon		;81da
	cpl			;81dd   ; 0xFF - A...
	add a,a			;81de   ; ...por 2...
	push de			;81df
	ld e,a			;81e0
	ld d,000h		;81e1
	ld hl,08308h		;81e3   ; ...en la tabla de ordenes 0x8308
	add hl,de			;81e6
	pop de			;81e7
	push hl			;81e8   ; la vuelta: otra vez aqui, a por los tres bytes siguientes
	ld hl,pieza_sigue		;81e9
	ex (sp),hl			;81ec
	ld a,(hl)			;81ed   ; la rutina
	inc hl			;81ee
	ld h,(hl)			;81ef
	ld l,a			;81f0
	jp (hl)			;81f1   ; a la orden
nota_pon:		; Una nota: A el numero, E la duracion, D hasta la siguiente; duracion 0 es un silencio
	ld (ix+005h),e		;81f2   ; la duracion...
	ld (ix+006h),e		;81f5   ; ...lo que le queda...
	ld (ix+007h),d		;81f8   ; ...y hasta la siguiente
	inc e			;81fb   ; duracion 0: silencio
	dec e			;81fc
	jp z,canal_calla		;81fd
	ld d,a			;8200
	ld a,(0f000h)		;8201   ; mas el transporte
	add a,d			;8204   ; ...mas la nota
	ld c,000h		;8205   ; la octava
nota_octava:		; La octava: de 12 en 12
	cp 00ch		;8207   ; de 12 en 12...
	jr c,nota_periodo		;8209
	sub 00ch		;820b
	inc c			;820d
	jr nota_octava		;820e   ; ...una octava mas
nota_periodo:		; El periodo de la nota (0x8330), partido por 2 por cada octava
	add a,a			;8210
	ld e,a			;8211   ; la nota de la tabla...
	ld d,000h		;8212
	ld hl,08330h		;8214   ; ...0x8330
	add hl,de			;8217
	ld e,(hl)			;8218
	inc hl			;8219
	ld d,(hl)			;821a
	ld a,c			;821b   ; las octavas de mas...
	and a			;821c
	jr z,nota_escribe		;821d
nota_octava_baja:		; Una octava mas arriba
	srl d		;821f   ; ...el periodo a la mitad
	rr e		;8221
	dec a			;8223
	jr nz,nota_octava_baja		;8224
nota_escribe:		; El periodo en los registros 2B y 2B+1 del PSG
	ld a,b			;8226   ; el registro 2B...
	add a,b			;8227
	call 00093h		;8228   ; ...la parte baja...
	ld e,d			;822b
	inc a			;822c
	call 00093h		;822d   ; ...y la alta
nota_envolvente:		; Si la envolvente es de las de tabla, desde el paso 0
	ld a,(ix+00ch)		;8230   ; la envolvente es de tabla?
	cp 010h		;8233
	ret c			;8235
	xor a			;8236   ; desde el paso 0
	jp envolvente_paso		;8237
orden_fin:		; Orden 0xFF: la pieza se acaba y el canal calla
	xor a			;823a
	ld (ix+002h),a		;823b   ; el canal ya no suena
	pop hl			;823e   ; fuera la vuelta a por mas
	jp canal_calla		;823f
orden_repite:		; Orden 0xFC: vuelve a la marca si faltan repeticiones
	dec (ix+011h)		;8242   ; una repeticion menos...
	ret z			;8245   ; ...si es la ultima, sigue
orden_vuelve:		; Orden 0xFD: vuelve a la marca
	ld e,(ix+00fh)		;8246   ; la marca...
	ld d,(ix+010h)		;8249
orden_salta:		; Orden 0xF4: salta a DE
	ld (ix+003h),e		;824c   ; ...por donde va
	ld (ix+004h),d		;824f
orden_nada:		; Orden 0xFE: nada
	ret			;8252
orden_marca:		; Orden 0xFB: la marca de la repeticion y cuantas veces
	ld (ix+011h),d		;8253   ; cuantas veces...
	ld e,(ix+003h)		;8256   ; ...y la marca es por donde va
	ld d,(ix+004h)		;8259
	ld (ix+00fh),e		;825c
	ld (ix+010h),d		;825f
	ret			;8262
orden_volumen:		; Orden 0xFA: el volumen del canal
	ld a,d			;8263   ; el volumen, de 0 a 15
	and 00fh		;8264
	ld (ix+008h),a		;8266
	ret			;8269
envolvente_psg:		; La envolvente del PSG: volumen 16 y los registros 11-13
	ld a,010h		;826a   ; el volumen 16: la envolvente del PSG
	ld (ix+00bh),a		;826c
	call volumen		;826f   ; en el registro de volumen
	ld e,d			;8272
	ld a,00dh		;8273   ; la forma en el registro 13
	call 00093h		;8275
	call pieza_lee		;8278   ; los tres bytes siguientes de la pieza...
	ld a,00bh		;827b   ; ...el periodo en los registros 11...
	call 00093h		;827d
	inc a			;8280
	ld e,d			;8281   ; ...y 12
	jp 00093h		;8282
orden_envolvente:		; Orden 0xF9: el tipo de envolvente: del PSG o de la tabla 0x8348
	ld (ix+00ch),d		;8285   ; el tipo de envolvente...
	bit 4,d		;8288   ; ...bit 4: de tabla
	jr z,envolvente_psg		;828a
	ld a,d			;828c   ; la tabla: 8 bytes por envolvente...
	and 00fh		;828d
	add a,a			;828f
	add a,a			;8290
	add a,a			;8291
	ld e,a			;8292
	ld d,000h		;8293
	ld hl,08348h		;8295
	add hl,de			;8298
	ld (ix+009h),l		;8299   ; ...la del canal
	ld (ix+00ah),h		;829c
	ret			;829f
orden_tempo:		; Orden 0xF8: el tempo del canal (cuadros por paso)
	ld (ix+00dh),d		;82a0
	ret			;82a3
orden_transporte:		; Orden 0xF7: el transporte, para los tres canales
	ld a,d			;82a4
	ld (0f000h),a		;82a5
	ret			;82a8
orden_mezcla:		; Orden 0xF6: tono y ruido del canal en el registro 7
	ld a,d			;82a9   ; los bits de tono y ruido del canal...
	and 009h		;82aa
	ld l,a			;82ac
	ld h,009h		;82ad   ; ...la mascara
	ld a,b			;82af
	and a			;82b0
	jr z,orden_mezcla_pon		;82b1
orden_mezcla_bit:		; Los bits del canal
	add hl,hl			;82b3   ; corridos al canal
	dec a			;82b4
	jr nz,orden_mezcla_bit		;82b5
orden_mezcla_pon:		; Los escribe
	ld a,007h		;82b7   ; RDPSG 7
	call 00096h		;82b9
	ld c,a			;82bc
	ld a,h			;82bd   ; fuera los del canal...
	cpl			;82be
	and c			;82bf
	or l			;82c0   ; ...y los nuevos
	and 03fh		;82c1
	or 080h		;82c3   ; los puertos de E/S como estaban
	ld e,a			;82c5
	ld a,007h		;82c6   ; WRTPSG 7
	jp 00093h		;82c8
orden_ruido:		; Orden 0xF5: el periodo del ruido y una nota de ruido
	pop af			;82cb   ; fuera la vuelta...
	push de			;82cc
	call pieza_lee		;82cd   ; ...y los tres bytes siguientes
	pop af			;82d0
	ld (ix+005h),e		;82d1   ; la duracion...
	ld (ix+006h),e		;82d4
	ld (ix+007h),d		;82d7   ; ...y hasta la siguiente
	inc e			;82da
	dec e			;82db
	jp z,canal_calla		;82dc   ; 0: silencio
	ld e,a			;82df
	ld a,006h		;82e0   ; el periodo del ruido en el registro 6
	call 00093h		;82e2
	jp nota_envolvente		;82e5
pieza_lee:		; Los tres bytes siguientes de la pieza: A, E, D
	ld l,(ix+000h)		;82e8   ; el principio de la pieza...
	ld h,(ix+001h)		;82eb
	ld e,(ix+003h)		;82ee   ; ...mas por donde va
	ld d,(ix+004h)		;82f1
	add hl,de			;82f4
	inc de			;82f5   ; tres mas
	inc de			;82f6
	inc de			;82f7
	ld (ix+003h),e		;82f8
	ld (ix+004h),d		;82fb
	ld a,(0f001h)		;82fe   ; el canal...
	ld b,a			;8301
	ld a,(hl)			;8302   ; A, E y D
	inc hl			;8303
	ld e,(hl)			;8304
	inc hl			;8305
	ld d,(hl)			;8306
	ret			;8307

; ----------------------------------------------------------------------
; DATOS ordenes: Las doce ordenes del motor, de la 0xFF a la 0xF4
;   0x8308..0x8320  (24 bytes)
DATA_ordenes:
	defw 0823ah,08252h	; 8308  -> orden_fin orden_nada
	defw 08246h,08242h	; 830c  -> orden_vuelve orden_repite
	defw 08253h,08263h	; 8310  -> orden_marca orden_volumen
	defw 08285h,082a0h	; 8314  -> orden_envolvente orden_tempo
	defw 082a4h,082a9h	; 8318  -> orden_transporte orden_mezcla
	defw 082cbh,0824ch	; 831c  -> orden_ruido orden_salta

; ----------------------------------------------------------------------
; DATOS canal_inicio: El estado inicial de un canal (desde +2): suena, la
;   duracion, el volumen 15, la envolvente 0x8348...; la copia de 30 bytes
;   sigue por la tabla de los periodos
;   0x8320..0x8330  (16 bytes)
DATA_canal_inicio:
	defb 000h,000h,000h,001h,001h,001h,00fh,048h,083h,010h,010h,001h,001h,000h,000h,001h	; 8320  .......H........

; ----------------------------------------------------------------------
; DATOS periodos: Los periodos de las doce notas de la octava mas baja (do a
;   si)
;   0x8330..0x8348  (24 bytes)
DATA_periodos:
	defw 00d5ch,00c9dh,00be7h,00b3ch,00a9bh,00a02h,00973h,008ebh,0086bh,007f2h,00780h,00714h	; 8330

; ----------------------------------------------------------------------
; DATOS envolventes: Las ocho envolventes de tabla: 16 pasos de 4 bits (8
;   bytes cada una)
;   0x8348..0x8388  (64 bytes)
DATA_envolventes:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 8348  ........
	defb 0feh,0dch,0bah,098h,076h,054h,032h,010h	; 8350  ....vT2.
	defb 001h,023h,045h,067h,089h,0abh,0cdh,0efh	; 8358  .#Eg....
	defb 0feh,0dch,0bah,098h,089h,0abh,0cdh,0efh	; 8360  ........
	defb 089h,0abh,0cdh,0efh,0feh,0dch,0bah,098h	; 8368  ........
	defb 0fdh,0b9h,075h,031h,0ech,0a8h,064h,020h	; 8370  ..u1..d 
	defb 004h,08ch,0feh,0dch,0bah,098h,076h,054h	; 8378  ......vT
	defb 004h,08ch,0feh,0dch,0bah,0abh,0cdh,0efh	; 8380  ........

; ======================================================================
; CODIGO 0x8388..0x83ec  (100 bytes)
; ======================================================================


estado_inicio:		; El estado 1, paso 1: cargar los dibujos
	ld hl,00101h		;8388
	ld (0e05eh),hl		;838b
	xor a			;838e   ; la pista quieta
	ld (0f0d0h),a		;838f
	ret			;8392
bucle_uno:		; Una vuelta del bucle principal
	call pago		;8393
	ret			;8396
cuadro:		; La parte de la interrupcion que va con la pantalla: los sprites, el estado, la pista y los mandos
	call sprites_gira		;8397
	ld hl,0e180h		;839a   ; la tabla de sprites (26) a la VRAM
	ld de,01b00h		;839d
	ld bc,00068h		;83a0
	call 0005ch		;83a3
	call sprites_gira		;83a6   ; los sprites vuelven a girar
	call estado		;83a9   ; el estado del juego
	call pista		;83ac   ; la pista
	call mandos		;83af   ; los mandos
	ret			;83b2
sprites_gira:		; Los cuatro grupos de tres sprites de los caballos (0xE198) cambian de orden cada cuadro: si coinciden en una linea, parpadean por turnos
	ld hl,0e198h		;83b3   ; el primero...
	ld de,0ef24h		;83b6   ; ...pasa al cuarto
	ld bc,0000ch		;83b9
	ldir		;83bc
	ld de,0ef18h		;83be   ; el segundo al tercero
	ld bc,0000ch		;83c1
	ldir		;83c4
	ld de,0ef0ch		;83c6   ; el tercero al segundo
	ld bc,0000ch		;83c9
	ldir		;83cc
	ld de,0ef00h		;83ce   ; el cuarto al primero
	ld bc,0000ch		;83d1
	ldir		;83d4
	ld hl,0ef00h		;83d6   ; y de vuelta a 0xE198
	ld de,0e198h		;83d9
	ld bc,00030h		;83dc
	ldir		;83df
	ret			;83e1
estado:		; La maquina de estados: 0xE05E (1 los dibujos, 2 la seleccion, 3 el jinete, 4 la apuesta, 5 la demostracion)
	ld ix,0e05eh		;83e2
	ld a,(ix+000h)		;83e6   ; el estado...
	call salta_tabla		;83e9   ; ...por la tabla

; ----------------------------------------------------------------------
; DATOS tabla_estados: Los cinco estados: los dibujos, la seleccion, el
;   jinete, la apuesta y la demostracion
;   0x83ec..0x83f6  (10 bytes)
DATA_tabla_estados:
	defw 083f6h,0864ah,08866h,08a6dh,08d35h	; 83ec

; ======================================================================
; CODIGO 0x83f6..0x851a  (292 bytes)
; ======================================================================


carga_dibujos:		; Estado 1: los dibujos del juego a la VRAM y la pantalla de la seleccion a la RAM
	call 00041h		;83f6   ; la pantalla apagada (DISSCR)
	call sonido_calla		;83f9   ; el sonido callado
	call ram_borra		;83fc   ; la RAM del juego a cero
	call sprites_fuera		;83ff   ; los sprites fuera
	ld hl,0ac1bh		;8402   ; los dibujos de los sprites (0xAC1B, 2 KB)...
	ld de,03800h		;8405   ; ...a 0x3800
	ld bc,00800h		;8408   ; 2 KB a la VRAM (LDIRVM)
	call 0005ch		;840b
	ld hl,0b435h		;840e   ; las casillas: 0xB435...
	ld de,0e800h		;8411   ; a 0xE800...
	ld bc,00400h		;8414
	ldir		;8417   ; ...1 KB
	ld hl,0b835h		;8419   ; ...y 0xB835, 2 KB...
	ld de,0ec00h		;841c   ; a 0xEC00...
	ld bc,00400h		;841f
	ldir		;8422   ; ...1 KB
	ld hl,0e800h		;8424   ; ...a los tres tercios de la tabla de patrones
	ld de,00000h		;8427   ; a la tabla de patrones...
	ld bc,00800h		;842a   ; ...2 KB
	call vram_tres		;842d
	ld hl,0bbf5h		;8430   ; los colores de las casillas: 0xBBF5 (256 bytes)...
	ld de,0e800h		;8433   ; a 0xE800...
	ld bc,00100h		;8436
	ldir		;8439   ; ...256 bytes
	ld hl,085deh		;843b   ; ...y los de la lista 0x85DE...
	call colores_lista		;843e   ; desde 0xE900
	ld hl,0e800h		;8441   ; ...a los tres tercios de la tabla de colores
	ld de,02000h		;8444   ; a la tabla de colores...
	ld bc,00800h		;8447   ; ...2 KB
	call vram_tres		;844a
	ld a,01eh		;844d   ; las letras 0x30-0x5F del primer tercio: negro sobre gris (0x1E)
	ld hl,02180h		;844f
	ld bc,00180h		;8452   ; 48 casillas (FILVRM)
	call 00056h		;8455
	ld a,020h		;8458   ; la pantalla de la seleccion en blanco (0x20)...
	ld b,000h		;845a   ; ...768 bytes
	ld hl,0e500h		;845c   ; en 0xE500...
	call llena		;845f   ; ...256...
	call llena		;8462   ; ...512...
	call llena		;8465   ; ...y 768
	call seleccion_monta		;8468   ; los textos de la seleccion
	ld hl,0ac9bh		;846b   ; las seis filas de arriba de la pantalla de la carrera (0xAC9B) a 0xE200...
	ld de,0e200h		;846e   ; 192 bytes
	ld bc,000c0h		;8471
	ldir		;8474
	ld hl,0ad5bh		;8476   ; ...y las dos de abajo (0xAD5B) a 0xE4C0
	ld de,0e4c0h		;8479   ; 64 bytes
	ld bc,00040h		;847c
	ldir		;847f
	xor a			;8481   ; 0xF310-0xF31F a cero
	ld hl,0f310h		;8482   ; 16 bytes...
	ld b,010h		;8485
	call llena		;8487   ; ...a cero
	ld hl,00102h		;848a   ; al estado 2, paso 1: la seleccion
	ld (0e05eh),hl		;848d   ; estado 2, paso 1
	ret			;8490
ram_borra:		; La RAM del juego (0xE000-0xE1FF) a cero
	ld hl,0e000h		;8491
	xor a			;8494
	ld b,a			;8495
	call llena		;8496
	call llena		;8499
sprites_fuera:		; Los 26 sprites a Y = 0xC0 (fuera) y la marca de fin 0xD0
	ld a,0c0h		;849c
	ld b,068h		;849e   ; 26 sprites x 4
	ld hl,0e180h		;84a0
	call llena		;84a3
	ld a,0d0h		;84a6   ; detras, la marca de fin (0xD0)
	ld (hl),a			;84a8
	ret			;84a9
seleccion_monta:		; La pantalla de la seleccion en 0xE500: el titulo en kanji, los modos y el copyright
	ld hl,0bd35h		;84aa   ; el titulo: CASIO y 大障害競馬...
	ld de,0e509h		;84ad   ; ...en la fila 0...
	ld bc,00e06h		;84b0   ; ...14 casillas por 6 filas
	call copia_bloque		;84b3   ; (0xBD35)
	ld hl,0851ah		;84b6   ; PLAYER SELECT
	ld de,0e5eah		;84b9   ; fila 7, columna 10...
	ld bc,0000dh		;84bc   ; ...13 letras
	ldir		;84bf
	ld hl,08527h		;84c1   ; A PLAY-JOCKEY MODE
	ld de,0e627h		;84c4   ; fila 9, columna 7
	ld bc,00013h		;84c7   ; 19 letras
	ldir		;84ca
	ld hl,0853ah		;84cc   ; B 1PLAYER BET MODE
	ld de,0e667h		;84cf   ; fila 11
	ld bc,00013h		;84d2
	ldir		;84d5
	ld hl,0854dh		;84d7   ; C 2PLAYERS BET MODE
	ld de,0e6a7h		;84da   ; fila 13
	ld bc,00013h		;84dd
	ldir		;84e0
	ld hl,08560h		;84e2   ; D 3PLAYERS BET MODE
	ld de,0e6e7h		;84e5   ; fila 15
	ld bc,00013h		;84e8
	ldir		;84eb
	ld hl,08573h		;84ed   ; E 4PLAYERS BET MODE
	ld de,0e727h		;84f0   ; fila 17
	ld bc,00013h		;84f3
	ldir		;84f6
	ld hl,08586h		;84f8   ; PUSH TRIGGER 1
	ld de,0e76ah		;84fb   ; fila 19, columna 10...
	ld bc,0000eh		;84fe   ; ...14 letras
	ldir		;8501
	ld hl,08594h		;8503   ; TO START GAME
	ld de,0e7a9h		;8506   ; fila 21, columna 9
	ld bc,0000eh		;8509
	ldir		;850c
	ld hl,085a2h		;850e   ; COPYRIGHT 1984 @ CASIO
	ld de,0e7e6h		;8511   ; fila 23, columna 6...
	ld bc,00016h		;8514   ; ...22 letras
	ldir		;8517
	ret			;8519

; ----------------------------------------------------------------------
; DATOS textos_seleccion: Los textos de la seleccion, en ASCII: PLAYER SELECT,
;   los cinco modos, PUSH TRIGGER 1 TO START GAME y el copyright (la @ se
;   dibuja como ©, ^ como -)
;   0x851a..0x85b8  (158 bytes)
DATA_textos_seleccion:
	defb 050h,04ch,041h,059h,045h,052h,020h,053h,045h,04ch,045h,043h,054h	; 851a  PLAYER SELECT
	defb 041h,020h,050h,04ch,041h,059h,05eh,04ah,04fh,043h,04bh,045h,059h,020h,020h,04dh,04fh,044h,045h	; 8527  A PLAY^JOCKEY  MODE
	defb 042h,020h,031h,050h,04ch,041h,059h,045h,052h,020h,020h,042h,045h,054h,020h,04dh,04fh,044h,045h	; 853a  B 1PLAYER  BET MODE
	defb 043h,020h,032h,050h,04ch,041h,059h,045h,052h,053h,020h,042h,045h,054h,020h,04dh,04fh,044h,045h	; 854d  C 2PLAYERS BET MODE
	defb 044h,020h,033h,050h,04ch,041h,059h,045h,052h,053h,020h,042h,045h,054h,020h,04dh,04fh,044h,045h	; 8560  D 3PLAYERS BET MODE
	defb 045h,020h,034h,050h,04ch,041h,059h,045h,052h,053h,020h,042h,045h,054h,020h,04dh,04fh,044h,045h	; 8573  E 4PLAYERS BET MODE
	defb 050h,055h,053h,048h,020h,054h,052h,049h,047h,047h,045h,052h,020h,031h	; 8586  PUSH TRIGGER 1
	defb 020h,054h,04fh,020h,053h,054h,041h,052h,054h,020h,047h,041h,04dh,045h	; 8594   TO START GAME
	defb 043h,04fh,050h,059h,052h,049h,047h,048h,054h,020h,031h,039h,038h,034h,020h,040h,020h,043h,041h,053h,049h,04fh	; 85a2  COPYRIGHT 1984 @ CASIO

; ======================================================================
; CODIGO 0x85b8..0x85de  (38 bytes)
; ======================================================================


copia_bloque:		; Copia un bloque de C filas de B bytes desde HL a DE, que es una pantalla de 32 de ancho
	push bc			;85b8
	push de			;85b9
	ld c,b			;85ba   ; una fila
	ld b,000h		;85bb   ; BC = B
	ldir		;85bd   ; una fila
	pop de			;85bf
	push hl			;85c0   ; lo que queda
	ld hl,00020h		;85c1   ; DE a la fila siguiente
	add hl,de			;85c4   ; DE + 32
	ex de,hl			;85c5
	pop hl			;85c6
	pop bc			;85c7
	dec c			;85c8   ; una fila menos
	jp nz,copia_bloque		;85c9
	ret			;85cc
colores_lista:		; La lista de colores de HL: parejas (color, cuantos grupos de 8 bytes) hasta un 0, 0
	ld c,(hl)			;85cd   ; el color...
	inc hl			;85ce
	ld b,(hl)			;85cf   ; ...y cuantas casillas
	inc hl			;85d0
	ld a,b			;85d1   ; 0, 0: se acaba
	or c			;85d2
	ret z			;85d3
	push hl			;85d4
	ex de,hl			;85d5
	call llena_filas		;85d6
	ex de,hl			;85d9
	pop hl			;85da
	jp colores_lista		;85db

; ----------------------------------------------------------------------
; DATOS colores_casillas: Los colores de las casillas de la carrera de hierba:
;   parejas (color, cuantas casillas)
;   0x85de..0x8616  (56 bytes)
DATA_colores_casillas:
	defb 0f0h,001h	; 85de
	defb 090h,00fh	; 85e0
	defb 0f0h,030h	; 85e2
	defb 050h,020h	; 85e4
	defb 01eh,011h	; 85e6
	defb 015h,00fh	; 85e8
	defb 01ch,016h	; 85ea
	defb 09fh,00bh	; 85ec
	defb 03ch,004h	; 85ee
	defb 0c3h,00dh	; 85f0
	defb 05fh,005h	; 85f2
	defb 0f6h,001h	; 85f4
	defb 083h,007h	; 85f6
	defb 005h,001h	; 85f8
	defb 0d3h,002h	; 85fa
	defb 0c3h,004h	; 85fc
	defb 0e6h,001h	; 85fe
	defb 0e1h,001h	; 8600
	defb 081h,001h	; 8602
	defb 011h,001h	; 8604
	defb 0f3h,001h	; 8606
	defb 083h,001h	; 8608
	defb 0f3h,001h	; 860a
	defb 066h,001h	; 860c
	defb 088h,001h	; 860e
	defb 090h,003h	; 8610
	defb 01eh,007h	; 8612
	defb 000h,000h	; 8614

; ======================================================================
; CODIGO 0x8616..0x8650  (58 bytes)
; ======================================================================


vram_tres:		; Copia BC bytes de HL a la VRAM DE y a los dos tercios siguientes (DE + 0x800, + 0x1000)
	push hl			;8616   ; lo de ahora
	push de			;8617
	push bc			;8618
	call 0005ch		;8619   ; LDIRVM al primer tercio
	pop bc			;861c
	pop de			;861d
	ld hl,00800h		;861e   ; el segundo tercio...
	add hl,de			;8621
	ex de,hl			;8622
	pop hl			;8623
	push hl			;8624
	push de			;8625
	push bc			;8626
	call 0005ch		;8627   ; ...LDIRVM
	pop bc			;862a
	pop de			;862b
	ld hl,00800h		;862c   ; el tercer tercio...
	add hl,de			;862f
	ex de,hl			;8630
	pop hl			;8631
	call 0005ch		;8632   ; ...LDIRVM
	ret			;8635
azar:		; El numero al azar de 0xE800: x 5 + 1, a la mitad y mas el registro R
	push bc			;8636
	push hl			;8637
	ld hl,0e800h		;8638   ; la semilla
	ld a,(hl)			;863b
	ld b,a			;863c   ; B = la semilla
	add a,a			;863d   ; x 5...
	add a,a			;863e   ; x 4...
	add a,b			;863f   ; ...+ ella: x 5
	inc a			;8640   ; ...+ 1
	rrca			;8641   ; ...a la mitad (rrca)
	ld c,a			;8642
	ld a,r		;8643   ; mas R, que cambia con cada instruccion
	add a,c			;8645
	ld (hl),a			;8646   ; la nueva semilla
	pop hl			;8647
	pop bc			;8648
	ret			;8649
estado_seleccion:		; Estado 2: la seleccion de modo
	ld a,(ix+001h)		;864a   ; el paso...
	call salta_tabla		;864d   ; ...por la tabla

; ----------------------------------------------------------------------
; DATOS pasos_seleccion: Los tres pasos: la pantalla, la espera y la eleccion
;   0x8650..0x8656  (6 bytes)
DATA_pasos_seleccion:
	defw 08656h,086adh,086e5h	; 8650  -> seleccion_pantalla seleccion_espera seleccion_elige

; ======================================================================
; CODIGO 0x8656..0x86e1  (139 bytes)
; ======================================================================


seleccion_pantalla:		; Paso 1: la pantalla de la seleccion a la VRAM
	call 00041h		;8656   ; la pantalla apagada
	call ram_borra		;8659   ; la RAM del juego a cero
	call sprites_fuera		;865c   ; los sprites fuera
	ld hl,0b735h		;865f   ; las letras grandes del titulo (0xB735) en las casillas 0x60-0x7F
	ld de,00300h		;8662   ; a las casillas 0x60-0x7F...
	ld bc,00100h		;8665   ; ...256 bytes...
	call vram_tres		;8668   ; ...de los tres tercios
	ld hl,0e800h		;866b   ; sus colores: rojo sobre negro (0x60)...
	ld a,060h		;866e   ; rojo (0x60)...
	ld b,000h		;8670   ; ...256 bytes
	call llena		;8672
	ld hl,0e800h		;8675   ; a sus colores...
	ld de,02300h		;8678   ; ...en 0x2300
	ld bc,00100h		;867b
	call vram_tres		;867e   ; ...en los tres tercios
	ld a,0f1h		;8681   ; blanco sobre negro (0xF1)...
	ld hl,0e800h		;8683   ; 512 bytes...
	ld b,000h		;8686   ; ...de 0xF1
	call llena		;8688
	call llena		;868b
	ld hl,0e800h		;868e   ; ...las casillas 0x30-0x5F
	ld de,02180h		;8691   ; a los colores de las casillas 0x30-0x5F...
	ld bc,00180h		;8694
	call vram_tres		;8697   ; ...de los tres tercios
	ld hl,0e500h		;869a   ; la pantalla montada (0xE500) a la tabla de nombres
	ld de,01800h		;869d   ; a la tabla de nombres...
	ld bc,00300h		;86a0   ; ...768 bytes
	call 0005ch		;86a3
	ld hl,00202h		;86a6   ; al paso 2
	ld (0e05eh),hl		;86a9   ; estado 2, paso 2
	ret			;86ac
seleccion_espera:		; Paso 2: la pantalla encendida, la demostracion preparada y la cuenta de 1024 cuadros
	call 00044h		;86ad   ; ENASCR
	xor a			;86b0   ; la pista quieta
	ld (0f0d0h),a		;86b1
	dec a			;86b4   ; el modo, 0xFF: la demostracion si nadie toca nada
	ld (0e001h),a		;86b5
	ld hl,086e1h		;86b8   ; el sprite del cursor
	ld de,0e1c8h		;86bb
	ld bc,00004h		;86be
	ldir		;86c1
	ld hl,00400h		;86c3   ; 1024 cuadros (unos 17 segundos)
	ld (0e05ch),hl		;86c6
	ld hl,00302h		;86c9   ; al paso 3
	ld (0e05eh),hl		;86cc
	ret			;86cf
seleccion_toca:		; Si se mueve la palanca, la cuenta vuelve a empezar; luego la cuenta atras
	ld a,(0e003h)		;86d0   ; arriba o abajo?
	and 060h		;86d3
	jr z,seleccion_cuenta		;86d5
	ld hl,00400h		;86d7   ; otra vez 1024
	ld (0e05ch),hl		;86da
seleccion_cuenta:		; Un cuadro menos
	call cuenta_baja		;86dd
	ret			;86e0

; ----------------------------------------------------------------------
; DATOS sprite_cursor: El cursor de la seleccion: Y 0x3F, X 0x38, dibujo 0x0C,
;   color 1
;   0x86e1..0x86e5  (4 bytes)
DATA_sprite_cursor:
	defb 03fh,038h,00ch,001h	; 86e1

; ======================================================================
; CODIGO 0x86e5..0x8794  (175 bytes)
; ======================================================================


seleccion_elige:		; Paso 3: el cursor con la palanca, y el boton 1 elige; si se acaba la cuenta, la demostracion
	call seleccion_toca		;86e5   ; se acaba la cuenta?
	jp z,carrera_pantalla		;86e8
	ld a,(0e00ah)		;86eb   ; el boton 1?
	and a			;86ee   ; no: el cursor
	jp z,seleccion_cursor		;86ef
	ld a,(0e063h)		;86f2   ; la opcion es el modo
	ld (0e001h),a		;86f5
	call apuestas_empieza		;86f8   ; la carrera 1 y las apuestas
carrera_pantalla:		; La pantalla de la carrera: las letras, el marcador de abajo y el estado que toca
	call 00041h		;86fb   ; la pantalla apagada
	call sprites_fuera		;86fe   ; los sprites fuera
	ld a,01eh		;8701   ; las letras 0x30-0x5F: negro sobre gris (0x1E)
	ld hl,0e800h		;8703   ; 512 bytes en 0xE800...
	ld b,000h		;8706
	call llena		;8708
	call llena		;870b   ; ...con 0x1E
	ld hl,0e800h		;870e   ; a la tabla de colores...
	ld de,02180h		;8711   ; ...de las casillas 0x30-0x5F...
	ld bc,00180h		;8714
	call vram_tres		;8717   ; ...en los tres tercios
	ld hl,0b835h		;871a   ; las casillas 0x60-0x7F: 0xB835 y 0xB935
	ld de,0e800h		;871d   ; a 0xE800, 128 bytes...
	ld bc,00080h		;8720
	ldir		;8723
	ld hl,0b935h		;8725   ; ...y otros 128
	ld bc,00080h		;8728
	ldir		;872b
	ld hl,0e800h		;872d   ; a las casillas 0x60-0x7F...
	ld de,00300h		;8730
	ld bc,00100h		;8733
	call vram_tres		;8736   ; ...de los tres tercios
	ld hl,0e800h		;8739   ; sus colores: 0x15 las casillas 0x60-0x6F...
	ld a,015h		;873c
	ld b,080h		;873e   ; 128 bytes
	call llena		;8740
	ld a,09fh		;8743   ; ...y 0x9F las 0x70-0x7F
	ld b,080h		;8745   ; 128 bytes
	call llena		;8747
	ld hl,0e800h		;874a   ; sus colores...
	ld de,02300h		;874d   ; ...en 0x2300...
	ld bc,00100h		;8750
	call vram_tres		;8753   ; ...de los tres tercios
	ld hl,0e200h		;8756   ; la pantalla de la carrera (0xE200, montada al arrancar) a la tabla de nombres
	ld de,01800h		;8759   ; a la tabla de nombres...
	ld bc,00300h		;875c   ; ...768 bytes
	call 0005ch		;875f
	ld a,(0e001h)		;8762   ; el modo
	and a			;8765   ; 0: el jinete
	call z,cartel_bonus		;8766   ; el jinete: los carteles de BONUS
	ld h,001h		;8769   ; H = 1: el paso 1 del estado...
	ld l,005h		;876b   ; ...5, la demostracion
	cp 0ffh		;876d   ; 0xFF?
	call z,cartel_demostracion		;876f   ; con su cartel
	jr z,carrera_estado		;8772   ; la demostracion
	ld l,003h		;8774   ; 3: el jinete...
	cp 001h		;8776   ; 1-4: la apuesta
	jr c,carrera_estado		;8778
	ld l,004h		;877a   ; ...4: la apuesta
carrera_estado:		; El estado y su paso
	ld (0e05eh),hl		;877c
	ret			;877f
cartel_demostracion:		; DEMONSTRATION en el recuadro de arriba
	push af			;8780
	push hl			;8781
	call recuadro_borra		;8782   ; el recuadro en blanco
	ld hl,08794h		;8785   ; DEMONSTRATION...
	ld de,01885h		;8788   ; ...en la fila 4
	ld bc,0000dh		;878b
	call 0005ch		;878e
	pop hl			;8791
	pop af			;8792
	ret			;8793

; ----------------------------------------------------------------------
; DATOS texto_demostracion: DEMONSTRATION
;   0x8794..0x87a1  (13 bytes)
DATA_texto_demostracion:
	defb 044h,045h,04dh,04fh,04eh,053h,054h,052h,041h,054h,049h,04fh,04eh	; 8794  DEMONSTRATION

; ======================================================================
; CODIGO 0x87a1..0x87e1  (64 bytes)
; ======================================================================


cartel_bonus:		; El recuadro del jinete: 1ST BONUS 1000 y 2ND BONUS 500
	push af			;87a1
	call recuadro_borra		;87a2
	ld hl,087e1h		;87a5   ; la fila 3...
	ld de,01863h		;87a8
	ld bc,00011h		;87ab
	call 0005ch		;87ae
	ld hl,087f2h		;87b1   ; ...y la 4
	ld de,01883h		;87b4
	ld bc,00011h		;87b7
	call 0005ch		;87ba
	pop af			;87bd
	ret			;87be
recuadro_borra:		; Las cuatro filas del recuadro de arriba (0x1840-0x18BF), cuatro veces 4 casillas 0x90
	ld hl,01840h		;87bf
	call recuadro_fila		;87c2   ; la fila 2
	ld hl,01860h		;87c5
	call recuadro_fila		;87c8   ; la fila 3
	ld hl,01880h		;87cb
	call recuadro_fila		;87ce   ; la fila 4
	ld hl,018a0h		;87d1
	call recuadro_fila		;87d4   ; la fila 5
	ret			;87d7
recuadro_fila:		; Cuatro casillas 0x90 en HL (FILVRM)
	ld a,090h		;87d8
	ld bc,00004h		;87da
	call 00056h		;87dd
	ret			;87e0

; ----------------------------------------------------------------------
; DATOS textos_bonus: 1ST BONUS 1000 y 2ND BONUS 500 (los numeros son casillas
;   propias, 0x80-0x89)
;   0x87e1..0x8803  (34 bytes)
DATA_textos_bonus:
	defb 031h,053h,054h,090h,090h,090h,042h,04fh,04eh,055h,053h,090h,090h,081h,080h,080h,080h	; 87e1  1ST...BONUS......
	defb 032h,04eh,044h,090h,090h,090h,042h,04fh,04eh,055h,053h,090h,090h,090h,085h,080h,080h	; 87f2  2ND...BONUS......

; ======================================================================
; CODIGO 0x8803..0x8836  (51 bytes)
; ======================================================================


apuestas_empieza:		; La carrera 1; cada jugador que apuesta empieza con su marca a 1
	ld a,001h		;8803   ; la carrera 1
	ld (0e000h),a		;8805
	ld a,(0e001h)		;8808   ; cuantos jugadores...
	and 007h		;880b   ; ...0: el jinete
	ret z			;880d
	ld b,a			;880e
	ld hl,0e031h		;880f   ; una marca cada 4 bytes desde 0xE031
	ld de,00004h		;8812
apuestas_empieza_uno:		; Un jugador
	ld (hl),001h		;8815
	add hl,de			;8817
	djnz apuestas_empieza_uno		;8818
	ret			;881a
seleccion_cursor:		; El cursor de la seleccion: la palanca mueve la opcion (0-4) y el sprite parpadea
	ld b,005h		;881b   ; cinco opciones
	call opcion_mueve		;881d
	ld b,000h		;8820   ; la Y del cursor...
	ld hl,08836h		;8822   ; ...de la tabla 0x8836
	add hl,bc			;8825
	ld a,(hl)			;8826
	ld (0e1c8h),a		;8827
	ld a,(0e07bh)		;882a   ; cada 4 cuadros...
	bit 2,a		;882d
	ret nz			;882f
	ld a,0c2h		;8830   ; ...fuera
	ld (0e1c8h),a		;8832
	ret			;8835

; ----------------------------------------------------------------------
; DATOS y_cursor: La Y del cursor en cada opcion: A a E
;   0x8836..0x883b  (5 bytes)
DATA_y_cursor:
	defb 03fh,04fh,05fh,06fh,07fh	; 8836

; ======================================================================
; CODIGO 0x883b..0x886c  (49 bytes)
; ======================================================================


opcion_mueve:		; La opcion 0xE063 con la palanca: abajo uno mas, arriba uno menos, entre 0 y B - 1; deja en C la nueva y en E la vieja
	ld hl,(0e00ch)		;883b   ; la palanca con repeticion...
	ld a,(0e07bh)		;883e   ; ...cuenta solo un cuadro de cada 8
	and 007h		;8841
	jr z,L_8847		;8843
	ld l,000h		;8845
L_8847:
	ld a,(0e009h)		;8847   ; o la recien pulsada
	or l			;884a
	ld hl,0e063h		;884b   ; la opcion
	ld c,(hl)			;884e
	ld e,c			;884f
	add a,a			;8850   ; los bits de la palanca, del 7 (derecha) abajo...
	add a,a			;8851   ; ...bit 6: abajo
	jr c,opcion_baja		;8852
	add a,a			;8854   ; bit 5: arriba
	jr nc,opcion_guarda		;8855
	ld a,c			;8857   ; la primera?
	and a			;8858
	jr z,opcion_guarda		;8859
	dec c			;885b
	jr opcion_guarda		;885c
opcion_baja:		; Una mas, si no es la ultima
	inc c			;885e
	ld a,c			;885f
	cp b			;8860
	jr c,opcion_guarda		;8861
	dec c			;8863
opcion_guarda:		; La opcion nueva
	ld (hl),c			;8864
	ret			;8865
estado_jinete:		; Estado 3: el modo A, el jugador lleva un caballo
	ld a,(ix+001h)		;8866   ; el paso...
	call salta_tabla		;8869   ; ...por la tabla

; ----------------------------------------------------------------------
; DATOS pasos_jinete: Los cinco pasos: la carrera nueva, la eleccion del
;   caballo, el final de las nueve, su espera y la salida
;   0x886c..0x8876  (10 bytes)
DATA_pasos_jinete:
	defw 08876h,08939h,08a00h,08a2eh,08a59h	; 886c

; ======================================================================
; CODIGO 0x8876..0x888e  (24 bytes)
; ======================================================================


jinete_carrera:		; Paso 1: los caballos a la salida, los premios de la carrera y su musica
	call caballos_salida		;8876   ; los cuatro caballos al principio
	call premios		;8879   ; los premios de la carrera
	ld hl,00400h		;887c   ; 1024 cuadros para elegir
	ld (0e05ch),hl		;887f
	xor a			;8882   ; el cursor en el caballo 1
	ld (0e063h),a		;8883
	call musica_primera		;8886   ; la musica de la primera carrera
	ld (ix+001h),002h		;8889   ; al paso 2
	ret			;888d

; ----------------------------------------------------------------------
; DATOS textos_horse_select: HORSE SELECT JOY y START PUSH TRIG 2 (el espacio
;   es la hierba, 0xE2-0xE4); PUSH TRIG 2 se usa tambien solo (0x88A4)
;   0x888e..0x88af  (33 bytes)
DATA_textos_horse_select:
	defb 048h,04fh,052h,053h,045h,0e2h,053h,045h,04ch,045h,043h,054h,0e3h,04ah,04fh,059h	; 888e  HORSE.SELECT.JOY
	defb 053h,054h,041h,052h,054h,0e3h,050h,055h,053h,048h,0e4h,054h,052h,049h,047h,0e3h,032h	; 889e  START.PUSH.TRIG.2

; ======================================================================
; CODIGO 0x88af..0x88e6  (55 bytes)
; ======================================================================


premios:		; Los premios de la carrera (0xE000): 1ST en la fila 3 (0x88E6) y 2ND en la 4 (0x88EF), dos cifras y los ceros fijos
	ld a,(0e000h)		;88af   ; la carrera...
	dec a			;88b2   ; ...menos 1
	ld c,a			;88b3
	ld b,000h		;88b4
	ld hl,088e6h		;88b6   ; el del primero
	add hl,bc			;88b9
	ex de,hl			;88ba
	ld hl,01870h		;88bb   ; en la fila 3
	push bc			;88be
	call premio_pinta		;88bf
	pop bc			;88c2
	ld hl,088efh		;88c3   ; el del segundo...
	add hl,bc			;88c6
	ex de,hl			;88c7
	ld hl,01890h		;88c8   ; ...en la fila 4
premio_pinta:		; Las dos cifras BCD de (DE) en HL: un 0 a la izquierda va en blanco
	ld a,(de)			;88cb   ; las decenas...
	ld b,a			;88cc
	rrca			;88cd
	rrca			;88ce
	rrca			;88cf
	rrca			;88d0
	and 00fh		;88d1
	jr nz,premio_cifra		;88d3   ; un 0: la casilla en blanco (0x10 + 0x80)
	ld a,010h		;88d5
premio_cifra:		; Las cifras son las casillas 0x80-0x89
	or 080h		;88d7
	call vram_pon		;88d9
	inc hl			;88dc
	ld a,b			;88dd   ; las unidades
	and 00fh		;88de
	or 080h		;88e0
	call vram_pon		;88e2
	ret			;88e5

; ----------------------------------------------------------------------
; DATOS premios_tabla: Los premios en BCD por carrera (con dos ceros detras):
;   1ST de 1000 a 9000 y 2ND de 500 a 4500; detras, cuatro bytes (0x50, 0xC0,
;   0x00, 0x08) que estas rutinas no leen: el indice llega a 0x88F7
;   0x88e6..0x88fc  (22 bytes)
DATA_premios_tabla:
	defb 010h,020h,030h,040h,050h,060h,070h,080h,090h	; 88e6  . 0@P`p..
	defb 005h,010h,015h,020h,025h,030h,035h,040h,045h	; 88ef  ... %05@E
	defb 050h,0c0h,000h,008h	; 88f8

; ======================================================================
; CODIGO 0x88fc..0x89d3  (215 bytes)
; ======================================================================


caballos_salida:		; Los cuatro caballos al paso 1 de su estado 1 (la salida), la pista empieza, el sonido callado y la apuesta preparada
	ld hl,00101h		;88fc   ; estado 1, paso 1...
	ld (0e07fh),hl		;88ff   ; ...en los cuatro caballos
	ld (0e09fh),hl		;8902
	ld (0e0bfh),hl		;8905
	ld (0e0dfh),hl		;8908
	ld a,001h		;890b   ; la pista: empieza
	ld (0e06ch),a		;890d
	call sprites_fuera		;8910   ; los sprites fuera
	call sonido_calla		;8913   ; el sonido callado
	push ix		;8916
	push iy		;8918
	call carrera_prepara		;891a   ; las fuerzas y las cuotas (0xA8CC)
	pop iy		;891d
	pop ix		;891f
	ret			;8921
musica_primera:		; La musica de la primera carrera, en los canales 0 y 1 (0xAD9B y 0xBD89)
	ld a,(0e000h)		;8922   ; solo en la carrera 1
	cp 001h		;8925
	ret nz			;8927
	ld b,000h		;8928
	ld de,0ad9bh		;892a
	call pieza		;892d
	ld b,001h		;8930
	ld de,0bd89h		;8932
	call pieza		;8935
	ret			;8938
jinete_elige:		; Paso 2: HORSE SELECT; la palanca mueve el cursor por los cuatro caballos y el boton 1 elige (o se acaba la cuenta)
	call 00044h		;8939   ; la pantalla encendida
	call suena		;893c   ; espera a que acabe la musica
	ret nz			;893f   ; aun suena
	call cartel_horse_select		;8940   ; HORSE SELECT JOY / START PUSH TRIG 2
	call seleccion_toca		;8943   ; la cuenta: si se acaba, elige solo
	jp z,jinete_elegido		;8946   ; se acaba la cuenta: el caballo de la opcion
	ld a,(0e00ah)		;8949   ; el boton 1?
	and a			;894c
	jp nz,jinete_elegido		;894d   ; el boton 1: tambien
	ld b,004h		;8950   ; cuatro caballos: la palanca
	call opcion_mueve		;8952   ; la opcion
	ld a,b			;8955   ; ha cambiado?
	cp e			;8956   ; la misma?
	jr z,jinete_cursor		;8957
	ld hl,0e18bh		;8959   ; el color del numero del caballo de antes...
	ld a,e			;895c   ; la de antes...
	add a,a			;895d   ; ...x 4: su sprite
	add a,a			;895e
	ld e,a			;895f
	ld d,000h		;8960
	add hl,de			;8962   ; el color
	ld (hl),00fh		;8963   ; ...a blanco
jinete_cursor:		; El numero del caballo elegido parpadea: blanco y negro cada 4 cuadros
	ld hl,0e18bh		;8965   ; el sprite del numero del caballo
	ld a,c			;8968   ; la nueva...
	add a,a			;8969   ; ...x 4
	add a,a			;896a
	ld c,a			;896b
	ld b,000h		;896c
	add hl,bc			;896e   ; el color
	ld (hl),00fh		;896f   ; blanco
	ld a,(0e07bh)		;8971   ; cada 4 cuadros
	bit 2,a		;8974
	ret nz			;8976
	ld (hl),000h		;8977   ; negro
	ret			;8979   ; negro
jinete_elegido:		; El caballo: la opcion + 1; los numeros a blanco y al paso 5
	ld a,(0e063h)		;897a   ; el caballo...
	inc a			;897d
	ld (0e002h),a		;897e   ; ...del jugador
	ld a,00fh		;8981   ; los dos sprites 0 y 1, a Y 0x0F...
	ld (0e180h),a		;8983
	ld (0e184h),a		;8986
	ld a,00fh		;8989   ; ...los cuatro numeros de los caballos en blanco
	ld (0e18bh),a		;898b
	ld (0e18fh),a		;898e
	ld (0e193h),a		;8991
	ld (0e197h),a		;8994
	call fuerza_jugador		;8997   ; la fuerza de su caballo para la barra (0xF0E7)
	ld hl,00503h		;899a   ; al paso 5
	ld (0e05eh),hl		;899d
	ret			;89a0
cartel_horse_select:		; HORSE SELECT JOY / START PUSH TRIG 2 en el centro de la pista
	ld hl,0888eh		;89a1   ; HORSE SELECT JOY...
	ld de,01962h		;89a4   ; ...en la fila 11
	ld bc,00010h		;89a7
	call 0005ch		;89aa
	ld hl,0889eh		;89ad   ; START PUSH TRIG 2...
	ld de,019a2h		;89b0   ; ...en la fila 13
	ld bc,00011h		;89b3
	call 0005ch		;89b6
	ret			;89b9
cartel_borra:		; El cartel del centro, borrado con hierba (0x89D3)
	ld hl,089d3h		;89ba
	ld de,01962h		;89bd   ; en la fila 11
	ld bc,00014h		;89c0
	call 0005ch		;89c3
	ld hl,089d3h		;89c6
	ld de,019a2h		;89c9   ; en la fila 13
	ld bc,00014h		;89cc
	call 0005ch		;89cf
	ret			;89d2

; ----------------------------------------------------------------------
; DATOS hierba: Veinte casillas de hierba para borrar un cartel
;   0x89d3..0x89e7  (20 bytes)
DATA_hierba:
	defb 0e2h,0e3h,0e4h,0e5h,0e2h,0e4h,0e3h,0e2h,0e3h,0e4h,0e5h,0e2h,0e4h,0e3h,0e3h,0e4h,0e5h,0e2h,0e4h,0e3h	; 89d3  ....................

; ======================================================================
; CODIGO 0x89e7..0x8a73  (140 bytes)
; ======================================================================


caballos_corren:		; Los cuatro caballos al paso 2 de su estado 1, la pista corre y sin resultado
	ld hl,00102h		;89e7
	ld (0e07fh),hl		;89ea
	ld (0e09fh),hl		;89ed
	ld (0e0bfh),hl		;89f0
	ld (0e0dfh),hl		;89f3
	ld a,002h		;89f6   ; la pista: corre
	ld (0e06ch),a		;89f8
	xor a			;89fb   ; sin resultado
	ld (0e07dh),a		;89fc
	ret			;89ff
jinete_fin:		; Paso 3: las nueve carreras hechas: RACE END, su musica y a la carrera 1
	ld a,0c2h		;8a00   ; el sprite 0 fuera
	ld (0e180h),a		;8a02
	ld hl,0e000h		;8a05   ; otra vez la carrera 1
	ld (hl),001h		;8a08
	call musica_fin		;8a0a   ; la musica
	call cartel_race_end		;8a0d   ; RACE END
	ld hl,00200h		;8a10   ; 512 cuadros
	ld (0e05ch),hl		;8a13
	ld hl,00403h		;8a16   ; al paso 4 del estado 3
	ld (0e05eh),hl		;8a19
	ret			;8a1c
musica_fin:		; La musica de las nueve carreras hechas, en los canales 0 y 1 (0xBEDC y 0xBF07)
	ld b,000h		;8a1d
	ld de,0bedch		;8a1f   ; (0xBEDC)
	call pieza		;8a22
	ld b,001h		;8a25   ; el canal 1...
	ld de,0bf07h		;8a27   ; ...(0xBF07)
	call pieza		;8a2a
	ret			;8a2d
jinete_fin_espera:		; Paso 4: la musica y la cuenta, y otra vez desde el paso 1
	call carrera_apuestas		;8a2e   ; la pista y el marcador siguen
	call suena		;8a31   ; suena?
	ret nz			;8a34
	call cuenta_baja		;8a35   ; la cuenta
	ret nz			;8a38
	call cartel_borra		;8a39   ; sin cartel
	ld hl,00103h		;8a3c   ; al paso 1
	ld (0e05eh),hl		;8a3f
	ret			;8a42
suena:		; NZ si alguno de los tres canales suena
	ld a,(0f004h)		;8a43
	ld hl,(0f024h)		;8a46   ; el canal 1
	or l			;8a49
	ld hl,(0f044h)		;8a4a   ; el canal 2
	or l			;8a4d
	ret			;8a4e
cuenta_baja:		; La cuenta 0xE05C, uno menos; Z si llega a 0
	ld hl,(0e05ch)		;8a4f
	dec hl			;8a52   ; uno menos
	ld (0e05ch),hl		;8a53
	ld a,h			;8a56   ; es 0?
	or l			;8a57
	ret			;8a58
jinete_sale:		; Paso 5: el boton 2 sale; la fanfarria y la carrera sigue en el estado 4, paso 3
	ld a,(0e00bh)		;8a59   ; el boton 2?
	and a			;8a5c
	ret z			;8a5d
	call fanfarria		;8a5e   ; la fanfarria
	call cartel_borra		;8a61   ; sin cartel
	ld (ix+001h),003h		;8a64   ; el paso 3...
	ld (ix+000h),004h		;8a68   ; ...del estado 4: la carrera
	ret			;8a6c
estado_carrera:		; Estado 4: los modos B a E (la apuesta) y la carrera de todos los modos
	ld a,(ix+001h)		;8a6d   ; el paso...
	call salta_tabla		;8a70   ; ...por la tabla

; ----------------------------------------------------------------------
; DATOS pasos_carrera: Los nueve pasos: la salida, la apuesta, la fanfarria,
;   la espera, la carrera, el final, la siguiente, el final de las nueve y el
;   pago
;   0x8a73..0x8a85  (18 bytes)
DATA_pasos_carrera:
	defw 08a85h,08a98h,08af1h,08b0bh,08b1fh,08ba0h,08c7dh,08cc2h,08cd4h	; 8a73

; ======================================================================
; CODIGO 0x8a85..0x8ad9  (84 bytes)
; ======================================================================


apuesta_salida:		; Paso 1: los caballos a la salida, los cursores de la apuesta y la musica
	call caballos_salida		;8a85
	ld a,00fh		;8a88   ; los dos cursores de la apuesta, a Y 0x0F
	ld (0e180h),a		;8a8a
	ld (0e184h),a		;8a8d
	call musica_primera		;8a90   ; la musica de la primera carrera
	ld (ix+001h),002h		;8a93   ; al paso 2
	ret			;8a97
apuesta:		; Paso 2: BET MODE / START PUSH TRIG 2; las apuestas (0xA383) hasta que se pulsa el boton 2
	call 00044h		;8a98   ; la pantalla encendida
	call suena		;8a9b   ; espera a que acabe la musica
	ret nz			;8a9e
	call cartel_bet_mode		;8a9f   ; BET MODE / START PUSH TRIG 2
	push ix		;8aa2
	push iy		;8aa4
	call apuesta_mandos		;8aa6   ; las apuestas
	pop iy		;8aa9
	pop ix		;8aab
	ld a,(0f0c9h)		;8aad   ; sigue la apuesta (bit 7 de 0xF0C9)?
	add a,a			;8ab0
	ret c			;8ab1
	call sonido_calla		;8ab2   ; el sonido callado
	call cartel_borra		;8ab5   ; sin cartel
	call fanfarria		;8ab8   ; la fanfarria
	ld (ix+001h),003h		;8abb   ; al paso 3
	ret			;8abf
cartel_bet_mode:		; BET MODE / START PUSH TRIG 2
	ld hl,08ad9h		;8ac0
	ld de,01962h		;8ac3   ; en la fila 11
	ld bc,00008h		;8ac6
	call 0005ch		;8ac9
	ld hl,0889eh		;8acc   ; START PUSH TRIG 2 en la fila 13
	ld de,019a2h		;8acf
	ld bc,00011h		;8ad2
	call 0005ch		;8ad5
	ret			;8ad8

; ----------------------------------------------------------------------
; DATOS texto_bet_mode: BET MODE (0xE2 es el espacio sobre la hierba)
;   0x8ad9..0x8ae1  (8 bytes)
DATA_texto_bet_mode:
	defb 042h,045h,054h,0e2h,04dh,04fh,044h,045h	; 8ad9  BET.MODE

; ======================================================================
; CODIGO 0x8ae1..0x8b83  (162 bytes)
; ======================================================================


fanfarria:		; La fanfarria de la salida, en los canales 0 y 1 (0xBDCF y 0xBE02)
	ld b,000h		;8ae1
	ld de,0bdcfh		;8ae3   ; (0xBDCF)
	call pieza		;8ae6
	ld b,001h		;8ae9   ; el canal 1...
	ld de,0be02h		;8aeb   ; ...(0xBE02)
	call pieza		;8aee
carrera_fanfarria:		; Paso 3: cuando acaba la fanfarria, 32 cuadros y el sonido de la salida (0xBE8E, canal 2)
	call suena		;8af1   ; suena?
	ret nz			;8af4
	ld hl,00020h		;8af5   ; 32 cuadros
	ld (0e05ch),hl		;8af8
	call sonido_calla		;8afb
	ld b,002h		;8afe   ; la salida
	ld de,0be8eh		;8b00
	call pieza		;8b03
	ld (ix+001h),004h		;8b06   ; al paso 4
	ret			;8b0a
carrera_sale:		; Paso 4: la musica de la carrera (0xBE7F, canal 0) y los caballos corren
	call cuenta_baja		;8b0b   ; la cuenta
	ret nz			;8b0e
	ld b,000h		;8b0f   ; la musica de la carrera
	ld de,0be7fh		;8b11
	call pieza		;8b14
	call caballos_corren		;8b17   ; a correr
	ld (ix+001h),005h		;8b1a   ; al paso 5
	ret			;8b1e
carrera_corre:		; Paso 5: la carrera; en la demostracion, el boton 1 vuelve a la seleccion; al llegar los dos primeros, el pago
	ld a,(0e001h)		;8b1f   ; la demostracion?
	cp 0ffh		;8b22
	jr nz,L_8B2D		;8b24
	ld a,(0e00ah)		;8b26   ; el boton 1?
	and a			;8b29
	jp nz,a_seleccion		;8b2a
L_8B2D:
	call carrera_apuestas		;8b2d   ; las apuestas y los carteles
	ld a,(0e07dh)		;8b30   ; el resultado (0x80 + la pareja ganadora)
	and a			;8b33
	ret z			;8b34
	and 07fh		;8b35   ; la pareja ganadora...
	ld (0f0c8h),a		;8b37   ; ...para el pago
	ld a,001h		;8b3a   ; el pago empieza
	ld (0f0d0h),a		;8b3c
	ld a,0c2h		;8b3f   ; los cuatro sprites de las apuestas, fuera
	ld (0e1c8h),a		;8b41
	ld (0e1cch),a		;8b44
	ld (0e1d0h),a		;8b47
	ld (0e1d4h),a		;8b4a
	ld (ix+001h),009h		;8b4d   ; al paso 9
	ret			;8b51
carrera_apuestas:		; Cada cuadro de la carrera: el parpadeo de la apuesta, las fuerzas, el pago y el cartel de la demostracion
	push ix		;8b52
	push iy		;8b54
	call ganadora_parpadea		;8b56   ; la pareja que gana parpadea
	call carrera_ordenador		;8b59   ; el ordenador lleva sus caballos y el jugador el suyo
	call pago_paso		;8b5c   ; el pago, una cuenta cada dos cuadros
	call demostracion_cartel		;8b5f   ; DEMONSTRATION parpadea
	pop iy		;8b62
	pop ix		;8b64
	ret			;8b66
demostracion_cartel:		; En la demostracion, el cartel DEMONSTRATION aparece y desaparece cada 16 cuadros
	ld a,(0e001h)		;8b67   ; la demostracion?
	inc a			;8b6a
	ret nz			;8b6b
	ld hl,08794h		;8b6c   ; DEMONSTRATION...
	ld a,(0e07bh)		;8b6f   ; ...o cada 16 cuadros...
	bit 4,a		;8b72
	jr z,demostracion_cartel_pon		;8b74
	ld hl,08b83h		;8b76   ; ...en blanco
demostracion_cartel_pon:		; En la fila 4
	ld de,01885h		;8b79
	ld bc,0000dh		;8b7c
	call 0005ch		;8b7f
	ret			;8b82

; ----------------------------------------------------------------------
; DATOS cartel_blanco: Trece casillas 0x90: el recuadro en blanco
;   0x8b83..0x8b90  (13 bytes)
DATA_cartel_blanco:
	defb 090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h	; 8b83  .............

; ======================================================================
; CODIGO 0x8b90..0x8c44  (180 bytes)
; ======================================================================


a_seleccion:		; Vuelve a la seleccion: el sonido callado y el estado 2, paso 1
	call sonido_calla		;8b90
	xor a			;8b93   ; sin pago
	ld (0f0d0h),a		;8b94
	ld (ix+001h),001h		;8b97   ; paso 1...
	ld (ix+000h),002h		;8b9b   ; ...del estado 2
	ret			;8b9f
carrera_final:		; Paso 6: cuando los caballos se han parado y calla la musica, el final: GAME OVER, la carrera siguiente o RACE END
	call carrera_apuestas		;8ba0   ; las apuestas y los carteles
	call caballos_quietos		;8ba3   ; todos los caballos parados?
	ret nz			;8ba6
	ld a,(0f024h)		;8ba7   ; suenan los canales 1 o 2?
	ld hl,(0f044h)		;8baa   ; el canal 2
	or l			;8bad
	ret nz			;8bae
	call sonido_calla		;8baf   ; el sonido callado
	xor a			;8bb2   ; la pista y los caballos, quietos
	ld (0e06ch),a		;8bb3   ; la pista quieta
	ld (0e07fh),a		;8bb6   ; los cuatro caballos al estado 0
	ld (0e09fh),a		;8bb9
	ld (0e0bfh),a		;8bbc
	ld (0e0dfh),a		;8bbf
	ld a,(0e001h)		;8bc2   ; el modo
	cp 0ffh		;8bc5   ; la demostracion?
	jp z,a_seleccion		;8bc7   ; la demostracion: a la seleccion
	and a			;8bca   ; el jinete?
	jp nz,apuesta_final		;8bcb   ; la apuesta
	ld a,(0e144h)		;8bce   ; el jinete: ha llegado el ultimo?...
	cp 004h		;8bd1   ; cuarto?
	jp z,game_over		;8bd3   ; ...GAME OVER
	ld a,(0e000h)		;8bd6   ; la carrera 9?
	cp 009h		;8bd9   ; la carrera 9?
	jp z,jinete_nueve		;8bdb
carrera_siguiente:		; PUSH TRIG 2 y la musica de la llegada (0xBF7D y 0xBF8A); al paso 7
	call cartel_push_trig		;8bde   ; PUSH TRIG 2
	ld b,000h		;8be1   ; el canal 0...
	ld de,0bf7dh		;8be3   ; ...la llegada (0xBF7D)
	call pieza		;8be6
	ld b,001h		;8be9   ; el canal 1...
	ld de,0bf8ah		;8beb   ; ...(0xBF8A)
	call pieza		;8bee
	ld (ix+001h),007h		;8bf1   ; al paso 7
	ret			;8bf5
jinete_nueve:		; El jinete despues de la carrera 9: el estado 3, paso 3 (RACE END)
	ld (ix+001h),003h		;8bf6   ; paso 3...
	ld (ix+000h),003h		;8bfa   ; ...del estado 3
	ret			;8bfe
apuesta_final:		; La apuesta: si nadie tiene dinero, GAME OVER; despues de la carrera 9, RACE END
	ld hl,0e02fh		;8bff   ; el dinero de los cuatro jugadores (16 bytes)...
	xor a			;8c02   ; sumados con OR
	ld b,010h		;8c03
L_8C05:
	or (hl)			;8c05   ; un byte
	inc hl			;8c06
	djnz L_8C05		;8c07
	jr z,game_over		;8c09   ; ...a cero: GAME OVER
	ld a,(0e000h)		;8c0b   ; la carrera 9?
	cp 009h		;8c0e   ; la carrera 9?
	jr nz,carrera_siguiente		;8c10
	call musica_fin		;8c12   ; la musica de las nueve...
	call cartel_race_end		;8c15   ; ...RACE END...
	ld hl,00200h		;8c18   ; ...512 cuadros...
	ld (0e05ch),hl		;8c1b   ; en la cuenta
	ld (ix+001h),008h		;8c1e   ; ...y al paso 8
	ret			;8c22
game_over:		; GAME OVER, su musica, 512 cuadros y al paso 8
	call cartel_game_over		;8c23
	call musica_game_over		;8c26   ; su musica
	ld hl,00200h		;8c29   ; 512 cuadros
	ld (0e05ch),hl		;8c2c
	ld (ix+001h),008h		;8c2f   ; al paso 8
	ret			;8c33
cartel_game_over:		; GAME OVER en la fila 11 y los sprites fuera
	ld hl,08c44h		;8c34
	ld de,0196ah		;8c37   ; en la fila 11
	ld bc,00009h		;8c3a
	call 0005ch		;8c3d
	call sprites_fuera		;8c40   ; los sprites fuera
	ret			;8c43

; ----------------------------------------------------------------------
; DATOS texto_game_over: GAME OVER
;   0x8c44..0x8c4d  (9 bytes)
DATA_texto_game_over:
	defb 047h,041h,04dh,045h,0e2h,04fh,056h,045h,052h	; 8c44  GAME.OVER

; ======================================================================
; CODIGO 0x8c4d..0x8cae  (97 bytes)
; ======================================================================


musica_game_over:		; La musica de GAME OVER, en los canales 0 y 1 (0xBE56 y 0xBE6C)
	ld b,000h		;8c4d
	ld de,0be56h		;8c4f   ; (0xBE56)
	call pieza		;8c52
	ld b,001h		;8c55   ; el canal 1...
	ld de,0be6ch		;8c57   ; ...(0xBE6C)
	call pieza		;8c5a
	ret			;8c5d
cartel_push_trig:		; PUSH TRIG 2 en la fila 11
	ld hl,088a4h		;8c5e
	ld de,01969h		;8c61
	ld bc,0000bh		;8c64
	call 0005ch		;8c67
	ret			;8c6a
caballos_quietos:		; Z si los cuatro caballos estan en el estado 0 (parados)
	xor a			;8c6b
	ld hl,(0e07fh)		;8c6c   ; el estado del 1...
	or l			;8c6f
	ld hl,(0e09fh)		;8c70   ; ...del 2...
	or l			;8c73
	ld hl,(0e0bfh)		;8c74   ; ...del 3...
	or l			;8c77
	ld hl,(0e0dfh)		;8c78   ; ...y del 4
	or l			;8c7b
	ret			;8c7c
carrera_otra:		; Paso 7: cuando calla la musica, el boton 2 pasa a la carrera siguiente
	call carrera_apuestas		;8c7d
	call suena		;8c80   ; suena?
	ret nz			;8c83
	ld a,(0e00bh)		;8c84   ; el boton 2?
	and a			;8c87
	ret z			;8c88
	xor a			;8c89   ; el pago acabado
	ld (0f0d0h),a		;8c8a
	call cartel_borra		;8c8d   ; sin cartel
	ld hl,0e000h		;8c90   ; la carrera siguiente
	inc (hl)			;8c93
	ld a,(0e001h)		;8c94   ; el jinete?
	and a			;8c97
	jr z,$+30		;8c98
	ld hl,00104h		;8c9a   ; la apuesta: al paso 1 del estado 4
	ld (0e05eh),hl		;8c9d
	ret			;8ca0
cartel_race_end:		; RACE END en la fila 11
	ld hl,08caeh		;8ca1
	ld de,0196ch		;8ca4
	ld bc,00008h		;8ca7
	call 0005ch		;8caa
	ret			;8cad

; ----------------------------------------------------------------------
; DATOS texto_race_end: RACE END
;   0x8cae..0x8cb6  (8 bytes)
DATA_texto_race_end:
	defb 052h,041h,043h,045h,0e3h,045h,04eh,044h	; 8cae  RACE.END

; ======================================================================
; CODIGO 0x8cb6..0x8d3b  (133 bytes)
; ======================================================================


jinete_otra:		; El jinete: el sprite 0 fuera y al paso 1 del estado 3
	ld a,0c2h		;8cb6
	ld (0e180h),a		;8cb8
	ld hl,00103h		;8cbb
	ld (0e05eh),hl		;8cbe
	ret			;8cc1
carrera_vuelve:		; Paso 8: cuando calla la musica y se acaba la cuenta, a la seleccion
	call carrera_apuestas		;8cc2
	call suena		;8cc5   ; suena?
	ret nz			;8cc8
	call cuenta_baja		;8cc9   ; la cuenta
	ret nz			;8ccc
	ld hl,00102h		;8ccd   ; al estado 2, paso 1
	ld (0e05eh),hl		;8cd0
	ret			;8cd3
carrera_pago:		; Paso 9: espera a que acabe el pago (bit 7 de 0xF0D0) y suena lo que toque; al paso 6
	call carrera_apuestas		;8cd4
	ld hl,(0f0d0h)		;8cd7   ; el pago...
	bit 7,l		;8cda   ; ...acabado?
	ret z			;8cdc
	ld a,(0e001h)		;8cdd   ; el modo
	and a			;8ce0
	jr z,jinete_puesto		;8ce1
	dec a			;8ce3   ; un solo jugador: nada
	jr z,carrera_pago_fin		;8ce4
	bit 1,l		;8ce6   ; alguien ha cobrado (bit 1)?...
	jr z,carrera_pago_fin		;8ce8
	ld b,001h		;8cea   ; ...el sonido de cobrar (0xBE49) en los canales 1 y 2
	ld de,0be49h		;8cec
	call pieza		;8cef
	ld b,002h		;8cf2
	ld de,0be49h		;8cf4
	call pieza		;8cf7
carrera_pago_fin:		; Al paso 6
	ld (ix+001h),006h		;8cfa
	ret			;8cfe
jinete_puesto:		; El jinete: el primero o el segundo tienen su musica (0xBF32 y 0xBF54); el primero de la carrera 9, la de 0xBF97 y 0xBFB9
	ld a,(0e144h)		;8cff   ; el puesto del jugador
	cp 001h		;8d02
	jr z,jinete_primero		;8d04
	cp 002h		;8d06
	jr nz,carrera_pago_fin		;8d08
jinete_premio:		; La musica del premio
	ld b,001h		;8d0a
	ld de,0bf32h		;8d0c   ; (0xBF32)
	call pieza		;8d0f
	ld b,002h		;8d12   ; el canal 2...
	ld de,0bf54h		;8d14   ; ...(0xBF54)
	call pieza		;8d17
	jr carrera_pago_fin		;8d1a
jinete_primero:		; El primero: en la carrera 9, la musica de las nueve ganadas
	ld a,(0e000h)		;8d1c   ; la carrera 9?
	cp 009h		;8d1f
	jr nz,jinete_premio		;8d21
	ld b,001h		;8d23
	ld de,0bf97h		;8d25
	call pieza		;8d28
	ld b,002h		;8d2b
	ld de,0bfb9h		;8d2d
	call pieza		;8d30
	jr carrera_pago_fin		;8d33
estado_demostracion:		; Estado 5: la demostracion, la carrera 9 con el ordenador
	ld a,(ix+001h)		;8d35
	call salta_tabla		;8d38

; ----------------------------------------------------------------------
; DATOS pasos_demostracion: Los tres pasos: la carrera 9, la pantalla y la
;   espera
;   0x8d3b..0x8d41  (6 bytes)
DATA_pasos_demostracion:
	defw 08d41h,08d4eh,08d5ch	; 8d3b  -> demostracion_salida demostracion_pantalla demostracion_espera

; ======================================================================
; CODIGO 0x8d41..0x8d79  (56 bytes)
; ======================================================================


demostracion_salida:		; Paso 1: la carrera 9 y los caballos a la salida
	ld a,009h		;8d41   ; la carrera 9 (tierra, 3600 m)
	ld (0e000h),a		;8d43
	call caballos_salida		;8d46
	ld (ix+001h),002h		;8d49
	ret			;8d4d
demostracion_pantalla:		; Paso 2: la pantalla encendida y 128 cuadros
	call 00044h		;8d4e
	ld hl,00080h		;8d51
	ld (0e05ch),hl		;8d54
	ld (ix+001h),003h		;8d57
	ret			;8d5b
demostracion_espera:		; Paso 3: el cartel parpadea; al acabar la cuenta, la fanfarria y la carrera (estado 4, paso 3)
	call demostracion_cartel		;8d5c
	call cuenta_baja		;8d5f   ; la cuenta
	ret nz			;8d62
	call fanfarria		;8d63   ; la fanfarria
	ld (ix+001h),003h		;8d66   ; paso 3...
	ld (ix+000h),004h		;8d6a   ; ...del estado 4: la carrera
	ret			;8d6e
pista:		; La pista (0xE06C): 1 la monta, 2 la hace correr
	ld ix,0e06ch		;8d6f
	ld a,(ix+000h)		;8d73
	call salta_tabla		;8d76

; ----------------------------------------------------------------------
; DATOS pasos_pista: Los dos pasos: montar y correr
;   0x8d79..0x8d7d  (4 bytes)
DATA_pasos_pista:
	defw 08d7dh,090f9h	; 8d79  -> pista_monta pista_corre

; ======================================================================
; CODIGO 0x8d7d..0x8da3  (38 bytes)
; ======================================================================


pista_monta:		; La pista de la carrera: los colores, los obstaculos, el cartel de arriba, los arbustos y los carteles de la distancia
	ld hl,00060h		;8d7d   ; la velocidad de la pista: 0x60
	ld (0e06dh),hl		;8d80
	xor a			;8d83
	ld (0e06fh),a		;8d84
	ld a,005h		;8d87   ; cada 5 pasos, una casilla
	ld (0e070h),a		;8d89
	call carrera_tipo		;8d8c   ; la carrera de la tabla 0x8DA3
	call pista_pinta		;8d8f
	ld (ix+000h),000h		;8d92   ; montada
	ret			;8d96
carrera_tipo:		; El byte de la carrera en 0x8DA3: bit 7 hierba, bits 4-6 los obstaculos, bits 0-3 la distancia
	ld hl,(0e000h)		;8d97
	ld h,000h		;8d9a   ; la carrera...
	dec l			;8d9c   ; ...menos 1
	ld de,08da3h		;8d9d   ; en la tabla
	add hl,de			;8da0
	ld a,(hl)			;8da1
	ret			;8da2

; ----------------------------------------------------------------------
; DATOS carreras: Las nueve carreras: bit 7 hierba (si no, tierra), bits 4-6
;   la serie de obstaculos (0x8E5A), bits 0-3 la distancia (0x9017)
;   0x8da3..0x8dac  (9 bytes)
DATA_carreras:
	defb 080h,011h,0a2h,081h,032h,0c1h,082h,053h,064h	; 8da3  ....2..Sd

; ======================================================================
; CODIGO 0x8dac..0x8e29  (125 bytes)
; ======================================================================


pista_pinta:		; Los colores, los obstaculos, el cartel, la salida y la pista entera a la VRAM
	push af			;8dac
	call pista_colores		;8dad   ; los colores de la hierba o de la tierra
	pop af			;8db0
	push af			;8db1
	call pista_serie		;8db2   ; la serie de obstaculos
	pop af			;8db5
	push af			;8db6
	call cartel_carrera		;8db7   ; el cartel de la carrera
	pop af			;8dba
	push af			;8dbb
	call pista_salida		;8dbc   ; la salida y la pista en la RAM
	pop af			;8dbf
	call pista_vram		;8dc0   ; a la VRAM
	ret			;8dc3
pista_colores:		; Los colores de las casillas del suelo: los de la hierba (0x85EE) o los de la tierra (0x8E29)
	push af			;8dc4
	ld hl,085eeh		;8dc5   ; la hierba...
	and 080h		;8dc8
	jp nz,L_8DD0		;8dca
	ld hl,08e29h		;8dcd   ; ...o la tierra
L_8DD0:
	ld de,0e800h		;8dd0   ; la lista de colores...
	call colores_lista		;8dd3
	ld hl,0e800h		;8dd6   ; ...a los tres tercios desde la casilla 0xC1
	ld de,02608h		;8dd9
	ld bc,00160h		;8ddc
	call vram_tres		;8ddf
	pop af			;8de2
	push af			;8de3
	and 080h		;8de4
	ld hl,0bc8dh		;8de6   ; los colores de las cosas sueltas: los de la hierba (0xBC8D)...
	jr nz,L_8DEE		;8de9
	ld hl,0bcf5h		;8deb   ; ...o los de la tierra (0xBCF5)...
L_8DEE:
	ld de,0e800h		;8dee
	ld bc,00040h		;8df1
	ldir		;8df4
	ld hl,0e800h		;8df6   ; ...a las casillas 0x13-0x1A
	ld de,02098h		;8df9
	ld bc,00040h		;8dfc
	call vram_tres		;8dff
	pop af			;8e02
	push af			;8e03
	and 080h		;8e04
	ld a,013h		;8e06   ; las letras sobre el suelo: negro sobre verde (0x13) o sobre rojo (0x19)...
	jr nz,L_8E0C		;8e08
	ld a,019h		;8e0a
L_8E0C:
	ld hl,02980h		;8e0c   ; ...las casillas 0x30-0x5F del tercio de en medio
	ld bc,00180h		;8e0f
	call 00056h		;8e12
	pop af			;8e15
	and 080h		;8e16
	ld a,033h		;8e18   ; la casilla 0 del primer tercio, del color del suelo: 0x33 o 0x99
	jp nz,L_8E1F		;8e1a
	ld a,099h		;8e1d
L_8E1F:
	ld bc,00008h		;8e1f
	ld hl,02000h		;8e22
	call 00056h		;8e25
	ret			;8e28

; ----------------------------------------------------------------------
; DATOS colores_tierra: Los colores de las casillas de la carrera de tierra:
;   parejas (color, cuantas casillas)
;   0x8e29..0x8e49  (32 bytes)
DATA_colores_tierra:
	defb 09ch,004h	; 8e29
	defb 0c9h,00dh	; 8e2b
	defb 05fh,005h	; 8e2d
	defb 0f6h,001h	; 8e2f
	defb 089h,007h	; 8e31
	defb 005h,001h	; 8e33
	defb 0d9h,002h	; 8e35
	defb 069h,004h	; 8e37
	defb 0e6h,001h	; 8e39
	defb 0e1h,001h	; 8e3b
	defb 081h,001h	; 8e3d
	defb 011h,001h	; 8e3f
	defb 0f9h,001h	; 8e41
	defb 089h,001h	; 8e43
	defb 0f9h,001h	; 8e45
	defb 000h,000h	; 8e47

; ======================================================================
; CODIGO 0x8e49..0x8e5a  (17 bytes)
; ======================================================================


pista_serie:		; La serie de obstaculos: 0x8E5A + (bits 4-6) x 12
	and 070h		;8e49   ; los bits 4-6: la serie x 16...
	rrca			;8e4b
	ld c,a			;8e4c   ; ...C = x 8...
	rrca			;8e4d
	add a,c			;8e4e   ; ...x 8 + x 4 = x 12
	ld c,a			;8e4f
	ld b,000h		;8e50
	ld hl,08e5ah		;8e52
	add hl,bc			;8e55
	ld (0e072h),hl		;8e56   ; en 0xE072
	ret			;8e59

; ----------------------------------------------------------------------
; DATOS series: Las siete series de obstaculos: doce bytes, uno por cada 16
;   pasos de la pista, con la fila de 0x933D que toca
;   0x8e5a..0x8eae  (84 bytes)
DATA_series:
	defb 00ah,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8e5a  ............
	defb 002h,003h,004h,001h,000h,000h,000h,000h,000h,000h,000h,000h	; 8e66  ............
	defb 002h,005h,003h,004h,005h,001h,000h,000h,000h,000h,000h,000h	; 8e72  ............
	defb 002h,007h,009h,008h,006h,001h,000h,000h,000h,000h,000h,000h	; 8e7e  ............
	defb 002h,009h,009h,001h,000h,000h,000h,000h,000h,000h,000h,000h	; 8e8a  ............
	defb 002h,006h,008h,009h,008h,006h,007h,001h,000h,000h,000h,000h	; 8e96  ............
	defb 002h,003h,008h,007h,008h,006h,008h,004h,001h,000h,000h,000h	; 8ea2  ............

; ======================================================================
; CODIGO 0x8eae..0x8edc  (46 bytes)
; ======================================================================


cartel_carrera:		; El cartel de la carrera arriba a la derecha (n RACE, GRASS o DIRT, la distancia): 5 filas de 4 casillas de 0x8EDC
	ld hl,(0e000h)		;8eae   ; la carrera...
	ld h,000h		;8eb1
	dec l			;8eb3   ; ...menos 1...
	add hl,hl			;8eb4   ; la carrera x 20
	add hl,hl			;8eb5   ; ...x 4...
	push hl			;8eb6
	add hl,hl			;8eb7   ; ...x 16...
	add hl,hl			;8eb8
	pop de			;8eb9
	add hl,de			;8eba   ; ...x 4 + x 16 = x 20
	ld de,08edch		;8ebb   ; los carteles
	add hl,de			;8ebe
	ld de,01839h		;8ebf   ; en la columna 25
	ld b,005h		;8ec2   ; cinco filas
cartel_carrera_fila:		; Una fila
	push bc			;8ec4
	push hl			;8ec5
	push de			;8ec6
	ld bc,00004h		;8ec7   ; cuatro casillas...
	call 0005ch		;8eca   ; ...LDIRVM
	pop de			;8ecd
	ld hl,00020h		;8ece   ; la fila siguiente de la pantalla...
	add hl,de			;8ed1
	ex de,hl			;8ed2
	pop hl			;8ed3
	ld bc,00004h		;8ed4   ; ...y del cartel
	add hl,bc			;8ed7
	pop bc			;8ed8
	djnz cartel_carrera_fila		;8ed9   ; las cinco
	ret			;8edb

; ----------------------------------------------------------------------
; DATOS carteles_carrera: Los carteles de las nueve carreras: 5 filas de 4
;   casillas cada uno
;   0x8edc..0x8f90  (180 bytes)
DATA_carteles_carrera:
	defb 000h,0eah,000h,000h	; 8edc
	defb 0a1h,0abh,0ach,0adh	; 8ee0
	defb 0b2h,0b3h,0b4h,0b5h	; 8ee4
	defb 000h,000h,0ebh,000h	; 8ee8
	defb 0b6h,0b7h,0b8h,0d6h	; 8eec
	defb 0ech,000h,000h,000h	; 8ef0
	defb 0a2h,0abh,0ach,0adh	; 8ef4
	defb 0aeh,0afh,0b0h,0b1h	; 8ef8
	defb 000h,000h,0ebh,000h	; 8efc
	defb 0b9h,0bah,0b8h,0d6h	; 8f00
	defb 000h,000h,000h,000h	; 8f04
	defb 0a3h,0abh,0ach,0adh	; 8f08
	defb 0b2h,0b3h,0b4h,0b5h	; 8f0c
	defb 000h,0eah,0ebh,000h	; 8f10
	defb 0bbh,0bch,0b8h,0d6h	; 8f14
	defb 0ech,000h,000h,000h	; 8f18
	defb 0a4h,0abh,0ach,0adh	; 8f1c
	defb 0b2h,0b3h,0b4h,0b5h	; 8f20
	defb 000h,000h,0ebh,000h	; 8f24
	defb 0b9h,0bah,0b8h,0d6h	; 8f28
	defb 000h,000h,000h,000h	; 8f2c
	defb 0a5h,0abh,0ach,0adh	; 8f30
	defb 0aeh,0afh,0b0h,0b1h	; 8f34
	defb 000h,0eah,0ebh,000h	; 8f38
	defb 0bbh,0bch,0b8h,0d6h	; 8f3c
	defb 0ech,000h,000h,000h	; 8f40
	defb 0a6h,0abh,0ach,0adh	; 8f44
	defb 0b2h,0b3h,0b4h,0b5h	; 8f48
	defb 000h,000h,0ebh,000h	; 8f4c
	defb 0b9h,0bah,0b8h,0d6h	; 8f50
	defb 000h,000h,000h,000h	; 8f54
	defb 0a7h,0abh,0ach,0adh	; 8f58
	defb 0b2h,0b3h,0b4h,0b5h	; 8f5c
	defb 000h,0eah,0ebh,000h	; 8f60
	defb 0bbh,0bch,0b8h,0d6h	; 8f64
	defb 000h,000h,000h,0eah	; 8f68
	defb 0a8h,0abh,0ach,0adh	; 8f6c
	defb 0aeh,0afh,0b0h,0b1h	; 8f70
	defb 000h,000h,0ebh,000h	; 8f74
	defb 0bdh,0beh,0b8h,0d6h	; 8f78
	defb 000h,0eah,000h,000h	; 8f7c
	defb 0a9h,0abh,0ach,0adh	; 8f80
	defb 0aeh,0afh,0b0h,0b1h	; 8f84
	defb 000h,000h,0ebh,000h	; 8f88
	defb 0bfh,0c0h,0b8h,0d6h	; 8f8c

; ======================================================================
; CODIGO 0x8f90..0x9012  (130 bytes)
; ======================================================================


pista_salida:		; La pista desde la salida: la distancia, el fondo al azar, los arbustos y las primeras columnas
	and 00fh		;8f90   ; la distancia de la tabla 0x9017...
	ld e,a			;8f92   ; la distancia...
	ld d,000h		;8f93
	ld hl,09017h		;8f95   ; ...por la tabla 0x9017
	add hl,de			;8f98
	ld a,(hl)			;8f99
	ld (0e071h),a		;8f9a   ; ...lo que queda de carrera
	ld (0e060h),a		;8f9d   ; y el paso de la columna que se pinta
	ld hl,0ed60h		;8fa0   ; el suelo de la pista (12 filas) con casillas al azar
	ld bc,00180h		;8fa3   ; 12 filas de 32
	call suelo_azar		;8fa6
	ld hl,0ef8fh		;8fa9   ; y el de la columna que entra
	ld bc,0003ch		;8fac   ; 12 filas de 5
	call suelo_azar		;8faf
	ld a,(0e060h)		;8fb2   ; los arbustos de la salida
	call arbustos		;8fb5   ; el arbusto o el cartel del paso...
	call arbustos_entran		;8fb8   ; ...en la columna que entra
	ld bc,0ed00h		;8fbb   ; las seis columnas de cinco casillas de la pista
	ld a,006h		;8fbe   ; seis columnas
	ld (0e061h),a		;8fc0
pista_salida_col:		; Una columna
	ld hl,0e060h		;8fc3   ; el paso siguiente
	inc (hl)			;8fc6
	ld a,(hl)			;8fc7
	push bc			;8fc8
	call arbustos		;8fc9   ; su arbusto
	pop bc			;8fcc
	push bc			;8fcd
	call arbustos_pon		;8fce   ; en la columna BC
	pop bc			;8fd1
	ld hl,00005h		;8fd2   ; cinco casillas mas a la derecha
	add hl,bc			;8fd5
	push hl			;8fd6
	pop bc			;8fd7
	ld hl,0e061h		;8fd8   ; una columna menos
	dec (hl)			;8fdb
	jp nz,pista_salida_col		;8fdc
	ld hl,0e060h		;8fdf   ; la ultima, mas estrecha
	inc (hl)			;8fe2   ; el paso siguiente
	ld a,(hl)			;8fe3
	push bc			;8fe4
	call arbustos		;8fe5   ; su arbusto
	pop bc			;8fe8
	call arbustos_estrecho		;8fe9   ; las dos ultimas casillas
	ld hl,09012h		;8fec   ; el borde de la columna que entra
	ld de,0efcbh		;8fef   ; en la columna que entra, el borde
	ld bc,00005h		;8ff2
	ldir		;8ff5
	ld hl,0eee0h		;8ff7   ; la valla de abajo: 0xE0, 0xE1...
	ld b,010h		;8ffa   ; 16 parejas
pista_valla:		; ...16 veces
	ld (hl),0e0h		;8ffc   ; la valla: 0xE0...
	inc hl			;8ffe
	ld (hl),0e1h		;8fff   ; ...y 0xE1
	inc hl			;9001
	djnz pista_valla		;9002
	ld hl,0ed76h		;9004   ; la linea de la salida (0xEA) en las 12 filas
	ld b,00ch		;9007   ; 12 filas
pista_linea:		; Una fila
	ld (hl),0eah		;9009   ; la linea de la salida
	ld de,00020h		;900b   ; la fila siguiente
	add hl,de			;900e
	djnz pista_linea		;900f
	ret			;9011

; ----------------------------------------------------------------------
; DATOS pista_borde: La columna de la valla (0xE0, 0xE1) y las cinco
;   distancias: lo que queda de carrera (de 25 m en 25 m) para 1200, 1600,
;   2400, 3200 y 3600 m
;   0x9012..0x901c  (10 bytes)
DATA_pista_borde:
	defb 0e0h,0e1h,0e0h,0e1h,0e0h	; 9012
	defb 02bh,03bh,05bh,07bh,08bh	; 9017

; ======================================================================
; CODIGO 0x901c..0x91b2  (406 bytes)
; ======================================================================


suelo_azar:		; BC casillas desde HL: el suelo, una de 0xE2-0xE5 al azar
	call azar		;901c
	and 003h		;901f   ; una de cuatro...
	add a,0e2h		;9021   ; ...de 0xE2 a 0xE5
	ld (hl),a			;9023
	inc hl			;9024
	dec bc			;9025   ; una menos
	ld a,b			;9026
	or c			;9027
	jp nz,suelo_azar		;9028
	ret			;902b
arbustos:		; Los arbustos del paso A de la pista: el nibble de 0x92DD; de 0 a 3 el tipo de arbusto (0x93ED), 4 o mas un cartel de distancia (0x942D); A = 1 si hay cartel
	cp 060h		;902c   ; la segunda mitad?
	ld b,000h		;902e
	jr c,L_9035		;9030
	inc b			;9032
	sub 060h		;9033
L_9035:
	ld hl,092ddh		;9035   ; el nibble del paso
	ld e,a			;9038   ; el paso, en la tabla
	ld d,000h		;9039
	add hl,de			;903b
	ld a,(hl)			;903c   ; el byte...
	bit 0,b		;903d   ; ...la mitad baja o alta
	jr z,arbustos_tipo		;903f
	rrca			;9041
	rrca			;9042
	rrca			;9043
	rrca			;9044
arbustos_tipo:		; El nibble
	and 00fh		;9045
	ld c,a			;9047   ; el nibble
	cp 004h		;9048   ; un cartel?
	jr c,arbustos_dibujo		;904a   ; un arbusto (0-3)?
	ld a,003h		;904c   ; con cartel: el arbusto 3
arbustos_dibujo:		; La direccion del arbusto
	add a,a			;904e   ; 16 casillas por arbusto
	add a,a			;904f   ; x 16
	add a,a			;9050
	add a,a			;9051
	ld e,a			;9052
	ld d,000h		;9053
	ld hl,093edh		;9055   ; los arbustos
	add hl,de			;9058
	ld a,c			;9059   ; el nibble...
	cp 004h		;905a   ; sin cartel: A = 0
	ld a,000h		;905c   ; ...menos de 4:...
	ret c			;905e   ; ...sin cartel
	dec c			;905f   ; el cartel: 4 casillas...
	dec c			;9060   ; el cartel: el nibble - 4...
	dec c			;9061
	dec c			;9062
	ld a,c			;9063
	add a,a			;9064   ; ...x 4
	add a,a			;9065
	bit 0,b		;9066   ; ...en la segunda mitad de la pista, 12 carteles mas alla (2400, 3200 y 3600 m)
	jr z,arbustos_cartel		;9068   ; la primera mitad?
	add a,030h		;906a   ; la segunda: 12 carteles mas alla
arbustos_cartel:		; La direccion del cartel
	ld c,a			;906c
	ld b,000h		;906d
	ex de,hl			;906f
	ld hl,0942dh		;9070   ; los carteles (0x942D)
	add hl,bc			;9073
	ex de,hl			;9074
	ld a,001h		;9075   ; A = 1: hay cartel
	ret			;9077
arbustos_entran:		; Los arbustos (tres filas de 5) en la columna que entra (0xEF80) y el cartel encima, si lo hay
	push de			;9078   ; los arbustos
	ld de,0ef80h		;9079   ; la fila 0 de la columna que entra
	ld bc,00005h		;907c
	ldir		;907f   ; 5 casillas
	ld de,0ef85h		;9081   ; la fila 1
	ld bc,00005h		;9084
	ldir		;9087
	ld de,0ef8ah		;9089   ; la fila 2
	ld bc,00005h		;908c
	ldir		;908f
	pop hl			;9091   ; HL = el cartel
	and a			;9092   ; hay cartel?
	ret z			;9093
	ld de,0ef86h		;9094   ; encima, en la fila 1...
	ld bc,00004h		;9097   ; ...4 casillas
	ldir		;909a
	ret			;909c
arbustos_pon:		; Lo mismo en la columna BC de la pista montada
	push de			;909d   ; la columna de la pista...
	push bc			;909e
	pop de			;909f   ; ...en DE
	ld bc,00005h		;90a0   ; la fila 0
	ldir		;90a3
	ld bc,0001bh		;90a5   ; la fila siguiente (32 - 5)
	ex de,hl			;90a8
	add hl,bc			;90a9
	ex de,hl			;90aa
	ld bc,00005h		;90ab   ; la fila 1
	ldir		;90ae
	ld bc,0001bh		;90b0
	ex de,hl			;90b3
	add hl,bc			;90b4
	ex de,hl			;90b5
	ld bc,00005h		;90b6   ; la fila 2
	ldir		;90b9
	pop hl			;90bb   ; HL = el cartel
	and a			;90bc   ; hay cartel?
	ret z			;90bd
	ld bc,00024h		;90be   ; de vuelta a la fila 1, una mas a la derecha...
	ex de,hl			;90c1
	sbc hl,bc		;90c2
	ex de,hl			;90c4
	ld bc,00004h		;90c5   ; ...4 casillas
	ldir		;90c8
	ret			;90ca
arbustos_estrecho:		; La ultima columna, de 2 casillas
	push bc			;90cb   ; la columna...
	pop de			;90cc
	ldi		;90cd   ; dos casillas de la fila 0
	ldi		;90cf
	inc hl			;90d1   ; el resto del arbusto, no
	inc hl			;90d2
	inc hl			;90d3
	ld bc,0001eh		;90d4   ; la fila siguiente (32 - 2)
	ex de,hl			;90d7
	add hl,bc			;90d8
	ex de,hl			;90d9
	ldi		;90da   ; la fila 1
	ldi		;90dc
	inc hl			;90de
	inc hl			;90df
	inc hl			;90e0
	ld bc,0001eh		;90e1
	ex de,hl			;90e4
	add hl,bc			;90e5
	ex de,hl			;90e6
	ldi		;90e7   ; la fila 2
	ldi		;90e9
	ret			;90eb
pista_vram:		; La pista montada (0xED00, 16 filas) a la VRAM, desde la fila 6
	ld hl,0ed00h		;90ec   ; la pista montada...
	ld de,018c0h		;90ef   ; ...a la fila 6...
	ld bc,00200h		;90f2   ; ...16 filas (LDIRVM)
	call 0005ch		;90f5
	ret			;90f8
pista_corre:		; Cada cuadro: las fuerzas, la marca de la carrera, y la pista corre segun la velocidad; cada 5 pasos, una casilla nueva
	push ix		;90f9   ; lo de quien llama
	push iy		;90fb
	call fuerzas		;90fd   ; las fuerzas de los caballos
	call plano		;9100   ; los sprites de 0xE1C8 (0xA6E3)
	pop iy		;9103   ; ...
	pop ix		;9105
	ld hl,0e06dh		;9107   ; la velocidad...
	call suma_paso		;910a   ; ...suma la cuenta de la pista
	ld hl,0e06fh		;910d   ; los octavos de casilla...
	ld c,(hl)			;9110   ; la cuenta (los dieciseisavos)...
	add a,c			;9111   ; ...mas lo de este cuadro
	ld c,a			;9112
	and 00fh		;9113   ; lo que queda
	ld (hl),a			;9115
	ld a,c			;9116   ; lo que pasa de 16
	and 0f0h		;9117   ; ...una casilla entera?
	ret z			;9119   ; nada: la pista no corre
	ld hl,0eeffh		;911a   ; la pista, una casilla a la derecha (512 bytes)
	ld de,0ef00h		;911d   ; de la ultima fila hacia atras...
	ld bc,00200h		;9120   ; ...512 bytes
	lddr		;9123   ; todo un byte a la derecha
	ld b,010h		;9125   ; la columna que entra a la izquierda: 16 filas
	ld hl,0ed00h		;9127   ; la columna 0
	ld de,0ef84h		;912a   ; la columna que entra, desde la fila 0, casilla 4
pista_entra:		; Una fila
	ld a,(de)			;912d   ; una casilla de la columna que entra...
	ld (hl),a			;912e   ; ...en la columna 0
	push bc			;912f
	ld bc,00020h		;9130   ; la fila siguiente
	add hl,bc			;9133
	ex de,hl			;9134
	ld bc,00005h		;9135   ; en la columna que entra, 5 mas
	add hl,bc			;9138
	ex de,hl			;9139
	pop bc			;913a
	djnz pista_entra		;913b   ; 16 filas
	ld hl,0efd4h		;913d   ; la columna de los arbustos, una tambien
	ld de,0efd5h		;9140   ; (0xEF80-0xEFD5)
	ld bc,00055h		;9143
	lddr		;9146   ; todo un byte mas alla
	call pista_vram		;9148   ; a la VRAM
	ld hl,0e070h		;914b   ; cada 5 casillas...
	dec (hl)			;914e   ; un paso de los cinco
	ret nz			;914f
	ld (hl),005h		;9150   ; otra vez 5
	ld hl,0e071h		;9152   ; ...un paso menos de carrera
	dec (hl)			;9155   ; un paso de carrera menos
	ld a,(hl)			;9156
	cp 0ffh		;9157   ; pasa de 0...
	jp nz,pista_paso		;9159   ; no llega a 0
	ld (hl),0bfh		;915c   ; ...a 0xBF (la recta de la meta)
pista_paso:		; Los arbustos y los obstaculos del paso nuevo; si es el 0xBB, la pista se para
	call pista_columna		;915e   ; la columna del paso
	ld a,(0e071h)		;9161   ; el paso...
	cp 0bbh		;9164   ; el ultimo paso
	ret nz			;9166   ; ...no es el ultimo
	xor a			;9167   ; la pista se para...
	ld (0e06dh),a		;9168   ; velocidad 0
	ld (ix+000h),000h		;916b   ; ...y queda quieta
	ret			;916f
pista_columna:		; Los arbustos y el obstaculo del paso en la columna que entra
	ld a,(0e071h)		;9170
	call arbustos		;9173   ; el arbusto del paso...
	call arbustos_entran		;9176   ; ...en la columna que entra
	ld a,(0e071h)		;9179
	call obstaculo		;917c   ; el obstaculo del paso...
	call obstaculo_pon		;917f   ; ...en la columna
	ret			;9182
obstaculo:		; El obstaculo del paso A: la fila de la serie (0xE072) que toca a los 16 pasos y su columna en 0x933D
	ld c,a			;9183   ; el paso
	rrca			;9184   ; los 16 pasos...
	rrca			;9185   ; los 16 pasos (el nibble alto)...
	rrca			;9186
	rrca			;9187
	and 00fh		;9188
	ld e,a			;918a   ; ...en la serie
	ld d,000h		;918b
	ld hl,(0e072h)		;918d   ; ...en la serie: la fila...
	add hl,de			;9190
	ld a,(hl)			;9191   ; la fila de 0x933D...
	add a,a			;9192   ; ...de 16 bytes
	add a,a			;9193   ; ...x 16
	add a,a			;9194
	add a,a			;9195
	ld e,a			;9196
	ld d,000h		;9197
	ld hl,0933dh		;9199   ; la fila
	add hl,de			;919c
	ld a,c			;919d   ; el paso dentro de la fila
	and 00fh		;919e   ; el paso dentro de la fila
	ld c,a			;91a0
	ld b,000h		;91a1
	add hl,bc			;91a3
	ld a,(hl)			;91a4   ; el obstaculo
	ret			;91a5
obstaculo_pon:		; La columna sin obstaculo y, si lo hay (1 la meta, 2 una valla, 3 una ria, 4 las dos, 5 cosas sueltas), lo pinta
	push af			;91a6
	call columna_limpia		;91a7   ; el suelo y el borde
	pop af			;91aa
	and a			;91ab
	ret z			;91ac
	and 007h		;91ad   ; el tipo...
	call salta_tabla		;91af   ; ...por la tabla

; ----------------------------------------------------------------------
; DATOS tabla_obstaculos: Los cinco obstaculos: la meta, la valla, la ria, la
;   ria y la valla, y las cosas sueltas
;   0x91b2..0x91bc  (10 bytes)
DATA_tabla_obstaculos:
	defw 091bch,091edh,09208h,09251h,09258h	; 91b2

; ======================================================================
; CODIGO 0x91bc..0x91c9  (13 bytes)
; ======================================================================


obstaculo_meta:		; La meta: GOAL en vertical, 3 casillas por 12 filas (0x91C9)
	ld hl,091c9h		;91bc
	ld de,0ef90h		;91bf
	ld bc,0030ch		;91c2
	call copia_columna		;91c5
	ret			;91c8

; ----------------------------------------------------------------------
; DATOS dibujo_meta: La meta: 12 filas de 3 casillas, con G, O, A y L
;   0x91c9..0x91ed  (36 bytes)
DATA_dibujo_meta:
	defb 0e3h,0e3h,0ebh	; 91c9
	defb 0e3h,0e3h,0ebh	; 91cc
	defb 0e3h,0e3h,0ebh	; 91cf
	defb 0d8h,0dch,0ebh	; 91d2
	defb 0e4h,0e4h,0ebh	; 91d5
	defb 0d9h,0ddh,0ebh	; 91d8
	defb 0e5h,0e5h,0ebh	; 91db
	defb 0dah,0deh,0ebh	; 91de
	defb 0e5h,0e5h,0ebh	; 91e1
	defb 0dbh,0deh,0ebh	; 91e4
	defb 0e4h,0e4h,0ebh	; 91e7
	defb 0e4h,0e4h,0ebh	; 91ea

; ======================================================================
; CODIGO 0x91ed..0x91fa  (13 bytes)
; ======================================================================


obstaculo_valla:		; La valla: un poste a rayas de 13 casillas (0x91FA)
	ld hl,091fah		;91ed
	ld de,0ef8eh		;91f0
	ld bc,0010dh		;91f3
	call copia_columna		;91f6
	ret			;91f9

; ----------------------------------------------------------------------
; DATOS dibujo_valla: La valla: 13 casillas en una columna
;   0x91fa..0x9208  (14 bytes)
DATA_dibujo_valla:
	defb 0e6h,0e7h,0e7h,0e8h,0e7h,0e7h,0e8h,0e7h,0e7h,0e8h,0e7h,0e7h,0e9h,0e0h	; 91fa  ..............

; ======================================================================
; CODIGO 0x9208..0x9215  (13 bytes)
; ======================================================================


obstaculo_ria:		; La ria: 5 casillas por 12 filas (0x9215)
	ld hl,09215h		;9208
	ld de,0ef8fh		;920b
	ld bc,0050ch		;920e
	call copia_columna		;9211
	ret			;9214

; ----------------------------------------------------------------------
; DATOS dibujo_ria: La ria: 12 filas de 5 casillas
;   0x9215..0x9251  (60 bytes)
DATA_dibujo_ria:
	defb 0eah,01bh,01bh,01bh,0ech	; 9215
	defb 0eah,01dh,01eh,01ch,0ech	; 921a
	defb 0eah,01ch,01ch,01dh,0ech	; 921f
	defb 0eah,01eh,01ch,01ch,0ech	; 9224
	defb 0eah,01ch,01dh,01eh,0ech	; 9229
	defb 0eah,01ch,01ch,01dh,0ech	; 922e
	defb 0eah,01dh,01eh,01ch,0ech	; 9233
	defb 0eah,01ch,01ch,01dh,0ech	; 9238
	defb 0eah,01ch,01dh,01eh,0ech	; 923d
	defb 0eah,01dh,01ch,01dh,0ech	; 9242
	defb 0eah,01dh,01eh,01dh,0ech	; 9247
	defb 0eah,01dh,01ch,01dh,0ech	; 924c

; ======================================================================
; CODIGO 0x9251..0x9295  (68 bytes)
; ======================================================================


obstaculo_ria_valla:		; La ria con la valla
	call obstaculo_ria		;9251
	call obstaculo_valla		;9254
	ret			;9257
obstaculo_sueltas:		; Dos cosas sueltas al azar en la pista (solo en las carreras pares)
	ld a,(0e000h)		;9258   ; una carrera impar?
	bit 0,a		;925b
	ret nz			;925d
	call obstaculo_suelta		;925e
	call obstaculo_suelta		;9261
	ret			;9264
obstaculo_suelta:		; Una: el sitio (0x929D) y el dibujo (0x92AD) al azar
	call azar		;9265   ; uno de los ocho sitios...
	and 007h		;9268   ; uno de ocho
	add a,a			;926a
	ld c,a			;926b   ; x 2
	ld b,000h		;926c
	ld hl,0929dh		;926e   ; los sitios
	add hl,bc			;9271
	ld e,(hl)			;9272   ; DE = el sitio
	inc hl			;9273
	ld d,(hl)			;9274
	call azar		;9275   ; ...uno de los cuatro dibujos
	and 003h		;9278   ; uno de cuatro
	add a,a			;927a
	ld c,a			;927b   ; x 2
	ld b,000h		;927c
	ld hl,092adh		;927e   ; los dibujos
	add hl,bc			;9281
	push hl			;9282   ; HL = el dibujo
	call azar		;9283   ; se pone? (0x9295)
	ld hl,09295h		;9286   ; los umbrales
	call tabla_umbral		;9289
	pop hl			;928c
	and a			;928d   ; se pone?
	ret z			;928e
	ld bc,00002h		;928f   ; dos casillas
	ldir		;9292
	ret			;9294

; ----------------------------------------------------------------------
; DATOS sueltas: Los umbrales y si se pone (siempre), los ocho sitios de la
;   columna y los cuatro dibujos de dos casillas (0x13-0x1A)
;   0x9295..0x92b5  (32 bytes)
DATA_sueltas:
	defb 000h,030h,060h,080h	; 9295
	defb 001h,001h,001h,001h	; 9299
	defw 0ef94h,0ef9ch,0efa4h,0efafh,0efb7h,0efbfh,0efc2h,0efc9h	; 929d
	defb 013h,014h	; 92ad
	defb 015h,016h	; 92af
	defb 017h,018h	; 92b1
	defb 019h,01ah	; 92b3

; ======================================================================
; CODIGO 0x92b5..0x92dd  (40 bytes)
; ======================================================================


copia_columna:		; Copia C filas de B bytes desde HL a DE, que es la columna de 5 de ancho
	push bc			;92b5   ; C filas
	push de			;92b6
	ld c,b			;92b7   ; B casillas
	ld b,000h		;92b8
	ldir		;92ba   ; una fila
	pop de			;92bc
	push hl			;92bd
	ld hl,00005h		;92be   ; la fila siguiente, 5 mas alla
	add hl,de			;92c1
	ex de,hl			;92c2
	pop hl			;92c3
	pop bc			;92c4
	dec c			;92c5   ; todas
	jp nz,copia_columna		;92c6
	ret			;92c9
columna_limpia:		; La columna que entra: el suelo al azar y el borde
	ld hl,0ef8fh		;92ca   ; la columna que entra, desde la fila 3
	ld bc,0003ch		;92cd   ; 12 filas de 5...
	call suelo_azar		;92d0   ; ...el suelo al azar
	ex de,hl			;92d3
	ld hl,09012h		;92d4   ; el borde (0x9012)
	ld bc,00005h		;92d7
	ldir		;92da
	ret			;92dc

; ----------------------------------------------------------------------
; DATOS tabla_arbustos: Los arbustos y carteles de los 192 pasos de la pista:
;   un nibble por paso
;   0x92dd..0x933d  (96 bytes)
DATA_tabla_arbustos:
	defb 040h,011h,022h,011h,014h,022h,022h,011h,015h,022h,022h,011h,016h,022h,011h,011h	; 92dd  @.".."".."".."..
	defb 037h,022h,011h,022h,028h,011h,022h,022h,039h,022h,011h,022h,02ah,011h,011h,022h	; 92ed  7"."(.""9"."*.."
	defb 05bh,022h,022h,011h,02ch,011h,022h,011h,023h,022h,022h,011h,022h,011h,022h,022h	; 92fd  ["".,.".#"".".""
	defb 06dh,011h,022h,022h,011h,022h,011h,022h,033h,011h,022h,022h,011h,011h,022h,011h	; 930d  m.""."."3.""..".
	defb 03eh,011h,022h,011h,022h,022h,011h,022h,033h,011h,022h,022h,011h,022h,022h,011h	; 931d  >.".""."3.""."".
	defb 033h,011h,022h,022h,011h,022h,011h,022h,033h,022h,022h,011h,022h,011h,022h,011h	; 932d  3.""."."3"".".".

; ----------------------------------------------------------------------
; DATOS tabla_obstaculos_filas: Las once filas de obstaculos de 16 pasos: 0
;   nada, 1 la meta, 2 la valla, 3 la ria, 4 las dos, 5 cosas sueltas
;   0x933d..0x93ed  (176 bytes)
DATA_tabla_obstaculos_filas:
	defb 000h,005h,000h,000h,005h,000h,000h,000h,000h,000h,005h,000h,000h,005h,000h,000h	; 933d  ................
	defb 000h,005h,000h,005h,000h,000h,000h,002h,000h,000h,005h,000h,000h,000h,000h,000h	; 934d  ................
	defb 001h,000h,000h,000h,005h,000h,000h,003h,000h,000h,005h,000h,000h,005h,000h,000h	; 935d  ................
	defb 000h,000h,000h,005h,000h,000h,000h,002h,000h,000h,000h,000h,005h,000h,005h,000h	; 936d  ................
	defb 000h,000h,005h,000h,005h,000h,000h,000h,003h,000h,000h,005h,000h,000h,005h,000h	; 937d  ................
	defb 000h,005h,000h,000h,005h,000h,000h,000h,004h,000h,000h,000h,005h,000h,000h,005h	; 938d  ................
	defb 000h,000h,005h,000h,002h,000h,005h,000h,000h,000h,005h,000h,002h,000h,000h,005h	; 939d  ................
	defb 000h,000h,005h,000h,003h,000h,005h,000h,005h,000h,005h,000h,003h,000h,005h,000h	; 93ad  ................
	defb 000h,005h,005h,000h,004h,000h,005h,000h,005h,000h,005h,000h,004h,000h,005h,005h	; 93bd  ................
	defb 000h,005h,005h,000h,003h,000h,005h,000h,004h,000h,005h,000h,002h,000h,005h,000h	; 93cd  ................
	defb 001h,000h,000h,005h,000h,000h,005h,000h,005h,000h,005h,000h,000h,005h,000h,000h	; 93dd  ................

; ----------------------------------------------------------------------
; DATOS dibujos_arbustos: Los cuatro arbustos: 3 filas de 5 casillas (y una de
;   relleno)
;   0x93ed..0x942d  (64 bytes)
DATA_dibujos_arbustos:
	defb 0edh,0edh,01fh,0edh,0edh,0edh,0edh,0e9h,0edh,0edh,0edh,0edh,0e9h,0edh,0edh,000h	; 93ed  ................
	defb 0edh,0edh,0edh,0edh,0edh,0edh,001h,003h,005h,007h,0edh,002h,004h,006h,008h,000h	; 93fd  ................
	defb 0edh,0edh,0edh,0edh,0edh,009h,00bh,00dh,00fh,011h,00ah,00ch,00eh,010h,012h,000h	; 940d  ................
	defb 0edh,0edh,0edh,0edh,0edh,0edh,0d2h,0d3h,0d4h,0d5h,0edh,0d7h,0d7h,0d7h,0d7h,000h	; 941d  ................

; ----------------------------------------------------------------------
; DATOS dibujos_carteles: Los carteles de distancia: 100 m a 900 m y los de la
;   salida (1200, 1600, 2400, 3200 y 3600 m), 4 casillas cada uno
;   0x942d..0x9469  (60 bytes)
DATA_dibujos_carteles:
	defb 071h,070h,070h,0d6h	; 942d
	defb 072h,070h,070h,0d6h	; 9431
	defb 073h,070h,070h,0d6h	; 9435
	defb 074h,070h,070h,0d6h	; 9439
	defb 075h,070h,070h,0d6h	; 943d
	defb 076h,070h,070h,0d6h	; 9441
	defb 077h,070h,070h,0d6h	; 9445
	defb 078h,070h,070h,0d6h	; 9449
	defb 079h,070h,070h,0d6h	; 944d
	defb 0b6h,0b7h,0b8h,0d6h	; 9451
	defb 0b9h,0bah,0b8h,0d6h	; 9455
	defb 000h,000h,000h,000h	; 9459
	defb 0bbh,0bch,0b8h,0d6h	; 945d
	defb 0bdh,0beh,0b8h,0d6h	; 9461
	defb 0bfh,0c0h,0b8h,0d6h	; 9465

; ======================================================================
; CODIGO 0x9469..0x9507  (158 bytes)
; ======================================================================


mandos:		; Los mandos: la palanca (0xE003, un bit por direccion), el boton 1 (0xE004) y el boton 2 (0xE005); lo recien pulsado en 0xE009-0xE00B
	ld hl,0e003h		;9469   ; los de este cuadro pasan a ser los de antes
	ld de,0e006h		;946c
	ld bc,00003h		;946f
	ldir		;9472
	ld a,001h		;9474   ; la palanca del mando 1...
	call 000d5h		;9476
	and a			;9479
	jr nz,mandos_palanca		;947a
	ld a,002h		;947c   ; ...o la del 2...
	call 000d5h		;947e
	and a			;9481
	jr nz,mandos_palanca		;9482
	ld a,000h		;9484   ; ...o los cursores
	call 000d5h		;9486
mandos_palanca:		; La direccion (0-8) a bits por la tabla 0x9507: 0x20 arriba, 0x40 abajo, 0x10 izquierda, 0x80 derecha
	ld c,a			;9489   ; la direccion...
	ld b,000h		;948a
	ld hl,09507h		;948c   ; ...por la tabla
	add hl,bc			;948f
	ld a,(hl)			;9490
	ld (0e003h),a		;9491   ; los bits
	ld a,001h		;9494   ; el boton 1 del mando 1...
	call 000d8h		;9496
	and a			;9499
	jr nz,mandos_boton2		;949a
	ld a,002h		;949c   ; ...o del 2...
	call 000d8h		;949e
	and a			;94a1
	jr nz,mandos_boton2		;94a2
	ld a,000h		;94a4   ; ...o la barra
	call 000d8h		;94a6
mandos_boton2:		; El boton 2: el de los mandos 1 o 2 (GTTRIG 3 y 4) o GRAPH en el teclado (fila 6, bit 2)
	ld (0e004h),a		;94a9
	ld a,003h		;94ac   ; el boton 2 del mando 1...
	call 000d8h		;94ae
	and a			;94b1
	jr nz,mandos_boton2_pon		;94b2
	ld a,004h		;94b4   ; ...o del 2...
	call 000d8h		;94b6
	and a			;94b9
	jr nz,mandos_boton2_pon		;94ba
	ld a,006h		;94bc   ; ...o la fila 6 del teclado (SNSMAT)...
	call 00141h		;94be
	cpl			;94c1   ; ...GRAPH pulsada?
	and 004h		;94c2
	jr z,mandos_boton2_pon		;94c4
	ld a,0ffh		;94c6
mandos_boton2_pon:		; 0xFF si esta pulsado
	ld (0e005h),a		;94c8
	ld hl,0e003h		;94cb   ; lo recien pulsado: lo de ahora...
	ld de,0e006h		;94ce
	ld ix,0e009h		;94d1
	ld b,003h		;94d5   ; ...de los tres
mandos_nuevo:		; ...y no lo de antes
	ld a,(de)			;94d7
	cpl			;94d8
	ld c,(hl)			;94d9
	and c			;94da
	ld (ix+000h),a		;94db
	inc hl			;94de
	inc de			;94df
	inc ix		;94e0
	djnz mandos_nuevo		;94e2
	ld a,(0e003h)		;94e4   ; la repeticion de la palanca: cuatro cuentas de 32 cuadros (0xE00D), una por direccion
	ld b,004h		;94e7
	ld de,00080h		;94e9   ; el bit de la direccion
	ld hl,0e00dh		;94ec
mandos_repite:		; Si no se pulsa, la cuenta vuelve a 32; si llega a 0, la direccion cuenta como pulsada y la cuenta se queda en 1
	add a,a			;94ef
	jr c,mandos_cuenta		;94f0
	ld (hl),020h		;94f2   ; suelta: la cuenta a 32
mandos_cuenta:		; Un cuadro menos
	dec (hl)			;94f4
	jr nz,mandos_sig		;94f5
	inc (hl)			;94f7   ; a 0: se queda en 1...
	push af			;94f8
	ld a,d			;94f9   ; ...y la direccion cuenta
	or e			;94fa
	ld d,a			;94fb
	pop af			;94fc
mandos_sig:		; La direccion siguiente
	inc hl			;94fd
	srl e		;94fe
	djnz mandos_repite		;9500
	ld a,d			;9502   ; la palanca con repeticion
	ld (0e00ch),a		;9503
	ret			;9506

; ----------------------------------------------------------------------
; DATOS palanca_bits: GTSTCK (0-8) a bits: nada, arriba, arriba-derecha,
;   derecha, abajo-derecha, abajo, abajo-izquierda, izquierda,
;   arriba-izquierda
;   0x9507..0x9510  (9 bytes)
DATA_palanca_bits:
	defb 000h,020h,0a0h,080h,0c0h,040h,050h,010h,030h	; 9507  . ...@P.0

; ======================================================================
; CODIGO 0x9510..0x961f  (271 bytes)
; ======================================================================


cuotas_pinta:		; Las seis cuotas (0xE011, BCD) en la fila 1, debajo de 1-2, 1-3, 1-4, 2-3, 2-4 y 3-4; el 0 de la izquierda, en blanco
	ld hl,01825h		;9510   ; la fila 1, columna 5
	ld de,0e011h		;9513
	ld b,006h		;9516   ; seis cuotas
cuotas_una:		; Una: las decenas...
	ld a,(de)			;9518
	rrca			;9519
	rrca			;951a
	rrca			;951b
	rrca			;951c
	and 00fh		;951d
	jr nz,cuotas_cifra		;951f   ; un 0?
	ld a,0dfh		;9521   ; ...en blanco (0xDF)
	jr cuotas_unidades		;9523
cuotas_cifra:		; Las cifras son las casillas 0x60-0x69
	or 060h		;9525
cuotas_unidades:		; ...y las unidades
	call vram_pon		;9527
	inc hl			;952a   ; la columna siguiente
	ld a,(de)			;952b   ; las unidades...
	and 00fh		;952c
	or 060h		;952e   ; ...casilla 0x60 + la cifra
	call vram_pon		;9530
	inc de			;9533   ; la siguiente, tres casillas mas alla
	inc hl			;9534
	inc hl			;9535
	djnz cuotas_una		;9536   ; las seis
	ret			;9538
apuestas_pinta:		; Las apuestas de los jugadores (0xE017, seis por jugador) en el recuadro de arriba: una fila por jugador
	ld hl,01845h		;9539   ; la fila 2
	ld de,0e017h		;953c   ; las apuestas
	ld a,(0e001h)		;953f   ; el modo: el jinete...
	ld b,004h		;9542
	and a			;9544
	ret z			;9545
	cp 0ffh		;9546   ; ...y la demostracion no apuestan
	ret z			;9548
apuestas_fila:		; Un jugador: seis apuestas de dos cifras
	push bc			;9549
	ld b,006h		;954a
apuestas_una:		; Una: las decenas, un 0 en blanco...
	ld a,(de)			;954c   ; las decenas
	rrca			;954d
	rrca			;954e
	rrca			;954f
	rrca			;9550
	and 00fh		;9551
	jr nz,apuestas_decenas		;9553   ; no es 0
	ld a,010h		;9555
apuestas_decenas:		; Las cifras de las apuestas son las casillas 0x80-0x89 (0x90 en blanco)
	or 080h		;9557
	call vram_pon		;9559
	inc hl			;955c
	ld a,(de)			;955d   ; ...las unidades: si no hay apuesta, en blanco
	and a			;955e
	jr nz,apuestas_unidades		;955f
	ld a,010h		;9561
	jr apuestas_cifra		;9563
apuestas_unidades:		; Las unidades
	and 00fh		;9565
apuestas_cifra:		; La cifra
	or 080h		;9567   ; la casilla 0x80 + la cifra
	call vram_pon		;9569
	inc hl			;956c   ; la siguiente, tres casillas mas alla
	inc hl			;956d
	inc de			;956e   ; la apuesta siguiente
	djnz apuestas_una		;956f   ; las seis
	push de			;9571   ; la fila siguiente
	ld de,0000eh		;9572   ; la fila siguiente
	add hl,de			;9575
	pop de			;9576
	pop bc			;9577
	djnz apuestas_fila		;9578   ; los jugadores
	ret			;957a
vram_pon:		; WRTVRM sin tocar HL, DE ni BC
	push hl			;957b
	push de			;957c
	push bc			;957d
	call 0004dh		;957e   ; WRTVRM
	pop bc			;9581
	pop de			;9582
	pop hl			;9583
	ret			;9584
carrera_cuadro:		; La parte de la interrupcion que mueve la carrera: los pasos, la camara, el cansancio, los caballos, los jinetes, la meta y los sonidos
	ld hl,0e07bh		;9585   ; un cuadro mas
	inc (hl)			;9588
	call caballos_pasos		;9589   ; el paso de cada caballo y lo que pide el jugador
	call camara		;958c   ; la velocidad de la pista
	call cansancio		;958f   ; el cansancio
	call caballos		;9592   ; los cuatro caballos
	call jinetes		;9595   ; los cuatro jinetes
	call meta_luz		;9598   ; la luz de la meta
	call sonidos		;959b   ; los sonidos de la carrera
	call marca_puesto		;959e   ; la marca del puesto
	ret			;95a1
caballos_pasos:		; La velocidad de cada caballo (0xE077) por los bits 2-4 de 0xE041 (0x961F); y en 0xE13F lo que hace: el boton 2 salta, arriba y abajo cambian de calle
	ld hl,0e041h		;95a2   ; los cuatro caballos (4 bytes cada uno)
	ld iy,0e13fh		;95a5   ; lo que hace cada uno
	ld de,0e077h		;95a9   ; las velocidades
	ld b,004h		;95ac
caballos_pasos_uno:		; Uno: el byte entero...
	ld a,(hl)			;95ae   ; el byte del caballo
	ld (iy+000h),a		;95af   ; a 0xE13F
	and 01ch		;95b2   ; ...los bits 2-4: el paso
	rrca			;95b4   ; los bits 2-4
	rrca			;95b5
	push de			;95b6
	push hl			;95b7
	ld e,a			;95b8   ; en la tabla
	ld d,000h		;95b9
	ld hl,0961fh		;95bb   ; la velocidad de la tabla
	add hl,de			;95be
	ld a,(hl)			;95bf   ; la velocidad
	pop hl			;95c0
	ld de,00004h		;95c1   ; el caballo siguiente, 4 bytes mas alla
	add hl,de			;95c4
	pop de			;95c5
	ld (de),a			;95c6   ; en 0xE077
	inc de			;95c7   ; la velocidad siguiente
	inc iy		;95c8
	djnz caballos_pasos_uno		;95ca   ; los cuatro
	ld hl,0e13fh		;95cc   ; de lo que hacen, solo los bits 5-7
	ld b,004h		;95cf   ; los cuatro
caballos_hace_limpia:		; Uno
	ld a,(hl)			;95d1
	and 0e0h		;95d2   ; bits 5-7
	ld (hl),a			;95d4
	inc hl			;95d5
	djnz caballos_hace_limpia		;95d6
	ld a,(0e002h)		;95d8   ; el caballo del jugador?
	and a			;95db   ; jinete?
	jr z,caballos_hace_pasa		;95dc
	ld b,000h		;95de
	ld c,a			;95e0
	dec c			;95e1   ; el caballo - 1
	ld hl,0e13fh		;95e2   ; el suyo
	add hl,bc			;95e5
	ld a,(hl)			;95e6   ; solo el bit 5 (el latigo)...
	and 020h		;95e7   ; el latigo...
	ld (hl),a			;95e9
	set 0,(hl)		;95ea   ; ...y el bit 0: es el del jugador
	ld a,(0e071h)		;95ec   ; no en la salida ni en la recta final?
	dec a			;95ef   ; el paso de la pista...
	cp 0afh		;95f0   ; ...entre 0x01 y 0xAF?
	jr nc,caballos_calle		;95f2
	ld a,(0e00bh)		;95f4   ; el boton 2...
	and a			;95f7   ; el boton 2?
	jr z,caballos_calle		;95f8
	set 4,(hl)		;95fa   ; ...bit 4: salta
caballos_calle:		; Arriba o abajo: bit 7 cambia de calle, bit 6 hacia abajo
	ld a,(0e003h)		;95fc
	and 060h		;95ff   ; arriba o abajo?
	jr z,caballos_hace_pasa		;9601
	set 7,(hl)		;9603   ; bit 7: cambia de calle...
	and 040h		;9605   ; ...abajo?
	jr z,caballos_hace_pasa		;9607
	set 6,(hl)		;9609   ; bit 6
caballos_hace_pasa:		; Lo que hace cada uno, a su byte +0x19
	ld hl,0e098h		;960b   ; el byte +0x19 de cada caballo
	ld de,0e13fh		;960e   ; lo que hacen
	ld b,004h		;9611
caballos_hace_uno:		; Uno
	ld a,(de)			;9613   ; lo que hace...
	ld (hl),a			;9614   ; ...a su byte
	push de			;9615
	ld de,00020h		;9616   ; el caballo siguiente (32 bytes)
	add hl,de			;9619
	pop de			;961a
	inc de			;961b
	djnz caballos_hace_uno		;961c   ; los cuatro
	ret			;961e

; ----------------------------------------------------------------------
; DATOS velocidades: Las ocho velocidades de los caballos, por el paso (bits
;   2-4 de 0xE041)
;   0x961f..0x9627  (8 bytes)
DATA_velocidades:
	defb 084h,098h,0a4h,0a8h,070h,06ch,064h,060h	; 961f  ....pld`

; ======================================================================
; CODIGO 0x9627..0x974e  (295 bytes)
; ======================================================================


camara:		; La velocidad de la pista (0xE06D): la del caballo que ha llegado al borde izquierdo; luego baja hasta 0x60. Y lo rapido que va cada caballo contra la pista
	ld a,(0e07ch)		;9627   ; ha llegado alguno a la meta?
	and a			;962a
	jp nz,camara_meta		;962b
	ld hl,0e08fh		;962e   ; el bit 7 de +0x10 de cada caballo: en el borde
	ld de,00020h		;9631
	ld bc,00400h		;9634
camara_borde:		; Uno
	ld a,(hl)			;9637   ; el borde izquierdo...
	add a,a			;9638   ; ...bit 7
	push hl			;9639
	call c,camara_lider		;963a   ; esta en el borde: la pista va a su velocidad
	pop hl			;963d
	add hl,de			;963e   ; el caballo siguiente
	inc c			;963f   ; su numero
	djnz camara_borde		;9640
	ld hl,0e06dh		;9642   ; la velocidad de la pista...
	ld a,(hl)			;9645   ; la velocidad de la pista
	cp 060h		;9646   ; ...por encima de 0x60...
	jr c,caballos_contra		;9648
	ld a,(0e07bh)		;964a   ; ...baja uno cada dos cuadros
	bit 0,a		;964d   ; en los cuadros pares
	jr z,caballos_contra		;964f
	dec (hl)			;9651   ; uno menos
caballos_contra:		; Cada caballo: +0x0D lo que se mueve contra la pista (la diferencia entre las dos velocidades, a la mitad) y el bit 0 de +0x0F si va mas lento (o igual)
	ld hl,0e077h		;9652
	ld ix,0e07fh		;9655
	ld a,(0e06dh)		;9659   ; la velocidad de la pista
	ld c,a			;965c
	ld b,004h		;965d
caballos_contra_uno:		; Uno
	res 0,(ix+00fh)		;965f
	ld a,(hl)			;9663   ; la suya, menos la de la pista
	sub c			;9664
	jr z,caballos_contra_lento		;9665
	jr nc,caballos_contra_mitad		;9667   ; mas rapido: el bit 0 a cero
	neg		;9669   ; mas lento: la diferencia en positivo
caballos_contra_lento:		; Va mas lento que la pista (o igual): el bit 0
	set 0,(ix+00fh)		;966b
caballos_contra_mitad:		; La mitad
	rrca			;966f
	and 07fh		;9670   ; a la mitad
	ld (ix+00dh),a		;9672   ; en +0x0D
	inc hl			;9675
	ld de,00020h		;9676   ; el caballo siguiente
	add ix,de		;9679
	djnz caballos_contra_uno		;967b
	ret			;967d
camara_meta:		; Con caballos en la meta, la pista se va parando
	ld hl,0e06dh		;967e
	ld a,(hl)			;9681
	and a			;9682   ; ya parada?
	jp z,caballos_contra		;9683
	dec (hl)			;9686   ; un poco mas lenta
	jp caballos_contra		;9687
camara_lider:		; Si el caballo del borde corre, la pista toma su velocidad
	res 7,(hl)		;968a   ; se borra la marca
	dec hl			;968c   ; el byte +0x0D...
	dec hl			;968d
	dec hl			;968e
	ld a,(hl)			;968f   ; corre?
	and a			;9690   ; ...se mueve?
	ret z			;9691
	pop hl			;9692   ; fuera la vuelta: la pista...
	pop hl			;9693   ; fuera la vuelta
	ld b,000h		;9694   ; el caballo C
	ld hl,0e077h		;9696   ; su velocidad
	add hl,bc			;9699
	ld a,(hl)			;969a   ; ...va a la velocidad de ese caballo
	ld (0e06dh),a		;969b   ; la de la pista
	jp caballos_contra		;969e
cansancio:		; Corriendo, cada caballo gasta su fuerza (0xE03F) segun lo rapido que va
	ld a,(0e06ch)		;96a1   ; la pista corre?
	cp 002h		;96a4
	ret nz			;96a6
	ld a,(0e077h)		;96a7   ; el caballo 1: la velocidad entre 32...
	call entre_32		;96aa
	ld hl,0e11fh		;96ad
	ld (hl),a			;96b0
	call suma_paso		;96b1   ; ...suma su cuenta...
	and a			;96b4
	jr z,cansancio_2		;96b5
	ld hl,(0e03fh)		;96b7   ; ...y si pasa de 64, un punto menos de fuerza
	dec hl			;96ba
	ld (0e03fh),hl		;96bb
cansancio_2:		; El caballo 2
	ld a,(0e078h)		;96be
	call entre_32		;96c1   ; la velocidad entre 32
	ld hl,0e127h		;96c4
	ld (hl),a			;96c7
	call suma_paso		;96c8
	and a			;96cb
	jr z,cansancio_3		;96cc
	ld hl,(0e043h)		;96ce   ; un punto menos de fuerza
	dec hl			;96d1
	ld (0e043h),hl		;96d2
cansancio_3:		; El caballo 3
	ld a,(0e079h)		;96d5
	call entre_32		;96d8   ; la velocidad entre 32
	ld hl,0e12fh		;96db
	ld (hl),a			;96de
	call suma_paso		;96df
	and a			;96e2
	jr z,cansancio_4		;96e3
	ld hl,(0e047h)		;96e5   ; un punto menos de fuerza
	dec hl			;96e8
	ld (0e047h),hl		;96e9
cansancio_4:		; El caballo 4
	ld a,(0e07ah)		;96ec
	call entre_32		;96ef   ; la velocidad entre 32
	ld hl,0e137h		;96f2
	ld (hl),a			;96f5
	call suma_paso		;96f6   ; suma la cuenta
	and a			;96f9
	ret z			;96fa
	ld hl,(0e04bh)		;96fb   ; un punto menos de fuerza
	dec hl			;96fe
	ld (0e04bh),hl		;96ff
	ret			;9702
entre_32:		; Los bits 5-6: la velocidad entre 32
	rrca			;9703   ; cinco rrca: los bits 5-6 abajo...
	rrca			;9704
	rrca			;9705
	rrca			;9706
	rrca			;9707
	and 003h		;9708   ; ...0-3
	ret			;970a
caballos:		; Los cuatro caballos: cada uno con su bloque (0xE07F, 32 bytes), sus tres sprites, su calle de salida y su numero
	ld ix,0e07fh		;970b   ; el 1...
	ld iy,0e198h		;970f   ; ...sprites 0x18-0x1A...
	ld de,00148h		;9713   ; ...negro (color 1), en la calle de Y 0x48
	ld c,000h		;9716   ; el numero 0
	call caballo		;9718   ; el 2
	ld ix,0e09fh		;971b   ; el 2...
	ld iy,0e1a4h		;971f   ; ...sprites 0x09-0x0B...
	ld de,00d61h		;9723   ; ...magenta (0x0D), calle de Y 0x61
	ld c,001h		;9726
	call caballo		;9728   ; el 3
	ld ix,0e0bfh		;972b   ; el 3...
	ld iy,0e1b0h		;972f   ; ...sprites 0x0C-0x0E...
	ld de,0067ah		;9733   ; ...rojo (6), calle de Y 0x7A
	ld c,002h		;9736
	call caballo		;9738   ; el 4
	ld ix,0e0dfh		;973b   ; el 4...
	ld iy,0e1bch		;973f   ; ...sprites 0x0F-0x11...
	ld de,00493h		;9743   ; ...azul (4), calle de Y 0x93
	ld c,003h		;9746
caballo:		; Un caballo por su estado (+0): 1 la salida, 2 corre, 3 tropieza, 4 salta, 5 cae, 6 en el suelo, 7 despues de la meta
	ld a,(ix+000h)		;9748
	call salta_tabla		;974b   ; por la tabla

; ----------------------------------------------------------------------
; DATOS estados_caballo: Los siete estados: la salida, corre, tropieza, salta,
;   cae, en el suelo y despues de la meta
;   0x974e..0x975c  (14 bytes)
DATA_estados_caballo:
	defw 0975ch,09798h,09b26h,09b98h,09c12h,09c4fh,09cd3h	; 974e

; ======================================================================
; CODIGO 0x975c..0x979e  (66 bytes)
; ======================================================================


caballo_sale:		; Estado 1: el bloque a cero, su calle, X 0xD0 a la derecha, el dibujo 2 y su color; nadie ha llegado y los jinetes montan
	push ix		;975c   ; el bloque...
	pop hl			;975e
	xor a			;975f   ; ...a cero
	ld b,020h		;9760
	call llena		;9762
	ld (ix+011h),e		;9765   ; la Y de su calle
	ld (ix+002h),e		;9768
	ld (ix+003h),0d0h		;976b   ; X: 0xD0
	ld (ix+005h),002h		;976f   ; el dibujo 2
	ld (ix+006h),d		;9773   ; el color
	ld (ix+017h),c		;9776   ; el numero
	ld (0e07ch),a		;9779   ; nadie en la meta
	ld (0e143h),a		;977c   ; ni el jugador
	ld (0e144h),a		;977f
	call caballo_sprites		;9782   ; los sprites
	ld hl,00101h		;9785   ; los cuatro jinetes, al estado 1
	ld (0e0ffh),hl		;9788
	ld (0e107h),hl		;978b
	ld (0e10fh),hl		;978e
	ld (0e117h),hl		;9791
	call meta_borra		;9794   ; los numeros de 1ST y 2ND en blanco
	ret			;9797
caballo_corre:		; Estado 2: correr (paso 1) o prepararse para saltar (paso 2)
	ld a,(ix+001h)		;9798
	call salta_tabla		;979b

; ----------------------------------------------------------------------
; DATOS pasos_corre: Los dos pasos: correr y prepararse para saltar
;   0x979e..0x97a2  (4 bytes)
DATA_pasos_corre:
	defw 097a2h,09b0ah	; 979e  -> corre preparado

; ======================================================================
; CODIGO 0x97a2..0x9865  (195 bytes)
; ======================================================================


corre:		; Paso 1: lo que pisa: la meta, las cosas sueltas, la valla o la ria; si no, salta si toca (el jugador con el boton 2, el ordenador si viene un obstaculo)
	call pisa		;97a2   ; bit 7: la meta
	add a,a			;97a5
	jp c,caballo_meta		;97a6
	add a,a			;97a9   ; bit 6: cosas sueltas, tropieza
	jp c,a_tropieza		;97aa
	add a,a			;97ad   ; bit 5: la valla o la ria, cae
	jp c,a_cae		;97ae
	ld a,(ix+019h)		;97b1   ; es el del jugador?...
	bit 0,a		;97b4
	jr z,corre_ordenador		;97b6
	bit 4,a		;97b8   ; ...ha pulsado el boton 2?
	jp nz,a_preparado		;97ba
	jr corre_mueve		;97bd
corre_ordenador:		; El ordenador salta si lo que viene delante (16 pixeles) es un obstaculo (bit 3)
	call pisa_delante		;97bf
	bit 3,a		;97c2
	jp nz,a_preparado		;97c4
corre_mueve:		; Se mueve; en los bordes de la pantalla, la marca para la camara
	call caballo_mueve		;97c7
	ld a,(ix+003h)		;97ca   ; X < 0x50: en el borde izquierdo
	cp 050h		;97cd
	jp c,borde_izquierdo		;97cf
	cp 0e8h		;97d2   ; X >= 0xE8: en el derecho
	jp nc,borde_derecho		;97d4
	ld a,(ix+010h)		;97d7   ; dentro: sin marcas
	and 03fh		;97da
	ld (ix+010h),a		;97dc
	ret			;97df
caballo_meta:		; Llega a la meta: uno mas; si es el del jugador, su puesto; el primero cambia la pista y los dos primeros dan la pareja ganadora
	ld a,(ix+018h)		;97e0   ; ya habia llegado?
	and a			;97e3
	ret nz			;97e4
	ld hl,0e145h		;97e5   ; la meta parpadea
	set 7,(hl)		;97e8
	ld hl,0e143h		;97ea   ; uno mas en la meta
	inc (hl)			;97ed
	bit 0,(ix+019h)		;97ee   ; es el del jugador?
	jr z,meta_puesto		;97f2
	ld a,(hl)			;97f4   ; su puesto
	ld (0e144h),a		;97f5
meta_puesto:		; El puesto: el primero lleva al jinete de la victoria; el jinete pinta los numeros de 1ST y 2ND
	ld a,(hl)			;97f8
	call meta_jinete		;97f9   ; el jinete del primero
	cp 005h		;97fc   ; solo los dos primeros
	call c,meta_numero		;97fe   ; el numero en el recuadro
	ld a,(0e07ch)		;9801   ; los que han llegado (la suma de sus valores)
	cp 020h		;9804   ; el primero: 0x986B
	jr c,$+101		;9806   ; el primero
	cp 030h		;9808   ; el tercero o mas: nada
	jp nc,meta_hecho		;980a   ; el tercero o mas
	sub 020h		;980d   ; el segundo: la pareja de los dos...
	rrca			;980f   ; entre 2...
	and 007h		;9810   ; ...de 0 a 7...
	dec a			;9812   ; ...menos 1
	ld c,a			;9813   ; ...por la tabla 0x9865
	ld b,000h		;9814
	ld hl,09865h		;9816   ; la pareja
	add hl,bc			;9819
	ld a,(hl)			;981a
	ld (0e07dh),a		;981b   ; el resultado
	ld (ix+018h),0ffh		;981e   ; llegado
	ret			;9822   ; vuelve
meta_numero:		; El jinete: el numero del caballo en 1ST (fila 3) o 2ND (fila 4)
	ld a,(0e001h)		;9823   ; solo el jinete
	and a			;9826
	ret nz			;9827
	ld a,(hl)			;9828   ; el primero...
	ld hl,01867h		;9829
	cp 001h		;982c
	jr z,meta_numero_pon		;982e
	cp 002h		;9830
	ret nz			;9832
	ld hl,01887h		;9833   ; ...o el segundo
meta_numero_pon:		; El numero: la casilla 0x8A + el caballo
	ld a,(ix+017h)		;9836
	add a,08ah		;9839
	call 0004dh		;983b
	ret			;983e
meta_jinete:		; El jinete del primero, al estado 4 (la victoria)
	push af			;983f
	cp 001h		;9840   ; el primero?
	jr nz,meta_jinete_fin		;9842
	ld c,(ix+017h)		;9844   ; su jinete
	ld hl,09ccbh		;9847
	call tabla_palabra		;984a
	ld (hl),004h		;984d   ; estado 4...
	inc hl			;984f
	ld (hl),001h		;9850   ; ...paso 1
meta_jinete_fin:		; Vuelve
	pop af			;9852
	ret			;9853
meta_borra:		; Los numeros de 1ST y 2ND en blanco (0x90)
	ld hl,01867h		;9854
	ld a,090h		;9857   ; en blanco
	call 0004dh		;9859   ; WRTVRM
	ld hl,01887h		;985c
	ld a,090h		;985f   ; en blanco
	call 0004dh		;9861
	ret			;9864

; ----------------------------------------------------------------------
; DATOS parejas: La pareja ganadora por la suma de los dos primeros (0x22,
;   0x24, 0x26, 0x28, 0x2A, 0x2C): 0x80 + su lugar en las cuotas (1-2, 1-3,
;   2-3, 1-4, 2-4, 3-4)
;   0x9865..0x986b  (6 bytes)
DATA_parejas:
	defb 080h,081h,083h,082h,084h,085h	; 9865

; ======================================================================
; CODIGO 0x986b..0x988f  (36 bytes)
; ======================================================================


meta_primero:		; El primero: suma su valor (0x988F) y todos los caballos pasan al estado 7
	ld c,(ix+017h)		;986b   ; su valor...
	ld b,000h		;986e
	ld hl,0988fh		;9870
	add hl,bc			;9873
	ld a,(hl)			;9874
	ld hl,0e07ch		;9875   ; ...a la cuenta de la meta
	ld c,(hl)			;9878
	add a,c			;9879
	ld (hl),a			;987a
	ld hl,00107h		;987b   ; el estado 7...
	ld (0e07fh),hl		;987e   ; ...para los cuatro
	ld (0e09fh),hl		;9881
	ld (0e0bfh),hl		;9884
	ld (0e0dfh),hl		;9887
meta_hecho:		; Llegado
	ld (ix+018h),0ffh		;988a
	ret			;988e

; ----------------------------------------------------------------------
; DATOS valores_meta: El valor de cada caballo al llegar: 0x10, 0x12, 0x14 y
;   0x18 (la suma de dos da la pareja)
;   0x988f..0x9893  (4 bytes)
DATA_valores_meta:
	defb 010h,012h,014h,018h	; 988f

; ======================================================================
; CODIGO 0x9893..0x98ed  (90 bytes)
; ======================================================================


a_tropieza:		; Al estado 3: tropieza
	ld (ix+001h),001h		;9893
	ld (ix+000h),003h		;9897
	ret			;989b
a_cae:		; Al estado 5: cae
	ld (ix+001h),001h		;989c
	ld (ix+000h),005h		;98a0
	ret			;98a4
borde_izquierdo:		; La marca del borde izquierdo
	set 7,(ix+010h)		;98a5
	ret			;98a9
borde_derecho:		; La marca del borde derecho
	set 6,(ix+010h)		;98aa
	ret			;98ae
a_preparado:		; Al paso 2: se prepara para saltar
	ld (ix+001h),002h		;98af
	ret			;98b3
pisa:		; Lo que pisa el caballo: la casilla bajo sus patas (X + 12, Y - 8) y la de su izquierda, por la tabla 0x98ED
	ld a,(ix+002h)		;98b4
	add a,00ch		;98b7   ; X + 12
	ld l,a			;98b9
	ld a,(ix+003h)		;98ba
	add a,0f8h		;98bd   ; Y - 8
	ld h,a			;98bf
	ld de,098edh		;98c0
	call pisa_dos		;98c3
	ret			;98c6
pisa_delante:		; Lo que tiene delante: Y - 16, por la tabla 0x9904
	ld a,(ix+002h)		;98c7
	add a,00ch		;98ca   ; X + 12
	ld l,a			;98cc
	ld a,(ix+003h)		;98cd
	add a,0f0h		;98d0   ; Y - 16
	ld h,a			;98d2
	ld de,09904h		;98d3
	call pisa_dos		;98d6
	ret			;98d9
pisa_cae:		; Donde cae del salto: Y - 18, por la tabla 0x991B
	ld a,(ix+002h)		;98da
	add a,00ch		;98dd   ; X + 12
	ld l,a			;98df
	ld a,(ix+003h)		;98e0
	add a,0eeh		;98e3   ; Y - 18
	ld h,a			;98e5
	ld de,0991bh		;98e6
	call pisa_dos		;98e9
	ret			;98ec

; ----------------------------------------------------------------------
; DATOS pisa_tablas: Lo que es cada casilla para las patas, delante y al caer
;   del salto: bit 7 la meta, 6 cosas sueltas, 5 la valla o la ria, 4 lo mismo
;   al caer, 3 un obstaculo delante
;   0x98ed..0x9931  (68 bytes)
DATA_pisa_tablas:
	defb 040h,040h,040h,040h,040h,040h,040h,040h,020h,020h,020h,020h,000h,000h,000h,000h,020h,020h,020h,020h,000h,080h,020h	; 98ed  @@@@@@@@    ....    .. 
	defb 008h,008h,008h,008h,008h,008h,008h,008h,000h,000h,000h,000h,000h,000h,000h,000h,008h,008h,008h,008h,000h,000h,008h	; 9904  .......................
	defb 040h,040h,040h,040h,040h,040h,040h,040h,010h,010h,010h,010h,000h,000h,000h,000h,010h,010h,010h,000h,000h,010h	; 991b  @@@@@@@@..............

; ======================================================================
; CODIGO 0x9931..0x9a20  (239 bytes)
; ======================================================================


pisa_dos:		; Las dos casillas (la de la columna y la de dos mas a la izquierda), sus bits juntos
	call pisa_casilla		;9931
	call pisa_tabla		;9934   ; su byte
	ld b,a			;9937
	dec h			;9938   ; dos columnas a la izquierda
	dec h			;9939
	call pisa_casilla		;993a
	call pisa_tabla		;993d
	or b			;9940   ; los dos juntos
	ret			;9941
pisa_casilla:		; La casilla de la pantalla en (L, H) y su lugar en la tabla: 0x13-0x1E o desde 0xD6
	call pantalla_lee		;9942
	sub 013h		;9945   ; 0x13-0x1E: 0-11
	cp 00ch		;9947
	ret c			;9949
	sub 0c3h		;994a   ; desde 0xD6: 12 en adelante
	ret			;994c
pisa_tabla:		; El byte A de la tabla DE
	push hl			;994d
	ld l,a			;994e   ; HL = A...
	ld h,000h		;994f
	add hl,de			;9951   ; ...+ DE
	ld a,(hl)			;9952
	pop hl			;9953
	ret			;9954
pantalla_lee:		; RDVRM de la casilla de la pantalla en (Y = L, X = H)
	push hl			;9955
	push de			;9956
	ld a,h			;9957   ; X / 8
	rrca			;9958   ; X entre 8
	rrca			;9959
	rrca			;995a
	and 01fh		;995b
	ld e,a			;995d   ; en DE
	ld d,000h		;995e
	ld h,d			;9960
	ld a,l			;9961   ; Y / 8 x 32
	and 0f8h		;9962   ; Y redondeada a 8...
	ld l,a			;9964
	add hl,hl			;9965   ; ...x 4: la fila x 32
	add hl,hl			;9966
	add hl,de			;9967   ; mas la columna
	ld de,01800h		;9968   ; la tabla de nombres
	add hl,de			;996b   ; mas la tabla de nombres
	call 0004ah		;996c   ; RDVRM
	pop de			;996f
	pop hl			;9970
	ret			;9971
caballo_mueve:		; El caballo se mueve: su calle, su X contra la pista y el galope
	call calle		;9972   ; la calle
	push ix		;9975
	pop hl			;9977
	ld de,0000dh		;9978   ; lo que se mueve contra la pista (+0x0D)...
	add hl,de			;997b
	call suma_paso		;997c   ; ...suma la cuenta
	and a			;997f
	jp z,caballo_galope		;9980
	ld e,(ix+003h)		;9983   ; la X (16 bits)
	ld d,(ix+004h)		;9986
	bit 0,(ix+00fh)		;9989   ; mas lento que la pista?
	jp z,caballo_adelanta		;998d
	bit 6,(ix+010h)		;9990   ; en el borde derecho, no pasa
	jp nz,caballo_x		;9994
	inc de			;9997   ; atras: a la derecha
	jp caballo_x		;9998
caballo_adelanta:		; Mas rapido: a la izquierda (adelante); en la salida no pasa de X 0x50
	ld a,(0e07ch)		;999b   ; ha llegado alguno?
	and a			;999e
	jr nz,caballo_izquierda		;999f
	ld a,e			;99a1   ; en la salida...
	cp 050h		;99a2   ; ...no pasa de 0x50
	jr c,caballo_galope		;99a4
caballo_izquierda:		; Uno a la izquierda
	dec de			;99a6
caballo_x:		; La X nueva
	ld (ix+003h),e		;99a7
	ld (ix+004h),d		;99aa
caballo_galope:		; El galope, mas deprisa cuanto mas corre (0x9A20)
	ld e,(ix+017h)		;99ad   ; su velocidad...
	ld d,000h		;99b0
	ld hl,0e077h		;99b2
	add hl,de			;99b5
	ld a,(hl)			;99b6
	rrca			;99b7   ; ...a la mitad
	and 07fh		;99b8
	ld (ix+009h),a		;99ba
	ld de,09a20h		;99bd
	call animacion		;99c0
	ret			;99c3
calle:		; Cada cuatro cuadros, la calle: arriba o abajo un pixel, hasta 4 de su sitio; si no, vuelve
	ld a,(0e07bh)		;99c4   ; un cuadro de cada cuatro
	and 003h		;99c7
	cp 001h		;99c9
	ret nz			;99cb
	ld c,(ix+013h)		;99cc   ; lo que se ha movido de su calle
	ld b,c			;99cf
	ld a,(ix+019h)		;99d0   ; cambia de calle?
	add a,a			;99d3
	jr nc,calle_vuelve		;99d4
	inc c			;99d6   ; abajo...
	add a,a			;99d7
	jr c,calle_limite		;99d8
	dec c			;99da   ; ...o arriba
	dec c			;99db
calle_limite:		; No mas de 4
	ld a,c			;99dc
	bit 7,a		;99dd
	jr z,calle_dentro		;99df
	neg		;99e1
calle_dentro:		; Pasa de 4: se queda
	cp 005h		;99e3
	jr c,calle_y		;99e5
	ld c,b			;99e7
calle_y:		; La Y: la de su calle mas lo movido
	ld a,(ix+011h)		;99e8
	add a,c			;99eb
	ld (ix+002h),a		;99ec
	ld (ix+013h),c		;99ef
	ret			;99f2
calle_vuelve:		; Sin palanca, vuelve a su calle
	ld a,c			;99f3
	and a			;99f4   ; ya esta en su calle
	jr z,calle_y		;99f5
	bit 7,a		;99f7   ; por encima?
	jr z,calle_baja		;99f9
	inc c			;99fb   ; por debajo: uno mas
	jr calle_y		;99fc
calle_baja:		; Uno menos
	dec c			;99fe
	jr calle_y		;99ff
animacion:		; La animacion del caballo: cuando la cuenta (+0x09) pasa de 64, el dibujo siguiente de la serie DE (umbrales y dibujos, 0x80BB)
	push ix		;9a01
	pop hl			;9a03
	ld bc,00009h		;9a04   ; la cuenta
	add hl,bc			;9a07
	call suma_paso		;9a08
	and a			;9a0b
	ret z			;9a0c
	inc (ix+00bh)		;9a0d   ; el paso de la animacion
	ld a,(ix+00bh)		;9a10
	and 01fh		;9a13
	ex de,hl			;9a15   ; la serie
	call tabla_umbral		;9a16   ; el dibujo que toca
	ld (ix+005h),a		;9a19
	call caballo_sprites		;9a1c
	ret			;9a1f

; ----------------------------------------------------------------------
; DATOS animaciones: Las cuatro series de dibujos del caballo: cuatro umbrales
;   y cuatro dibujos (galope, salto, caida y en el suelo)
;   0x9a20..0x9a40  (32 bytes)
DATA_animaciones:
	defb 000h,008h,010h,018h,002h,003h,000h,001h	; 9a20  ........
	defb 000h,008h,010h,018h,004h,005h,009h,006h	; 9a28  ........
	defb 000h,008h,010h,018h,008h,005h,007h,002h	; 9a30  ........
	defb 000h,008h,010h,018h,007h,002h,002h,002h	; 9a38  ........

; ======================================================================
; CODIGO 0x9a40..0x9b2c  (236 bytes)
; ======================================================================


caballo_sprites:		; Los tres sprites del caballo: el color, el dibujo (0xB3DB, 9 bytes: dibujo, Y y X de cada sprite) y su sitio en la pantalla; si sale por los bordes, el bit 7 del color corre la X 32 pixeles
	ld a,(ix+006h)		;9a40   ; el color en los tres
	ld (iy+003h),a		;9a43   ; el primer sprite...
	ld (iy+007h),a		;9a46   ; ...el segundo...
	ld (iy+00bh),a		;9a49   ; ...y el tercero
	ld a,(ix+005h)		;9a4c   ; el dibujo x 9
	ld b,a			;9a4f
	add a,a			;9a50   ; x 8...
	add a,a			;9a51
	add a,a			;9a52
	add a,b			;9a53   ; ...+ 1: x 9
	ld c,a			;9a54
	ld b,000h		;9a55
	ld hl,0b3dbh		;9a57   ; la tabla
	add hl,bc			;9a5a
	ld a,(hl)			;9a5b   ; dibujo, Y y X del primero...
	ld (iy+002h),a		;9a5c   ; el dibujo
	inc hl			;9a5f
	ld a,(hl)			;9a60
	ld (iy+000h),a		;9a61   ; la Y
	inc hl			;9a64
	ld a,(hl)			;9a65
	ld (iy+001h),a		;9a66   ; la X
	inc hl			;9a69
	ld a,(hl)			;9a6a   ; ...del segundo...
	ld (iy+006h),a		;9a6b   ; el dibujo
	inc hl			;9a6e
	ld a,(hl)			;9a6f
	ld (iy+004h),a		;9a70   ; la Y
	inc hl			;9a73
	ld a,(hl)			;9a74
	ld (iy+005h),a		;9a75   ; la X
	inc hl			;9a78
	ld a,(hl)			;9a79   ; ...y del tercero
	ld (iy+00ah),a		;9a7a   ; el dibujo
	inc hl			;9a7d
	ld a,(hl)			;9a7e
	ld (iy+008h),a		;9a7f   ; la Y
	inc hl			;9a82
	ld a,(hl)			;9a83
	ld (iy+009h),a		;9a84   ; la X
	push iy		;9a87   ; mas la calle en las tres Y
	pop hl			;9a89
	ld de,00004h		;9a8a   ; de sprite en sprite
	ld b,(ix+002h)		;9a8d   ; la Y del caballo
	ld a,(hl)			;9a90
	add a,b			;9a91   ; mas la del primero
	ld (hl),a			;9a92
	add hl,de			;9a93   ; el segundo
	ld a,(hl)			;9a94
	add a,b			;9a95
	ld (hl),a			;9a96
	add hl,de			;9a97   ; el tercero
	ld a,(hl)			;9a98
	add a,b			;9a99
	ld (hl),a			;9a9a
	ld e,(ix+003h)		;9a9b   ; la X del caballo (16 bits)...
	ld d,(ix+004h)		;9a9e
	ld l,(iy+001h)		;9aa1   ; ...mas la de cada sprite
	res 7,(iy+003h)		;9aa4   ; sin correr la X
	call sprite_x		;9aa8   ; fuera de la pantalla?
	ld (iy+001h),a		;9aab   ; la X del sprite
	jr nc,sprites_x2		;9aae   ; dentro?
	ld (iy+000h),a		;9ab0   ; fuera: Y = 0xC2
sprites_x2:		; Por la izquierda: la X + 32 y el bit 7 del color
	bit 0,b		;9ab3   ; por la izquierda?...
	jr z,sprites_seg		;9ab5
	set 7,(iy+003h)		;9ab7   ; ...la X corrida 32 pixeles (bit 7 del color)
sprites_seg:		; El segundo sprite
	ld l,(iy+005h)		;9abb   ; el segundo
	res 7,(iy+007h)		;9abe
	call sprite_x		;9ac2   ; dentro?
	ld (iy+005h),a		;9ac5   ; su X
	jr nc,sprites_x3		;9ac8
	ld (iy+004h),a		;9aca   ; fuera: Y = 0xC2
sprites_x3:		; ...
	bit 0,b		;9acd   ; por la izquierda?
	jr z,sprites_ter		;9acf
	set 7,(iy+007h)		;9ad1   ; ...corrida
sprites_ter:		; El tercero
	ld l,(iy+009h)		;9ad5   ; el tercero
	res 7,(iy+00bh)		;9ad8
	call sprite_x		;9adc   ; dentro?
	ld (iy+009h),a		;9adf   ; su X
	jr nc,sprites_x4		;9ae2
	ld (iy+008h),a		;9ae4   ; fuera
	ret			;9ae7
sprites_x4:		; ...
	bit 0,b		;9ae8   ; por la izquierda?
	ret z			;9aea
	set 7,(iy+00bh)		;9aeb   ; ...corrida
	ret			;9aef
sprite_x:		; La X del sprite: DE + L (con signo); si no cae en la pantalla, NC y A = 0xC2 (fuera)
	ld h,000h		;9af0   ; H = 0 y B = 0 (sin correr)
	ld b,h			;9af2
	bit 7,l		;9af3   ; L con signo
	jr z,L_9AF9		;9af5
	ld h,0ffh		;9af7   ; negativo: H = 0xFF
L_9AF9:
	add hl,de			;9af9   ; la suma
	ld a,h			;9afa   ; dentro de 0-255?
	and a			;9afb
	ld a,l			;9afc
	ret z			;9afd   ; dentro: A = la X
	cp 0f0h		;9afe   ; por la izquierda, hasta -16...
	ld a,0c2h		;9b00   ; ...si no, fuera
	ret c			;9b02   ; mas a la izquierda: fuera
	ld a,l			;9b03   ; la X + 32...
	add a,020h		;9b04
	ld b,001h		;9b06   ; ...y el bit 7 del color
	and a			;9b08   ; NC: dentro
	ret			;9b09
preparado:		; Paso 2 del estado 2: el galope hasta el final del paso y a saltar (estado 4)
	ld de,09a20h		;9b0a
	call animacion		;9b0d
	ld a,(ix+00bh)		;9b10   ; el final del paso?
	and 003h		;9b13
	cp 003h		;9b15
	ret nz			;9b17
	ld a,000h		;9b18   ; la cuenta de la animacion a 0
	ld (ix+00bh),a		;9b1a
	ld (ix+001h),001h		;9b1d   ; estado 4, paso 1: salta
	ld (ix+000h),004h		;9b21
	ret			;9b25
caballo_tropieza:		; Estado 3: tropieza con algo suelto (o vuelve del suelo)
	ld a,(ix+001h)		;9b26
	call salta_tabla		;9b29

; ----------------------------------------------------------------------
; DATOS pasos_tropieza: Los dos pasos: el golpe y el frenazo
;   0x9b2c..0x9b30  (4 bytes)
DATA_pasos_tropieza:
	defw 09b30h,09b4ah	; 9b2c  -> tropieza frenazo

; ======================================================================
; CODIGO 0x9b30..0x9ba0  (112 bytes)
; ======================================================================


tropieza:		; Paso 1: el sonido (si es el jugador o se apuesta), 24 cuadros y al paso 2
	ld a,(0e001h)		;9b30   ; la apuesta: suena
	and a			;9b33
	jr nz,tropieza_suena		;9b34
	bit 0,(ix+019h)		;9b36   ; el jinete: solo el suyo
	jr z,tropieza_cuenta		;9b3a
tropieza_suena:		; El sonido del golpe (bit 5 de 0xE147)
	ld hl,0e147h		;9b3c
	set 5,(hl)		;9b3f
tropieza_cuenta:		; 24 cuadros
	ld (ix+01ah),018h		;9b41
	ld (ix+001h),002h		;9b45
	ret			;9b49
frenazo:		; Paso 2: frenado 24 cuadros; luego, si pisa la valla o la ria cae, si pisa algo suelto se queda; si no, corre; el jugador puede saltar
	ld a,(ix+019h)		;9b4a   ; el jugador...
	bit 0,a		;9b4d
	jr z,frenazo_cuenta		;9b4f
	bit 4,a		;9b51   ; ...pulsa el boton 2?
	jr nz,frenazo_salta		;9b53
frenazo_cuenta:		; Un cuadro menos: mientras, mas lento que la pista
	dec (ix+01ah)		;9b55
	jr z,frenazo_fin		;9b58
	ld (ix+00fh),0ffh		;9b5a   ; mas lento...
	ld (ix+00dh),010h		;9b5e   ; ...a 16
	jp corre_mueve		;9b62
frenazo_fin:		; Se acaba: lo que pisa
	inc (ix+01ah)		;9b65
	call pisa		;9b68
	bit 5,a		;9b6b   ; la valla o la ria?
	jr nz,frenazo_cae		;9b6d
	and a			;9b6f   ; nada?
	jr nz,frenazo_quieto		;9b70
	ld (ix+001h),001h		;9b72   ; a correr
	ld (ix+000h),002h		;9b76
	ret			;9b7a
frenazo_quieto:		; Sigue sobre algo suelto: quieto con la pista
	ld (ix+00fh),000h		;9b7b
	ld (ix+00dh),000h		;9b7f
	jp corre_mueve		;9b83
frenazo_salta:		; Al paso 2 del estado 2: a saltar
	ld (ix+001h),002h		;9b86
	ld (ix+000h),002h		;9b8a
	ret			;9b8e
frenazo_cae:		; Al estado 5: cae
	ld (ix+001h),001h		;9b8f
	ld (ix+000h),005h		;9b93
	ret			;9b97
caballo_salta:		; Estado 4: el salto (paso 1 sube, 2 en el aire, 3 baja)
	ld a,(ix+001h)		;9b98
	and 003h		;9b9b
	call salta_tabla		;9b9d

; ----------------------------------------------------------------------
; DATOS pasos_salto: Los tres pasos del salto
;   0x9ba0..0x9ba6  (6 bytes)
DATA_pasos_salto:
	defw 09ba6h,09bcfh,09bd8h	; 9ba0  -> salto_sube salto_aire salto_baja

; ======================================================================
; CODIGO 0x9ba6..0x9c18  (114 bytes)
; ======================================================================


salto_sube:		; Paso 1: la animacion del salto hasta el dibujo 15, el sonido y 24 cuadros en el aire
	ld de,09a28h		;9ba6
	call animacion		;9ba9
	ld a,(ix+00bh)		;9bac   ; el paso de la animacion...
	and 01fh		;9baf
	cp 00fh		;9bb1   ; ...el 15?
	ret nz			;9bb3
	call salto_suena		;9bb4   ; el sonido
	ld a,018h		;9bb7   ; 24 cuadros...
	ld (ix+00ch),a		;9bb9
	ld (ix+001h),002h		;9bbc   ; ...en el paso 2
	ret			;9bc0
salto_suena:		; El sonido del salto (0xBEA1, canal 2) si el canal esta libre
	ld a,(0f044h)		;9bc1   ; el canal 2 suena?
	and a			;9bc4
	ret nz			;9bc5
	ld b,002h		;9bc6   ; el canal 2...
	ld de,0bea1h		;9bc8   ; ...el salto
	call pieza		;9bcb
	ret			;9bce
salto_aire:		; Paso 2: en el aire
	dec (ix+00ch)		;9bcf
	ret nz			;9bd2
	ld (ix+001h),003h		;9bd3
	ret			;9bd7
salto_baja:		; Paso 3: hasta el final de la animacion; donde cae: sobre algo suelto tropieza, en la valla o la ria va al suelo; si no, corre
	ld de,09a28h		;9bd8
	call animacion		;9bdb
	ld a,(ix+00bh)		;9bde   ; el final?
	and 01fh		;9be1
	cp 01fh		;9be3
	ret nz			;9be5
	call pisa_cae		;9be6   ; donde cae
	bit 6,a		;9be9   ; algo suelto?
	jp nz,salto_tropieza		;9beb
	bit 4,a		;9bee   ; la valla o la ria?
	jp nz,salto_suelo		;9bf0
	ld (ix+000h),002h		;9bf3   ; bien: a correr
	ld (ix+001h),001h		;9bf7
	ret			;9bfb
salto_tropieza:		; Al estado 3: tropieza
	ld (ix+001h),001h		;9bfc
	ld (ix+000h),003h		;9c00
	ret			;9c04
salto_suelo:		; Al estado 6: al suelo
	ld (ix+00bh),000h		;9c05
	ld (ix+001h),001h		;9c09
	ld (ix+000h),006h		;9c0d
	ret			;9c11
caballo_cae:		; Estado 5: cae (la animacion de la caida y el jinete sale despedido)
	ld a,(ix+001h)		;9c12
	call salta_tabla		;9c15

; ----------------------------------------------------------------------
; DATOS pasos_cae: Los dos pasos de la caida
;   0x9c18..0x9c1c  (4 bytes)
DATA_pasos_cae:
	defw 09c1ch,09c33h	; 9c18  -> cae_galope cae_caida

; ======================================================================
; CODIGO 0x9c1c..0x9c55  (57 bytes)
; ======================================================================


cae_galope:		; Paso 1: acaba el paso de galope
	ld de,09a20h		;9c1c   ; la animacion del galope
	call animacion		;9c1f
	ld a,(ix+00bh)		;9c22
	and 003h		;9c25   ; el ultimo de la serie?
	cp 003h		;9c27
	ret nz			;9c29
	ld (ix+00bh),000h		;9c2a
	ld (ix+001h),002h		;9c2e   ; al paso 2
	ret			;9c32
cae_caida:		; Paso 2: la caida (0x9A30); en el dibujo 4 sale el jinete; al final, en el suelo
	ld de,09a30h		;9c33
	call animacion		;9c36
	ld a,(ix+00bh)		;9c39
	and 01fh		;9c3c
	cp 004h		;9c3e   ; el dibujo 4?
	call z,jinete_despedido		;9c40
	cp 01fh		;9c43   ; el final?
	ret nz			;9c45
	ld (ix+001h),002h		;9c46   ; al estado 6, paso 2
	ld (ix+000h),006h		;9c4a
	ret			;9c4e
caballo_suelo:		; Estado 6: en el suelo, se queda atras con la pista hasta salir por la derecha
	ld a,(ix+001h)		;9c4f
	call salta_tabla		;9c52

; ----------------------------------------------------------------------
; DATOS pasos_suelo: Los dos pasos: caer y quedarse atras
;   0x9c55..0x9c59  (4 bytes)
DATA_pasos_suelo:
	defw 09c59h,09c87h	; 9c55  -> suelo_cae suelo_atras

; ======================================================================
; CODIGO 0x9c59..0x9ccb  (114 bytes)
; ======================================================================


suelo_cae:		; Paso 1: la animacion (0x9A38); en el dibujo 4, el jinete sale despedido
	ld de,09a38h		;9c59   ; la animacion de la caida al suelo (0x9A38)
	call animacion		;9c5c
	ld a,(ix+00bh)		;9c5f   ; el paso de la animacion
	and 01fh		;9c62
	cp 004h		;9c64   ; el 4?...
	push af			;9c66
	call z,jinete_despedido		;9c67   ; ...el jinete sale despedido
	pop af			;9c6a
	cp 01fh		;9c6b   ; el final?
	ret nz			;9c6d
	ld (ix+001h),002h		;9c6e   ; al paso 2
	ret			;9c72
jinete_despedido:		; El sonido de la caida (bit 7 de 0xE147) y el jinete de este caballo al estado 3
	ld hl,0e147h		;9c73
	set 7,(hl)		;9c76
	ld c,(ix+017h)		;9c78   ; el jinete...
	ld hl,09ccbh		;9c7b
	call tabla_palabra		;9c7e
	ld (hl),003h		;9c81   ; ...estado 3, paso 1
	inc hl			;9c83
	ld (hl),001h		;9c84
	ret			;9c86
suelo_atras:		; Paso 2: con la pista corriendo, a la derecha a su velocidad; al salir (X >= 0xD8), vuelve a la carrera con el jinete
	ld a,(0e06ch)		;9c87   ; la pista corre?
	and a			;9c8a
	jr z,suelo_derecha		;9c8b
	ld a,(0e06dh)		;9c8d   ; la mitad de su velocidad...
	rrca			;9c90
	and 07fh		;9c91
	ld (ix+00dh),a		;9c93
	push ix		;9c96
	pop hl			;9c98
	ld de,0000dh		;9c99
	add hl,de			;9c9c
	call suma_paso		;9c9d   ; ...en la cuenta
	and a			;9ca0
	ret z			;9ca1
suelo_derecha:		; Un pixel a la derecha
	inc (ix+003h)		;9ca2
	ld a,(ix+003h)		;9ca5
	cp 0d8h		;9ca8   ; ha salido?
	jr c,suelo_sprites		;9caa
	ld c,(ix+017h)		;9cac   ; su jinete...
	ld hl,09ccbh		;9caf
	call tabla_palabra		;9cb2
	ld (hl),001h		;9cb5   ; ...a montar otra vez
	inc hl			;9cb7
	ld (hl),001h		;9cb8
	ld (ix+01ah),010h		;9cba   ; 16 cuadros...
	ld (ix+001h),002h		;9cbe   ; ...frenado (estado 3, paso 2)
	ld (ix+000h),003h		;9cc2
	ret			;9cc6
suelo_sprites:		; Los sprites
	call caballo_sprites		;9cc7
	ret			;9cca

; ----------------------------------------------------------------------
; DATOS jinetes_tabla: Los bloques de los cuatro jinetes (0xE0FF, 8 bytes cada
;   uno)
;   0x9ccb..0x9cd3  (8 bytes)
DATA_jinetes_tabla:
	defw 0e0ffh,0e107h,0e10fh,0e117h	; 9ccb

; ======================================================================
; CODIGO 0x9cd3..0x9d37  (100 bytes)
; ======================================================================


caballo_tras_meta:		; Estado 7: despues del primero en la meta: corre hasta salir por la izquierda y se para
	call pisa		;9cd3
	bit 7,a		;9cd6   ; la meta?
	call nz,caballo_meta		;9cd8
	ld a,(ix+004h)		;9cdb   ; fuera por la izquierda?
	cp 0ffh		;9cde
	jp nz,tras_meta_corre		;9ce0
	ld a,(ix+003h)		;9ce3
	cp 0e0h		;9ce6
	jp c,tras_meta_para		;9ce8
tras_meta_corre:		; Corre
	call caballo_mueve		;9ceb
	ret			;9cee
tras_meta_para:		; Parado: estado 0
	ld (ix+000h),000h		;9cef
	ret			;9cf3
jinetes:		; Los cuatro jinetes: un bloque de 8 bytes (0xE0FF) y un sprite cada uno, sobre su caballo
	ld ix,0e0ffh		;9cf4   ; el 1...
	ld iy,0e188h		;9cf8   ; ...sprite 0x02...
	ld de,0e081h		;9cfc   ; ...sobre el caballo 1
	ld c,000h		;9cff   ; el numero 0
	call jinete		;9d01
	ld ix,0e107h		;9d04   ; el 2
	ld iy,0e18ch		;9d08   ; el 2: sprite 0x03...
	ld de,0e0a1h		;9d0c   ; ...sobre el caballo 2
	ld c,001h		;9d0f
	call jinete		;9d11
	ld ix,0e10fh		;9d14   ; el 3
	ld iy,0e190h		;9d18   ; el 3: sprite 0x04...
	ld de,0e0c1h		;9d1c   ; ...sobre el caballo 3
	ld c,002h		;9d1f
	call jinete		;9d21
	ld ix,0e117h		;9d24   ; el 4
	ld iy,0e194h		;9d28   ; el 4: sprite 0x05...
	ld de,0e0e1h		;9d2c   ; ...sobre el caballo 4
	ld c,003h		;9d2f
jinete:		; Un jinete por su estado: 1 monta, 2 cabalga, 3 sale despedido, 4 la victoria
	ld a,(ix+000h)		;9d31
	call salta_tabla		;9d34

; ----------------------------------------------------------------------
; DATOS estados_jinete: Los cuatro estados del jinete
;   0x9d37..0x9d3f  (8 bytes)
DATA_estados_jinete:
	defw 09d3fh,09db1h,09e3fh,09e97h	; 9d37  -> jinete_monta jinete_cabalga jinete_cae jinete_victoria

; ======================================================================
; CODIGO 0x9d3f..0x9d99  (90 bytes)
; ======================================================================


jinete_monta:		; Estado 1: el bloque a cero, blanco, su numero y a cabalgar
	push ix		;9d3f
	pop hl			;9d41
	ld a,000h		;9d42
	ld b,008h		;9d44
	call llena		;9d46
	ld (iy+003h),00fh		;9d49   ; blanco
	ld (ix+002h),c		;9d4d   ; el numero
	call jinete_dibujo		;9d50
	ld (ix+000h),002h		;9d53
	ld (ix+001h),001h		;9d57
	ret			;9d5b
jinete_dibujo:		; El dibujo del jinete (0x9D99: dibujo, Y y X por numero y postura) sobre su caballo
	ld c,(ix+002h)		;9d5c   ; el numero
	ld a,(ix+003h)		;9d5f   ; la postura...
	add a,a			;9d62   ; ...x 4 + el numero...
	add a,a			;9d63   ; x 4
	add a,c			;9d64   ; + el numero
	ld c,a			;9d65
	add a,a			;9d66   ; ...x 3
	add a,c			;9d67   ; x 3
	ld c,a			;9d68
	ld b,000h		;9d69
	ld hl,09d99h		;9d6b   ; los dibujos del jinete
	add hl,bc			;9d6e
jinete_sprite:		; El sprite: dibujo, Y del caballo + dy, X del caballo + dx
	ld a,(hl)			;9d6f   ; el dibujo
	ld (iy+002h),a		;9d70   ; al sprite
	inc hl			;9d73
	ld c,(hl)			;9d74   ; dy
	ld a,(de)			;9d75   ; la Y del caballo...
	add a,c			;9d76   ; la Y del caballo + dy
	ld (iy+000h),a		;9d77   ; la Y
	inc hl			;9d7a   ; dx
	ld c,(hl)			;9d7b   ; la X...
	inc de			;9d7c
	ex de,hl			;9d7d
	ld e,(hl)			;9d7e   ; la X del caballo (16 bits)
	inc hl			;9d7f
	ld d,(hl)			;9d80
	ld l,c			;9d81   ; + dx
	res 7,(iy+003h)		;9d82   ; fuera?
	call sprite_x		;9d86   ; dentro de la pantalla?
	ld (iy+001h),a		;9d89   ; la X
	jr nc,L_9D91		;9d8c
	ld (iy+000h),a		;9d8e   ; fuera
L_9D91:
	bit 0,b		;9d91   ; por la izquierda?
	ret z			;9d93
	set 7,(iy+003h)		;9d94   ; la X corrida 32 pixeles
	ret			;9d98

; ----------------------------------------------------------------------
; DATOS jinetes_dibujos: Los dibujos del jinete: los cuatro numeros sentado y
;   los cuatro con el latigo (dibujo, dy, dx)
;   0x9d99..0x9db1  (24 bytes)
DATA_jinetes_dibujos:
	defb 0b4h,0f7h,0fbh	; 9d99
	defb 0b8h,0f7h,0fbh	; 9d9c
	defb 0bch,0f7h,0fbh	; 9d9f
	defb 0c0h,0f7h,0fbh	; 9da2
	defb 0c4h,0f5h,0fbh	; 9da5
	defb 0c8h,0f5h,0fbh	; 9da8
	defb 0cch,0f5h,0fbh	; 9dab
	defb 0d0h,0f5h,0fbh	; 9dae

; ======================================================================
; CODIGO 0x9db1..0x9de5  (52 bytes)
; ======================================================================


jinete_cabalga:		; Estado 2: sentado, o el latigo si lo usa (con el caballo en los estados 2, 3, 6 o 7); sube y baja con el galope (0x9E35)
	push de			;9db1
	ld (ix+003h),000h		;9db2   ; sentado
	ld hl,09de5h		;9db6   ; su caballo
	call tabla_palabra		;9db9   ; el bloque del caballo
	ld a,(hl)			;9dbc   ; el estado del caballo...
	cp 002h		;9dbd   ; estado 0 o 1?
	jr c,jinete_galope		;9dbf
	cp 004h		;9dc1   ; 2 o 3?
	jr c,L_9DC9		;9dc3
	cp 006h		;9dc5   ; 4 o 5?
	jr c,jinete_galope		;9dc7
L_9DC9:
	call latigo		;9dc9   ; ...2, 3, 6 o 7: el latigo
jinete_galope:		; La Y segun el dibujo del caballo
	pop de			;9dcc   ; el sitio del caballo
	push de			;9dcd
	call jinete_dibujo		;9dce   ; el dibujo
	pop hl			;9dd1   ; el byte +5 del caballo...
	inc hl			;9dd2
	inc hl			;9dd3
	inc hl			;9dd4
	ld c,(hl)			;9dd5   ; ...su dibujo
	ld b,000h		;9dd6
	ld hl,09e35h		;9dd8   ; la Y que le toca
	add hl,bc			;9ddb
	ld c,(hl)			;9ddc
	ld a,(iy+000h)		;9ddd   ; la Y del sprite...
	add a,c			;9de0   ; ...mas eso
	ld (iy+000h),a		;9de1
	ret			;9de4

; ----------------------------------------------------------------------
; DATOS caballos_tabla: Los bloques de los cuatro caballos
;   0x9de5..0x9ded  (8 bytes)
DATA_caballos_tabla:
	defw 0e07fh,0e09fh,0e0bfh,0e0dfh	; 9de5

; ======================================================================
; CODIGO 0x9ded..0x9e35  (72 bytes)
; ======================================================================


tabla_palabra:		; HL = la palabra C de la tabla HL
	ld a,c			;9ded
	add a,a			;9dee   ; C x 2
	ld c,a			;9def
	ld b,000h		;9df0
	add hl,bc			;9df2
	ld e,(hl)			;9df3   ; la palabra
	inc hl			;9df4
	ld d,(hl)			;9df5
	ex de,hl			;9df6   ; en HL
	ret			;9df7
latigo:		; El latigo: si su caballo lo lleva (bit 5 de 0xE13F), 16 cuadros arriba y abajo; en el modo A, solo el jinete del jugador
	ld hl,0e13fh		;9df8
	ld c,(ix+002h)		;9dfb
	ld b,000h		;9dfe
	add hl,bc			;9e00
	ld a,(0e001h)		;9e01   ; el jinete: solo el del jugador
	and a			;9e04
	jr nz,latigo_cuenta		;9e05
	bit 0,(hl)		;9e07
	ret z			;9e09
latigo_cuenta:		; Empieza a contar?...
	ld a,(ix+004h)		;9e0a
	and a			;9e0d
	jr nz,latigo_sube		;9e0e
	bit 5,(hl)		;9e10   ; ...si el caballo usa el latigo...
	jr z,latigo_postura		;9e12
	push af			;9e14
	ld hl,0e147h		;9e15   ; ...con su sonido
	set 6,(hl)		;9e18
	pop af			;9e1a
latigo_sube:		; La cuenta, hasta 16
	inc (ix+004h)		;9e1b
	cp 010h		;9e1e
	jr c,latigo_postura		;9e20
	ld (ix+004h),000h		;9e22
	ld a,000h		;9e26
latigo_postura:		; Ocho cuadros con el latigo, ocho sin el
	bit 3,(ix+004h)		;9e28
	ld a,000h		;9e2c
	jr z,latigo_pon		;9e2e
	inc a			;9e30
latigo_pon:		; La postura
	ld (ix+003h),a		;9e31
	ret			;9e34

; ----------------------------------------------------------------------
; DATOS galope_y: La Y del jinete con cada dibujo del caballo
;   0x9e35..0x9e3f  (10 bytes)
DATA_galope_y:
	defb 000h,000h,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh	; 9e35  ..........

; ======================================================================
; CODIGO 0x9e3f..0x9e45  (6 bytes)
; ======================================================================


jinete_cae:		; Estado 3: sale despedido
	ld a,(ix+001h)		;9e3f
	call salta_tabla		;9e42

; ----------------------------------------------------------------------
; DATOS pasos_jinete_cae: Los dos pasos: empieza y vuela
;   0x9e45..0x9e49  (4 bytes)
DATA_pasos_jinete_cae:
	defw 09e49h,09e56h	; 9e45  -> jinete_cae_empieza jinete_vuela

; ======================================================================
; CODIGO 0x9e49..0x9e7f  (54 bytes)
; ======================================================================


jinete_cae_empieza:		; Paso 1: desde el principio de la trayectoria
	ld (ix+005h),000h		;9e49
	ld (ix+006h),010h		;9e4d
	ld (ix+001h),002h		;9e51
	ret			;9e55
jinete_vuela:		; Paso 2: la trayectoria (0x9E7F: dibujo, dy, dx), un punto mas cada vez que la cuenta pasa de 64, hasta el 7
	push de			;9e56   ; lo de quien llama
	push ix		;9e57   ; la cuenta del jinete...
	pop hl			;9e59
	ld de,00006h		;9e5a   ; ...en +6
	add hl,de			;9e5d
	call suma_paso		;9e5e   ; pasa de 64?
	and a			;9e61
	jr z,jinete_vuela_pon		;9e62
	ld a,(ix+005h)		;9e64   ; el punto...
	cp 007h		;9e67   ; ...el ultimo?
	jr nc,jinete_vuela_pon		;9e69
	inc (ix+005h)		;9e6b   ; el siguiente
jinete_vuela_pon:		; El punto x 3
	ld c,(ix+005h)		;9e6e   ; el punto...
	ld a,c			;9e71
	add a,a			;9e72   ; ...x 3
	add a,c			;9e73
	ld c,a			;9e74
	ld b,000h		;9e75
	ld hl,09e7fh		;9e77   ; la trayectoria
	add hl,bc			;9e7a
	pop de			;9e7b
	jp jinete_sprite		;9e7c   ; el sprite

; ----------------------------------------------------------------------
; DATOS jinete_trayectoria: Los ocho puntos del jinete despedido: dibujo, dy,
;   dx
;   0x9e7f..0x9e97  (24 bytes)
DATA_jinete_trayectoria:
	defb 0d4h,0f5h,0f9h	; 9e7f
	defb 0d4h,0f4h,0fah	; 9e82
	defb 0d4h,0f1h,0fdh	; 9e85
	defb 0dch,0fah,0ffh	; 9e88
	defb 0dch,0fdh,000h	; 9e8b
	defb 0dch,0ffh,000h	; 9e8e
	defb 0d8h,001h,000h	; 9e91
	defb 0d8h,002h,001h	; 9e94

; ======================================================================
; CODIGO 0x9e97..0x9ea7  (16 bytes)
; ======================================================================


jinete_victoria:		; Estado 4: el jinete del primero levanta el brazo, ocho cuadros si y ocho no (0x9EA7 y 0x9EAA)
	ld hl,09ea7h		;9e97
	ld a,(0e07bh)		;9e9a
	bit 3,a		;9e9d
	jr z,jinete_victoria_pon		;9e9f
	ld hl,09eaah		;9ea1
jinete_victoria_pon:		; El dibujo
	jp jinete_sprite		;9ea4

; ----------------------------------------------------------------------
; DATOS jinete_brazo: Las dos posturas de la victoria (dibujo, dy, dx)
;   0x9ea7..0x9ead  (6 bytes)
DATA_jinete_brazo:
	defb 034h,0f2h,0fbh	; 9ea7
	defb 038h,0f2h,0fbh	; 9eaa

; ======================================================================
; CODIGO 0x9ead..0x9ee6  (57 bytes)
; ======================================================================


meta_luz:		; Cada vez que llega un caballo, la luz de lo alto de la meta (las tres ultimas lineas de la casilla 0x1F) se pone blanca 8 cuadros y vuelve al azul
	ld hl,0e145h		;9ead
	bit 6,(hl)		;9eb0   ; ya parpadea?
	jr nz,meta_cuenta		;9eb2
	bit 7,(hl)		;9eb4   ; ha llegado alguno?
	ret z			;9eb6
	set 6,(hl)		;9eb7
	call meta_color1		;9eb9
	xor a			;9ebc
	ld (0e146h),a		;9ebd
	ret			;9ec0
meta_cuenta:		; Un cuadro mas: hasta 16
	ld hl,0e146h		;9ec1
	inc (hl)			;9ec4   ; un cuadro mas
	ld a,(hl)			;9ec5
	cp 010h		;9ec6   ; 16: se acaba
	jr nc,meta_para		;9ec8
	cp 008h		;9eca   ; a los 8...
	ret c			;9ecc
	call meta_color2		;9ecd   ; ...de vuelta al azul
	ret			;9ed0
meta_para:		; Se acaba
	xor a			;9ed1
	ld (0e145h),a		;9ed2
	ret			;9ed5
meta_color1:		; El color 0x1F (blanco) en las lineas 5-7 de la casilla 0x1F del primer tercio...
	ld a,01fh		;9ed6
meta_color:		; ...FILVRM
	ld hl,020fdh		;9ed8
	ld bc,00003h		;9edb
	call 00056h		;9ede
	ret			;9ee1
meta_color2:		; ...o 0x14 (azul)
	ld a,014h		;9ee2
	jr meta_color		;9ee4

; ----------------------------------------------------------------------
; DATOS ret_suelto: Un "ret" al que no se llega: 0x9EE2 salta a 0x9ED8, que
;   vuelve por su cuenta
;   0x9ee6..0x9ee7  (1 bytes)
DATA_ret_suelto:
	defb 0c9h	; 9ee6

; ======================================================================
; CODIGO 0x9ee7..0x9f44  (93 bytes)
; ======================================================================


sonidos:		; Los sonidos de la carrera en el canal 1, si esta libre: la caida (bit 7 de 0xE147), el latigo (6) o el golpe (5)
	ld a,(0e06ch)		;9ee7
	cp 002h		;9eea
	ret nz			;9eec
	ld a,(0f024h)		;9eed   ; el canal 1 suena?
	and a			;9ef0
	ret nz			;9ef1
	ld hl,0e147h		;9ef2   ; lo que ha pasado
	ld a,(hl)			;9ef5
	add a,a			;9ef6   ; bit 7: la caida
	jr c,sonido_caida		;9ef7
	add a,a			;9ef9   ; bit 6: el latigo
	jr c,sonido_latigo		;9efa
	add a,a			;9efc   ; bit 5: el golpe
	ret nc			;9efd
	ld (hl),000h		;9efe   ; (0xBF76)
	ld de,0bf76h		;9f00
	jr sonido_pon		;9f03
sonido_caida:		; La caida (0xBE33)
	ld (hl),000h		;9f05
	ld de,0be33h		;9f07
	jr sonido_pon		;9f0a
sonido_latigo:		; El latigo (0xBEC9)
	ld (hl),000h		;9f0c
	ld de,0bec9h		;9f0e
sonido_pon:		; En el canal 1
	ld b,001h		;9f11
	call pieza		;9f13
	ret			;9f16
marca_puesto:		; El jinete: si su caballo llega primero o segundo, el sprite 0 parpadea junto a 1ST o 2ND
	ld a,(0e001h)		;9f17   ; solo el jinete
	and a			;9f1a
	ret nz			;9f1b
	ld a,(0e144h)		;9f1c   ; ha llegado?
	and a			;9f1f
	jr z,marca_puesto_fuera		;9f20
	cp 003h		;9f22   ; primero o segundo...
	ret nc			;9f24
	ld hl,09f44h		;9f25   ; ...la X, el dibujo y el color
	ld de,0e181h		;9f28
	ld bc,00003h		;9f2b
	ldir		;9f2e
	ld hl,0e07bh		;9f30   ; parpadea cada 16 cuadros
	bit 4,(hl)		;9f33
	jr z,marca_puesto_y		;9f35
marca_puesto_fuera:		; Fuera
	xor a			;9f37
marca_puesto_y:		; La Y de la tabla en el sprite 0
	ld hl,09f47h		;9f38
	ld c,a			;9f3b   ; el puesto (o 0)
	ld b,000h		;9f3c
	add hl,bc			;9f3e
	ld a,(hl)			;9f3f
	ld (0e180h),a		;9f40   ; la Y del sprite 0
	ret			;9f43

; ----------------------------------------------------------------------
; DATOS marca_puesto_tabla: El sprite de la marca (X 0x38, dibujo 0xAC, gris)
;   y las tres Y: fuera (0xC2), en la fila de 1ST y en la de 2ND
;   0x9f44..0x9f4a  (6 bytes)
DATA_marca_puesto_tabla:
	defb 038h,0ach,00eh	; 9f44
	defb 0c2h,017h,01fh	; 9f47

; ======================================================================
; CODIGO 0x9f4a..0xa0fb  (433 bytes)
; ======================================================================


fuerzas:		; Cada paso de la pista: la fuerza de cada caballo se reparte con lo que le queda por correr, y el ordenador elige el paso de los suyos
	ld a,(0e071h)		;9f4a   ; el paso de la pista...
	ld c,a			;9f4d
	ld a,(0f0eah)		;9f4e   ; ...es otro?
	xor c			;9f51
	ret z			;9f52
	ld a,c			;9f53
	ld (0f0eah),a		;9f54
	push ix		;9f57
	ld ix,0e03fh		;9f59   ; las fuerzas
	ld b,004h		;9f5d   ; cuatro caballos
	ld hl,0f080h		;9f5f   ; las cuentas de cada uno (8 bytes)
fuerzas_uno:		; Un caballo: su cuenta menos la fuerza (sin bajar de 0)...
	push hl			;9f62
	ld e,(ix+000h)		;9f63
	ld d,(ix+001h)		;9f66
	call palabra_menos		;9f69
	ld l,e			;9f6c   ; ...la mitad, redondeada hacia arriba...
	ld h,d			;9f6d
	srl h		;9f6e
	rr l		;9f70
	jr nc,L_9F75		;9f72
	inc l			;9f74
L_9F75:
	ld a,(ix+000h)		;9f75   ; ...se le quita a la fuerza (sin bajar de 0)
	sub l			;9f78
	ld (ix+000h),a		;9f79
	ld a,(ix+001h)		;9f7c
	sbc a,h			;9f7f
	jr nc,fuerzas_resta		;9f80
	xor a			;9f82
	ld (ix+000h),a		;9f83
fuerzas_resta:		; La fuerza nueva
	ld (ix+001h),a		;9f86   ; el byte alto
	add hl,de			;9f89   ; la mitad, mas la cuenta
	ex de,hl			;9f8a
	pop hl			;9f8b   ; las cuentas
	push hl			;9f8c
	push de			;9f8d
	exx			;9f8e   ; la mitad mas la cuenta, en DE'
	pop de			;9f8f
	exx			;9f90
	call palabra_menos_pon		;9f91   ; a la cuenta, sin bajar de 0
	call palabra_cero		;9f94   ; las tres palabras siguientes: alguna no es 0?
	jr nz,fuerzas_cuenta		;9f97   ; la primera no es 0
	call palabra_cero		;9f99   ; la segunda...
	jr nz,fuerzas_cuenta		;9f9c
	call palabra_cero		;9f9e   ; ...o la tercera
	jr z,fuerzas_sig		;9fa1   ; todas 0: no se guarda
fuerzas_cuenta:		; Se vuelve a guardar
	exx			;9fa3   ; la cuenta nueva (DE')
	push de			;9fa4
	exx			;9fa5
	pop de			;9fa6
	call palabra_menos_pon		;9fa7   ; guardada, sin bajar de 0
	call c,palabra_menos_antes		;9faa
fuerzas_sig:		; El caballo siguiente
	pop hl			;9fad
	call siguiente8		;9fae
	djnz fuerzas_uno		;9fb1
	ld hl,0f0a0h		;9fb3   ; la cuenta de la carrera (0xF0A0)...
	call palabra_baja		;9fb6
	jr z,fuerzas_paso		;9fb9
	ld bc,00000h		;9fbb   ; ...y las de los caballos: cual llega antes a 0 (BC)
	call palabra_baja		;9fbe
	call z,palabra_baja		;9fc1
	call z,palabra_baja		;9fc4
fuerzas_paso:		; Lo que queda (0xF0CE) y el paso de cada caballo del ordenador
	ld (0f0ceh),de		;9fc7
	ld hl,0f080h		;9fcb
	add hl,bc			;9fce
	push hl			;9fcf
	exx			;9fd0
	pop hl			;9fd1
	ld ix,0e041h		;9fd2   ; el paso de los cuatro
	ld b,004h		;9fd6
	ld a,(0e002h)		;9fd8   ; el del jugador no
	and 007h		;9fdb
fuerzas_paso_uno:		; Uno: su cuenta x 8 entre lo que queda; 4 menos eso, de 0 a 7, es el paso (bits 2-4)
	dec a			;9fdd   ; es el del jugador?
	jp z,fuerzas_paso_sig		;9fde   ; si: no se toca
	push af			;9fe1
	push bc			;9fe2
	push hl			;9fe3
	ld e,(hl)			;9fe4   ; su cuenta
	inc hl			;9fe5
	ld d,(hl)			;9fe6
	push de			;9fe7
	exx			;9fe8   ; en HL'...
	pop hl			;9fe9
	add hl,hl			;9fea   ; ...x 8
	add hl,hl			;9feb
	add hl,hl			;9fec
	ld de,(0f0ceh)		;9fed   ; lo que queda...
	ld a,e			;9ff1   ; ...es 0?: el paso 7 (0x1C)
	or d			;9ff2
	ld a,01ch		;9ff3   ; el paso mas lento
	jr z,fuerzas_paso_pon		;9ff5
	call divide		;9ff7   ; la division
	ld de,00004h		;9ffa   ; menos 4
	or a			;9ffd
	sbc hl,de		;9ffe
	ld a,l			;a000   ; el paso: 4 - el cociente
	neg		;a001   ; 4 - el cociente...
	and 007h		;a003   ; ...de 0 a 7...
	add a,a			;a005   ; ...en los bits 2-4
	add a,a			;a006   ; x 4: en los bits 2-4
fuerzas_paso_pon:		; El paso en su byte
	ld l,a			;a007
	ld a,(ix+000h)		;a008   ; el byte del paso...
	and 0e3h		;a00b   ; ...sin los bits 2-4...
	or l			;a00d   ; ...con los nuevos
	ld (ix+000h),a		;a00e
	pop hl			;a011   ; lo de antes
	pop bc			;a012
	pop af			;a013
fuerzas_paso_sig:		; El caballo siguiente
	call siguiente8		;a014   ; las cuentas siguientes
	djnz fuerzas_paso_uno		;a017   ; los cuatro
	pop ix		;a019
	ret			;a01b
fuerzas_empieza:		; Al empezar la carrera: la fuerza de cada caballo es la de la distancia (0xA105) mas sus dos numeros al azar (el segundo con signo, bit 3)
	ld hl,(0e000h)		;a01c   ; la carrera...
	ld h,000h		;a01f
	dec l			;a021
	ld de,08da3h		;a022
	add hl,de			;a025
	ld a,(hl)			;a026   ; ...su distancia
	and 007h		;a027
	ld c,a			;a029
	push bc			;a02a
	ld l,c			;a02b
	ld h,000h		;a02c
	ld de,0a105h		;a02e   ; la fuerza de la distancia
	call tabla_w		;a031
	ld hl,0e03fh		;a034   ; los cuatro caballos
	ld b,004h		;a037
fuerzas_empieza_uno:		; Uno: el primer numero...
	push bc			;a039
	push de			;a03a
	ld c,(hl)			;a03b   ; el primer numero
	inc hl			;a03c
	ld a,(hl)			;a03d   ; ...el segundo: bit 3 el signo
	ld b,000h		;a03e   ; BC = el primero
	push hl			;a040
	bit 3,a		;a041   ; el segundo es negativo?
	res 3,a		;a043   ; sin el signo
	ld h,b			;a045
	ld l,a			;a046   ; positivo
	jr z,fuerzas_empieza_suma		;a047
	cpl			;a049   ; negativo
	dec h			;a04a   ; negativo: 0xFF...
	ld l,a			;a04b   ; ...complemento a dos
	inc hl			;a04c
fuerzas_empieza_suma:		; La suma, mas la de la distancia...
	add hl,bc			;a04d   ; la suma...
	add hl,de			;a04e   ; ...mas la de la distancia
	ex de,hl			;a04f
	pop hl			;a050
	dec hl			;a051   ; la fuerza...
	call palabra_pon		;a052   ; ...es la fuerza
	ld a,(hl)			;a055   ; de los dos bytes de despues, solo los bits 0-1
	and 003h		;a056   ; el byte de despues...
	ld (hl),a			;a058   ; ...solo los bits 0-1
	inc hl			;a059   ; el caballo siguiente
	inc hl			;a05a
	pop de			;a05b
	pop bc			;a05c
	djnz fuerzas_empieza_uno		;a05d   ; cuatro
	pop bc			;a05f   ; la distancia
	ld l,c			;a060   ; los pasos de la carrera (0xA0FB)...
	ld h,000h		;a061
	ld de,0a0fbh		;a063   ; la tabla de los pasos
	call tabla_w		;a066
	ex de,hl			;a069   ; los pasos de la carrera
	ld (0f0a0h),hl		;a06a   ; ...en 0xF0A0
	ld hl,0f080h		;a06d   ; la fuerza de cada uno, a sus cuentas
	ld ix,0e03fh		;a070   ; la fuerza...
	ld b,004h		;a074   ; ...de los cuatro
fuerzas_copia:		; Una
	ld a,(ix+000h)		;a076
	ld (hl),a			;a079
	inc hl			;a07a
	ld a,(ix+001h)		;a07b
	ld (hl),a			;a07e
	dec hl			;a07f
	call siguiente8		;a080
	djnz fuerzas_copia		;a083
	call tercios_carrera		;a085   ; los tercios
	call tercios_caballos		;a088
	ld hl,0f082h		;a08b   ; y las cuentas segun los bits 0-1 de cada caballo
	ld ix,0e041h		;a08e
	ld b,004h		;a092
fuerzas_estilo:		; Uno: 3 no cambia; si no, se pasa un octavo de una cuenta a otra
	push hl			;a094
	push bc			;a095
	ld a,(ix+000h)		;a096   ; 3?
	cp 003h		;a099
	jr z,fuerzas_estilo_sig		;a09b
	call palabra_lee		;a09d   ; un octavo...
	ld b,003h		;a0a0
fuerzas_octavo:		; ...entre 8
	or a			;a0a2
	rr d		;a0a3
	rr e		;a0a5
	djnz fuerzas_octavo		;a0a7
	jr z,fuerzas_quita2		;a0a9   ; es 0?
	dec a			;a0ab   ; 1 o 2: de que cuenta a cual
	jr z,fuerzas_quita		;a0ac
	inc hl			;a0ae
	inc hl			;a0af
fuerzas_quita:		; Se quita de una y se suma a la otra
	call palabra_resta		;a0b0
	call palabra_suma		;a0b3
	jr fuerzas_estilo_sig		;a0b6
fuerzas_quita2:		; Al reves
	call palabra_suma		;a0b8
	call palabra_resta		;a0bb
fuerzas_estilo_sig:		; El siguiente
	pop bc			;a0be
	pop hl			;a0bf
	call siguiente8		;a0c0
	djnz fuerzas_estilo		;a0c3
	ret			;a0c5
tercios_carrera:		; La cuenta de la carrera (0xF0A0) partida en tres
	ld hl,0f0a0h		;a0c6   ; la cuenta de la carrera
	ld b,001h		;a0c9   ; una
	jr tercios_uno		;a0cb
tercios_caballos:		; Las de los cuatro caballos
	ld hl,0f080h		;a0cd   ; las de los cuatro caballos
	ld b,004h		;a0d0   ; cuatro
tercios_uno:		; Una: un tercio, otro tercio y lo que sobra
	ld e,(hl)			;a0d2   ; la palabra
	inc hl			;a0d3
	ld d,(hl)			;a0d4
	inc hl			;a0d5
	push de			;a0d6   ; el total
	push bc			;a0d7
	push hl			;a0d8
	ex de,hl			;a0d9   ; entre 3
	ld de,00003h		;a0da   ; ...3
	call divide		;a0dd   ; (0xA184)
	ex de,hl			;a0e0   ; DE = el tercio
	pop hl			;a0e1
	pop bc			;a0e2
	call palabra_pon		;a0e3   ; el tercio dos veces
	call palabra_pon		;a0e6   ; en las dos siguientes
	push de			;a0e9   ; el tercio, a DE'
	exx			;a0ea
	pop de			;a0eb
	pop hl			;a0ec   ; HL' = el total
	or a			;a0ed   ; lo que sobra: el total menos dos tercios
	sbc hl,de		;a0ee   ; menos un tercio...
	sbc hl,de		;a0f0   ; ...y otro
	push hl			;a0f2
	exx			;a0f3
	pop de			;a0f4   ; lo que sobra...
	call palabra_pon		;a0f5   ; ...en la cuarta
	djnz tercios_uno		;a0f8   ; la siguiente
	ret			;a0fa

; ----------------------------------------------------------------------
; DATOS distancias: Los pasos de pista de cada distancia (48, 64, 96, 128 y
;   144: de 25 m en 25 m) y la fuerza de los caballos para cada una (127, 169,
;   254, 339 y 382)
;   0xa0fb..0xa10f  (20 bytes)
DATA_distancias:
	defw 00030h,00040h,00060h,00080h,00090h	; a0fb
	defw 0007fh,000a9h,000feh,00153h,0017eh	; a105

; ======================================================================
; CODIGO 0xa10f..0xa2ef  (480 bytes)
; ======================================================================


palabra_suma:		; (HL) += DE
	push de			;a10f
	push hl			;a110
	push de			;a111
	call palabra_lee		;a112   ; la palabra
	ex de,hl			;a115
	pop de			;a116
	add hl,de			;a117   ; mas DE
palabra_guarda:		; Lo guarda
	ex de,hl			;a118
	pop hl			;a119
	call palabra_pon		;a11a
	pop de			;a11d
	ret			;a11e
palabra_resta:		; (HL) -= DE
	push de			;a11f
	push hl			;a120
	push de			;a121
	call palabra_lee		;a122   ; la palabra
	ex de,hl			;a125
	pop de			;a126
	or a			;a127
	sbc hl,de		;a128   ; menos DE
	jr palabra_guarda		;a12a
palabra_cero:		; Z si la palabra (HL) es 0; si lo es, HL pasa a la siguiente
	call palabra_lee		;a12c
	ld a,e			;a12f   ; es 0?
	or d			;a130
	ret nz			;a131
	inc hl			;a132   ; la siguiente
	inc hl			;a133
	ret			;a134
palabra_baja:		; Una palabra menos: si llega a 0, BC + 2 (cuenta cual)
	call palabra_lee		;a135
	ld a,e			;a138   ; es 0?
	or d			;a139
	jr z,palabra_baja_cero		;a13a
	dec de			;a13c   ; una menos
	call palabra_pon		;a13d
	ld a,e			;a140   ; la parte baja no es 0?
	or a			;a141
	ret nz			;a142
	jr palabra_baja_bc		;a143
palabra_baja_cero:		; Ya era 0
	inc hl			;a145
	inc hl			;a146
palabra_baja_bc:		; BC + 2
	inc bc			;a147
	inc bc			;a148
	ret			;a149
tabla_w:		; DE = la palabra HL de la tabla DE
	add hl,hl			;a14a   ; el indice x 2
	add hl,de			;a14b
	ld e,(hl)			;a14c   ; la palabra
	inc hl			;a14d
	ld d,(hl)			;a14e
	ret			;a14f
cuenta_caballo:		; HL = 0xF080 + B x 8: las cuentas del caballo B. Nadie la llama
	ld de,0f080h		;a150   ; las cuentas...
	ld l,b			;a153   ; ...B x 8
	ld h,000h		;a154
	add hl,hl			;a156
	add hl,hl			;a157
	add hl,hl			;a158
	add hl,de			;a159
	ret			;a15a
palabra_lee:		; DE = la palabra (HL), sin mover HL
	ld e,(hl)			;a15b
	inc hl			;a15c
	ld d,(hl)			;a15d
	dec hl			;a15e
	ret			;a15f
palabra_menos:		; DE = (HL) - DE, sin bajar de 0
	push hl			;a160
	push de			;a161
	call palabra_lee		;a162   ; la palabra
	ex de,hl			;a165
	pop de			;a166
	or a			;a167
	sbc hl,de		;a168   ; menos DE
	jr nc,palabra_menos_fin		;a16a
	ld hl,00000h		;a16c   ; sin bajar de 0
palabra_menos_fin:		; ...
	ex de,hl			;a16f
	pop hl			;a170
	ret			;a171
palabra_menos_pon:		; (HL) = (HL) - DE, sin bajar de 0
	call palabra_menos		;a172
palabra_pon:		; (HL) = DE y HL + 2
	ld (hl),e			;a175
	inc hl			;a176
	ld (hl),d			;a177
	inc hl			;a178
	ret			;a179
palabra_menos_antes:		; La palabra anterior a 0 y la resta en esta
	dec hl			;a17a
	dec hl			;a17b
	ld (hl),000h		;a17c   ; la palabra anterior a 0
	inc hl			;a17e
	ld (hl),000h		;a17f
	inc hl			;a181
	jr palabra_menos_pon		;a182
divide:		; HL = HL / DE (16 bits): el divisor se corre a la izquierda y se resta bit a bit
	ld b,000h		;a184   ; cuantos bits se corre
	ex de,hl			;a186
divide_corre:		; El divisor a la izquierda hasta que se sale un bit
	add hl,hl			;a187
	inc b			;a188
	jr c,divide_resta		;a189
	ld a,b			;a18b   ; 16 veces sin salir: es 0
	cp 010h		;a18c
	jr nz,divide_corre		;a18e
	ex de,hl			;a190
	ret			;a191
divide_resta:		; El bit que se ha salido, de vuelta
	rr h		;a192
	rr l		;a194
	ex de,hl			;a196
	exx			;a197
	ld hl,00000h		;a198   ; el cociente, en HL'
	exx			;a19b
divide_bit:		; Cabe?...
	or a			;a19c
	push hl			;a19d
	sbc hl,de		;a19e
	jr c,divide_baja		;a1a0
	pop hl			;a1a2
	sbc hl,de		;a1a3   ; ...si: se resta y el cociente uno mas
	exx			;a1a5
	inc hl			;a1a6
	exx			;a1a7
	jr divide_bit		;a1a8
divide_baja:		; No cabe: el siguiente bit
	pop hl			;a1aa
	dec b			;a1ab
	jr z,divide_fin		;a1ac
	exx			;a1ae
	add hl,hl			;a1af   ; el cociente x 2
	exx			;a1b0
	srl d		;a1b1   ; el divisor a la derecha
	rr e		;a1b3
	jr divide_bit		;a1b5
divide_fin:		; El cociente en HL
	exx			;a1b7
	ret			;a1b8
cuotas:		; Las cuotas de las seis parejas: cuanto mas fuertes los dos caballos, menos pagan (de 2 a 99)
	ld hl,0f0b0h		;a1b9   ; hay que hacerlas?
	bit 7,(hl)		;a1bc
	ret z			;a1be
	res 7,(hl)		;a1bf
	ld hl,0e03fh		;a1c1   ; la fuerza mas baja de los cuatro...
	ld de,00004h		;a1c4
	ld b,003h		;a1c7
	ld a,(hl)			;a1c9
	ld c,a			;a1ca
cuotas_min:		; ...
	add hl,de			;a1cb
	cp (hl)			;a1cc
	jr c,cuotas_min_sig		;a1cd
	ld a,(hl)			;a1cf
	ld c,a			;a1d0
cuotas_min_sig:		; ...
	djnz cuotas_min		;a1d1
	push bc			;a1d3   ; ...y la mas alta
	ld hl,0e03fh		;a1d4
	ld b,003h		;a1d7
	ld a,(hl)			;a1d9
	ld c,a			;a1da
cuotas_max:		; ...
	add hl,de			;a1db
	cp (hl)			;a1dc
	jr nc,cuotas_max_sig		;a1dd
	ld a,(hl)			;a1df
	ld c,a			;a1e0
cuotas_max_sig:		; ...
	djnz cuotas_max		;a1e1
	ld a,c			;a1e3   ; la diferencia, menos 10...
	pop bc			;a1e4
	sub c			;a1e5
	sub 00ah		;a1e6
	ld c,01fh		;a1e8   ; ...si no llega, 0x1F...
	jr c,cuotas_factor		;a1ea
	ld hl,0a2efh		;a1ec   ; ...si no, de la tabla 0xA2EF
	call suma_a		;a1ef
	ld c,(hl)			;a1f2
cuotas_factor:		; El factor (0xF0C7)
	ld a,c			;a1f3
	ld (0f0c7h),a		;a1f4   ; el factor de las cuotas
	ld de,0f0b7h		;a1f7   ; lo de cada pareja, en 0xF0B7...
	ld bc,00000h		;a1fa   ; ...y la suma en BC
	ld a,(0e03fh)		;a1fd   ; 1-2
	ld l,a			;a200   ; 1...
	ld a,(0e043h)		;a201   ; ...y 2
	call cuotas_pareja		;a204
	ld a,(0e03fh)		;a207   ; 1-3
	ld l,a			;a20a   ; 1 y 3
	ld a,(0e047h)		;a20b
	call cuotas_pareja		;a20e
	ld a,(0e03fh)		;a211   ; 1-4
	ld l,a			;a214   ; 1 y 4
	ld a,(0e04bh)		;a215
	call cuotas_pareja		;a218
	ld a,(0e043h)		;a21b   ; 2-3
	ld l,a			;a21e   ; 2 y 3
	ld a,(0e047h)		;a21f
	call cuotas_pareja		;a222
	ld a,(0e043h)		;a225   ; 2-4
	ld l,a			;a228   ; 2 y 4
	ld a,(0e04bh)		;a229
	call cuotas_pareja		;a22c
	ld a,(0e047h)		;a22f   ; 3-4
	ld l,a			;a232   ; 3 y 4
	ld a,(0e04bh)		;a233
	call cuotas_pareja		;a236
	ld (0f0c3h),bc		;a239   ; la suma de las seis
	ld hl,0f0b7h		;a23d   ; lo de cada pareja...
	ld de,0f0b7h		;a240   ; ...y alli las cuotas
	ld b,006h		;a243   ; seis cuotas
cuota_calcula:		; Una: la suma x el factor entre lo de la pareja
	push de			;a245
	xor a			;a246   ; sin parte alta
	ld (0f0b6h),a		;a247
	ld a,(0f0c7h)		;a24a   ; el factor...
	ld e,(hl)			;a24d   ; ...por lo de la pareja
	inc hl			;a24e   ; DE = lo de la pareja
	ld d,(hl)			;a24f
	inc hl			;a250
	push bc			;a251
	push hl			;a252
	call multiplica		;a253   ; el factor x lo de la pareja
	ld de,(0f0c3h)		;a256   ; entre la suma, restando
	ld a,(0f0b6h)		;a25a   ; la parte alta de la multiplicacion
	ld c,a			;a25d
	xor a			;a25e   ; el cociente
cuotas_resta:		; Una resta mas
	or a			;a25f
	inc a			;a260   ; uno mas
	sbc hl,de		;a261   ; menos la suma
	jr nc,cuotas_resta		;a263   ; cabe otra vez
	push af			;a265
	ld a,c			;a266   ; quedan partes altas?
	or a			;a267
	jr z,cuotas_cociente		;a268
	dec c			;a26a   ; una menos
	pop af			;a26b
	jr cuotas_resta		;a26c
cuotas_cociente:		; El cociente
	pop af			;a26e
	dec a			;a26f   ; el cociente
	pop hl			;a270
	pop bc			;a271
	cp 002h		;a272   ; al menos 2
	jr nc,cuotas_pon		;a274   ; al menos 2
	ld a,002h		;a276   ; 2
cuotas_pon:		; La cuota
	pop de			;a278
	ld (de),a			;a279   ; la cuota
	inc de			;a27a
	djnz cuota_calcula		;a27b   ; las seis
	ld hl,0f0b7h		;a27d   ; las seis a BCD
	ld e,00ah		;a280   ; de 10 en 10
cuotas_bcd:		; Una: las decenas...
	ld a,(hl)			;a282   ; la cuota
	ld d,000h		;a283   ; las decenas
cuotas_bcd_10:		; ...de 10 en 10
	cp e			;a285
	jr c,cuotas_bcd_pon		;a286   ; menos de 10?
	sub e			;a288   ; 10 menos...
	inc d			;a289   ; ...una decena mas
	jr cuotas_bcd_10		;a28a
cuotas_bcd_pon:		; Las decenas arriba, las unidades abajo
	ld c,a			;a28c   ; las unidades
	ld a,d			;a28d   ; las decenas...
	add a,a			;a28e   ; ...arriba
	add a,a			;a28f
	add a,a			;a290
	add a,a			;a291
	or c			;a292   ; ...con las unidades
	ld c,000h		;a293   ; las centenas de lo que se ha juntado
cuotas_bcd_100:		; Lo que pasa de 100...
	sub 00ah		;a295   ; menos 10
	jr c,cuotas_bcd_99		;a297
	inc c			;a299   ; una mas
	jr cuotas_bcd_100		;a29a
cuotas_bcd_99:		; ...no mas de 99
	add a,00ah		;a29c   ; lo que sobra
	ex af,af'			;a29e
	ld a,c			;a29f   ; las centenas...
	rlca			;a2a0   ; ...arriba
	rlca			;a2a1
	rlca			;a2a2
	rlca			;a2a3
	ld c,a			;a2a4
	ex af,af'			;a2a5
	or c			;a2a6   ; con lo de abajo
	cp 099h		;a2a7   ; mas de 99?
	jr c,cuotas_bcd_sig		;a2a9
	ld a,099h		;a2ab   ; 99
cuotas_bcd_sig:		; La siguiente
	ld (hl),a			;a2ad   ; la cuota en BCD
	inc hl			;a2ae
	djnz cuotas_bcd		;a2af   ; las seis
	ld bc,00006h		;a2b1   ; las seis cuotas, al marcador (0xE011)
	ld de,0e011h		;a2b4   ; al marcador
	ld hl,0f0b7h		;a2b7
	ldir		;a2ba
	ret			;a2bc
multiplica:		; HL = DE x A (8 bits); lo que pasa de 16 bits, en 0xF0B6
	ld hl,0f0b6h		;a2bd
	ld (hl),000h		;a2c0
	ld hl,00000h		;a2c2
	ld b,008h		;a2c5
multiplica_bit:		; Un bit de A
	rlca			;a2c7
	jr nc,multiplica_sig		;a2c8   ; bit a 0: nada
	add hl,de			;a2ca   ; bit a 1: + DE
	jr nc,multiplica_sig		;a2cb
	push hl			;a2cd   ; se pasa de 16 bits...
	ld hl,0f0b6h		;a2ce
	rl (hl)		;a2d1   ; ...a 0xF0B6
	pop hl			;a2d3
multiplica_sig:		; El siguiente
	dec b			;a2d4
	ret z			;a2d5
	add hl,hl			;a2d6
	jr multiplica_bit		;a2d7
cuotas_pareja:		; Lo de una pareja: 31 - (las fuerzas bajas de los dos) por el factor, a (DE), y la suma en BC
	push bc			;a2d9   ; la suma
	push de			;a2da
	add a,l			;a2db   ; las dos fuerzas...
	xor 01fh		;a2dc   ; ...contra 31
	ld e,a			;a2de   ; E = 31 - las dos
	ld d,000h		;a2df
	call multiplica		;a2e1   ; por el factor
	pop de			;a2e4
	ex de,hl			;a2e5   ; DE = el sitio
	call palabra_pon		;a2e6   ; lo de la pareja
	ex de,hl			;a2e9
	pop bc			;a2ea
	add hl,bc			;a2eb   ; a la suma
	ld b,h			;a2ec   ; en BC
	ld c,l			;a2ed
	ret			;a2ee

; ----------------------------------------------------------------------
; DATOS cuotas_factores: El factor de las cuotas segun lo que separa al mas
;   fuerte del mas flojo
;   0xa2ef..0xa2f5  (6 bytes)
DATA_cuotas_factores:
	defb 02fh,03fh,04fh,05fh,06fh,07fh	; a2ef

; ======================================================================
; CODIGO 0xa2f5..0xa532  (573 bytes)
; ======================================================================


pago:		; El pago, fuera de la interrupcion: a cada jugador, por cada punto apostado a la pareja ganadora, la cuota; uno cada dos cuadros, contando en el marcador
	ld hl,0f0d0h		;a2f5   ; el pago (0xF0D0): bit 0 empieza, bit 7 acabado
	ld a,(hl)			;a2f8
	bit 0,a		;a2f9
	ret z			;a2fb
	bit 7,a		;a2fc
	ret nz			;a2fe
	or 00ch		;a2ff   ; bits 2 y 3: la pareja parpadea y la cuenta va
	ld (hl),a			;a301
	ld bc,00400h		;a302   ; cuatro jugadores
	ld iy,0e02fh		;a305   ; su dinero (0xE02F)
	ld ix,0e017h		;a309   ; sus apuestas (0xE017)
	ld hl,0f0b7h		;a30d   ; las cuotas
	ld a,(0f0c8h)		;a310   ; la pareja ganadora
	ld e,a			;a313
	ld d,c			;a314
	add hl,de			;a315
	add ix,de		;a316
pago_jugador:		; Un jugador: lo que ha apostado a la pareja
	push bc			;a318   ; el contador de jugadores
	ld a,(ix+000h)		;a319   ; lo apostado a la pareja (BCD)
	or a			;a31c
	jr z,pago_sig		;a31d   ; nada
	ld b,a			;a31f   ; B: los puntos
	ld a,(0f0d0h)		;a320   ; alguien cobra (bit 1)
	set 1,a		;a323
	ld (0f0d0h),a		;a325   ; en 0xF0D0
pago_punto:		; Un punto
	push hl			;a328   ; la cuota
pago_espera:		; Espera a que la interrupcion de paso (0xF0E9, cada dos cuadros)
	ld a,(0f0e9h)		;a329
	or a			;a32c
	jr z,pago_espera		;a32d   ; aun no
	ld a,(iy+001h)		;a32f   ; el dinero mas la cuota (BCD)...
	add a,(hl)			;a332   ; + la cuota...
	daa			;a333   ; ...en BCD
	ld (iy+001h),a		;a334   ; el byte bajo del dinero
	ld a,000h		;a337   ; ...con el acarreo
	adc a,(iy+002h)		;a339   ; el acarreo, al alto
	daa			;a33c
	ld (iy+002h),a		;a33d   ; el byte alto
	push bc			;a340   ; los contadores
	push ix		;a341   ; que jugador es...
	push iy		;a343
	pop hl			;a345   ; IY - 0xE02F...
	ld de,0e02fh		;a346
	or a			;a349
	sbc hl,de		;a34a
	rr h		;a34c   ; ...entre 2: el jugador x 2...
	rr l		;a34e
	ex de,hl			;a350   ; ...para la tabla de sitios
	ld ix,0a6dbh		;a351   ; ...su sitio en el marcador
	add ix,de		;a355   ; su sitio
	inc iy		;a357   ; su dinero
	call dinero_pon		;a359   ; el dinero, en la pantalla
	pop ix		;a35c   ; lo de antes
	pop bc			;a35e
	pop hl			;a35f
	xor a			;a360   ; espera otra vez
	ld (0f0e9h),a		;a361   ; el permiso, gastado
	dec iy		;a364   ; IY otra vez al jugador
	ld a,b			;a366   ; un punto menos (BCD)
	sub 001h		;a367   ; un punto menos...
	daa			;a369   ; ...en BCD
	ld b,a			;a36a
	jr nz,pago_punto		;a36b   ; quedan?
pago_sig:		; El jugador siguiente
	pop bc			;a36d
	ld de,00004h		;a36e   ; el dinero del jugador siguiente
	add iy,de		;a371
	ld de,00006h		;a373   ; sus apuestas
	add ix,de		;a376
	djnz pago_jugador		;a378   ; los cuatro
	call premio_jinete		;a37a   ; el premio del jinete
	ld hl,0f0d0h		;a37d   ; el pago, acabado
	set 7,(hl)		;a380   ; bit 7: acabado
	ret			;a382
apuesta_mandos:		; La apuesta: el cursor (dos sprites) por las 24 casillas de las apuestas; el boton 1 cambia entre mover y apostar; el boton 2 acaba
	ld hl,0f0b4h		;a383   ; la espera entre movimientos...
	ld a,(hl)			;a386   ; la espera
	or a			;a387
	jr z,apuesta_mandos_va		;a388   ; no hay
	dec (hl)			;a38a   ; ...un cuadro menos
apuesta_mandos_va:		; Se apuesta (bit 7 de 0xF0C9)?
	ld hl,0f0c9h		;a38b
	ld a,(hl)			;a38e   ; se apuesta?
	rlca			;a38f
	ret nc			;a390
	ld a,(0e00bh)		;a391   ; el boton 2?
	or a			;a394   ; el boton 2?
	jr z,apuesta_jinete		;a395
apuesta_acaba:		; Se acaba: el cursor fuera
	ld a,0c2h		;a397   ; los dos sprites del cursor...
	ld (0e180h),a		;a399
	ld (0e184h),a		;a39c   ; ...fuera
	res 7,(hl)		;a39f   ; se acabo la apuesta
	ret			;a3a1
apuesta_jinete:		; El jinete (bit 4) no apuesta
	bit 4,(hl)		;a3a2
	jr nz,apuesta_acaba		;a3a4
	ld a,(0e00ah)		;a3a6   ; el boton 1...
	or a			;a3a9   ; el boton 1?
	jr z,apuesta_modo		;a3aa
	ld a,(hl)			;a3ac   ; ...cambia entre mover y apostar (bit 3)
	xor 008h		;a3ad   ; cambia de modo
	ld (hl),a			;a3af
apuesta_modo:		; Apostar o mover
	ld de,0f0b1h		;a3b0   ; la espera de la repeticion
	bit 3,(hl)		;a3b3   ; mover?
	jp z,apuesta_mueve		;a3b5
	push hl			;a3b8
	ld hl,0f0cbh		;a3b9   ; el cursor parpadea cada 12 cuadros
	dec (hl)			;a3bc   ; un cuadro menos
	jr nz,L_A3D0		;a3bd
	ld (hl),00ch		;a3bf   ; otra vez 12
	ld a,(0e183h)		;a3c1   ; el color del cursor...
	or a			;a3c4
	ld a,008h		;a3c5   ; ...rojo o transparente
	jr z,L_A3CA		;a3c7
	xor a			;a3c9
L_A3CA:
	ld (0e183h),a		;a3ca   ; en los dos sprites
	ld (0e187h),a		;a3cd
L_A3D0:
	pop hl			;a3d0
	ld a,(0e003h)		;a3d1   ; la palanca, la misma que antes...
	ld c,a			;a3d4   ; C = la palanca
	ld a,(0e006h)		;a3d5   ; la de antes
	cp c			;a3d8   ; ha cambiado?
	jr nz,apuesta_suelta		;a3d9
	and 060h		;a3db   ; ...arriba o abajo?
	jr nz,apuesta_repite		;a3dd
apuesta_suelta:		; Suelta: sin repeticion
	res 2,(hl)		;a3df   ; sin repeticion
	xor a			;a3e1
	ld (de),a			;a3e2   ; sin espera
	ret			;a3e3
apuesta_repite:		; Pulsada: la primera vez...
	bit 2,(hl)		;a3e4   ; ya se repite?
	jr nz,apuesta_espera		;a3e6
	set 2,(hl)		;a3e8   ; ...56 cuadros hasta la repeticion
	ld a,038h		;a3ea   ; 56 cuadros
	ld (de),a			;a3ec
	jr apuesta_punto		;a3ed
apuesta_espera:		; La espera...
	ld a,(de)			;a3ef   ; la espera...
	or a			;a3f0
	jr z,apuesta_rapido		;a3f1   ; ...se acaba?
	dec a			;a3f3   ; un cuadro menos
	ld (de),a			;a3f4
	ret			;a3f5
apuesta_rapido:		; ...luego, una cada 8 cuadros
	ld a,008h		;a3f6   ; 8 cuadros
	ld (de),a			;a3f8
	xor a			;a3f9   ; el color del cursor a 0 (transparente)
	ld (0e183h),a		;a3fa
	ld (0e187h),a		;a3fd
apuesta_punto:		; Un punto: el jugador de la fila del cursor; abajo quita uno de la apuesta y lo devuelve; arriba apuesta uno (no mas de tres parejas ni de 99)
	ld a,(0e180h)		;a400   ; la fila del cursor...
	sub 00fh		;a403   ; menos 0x0F...
	srl a		;a405   ; ...el jugador
	ld hl,0e02fh		;a407   ; los dineros
	call suma_a		;a40a
	inc hl			;a40d   ; su dinero
	ld a,(0e006h)		;a40e   ; abajo?
	bit 6,a		;a411   ; bit 6: abajo
	jr nz,apuesta_baja		;a413
	push hl			;a415   ; el dinero
	ld a,(0e180h)		;a416   ; sus seis apuestas
	sub 00fh		;a419   ; menos 0x0F...
	or a			;a41b
	rra			;a41c   ; ...entre 2...
	ld c,a			;a41d
	or a			;a41e
	rra			;a41f   ; ...y entre 4, sumados: el jugador x 6
	add a,c			;a420
	ld hl,0e017h		;a421   ; las apuestas
	call suma_a		;a424   ; las de este jugador
	ld c,000h		;a427   ; cuantas tiene...
	ld b,006h		;a429   ; seis
apuesta_cuenta:		; Una
	ld a,(hl)			;a42b   ; una...
	or a			;a42c   ; ...es 0?
	jr z,apuesta_cuenta_sig		;a42d
	inc c			;a42f   ; una mas
apuesta_cuenta_sig:		; La siguiente
	inc hl			;a430
	djnz apuesta_cuenta		;a431
	ld a,c			;a433   ; ...tres ya?
	cp 003h		;a434   ; tres?
	jr nz,apuesta_menos3		;a436
	ld a,(0f0b2h)		;a438   ; solo puede subir una de las tres
	ld hl,0e017h		;a43b
	call suma_a		;a43e   ; la del cursor
	ld a,(hl)			;a441   ; tiene?
	or a			;a442
	pop hl			;a443
	jr nz,apuesta_sube		;a444   ; si: sube
	ret			;a446
apuesta_menos3:		; Menos de tres
	pop hl			;a447
	ret nc			;a448   ; menos de tres
apuesta_sube:		; Le queda dinero?
	ld a,(hl)			;a449   ; el dinero, tres bytes
	inc hl			;a44a
	ld c,(hl)			;a44b
	inc hl			;a44c
	or (hl)			;a44d
	dec hl			;a44e
	dec hl			;a44f
	jr nz,apuesta_sube_va		;a450   ; no es 0
	or c			;a452   ; es 0: no apuesta
	ret z			;a453
apuesta_sube_va:		; 99 ya?
	push hl			;a454
	call apuesta_lee		;a455   ; la apuesta de la casilla
	pop hl			;a458
	cp 099h		;a459   ; 99?
	ret z			;a45b
	ld a,(hl)			;a45c   ; el dinero, uno menos (BCD, tres bytes)
	sub 001h		;a45d   ; un punto menos...
	daa			;a45f
	ld (hl),a			;a460
	inc hl			;a461
	ld a,(hl)			;a462
	sbc a,000h		;a463   ; ...con el acarreo...
	daa			;a465
	ld (hl),a			;a466
	inc hl			;a467
	ld a,(hl)			;a468
	sbc a,000h		;a469   ; ...en los tres bytes
	daa			;a46b
	ld (hl),a			;a46c
	call apuesta_lee		;a46d   ; la apuesta, uno mas
	add a,001h		;a470   ; la apuesta + 1
	jr apuesta_pon		;a472
apuesta_baja:		; Abajo: si hay apuesta, el dinero uno mas y la apuesta uno menos
	push hl			;a474
	call apuesta_lee		;a475   ; la apuesta de la casilla
	pop hl			;a478
	or a			;a479   ; no hay
	ret z			;a47a
	ld a,(hl)			;a47b   ; el dinero, uno mas
	add a,001h		;a47c   ; un punto mas...
	daa			;a47e
	ld (hl),a			;a47f
	inc hl			;a480
	ld a,(hl)			;a481
	adc a,000h		;a482   ; ...con el acarreo...
	daa			;a484
	ld (hl),a			;a485
	inc hl			;a486
	ld a,(hl)			;a487
	adc a,000h		;a488   ; ...en los tres bytes
	daa			;a48a
	ld (hl),a			;a48b
	call apuesta_lee		;a48c   ; la apuesta, uno menos
	sub 001h		;a48f   ; la apuesta - 1
apuesta_pon:		; La apuesta, el dinero y las apuestas en la pantalla
	daa			;a491
	ld (hl),a			;a492   ; la apuesta
	call dinero_pinta		;a493   ; el dinero en la pantalla
	call apuestas_pinta		;a496   ; y las apuestas
	ret			;a499
apuesta_mueve:		; Mover: el cursor en rojo; la palanca lo mueve una casilla cada 24 cuadros
	ld a,008h		;a49a   ; rojo
	ld (0e183h),a		;a49c   ; del primero...
	ld (0e187h),a		;a49f   ; ...y del segundo sprite
	ld a,(0e003h)		;a4a2   ; la misma palanca que antes?
	ld c,a			;a4a5   ; la palanca
	ld a,(0e006h)		;a4a6   ; la de antes
	cp c			;a4a9   ; ha cambiado: espera
	ret nz			;a4aa
	and 0f0h		;a4ab   ; alguna direccion?
	ret z			;a4ad
	ld b,a			;a4ae   ; B = las direcciones
	ld a,(0f0b4h)		;a4af   ; espera?
	or a			;a4b2
	ret nz			;a4b3   ; aun espera
	ld a,(0f0b2h)		;a4b4   ; la casilla
	rlc b		;a4b7   ; derecha?
	jr c,apuesta_derecha		;a4b9   ; bit 7: derecha
	rlc b		;a4bb   ; abajo?
	jr c,apuesta_abajo		;a4bd   ; bit 6: abajo
	rlc b		;a4bf   ; arriba?
	jr c,apuesta_arriba		;a4c1   ; bit 5: arriba
	or a			;a4c3   ; izquierda: no en la primera columna
	jr z,apuesta_casilla		;a4c4   ; la columna 0 de una fila?
	cp 006h		;a4c6
	jr z,apuesta_casilla		;a4c8
	cp 00ch		;a4ca
	jr z,apuesta_casilla		;a4cc
	cp 012h		;a4ce
	jr z,apuesta_casilla		;a4d0
	dec a			;a4d2   ; una a la izquierda
apuesta_casilla:		; La casilla nueva y sus dos sprites (0xA541: X e Y)
	ld (0f0b2h),a		;a4d3   ; la casilla
	add a,a			;a4d6   ; x 2
	ld hl,0a541h		;a4d7   ; la X y la Y...
	call suma_a		;a4da
	ld a,(hl)			;a4dd   ; la X del primer sprite...
	ld (0e181h),a		;a4de   ; la X...
	add a,018h		;a4e1   ; ...y 24 mas
	ld (0e185h),a		;a4e3   ; ...y la del segundo
	inc hl			;a4e6
	ld a,(hl)			;a4e7   ; la Y
	ld (0e180h),a		;a4e8   ; la Y de los dos
	ld (0e184h),a		;a4eb
	ld (0f0b3h),a		;a4ee   ; (en 0xF0B3)
	ld a,018h		;a4f1   ; 24 cuadros de espera
	ld (0f0b4h),a		;a4f3   ; la espera
	ret			;a4f6
apuesta_derecha:		; Derecha: no en la ultima columna
	cp 005h		;a4f7   ; la columna 5 de una fila?
	jr z,apuesta_casilla		;a4f9
	cp 00bh		;a4fb
	jr z,apuesta_casilla		;a4fd
	cp 011h		;a4ff
	jr z,apuesta_casilla		;a501
	cp 017h		;a503
	jr z,apuesta_casilla		;a505
	inc a			;a507   ; una a la derecha
	jr apuesta_casilla		;a508
apuesta_arriba:		; Arriba: no en la primera fila
	cp 006h		;a50a   ; la primera fila?
	jr c,apuesta_casilla		;a50c
	sub 006h		;a50e   ; una fila arriba
	jr apuesta_casilla		;a510
apuesta_abajo:		; Abajo: no mas alla de las filas de los que juegan (0xA532)
	ld a,(0e002h)		;a512   ; el jinete?
	ld hl,0a532h		;a515
	or a			;a518   ; el jinete: la tabla del jugador
	jr nz,apuesta_abajo_va		;a519
	ld a,(0f0c9h)		;a51b   ; cuantos juegan
	and 060h		;a51e   ; cuantos juegan (bits 5-6)...
	rlca			;a520   ; ...a 0-3
	rlca			;a521
	rlca			;a522
	call suma_a		;a523
apuesta_abajo_va:		; La fila de abajo
	ld a,(0f0b2h)		;a526   ; una fila abajo...
	add a,006h		;a529
	cp (hl)			;a52b   ; ...cabe?
	jr c,apuesta_casilla		;a52c
	sub 006h		;a52e   ; no: se queda
	jr apuesta_casilla		;a530

; ----------------------------------------------------------------------
; DATOS apuesta_filas: El final de las casillas de 1, 2, 3 y 4 jugadores
;   0xa532..0xa536  (4 bytes)
DATA_apuesta_filas:
	defb 006h,00ch,012h,018h	; a532

; ======================================================================
; CODIGO 0xa536..0xa541  (11 bytes)
; ======================================================================


apuesta_lee:		; La apuesta de la casilla del cursor
	ld a,(0f0b2h)		;a536
	ld hl,0e017h		;a539
	call suma_a		;a53c
	ld a,(hl)			;a53f
	ret			;a540

; ----------------------------------------------------------------------
; DATOS apuesta_cursor: Las 24 casillas de las apuestas: X e Y del cursor
;   (seis columnas, cuatro filas)
;   0xa541..0xa571  (48 bytes)
DATA_apuesta_cursor:
	defb 020h,00fh	; a541
	defb 038h,00fh	; a543
	defb 050h,00fh	; a545
	defb 068h,00fh	; a547
	defb 080h,00fh	; a549
	defb 098h,00fh	; a54b
	defb 020h,017h	; a54d
	defb 038h,017h	; a54f
	defb 050h,017h	; a551
	defb 068h,017h	; a553
	defb 080h,017h	; a555
	defb 098h,017h	; a557
	defb 020h,01fh	; a559
	defb 038h,01fh	; a55b
	defb 050h,01fh	; a55d
	defb 068h,01fh	; a55f
	defb 080h,01fh	; a561
	defb 098h,01fh	; a563
	defb 020h,027h	; a565
	defb 038h,027h	; a567
	defb 050h,027h	; a569
	defb 068h,027h	; a56b
	defb 080h,027h	; a56d
	defb 098h,027h	; a56f

; ======================================================================
; CODIGO 0xa571..0xa5f9  (136 bytes)
; ======================================================================


carrera_ordenador:		; Cada cuatro pasos de pista, el ordenador cambia al azar los bits 6-7 y el latigo (uno de cada cuatro) de sus caballos; despues, el caballo del jugador y la barra MIN-MAX
	ld a,(0f0eah)		;a571   ; el paso de la pista...
	ld c,a			;a574
	ld a,(0e071h)		;a575
	cp c			;a578   ; ...es otro...
	jr z,jugador_y_barra		;a579
	and 003h		;a57b   ; ...y multiplo de 4?
	jr nz,jugador_y_barra		;a57d
	ld hl,0e041h		;a57f
	ld b,004h		;a582   ; cuatro caballos
	ld a,(0e002h)		;a584   ; el del jugador no
	and 007h		;a587
ordenador_uno:		; Uno: los bits 6-7 al azar
	dec a			;a589   ; es el del jugador?
	jr z,ordenador_sig		;a58a
	push af			;a58c
	call azar		;a58d   ; al azar...
	and 0c0h		;a590   ; ...los bits 6-7
	ld c,a			;a592
	ld a,(hl)			;a593   ; el byte del paso...
	and 03fh		;a594   ; ...sin los bits 6-7...
	or c			;a596   ; ...con los nuevos
	ld (hl),a			;a597
	call azar		;a598   ; el latigo: uno de cada cuatro
	and 003h		;a59b   ; uno de cada cuatro...
	ld a,020h		;a59d   ; ...el latigo
	jr z,ordenador_latigo		;a59f
	xor a			;a5a1   ; sin latigo
ordenador_latigo:		; ...
	ld c,a			;a5a2
	ld a,(hl)			;a5a3   ; el byte del paso...
	and 0dfh		;a5a4   ; ...sin el bit 5...
	or c			;a5a6   ; ...con el latigo o no
	ld (hl),a			;a5a7
	pop af			;a5a8
ordenador_sig:		; El siguiente
	ld de,00004h		;a5a9   ; el caballo siguiente
	add hl,de			;a5ac
	djnz ordenador_uno		;a5ad
jugador_y_barra:		; El caballo del jugador, la barra
	call jinete_jugador		;a5af   ; el caballo del jugador
	call barra_cuenta		;a5b2   ; lo que le queda
	ld a,(0e002h)		;a5b5   ; el jinete?
	or a			;a5b8   ; jinete?
	ret z			;a5b9
	ld a,(0f0d0h)		;a5ba   ; en el pago no
	or a			;a5bd   ; el pago?
	ret nz			;a5be
	ld a,(0f0e6h)		;a5bf   ; lo que le queda de fuerza (0-63)
	or a			;a5c2   ; algo?
	jr nz,barra		;a5c3
	ld bc,00010h		;a5c5   ; nada: la barra vacia (0xA639)
	ld de,0e1d8h		;a5c8   ; los cuatro sprites de la barra
	ld hl,0a639h		;a5cb   ; vacia
	ldir		;a5ce
	ret			;a5d0
barra:		; La barra MIN-MAX: los cuatro sprites (0xA5F9) segun los bits 4-5 y la X del ultimo segun los bits 0-3
	and 030h		;a5d1   ; los bits 4-5: el grupo
	ld hl,0a5f9h		;a5d3   ; de 16 bytes
	call suma_a		;a5d6
	ld de,0e1d8h		;a5d9   ; a los cuatro sprites
	ld bc,00010h		;a5dc
	ldir		;a5df
	ld a,(0f0e6h)		;a5e1   ; los bits 0-3...
	and 00fh		;a5e4   ; los bits 0-3
	ld c,000h		;a5e6   ; sin dibujo nuevo
	cp 008h		;a5e8   ; menos de 8: el sprite del final cambia de dibujo
	jr nc,barra_x		;a5ea
	ld c,0a8h		;a5ec   ; el dibujo 0xA8
barra_x:		; La X del final
	ld hl,0e1ddh		;a5ee   ; la X del sprite del final...
	add a,(hl)			;a5f1   ; ...mas los bits 0-3
	ld (hl),a			;a5f2
	ld a,c			;a5f3   ; dibujo nuevo?
	or a			;a5f4
	ret z			;a5f5
	inc hl			;a5f6   ; el dibujo
	ld (hl),a			;a5f7
	ret			;a5f8

; ----------------------------------------------------------------------
; DATOS barra_sprites: La barra MIN-MAX: cuatro grupos de cuatro sprites por
;   lo que queda de fuerza, la barra vacia y los cuatro sprites fuera
;   0xa5f9..0xa659  (96 bytes)
DATA_barra_sprites:
	defb 0b7h,070h,0a8h,00eh	; a5f9
	defb 0b7h,060h,0a8h,00eh	; a5fd
	defb 0b7h,080h,0a8h,00eh	; a601
	defb 0b7h,090h,0a8h,00eh	; a605
	defb 0c2h,000h,0a8h,000h	; a609
	defb 0b7h,070h,0a8h,00eh	; a60d
	defb 0b7h,080h,0a8h,00eh	; a611
	defb 0b7h,090h,0a8h,00eh	; a615
	defb 0c2h,000h,0a8h,000h	; a619
	defb 0b7h,080h,0a8h,00eh	; a61d
	defb 0b7h,090h,0a8h,00eh	; a621
	defb 0c2h,000h,0a8h,000h	; a625
	defb 0b7h,0a0h,0e4h,005h	; a629
	defb 0b7h,090h,0ach,00eh	; a62d
	defb 0c2h,000h,0a8h,00eh	; a631
	defb 0c2h,000h,0a8h,00eh	; a635
	defb 0b7h,060h,0a8h,00eh	; a639
	defb 0b7h,070h,0a8h,00eh	; a63d
	defb 0b7h,080h,0a8h,00eh	; a641
	defb 0b7h,090h,0a8h,00eh	; a645
	defb 0c2h,000h,0a8h,00eh	; a649
	defb 0c2h,000h,0a8h,00eh	; a64d
	defb 0c2h,000h,0a8h,00eh	; a651
	defb 0c2h,000h,0a8h,00eh	; a655

; ======================================================================
; CODIGO 0xa659..0xa6d4  (123 bytes)
; ======================================================================


dinero_pinta:		; El dinero de los cuatro jugadores en el marcador de abajo (1UP-4UP)
	ld ix,0a6dbh		;a659   ; sus sitios en la pantalla
	ld iy,0e030h		;a65d   ; el dinero
	ld b,004h		;a661
dinero_uno:		; Uno
	push bc			;a663
	call dinero_pon		;a664   ; el dinero de uno
	ld de,00004h		;a667   ; el siguiente jugador
	add iy,de		;a66a
	ld e,002h		;a66c   ; su sitio en la pantalla
	add ix,de		;a66e
	pop bc			;a670
	djnz dinero_uno		;a671
	ret			;a673
dinero_pon:		; El dinero de (IY): dos bytes BCD, cuatro cifras; los ceros de la izquierda en blanco; y un 0 detras
	ld b,002h		;a674
	ld c,(iy+001h)		;a676   ; el byte alto
	ld a,(0a6d6h)		;a679   ; aun no ha salido una cifra
	ld hl,0f0cah		;a67c
	ld (hl),a			;a67f
	ld e,(ix+000h)		;a680
	ld d,(ix+001h)		;a683
dinero_byte:		; Un byte: las dos cifras
	call dinero_alta		;a686
	call dinero_baja		;a689
	ld c,(iy+000h)		;a68c   ; el byte bajo
	djnz dinero_byte		;a68f
	bit 0,(hl)		;a691   ; todo ceros: el ultimo en blanco...
	ld a,060h		;a693
	jr z,dinero_cero		;a695
	ld a,0dfh		;a697
dinero_cero:		; ...y el 0 de detras
	ex de,hl			;a699
	call vram_pon		;a69a
	inc hl			;a69d
	ld a,060h		;a69e
	jp vram_pon		;a6a0
dinero_alta:		; La cifra alta: un 0 a la izquierda, en blanco (0xDF)
	ld a,(0a6d4h)		;a6a3
	and c			;a6a6   ; la cifra alta
	jr nz,dinero_cifra		;a6a7
	bit 0,(hl)		;a6a9   ; aun sin cifras?
	jr z,dinero_cifra		;a6ab
	ld a,0dfh		;a6ad   ; en blanco
	jr dinero_cifra_pon		;a6af
dinero_cifra:		; La cifra: casilla 0x60 + n
	rrca			;a6b1   ; la cifra de arriba
	rrca			;a6b2
	rrca			;a6b3
	rrca			;a6b4
	res 0,(hl)		;a6b5   ; ya hay cifras
	add a,060h		;a6b7
dinero_cifra_pon:		; A la pantalla
	ex de,hl			;a6b9
	call vram_pon		;a6ba
	ex de,hl			;a6bd
	inc de			;a6be
	ret			;a6bf
dinero_baja:		; La cifra baja
	ld a,(0a6d5h)		;a6c0
	and c			;a6c3   ; la cifra baja
	jr nz,dinero_baja_pon		;a6c4
	bit 0,(hl)		;a6c6   ; aun sin cifras?
	jr z,dinero_baja_pon		;a6c8
	ld a,0dfh		;a6ca   ; en blanco
	jr dinero_cifra_pon		;a6cc
dinero_baja_pon:		; ...
	res 0,(hl)		;a6ce
	add a,060h		;a6d0
	jr dinero_cifra_pon		;a6d2

; ----------------------------------------------------------------------
; DATOS dinero_tabla: Las mascaras de las dos cifras y el aviso de ceros;
;   cuatro bytes que nadie lee por su direccion; y los sitios del dinero de
;   1UP, 2UP, 3UP y 4UP en la pantalla
;   0xa6d4..0xa6e3  (15 bytes)
DATA_dinero_tabla:
	defb 0f0h,00fh,001h	; a6d4
	defb 000h,002h,000h,006h	; a6d7
	defw 01ac5h,01ae5h,01ad9h,01af9h	; a6db

; ======================================================================
; CODIGO 0xa6e3..0xa7bc  (217 bytes)
; ======================================================================


plano:		; El plano del ovalo, arriba a la derecha: un punto (sprite) por caballo segun donde va en la pista
	ld a,(0f0d0h)		;a6e3   ; no en el pago
	and 08fh		;a6e6
	ret nz			;a6e8
	ld ix,0e050h		;a6e9   ; la vuelta de cada caballo
	ld hl,0e199h		;a6ed   ; su X en la pantalla
	ld b,004h		;a6f0
	ld a,(0e071h)		;a6f2   ; el paso de la pista, de 0 a 0x5F
	add a,008h		;a6f5
	cp 060h		;a6f7
	jr c,plano_vuelta		;a6f9
	sub 060h		;a6fb
plano_vuelta:		; 0x60 - el paso
	ld c,a			;a6fd
	ld a,060h		;a6fe
	sub c			;a700
	ld c,a			;a701
plano_uno:		; Un caballo: la X entre 32, contra el paso
	ld a,(hl)			;a702   ; la X del primer sprite...
	and 0e0h		;a703   ; ...entre 32
	rlca			;a705
	rlca			;a706
	rlca			;a707
	ld e,a			;a708
	ld a,007h		;a709   ; 7 menos eso...
	sub e			;a70b
	add a,c			;a70c   ; ...mas la vuelta de la pista
	cp 0c0h		;a70d   ; de 0 a 0xBF
	jr c,plano_mod		;a70f
	sub 040h		;a711
plano_mod:		; De 0 a 0x5F
	cp 060h		;a713   ; de 0 a 0x5F
	jr c,plano_pon		;a715
	sub 060h		;a717
plano_pon:		; Con el bit 7
	set 7,a		;a719   ; con el bit 7: en la carrera
	ld (ix+000h),a		;a71b   ; a 0xE050
	inc ix		;a71e
	ld de,0000ch		;a720   ; el caballo siguiente (12 bytes de sprites)
	add hl,de			;a723
	djnz plano_uno		;a724   ; los cuatro
	ld hl,0e050h		;a726   ; los cuatro puntos
	ld ix,0e1c8h		;a729   ; los sprites 0x12-0x15
	xor a			;a72d
	ld (0f0cdh),a		;a72e   ; el contador de caballos
plano_punto:		; Un punto: en la recta de abajo, la curva, la recta de arriba o la otra curva
	ld a,(hl)			;a731
	push hl			;a732
	bit 7,a		;a733
	jp z,plano_fuera		;a735
	and 07fh		;a738
	cp 010h		;a73a   ; la recta de abajo
	jr c,plano_recta		;a73c
	cp 020h		;a73e   ; la primera curva
	jr c,plano_curva1		;a740
	cp 040h		;a742   ; la recta de arriba
	jr c,plano_arriba		;a744
	cp 050h		;a746   ; la segunda curva
	jr c,plano_curva2		;a748
plano_recta:		; Una recta: la X de 0xD7 hacia atras y la Y de la tabla 0xA7BC
	ld c,000h		;a74a
	cp 050h		;a74c
	jr c,plano_recta_x		;a74e
	ld c,060h		;a750
plano_recta_x:		; ...
	sub c			;a752   ; la vuelta
	ld c,a			;a753
	ld a,0d7h		;a754   ; la X: 0xD7 menos eso
	sub c			;a756
	ld (ix+001h),a		;a757
	ld hl,0a7bch		;a75a   ; la Y de la recta de abajo
plano_y:		; La Y del caballo
	ld a,(0f0cdh)		;a75d
	call suma_a		;a760
	ld a,(hl)			;a763
	ld (ix+000h),a		;a764
plano_dibujo:		; El dibujo 8, negro
	ld (ix+002h),008h		;a767
	ld (ix+003h),001h		;a76b
plano_sig:		; El siguiente
	ld hl,0f0cdh		;a76f
	inc (hl)			;a772   ; uno mas
	ld a,(hl)			;a773
	pop hl			;a774
	inc hl			;a775
	ld de,00004h		;a776
	add ix,de		;a779   ; el sprite siguiente
	cp 004h		;a77b   ; los cuatro
	jr c,plano_punto		;a77d
	ret			;a77f
plano_arriba:		; La recta de arriba: la X desde 0xC8 y la Y de la tabla 0xA7C0
	sub 020h		;a780
	add a,0c8h		;a782
	ld (ix+001h),a		;a784
	ld hl,0a7c0h		;a787
	jr plano_y		;a78a
plano_curva1:		; La primera curva: X e Y de la tabla 0xA7C4
	sub 010h		;a78c
plano_curva:		; ...
	call plano_tabla		;a78e
	ld (ix+000h),d		;a791
	ld (ix+001h),e		;a794
	jr plano_dibujo		;a797
plano_curva2:		; La segunda curva
	sub 030h		;a799
	jr plano_curva		;a79b
plano_fuera:		; Sin carrera: fuera
	ld (ix+000h),0c0h		;a79d
	ld (ix+003h),000h		;a7a1
	jr plano_sig		;a7a5
plano_tabla:		; X e Y de la curva: la tabla del caballo y el punto
	push af			;a7a7
	ld a,(0f0cdh)		;a7a8   ; el caballo...
	add a,a			;a7ab   ; ...x 2: su tabla
	ld de,0a7c4h		;a7ac
	call tabla_w2		;a7af
	pop af			;a7b2
	add a,a			;a7b3   ; el punto x 2
tabla_w2:		; DE = la palabra A de la tabla DE
	ld l,a			;a7b4
	ld h,000h		;a7b5
	add hl,de			;a7b7   ; la tabla + A
	ld e,(hl)			;a7b8   ; la palabra
	inc hl			;a7b9
	ld d,(hl)			;a7ba
	ret			;a7bb

; ----------------------------------------------------------------------
; DATOS plano_tablas: El plano: la Y de cada caballo en la recta de abajo y en
;   la de arriba, y las tablas de las curvas (Y, X) de cada caballo
;   0xa7bc..0xa8cc  (272 bytes)
DATA_plano_tablas:
	defb 01fh,021h,023h,025h	; a7bc
	defb 00eh,00ch,00ah,008h	; a7c0
	defw 0a7cch,0a80ch,0a84ch,0a88ch	; a7c4
	defb 0c7h,01eh,0c6h,01dh,0c5h,01ch,0c5h,01bh,0c4h,01ah,0c4h,019h,0c3h,018h,0c3h,017h	; a7cc  ................
	defb 0c3h,016h,0c3h,015h,0c4h,014h,0c4h,013h,0c5h,012h,0c5h,011h,0c6h,010h,0c7h,00fh	; a7dc  ................
	defb 0e8h,00fh,0e9h,010h,0eah,011h,0eah,012h,0ebh,013h,0ebh,014h,0ech,015h,0ech,016h	; a7ec  ................
	defb 0ech,017h,0ech,018h,0ebh,019h,0ebh,01ah,0eah,01bh,0eah,01ch,0e9h,01dh,0e8h,01eh	; a7fc  ................
	defb 0c7h,020h,0c6h,01fh,0c5h,01eh,0c4h,01dh,0c3h,01bh,0c2h,019h,0c1h,018h,0c1h,017h	; a80c  . ..............
	defb 0c1h,016h,0c1h,015h,0c2h,014h,0c3h,012h,0c4h,010h,0c5h,00fh,0c6h,00eh,0c7h,00dh	; a81c  ................
	defb 0e8h,00dh,0e9h,00eh,0eah,00fh,0ebh,010h,0ech,012h,0edh,014h,0eeh,015h,0eeh,016h	; a82c  ................
	defb 0eeh,017h,0eeh,018h,0edh,019h,0ech,01bh,0ebh,01dh,0eah,01eh,0e9h,01fh,0e8h,020h	; a83c  ............... 
	defb 0c7h,022h,0c5h,021h,0c4h,020h,0c2h,01eh,0c1h,01ch,0c0h,01ah,0bfh,019h,0bfh,017h	; a84c  .".!. ..........
	defb 0bfh,016h,0bfh,014h,0c0h,013h,0c1h,011h,0c2h,00fh,0c4h,00dh,0c5h,00ch,0c7h,00bh	; a85c  ................
	defb 0e8h,00bh,0eah,00ch,0ebh,00dh,0edh,00fh,0eeh,011h,0efh,013h,0f0h,014h,0f0h,016h	; a86c  ................
	defb 0f0h,017h,0f0h,019h,0efh,01ah,0eeh,01ch,0edh,01eh,0ebh,020h,0eah,021h,0e8h,022h	; a87c  ........... .!."
	defb 0c6h,024h,0c4h,023h,0c2h,021h,0c0h,01fh,0bfh,01dh,0beh,01bh,0bdh,019h,0bdh,017h	; a88c  .$.#.!..........
	defb 0bdh,016h,0bdh,014h,0beh,012h,0bfh,010h,0c0h,00eh,0c2h,00ch,0c4h,00ah,0c6h,009h	; a89c  ................
	defb 0e9h,009h,0ebh,00ah,0edh,00ch,0efh,00eh,0f0h,010h,0f1h,012h,0f2h,014h,0f2h,016h	; a8ac  ................
	defb 0f2h,017h,0f2h,019h,0f1h,01bh,0f0h,01dh,0efh,01fh,0edh,021h,0ebh,023h,0e9h,024h	; a8bc  ...........!.#.$

; ======================================================================
; CODIGO 0xa8cc..0xa96c  (160 bytes)
; ======================================================================


carrera_prepara:		; La carrera nueva: las fuerzas al azar, las cuotas, las cuentas, las apuestas a cero, el marcador y el cursor de la apuesta
	ld a,0c2h		;a8cc   ; el sprite del plano, fuera
	ld (0e1c8h),a		;a8ce   ; (0xC2)
	call azar16		;a8d1   ; 16 numeros al azar
	call cuotas		;a8d4   ; las cuotas
	ld hl,(0e000h)		;a8d7   ; la distancia de la carrera
	ld h,000h		;a8da
	dec l			;a8dc   ; ...menos 1...
	ld de,08da3h		;a8dd   ; ...en la tabla de las carreras
	add hl,de			;a8e0
	ld a,(hl)			;a8e1
	and 007h		;a8e2   ; la distancia
	ld c,a			;a8e4
	push bc			;a8e5
	call fuerzas_empieza		;a8e6   ; las fuerzas
	pop bc			;a8e9
	ld hl,0a96ch		;a8ea   ; el ultimo paso visto
	ld b,000h		;a8ed
	add hl,bc			;a8ef   ; ...por la distancia
	ld a,(hl)			;a8f0
	ld (0f0eah),a		;a8f1   ; en 0xF0EA
	ld hl,0f0b0h		;a8f4   ; las cuotas, hechas
	set 7,(hl)		;a8f7   ; bit 7: las cuotas se han hecho
	ld hl,0e017h		;a8f9   ; las 24 apuestas a cero
	ld b,018h		;a8fc   ; 24 bytes
L_A8FE:
	ld (hl),000h		;a8fe
	inc hl			;a900
	djnz L_A8FE		;a901
	call apuestas_pinta		;a903   ; las apuestas, el dinero y las cuotas en la pantalla
	call dinero_pinta		;a906   ; el dinero de los cuatro
	call cuotas_pinta		;a909   ; las cuotas
	ld a,(0e001h)		;a90c   ; el modo (la demostracion como un jugador)
	cp 0ffh		;a90f
	jr nz,carrera_prepara_modo		;a911
	ld a,001h		;a913   ; ...como un jugador
carrera_prepara_modo:		; Los bits de la apuesta por el modo (0xA979): 7 se apuesta, 4 el jinete, 5-6 cuantos juegan
	ld hl,0a979h		;a915   ; la tabla de los modos
	call suma_a		;a918
	ld a,(hl)			;a91b
	ld (0f0c9h),a		;a91c   ; en 0xF0C9
	ld a,00ch		;a91f   ; el parpadeo del cursor
	ld (0f0cbh),a		;a921
	xor a			;a924   ; el pago a cero
	ld hl,0f0d0h		;a925   ; 0xF0D0-0xF0D5: el pago y el latigo
	ld b,006h		;a928
carrera_prepara_borra:		; ...
	ld (hl),a			;a92a
	inc hl			;a92b
	djnz carrera_prepara_borra		;a92c
	ld hl,0f0d6h		;a92e   ; el latigo y sus cuentas a cero
	ld de,0f0d7h		;a931
	ld bc,00010h		;a934
	ld (hl),000h		;a937
	ldir		;a939
	ld hl,0a649h		;a93b   ; la barra MIN-MAX, fuera
	ld de,0e1d8h		;a93e   ; los cuatro sprites de la barra (0xE1D8)
	ld bc,00010h		;a941
	ldir		;a944
	ld a,03fh		;a946   ; la fuerza entera
	ld (0f0e6h),a		;a948
	ld a,(0f0c9h)		;a94b   ; el jinete: sin cursor
	bit 4,a		;a94e   ; el jinete?
	ret nz			;a950
	ld hl,00010h		;a951   ; la apuesta: el cursor en la primera casilla
	ld (0f0b1h),hl		;a954
	ld a,h			;a957   ; sin espera entre movimientos
	ld (0f0b4h),a		;a958
	ld a,001h		;a95b   ; la primera casilla
	ld (0f0b3h),a		;a95d
	ld de,0e180h		;a960   ; los dos sprites del cursor
	ld hl,0a971h		;a963   ; (0xA971)
	ld bc,00008h		;a966
	ldir		;a969
	ret			;a96b

; ----------------------------------------------------------------------
; DATOS carrera_tablas: El ultimo paso visto al empezar (por la distancia),
;   los dos sprites del cursor y los bits de la apuesta por modo
;   0xa96c..0xa97e  (18 bytes)
DATA_carrera_tablas:
	defb 02bh,03bh,05bh,08bh,0bbh	; a96c
	defb 0c2h,020h,000h,008h	; a971
	defb 0c2h,038h,004h,008h	; a975
	defb 090h,080h,0a0h,0c0h,0e0h	; a979

; ======================================================================
; CODIGO 0xa97e..0xa9dd  (95 bytes)
; ======================================================================


azar16:		; Los 16 numeros al azar (0-15) de 0xE03F
	ld hl,0e03fh		;a97e
	ld b,004h		;a981
azar16_uno:		; ...
	ld c,004h		;a983
azar16_pon:		; ...
	call azar		;a985
	and 00fh		;a988   ; de 0 a 15
	ld (hl),a			;a98a
	inc hl			;a98b
	dec c			;a98c   ; los cuatro de cada caballo
	jr nz,azar16_pon		;a98d
	djnz azar16_uno		;a98f   ; los cuatro caballos
	ret			;a991
ganadora_parpadea:		; En el pago, la pareja ganadora parpadea (un sprite sobre su cuota); si no, fuera
	ld a,(0f0d0h)		;a992   ; el pago?
	or a			;a995
	ret z			;a996
	bit 3,a		;a997   ; parpadea?
	jr nz,ganadora_va		;a999   ; la pareja parpadea (bit 3)?
	ld hl,0e1c8h		;a99b   ; no: los cuatro sprites fuera
	ld de,00004h		;a99e   ; de 4 en 4
	ld b,e			;a9a1   ; cuatro
ganadora_fuera:		; Uno
	ld (hl),0c2h		;a9a2   ; Y = 0xC2: fuera
	add hl,de			;a9a4
	djnz ganadora_fuera		;a9a5
	xor a			;a9a7
	ld (0f0b5h),a		;a9a8   ; la cuenta del parpadeo a 0
	ret			;a9ab
ganadora_va:		; Cada 8 cuadros, encendido o apagado
	ld hl,0f0b5h		;a9ac   ; un cuadro mas
	inc (hl)			;a9af
	ld a,(hl)			;a9b0
	and 008h		;a9b1   ; cada 8 cuadros...
	rrca			;a9b3   ; ...apagado (0) o encendido (4)
	ld hl,0a9ddh		;a9b4
	call suma_a		;a9b7
	ld de,0e1c8h		;a9ba   ; en el sprite 0x12
	ld bc,00004h		;a9bd
	ldir		;a9c0
	ld a,(0f0c8h)		;a9c2   ; la X de la pareja
	ld hl,0a9e5h		;a9c5   ; su X
	call suma_a		;a9c8
	ld a,(hl)			;a9cb
	ld (0e1c9h),a		;a9cc   ; en el sprite
	ld hl,0e1cch		;a9cf   ; los otros tres, fuera
	ld de,00004h		;a9d2   ; los tres siguientes
	ld b,003h		;a9d5
ganadora_fuera3:		; Uno
	ld (hl),0c2h		;a9d7   ; fuera
	add hl,de			;a9d9
	djnz ganadora_fuera3		;a9da
	ret			;a9dc

; ----------------------------------------------------------------------
; DATOS ganadora_tabla: El sprite apagado y encendido, y la X de las seis
;   parejas
;   0xa9dd..0xa9eb  (14 bytes)
DATA_ganadora_tabla:
	defb 0c2h,000h,00ch,005h	; a9dd
	defb 0ffh,000h,00ch,005h	; a9e1
	defb 028h,040h,058h,070h,088h,0a0h	; a9e5

; ======================================================================
; CODIGO 0xa9eb..0xaafc  (273 bytes)
; ======================================================================


pago_paso:		; Cada dos cuadros, el permiso para un punto del pago (0xF0E9); al acabar, deja de parpadear
	ld a,(0f0d0h)		;a9eb   ; la cuenta del pago va?
	bit 2,a		;a9ee
	ret z			;a9f0
	ld a,(0e07bh)		;a9f1   ; un cuadro de cada dos
	rrca			;a9f4
	ret c			;a9f5
	ld a,0ffh		;a9f6   ; el permiso para un punto
	ld (0f0e9h),a		;a9f8
	ld a,(0f0d0h)		;a9fb   ; el pago se ha acabado?
	bit 7,a		;a9fe
	ret z			;aa00
	res 2,a		;aa01   ; la cuenta, parada
	ld (0f0d0h),a		;aa03
	ret			;aa06
jinete_jugador:		; El jinete: el latigo (boton 1), su efecto en la velocidad y, sin fuerza, el paso mas lento
	ld a,(0f0c9h)		;aa07   ; el jinete?
	and 010h		;aa0a   ; el jinete?
	ret z			;aa0c
	ld a,(0e002h)		;aa0d   ; con caballo?
	or a			;aa10
	ret z			;aa11
	call latigo_pulsa		;aa12   ; el latigo
	call latigo_cuentas		;aa15   ; sus cuentas
	call velocidad_jugador		;aa18   ; la velocidad
	ld a,(0e002h)		;aa1b   ; le queda fuerza?
	call cuentas_jugador		;aa1e   ; su cuenta
	ld a,e			;aa21   ; es 0?
	inc hl			;aa22
	or d			;aa23
	ret nz			;aa24   ; no: sigue
	call caballo_jugador		;aa25   ; sin fuerza: el paso 7 (0x1C)
	ld a,(hl)			;aa28   ; el byte del paso...
	and 0e3h		;aa29
	or 01ch		;aa2b   ; ...el paso 7, el mas lento
	ld (hl),a			;aa2d
	ret			;aa2e
velocidad_jugador:		; Las dos esperas (0xF0D1 y 0xF0D3) y lo que toca segun los bits 3-4 de 0xF0D5 (0xAB15)
	ld hl,(0f0d1h)		;aa2f   ; la primera espera...
	ld a,l			;aa32
	or h			;aa33
	jr z,velocidad_espera2		;aa34   ; ...ya es 0
	dec hl			;aa36   ; un cuadro menos
velocidad_espera2:		; ...
	ld (0f0d1h),hl		;aa37
	ld hl,(0f0d3h)		;aa3a   ; la segunda espera
	ld a,l			;aa3d
	or h			;aa3e
	jr z,velocidad_espera3		;aa3f
	dec hl			;aa41   ; un cuadro menos
velocidad_espera3:		; ...
	ld (0f0d3h),hl		;aa42
	ld a,(0f0d5h)		;aa45   ; el estado...
	and 018h		;aa48   ; los bits 3-4...
	rrca			;aa4a   ; ...x 2
	rrca			;aa4b
	ld de,0ab15h		;aa4c   ; ...por la tabla
	call tabla_w2		;aa4f   ; la rutina
	ex de,hl			;aa52
	jp (hl)			;aa53   ; a ella
velocidad_baja:		; 0: la velocidad baja un punto (0-4) y espera
	ld hl,0f0d5h		;aa54
	ld a,(hl)			;aa57   ; la velocidad (0-4)
	and 007h		;aa58   ; en 0, se queda
	jr z,velocidad_espera		;aa5a
	dec (hl)			;aa5c   ; una menos
	dec a			;aa5d
velocidad_espera:		; La espera
	ld hl,(0ab22h)		;aa5e   ; 0x0020 cuadros...
	ld (0f0d1h),hl		;aa61   ; ...de espera
velocidad_pon:		; El paso de la velocidad (0xAB1D) en el caballo del jugador
	ld hl,0ab1dh		;aa64   ; los pasos de la velocidad
	call suma_a		;aa67
	ld c,(hl)			;aa6a   ; el paso
	call caballo_jugador		;aa6b   ; el byte del caballo del jugador...
	ld a,(hl)			;aa6e
	and 0e3h		;aa6f   ; ...sin los bits 2-4...
	or c			;aa71   ; ...con el paso
	ld (hl),a			;aa72
	ret			;aa73
velocidad_sigue:		; 2 o 3: si se acaba la espera, al estado 0
	ld hl,(0f0d1h)		;aa74   ; la espera
	ld a,l			;aa77
	or h			;aa78
	jr z,velocidad_igual		;aa79   ; ya es 0
	dec hl			;aa7b   ; un cuadro menos
	ld (0f0d1h),hl		;aa7c
	ld a,l			;aa7f
	or h			;aa80
	jr nz,velocidad_igual		;aa81   ; aun no
	ld hl,0f0d5h		;aa83   ; se acaba: al estado 0...
	ld a,(hl)			;aa86
	and 0e7h		;aa87
	ld (hl),a			;aa89
	jr velocidad_baja		;aa8a   ; ...y la velocidad baja
velocidad_igual:		; Sigue igual
	ld a,(0f0d5h)		;aa8c   ; la velocidad de ahora
	and 007h		;aa8f
	jr velocidad_pon		;aa91
velocidad_sube:		; 1: el latigo sube la velocidad; en la 5, la fuerza baja
	ld hl,0f0d5h		;aa93   ; la velocidad...
	ld a,(hl)			;aa96
	inc a			;aa97   ; ...+ 1...
	and 007h		;aa98
	cp 005h		;aa9a   ; 5?
	call nc,latigo_cansa		;aa9c   ; ...pasa de 4: cansa y se queda
	inc (hl)			;aa9f   ; un punto mas, al estado 2
	ld a,(hl)			;aaa0   ; al estado 2
	and 0e7h		;aaa1
	or 010h		;aaa3
	ld (hl),a			;aaa5
	ld hl,(0ab24h)		;aaa6   ; 0x00C0 cuadros...
	ld (0f0d1h),hl		;aaa9   ; ...de espera
	and 007h		;aaac
	jr velocidad_pon		;aaae
latigo_cansa:		; El latigo de mas: la fuerza y las cuentas del caballo, un poco menos (0xAAFC)
	push hl			;aab0
	ld hl,0e03fh		;aab1   ; la fuerza del caballo del jugador...
	call caballo_jugador_n		;aab4
	push de			;aab7
	call cansa		;aab8   ; ...menos lo de la carrera
	pop de			;aabb
	ld hl,0f080h		;aabc   ; sus cuentas
	add hl,de			;aabf
	add hl,de			;aac0
	ld b,003h		;aac1   ; tres palabras
	call cansa		;aac3   ; la primera
latigo_cansa_uno:		; ...
	call cansa		;aac6   ; la siguiente que no sea 0...
	jr nz,latigo_cansa_fin		;aac9
	djnz latigo_cansa_uno		;aacb   ; ...de las tres
latigo_cansa_fin:		; La velocidad, un punto menos
	pop hl			;aacd
	dec (hl)			;aace   ; la velocidad, una menos
	ret			;aacf
cansa:		; Una palabra menos lo de la carrera (0xAAFC), sin bajar de 0
	push hl			;aad0
	ld e,(hl)			;aad1   ; la palabra
	inc hl			;aad2
	ld d,(hl)			;aad3
	ld a,e			;aad4
	or d			;aad5
	jr nz,cansa_resta		;aad6   ; no es 0
	pop hl			;aad8   ; es 0: HL a la siguiente, con Z
	inc hl			;aad9
	inc hl			;aada
	ret			;aadb
cansa_resta:		; ...
	push de			;aadc
	ld a,(0e000h)		;aadd   ; la carrera...
	dec a			;aae0
	ld hl,0aafch		;aae1   ; ...lo que cuesta
	call suma_a		;aae4
	ld e,(hl)			;aae7
	ld d,000h		;aae8
	pop hl			;aaea
	or a			;aaeb
	sbc hl,de		;aaec   ; la palabra menos eso...
	jr nc,cansa_pon		;aaee
	ld hl,00000h		;aaf0   ; ...sin bajar de 0
cansa_pon:		; ...
	ex de,hl			;aaf3
	pop hl			;aaf4
	call palabra_pon		;aaf5   ; guardada
	ld a,001h		;aaf8   ; NZ: hecho
	or a			;aafa
	ret			;aafb

; ----------------------------------------------------------------------
; DATOS latigo_coste: Lo que cuesta el latigo de mas en cada carrera
;   0xaafc..0xab05  (9 bytes)
DATA_latigo_coste:
	defb 003h,003h,003h,004h,004h,005h,005h,006h,006h	; aafc  .........

; ======================================================================
; CODIGO 0xab05..0xab15  (16 bytes)
; ======================================================================


caballo_jugador:		; HL = el byte del paso del caballo del jugador (0xE041 + 4 x (n - 1))
	ld hl,0e041h		;ab05
caballo_jugador_n:		; ...en la tabla HL
	ld a,(0e002h)		;ab08
	dec a			;ab0b
	and 003h		;ab0c
	add a,a			;ab0e
	add a,a			;ab0f
suma_a:		; HL += A
	ld e,a			;ab10
	ld d,000h		;ab11
	add hl,de			;ab13
	ret			;ab14

; ----------------------------------------------------------------------
; DATOS velocidad_tablas: Los cuatro estados del latigo, los cinco pasos de la
;   velocidad (de 0x60 a 0x84) y las tres esperas
;   0xab15..0xab27  (18 bytes)
DATA_velocidad_tablas:
	defw 0aa54h,0aa93h,0aa74h,0aa74h	; ab15  -> velocidad_baja velocidad_sube velocidad_sigue velocidad_sigue
	defb 01ch,018h,014h,010h,000h	; ab1d
	defw 00020h,000c0h	; ab22
	defb 020h	; ab26

; ======================================================================
; CODIGO 0xab27..0xac01  (218 bytes)
; ======================================================================


latigo_pulsa:		; El boton 1: un latigazo (hasta 16 en cola) y el latigo del jinete
	call caballo_jugador		;ab27   ; sin latigo
	res 5,(hl)		;ab2a   ; sin latigo
	ld a,(0e00ah)		;ab2c   ; el boton 1?
	ld hl,0f0d5h		;ab2f   ; la cola del latigo
	or a			;ab32
	jr nz,latigo_nuevo		;ab33   ; pulsado
	res 7,(hl)		;ab35   ; suelto: se puede volver a pulsar
	ret			;ab37
latigo_nuevo:		; Una vez por pulsacion
	bit 7,(hl)		;ab38   ; ya contado?
	ret nz			;ab3a
	ld a,(hl)			;ab3b
	or 0c0h		;ab3c   ; bits 6 y 7: contado
	ld (hl),a			;ab3e
	ld hl,0f0d6h		;ab3f   ; los latigazos en cola
	ld a,(hl)			;ab42
	cp 010h		;ab43   ; 16?
	jr nc,latigo_lleno		;ab45
	inc (hl)			;ab47   ; uno mas
	inc hl			;ab48
	call suma_a		;ab49   ; su sitio en la cola
	ld a,(0ab26h)		;ab4c   ; la espera (0x20 cuadros)
	ld (hl),a			;ab4f
	call caballo_jugador		;ab50   ; el byte del paso del caballo...
	set 5,(hl)		;ab53   ; ...con el latigo (bit 5)
	ret			;ab55
latigo_lleno:		; 16 ya: nada
	ld hl,0f0d5h		;ab56
	res 7,(hl)		;ab59
	ret			;ab5b
latigo_cuentas:		; Las cuentas de los latigazos: cuando una llega a 0, sale de la cola y la velocidad sube
	ld hl,0f0d6h		;ab5c
	ld a,(hl)			;ab5f   ; cuantos en cola
	or a			;ab60
	ret z			;ab61   ; ninguno
	ld b,a			;ab62
	inc hl			;ab63   ; sus esperas
latigo_cola_uno:		; Una
	dec (hl)			;ab64   ; una menos
	call z,latigo_sale		;ab65   ; se acaba: sale
	inc hl			;ab68
	djnz latigo_cola_uno		;ab69   ; todos
	ret			;ab6b
latigo_sale:		; Sale: al estado 1 y la cola corre
	ld a,(0f0d5h)		;ab6c   ; el estado del latigo...
	and 0e7h		;ab6f
	or 008h		;ab71   ; ...a 1: la velocidad sube
	ld (0f0d5h),a		;ab73
	push hl			;ab76
	push bc			;ab77
	ld e,l			;ab78   ; la cola...
	ld d,h			;ab79
	inc hl			;ab7a   ; ...corre un sitio
	ld a,010h		;ab7b   ; lo que queda de cola
	sub b			;ab7d
	ld c,a			;ab7e
	ld b,000h		;ab7f
	or a			;ab81
	jr z,latigo_cola		;ab82   ; nada
	ldir		;ab84
latigo_cola:		; Uno menos en la cola
	ld hl,0f0d6h		;ab86
	dec (hl)			;ab89   ; uno menos
	pop bc			;ab8a
	pop hl			;ab8b
	dec hl			;ab8c   ; el mismo sitio otra vez
	ret			;ab8d
fuerza_jugador:		; La fuerza del caballo del jugador al salir (0xF0E7), para la barra
	ld a,(0e002h)		;ab8e   ; el caballo del jugador
	call cuentas_jugador		;ab91   ; su cuenta
	ex de,hl			;ab94
	ld (0f0e7h),hl		;ab95   ; a 0xF0E7
	ret			;ab98
barra_cuenta:		; Lo que le queda: la fuerza x 63 entre la de la salida (0-63, 0xF0E6)
	ld a,(0e002h)		;ab99   ; el jinete?
	or a			;ab9c
	ret z			;ab9d
	call cuentas_jugador		;ab9e   ; la cuenta del caballo del jugador
	ld a,e			;aba1   ; es 0?
	or d			;aba2
	jr z,barra_vacia		;aba3
	ld a,03fh		;aba5   ; x 63
	call multiplica		;aba7
	ex de,hl			;abaa
	ld hl,(0f0e7h)		;abab   ; la de la salida
	ld a,e			;abae   ; es 0?
	or d			;abaf
	jr z,barra_vacia		;abb0
	ex de,hl			;abb2
	call divide		;abb3   ; entre la de la salida
	ld a,l			;abb6
	ld (0f0e6h),a		;abb7   ; lo que le queda, de 0 a 63
	ret			;abba
barra_vacia:		; Nada
	xor a			;abbb
	ld (0f0e6h),a		;abbc
	ret			;abbf
cuentas_jugador:		; DE = la cuenta del caballo A (0xF080 + (A - 1) x 8)
	dec a			;abc0   ; el caballo - 1
	and 003h		;abc1
	add a,a			;abc3   ; x 8
	add a,a			;abc4
	add a,a			;abc5
	ld de,0f080h		;abc6   ; en 0xF080
	jp tabla_w2		;abc9
premio_jinete:		; El premio del jinete: si su caballo llega primero o segundo, el de la carrera (0xAC01) a su dinero
	ld hl,(0e000h)		;abcc   ; la carrera...
	ld h,000h		;abcf
	dec l			;abd1
	add hl,hl			;abd2   ; ...x 2...
	ld de,0ac01h		;abd3   ; ...en la tabla de premios
	add hl,de			;abd6
	ld a,(0e144h)		;abd7   ; el puesto
	or a			;abda
	ret z			;abdb
	cp 003h		;abdc   ; primero o segundo
	ret nc			;abde   ; el tercero o el cuarto: nada
	dec a			;abdf   ; el premio del primero o del segundo
	call suma_a		;abe0
	ld e,(hl)			;abe3
	ld a,(0e002h)		;abe4   ; el jinete?
	or a			;abe7
	ret z			;abe8
	ld hl,0e030h		;abe9   ; el dinero del jugador 1 (BCD)
	ld a,(hl)			;abec   ; el dinero...
	add a,e			;abed   ; ...mas el premio...
	daa			;abee   ; ...en BCD
	ld (hl),a			;abef
	inc hl			;abf0   ; el acarreo...
	ld a,(hl)			;abf1
	adc a,000h		;abf2   ; ...al byte alto
	daa			;abf4
	ld (hl),a			;abf5
	ld ix,0a6dbh		;abf6   ; a la pantalla
	ld iy,0e030h		;abfa   ; ...y su dinero
	jp dinero_pon		;abfe

; ----------------------------------------------------------------------
; DATOS premios_jinete: Los premios de las nueve carreras, en BCD (centenas):
;   1ST y 2ND
;   0xac01..0xac13  (18 bytes)
DATA_premios_jinete:
	defb 010h,005h	; ac01
	defb 020h,010h	; ac03
	defb 030h,015h	; ac05
	defb 040h,020h	; ac07
	defb 050h,025h	; ac09
	defb 060h,030h	; ac0b
	defb 070h,035h	; ac0d
	defb 080h,040h	; ac0f
	defb 090h,045h	; ac11

; ======================================================================
; CODIGO 0xac13..0xac1b  (8 bytes)
; ======================================================================


siguiente8:		; HL + 8 e IX + 4
	ld de,00004h		;ac13
	add hl,de			;ac16
	add hl,de			;ac17
	add ix,de		;ac18
	ret			;ac1a

; ----------------------------------------------------------------------
; DATOS sprites_cursores: Los dibujos de sprite 0-3 (16 x 16): el cursor de la
;   apuesta (0 y 1), el punto del plano (2) y el cursor de la seleccion (3)
;   0xac1b..0xac9b  (128 bytes)
DATA_sprites_cursores:
	defb 000h,078h,07ch,07fh,07fh,07ch,078h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac1b  .x|..|x.........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac2b  ................
	defb 000h,01eh,03eh,0feh,0feh,03eh,01eh,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac3b  ..>..>..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac4b  ................
	defb 080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac5b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac6b  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ac7b  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ac8b  ................

; ----------------------------------------------------------------------
; DATOS pantalla_arriba: Las seis filas de arriba de la pantalla de la carrera
;   (ODDS, las cuotas, el recuadro y el ovalo); van tambien a los sprites 4-9,
;   que no se usan
;   0xac9b..0xad5b  (192 bytes)
DATA_pantalla_arriba:
	defb 0dfh,0dfh,0dfh,0dfh,0dfh,09ah,09bh,0dfh,09ah,09ch,0dfh,09ah,09dh,0dfh,09eh,09ch,0dfh,09eh,09dh,0dfh,09fh,09dh,0dfh,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h	; ac9b  ................................
	defb 0dfh,097h,098h,099h,0dfh,0dfh,060h,0dfh,0dfh,060h,0dfh,0dfh,060h,0dfh,0dfh,060h,0dfh,0dfh,060h,0dfh,0dfh,060h,0dfh,0c5h,0c6h,0e2h,0eah,0e2h,0e2h,0c7h,0c8h,0d1h	; acbb  ......`..`..`..`..`..`..........
	defb 090h,08ah,08eh,08fh,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,0d0h,0c1h,0a1h,0abh,0ach,0adh,0c2h,0c9h,0d1h	; acdb  ................................
	defb 090h,08bh,08eh,08fh,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,0cfh,0c3h,0b2h,0b3h,0b4h,0b5h,0c4h,0cah,0d1h	; acfb  ................................
	defb 090h,08ch,08eh,08fh,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,0ceh,0cdh,0e2h,0e2h,0ebh,0e2h,0cch,0cbh,0d1h	; ad1b  ................................
	defb 090h,08dh,08eh,08fh,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,090h,0d1h,0d1h,0b6h,0b7h,0b8h,0d6h,0d1h,0d1h,0d1h	; ad3b  ................................

; ----------------------------------------------------------------------
; DATOS pantalla_abajo: Las dos filas de abajo: 1UP-4UP, el dinero y MIN-MAX
;   (sprites 10-11)
;   0xad5b..0xad9b  (64 bytes)
DATA_pantalla_abajo:
	defb 0dfh,06ah,06eh,06fh,0dfh,0dfh,0dfh,0dfh,0dfh,060h,060h,0dfh,091h,092h,093h,0dfh,0dfh,094h,095h,096h,0dfh,06ch,06eh,06fh,0dfh,0dfh,0dfh,0dfh,0dfh,060h,060h,0dfh	; ad5b  .jno.....``..........lno.....``.
	defb 0dfh,06bh,06eh,06fh,0dfh,0dfh,0dfh,0dfh,0dfh,060h,060h,0dfh,0eeh,0eeh,0eeh,0eeh,0eeh,0eeh,0eeh,0eeh,0dfh,06dh,06eh,06fh,0dfh,0dfh,0dfh,0dfh,0dfh,060h,060h,0dfh	; ad7b  .kno.....``..........mno.....``.

; ----------------------------------------------------------------------
; DATOS musica_primera_a: La musica de la primera carrera, canal 0 (con
;   0xBD89); grupos de tres bytes (nota, duracion, espera) u ordenes
;   (0xF4-0xFF)
;   0xad9b..0xadbc  (33 bytes)
DATA_musica_primera_a:
	defb 0fah,0ffh,00ah	; ad9b
	defb 0f9h,0ffh,011h	; ad9e
	defb 040h,000h,024h	; ada1
	defb 0fbh,0ffh,010h	; ada4
	defb 018h,00ch,00ch	; ada7
	defb 0f6h,0ffh,001h	; adaa
	defb 0f5h,0ffh,010h	; adad
	defb 000h,00ch,00ch	; adb0
	defb 0f6h,0ffh,008h	; adb3
	defb 0fch,0ffh,0ffh	; adb6
	defb 0ffh,000h,002h	; adb9

; ----------------------------------------------------------------------
; DATOS sprites: Los dibujos de sprite 13-61: los caballos (tres sprites cada
;   dibujo), los jinetes con su numero, el latigo, la caida y la barra
;   0xadbc..0xb3db  (1567 bytes)
DATA_sprites:
	defb 002h,003h,03bh,03bh,01eh,03ch,03ch,07ch,0dch,01ch,018h,018h,008h,00ch,004h,000h	; adbc  ..;;.<<|........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adcc  ................
	defb 000h,000h,039h,03bh,01eh,03eh,03ch,07ch,0dch,01ch,018h,018h,008h,00ch,004h,000h	; addc  ..9;.><|........
	defb 040h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adec  @...............
	defb 002h,003h,007h,00fh,01fh,03fh,07ch,060h,000h,000h,000h,000h,000h,000h,000h,000h	; adfc  .....?|`........
	defb 000h,000h,0c0h,0e0h,0f0h,0f8h,0feh,0ffh,07fh,07fh,03fh,03fh,01fh,03fh,07fh,07fh	; ae0c  ..........??.?..
	defb 03fh,03fh,01fh,01fh,00fh,01fh,03fh,078h,0e6h,0e3h,073h,031h,01dh,00ch,000h,0ffh	; ae1c  ??....?x..s1....
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,001h,001h,003h,086h,08ch,018h,018h,0f8h	; ae2c  ................
	defb 0fch,0ffh,0feh,0feh,07eh,0fch,0fch,0e8h,0d8h,0b0h,0b0h,060h,060h,000h,000h,003h	; ae3c  ....~......``...
	defb 00eh,0bch,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae4c  ................
	defb 002h,006h,00fh,01fh,03fh,07fh,0f9h,0c0h,000h,000h,000h,000h,001h,003h,007h,000h	; ae5c  ....?...........
	defb 000h,000h,080h,0c0h,0e0h,0f8h,0feh,0ffh,0ffh,07fh,07fh,0ffh,0ffh,0fbh,077h,01fh	; ae6c  ..............w.
	defb 01fh,00fh,00fh,01fh,03fh,07fh,0eeh,0dch,058h,018h,036h,032h,060h,0c0h,0c0h,0ffh	; ae7c  ....?...X.62`...
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,07ch,0f1h,001h,001h,003h,003h,002h,006h,00ch,00ch,0fch	; ae8c  .....|..........
	defb 0feh,0ffh,0ffh,0ffh,0feh,0feh,03eh,0dfh,0c7h,083h,003h,001h,001h,000h,000h,000h	; ae9c  ......>.........
	defb 001h,0c7h,07eh,038h,000h,000h,000h,000h,000h,000h,000h,080h,080h,0c0h,0c0h,000h	; aeac  ..~8............
	defb 002h,006h,00fh,01fh,03fh,07fh,0fbh,0c1h,001h,000h,000h,000h,000h,000h,000h,000h	; aebc  ....?...........
	defb 000h,000h,000h,080h,0c0h,0e0h,0f8h,0ffh,0ffh,0ffh,0ffh,07fh,07fh,0bdh,0bdh,0ffh	; aecc  ................
	defb 0ffh,07fh,07fh,03fh,03fh,05eh,05eh,06eh,076h,0e6h,0c7h,083h,083h,0c3h,0c3h,0ffh	; aedc  ...??^^nv.......
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f9h,000h,000h,000h,000h,000h,000h,000h,000h,0e0h	; aeec  ................
	defb 0fbh,0ffh,0fch,0fch,0bch,07ch,0beh,0ceh,076h,01bh,03bh,031h,061h,0c1h,0c1h,000h	; aefc  .....|..v.;1a...
	defb 080h,0e0h,0f8h,01eh,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h,004h	; af0c  ................
	defb 006h,00fh,01fh,03fh,07fh,0fbh,0c1h,001h,000h,000h,000h,000h,000h,000h,000h,000h	; af1c  ...?............
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0ffh,0ffh,0ffh,0ffh,07fh,07fh,03fh,03fh,0ffh	; af2c  .............??.
	defb 0ffh,0ffh,0ffh,07fh,07fh,03fh,03fh,01ah,01eh,00fh,007h,006h,006h,006h,006h,0ffh	; af3c  .....??.........
	defb 0ffh,0ffh,0ffh,0ffh,0efh,0f7h,083h,005h,00dh,009h,0dbh,0d3h,016h,00ch,00ch,0c0h	; af4c  ................
	defb 0f0h,0f8h,0fch,0f6h,0f3h,0f1h,0e0h,0e0h,0c0h,080h,000h,000h,000h,000h,000h,000h	; af5c  ................
	defb 000h,000h,000h,00ch,0f8h,0e0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,004h	; af6c  ................
	defb 006h,00fh,01fh,03fh,07fh,0fbh,0c1h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af7c  ...?............
	defb 000h,000h,080h,0c0h,0f0h,0fch,0ffh,0ffh,0ffh,07fh,07fh,03fh,03fh,03bh,01dh,000h	; af8c  ...........??;..
	defb 000h,000h,000h,000h,000h,000h,000h,01ch,00eh,007h,001h,000h,000h,000h,000h,0ffh	; af9c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f0h,000h,000h,080h,0c0h,070h,030h,000h,000h,0f8h	; afac  ...........p0...
	defb 0feh,0ffh,0ffh,0feh,0fch,0fch,0f8h,078h,078h,03ch,01eh,007h,003h,000h,000h,000h	; afbc  .......xx<......
	defb 000h,000h,0e3h,0feh,038h,000h,000h,000h,000h,000h,000h,000h,0c0h,0e0h,060h,000h	; afcc  ....8.........`.
	defb 000h,002h,003h,00fh,03fh,0ffh,0ffh,007h,000h,000h,000h,000h,000h,000h,000h,000h	; afdc  ....?...........
	defb 000h,000h,000h,080h,0c0h,0f0h,0fch,0ffh,0ffh,07fh,03fh,01fh,03fh,07fh,0ffh,000h	; afec  ..........?.?...
	defb 000h,000h,000h,000h,000h,000h,000h,0fbh,03ch,00fh,003h,000h,000h,000h,000h,083h	; affc  ........<.......
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0f8h,0e0h,000h,000h,000h,000h,000h,000h,000h,0f0h	; b00c  ................
	defb 0fch,0ffh,0feh,0fch,0feh,07fh,03fh,00fh,003h,000h,000h,000h,000h,000h,000h,000h	; b01c  ......?.........
	defb 000h,0c0h,0ffh,03ch,000h,000h,000h,0e0h,0f0h,03ch,00fh,003h,000h,000h,000h,001h	; b02c  ...<.....<......
	defb 001h,003h,007h,00fh,01fh,03eh,030h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b03c  .....>0.........
	defb 0c0h,0e0h,0f0h,0f8h,0fch,07eh,03fh,03fh,01fh,01fh,01fh,03fh,07fh,07bh,0e7h,000h	; b04c  .....~??...?.{..
	defb 000h,000h,000h,000h,000h,000h,000h,0cfh,0ceh,07ch,038h,030h,060h,040h,0c0h,0ffh	; b05c  .........|80`@..
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0dfh,0bch,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b06c  ................
	defb 000h,000h,000h,000h,000h,001h,0fbh,0fch,0feh,0feh,0feh,07fh,0bfh,01fh,006h,000h	; b07c  ................
	defb 000h,000h,001h,01eh,0fch,0f0h,000h,000h,000h,000h,0f0h,0f8h,0dfh,007h,000h,000h	; b08c  ................
	defb 000h,000h,000h,007h,01fh,07fh,03fh,03bh,03ch,03ch,078h,060h,060h,000h,000h,000h	; b09c  ......?;<<x``...
	defb 000h,000h,000h,0c0h,0f0h,0feh,0ffh,0ffh,07fh,03fh,03fh,01fh,01fh,01eh,03dh,000h	; b0ac  .........??...=.
	defb 000h,000h,000h,000h,000h,000h,000h,03bh,077h,0e3h,0c1h,060h,070h,01ch,00ch,0ffh	; b0bc  .......;w..`p...
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,0b0h,0f0h,0e0h,000h,000h,000h,001h	; b0cc  ................
	defb 000h,000h,000h,000h,001h,03fh,0fch,0fch,0fch,0feh,07fh,0bfh,0cfh,080h,000h,0c0h	; b0dc  .....?..........
	defb 070h,030h,030h,070h,0e0h,080h,000h,000h,020h,078h,0ffh,0c3h,080h,000h,000h,004h	; b0ec  p00p.... x......
	defb 006h,00fh,01fh,03fh,07fh,0f9h,0c1h,000h,000h,000h,018h,03ch,02fh,067h,063h,000h	; b0fc  ...?.......</gc.
	defb 000h,000h,0c0h,0e0h,0f0h,0f8h,0f8h,0fch,0feh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,000h	; b10c  ................
	defb 000h,000h,000h,000h,000h,000h,000h,07fh,03fh,00fh,003h,001h,000h,000h,000h,000h	; b11c  ........?.......
	defb 000h,000h,000h,000h,080h,0c0h,0f0h,0fch,0feh,0ffh,0bfh,0dfh,01fh,01fh,01eh,000h	; b12c  ................
	defb 000h,000h,000h,000h,000h,000h,000h,00eh,007h,007h,006h,00ch,00ch,018h,030h,000h	; b13c  ..............0.
	defb 000h,0e0h,0b8h,01ch,00ch,00eh,006h,006h,002h,002h,001h,000h,000h,000h,000h,0ffh	; b14c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; b15c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; b16c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b17c  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b18c  ................
	defb 000h,000h,000h,000h,000h,000h,000h,00fh,023h,00dh,009h,019h,071h,063h,003h,001h	; b19c  ........#...qc..
	defb 0e6h,07eh,03ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,070h	; b1ac  .~<............p
	defb 070h,03ch,01eh,03fh,0feh,03ch,031h,018h,008h,001h,000h,000h,000h,000h,000h,000h	; b1bc  p<.?.<1.........
	defb 000h,000h,000h,0e0h,000h,080h,080h,080h,080h,0c0h,000h,000h,000h,000h,000h,070h	; b1cc  ...............p
	defb 070h,03ch,01eh,03fh,0feh,03ch,031h,018h,008h,001h,000h,000h,000h,000h,000h,000h	; b1dc  p<.?.<1.........
	defb 000h,000h,000h,0e0h,000h,0c0h,0e0h,040h,080h,0e0h,000h,000h,000h,000h,000h,070h	; b1ec  .......@.......p
	defb 070h,03ch,01eh,03fh,0feh,03ch,031h,018h,009h,000h,000h,000h,000h,000h,000h,000h	; b1fc  p<.?.<1.........
	defb 000h,000h,000h,0e0h,000h,0c0h,020h,040h,020h,0c0h,000h,000h,000h,000h,000h,070h	; b20c  ...... @ ......p
	defb 070h,03ch,01eh,03fh,0feh,03ch,030h,019h,009h,000h,000h,000h,000h,000h,000h,000h	; b21c  p<.?.<0.........
	defb 000h,000h,000h,0e0h,000h,040h,0c0h,040h,0e0h,040h,000h,000h,000h,000h,000h,038h	; b22c  .....@.@.@.....8
	defb 038h,018h,03dh,03eh,07fh,0deh,01ch,018h,019h,008h,00ch,005h,000h,000h,000h,000h	; b23c  8.=>............
	defb 040h,080h,000h,000h,000h,000h,000h,080h,080h,080h,080h,0c0h,000h,000h,000h,038h	; b24c  @..............8
	defb 038h,018h,03dh,03eh,07eh,0deh,01ch,018h,019h,008h,00ch,005h,000h,000h,000h,000h	; b25c  8.=>~...........
	defb 040h,080h,000h,000h,000h,000h,000h,0c0h,020h,040h,080h,0e0h,000h,000h,000h,038h	; b26c  @....... @.....8
	defb 038h,018h,03dh,03eh,07eh,0deh,01ch,018h,019h,008h,00dh,004h,000h,000h,000h,000h	; b27c  8.=>~...........
	defb 040h,080h,000h,000h,000h,000h,000h,0c0h,020h,040h,020h,0c0h,000h,000h,000h,038h	; b28c  @....... @ ....8
	defb 038h,018h,03dh,03eh,07eh,0deh,01ch,018h,018h,009h,00dh,004h,000h,000h,000h,000h	; b29c  8.=>~...........
	defb 040h,080h,000h,000h,000h,000h,000h,040h,0c0h,040h,0e0h,040h,000h,000h,000h,000h	; b2ac  @......@.@.@....
	defb 000h,000h,000h,000h,010h,010h,009h,007h,013h,01fh,000h,000h,000h,000h,000h,000h	; b2bc  ................
	defb 000h,000h,0e0h,0e0h,060h,0f0h,0f8h,0e8h,0c8h,000h,000h,000h,000h,000h,000h,000h	; b2cc  ....`...........
	defb 000h,000h,000h,000h,020h,020h,018h,00fh,027h,03fh,000h,000h,000h,000h,000h,000h	; b2dc  ....  ..'?......
	defb 000h,000h,000h,000h,038h,020h,078h,0f8h,0f8h,0e0h,060h,03eh,000h,000h,000h,000h	; b2ec  ....8 x...`>....
	defb 080h,0c4h,027h,011h,00bh,00fh,007h,007h,003h,000h,003h,006h,000h,000h,000h,000h	; b2fc  ..'.............
	defb 000h,000h,000h,000h,000h,000h,0d8h,0f8h,0f8h,0c0h,080h,000h,000h,000h,000h,0ffh	; b30c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b31c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b32c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b33c  ................
	defb 0e3h,0c3h,0d3h,009h,081h,081h,0f3h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; b34c  ................
	defb 000h,000h,000h,001h,0e7h,0fch,0f8h,0fch,0feh,0ffh,07fh,0bfh,00fh,001h,000h,004h	; b35c  ................
	defb 008h,018h,070h,0e0h,080h,000h,000h,000h,000h,000h,080h,0e7h,0ffh,0f0h,000h,002h	; b36c  ..p.............
	defb 003h,00fh,03fh,0ffh,0ffh,006h,000h,000h,000h,000h,003h,00fh,03fh,0f0h,0c0h,000h	; b37c  ..?.........?...
	defb 000h,0c0h,0f8h,0ffh,0ffh,0ffh,07fh,03fh,03fh,07fh,0ffh,0f3h,000h,000h,000h,000h	; b38c  .......??.......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0f8h	; b39c  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,0f8h	; b3ac  ................
	defb 0ffh,0feh,0fch,0feh,07fh,03fh,00eh,000h,000h,000h,000h,000h,000h,000h,000h,00fh	; b3bc  .....?..........
	defb 0fch,0f0h,000h,000h,0c0h,0f0h,03fh,007h,000h,000h,000h,000h,000h,000h,000h	; b3cc  ......?........

; ----------------------------------------------------------------------
; DATOS caballo_dibujos: Los diez dibujos del caballo: para cada uno de sus
;   tres sprites, el dibujo, la Y y la X (9 bytes)
;   0xb3db..0xb435  (90 bytes)
DATA_caballo_dibujos:
	defb 03ch,0f5h,0eeh,040h,0fdh,0f5h,044h,0fdh,005h	; b3db  <..@..D..
	defb 048h,0f5h,0eeh,04ch,0fdh,0f3h,050h,0fdh,003h	; b3e4  H..L..P..
	defb 054h,0f5h,0eeh,058h,0fdh,0f5h,05ch,0fdh,005h	; b3ed  T..X..\..
	defb 060h,0f5h,0eeh,064h,0fdh,0f6h,068h,0fdh,006h	; b3f6  `..d..h..
	defb 06ch,0f5h,0edh,070h,0fdh,0f5h,074h,0fdh,005h	; b3ff  l..p..t..
	defb 078h,0f5h,0edh,07ch,0fdh,0f5h,080h,0fdh,005h	; b408  x..|.....
	defb 084h,0f5h,0edh,088h,0fdh,0f5h,08ch,0f5h,005h	; b411  .........
	defb 090h,0f5h,0edh,094h,0fdh,0f5h,098h,0f5h,005h	; b41a  .........
	defb 09ch,0f1h,0f1h,0a0h,0f9h,0f9h,0a4h,001h,001h	; b423  .........
	defb 0ech,0f8h,0edh,0f0h,0fdh,0f5h,0f4h,0fdh,005h	; b42c  .........

; ----------------------------------------------------------------------
; DATOS casillas: Las casillas 0x00-0x7F: los arbustos, las cosas sueltas
;   (0x13-0x1A), el agua de la ria (0x1B-0x1E), los bordes del recuadro, las
;   letras en ASCII (0x30-0x5F) y las letras grandes del titulo (0x60-0x7F)
;   0xb435..0xb835  (1024 bytes)
DATA_casillas:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; b435  ........
	defb 000h,000h,000h,000h,000h,001h,007h,00fh	; b43d  ........
	defb 00fh,01fh,01fh,01fh,00fh,00fh,007h,003h	; b445  ........
	defb 000h,000h,000h,000h,061h,0f3h,0fbh,0c9h	; b44d  ....a...
	defb 092h,067h,0ddh,0f1h,0c8h,036h,0cdh,0fbh	; b455  .g...6..
	defb 000h,000h,000h,060h,0f3h,0f7h,091h,02bh	; b45d  ...`...+
	defb 0b6h,05bh,0cfh,013h,04ch,0a7h,069h,0b7h	; b465  .[..L.i.
	defb 000h,000h,000h,000h,000h,080h,0d0h,0f8h	; b46d  ........
	defb 0fch,0fch,0fch,0f8h,0f8h,0f8h,0f0h,0e0h	; b475  ........
	defb 000h,000h,000h,004h,00dh,02fh,07fh,07fh	; b47d  ...../..
	defb 00fh,03fh,00ch,07fh,07fh,03fh,01fh,00fh	; b485  .?...?..
	defb 000h,000h,071h,0fbh,089h,066h,038h,0e3h	; b48d  ..q..f8.
	defb 0f6h,06fh,041h,02ah,0b6h,06fh,0dfh,0f7h	; b495  .oA*.o..
	defb 038h,024h,052h,020h,045h,053h,019h,072h	; b49d  8$R ES.r
	defb 0a3h,056h,0edh,032h,0e9h,077h,0dfh,073h	; b4a5  .V.2.w.s
	defb 000h,004h,09eh,056h,094h,028h,022h,05bh	; b4ad  ...V.("[
	defb 0afh,043h,06dh,0f3h,0b9h,08eh,03dh,0dfh	; b4b5  .Cm...=.
	defb 000h,000h,000h,000h,080h,0d8h,0fch,0feh	; b4bd  ........
	defb 0feh,0afh,043h,0afh,0feh,0feh,0fch,0f8h	; b4c5  ..C.....
	defb 020h,00fh,03fh,007h,0d0h,01fh,007h,088h	; b4cd   .?.....
	defb 042h,008h,0e0h,0f8h,0c0h,03fh,0f0h,004h	; b4d5  B....?..
	defb 002h,090h,00eh,03fh,0f0h,01fh,003h,084h	; b4dd  ...?....
	defb 040h,01ch,07eh,0c7h,0fch,00fh,0e0h,009h	; b4e5  @.~.....
	defb 040h,003h,00fh,007h,07fh,00fh,010h,042h	; b4ed  @......B
	defb 008h,0c2h,080h,0f8h,01fh,0e0h,008h,001h	; b4f5  ........
	defb 040h,00ch,02ch,000h,073h,0f0h,00fh,040h	; b4fd  @.,.s..@
	defb 002h,088h,007h,00fh,0f8h,0fch,00fh,0f0h	; b505  ........
	defb 0ffh,0ffh,0b7h,0fdh,0dfh,0fbh,0bfh,0feh	; b50d  ........
	defb 0efh,09fh,0fdh,0f6h,0dfh,077h,0f9h,09fh	; b515  .....w..
	defb 078h,0efh,09dh,0f7h,0bdh,0c7h,07bh,0bdh	; b51d  x.....{.
	defb 0f3h,0bdh,0deh,0efh,0bbh,07eh,0ebh,0b7h	; b525  .....~..
	defb 03ch,07eh,0ffh,0ffh,0ffh,0c3h,0c3h,0c3h	; b52d  <~......
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; b535  ........
	defb 000h,01fh,01fh,060h,060h,060h,060h,060h	; b53d  ...`````
	defb 060h,060h,060h,060h,060h,01fh,01fh,000h	; b545  `````...
	defb 000h,0feh,0feh,000h,000h,000h,000h,000h	; b54d  ........
	defb 000h,000h,000h,000h,000h,0feh,0feh,000h	; b555  ........
	defb 007h,01fh,018h,060h,060h,060h,060h,07fh	; b55d  ...````.
	defb 07fh,060h,060h,060h,060h,060h,060h,000h	; b565  .``````.
	defb 0e0h,0f8h,018h,006h,006h,006h,006h,0feh	; b56d  ........
	defb 0feh,006h,006h,006h,006h,006h,006h,000h	; b575  ........
	defb 000h,01fh,01fh,060h,060h,060h,060h,01fh	; b57d  ...````.
	defb 01fh,000h,000h,000h,000h,07fh,07fh,000h	; b585  ........
	defb 000h,0feh,0feh,000h,000h,000h,000h,0f8h	; b58d  ........
	defb 0f8h,006h,006h,006h,006h,0f8h,0f8h,000h	; b595  ........
	defb 000h,001h,001h,001h,001h,001h,001h,001h	; b59d  ........
	defb 001h,001h,001h,001h,001h,001h,001h,000h	; b5a5  ........
	defb 000h,080h,080h,080h,080h,080h,080h,080h	; b5ad  ........
	defb 03eh,041h,041h,041h,041h,041h,03eh,000h	; b5b5  >AAAAA>.
	defb 008h,008h,008h,008h,008h,008h,008h,000h	; b5bd  ........
	defb 07eh,001h,001h,03eh,040h,040h,07fh,000h	; b5c5  ~..>@@..
	defb 07eh,001h,001h,03eh,001h,001h,07eh,000h	; b5cd  ~..>..~.
	defb 044h,044h,044h,044h,07fh,004h,004h,000h	; b5d5  DDDD....
	defb 07fh,040h,040h,07eh,001h,001h,07eh,000h	; b5dd  .@@~..~.
	defb 03fh,040h,040h,03eh,041h,041h,03eh,000h	; b5e5  ?@@>AA>.
	defb 07fh,001h,001h,001h,001h,001h,001h,000h	; b5ed  ........
	defb 03eh,041h,041h,03eh,041h,041h,03eh,000h	; b5f5  >AA>AA>.
	defb 03eh,041h,041h,03eh,001h,001h,07eh,000h	; b5fd  >AA>..~.
	defb 000h,008h,000h,000h,000h,008h,000h,000h	; b605  ........
	defb 000h,008h,000h,000h,000h,008h,010h,000h	; b60d  ........
	defb 003h,00ch,030h,040h,030h,00ch,003h,000h	; b615  ..0@0...
	defb 000h,000h,07fh,000h,07fh,000h,000h,000h	; b61d  ........
	defb 060h,018h,006h,001h,006h,018h,060h,000h	; b625  `.....`.
	defb 03eh,041h,041h,006h,008h,000h,008h,000h	; b62d  >AA.....
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; b635  <B....B<
	defb 01ch,022h,041h,041h,07fh,041h,041h,000h	; b63d  ."AA.AA.
	defb 07eh,041h,041h,07eh,041h,041h,07eh,000h	; b645  ~AA~AA~.
	defb 03eh,041h,040h,040h,040h,041h,03eh,000h	; b64d  >A@@@A>.
	defb 07ch,042h,041h,041h,041h,042h,07ch,000h	; b655  |BAAAB|.
	defb 07fh,040h,040h,07fh,040h,040h,07fh,000h	; b65d  .@@.@@..
	defb 07fh,040h,040h,07eh,040h,040h,040h,000h	; b665  .@@~@@@.
	defb 03eh,041h,040h,04fh,041h,041h,03eh,000h	; b66d  >A@OAA>.
	defb 041h,041h,041h,07fh,041h,041h,041h,000h	; b675  AAA.AAA.
	defb 01ch,008h,008h,008h,008h,008h,01ch,000h	; b67d  ........
	defb 007h,002h,002h,002h,042h,042h,03ch,000h	; b685  ....BB<.
	defb 041h,042h,044h,078h,044h,042h,041h,000h	; b68d  ABDxDBA.
	defb 040h,040h,040h,040h,040h,040h,07fh,000h	; b695  @@@@@@..
	defb 041h,063h,055h,049h,041h,041h,041h,000h	; b69d  AcUIAAA.
	defb 041h,061h,051h,049h,045h,043h,041h,000h	; b6a5  AaQIECA.
	defb 03eh,041h,041h,041h,041h,041h,03eh,000h	; b6ad  >AAAAA>.
	defb 07eh,041h,041h,07eh,040h,040h,040h,000h	; b6b5  ~AA~@@@.
	defb 03eh,041h,041h,041h,049h,045h,03eh,001h	; b6bd  >AAAIE>.
	defb 07eh,041h,041h,07eh,041h,041h,041h,000h	; b6c5  ~AA~AAA.
	defb 03eh,041h,040h,03eh,001h,041h,03eh,000h	; b6cd  >A@>.A>.
	defb 07fh,008h,008h,008h,008h,008h,008h,000h	; b6d5  ........
	defb 041h,041h,041h,041h,041h,041h,03eh,000h	; b6dd  AAAAAA>.
	defb 041h,041h,022h,022h,014h,014h,008h,000h	; b6e5  AA""....
	defb 049h,049h,049h,049h,049h,049h,036h,000h	; b6ed  IIIIII6.
	defb 041h,022h,014h,008h,014h,022h,041h,000h	; b6f5  A"..."A.
	defb 041h,041h,041h,07fh,008h,008h,008h,000h	; b6fd  AAA.....
	defb 07fh,002h,004h,008h,010h,020h,07fh,000h	; b705  ..... ..
	defb 000h,000h,000h,000h,000h,000h,010h,000h	; b70d  ........
	defb 018h,024h,018h,029h,045h,042h,03dh,000h	; b715  .$.)EB=.
	defb 000h,000h,000h,008h,000h,000h,000h,000h	; b71d  ........
	defb 000h,000h,000h,000h,03eh,000h,000h,000h	; b725  ....>...
	defb 000h,000h,000h,000h,000h,000h,000h,07fh	; b72d  ........
	defb 003h,003h,003h,003h,003h,003h,003h,0ffh	; b735  ........
	defb 0ffh,003h,003h,003h,007h,007h,00eh,00eh	; b73d  ........
	defb 01ch,01ch,038h,038h,070h,070h,0e0h,0e0h	; b745  ..88pp..
	defb 080h,080h,080h,080h,080h,080h,080h,0ffh	; b74d  ........
	defb 0ffh,080h,080h,080h,0c0h,0c0h,0e0h,0e0h	; b755  ........
	defb 070h,070h,038h,038h,01ch,01ch,00fh,00fh	; b75d  pp88....
	defb 000h,0d8h,0fbh,0fbh,0d9h,0d9h,0dbh,0dbh	; b765  ........
	defb 0f0h,0f3h,0dbh,0dbh,0dbh,0dbh,0dbh,0fbh	; b76d  ........
	defb 0fbh,0c0h,0c3h,0c3h,0c0h,0c0h,0c0h,0c0h	; b775  ........
	defb 030h,030h,0ffh,0ffh,086h,086h,0ffh,0ffh	; b77d  00......
	defb 000h,0ffh,0ffh,003h,0ffh,0ffh,003h,0ffh	; b785  ........
	defb 0ffh,030h,0ffh,0ffh,030h,030h,030h,030h	; b78d  .0..0000
	defb 001h,001h,07fh,07fh,060h,061h,07fh,03fh	; b795  ....`a.?
	defb 001h,03fh,03fh,001h,07fh,07fh,000h,000h	; b79d  .??.....
	defb 03fh,03fh,030h,030h,030h,03fh,03fh,030h	; b7a5  ??000??0
	defb 080h,080h,0feh,0feh,006h,086h,0feh,0fch	; b7ad  ........
	defb 080h,0fch,0fch,080h,0feh,0feh,000h,000h	; b7b5  ........
	defb 0fch,0fch,00ch,00ch,00ch,0fch,0fch,00ch	; b7bd  ........
	defb 018h,018h,0feh,0feh,066h,066h,0ffh,0ffh	; b7c5  ....ff..
	defb 000h,07eh,07eh,066h,066h,07eh,07eh,036h	; b7cd  .~~ff~~6
	defb 036h,036h,036h,037h,077h,067h,0e6h,066h	; b7d5  6667wg.f
	defb 018h,018h,0feh,0feh,066h,066h,0ffh,0ffh	; b7dd  ....ff..
	defb 000h,07eh,07eh,066h,066h,07eh,07eh,06ch	; b7e5  .~~ff~~l
	defb 06ch,06ch,06ch,0eeh,0eeh,06fh,0efh,0cfh	; b7ed  lll..o..
	defb 03fh,03fh,031h,031h,03fh,03fh,031h,031h	; b7f5  ??11??11
	defb 03fh,03fh,031h,031h,03fh,03fh,000h,000h	; b7fd  ??11??..
	defb 0cdh,0cdh,0cdh,0cdh,0cdh,0cdh,0c0h,000h	; b805  ........
	defb 0f0h,0f0h,080h,080h,0f0h,0f0h,080h,080h	; b80d  ........
	defb 0f0h,0f0h,080h,080h,0ffh,0ffh,003h,003h	; b815  ........
	defb 0b3h,0b3h,0b3h,0b3h,0b7h,0b7h,007h,006h	; b81d  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; b825  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; b82d  ........

; ----------------------------------------------------------------------
; DATOS casillas_altas: Las casillas 0x80-0xF7: las cifras pequenas y grandes,
;   1UP-4UP, MIN, MAX, ODDS, las parejas, RACE, GRASS, DIRT, las distancias,
;   el ovalo, el cartel de CASIO, la valla de abajo, los postes y la meta; la
;   copia de 1 KB sigue por los colores
;   0xb835..0xbbf5  (960 bytes)
DATA_casillas_altas:
	defb 000h,03eh,022h,022h,022h,022h,03eh,000h	; b835  .>"""">.
	defb 000h,008h,008h,008h,008h,008h,008h,000h	; b83d  ........
	defb 000h,03eh,002h,03eh,020h,020h,03eh,000h	; b845  .>.>  >.
	defb 000h,03eh,002h,03eh,002h,002h,03eh,000h	; b84d  .>.>..>.
	defb 000h,024h,024h,024h,03eh,004h,004h,000h	; b855  .$$$>...
	defb 000h,03eh,020h,03eh,002h,002h,03eh,000h	; b85d  .> >..>.
	defb 000h,03eh,020h,03eh,022h,022h,03eh,000h	; b865  .> >"">.
	defb 000h,07ch,044h,044h,004h,004h,004h,000h	; b86d  .|DD....
	defb 000h,03eh,022h,03eh,022h,022h,03eh,000h	; b875  .>">"">.
	defb 000h,03eh,022h,03eh,002h,002h,03eh,000h	; b87d  .>">..>.
	defb 000h,018h,038h,018h,018h,018h,018h,03ch	; b885  ..8....<
	defb 000h,03ch,07eh,046h,01ch,038h,060h,07eh	; b88d  .<~F.8`~
	defb 000h,03ch,046h,01eh,006h,046h,07eh,03ch	; b895  .<F..F~<
	defb 000h,01ch,03ch,02ch,06ch,07eh,07eh,00ch	; b89d  ..<,l~~.
	defb 000h,066h,066h,066h,066h,066h,066h,03ch	; b8a5  .ffffff<
	defb 000h,07ch,07eh,066h,07eh,07ch,060h,060h	; b8ad  .|~f~|``
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; b8b5  ........
	defb 000h,084h,0cch,0cch,0fch,0b4h,0b4h,000h	; b8bd  ........
	defb 000h,0c8h,0cch,0ceh,0cfh,0cdh,0cch,000h	; b8c5  ........
	defb 000h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,000h	; b8cd  ........
	defb 000h,008h,00ch,00ch,00fh,00bh,00bh,000h	; b8d5  ........
	defb 000h,04ch,0cfh,0d9h,0d9h,05fh,059h,000h	; b8dd  .L..._Y.
	defb 000h,033h,01eh,08ch,09eh,0b3h,0b3h,000h	; b8e5  .3......
	defb 067h,094h,094h,094h,094h,094h,067h,000h	; b8ed  g.....g.
	defb 038h,0a5h,0a5h,0a4h,0a4h,0a5h,038h,000h	; b8f5  8.....8.
	defb 0c8h,02ch,00eh,0cfh,02eh,02ch,0c8h,000h	; b8fd  .,...,..
	defb 000h,018h,038h,019h,019h,018h,018h,03ch	; b905  ..8....<
	defb 000h,01eh,03fh,0a3h,08eh,01ch,030h,03fh	; b90d  ..?...0?
	defb 000h,01eh,023h,08fh,083h,023h,03fh,01eh	; b915  ..#..#?.
	defb 000h,00eh,01eh,096h,0b6h,03fh,03fh,006h	; b91d  .....??.
	defb 000h,078h,0fch,08dh,039h,070h,0c0h,0fch	; b925  .x..9p..
	defb 000h,078h,08ch,03dh,00dh,08ch,0fch,078h	; b92d  .x.=...x
	defb 000h,03ch,07eh,066h,066h,066h,07eh,03ch	; b935  .<~fff~<
	defb 000h,018h,038h,018h,018h,018h,018h,03ch	; b93d  ..8....<
	defb 000h,03ch,07eh,046h,01ch,038h,060h,07eh	; b945  .<~F.8`~
	defb 000h,03ch,046h,01eh,006h,046h,07eh,03ch	; b94d  .<F..F~<
	defb 000h,01ch,03ch,02ch,06ch,07eh,07eh,00ch	; b955  ..<,l~~.
	defb 000h,07eh,060h,07ch,07eh,006h,07eh,07ch	; b95d  .~`|~.~|
	defb 000h,03ch,07eh,060h,07ch,066h,066h,03ch	; b965  .<~`|ff<
	defb 000h,07eh,07eh,006h,00ch,00ch,018h,018h	; b96d  .~~.....
	defb 000h,03ch,066h,066h,03ch,066h,066h,03ch	; b975  .<ff<ff<
	defb 000h,03ch,066h,066h,03eh,006h,07eh,03ch	; b97d  .<ff>.~<
	defb 000h,026h,069h,029h,029h,029h,029h,076h	; b985  .&i))))v
	defb 000h,078h,06dh,06dh,079h,06dh,06dh,06dh	; b98d  .xmmymmm
	defb 000h,0e3h,0f7h,0b6h,0b6h,0f6h,0b7h,0b3h	; b995  ........
	defb 000h,09fh,0d8h,058h,01fh,058h,0dfh,09fh	; b99d  ...X.X..
	defb 000h,078h,07ch,066h,066h,066h,07ch,078h	; b9a5  .x|fff|x
	defb 000h,03ch,03ch,018h,018h,018h,03ch,03ch	; b9ad  .<<...<<
	defb 000h,07ch,066h,066h,07ch,066h,066h,066h	; b9b5  .|ff|fff
	defb 000h,07eh,07eh,018h,018h,018h,018h,018h	; b9bd  .~~.....
	defb 000h,039h,07dh,061h,06dh,065h,07dh,039h	; b9c5  .9}ame}9
	defb 000h,0e3h,0b3h,0b6h,0e6h,0b7h,0b6h,0b6h	; b9cd  ........
	defb 000h,08eh,0dfh,0d8h,0ceh,0c3h,0dfh,0deh	; b9d5  ........
	defb 000h,038h,07ch,060h,038h,00ch,07ch,078h	; b9dd  .8|`8.|x
	defb 000h,031h,073h,032h,030h,031h,033h,07bh	; b9e5  .1s2013{
	defb 000h,0c7h,0edh,06dh,0cdh,08dh,00dh,0e7h	; b9ed  ...m....
	defb 000h,01ch,0b6h,0b6h,0b6h,0b6h,0b6h,01ch	; b9f5  ........
	defb 000h,031h,073h,033h,033h,033h,033h,079h	; b9fd  .1s3333y
	defb 000h,0c7h,0edh,00dh,0cdh,06dh,06dh,0c7h	; ba05  .....mm.
	defb 000h,030h,078h,049h,019h,033h,063h,078h	; ba0d  .0xI.3cx
	defb 000h,0c7h,0cdh,0cdh,04dh,06dh,0edh,0c7h	; ba15  ....Mm..
	defb 000h,031h,07bh,00ah,038h,009h,07bh,033h	; ba1d  .1{.8.{3
	defb 000h,0c7h,0edh,06dh,0cdh,08dh,00dh,0e7h	; ba25  ...m....
	defb 000h,031h,07bh,00bh,03bh,00bh,07bh,031h	; ba2d  .1{.;.{1
	defb 000h,0c7h,0edh,00dh,0cdh,06dh,06dh,0c7h	; ba35  .....mm.
	defb 0ffh,0feh,0fch,0fch,0f8h,0f8h,0f0h,0f0h	; ba3d  ........
	defb 0ffh,07fh,03fh,03fh,01fh,01fh,00fh,00fh	; ba45  ..??....
	defb 0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,0ffh	; ba4d  ........
	defb 00fh,00fh,01fh,01fh,03fh,03fh,07fh,0ffh	; ba55  ....??..
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0fch	; ba5d  ........
	defb 0f8h,0e0h,0c0h,080h,000h,000h,000h,000h	; ba65  ........
	defb 01fh,007h,003h,001h,000h,000h,000h,000h	; ba6d  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,03fh	; ba75  .......?
	defb 03fh,01fh,01fh,01fh,00fh,00fh,00fh,00fh	; ba7d  ?.......
	defb 00fh,00fh,00fh,00fh,01fh,01fh,01fh,03fh	; ba85  .......?
	defb 03fh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba8d  ?.......
	defb 000h,000h,000h,000h,001h,003h,007h,01fh	; ba95  ........
	defb 000h,000h,000h,000h,080h,0c0h,0e0h,0f8h	; ba9d  ........
	defb 0fch,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; baa5  ........
	defb 0f0h,0f0h,0f0h,0f0h,0f8h,0f8h,0f8h,0fch	; baad  ........
	defb 0fch,0f8h,0f8h,0f8h,0f0h,0f0h,0f0h,0f0h	; bab5  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; babd  ........
	defb 000h,03ch,07eh,066h,060h,066h,07eh,03ch	; bac5  .<~f`f~<
	defb 000h,030h,079h,0cdh,0cch,0fch,0cdh,0cch	; bacd  .0y.....
	defb 000h,0f3h,0fbh,083h,0f3h,01bh,0fbh,0f3h	; bad5  ........
	defb 000h,03ch,07eh,066h,066h,066h,07eh,03ch	; badd  .<~fff~<
	defb 000h,054h,07eh,06ah,06ah,06ah,06ah,06ah	; bae5  .T~jjjjj
	defb 0ffh,018h,018h,018h,018h,018h,018h,018h	; baed  ........
	defb 000h,000h,000h,000h,000h,000h,0ffh,0ffh	; baf5  ........
	defb 07fh,0ffh,0c1h,0c1h,0c1h,0c1h,0ffh,07fh	; bafd  ........
	defb 07fh,0ffh,0c0h,0c0h,0c0h,0c0h,0ffh,07fh	; bb05  ........
	defb 0c7h,0c7h,0c6h,0c6h,0c0h,0c0h,0ffh,07fh	; bb0d  ........
	defb 030h,030h,030h,030h,030h,030h,0f0h,0f0h	; bb15  000000..
	defb 0f0h,0f0h,080h,080h,080h,080h,0f0h,0f0h	; bb1d  ........
	defb 0e0h,0f0h,030h,030h,030h,030h,0f0h,0e0h	; bb25  ..0000..
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; bb2d  ........
	defb 03ch,0ffh,0ffh,03ch,03ch,03ch,03ch,03ch	; bb35  <..<<<<<
	defb 018h,0ffh,0ffh,018h,018h,018h,018h,018h	; bb3d  ........
	defb 000h,004h,000h,000h,000h,040h,000h,000h	; bb45  .....@..
	defb 000h,001h,000h,000h,000h,000h,000h,000h	; bb4d  ........
	defb 000h,000h,000h,000h,080h,000h,000h,000h	; bb55  ........
	defb 000h,000h,000h,040h,000h,000h,002h,000h	; bb5d  ...@....
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fch,0fch	; bb65  ........
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fch,0fch	; bb6d  ........
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fch,0fch	; bb75  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; bb7d  ........
	defb 001h,001h,001h,001h,001h,001h,001h,001h	; bb85  ........
	defb 080h,080h,080h,080h,080h,080h,080h,080h	; bb8d  ........
	defb 080h,080h,080h,080h,080h,080h,080h,080h	; bb95  ........
	defb 080h,080h,080h,080h,080h,080h,080h,000h	; bb9d  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; bba5  ........
	defb 080h,080h,080h,080h,080h,080h,080h,080h	; bbad  ........
	defb 000h,0f8h,0f8h,006h,006h,006h,006h,006h	; bbb5  ........
	defb 006h,006h,006h,006h,006h,0f8h,0f8h,000h	; bbbd  ........
	defb 000h,03ch,07eh,060h,03ch,006h,07eh,07ch	; bbc5  .<~`<.~|
	defb 000h,07eh,07eh,018h,018h,018h,018h,018h	; bbcd  .~~.....
	defb 000h,07ch,07eh,066h,07ch,066h,07eh,07ch	; bbd5  .|~f|f~|
	defb 000h,03ch,07eh,066h,066h,066h,07eh,03ch	; bbdd  .<~fff~<
	defb 000h,078h,07ch,066h,066h,066h,07ch,078h	; bbe5  .x|fff|x
	defb 000h,066h,076h,07eh,07eh,07eh,06eh,066h	; bbed  .fv~~~nf

; ----------------------------------------------------------------------
; DATOS colores: Los colores de las casillas 0x00-0x1F (8 bytes cada una); en
;   0xBC8D, los de las cosas sueltas en la hierba
;   0xbbf5..0xbcf5  (256 bytes)
DATA_colores:
	defb 033h,033h,033h,033h,033h,033h,033h,033h	; bbf5  33333333
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h	; bbfd  ........
	defb 036h,036h,0c6h,036h,0c6h,0c6h,0c6h,0c6h	; bc05  66.6....
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,03ah	; bc0d  .......:
	defb 03ah,03ah,03ah,0c3h,0c3h,0c3h,0c3h,0c3h	; bc15  :::.....
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,03ah,03ah	; bc1d  ......::
	defb 03ah,03ah,03ah,0c3h,0c3h,0c3h,0c3h,0c3h	; bc25  :::.....
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h	; bc2d  ........
	defb 036h,036h,0c6h,036h,0c6h,036h,0c6h,0c6h	; bc35  66.6.6..
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h	; bc3d  ........
	defb 03ah,03ah,0c3h,0c6h,0c6h,0c6h,0c6h,0c6h	; bc45  ::......
	defb 0a6h,0a6h,0a6h,0a6h,03ah,03ah,03ah,03ah	; bc4d  ....::::
	defb 03ah,03ah,0c3h,0c3h,0c3h,0c3h,0c3h,0c3h	; bc55  ::......
	defb 0a6h,0a6h,03ah,03ah,03ah,03ah,03ah,03ah	; bc5d  ..::::::
	defb 03ah,03ah,03ah,0c3h,0c3h,0c3h,0c3h,0c3h	; bc65  :::.....
	defb 0a6h,0a6h,0a6h,03ah,03ah,03ah,03ah,03ah	; bc6d  ...:::::
	defb 03ah,0c3h,0c3h,0c3h,0c3h,0c3h,0c3h,0c3h	; bc75  :.......
	defb 036h,036h,036h,036h,036h,0a6h,0a6h,0a6h	; bc7d  66666...
	defb 0a6h,03ah,0c3h,0c3h,0c6h,0c6h,0c6h,0c6h	; bc85  .:......
	defb 0c3h,073h,073h,047h,047h,073h,043h,0c3h	; bc8d  .ssGGsC.
	defb 0c3h,0c3h,073h,073h,047h,047h,043h,0c3h	; bc95  ..ssGGC.
	defb 0c3h,0c3h,073h,073h,047h,043h,043h,0c3h	; bc9d  ..ssGCC.
	defb 0c3h,073h,073h,047h,073h,073h,043h,0c3h	; bca5  .ssGssC.
	defb 0c3h,0a3h,0a3h,0cah,0a3h,0c3h,0c3h,0c3h	; bcad  ........
	defb 0c3h,00ch,0c3h,0a3h,0cah,0c3h,0c3h,0c3h	; bcb5  ........
	defb 0c3h,0a3h,0c3h,033h,0a3h,0cah,0c3h,0c3h	; bcbd  ...3....
	defb 0c3h,0c3h,0a3h,0cah,0a3h,0a3h,0cah,0c3h	; bcc5  ........
	defb 066h,066h,05fh,057h,057h,05fh,057h,057h	; bccd  ff_WW_WW
	defb 05fh,057h,057h,05fh,057h,05fh,057h,05fh	; bcd5  _WW_W_W_
	defb 057h,05fh,057h,05fh,05fh,057h,05fh,057h	; bcdd  W_W__W_W
	defb 05fh,057h,05fh,057h,05fh,057h,05fh,057h	; bce5  _W_W_W_W
	defb 016h,016h,016h,016h,016h,014h,014h,014h	; bced  ........

; ----------------------------------------------------------------------
; DATOS colores_tierra_sueltas: Los colores de las cosas sueltas (0x13-0x1A)
;   en la tierra
;   0xbcf5..0xbd35  (64 bytes)
DATA_colores_tierra_sueltas:
	defb 0c9h,079h,079h,047h,047h,079h,049h,0c9h	; bcf5  .yyGGyI.
	defb 0c9h,0c9h,079h,079h,047h,047h,049h,0c9h	; bcfd  ..yyGGI.
	defb 0c9h,0c9h,079h,079h,047h,049h,049h,0c9h	; bd05  ..yyGII.
	defb 0c9h,079h,079h,047h,079h,079h,049h,0c9h	; bd0d  .yyGyyI.
	defb 0c9h,0a9h,0a9h,0cah,0a9h,0c9h,0c9h,0c9h	; bd15  ........
	defb 0c9h,00ch,0c9h,0a9h,0cah,0c9h,0c9h,0c9h	; bd1d  ........
	defb 0c9h,0a9h,0c9h,099h,0a9h,0cah,0c9h,0c9h	; bd25  ........
	defb 0c9h,0c9h,0a9h,0cah,0a9h,0a9h,0cah,0c9h	; bd2d  ........

; ----------------------------------------------------------------------
; DATOS titulo: El titulo de la seleccion: CASIO y 大障害競馬 en letras grandes, 14
;   x 6 casillas
;   0xbd35..0xbd89  (84 bytes)
DATA_titulo:
	defb 020h,021h,023h,020h,025h,027h,020h,029h,02bh,02dh,02fh,021h,0f0h,020h	; bd35   !# %' )+-/!. 
	defb 020h,022h,024h,020h,026h,028h,020h,02ah,02ch,02eh,0efh,022h,0f1h,020h	; bd43   "$ &( *,..". 
	defb 020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h	; bd51                
	defb 060h,063h,020h,066h,069h,020h,06ch,06fh,020h,072h,075h,020h,078h,07bh	; bd5f  `c fi lo ru x{
	defb 061h,064h,020h,067h,06ah,020h,06dh,070h,020h,073h,076h,020h,079h,07ch	; bd6d  ad gj mp sv y|
	defb 062h,065h,020h,068h,06bh,020h,06eh,071h,020h,074h,077h,020h,07ah,07dh	; bd7b  be hk nq tw z}

; ----------------------------------------------------------------------
; DATOS musica_primera_b: La musica de la primera carrera, canal 1; grupos de
;   tres bytes (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbd89..0xbdcf  (70 bytes)
DATA_musica_primera_b:
	defb 0fah,0ffh,00ch	; bd89
	defb 0f9h,0ffh,011h	; bd8c
	defb 02bh,00ch,00ch	; bd8f
	defb 030h,00ch,00ch	; bd92
	defb 034h,00ch,00ch	; bd95
	defb 037h,00ch,00ch	; bd98
	defb 037h,024h,024h	; bd9b
	defb 034h,00ch,00ch	; bd9e
	defb 034h,024h,024h	; bda1
	defb 030h,012h,012h	; bda4
	defb 034h,012h,012h	; bda7
	defb 030h,00ch,00ch	; bdaa
	defb 02bh,00ch,00ch	; bdad
	defb 02bh,00ch,00ch	; bdb0
	defb 030h,00ch,00ch	; bdb3
	defb 034h,00ch,00ch	; bdb6
	defb 037h,00ch,00ch	; bdb9
	defb 037h,024h,024h	; bdbc
	defb 034h,018h,018h	; bdbf
	defb 030h,018h,018h	; bdc2
	defb 02bh,00ch,00ch	; bdc5
	defb 02bh,024h,024h	; bdc8
	defb 030h,030h,030h	; bdcb
	defb 0ffh	; bdce

; ----------------------------------------------------------------------
; DATOS fanfarria_a: La fanfarria de la salida, canal 0; grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbdcf..0xbe02  (51 bytes)
DATA_fanfarria_a:
	defb 0fah,000h,00ch	; bdcf
	defb 024h,009h,00ch	; bdd2
	defb 029h,009h,00ch	; bdd5
	defb 02dh,009h,00ch	; bdd8
	defb 030h,006h,00ch	; bddb
	defb 030h,005h,006h	; bdde
	defb 030h,005h,006h	; bde1
	defb 030h,005h,00ch	; bde4
	defb 030h,009h,00ch	; bde7
	defb 02dh,009h,00ch	; bdea
	defb 029h,009h,00ch	; bded
	defb 024h,005h,00ch	; bdf0
	defb 024h,005h,006h	; bdf3
	defb 024h,005h,006h	; bdf6
	defb 024h,005h,00ch	; bdf9
	defb 029h,024h,036h	; bdfc
	defb 0ffh,000h,000h	; bdff

; ----------------------------------------------------------------------
; DATOS fanfarria_b: La fanfarria de la salida, canal 1; grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbe02..0xbe33  (49 bytes)
DATA_fanfarria_b:
	defb 0fah,000h,00ch	; be02
	defb 030h,009h,00ch	; be05
	defb 035h,009h,00ch	; be08
	defb 039h,009h,00ch	; be0b
	defb 03ch,005h,00ch	; be0e
	defb 03ch,005h,006h	; be11
	defb 03ch,005h,006h	; be14
	defb 03ch,005h,00ch	; be17
	defb 03ch,009h,00ch	; be1a
	defb 039h,009h,00ch	; be1d
	defb 035h,009h,00ch	; be20
	defb 030h,005h,00ch	; be23
	defb 030h,005h,006h	; be26
	defb 030h,005h,006h	; be29
	defb 030h,005h,00ch	; be2c
	defb 035h,024h,036h	; be2f
	defb 0ffh	; be32

; ----------------------------------------------------------------------
; DATOS sonido_caida: La caida del jinete (canal 1); grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbe33..0xbe49  (22 bytes)
DATA_sonido_caida:
	defb 0fah,000h,00fh	; be33
	defb 0f9h,000h,011h	; be36
	defb 030h,003h,004h	; be39
	defb 02eh,003h,004h	; be3c
	defb 02ch,003h,004h	; be3f
	defb 02ah,003h,004h	; be42
	defb 028h,007h,009h	; be45
	defb 0ffh	; be48

; ----------------------------------------------------------------------
; DATOS sonido_cobra: Alguien cobra (canales 1 y 2); grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbe49..0xbe56  (13 bytes)
DATA_sonido_cobra:
	defb 0fah,000h,00fh	; be49
	defb 0fbh,000h,003h	; be4c
	defb 037h,001h,004h	; be4f
	defb 0fch,000h,000h	; be52
	defb 0ffh	; be55

; ----------------------------------------------------------------------
; DATOS musica_game_over_a: GAME OVER, canal 0; grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbe56..0xbe6c  (22 bytes)
DATA_musica_game_over_a:
	defb 0fah,000h,00ch	; be56
	defb 026h,005h,00ch	; be59
	defb 027h,005h,006h	; be5c
	defb 029h,005h,006h	; be5f
	defb 027h,009h,00ch	; be62
	defb 026h,009h,00ch	; be65
	defb 024h,012h,018h	; be68
	defb 0ffh	; be6b

; ----------------------------------------------------------------------
; DATOS musica_game_over_b: GAME OVER, canal 1; grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbe6c..0xbe7f  (19 bytes)
DATA_musica_game_over_b:
	defb 0fah,000h,00bh	; be6c
	defb 01ah,009h,00ch	; be6f
	defb 021h,009h,00ch	; be72
	defb 01ch,009h,00ch	; be75
	defb 01fh,009h,00ch	; be78
	defb 018h,012h,018h	; be7b
	defb 0ffh	; be7e

; ----------------------------------------------------------------------
; DATOS musica_carrera: La carrera, canal 0: sus cinco primeras notas y la
;   salida (0xBE8E); grupos de tres bytes (nota, duracion, espera) u ordenes
;   (0xF4-0xFF)
;   0xbe7f..0xbe8e  (15 bytes)
DATA_musica_carrera:
	defb 0fah,000h,00eh	; be7f
	defb 00ch,001h,00ch	; be82
	defb 013h,001h,006h	; be85
	defb 013h,001h,006h	; be88
	defb 0fdh,000h,000h	; be8b

; ----------------------------------------------------------------------
; DATOS sonido_salida: La salida (canal 2): el final de la musica de la
;   carrera; grupos de tres bytes (nota, duracion, espera) u ordenes
;   (0xF4-0xFF)
;   0xbe8e..0xbea1  (19 bytes)
DATA_sonido_salida:
	defb 0f6h,000h,000h	; be8e
	defb 0f9h,000h,011h	; be91
	defb 0f5h,000h,01eh	; be94
	defb 000h,003h,004h	; be97
	defb 0f5h,000h,01eh	; be9a
	defb 000h,012h,018h	; be9d
	defb 0ffh	; bea0

; ----------------------------------------------------------------------
; DATOS sonido_salto: El salto (canal 2); grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbea1..0xbec9  (40 bytes)
DATA_sonido_salto:
	defb 0f6h,000h,008h	; bea1
	defb 0fah,000h,00ch	; bea4
	defb 024h,003h,003h	; bea7
	defb 025h,002h,002h	; beaa
	defb 026h,001h,001h	; bead
	defb 027h,001h,001h	; beb0
	defb 028h,001h,001h	; beb3
	defb 029h,001h,001h	; beb6
	defb 02ah,001h,001h	; beb9
	defb 02bh,001h,001h	; bebc
	defb 02ch,001h,001h	; bebf
	defb 02dh,001h,001h	; bec2
	defb 02eh,001h,001h	; bec5
	defb 0ffh	; bec8

; ----------------------------------------------------------------------
; DATOS sonido_latigo: El latigo (canal 1); grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbec9..0xbedc  (19 bytes)
DATA_sonido_latigo:
	defb 0fah,000h,00fh	; bec9
	defb 0f6h,000h,001h	; becc
	defb 0f9h,000h,011h	; becf
	defb 0f5h,000h,000h	; bed2
	defb 000h,007h,009h	; bed5
	defb 0f6h,000h,008h	; bed8
	defb 0ffh	; bedb

; ----------------------------------------------------------------------
; DATOS musica_fin_a: Las nueve carreras hechas (RACE END), canal 0; grupos de
;   tres bytes (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbedc..0xbf07  (43 bytes)
DATA_musica_fin_a:
	defb 0fah,000h,00ch	; bedc
	defb 028h,007h,009h	; bedf
	defb 028h,007h,009h	; bee2
	defb 02bh,007h,009h	; bee5
	defb 02bh,007h,009h	; bee8
	defb 02dh,007h,009h	; beeb
	defb 02dh,007h,009h	; beee
	defb 02bh,007h,009h	; bef1
	defb 02bh,007h,009h	; bef4
	defb 02dh,007h,009h	; bef7
	defb 02dh,007h,009h	; befa
	defb 02bh,007h,009h	; befd
	defb 02dh,007h,009h	; bf00
	defb 030h,036h,048h	; bf03
	defb 0ffh	; bf06

; ----------------------------------------------------------------------
; DATOS musica_fin_b: RACE END, canal 1; grupos de tres bytes (nota, duracion,
;   espera) u ordenes (0xF4-0xFF)
;   0xbf07..0xbf32  (43 bytes)
DATA_musica_fin_b:
	defb 0fah,000h,00bh	; bf07
	defb 018h,007h,009h	; bf0a
	defb 01fh,007h,009h	; bf0d
	defb 01ch,007h,009h	; bf10
	defb 01fh,007h,009h	; bf13
	defb 01ah,007h,009h	; bf16
	defb 021h,007h,009h	; bf19
	defb 01dh,007h,009h	; bf1c
	defb 021h,007h,009h	; bf1f
	defb 018h,007h,009h	; bf22
	defb 01fh,007h,009h	; bf25
	defb 01ch,007h,009h	; bf28
	defb 01fh,007h,009h	; bf2b
	defb 018h,036h,048h	; bf2e
	defb 0ffh	; bf31

; ----------------------------------------------------------------------
; DATOS musica_premio_a: El premio del jinete (primero o segundo), canal 1;
;   grupos de tres bytes (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf32..0xbf54  (34 bytes)
DATA_musica_premio_a:
	defb 0f9h,000h,011h	; bf32
	defb 028h,00eh,012h	; bf35
	defb 028h,007h,009h	; bf38
	defb 029h,007h,009h	; bf3b
	defb 02bh,00eh,012h	; bf3e
	defb 02bh,007h,009h	; bf41
	defb 029h,007h,009h	; bf44
	defb 028h,00eh,012h	; bf47
	defb 028h,007h,009h	; bf4a
	defb 029h,007h,009h	; bf4d
	defb 02bh,029h,036h	; bf50
	defb 0ffh	; bf53

; ----------------------------------------------------------------------
; DATOS musica_premio_b: El premio del jinete, canal 2; grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf54..0xbf76  (34 bytes)
DATA_musica_premio_b:
	defb 0f9h,000h,011h	; bf54
	defb 024h,00eh,012h	; bf57
	defb 024h,007h,009h	; bf5a
	defb 024h,007h,009h	; bf5d
	defb 024h,00eh,012h	; bf60
	defb 024h,007h,009h	; bf63
	defb 024h,007h,009h	; bf66
	defb 024h,00eh,012h	; bf69
	defb 024h,007h,009h	; bf6c
	defb 024h,007h,009h	; bf6f
	defb 024h,029h,036h	; bf72
	defb 0ffh	; bf75

; ----------------------------------------------------------------------
; DATOS sonido_golpe: El golpe con algo suelto (canal 1); grupos de tres bytes
;   (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf76..0xbf7d  (7 bytes)
DATA_sonido_golpe:
	defb 013h,004h,006h	; bf76
	defb 013h,00eh,012h	; bf79
	defb 0ffh	; bf7c

; ----------------------------------------------------------------------
; DATOS musica_llegada_a: La llegada, canal 0; grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf7d..0xbf8a  (13 bytes)
DATA_musica_llegada_a:
	defb 0fah,000h,00ch	; bf7d
	defb 02bh,007h,012h	; bf80
	defb 030h,007h,009h	; bf83
	defb 037h,024h,036h	; bf86
	defb 0ffh	; bf89

; ----------------------------------------------------------------------
; DATOS musica_llegada_b: La llegada, canal 1; grupos de tres bytes (nota,
;   duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf8a..0xbf97  (13 bytes)
DATA_musica_llegada_b:
	defb 0fah,000h,00ch	; bf8a
	defb 030h,007h,012h	; bf8d
	defb 034h,007h,009h	; bf90
	defb 03ch,024h,036h	; bf93
	defb 0ffh	; bf96

; ----------------------------------------------------------------------
; DATOS musica_campeon_a: El primero en la carrera 9, canal 1; grupos de tres
;   bytes (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbf97..0xbfb9  (34 bytes)
DATA_musica_campeon_a:
	defb 0fah,000h,00bh	; bf97
	defb 0f9h,000h,011h	; bf9a
	defb 034h,012h,012h	; bf9d
	defb 030h,006h,006h	; bfa0
	defb 034h,006h,006h	; bfa3
	defb 037h,006h,006h	; bfa6
	defb 039h,012h,012h	; bfa9
	defb 034h,006h,006h	; bfac
	defb 037h,006h,006h	; bfaf
	defb 03bh,006h,006h	; bfb2
	defb 03ch,036h,036h	; bfb5
	defb 0ffh	; bfb8

; ----------------------------------------------------------------------
; DATOS musica_campeon_b: El primero en la carrera 9, canal 2; grupos de tres
;   bytes (nota, duracion, espera) u ordenes (0xF4-0xFF)
;   0xbfb9..0xbfdd  (36 bytes)
DATA_musica_campeon_b:
	defb 0fah,000h,00ah	; bfb9
	defb 0f9h,000h,011h	; bfbc
	defb 030h,012h,012h	; bfbf
	defb 02bh,006h,006h	; bfc2
	defb 030h,006h,006h	; bfc5
	defb 032h,006h,006h	; bfc8
	defb 035h,012h,012h	; bfcb
	defb 030h,006h,006h	; bfce
	defb 034h,006h,006h	; bfd1
	defb 037h,006h,006h	; bfd4
	defb 037h,036h,036h	; bfd7
	defb 0ffh,000h,000h	; bfda

; ----------------------------------------------------------------------
; DATOS relleno: El final de la ROM, a 0xFF
;   0xbfdd..0xc000  (35 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfdd  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfed  ................
	defb 0ffh,0ffh,0ffh	; bffd
