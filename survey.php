<?php

// ouverture de la base
$db = new SQLite3('ThinAppUsage.sqlite');

// cf2020-11 ajoute un timeout pour permettre plus d'acces/ecriture simultanés
$db->busyTimeout(20000);
// creer la table si besoin...
$sql = "CREATE TABLE IF NOT EXISTS ThinAppUsage ( AppID INTEGER PRIMARY KEY,AppName TEXT NOT NULL, UserHash TEXT NOT NULL, Computer TEXT NOT NULL, DateStart INTEGER);";
$query = $db->exec( $sql );
if (!$query) {
	echo($sql);
        exit("Erreur dans requete de creation: ".$db->lastErrorMsg());
}

// préparation des données
If ( Isset( $_GET['App'] )) {
	$AppName	= htmlspecialchars( $_GET['App'] );
	$AppName	= $db->escapeString( $AppName );
} else {
	Die( 'nom de l\'application manquante.' );
}

If ( Isset( $_GET['Id'] )) {
//echo substr('testabc@toto', 0, strpos('testabc@toto', '@'));
	$UserHash	= hash( 'crc32b', substr( $_GET['Id'], 0, strpos( $_GET['Id'], '@' ))) ;
	$UserHash	= $db->escapeString( $UserHash );
	$Computer	= htmlspecialchars( substr( $_GET['Id'], strpos( $_GET['Id'], '@' )+1)) ;
	$Computer	= $db->escapeString( $Computer );
} else {
	Die( 'Identifiant manquant.' );
}

// enregistrement de l'event.
$sql = "INSERT INTO ThinAppUsage (AppName, UserHash, Computer, DateStart) VALUES ('$AppName', '$UserHash', '$Computer', ". time() .");";

$query = $db->exec( $sql );

if (!$query) {
	exit("Erreur dans la requête insert : ". $db->lastErrorMsg());
} else {
	// renvoi un pixel vide
	$pixel = 'pixel.gif';

	if ( file_exists( $pixel )) {
		header( "Content-Type: image/gif");
		header( 'Content-Length: ' . filesize( $pixel ));
		readfile( $pixel );
	} else {
		header($_SERVER["SERVER_PROTOCOL"] . " 404 Not Found");
	}
}

