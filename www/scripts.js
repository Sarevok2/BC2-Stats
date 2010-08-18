
var itemTabLinks = new Array();
var itemStatDivs = new Array();

function init() {

	// Grab the tab links and content divs from the page
	var tabListItems = document.getElementById('tabs').childNodes;
	for ( var i = 0; i < tabListItems.length; i++ ) {
		if ( tabListItems[i].nodeName == "LI" ) {
			var tabLink = getFirstChildWithTagName( tabListItems[i], 'A' );
			var id = getHash( tabLink.getAttribute('href') );
			itemTabLinks[id] = tabLink;
			itemStatDivs[id] = document.getElementById( id );
		}
	}

	// Assign onclick events to the tab links, and
	// highlight the first tab
	var i = 0;

	for ( var id in itemTabLinks ) {
		itemTabLinks[id].onclick = showTab;
		itemTabLinks[id].onfocus = function() { this.blur() };
		if ( i == 0 ) itemTabLinks[id].className = 'selected';
		i++;
	}

	// Hide all content divs except the first
	var i = 0;

	for ( var id in itemStatDivs ) {
		if ( i != 0 ) itemStatDivs[id].className = 'itemTabs hide';
		i++;
	}
}

function showTab() {
	var selectedId = getHash( this.getAttribute('href') );

	// Highlight the selected tab, and dim all others.
	// Also show the selected content div, and hide all others.
	for ( var id in itemStatDivs ) {
		if ( id == selectedId ) {
			itemTabLinks[id].className = 'selected';
			itemStatDivs[id].className = 'itemTabs';
		} else {
			itemTabLinks[id].className = '';
			itemStatDivs[id].className = 'itemTabs hide';
		}
	}

	// Stop the browser following the link
	return false;
}


function getFirstChildWithTagName( element, tagName ) {
	for ( var i = 0; i < element.childNodes.length; i++ ) {
		if ( element.childNodes[i].nodeName == tagName ) return element.childNodes[i];
	}
}


function getHash( url ) {
	var hashPos = url.lastIndexOf ( '#' );
	return url.substring( hashPos + 1 );
}



document.onclick=hideStatBox;

var isIE = document.all?true:false;

if (!isIE) document.captureEvents(Event.MOUSEMOVE);
document.onmousemove = updateMousePos;

var xPos = 0;
var yPos = 0;

function updateMousePos(e) {
	if (isIE) {
		xPos = event.clientX + document.body.scrollLeft;
		yPos = event.clientY + document.body.scrollTop;
	}
	else {
		xPos = e.pageX;
		yPos = e.pageY;
	}
}

function getHTTPObject() {
	if (window.ActiveXObject)
		return new ActiveXObject("Microsoft.XMLHTTP");
	else if (window.XMLHttpRequest)
		return new XMLHttpRequest;
	else {
		alert("Your browser does not support AJAX.");
		return null;
	}
}


function showitemstats(persona, type, itemName) {
	httpObject = getHTTPObject();
	if (httpObject != null) {
		httpObject.open("GET", "itemstats.php?type="+type+"&name="+itemName+"&persona="+persona, true);
		httpObject.send(null);
		httpObject.onreadystatechange = setOutput;
	}
}

function formatTime(time) {
	var time = Math.floor(time/60);
	var minutes = time%60;
	time = Math.floor(time/60);
	var hours = time%24;
	var days = Math.floor(time/24);

	var string;
	if (days > 0) {string = days + "d " + hours + "h " + minutes + "m";}
	else if (hours > 0) {string = hours + "h " + minutes + "m";}
	else {string = minutes + "m";}

	return string;
}

function setOutput() {
	if (httpObject.readyState == 4) {
		var xml = httpObject.responseText;
		var xmlDoc;
		
		if (window.DOMParser) {
		  var parser=new DOMParser();
		  xmlDoc=parser.parseFromString(xml,"text/xml");
		}
		else {// Internet Explorer
		  xmlDoc=new ActiveXObject("Microsoft.XMLDOM");
		  xmlDoc.async="false";
		  xmlDoc.loadXML(xml);
	  }
		var html = "<table class='itemstatpopup'>";

		var typetags = xmlDoc.getElementsByTagName("type");
		var type;
		if (typetags.length > 0) {
			type = typetags[0].childNodes[0].nodeValue;
		}

		var locktags = xmlDoc.getElementsByTagName("lock");
		var lock = 0;
		if (locktags.length > 0) {
			lock = locktags[0].childNodes[0].nodeValue;
			if (lock && lock != 0) html = html + "<tr><th>Locked</th></tr>";
			else lock = 0;
		}
		if (lock == 0) {
			var killstags = xmlDoc.getElementsByTagName("kills");
			if (killstags.length > 0) {
				var kills = killstags[0].childNodes[0].nodeValue;
				if (kills) html = html + "<tr><th>Kills: </th><td>" + kills + "</td></tr>";
			}
			var shotsfired=0;
			var shotsfiredtags = xmlDoc.getElementsByTagName("shotsfired");
			if (shotsfiredtags.length > 0) {
				shotsfired = shotsfiredtags[0].childNodes[0].nodeValue;
				if (shotsfired) html = html + "<tr><th>Shots Fired: </th><td>" + shotsfired + "</td></tr>";
			}
			var shotshittags = xmlDoc.getElementsByTagName("shotshit");
			if (shotshittags.length > 0) {
				shotshit = shotshittags[0].childNodes[0].nodeValue;
				if (shotshit && shotsfired>0) html = html + "<tr><th>Accuracy: </th><td>" + (Math.round(shotshit/shotsfired*100)) + "%</td></tr>";
			}
			var timetags = xmlDoc.getElementsByTagName("time");
			if (timetags.length > 0) {
				var time = timetags[0].childNodes[0].nodeValue;
				if (time) html = html + "<tr><th>Time Played: </th><td>" + formatTime(time) + "</td></tr>";
			}
			var healstags = xmlDoc.getElementsByTagName("heals");
			if (healstags.length > 0) {
				var heals = healstags[0].childNodes[0].nodeValue;
				if (heals) html = html + "<tr><th>Heals: </th><td>" + heals + "</td></tr>";
			}
			var resuppliestags = xmlDoc.getElementsByTagName("resupplies");
			if (resuppliestags.length > 0) {
				var resupplies = resuppliestags[0].childNodes[0].nodeValue;
				if (resupplies) html = html + "<tr><th>Resupplies: </th><td>" + resupplies + "</td></tr>";
			}
			var revivestags = xmlDoc.getElementsByTagName("revives");
			if (revivestags.length > 0) {
				var revives = revivestags[0].childNodes[0].nodeValue;
				if (revives) html = html + "<tr><th>Revives: </th><td>" + revives + "</td></tr>";
			}
			var roadkillstags = xmlDoc.getElementsByTagName("roadkills");
			if (roadkillstags.length > 0) {
				var roadkills = roadkillstags[0].childNodes[0].nodeValue;
				if (roadkills) html = html + "<tr><th>Roadkills: </th><td>" + roadkills + "</td></tr>";
			}
			var distancetags = xmlDoc.getElementsByTagName("distance");
			if (distancetags.length > 0) {
				var distance = distancetags[0].childNodes[0].nodeValue;
				if (distance) html = html + "<tr><th>Distance Driven: </th><td>" + distance + "</td></tr>";
			}
		}
		html = html + "</table>";

		
		document.getElementById('statbox').innerHTML = html;
		document.getElementById('statbox').style.visibility = 'visible';
		document.getElementById('statbox').style.left = xPos - document.body.scrollLeft;
		document.getElementById('statbox').style.top = yPos + 20 - document.body.scrollTop;
	}
	
	
}

function hideStatBox() {
	document.getElementById('statbox').style.visibility = 'hidden';
}
