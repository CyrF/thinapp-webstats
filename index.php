<?php 
$pg = '';
if (isset( $_GET['page'] )) {
	$pg = $_GET['page'];
}
$datapoints = array(); // variables pour le script js

include( 'inc/page-header.html' );
include( 'inc/page-navigation.html' );
if ( $pg != '' ) {
	$Titles = array(
		"app" => "Statistiques par applications",
		"detail" => "Détail de l'application",
		"salle" => "Statistiques par salles"
	);	
	if (isset( $_GET['name'] )) {
		$Titles[$pg] .= " " . base64_decode_url($_GET['name']);
	}
	$SubTitles = array(
		"app" => "",
		"salle" => ""
	);
	if ( isset($Titles[$pg]) ) {
	?>
	<br>
      <h2><?php echo $Titles[$pg]; ?></h2>
	  <div class="media text-muted pt-3">
      <p class="media-body pb-3 mb-0 small lh-125 border-bottom border-gray">
        <?php echo $SubTitles[$pg]; ?>
      </p>
    </div>
	  
      <div class="table-responsive">
	  <?php 
// ouverture de la base
$db = new SQLite3('ThinAppUsage.sqlite');
//$db->query('ATTACH "ThinAppUsage2019-2020.sqlite AS AnneePassee;');

echo '<table class="table table-striped table-sm">';
switch ($pg) {
	case "app":
		if ( isset( $_GET['name'] )) {
			echo "<thead><tr><th>Salle</th><th>Nbre d'éxécution</th></tr></thead><tbody>";
			// Affichage du canvas pour le graphique
			echo '<canvas class="my-4 w-100 chartjs-render-monitor" id="myChart" width="1271" height="336" style="display: block; width: 1271px; height: 336px;"></canvas>';
			// Requete pour les donnees a inserer dans le graphique
			$sql = 'SELECT 
						strftime("%Y-%m", DateStart, "unixepoch") as Mois, 
						count(*) AS n 
					FROM ThinAppUsage 
					WHERE AppName = "'.base64_decode_url($_GET['name']).'" 
					GROUP BY strftime("%m-%Y", DateStart, "unixepoch") 
					ORDER BY Mois;';
			$results = $db->query($sql);
			$count = 0;
			while ($row = $results->fetchArray()) {
				$datapoints[$count]['n'] = $row['n'];
				$datapoints[$count]['Mois'] = $row['Mois'];
				$count++;
			}
			// Requete pour afficher dans le tableau la repartition par salle
			$sql = 'SELECT 
						AppName, 
						strftime("%Y-%m", DateStart, "unixepoch") as Mois, 
						count(AppName) AS n, 
						SUBSTR(Computer, 0, INSTR(Computer, "-")) as Salle 
					FROM ThinAppUsage 
					WHERE AppName == "'.base64_decode_url($_GET['name']).'"  
					GROUP BY Salle
					ORDER BY n DESC;';
			$results = $db->query($sql);
			while ($row = $results->fetchArray()) {
				
				echo "<tr><td><a href='?page=salle&name=" . base64_encode_url( $row['Salle'] ). "'>{$row['Salle']}</a></td><td>{$row['n']}</td></tr>";
			}
		} else {
			echo "<thead><tr><th>Application</th><th>Nbre d'execution</th></tr></thead><tbody>";
			$sql = 'SELECT 
						AppName, 
						count(*) AS n 
					FROM ThinAppUsage 
					WHERE AppName NOT LIKE "%.pdf"  
						AND AppName NOT LIKE "U:%"  
						AND AppName NOT LIKE "P:%"  
						AND AppName NOT LIKE "E:%"  
					GROUP BY AppName 
					ORDER BY n DESC;';
			$results = $db->query($sql);
			while ($row = $results->fetchArray()) {
				echo "<tr><td><a href='?page=app&name=". base64_encode_url($row['AppName'])."'>{$row['AppName']}</a></td><td>{$row['n']}</td></tr>";
			}
		}
		break;
	case "salle":
		if ( isset( $_GET['name'] )) {
			echo "<thead><tr><th>Application</th><th>Nbre d'execution</th></tr></thead><tbody>";
			// Affichage du canvas pour le graphique			
			echo '<canvas class="my-4 w-100 chartjs-render-monitor" id="myChart" width="1271" height="336" style="display: block; width: 1271px; height: 336px;"></canvas>';
		
			// Requete pour afficher dans le tableau la repartition par appli
			$sql = 'SELECT 
						AppName, 
						strftime("%Y-%m", DateStart, "unixepoch") as Mois, 
						count(AppName) AS n, 
						SUBSTR(Computer, 0, INSTR(Computer, "-")) as Salle 
					FROM ThinAppUsage 
					WHERE Salle == "'.base64_decode_url($_GET['name']).'"  
					GROUP BY AppName
					ORDER BY n DESC;';
			$results = $db->query($sql);
			while ($row = $results->fetchArray()) {
				echo "<tr><td><a href='?page=app&name=". base64_encode_url($row['AppName'])."'>{$row['AppName']}</a></td><td>{$row['n']}</td></tr>";
			}
			// Requete pour les donnees a inserer dans le graphique
			$sql = 'SELECT 
						strftime("%Y-%m", DateStart, "unixepoch") as Mois, 
						SUBSTR(Computer, 0, INSTR(Computer, "-")) as Salle,
						count(*) AS n 
					FROM ThinAppUsage 
					WHERE Salle = "'.base64_decode_url($_GET['name']).'" 
					GROUP BY Mois 
					ORDER BY Mois;';
			$results = $db->query($sql);
			$count = 0;
			while ($row = $results->fetchArray()) {
				$datapoints[$count]['n'] = $row['n'];
				$datapoints[$count]['Mois'] = $row['Mois'];
				$count++;
			}
		} else {
			echo "<thead><tr><th>Salles</th><th>Nbre d'execution</th></tr></thead><tbody>";
			$sql = 'SELECT AppName, Computer, count(*) AS n FROM ThinAppUsage GROUP BY SUBSTR(Computer, 1, INSTR(Computer, "-")) ORDER BY n DESC;';
			$results = $db->query($sql);
			while ($row = $results->fetchArray()) {
				$salle = substr($row['Computer'], 0, strpos($row['Computer'], '-'));
				echo "<tr><td><a href='?page=salle&name=".base64_encode_url($salle)."'>$salle</a></td><td>{$row['n']}</td></tr>";
			}
		}
		break;
	case "ff":
		echo "<thead><tr><th>Salles</th><th>Nbre d'execution</th></tr></thead><tbody>";
		$results = $db->query('select * FROM ThinAppUsage Where AppName LIKE "%.ino" or AppName LIKE "%.lab" or AppName LIKE "%.py" or AppName LIKE "%.sce";'); //lab py doc sce
		while ($row = $results->fetchArray()) {
			echo "<tr><td>{$row['AppID']}</td><td>{$row['AppName']}</td></tr>";
		}
		break;
}
echo "</tbody></table>"; 
?>
      </div>
    </main>
  </div>
</div>
<?php
	}
}

//include( 'inc/page-tableau.html' );
include( 'inc/page-footer.html' );

function base64_encode_url($string) {
    return str_replace(['+','/','='], ['-','_',''], base64_encode($string));
}

function base64_decode_url($string) {
    return base64_decode(str_replace(['-','_'], ['+','/'], $string));
}
function resultSetToArray($queryResultSet){
       $multiArray = array();
       $count = 0;
       while($row = $queryResultSet->fetchArray(SQLITE3_ASSOC)){
           foreach($row as $i=>$value) {
               $multiArray[$count][$i] = $value;
           }
           $count++;
       }
       return $multiArray;
}
