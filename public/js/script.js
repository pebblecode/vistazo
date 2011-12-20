/*
 * Preload images jQuery plugin
 * http://stackoverflow.com/questions/476679/preloading-images-with-jquery
 *
 */
$.fn.preload = function() {
  this.each(function(){
    $('<img/>')[0].src = this;
  });
}

$(function () {

  // Preload AJAX spinner
  $(['/img/loading.gif']).preload();
  
  // Flash the flash message
  if ($("#flash").length > 0) {
    $("#flash").hide(0, function() {
      $(this).fadeIn(1000);
    });
  }
  
  // Hide project add button on .project hover
  {
    $(".project").hover(
      function() {
        $(this).parents(".box").addClass("remove-add-img")
      },
      function() {
        $(this).parents(".box").removeClass("remove-add-img")
      }
    );
  }
  
  // Declare dialogs (but don't open by default)
  {
    // Team name
    $("#team-name-dialog").dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 470,
      minHeight: 65,
      autoOpen: false,
      position: 'top',
      closeText: "'"
    });
    $("#team-name h2").click(function(event) {
      $("#team-name-dialog").dialog('open');
      $("#team-name #team-name-form input:first").focus();
      overlayCloseOnClick();
      
      return false;
    });
    
    // User settings
    $( "#team-users-dialog" ).dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 480,
      position: 'top',
      autoOpen: false,
      closeText: "'"
    });
    $("#top-nav .action-bar .user-settings").click(function() {
      $( "#team-users-dialog" ).dialog('open');
      overlayCloseOnClick();
      
      return false;
    });
    
    // Team member edit
    $( ".edit-team-member-dialog" ).each(function() {
      // Create dialog with id instead of class
      $(this).dialog({
        modal: true,
        closeOnEscape: true,
        minWidth: 470,
        minHeight: 85,
        autoOpen: false,
        position: 'top',
        closeText: "'"
      })
    });
    $("#main .team-member-name").click(function() {
      var dialog_id = $(this).attr("href");
      $(dialog_id).dialog('open');
      overlayCloseOnClick();
      
      return false;
    });
    
    // Overlays - close dialogs when clicking (Note: need to run this after dialogs are created)
    function overlayCloseOnClick() {
      $(".ui-widget-overlay").live('click', function(){
         $(".ui-dialog-titlebar-close").trigger('click');
      });
    }
  }
  
  // Add user email checking
  {
    $("#invite-user-form").submit(function() {
      var error_form_classname = "errors-on-form";
      var error_field_msg_classname = "error-field-msg";
      var email = $(this).find(".new-object-text-box").val();
      
      // Regex from http://www.regular-expressions.info/email.html
      var valid_email = email.match(/(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i);
      if (!valid_email) {
        // Set invalid class and append message
        $(this).addClass(error_form_classname);
        if ($(this).find("." + error_field_msg_classname).length <= 0) {
          $(this).append("<p class='" + error_field_msg_classname + "'>Invalid email address</p>")
        }
        
        // Flash the error message
        $(this).find("." + error_field_msg_classname).hide(0, function() {
          $(this).fadeIn(500);
        });
        
        // Don't send the form
        return false;
      } else {
        $(this).find("." + error_field_msg_classname).remove();
        $(this).removeClass(error_form_classname);
      }
    });
  }
  
  // Team member
  {
    // Hijack submit button if nothing is in textbox (either empty or labelified value)
    $("#new-team-member-form .submit-button").click(function() {
      if (($("#new-team-member-form .new-object-text-box").val() == "") ||
           $("#new-team-member-form .new-object-text-box").val() == $("#new-team-member-form .new-object-text-box").attr("title")) {

        $("#new-team-member-form .new-object-text-box").focus();
        return false;
      }
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
    
    return false;
  });
  
  //remove help body class
  $("#overlay-bg, #help-nav, #help-week, #help-new, #help-close, #help-project, help-team").click(function() {
    $("body").removeClass("help-on");
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
      
      // Focus on new project text box
      $("#new-project-dialog .new-object-text-box").focus();
      
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
  var teamId = window.location.pathname.split('/')[1]; // From the first path of url
  var fromTeamMemberId = $(proj).attr("data-team-member-id");
  var toTeamMemberId = $(proj).parents('.team-member').first().attr("data-team-member-id");
  var teamMemberProjectId = $(proj).attr("data-team-member-project-id");
  var toDate = $(proj).parents('.box').first().attr("data-date");
    
  var url = "/" + teamId + "/team-member-project/" + teamMemberProjectId + "/update.json";
  $(proj).addClass('is_loading');
  $.post(url, { from_team_member_id: fromTeamMemberId, to_team_member_id: toTeamMemberId, to_date: toDate })
    .success(function(response) {
      // Update team member project info in data attributes
      $(proj).attr("data-team-member-id", toTeamMemberId);
      $(proj).attr("data-date", toDate);
      
      // Update delete link
      var delete_url = $(proj).find(".delete-tm-project-form").attr("action");
      // Should be in the form /team-member/[team member id]/project/[team member project id]/delete
      var old_team_member_id = delete_url.split("/")[2];
      var new_delete_url = delete_url.replace(old_team_member_id, toTeamMemberId);
      $(proj).find(".delete-tm-project-form").attr("action", new_delete_url);
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
