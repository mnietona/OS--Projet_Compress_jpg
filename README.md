# Outil de Compression d'Images

Ce script est un utilitaire pour la compression d'images JPEG en utilisant diverses optimisations. Il prend en charge le traitement par lots, le parcours récursif des dossiers, et les résolutions de sortie personnalisées.

## Prérequis

Avant d'utiliser le script, vous devez installer ImageMagick, une suite logicielle pour la manipulation d'images.

### Installation d'ImageMagick

#### Sur Linux (Ubuntu/Debian)

Ouvrez un terminal et exécutez les commandes suivantes :

```bash
sudo apt-get update
sudo apt-get install imagemagick
```

#### Sur macOS

Si vous avez Homebrew installé, exécutez :

```bash
brew install imagemagick
```

### Vérification de l'installation

Pour vérifier que ImageMagick est correctement installé, vous pouvez exécuter :

```bash
convert -version
```

Cela devrait afficher la version d'ImageMagick installée sur votre système.

## Comment Utiliser

Pour compresser une image ou un dossier d'images, exécutez le script avec les options souhaitées :

```bash
./compress_script.sh [options] resolution [nom_fichier_ou_dossier]
```

Les options incluent `-c` pour supprimer les métadonnées, `-r` pour le traitement récursif des dossiers, et `-e` pour changer l'extension de sortie. Consultez l'aide du script pour plus de détails :

```bash
./compress_script.sh --help
```

N'oubliez pas de rendre le script exécutable avec `chmod +x compress_script.sh` avant de l'exécuter.
