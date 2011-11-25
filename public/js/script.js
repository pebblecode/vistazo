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
      handle: '.handle',
      cursor: 'move',
      placeholder: 'placeholder',
      forcePlaceholderSize: true,
      opacity: 0.4,
      stop: function(event, ui) {
        var project = ui.item;
        var projectTeamMemberId = $(project).attr("data-team-member-id");
        var projectDate = $(project).attr("data-date");
        
        var containerTeamMemberId = $(project).parents(".team-member").first().attr("data-team-member-id");
        var containerDate = $(project).parents(".box").first().attr("data-date");
        
        if ((projectTeamMemberId != containerTeamMemberId) || (projectDate != containerDate)) {
          updateTeamMemberProject(project);
        }
      }
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

// Update team member project
function updateTeamMemberProject(proj) {
  var fromTeamMemberId = $(proj).attr("data-team-member-id");
  var toTeamMemberId = $(proj).parents('.team-member').first().attr("data-team-member-id");
  var teamMemberProjectId = $(proj).attr("data-team-member-project-id");
  var toDate = $(proj).parents('.box').first().attr("data-date");
    
  var url = "/team-member-project/" + teamMemberProjectId + "/update.json";
  $(proj).addClass('is_loading');
  $.post(url, { from_team_member_id: fromTeamMemberId, to_team_member_id: toTeamMemberId, to_date: toDate })
    .success(function(response) {
      // Update team member project info in data attributes
      $(proj).attr("data-team-member-id", toTeamMemberId);
      $(proj).attr("data-date", toDate);
    })
    .error(function(response) {
      // Move team member project back
      var fromDate = $(proj).attr("data-date");
      var fromLocation = $(".team-member[data-team-member-id=" + fromTeamMemberId + "]").find(".box[data-date=" + fromDate + "]");
      
      $(proj).remove();
      $(fromLocation).find(".new-project").before(proj);
    })
    .complete(function(data, status) {
      response = JSON.parse(data.responseText);
      if (status == "success") {
        updateFlash("success", response["message"]);
      } else {
        if (response) {
          updateFlash("warning", response["message"]);
        } else {
          updateFlash("warning", "Something weird happened. Please contact support about it.");
        }
      }
      
      $(proj).removeClass('is_loading');
    });
  
}

function updateFlash(status, msg) {
  $("#main").before("<div id='flash'><div class='flash " + status + "'>" + msg + "</div></div>");
}
