// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery(document).ready(function() {

  jQuery('.help').hide();
  jQuery(".help_link").click( function(event){ 
    event.preventDefault();
    jQuery(".help").dialog( { width: 800})
  })


  if (jQuery(".flash").text() != ""){
    jQuery(".flash").delay(2000).hide('slow');
  };

  jQuery("#multi_upload").click( function(){
  // jQuery(".pulpload").toggle('slow');
 //  var $body = $('html,body');
 //     var divPos = $(".pulpload").position();
  //    var scrollPosition = $body.scrollTop()+divPos.top;
 //  jQuery('html,body').animate({scrollTop: scrollPosition}, 500);
   jQuery(".pulpload").dialog();
})



//Tooltip
this.vtip = function() {    
this.xOffset = -12; // x distance from mouse
this.yOffset = 20; // y distance from mouse
jQuery(".vtip").unbind().hover(    
	function(e) {
		this.t = this.title;
		this.title = ''; 
		this.top = (e.pageY + yOffset); this.left = (e.pageX + xOffset);
		
		//jQuery('body').append( '<p id="vtip"><img id="vtipArrow" />' + this.t + '</p>' );
		jQuery('body').append( '<p id="vtip">' + this.t + '</p>' );            
		//jQuery('p#vtip #vtipArrow').attr("src", '../../images/vtip_arrow.png');
		jQuery('p#vtip').css("top", this.top+"px").css("left", this.left+"px").fadeIn("fast");
		
	},
	function() {                
		this.title = this.t;
		jQuery("p#vtip").fadeOut("fast").remove();
	}
).mousemove(
	function(e) {
		this.top = (e.pageY + yOffset);
		this.left = (e.pageX + xOffset);
					 
		jQuery("p#vtip").css("top", this.top+"px").css("left", this.left+"px");
            }).click(
            function() {                  
                 jQuery("p#vtip").fadeOut("fast").remove();
            }); 
    };

})
