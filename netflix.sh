#!/bin/bash
#Autores: Aldo Sivila y Arnau Raich
FILE=netflix.csv


# Ensure we are running under bash
if [ "$BASH_SOURCE" = "" ]; then
    /bin/bash "$0"
    exit 0
fi

. "bash-menu.sh"



#Funcion para añadir nueva pelicula temporalmente
function NuevaPelicula () {

	res=1
	while [ $res -eq "1" ]; do

        	mktemp netflix_temp.XXX

        	echo "Escribe los campos de la película: "
       		echo "Nombre: "
        	read name
        	echo "Rating: "
        	read rating
        	echo "Descripción del rating: "
        	read desc_rating
        	echo "Nivel del rating: "
        	read rating_lvl
        	echo "Año: "
        	read year
        	echo "Rating del usuario: "
        	read rating_user
        	echo "User rating size: "
        	read rating_size

        	echo $name", "$rating", "$desc_rating", "$rating_lvl", "$year", "$rating_user", "$rating_size >> netflix_temp.XXX
		echo "Quiere añadir una nueva película?(1/-)"
		read res
	done


	cat netflix_temp.XXX  >> netflix.csv
	rm -f netflix_temp.* 
	return 1

}

#Actualiza los datos del archivo netflix.csv al abrir el programa
function sincronizacion {
        wget -O netflixActualizado.csv https://raw.githubusercontent.com/acocauab/practica2csv/master/netflix.csv
        Dif=`diff netflixActualizado.csv netflix.csv | wc -l`
	if [ $Dif -eq 0 ] 
	then
		echo "Actualitzado"
		sleep 5
	else
		cat netflixActualizado.csv > netflix.csv
		echo "Actualizando"
		sleep 5
	fi
	rm netflixActualizado.csv
        clear

}

#Mensaje de aviso que se está volviendo al menú
function volverAlMenu {
	clear
	echo "volviendo al menu"
}

#Muestra el menú que hay dentro de la función 4
function menuBorrar {

        echo "1.Si, quiero borrarlos de la bdd"
        echo "2.Volver al menu"

}

#Si elige borrarlos, con awk compararemos las coincidencias con la bdd y de aqui obtendremos un fichero con la bdd sin las coincidencias
#y este se sustituirá con la bdd original para eliminar las coincidencias y finalmente se borrarán los archivos temporeales creados.
function borrar {
	clear
        echo "Seguro que quieres continuar con el borrado? s/n"
        read respuesta
        if [ "$respuesta"=="s" ];
	then

	awk 'BEGIN { while ( getline < "temp_coincidencias.txt" ) { arr[$0]++ } } { if (!( $0 in arr ) ) { print } }' netflix.csv | sort -u > netflix_borrado.csv
	cat netflix_borrado.csv > netflix.csv
	rm netflix_borrado.csv temp_coincidencias.txt

	fi
	
}

#El usuario pasará un parámetro y este buscara en la bdd los titulos que coincidan,los mostrará y nos preguntará si queremos eliminarlos de la bdd
#Podremos elegir entre borrar o volver al menú principal
function funcion4 (){
	echo "Borrarás las peliculas que coincidan segun lo que introduzcas"
	echo "Introduce una cadena de caracteres:"
	read titulo

	#coincidencias
	awk '{FS=","}
        	{if($1 ~ /'$titulo'/)
                	print $0
        	}' $FILE | sort -u > temp_coincidencias.txt
	clear

	echo "Estas son las coincidencias"
	cut -f1 -d"," temp_coincidencias.txt
	read wait
	clear


	while [ "$respuesta" != 2 ]
	do
	clear
	menuBorrar;

	read respuesta


	case $respuesta in

		1) borrar;;
		2) volverAlMenu;;
		*)opcionInvalida;;

	esac
	rm temp_coincidencias.txt
	done
	return 1
}

#Obtiene los años de las peliculas de la bdd y crea un directorio con el año si no existe,
#Y después en cada directorio crea un fichero si no existe, donde se ubicarán las peliculas del año de aquel directorio.
function funcion2 () {
	DirYears=`awk '{FS=","}
                {
                    print $5
                }' $FILE | sort -u`

	for directorio in $DirYears
	do
		if [ -d $directorio ];
		then
		echo "ya existe el direcotorio "$directorio
		else

		echo `mkdir $directorio`

		fi
	done

	for year in $DirYears
	do
		if [ -f ./$year/$year"-netflix.csv" ];
		then
		echo "ya existe el archivo " $year"-netflix.csv"
		else

		echo touch `./$year/$year"-netflix.csv"`

		fi

	awk '{FS=","}
                {if('$year'==$5)
		print $0
                }' $FILE| sort -u >> $year/$year"-netflix.csv"

	done
	return 1

}



#Muetra el menu principal
menu=(
 	echo "1.Recomendación rápida."
 	echo "2.Listar per año."
 	echo "3.Listar por rating."
	echo "4.Nueva Pelicula."
	echo "5.Crear directorios y fichero filtrado por años"
 	echo "6.Eliminar peliculas de la BDD"
	echo "7.Salir"
	)

#Muestra el titulo, año, rating y descripcion de una pelicula/serie aleatoria
function opcion1 () {
	clear;

 	echo "---------------------------------"
 	echo " Recomendación rápida"
 	echo "---------------------------------"

	lineFile=`tail +1 netflix.csv| wc -l`

	randomNumber=$[ ( $RANDOM % $lineFile ) + 2 ]

	awk ' BEGIN {FS=","};
		{if(NR=='$randomNumber')
        		print "Titulo : "$1 " , Año: "$5"\nRating: "$2"\nDescripción: "$3
		}' $FILE

 	read wait
	return 1

}

#Muestra  todas las peliculas/series que coincidan con el año que el usuario haya introducido
function opcion2 () {
	echo `clear`
	echo "----------------------------------------"
	echo "Introduce el año de la serie o pelicula:"
	echo "----------------------------------------"
	year=0;
	read year;
	clear;

	echo "Listado por AÑO:"
	awk '{FS=","}
        	{if($5=='$year')
                	print "Titulo : "$1 " , Rating: "$2
        	}' $FILE | sort -u

	read wait
	return 1

}

#Muestra todas las peliculas/series que coincidan con el rating que el usuario haya introducido(1-5)
#Cambia la nota de la serie por un rating con asteriscos
function opcion3 () {

	echo "Introduce el numero entre 1 y el 5";

	read case
	clear
	echo "Listado por rating: "
	case $case in
		1) star1; star2; star3; star4; star5;;
		2) star2; star3; star4; star5;;
		3) star3; star4; star5;;
		4) star4; star5;;
		5) star5;;
		*) opcionInvalida;;
	esac
	read wait
	return 1
}

#Filtra por rangos de rating y los sustituye por estrellas(star1,start2,star3,star4,star5)
function star1 {
	awk '{FS=","};
		{if($6<65 && $6>0)
			print "[     *     ] , "$1" , año; " $5
		}' $FILE | sort -u
}

function star2 {
        awk '{FS=","};
                {if($6<75 && $6>65)
                        print "[    * *    ] , "$1" , año; " $5
                }' $FILE | sort -u
}

function star3 {
        awk '{FS=","};
                {if($6<85 && $6>75)
                        print "[   * * *   ] , "$1" , año; " $5
                }' $FILE | sort -u
}

function star4 {
        awk '{FS=","};
                {if($6<95 && $6>85)
                        print "[  * * * *  ] , "$1" , año; " $5
                }' $FILE | sort -u
}

function star5 {
        awk '{FS=","};
                {if($6>95)
                        print "[ * * * * * ] , "$1" , año; " $5
                }' $FILE | sort -u
}




#Muestra un mensaje al salir del script
function salirPrograma {
 	echo `clear`
 	echo "Has salido del menú"
 	read wait
	return 0
}

#Muestra un mensaje de error, quando no se introduzca una opcion existente
function opcionInvalida {
  	echo `clear`
  	echo "No existe esa opción"
  	sleep 3
}


#Inicio del Script
#Lo primero que hace es sincronizar para actualizar la bdd
sincronizacion
#Bucle del menu principal  donde el usuario elige las opciones que quiera, hasta que eliga la opcion salir
case=1

menuItems=(
 	"1.Recomendación rápida."
 	"2.Listar per año."
 	"3.Listar por rating."
	"4.Nueva Pelicula."
	"5.Crear directorios y fichero filtrado por años"
 	"6.Eliminar peliculas de la BDD"
	"7.Salir"
	)

menuActions=(
	opcion1
	opcion2
	opcion3
	NuevaPelicula
	funcion2
	funcion4
	salirPrograma
	)


menuTitle=" Menú Neflix "
menuFooter="Enter=Seleccionar,Navegar con Arriba/Abajo o intruduce el número de la opción"
menuWidth=70
menuLeft=10
menuHighlight=$DRAW_COL_GREEN

menuInit
menuLoop


exit 0



