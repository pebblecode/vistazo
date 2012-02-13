var TEAM_ID = window.location.pathname.split('/')[1]; // From the first path of url

// Attempt at modularising backbone code
// VistazoApp = (function($) {
//   TeamMemberView = Backbone.View.extend({
//     render: function() {
//       $("week-view").html("weeeeeek");
//     }
//   });

//   var self = {};
//   self.start = function() {
//     new TeamMemberView({el: $('#week-view')}).render();
//   }
//   return self;
// });

// $(function() {
//   new VistazoApp(jQuery).start();
// });

/*
 * Backbone.js definitions
 */

// Use mustache symbols for variables in templates
// To interpolate values from input use: {{ ... }}
// To evaluate js use: {% ... %}
_.templateSettings = {
  interpolate: /\{\{(.+?)\}\}/g,
  evaluate: /\{\%(.+?)\%\}/g
};

var TeamMember = Backbone.Model.extend({
  defaults: {
    name : ""
  },
  url: "/" + TEAM_ID + "/team-member/add"
});

var TeamMembers = Backbone.Collection.extend({
  model: TeamMember,
  url: "/" + TEAM_ID + "/team-members"
});

var teamMembers = new TeamMembers;

teamMembers.bind('sync', function(teamMember) {
  console.log("successful creation");
  console.log("teamMember: " + JSON.stringify(teamMember));

  teamMemberView.render(teamMember);

  updateFlash("success", "Successfully added '<em>" + teamMember.get('name') + "</em>'.");
});

teamMembers.bind('error', function(response) {
  if (response) {
    try {
      respJson = JSON.parse(response.responseText);
      updateFlash("warning", respJson["message"]);
    } catch(error) {
      console.log(error);
      updateFlashWithError();
    }
  } else {
    updateFlashWithError();
  }
});

var TeamMemberView = Backbone.View.extend({
  events: { 
    "click #new-team-member-form .submit-button" : "handleNewTeamMember" 
  },
  handleNewTeamMember: function(data) {
    var inputField = $('input[name=new_team_member_name]');
    console.log("Pre create");
    
    var tm = new TeamMember({
      name: inputField.val()
    });

    tm.save();
    teamMembers.add(tm);

    inputField.val('');

    return false; // Don't submit form
  },
  render: function(teamMember) {
    console.log("Render team member row for: " + JSON.stringify(teamMember) + " (" + teamMember.get("id") + "): " + teamMember.get("name"));
    
    var rowNum = $(this.el).find(".team-member").length + 1 + 1; // 1 to increment and 1 for header row
    var rowClass = "row" + rowNum;
    var oddOrEvenClass = rowNum % 2 == 0 ? "even" : "odd";
    var weekTemplateVars = {
      tmId: teamMember.get("id"),
      tmName: teamMember.get("name"),
      oddOrEvenClass: oddOrEvenClass,
      rowClass: rowClass,
      tmProjects: teamMember.get("timetable_items")
    };
    var week = _.template($("#week-template").html(), weekTemplateVars);
    
    $(this.el).find('#week-view-content').append(week);

    setupEditTeamMemberDialog();
    setupNewProjectDialog();

    return this;
  }  
});

$(function () {
  
  // Flash the flash message
  if ($("#flash").length > 0) {
    $("#flash").hide(0, function() {
      $(this).fadeIn(1000);
    });
  }
  
  // First signed on
  {
    // Show help text
    if ($("body").hasClass("first-signon")) {
      $("body").addClass("help-on");
    }
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
    
    // Delete project
    $("#new-project-dialog .delete").click(function() {
      $( "#delete-project-dialog" ).dialog('open');
      $("#new-project-dialog").hide();
      overlayCloseOnClick();

      // Fill in form
      var deleteProjectDialog = _.template("\
      <div id='delete-project-dialog' title='Delete &ldquo;{{ projectName }}&rdquo; project'>\
        <p class='warning-icon'>W</p><p class='warning-msg'>All items added to the weekly timetable will also be deleted.</p>\
        <form method='post' action='/{{ teamId }}/project/{{ projectId }}/delete'>\
          <fieldset class='delete-object-fieldset' title='Delete project'>\
            <button class='delete' value='delete' name='delete' type='submit'>delete</button>\
          </fieldset>\
        </form>\
      </div>");

      $("#main").append(deleteProjectDialog({
        teamId: TEAM_ID, 
        projectId: $(this).parent().find("button[name=project_id]").val(),
        projectName: $(this).parent().find("button[name=project_id]").text()
      }));
      $( "#delete-project-dialog" ).dialog({
        modal: true,
        closeOnEscape: true,
        minWidth: 480,
        minHeight: 70,
        position: 'top',
        autoOpen: true,
        closeText: "'"
      });
      
      return false;
    });
    // Hide delete buttons by default and only show on 
    // $("#new-project-dialog .listing li button").hover(function() {
    //   $(this).parent().find(".delete").show();
    // }, function() {
    //   $(this).parent().find(".delete").hide();
    // });
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
  
  // Team member project delete button
  {
    // Only show on hover
    $(".delete-tm-project-form button").hide();
    $(".project").hover(function() {
      $(this).find(".delete-tm-project-form button").fadeIn(200);
    },
    function() {
      $(this).find(".delete-tm-project-form button").fadeOut(100);
    });
    
    // AJAX-ify delete
    $(".delete-tm-project-form button").click(function(event) {
      deleteTimetableItem($(this).first().parents(".project").first());
      return false;
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
      event.stopPropagation(); // Prevent opening new project dialog
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
    
    // AJAX-ify add existing project
    $("#new-project-dialog .listing li button").click(function() {
      var teamMemberId = $(this).parents('#new-tm-project-form').find("input[name=team_member_id]").val();
      var projId = $(this).val();
      var projDate = $(this).parents('#new-tm-project-form').find("input[name=date]").val();
      var projName = $(this).attr("title");
      var projHandleCssClass = $(this).parent().find(".handle").attr("class");
      
      // Add project object
      var projectTemplate = _.template(
        "<div class='project' data-team-member-id='{{ tmId }}' data-team-member-project-id='{{ tmProjId }}' data-date='{{ projDate }}'><div class='handle-container'><div class='{{ projHandleCssClass }}'></div></div><p class='project-title' title='{{ projName }}'>{{ projName.substring(0, 40) }}</p><form class='delete-tm-project-form' action='/team-member/{{ tmId }}/project/{{ tmProjId }}/delete' method='post'><button name='delete_project' type='submit' value='true'>×</button></form></div>"
      );
      var defaultProject = projectTemplate({
        tmId: teamMemberId,
        tmProjId: '',
        projHandleCssClass: projHandleCssClass,
        projDate: projDate,
        projName: projName
      });
      var projContainer = $(".box[data-team-member-id=" + teamMemberId + "][data-date='" + projDate + "']");
      $(projContainer).append(defaultProject);
      var proj = $(projContainer).children().last(".project");
      $(proj).addClass('is_loading');
      
      var url = "/" + TEAM_ID + "/team-member/" + teamMemberId + "/project/add.json";
      $.post(url, { date: projDate, project_id: projId })
        .success(function(response) {
          var tmProjId = response["team_member_project_id"];
          
          // Regenerate project using template
          submittedProj = projectTemplate({
            tmId: teamMemberId,
            tmProjId: tmProjId,
            projHandleCssClass: projHandleCssClass,
            projDate: projDate,
            projName: projName
          });
          $(proj).replaceWith(submittedProj); // NOTE: proj is no longer available
        })
        .error(function(response) {
          $(proj).remove();
          $(proj).removeClass('is_loading');
        })
        .complete(function(data, status) {
          var response = JSON.parse(data.responseText);
          if (status == "success") {
            updateFlash("success", response["message"]);
          } else {
            if (response) {
              updateFlash("warning", response["message"]);
            } else {
              updateFlash("warning", "Something weird happened. Please contact support about it.");
            }
          }
        });
      
      $("#new-project-dialog").hide();
      
      return false;
    });
    
    // AJAX-ify add new project
    
  }
});

// Overlays - close dialogs when clicking (Note: need to run this after dialogs are created)
function overlayCloseOnClick() {
  $(".ui-widget-overlay").live('click', function(){
     $(".ui-dialog-titlebar-close").trigger('click');
  });
}

function setupNewProjectDialog() {
    // Click box to show new project dialog
  $(".box").click(function (event) {
    $("#new-project-dialog form input[name=date]").val($(this).attr("data-date"));
    $("#new-project-dialog form input[name=team_member_id]").val($(this).attr("data-team-member-id"));
    
    // If clicked on weekend add class for weekend, and place dialog on the left
    // Otherwise, place dialog on the right
    $( "#new-project-dialog" ).removeClass("is-weekend");
    var new_project_dialog_top_offset = -46;
    var new_project_dialog_left_offset = 0;
    if ($(this).hasClass("col7") || $(this).hasClass("col8")) {
      $( "#new-project-dialog" ).addClass("is-weekend");
      new_project_dialog_left_offset = -220;
    } else {
      new_project_dialog_left_offset = 20;
    }

    $("#new-project-dialog").show().offset({ top: event.pageY + new_project_dialog_top_offset, left: event.pageX + new_project_dialog_left_offset });
    $("#new-project-dialog").show();
    
    // Focus on new project text box
    $("#new-project-dialog .new-object-text-box").focus();
    
    event.stopPropagation(); // Prevent click from hiding form
    return false;
  });

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
          updateTimetableItem(project);
        }
        
        // Hide new dialog in case a click gets triggered and shows it
        $("#new-project-dialog").hide();
      }
  })
  .disableSelection();
}

function setupEditTeamMemberDialog() {
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
}


// Update team member project
function updateTimetableItem(proj) {
  var fromTeamMemberId = $(proj).attr("data-team-member-id");
  var toTeamMemberId = $(proj).parents('.team-member').first().attr("data-team-member-id");
  var timetableItemId = $(proj).attr("data-team-member-project-id");
  var toDate = $(proj).parents('.box').first().attr("data-date");
    
  var url = "/" + TEAM_ID + "/team-member-project/" + timetableItemId + "/update.json";
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

// Delete team member project
function deleteTimetableItem(proj) {
  var teamMemberId = $(proj).attr("data-team-member-id");
  var timetableItemId = $(proj).attr("data-team-member-project-id");
    
  var url = "/team-member/" + teamMemberId + "/project/" + timetableItemId + "/delete.json";
  $(proj).addClass('is_loading');
  $.post(url)
    .success(function(response) {
      $(proj).fadeOut("slow", function() {
        $(this).remove();
      });
    })
    .error(function(response) {
      // Do nothing
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

function updateFlashWithError() {
  updateFlash("warning", "Something weird happened. Please contact support about it.");
}