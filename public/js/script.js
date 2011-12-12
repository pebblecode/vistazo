$(function () {
  // Flash the flash message
  if ($("#flash").length > 0) {
    $("#flash").hide(0, function() {
      $(this).fadeIn(1000);
    });
  }
  
  // Delete button - only show on hover
  {
    $(".delete-tm-project-form button").hide();
    $(".project").hover(function() {
      $(this).find(".delete-tm-project-form button").fadeIn(200);
    },
    function() {
      $(this).find(".delete-tm-project-form button").fadeOut(100);
    });
  }
  
  // Labelify new object text boxes
  $(".new-object-text-box").labelify({ labelledClass: "new-object-text-box-label" });
  
  // Add help body class
  $("#top-nav .action-bar .help").click(function() {
    $("body").toggleClass("help-on");
  });
  
  // Project dialog
  {
    $("#new-project-dialog").hide(); // Hide by default
    
    // Hide if clicking outside #new-project-dialog
    $('html').click(function() {
      $("#new-project-dialog").hide();
    });
    
    $("#new-project-dialog").click(function(event) {
      event.stopPropagation(); // Prevent clicking on form from hiding the form
    });
    
    $(".project").click(function(event) {
      $("#new-project-dialog").hide();
      event.stopPropagation(); // Prevent openning new project dialog
    });
    $(".box").click(function (event) {
      $("#new-project-dialog form input[name=date]").val($(this).attr("data-date"));
      $("#new-project-dialog form input[name=team_member_id]").val($(this).attr("data-team-member-id"));
      
      var new_project_dialog_top_offset = -46;
      var new_project_dialog_left_offset = 20;
      $("#new-project-dialog").show().offset({ top: event.pageY + new_project_dialog_top_offset, left: event.pageX + new_project_dialog_left_offset });
      $("#new-project-dialog").show();
      
      event.stopPropagation(); // Prevent click from hiding form
      return false;
    });

    $("#new-project-dialog .close").click(function() {
      $("#new-project-dialog").hide();
      return false;
    });
    
    // Enter key for new project submits the form
    $("#new-project-dialog .new-object-text-box").bind("keydown", function(event) {
       // track enter key
       var keycode = (event.keyCode ? event.keyCode : (event.which ? event.which : event.charCode));
       if (keycode == 13) { // keycode for enter key
          // force the 'Enter Key' to implicitly click the Update button
          $("#new-project-dialog .submit-button").click();
          return false;
       } else  {
          return true;
       }
    }); // end of function
  }
  
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
        
        // Hide new dialog in case a click gets triggered and shows it
        $("#new-project-dialog").hide();
      }
  })
  .disableSelection();
  
});

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
      $(fromLocation).append(proj);
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

function updateFlash(flashType, msg) {
  var flashMessage = "<div class='flash " + flashType + "'>" + msg + "</div>";
  
  if ($("#flash").length <= 0) {
    $("#main").before("<div id='flash'></div>");
  }  
  
  $("#flash .flash").remove();
  // Flash the flash message
  $("#flash").append(flashMessage).hide(0, function() {
    $(this).fadeIn(1000);
  });

  
}
