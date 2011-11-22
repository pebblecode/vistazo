$(function () {
  $("#new-project-form").hide(); // Hide by default
  
  $(".new-project").click(function () {
    $(this).css({opacity: "1"});
    $("#new-project-form").show();
  });
  
  $("#new-project-form .close").click(function() {
    $("#new-project-form").hide();
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