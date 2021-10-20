# Utilisation

Le script **lanceur.exe** lance une appli situé dans un sous-dossier **data**.
Il doit être renommé du même nom que l'executable a lancer.

Par exemple **\\srv-app\applications\Maths\Python\pyzo.exe** va rechercher:

- \\srv-app\applications\Maths\Python\data\pyzo.exe
- \\srv-app\applications\Maths\data\pyzo.exe
- \\srv-app\applications\data\pyzo.exe

L'appli peut être
- un package thinapp	(extension .exe)
- un script batch		(extension .bat, renommer le lanceur en .bat fonctionne)
- un exe portable		(extension .exe)
- une archive			(extension .zst, installer 7z-zstd)

# Fonctionnement

Si un thinapp est lancé, le script verifie et tue le processus s'il affiche un message d'erreur. 

Le script envoie un ping anonyme vers une base de donnée afin de créer des stats d'utilisation.
Elle est hébergée sur le serveur qoqcot a cette adresse : http://10.100.0.0/thinapp/

# Configuration par un fichier .ini
 
Un fichier .ini placé avec l'appli dans le dossier data peut configurer le fonctionnement du script (nommé par exemple pyzo.exe.ini) :

[Lanceur]
; ----- désactive la detection d'erreur thinapp ----
  NePasAfficherQuestionAppPlantee = True
  NePasSupprimerAppdataThinapp = False
; ----- dans le cas d'une archive, fichier a executer apres extraction ----
  CheminDExtraction = C:\ProgramData\AppsPortable
  SousDossier = Python38
  ProgrammeAExecuter = startpy.bat
; ----- dans le cas d'une archive, force l'extraction si nouvelle version ----
  VersionArchive = 1
; ----- dans le cas d'une archive, comportement de la barre de progression ----
  PasDeMessageProgression = False
  TitreProgression = Veuillez patientez...
  RemplacerMessages = une dizaine de messages, separés par des #
  
# Préparation d'une archive

L'archive est cree avec le format zstandard (semble le plus rapide sur un lien réseau) avec cette commande:

	7za.exe a -m0=zstd -mx1 AppliPortable.zst c:\Appli
  
Le programme **7za.exe** doit etre copié avec l'appli dans le dossier data.

Sans changement via le fichier ini, le script lancera apres decompression : 

	C:\ProgramData\AppsPortable\Appli\start.bat