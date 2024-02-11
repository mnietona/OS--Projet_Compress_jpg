#! /bin/bash


# Parameters for convert
READ_PARAMETERS='-auto-orient -colorspace RGB'
WRITE_PARAMETERS='-quality 85% -colorspace sRGB -interlace Plane -define jpeg:dct-method=float -sampling-factor 4:2:0'

# Return values
BAD_USAGE=1
CONVERT_ERR=2
NO_EXIST=3

# Formatted usage messages
SHORT_USAGE="\e[1mUSAGE\e[0m
    \e[1m${0}\e[0m [\e[1m-c\e[0m] [\e[1m-r\e[0m] [\e[1m-e\e[0m \e[4mextension\e[0m] \e[4mresolution\e[0m [\e[4mfilename_or_directory\e[0m]
or
    \e[1m${0} --help\e[0m
for detailed help."

USAGE="$SHORT_USAGE

The order of the options does not matter. However, if \e[4mfilename_or_directory\e[0m is given and is a number, it must appear after \e[4mresolution\e[0m.

  \e[1m-c\e[0m, \e[1m--strip\e[0m
    Compress more by removing metadata from the file.

  \e[1m-r\e[0m, \e[1m--recursive\e[0m
    If \e[4mfilename_or_directory\e[0m is a directory, recursively compress JPEG in subdirectories.
    Has no effect if \e[4mfilename_or_directory\e[0m is a regular file.
    This option has the same effect when file and directories are given on stdin.

  \e[1m-e\e[0m \e[4mextension\e[0m, \e[1m--ext\e[0m \e[4mextension\e[0m
    Change the extension of processed files to \e[4mextension\e[0m, even if the compression fails or does not actually happen.
    Renaming does not take place if it gives a filename that already exists, nor if the file being processed is not a JPEG file.

  \e[4mresolution\e[0m
    A number indicating the size in pixels of the smallest side.
    Smaller images will not be enlarged, but they will still be potentially compressed.

  \e[4mfilename_or_directory\e[0m
    If a filename is given, the file is compressed. If a directory is given, all the JPEG files in it are compressed.
    Can't begins with a dash (-).
    If it is not given at all, ${0} process files and directories whose name are given on stdin, one by line.

\e[1mDESCRIPTION\e[0m
    Compress the given picture or the jpeg located in the given directory. If none is given, read filenames from stdin, one by line.

\e[1mCOMPRESSION\e[0m
    The file written is a JPEG with quality of 85% and chroma halved. This is a lossy compression to reduce file size. However, it is calculated with precision (so it is not suitable for creating thumbnail collections of large images). The steps of the compression are:

      1. The entire file is read in.
      2. Its color space is converted to a linear space (RGB). This avoids a color shift usually seen when resizing images. 
      3. If the smallest side of the image is larger than the given resolution (in pixels), the image is resized so that this side has this size. 
      4. The image is converted (back) to the standard sRGB color space.
      5. The image is converted to the frequency domain according to the JPEG algorithm using an accurate Discrete Cosine Transform (DCT is calculated with the float method) and encoded in JPEG 85% quality, chroma halved. (The JPEG produced is progressive: the loading is done on the whole image by improving the quality gradually)." 

# Fonctions 


function print_without_formatting () {
    # Output the value of "$1" without formatting
    echo "$1" | sed 's/\\e\[[0-9;]\+m//g'
}


function is_jpeg () {
    # si filename est image/jpeg alors renvoi vrai sinon faux
    # recois lenom du fichier
    # revois ''0'' si le fichier est un jpeg

    if [ "$(file -i "$1")"  == "$1: image/jpeg; charset=binary" ]; then 
       return 0
    else
       return 1
    fi
}


function normalize  () {
        # Cree new_file si extention possible
        # recois l'extention et le fichier
        
        list_extention=( "jpg" "jpeg" "jpe" "jif" "jfif" "jfi" "JPG" "JPEG" "JPE" "JIF" "JFIF" "JFI" ) 
        var=false
        is_jpeg $2
        if [ "$?" == "0" ] ; then 
            for item in "${list_extention[@]}"
            do
              if [ "$1" == "$item" ] ; then
                 IFS='.' read -r -a array <<< "$2"
                 new_file="${array[0]}.$1"
                 var=true
                 break
               fi
            done
            if [ "$var" == "false" ] ; then 
               print_without_formatting "-e argument must be one of jpg, jpeg,  jpe, jif, jfif, jfi (or uppercase version of one)"
               print_without_formatting "$SHORT_USAGE"
               exit $BAD_USAGE
            fi
       else 
           new_file=$2
       fi

}


function arguments  () { 
       # donne au variable leur valeur 
       # recois tout les arguments 

       for x in $@ ; do tab+=($x) ; done
       END=${#tab[@]} 
       END=$(($END - 1))
      
       for i in $(seq 0 $END); do 

           if [ "$(echo ${tab[$i]} | grep "^[ [:digit:] ]*$")" -a "$resolution" == "false" ]; then
              resolution=${tab[$i]}
           elif [ "${tab[$i]}" == "-c" -o "${tab[$i]}" == "--strip" ]; then
              strip=true
           elif [ "${tab[$i]}" == "-e" -o "${tab[$i]}" == "--ext" ]; then
               extention=${tab[$i+1]}
               unset tab[$i+1]
           elif [ "${tab[$i]}" == "-r" -o "${tab[$i]}" == "--recursive" ]; then
               recursive=true
           elif [ "${tab[$i]}" == "help" -o "${tab[$i]}" == "-h" -o "${tab[$i]}" == "--help" ]; then
               print_without_formatting "$USAGE"
               exit 0
           elif [ "${tab[$i]}" == "" ]; then
              :
           else
              filename=${tab[$i]}
           fi
       done
}


function verif_size () { 
      # surpime le fichier qui prend le plus de place
      # recois filename et new_file
      
      size "$1" "$2"
      if [ "$?" == "0" ]; then
          rm $1
          print_without_formatting "$new_file"
      else
          rm $2
          print_without_formatting "$filename"
          print_without_formatting "Not compressed. File left untouched. (normal)"
      fi
      
}

function size  () { 
      # verifie la taille des fichier
      # recois filename et new_file
      # renvoi ''0'' si nouveau fichier <= à l'ancien
      
      size_file=$(stat --format=%s "$1")
      size_new_file=$(stat --format=%s "$2")
      if (( $size_file >= $size_new_file)); then 
             return 0
         else
            return 1
         fi
      
}

function verif_extention () { 
      # verifi si l'utilisateur demande une extention
      # Recois filename ,extention et strip
      
      if [ $2 != "false" ]; then
          normalize "$2" "$1"
          convertion "$3" "$1" "$new_file"
      else
          new_file=$1
          convertion "$3" "$1" "$new_file"
      fi 

}

function convertion () {
   # Fait la convertion du fichier en appelant CONVERT
   # Recois strip , filename, new_file
   
   if [ $2 != $3 ]; then
      if [ $1 == "false" ]; then
         convert $READ_PARAMETERS $2 -resize $resolutionx$resolution^ $WRITE_PARAMETERS $3
         verif_size "$2" "$3"  
      else
         convert $READ_PARAMETERS $2 -resize $resolutionx$resolution^>-strip $WRITE_PARAMETERS $3
         verif_size "$2" "$3"
      fi
   else  
       apres_point="${2##*.}"
       convert $READ_PARAMETERS $2 -resize $resolutionx$resolution^ $WRITE_PARAMETERS verification_taille_12.$apres_point
       size "$2" "verification_taille_12.$apres_point"
       
       if [ "$?" == "0" ]; then
          rm verification_taille_12.$apres_point
          if [ $1 == "false" ]; then
             convert $READ_PARAMETERS $2 -resize $resolutionx$resolution^ $WRITE_PARAMETERS $3
          else 
             convert $READ_PARAMETERS $2 -resize $resolutionx$resolution^>-strip $WRITE_PARAMETERS $3
          fi 
          print_without_formatting "$new_file"
      else
          rm verification_taille_12.$apres_point
          print_without_formatting "$2"
          print_without_formatting "Not compressed. File left untouched. (normal)"
      fi
   fi
}



function for_file () {
     # verifie que le fichier est bien une image 
     # recois filename
     
     if [ "$(file -b $1 | cut -d' ' -f2)" == "image" ]; then
        verif_extention "$1" "$extention" "strip"
        
     else
        print_without_formatting "$1"
        convert $READ_PARAMETERS $1 -resize $resolutionx$resolution^ $WRITE_PARAMETERS $1
        print_without_formatting "Error while compressing $1. File left untouched."
        erreur=true
     fi
}

function for_dossier () {
       # parcourt le dossier et appel for_file sur les images
       # recois filename

      directory=$1
      for i in $(ls $1); do
          filename=$directory/$i
          
          if [ "$(file -i "$filename")" == "$filename: inode/directory; charset=binary" ]; then 
             
             if [ "$recursive" == "true" ]; then
                sub_directory=$filename
                for_dossier "$sub_directory"     
                         
             else
                 :
             fi
             # permet de revenir au chemin du dossier précédent 
             directory=$1
          else
             for_file "$filename"
          fi
      done
        
}

# Variables

strip=false
recursive=false
extention=false
resolution=false
filename=false
erreur=false

# code

arguments $@

# verifie que resolution a été donné
if [ "$resolution" == "false" ]; then 
   print_without_formatting "Missing resolution."
   print_without_formatting "$SHORT_USAGE"
   exit $BAD_USAG
   fi

# attend l'entre dufichiers depuis le stdin
if [ "$filename" == "false" ]; then
   read filename
fi

# verifie que le fichier ne commence pas pas un "-"
if [ "${filename:0:1}" == "-" ]; then
   print_without_formatting "Do not use '-' as a first character of the filename."
   print_without_formatting "$SHORT_USAGE"
   exit $BAD_USAG
fi

# verifie si le fichier existe 
if [ -f "$filename" -o -d "$filename" ]; then 
   dossier="$(file -i "$filename")" 
   
   # verifie que fichier est un dossier 
   if [ "$dossier" == "$filename: inode/directory; charset=binary" ]; then
      for_dossier "$filename"
    
   else
       for_file "$filename"

   fi

else 
    print_without_formatting "$filename doesn't exist"
    exit $NO_EXIST

fi

if [ "$erreur" == "true" ]; then
   exit $CONVERT_ERR
fi




