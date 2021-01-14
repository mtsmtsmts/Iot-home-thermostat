<?php
    $Temp = $_GET['Temp'];
	
    if ( (!empty($Temp)) && (!preg_match('#[^0-9]#',$Temp)) ) {
        //Doesn't accept decimal numbers
       file_put_contents('data.html',  $Temp); 
    } 
    else {
		//do nothing - preserve data in db
	}
    //if(is_int($Temp)){
    //if (is_numeric((float) $Temp)){ 
	//if (ctype_digit($Temp)) {
?>


