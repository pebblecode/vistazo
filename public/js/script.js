$(function () {
  $("#new-project-dialog").hide(); // Hide by default
  
  $(".new-project").click(function () {
    $(this).css({opacity: "1"});
    
    $("#new-project-dialog form input[name=date]").val($(this).attr("data-date"));
    $("#new-project-dialog form input[name=team_member]").val($(this).attr("data-team-member"));
    $("#new-project-dialog").show();
    return false;
  });
  
  $("#new-project-dialog .close").click(function() {
    $("#new-project-dialog").hide();
    return false;
  });
  
});

$(function () {
  $(".new-project").hover(function () {
    $(this).animate({opacity: "1"});
    
  }, function () {
  
    $(this).animate({opacity: "0"});  
      
  });
}); // New project tab hover

// style dates