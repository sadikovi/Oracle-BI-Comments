//URL-encoding script
/**
*
* URL encode / decode
* http://www.webtoolkit.info/
*
**/
var Url = {
	// public method for url encoding
	encode : function (string) {
		return escape(this._utf8_encode(string));
	},
	// public method for url decoding
	decode : function (string) {
		return this._utf8_decode(unescape(string));
	},
	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
		string = string.replace(/\r\n/g,"\n");
		var utftext = "";
		for (var n = 0; n < string.length; n++) {
			var c = string.charCodeAt(n);
			if (c < 128) {
				utftext += String.fromCharCode(c);
			}
			else if((c > 127) && (c < 2048)) {
				utftext += String.fromCharCode((c >> 6) | 192);
				utftext += String.fromCharCode((c & 63) | 128);
			}
			else {
				utftext += String.fromCharCode((c >> 12) | 224);
				utftext += String.fromCharCode(((c >> 6) & 63) | 128);
				utftext += String.fromCharCode((c & 63) | 128);
			}
		}
		return utftext;
		},
	// private method for UTF-8 decoding
	_utf8_decode : function (utftext) {
		var string = "";
		var i = 0;
		var c = c1 = c2 = 0;
		while ( i < utftext.length ) {
			c = utftext.charCodeAt(i);
			if (c < 128) {
				string += String.fromCharCode(c);
				i++;
			}
			else if((c > 191) && (c < 224)) {
				c2 = utftext.charCodeAt(i+1);
				string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
				i += 2;
			}
			else {
				c2 = utftext.charCodeAt(i+1);
				c3 = utftext.charCodeAt(i+2);
				string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
				i += 3;
			}
		}
		return string;
	}
};

/*****************************************/
/*Write comment*/
/*****************************************/
//Method for writing comment
//Global parameters for taking current element attributes: "report" and "p0", "p1", "p2" and etc.
var cg_reportName = '';
var cg_parameters = new Array();

//Call function to show Comment Editor Form
doShowCustomDialog = function(b, c) {
	var a = new sitCustomCommentEditor('id');
	var e = new XUIDialog('id', a, a);
	e.dialogModel.titleText = 'Редактор комментария';
	e.show(a.backgroundFormat, a.clientWidth, a.clientHeight);
};

sitCustomCommentEditor = function(eid) {
	this.eid = eid;
}

sitCustomCommentEditor.prototype = new XUIEditor();

//Actions for editor when displayed
sitCustomCommentEditor.prototype.onDisplay = function()
{
	document.getElementById('sitComment').value = '';
}

//Actions for apply button
sitCustomCommentEditor.prototype.apply = function() {
	var opaqueLayer = saw.createChildElement(document.body, "div", "OpaqueLayer");
	jQuery('div.OpaqueLayer').attr('style', 'position: absolute; top: 0px; left: 0px; width: '+ document.body.offsetWidth +'px; height: '+ document.body.offsetHeight +'px; z-index: 4;');
	
	//Collect send parameters (comment text, report name, list of parameters)
	jQuery('#sitComment').each(function() {
		var commentTxt = Url.encode(jQuery(this).val());
		var reportName = cg_reportName;
		var parametersList = cg_parameters;
		
		//form send data
		sendData = {action: 'writecomment', objectname: reportName, comment: commentTxt};
		for (j=0;j<parametersList.length;j++) {
			jQuery(sendData).attr('p' + j, parametersList[j]);
		}
		
		function success(data) {
			alert('Ваш комментарий успешно загружен');
			jQuery('div.OpaqueLayer').remove();
		};
		
		function error(request, textStatus, thrownError) {
			jQuery('div.OpaqueLayer').remove();
			var requestJSON = jQuery.parseJSON(request.responseText)
			if (requestJSON.code === '004') {
				alert('Не введен текст комментария. Попробуйте еще раз.');
			} else {
				alert('Ошибка: ' + requestJSON.code + ': ' + requestJSON.message);
			}
		};
		
		jQuery.ajax({
			type: 'POST',
			url: '/analytics/rtk-xls-data-manager/commentsservlet',
			data: sendData,
			success: success,
			error: error
		});
	});
	
	cg_reportName = '';
	cg_parameters = '';
	
	return true;
};
//Init method for writing comment
function sitWriteComment(obj, event) {
	if (jQuery(obj).hasClass('Active')) {
		var reportName = jQuery(obj).attr('report');
		var pArray = new Array();
		
		var pCount = jQuery(obj).attr('p0') * 2 + 1;
		
		var currentPAttr = 'p0';
		for (i=0;i<pCount;i++) {
			currentPAttr = 'p' + i;
			pArray[i] = Url.encode(jQuery(obj).attr(currentPAttr));
		}
		
		cg_reportName = Url.encode(reportName);
		cg_parameters = pArray;

		doShowCustomDialog(null, event);
	}
};

/*****************************************/
/*Load comment*/
/*****************************************/
//Method for reading comments
//Create and resize scrollable menu methods
saw.header.getMaxMenuHeight = function (a) {
	return saw.getClientHeight() - saw.getElementXY(a)[1] - 100
};
saw.header.createScrollableMenuPanel = function (d, a) {
	if (saw.header.getMaxMenuHeight(a) < 300) {
		var c = saw.header.getMaxMenuHeight(a);
	} else {
		var c = 300;
	}
	var b = new saw.header.ScrollablePanel(d, c);
	return b
};
saw.header.resizeScrollableMenu = function (b, a) {
	if (b.parentNode != b.ownerDocument.body) {
		b.ownerDocument.body.appendChild(b)
	}
	if (b.style.display != "block") {
		b.style.visibility = "hidden";
		b.style.display = "block"
	}
	if (b.scrollPanel) {
		b.scrollPanel.resize(a ? saw.header.getMaxMenuHeight(a) : null)
	}
};

//Function to get scrollable menu coordinates
function sitGetObjCoords(elem) {
	var box = elem.getBoundingClientRect();

	var body = document.body;
	var docElem = document.documentElement;
	
	var scrollTop = window.pageYOffset || docElem.scrollTop || body.scrollTop;
	var scrollLeft = window.pageXOffset || docElem.scrollLeft || body.scrollLeft;
	
	var clientTop = docElem.clientTop || body.clientTop || 0;
	var clientLeft = docElem.clientLeft || body.clientLeft || 0;
	var topE = box.top  + scrollTop + elem.offsetHeight - clientTop;
	var leftE = box.left + scrollLeft - clientLeft;
	
	return {top: topE, left: leftE};
}
//Init method for reading comment
//Loading comment list data
function sitLoadComment(activeObj, event) {

	jQuery(activeObj).find('img.loadInd').attr('src', '/analytics/res/sk_blafp/catalog/loading-indicator-white.gif'); //Activate Indicator
	
	//Take parameters: report name and list of parameters
	var report = Url.encode(jQuery(activeObj).attr('report'));
	var params = new Array();
	
	var pCount = jQuery(activeObj).attr('p0') * 2 + 1;

	var currentPAttr = 'p0';
	for (i=0;i<pCount;i++) {
		currentPAttr = 'p' + i;
		params[i] = Url.encode(jQuery(activeObj).attr(currentPAttr));
	}
	
	//format send data
	sendData = {action: 'readcomment', objectname: report};
	for (j=0;j<params.length;j++) {
		jQuery(sendData).attr('p' + j, params[j]);
	}
	
	function success(data) {
	
		jQuery('img.loadInd').attr('src', '/analytics/res/sk_blafp/catalog/fileUpload_ena.png'); //Remove Indicator
		
		if (!menuDiv) {
			var menuDiv = saw.createChildElement(document.body, 'div', 'HeaderPopupWindow');
			var d = saw.header.createScrollableMenuPanel( menuDiv, activeObj);
			var menuItemsDiv = d.getContentContainer();
			var contentDiv = saw.createChildElement(menuItemsDiv, 'div', 'contentDivClass');
			var contentTable = saw.createChildElement(contentDiv, 'table', 'contentTable');
			var contentTBody = saw.createChildElement(contentTable, 'tbody', 'contentTable');
			var contentTR = saw.createChildElement(contentTBody, 'tr', '');
			var contentTD = saw.createChildElement(contentTR, 'td', '');
			
			if (data.result.length === 1 && data.result[0].comment === 'Комментарии отсутствуют') {
				var commentTable = saw.createChildElement(contentTD, 'table', 'contentTableComment');
				var commentTBody = saw.createChildElement(commentTable, 'tbody', 'contentTableCommentTbody');
				var comment = saw.createChildElement(commentTBody, 'tr', 'contentTableCommentTbodyTr');
						var commentText = saw.createChildElement(comment, 'td', 'contentTableCommentTbodyTrTd');
						jQuery(commentText).text(data.result[0].comment);
			} else {
				for (i=0;i<data.result.length;i++) {
					var commentTable = saw.createChildElement(contentTD, 'table', 'contentTableComment');
					jQuery(commentTable).attr('commentID', data.result[i].id);
					var commentTBody = saw.createChildElement(commentTable, 'tbody', 'contentTableCommentTbody');
					var title = saw.createChildElement(commentTBody, 'tr', 'contentTableCommentTitle');
						var date = saw.createChildElement(title, 'td', 'contentTableCommentTitleDate');
						jQuery(date).text(data.result[i].date);
						
						//add remove and alert images then username = returnData.username
						//Check user name
						var spanUser = '';
						jQuery('span.uberBarTextMenuButtonSpan.HeaderUserName').find('span.HeaderMenuBarText.HeaderMenuNavBarText').each(function() {
							jQuery(this).find('span').each(function () {
								spanUser = jQuery(this).text();
							});
						});
						
						if (spanUser === data.result[i].username) {
							var buttons = saw.createChildElement(title, 'td', 'contentTableCommentTitleButtons');
							jQuery(buttons).attr('align', 'right');
								var removeImage = saw.createChildElement(buttons, 'img', 'contentTableTitleButtonsRemoveImage');
								jQuery(removeImage).attr('src', '/analytics/res/sk_blafp/answers/remove.png').css({'height' : '15px', 'opacity' : '0.3'});
								jQuery(removeImage).attr({onmouseover: 'imageActive(this)', onmouseout: 'imageNormal(this)', onclick: 'imageClick(this)'});
						} else {
							jQuery(date).attr('colspan', 2);
						};
						
					var title = saw.createChildElement(commentTBody, 'tr', 'contentTableCommentTitle');
						var username = saw.createChildElement(title, 'td', 'contentTableCommentTitleUser');
						jQuery(username).text(data.result[i].username);
					
						var userComments = saw.createChildElement(title, 'td', 'contentTableCommentTitleUserComments');
						jQuery(userComments).text('оставил(а) комментарий:');
					
					var comment = saw.createChildElement(commentTBody, 'tr', 'contentTableCommentText');
						var commentText = saw.createChildElement(comment, 'td', 'contentTableCommentTextTd');
						jQuery(commentText).attr('colspan', 2);
						jQuery(commentText).text(data.result[i].comment);
				}
			}
		
		jQuery('div.HeaderPopupWindow').offset({ top: sitGetObjCoords(activeObj).top, left: sitGetObjCoords(activeObj).left});
		d.resize();
		} else {
			saw.header.resizeScrollableMenu(menuDiv, activeObj); //Resize scrollable panel
		}
	};
	
	function error(request, textStatus, thrownError) {
		jQuery('img.loadInd').attr('src', '/analytics/res/sk_blafp/catalog/fileUpload_ena.png'); ////Remove Indicator
		var requestJSON = jQuery.parseJSON(request.responseText);
		alert('Ошибка: ' + requestJSON.code + ': ' + requestJSON.message);
	};
	
	jQuery.ajax({
		type: 'POST',
		url: '/analytics/rtk-xls-data-manager/commentsservlet',
		data: sendData,
		dataType: 'json',
		success: success,
		error: error
	});
};
/*****************************************/
/*Delete comment*/
/*****************************************/
//Button actions
function imageActive(obj) {
	jQuery(obj).css('opacity', '1.0').addClass('Active');
};
function imageNormal(obj) {	
	jQuery(obj).css('opacity', '0.3').removeClass('Active');
};
function imageClick(obj) {
	if (jQuery(obj).hasClass('Active')) {
		if (jQuery(obj).hasClass('contentTableTitleButtonsRemoveImage')) {
			var opaqueLayer = saw.createChildElement(document.body, "div", "OpaqueLayer");
			jQuery('div.OpaqueLayer').attr('style', 'position: absolute; top: 0px; left: 0px; width: '+ document.body.offsetWidth +'px; height: '+ document.body.offsetHeight +'px;');
			sitDeleteComment(obj, null);
		}
	}
};
//Init method for deleting comment
//Delete comment
function sitDeleteComment(obj, event) {
	//Get and encode parameters from active object
	var currentTable = jQuery('table.contentTableComment').has(obj);
	var commentIdF = jQuery(currentTable).attr('commentID');
	
	//Format send data
	var sendData = {action: 'deletecomment', comment_id: commentIdF};
	
	function success(data) {
		jQuery('div.OpaqueLayer').remove();
		alert('Комментарий успешно удален');
	};
	
	function error(request, textStatus, thrownError) {
		jQuery('div.OpaqueLayer').remove();
		var requestJSON = jQuery.parseJSON(request.responseText);
		alert('Ошибка удаления. ' + requestJSON.code + ': ' + requestJSON.message);
	};

	jQuery.ajax({
		type: 'POST',
		url: '/analytics/rtk-xls-data-manager/commentsservlet',
		data: sendData,
		dataType: 'json',
		success: success,
		error: error
	});
};