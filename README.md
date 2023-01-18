# FB_THOMSON_M05_M6809
Freebasic Emulador de Thomson M05 con CPU Motorola 6809

El emulador del 6809 está al 99% de su finalizacion.
Basado en el emulador DCMOTO en su versión de 2009

El Emulador del Thomson Mo9 está en "pañales":
No emula el sonido, y eso hace que en algunos juegos, parezca que no
ocurre nada, cuando en realidad está sonando una música.
El teclado tiene pequeños fallos de emulación, pero hace su función
Algunas teclas, no he sido capaz de mapearlas bien, y han quedado en el 
mismo sitio que el Mo5 original, como el "=", que está sobre el "-"

La tecla de PC "\" hace la función de tecla "STOP" en el Mo5, y hace un "reset"
caliente (no borra la ram , sólo para la ejecución y vuelve al Basic)

Para cargar una cinta o un cartucho (extensiones K7 o M5), pulsamos "F4"
y elegimos ahí. Si es una cinta, previamente escribiremos RUN "" o LOAD
y pulsamos INTRO, entonces, F4, y elegimos la cinta.

Algunos juegos K7 no cargan , pero me he fijado, que le ocurre lo mismo
al emulador original, o sea, que no parece ser fallo de mi emulador

La tecla de "borrado" o "backspace", no funciona , y desconozco el porqué.
Para borrar, podemos retroceder con el cursor y escribir encima
o retroceder y pulsar "DEL" o "SUPR" que si funciona
(de todos modos, he visto un emulador al que le ocurre lo mismo)

Para escribir comandos Basic, podeis mirar un teclado Mo5 real, y fijaros
donde va cada comando Basic, y emplear la tecla "SHIFT derecho", más la
tecla del Basic.

Es capaz de grabar programas Basic en una cinta llamada "SaveMo5.k7"
En el Mo5 ponemos el nombre que queramos.
por ejemplo: SAVE "2" , y el PC lo recibe como "SaveMo5.k7"
Si el archivo ya existe, lo sobreescribe, asi que, cuidado con esto.

El emulador no tiene control de la CPU del PC (por ahora), y eso significa
que en algunos PC irá lento, y en otros rápido.
En el mio va al 100% de su velocidad real, y es un Dual Core 2.6 (año 2011)

Para jugarlo, necesitas la BIOS "Mo5.ROM" en la misma carpeta del emul
y juegos extension K7, y te recomiendo ver el Asterix, que funciona con teclas.
Al cargarlo, elegimos la opcion "1 Clavier".
Los cartuchos son extensión M5, de tamaño 16k. Los de 32k fallan algunos.

Dejo dos ficheros PD (Public Domain) como ejemplo: una cinta K7 y un cartucho M5
