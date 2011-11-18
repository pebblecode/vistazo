$(function () {
  $(".new-project").click(function () {
    $(this).css({opacity: "1"});
    $("#d-test").animate({opacity: "1"});
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