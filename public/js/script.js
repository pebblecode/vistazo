$(function () {
  $("#new-project-dialog").hide(); // Hide by default
  
  $(".new-project").click(function () {
    $(this).css({opacity: "1"});
    
    $("#new-project-dialog form input[name=date]").val($(this).attr("data-date"));
    $("#new-project-dialog form input[name=team_member_id]").val($(this).attr("data-team-member-id"));
    $("#new-project-dialog").show();
    return false;
  });
  
  $("#new-project-dialog .close").click(function() {
    $("#new-project-dialog").hide();
    return false;
  });
  
  // Enter key for new project submits the form
  $("#new-project-dialog .new-project-text-box").bind("keydown", function(event) {
     // track enter key
     var keycode = (event.keyCode ? event.keyCode : (event.which ? event.which : event.charCode));
     if (keycode == 13) { // keycode for enter key
        // force the 'Enter Key' to implicitly click the Update button
        $("#new-project-dialog .new-project-submit-button").click();
        return false;
     } else  {
        return true;
     }
  }); // end of function
  
  // Drag and drop for projects
  $('table .box').sortable({
      connectWith: '.box',
      handle: '.circle',
      cursor: 'move',
      placeholder: 'placeholder',
      forcePlaceholderSize: true,
      opacity: 0.4,
  })
  .disableSelection();
  
});

$(function () {
  $(".new-project").hover(function () {
    $(this).animate({opacity: "1"});
    
  }, function () {
  
    $(this).animate({opacity: "0"});  
      
  });
}); // New project tab hover

// style dates