// Global app namespace
var App = {};

(function() {

var TEAM_ID = window.location.pathname.split('/')[1]; // From the first path of url

// Use mustache symbols for variables in templates
// To interpolate values from input use: {{ ... }}
// To evaluate js use: {% ... %}
_.templateSettings = {
  interpolate: /\{\{(.+?)\}\}/g,
  evaluate: /\{\%(.+?)\%\}/g
};

///////////////////////////////////////////////////////////////
// Model/Collection declarations
///////////////////////////////////////////////////////////////

App.User = Backbone.Model.extend({
  defaults: {
    name: "",
    email: ""
  },
  url: "/" + TEAM_ID + "/team-member/add",
  addTimetableItem: function(ttItem) {
    var newTimetableItems = this.get("timetable_items");
    newTimetableItems.push(ttItem);
    this.set("timetable_items", newTimetableItems);
  },
  removeTimetableItemId: function(ttItemId) {
    var newTimetableItems = _.reject(this.get("timetable_items"), 
      function(ttItem) {
        return ttItem["id"] === ttItemId;
      });
    this.set("timetable_items", newTimetableItems);
  }
});

App.Users = Backbone.Collection.extend({
  model: App.User,
  url: "/" + TEAM_ID + "/team-members",
  addTimetableItemToUser: function(ttItem, userId) {
    var user = this.get(userId);
    user.addTimetableItem(ttItem);
  },
  updateTimetableItemForUser: function(ttItem, fromUserId, toUserId) {
    var fromUser = this.get(fromUserId);
    fromUser.removeTimetableItemId(ttItem["id"]);

    var toUser = this.get(toUserId);
    toUser.addTimetableItem(ttItem);
  },
  removeTimetableItemIdFromUser: function(ttItemId, userId) {
    var user = this.get(userId);
    user.removeTimetableItemId(ttItemId);
  }
});

App.TimetableItem = Backbone.Model.extend({
  defaults: {
    project_id: "",
    project_name: "",
    team_id: "",
    user_id: "",
    date: ""
  },
  url: function() {
    return "/" + this.get("team_id") + "/user/" + this.get("user_id") + "/timetable-items/new.json";
  }
});

App.Project = Backbone.Model.extend({
  defaults: {
    id: "",
    name: "",
    hex_colour: ""
  },

  // Same logic as lib/css_classes.rb > get_project_css_class
  css_class: function() {
    var formattedId = this.get("id").toLowerCase().replace(/W/g, '-');
    return "project-" + formattedId;
  }
});

App.Projects = Backbone.Collection.extend({
  model: App.Project,
  url: "/" + TEAM_ID + "/projects"
});


///////////////////////////////////////////////////////////////
// View declarations
///////////////////////////////////////////////////////////////

App.FlashView = Backbone.View.extend({
  render: function(flashType, msg) {
    var flashMessage = "<div class='flash " + flashType + "'>" + msg + "</div>";
    
    if ($("#flash").length <= 0) {
      $(this.el).before("<div id='flash'></div>");
    }  
    
    $("#flash .flash").remove();
    // Flash the flash message
    $("#flash").append(flashMessage).hide(0, function() {
      $(this).fadeIn(1000);
    });
  },

  renderError: function() {
    this.render("warning", "Something weird happened. Please contact support about it.");
  }
});

App.TeamDialogView = Backbone.View.extend({
  events: {
    "click #team-name h2": "render",
    "click #new-team-form .submit-button": "handleNewTeamNameSubmit"
  },
  initialize: function() {
    $("#team-name-dialog").dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 470,
      minHeight: 65,
      autoOpen: false,
      position: 'top',
      closeText: "'"
    });
  },
  render: function() {
    $("#team-name-dialog").dialog('open');
    $("#team-name #team-name-form input:first").focus();
    overlayCloseOnClick();

    return this;
  },
  handleNewTeamNameSubmit: function(event) {
    var submitButton = event.target;
    var inputField = $(submitButton).parent().find(".new-object-text-box");

    // Hijack submit button if nothing is in textbox (either empty or labelified value)
    if (($(inputField).val() == "") ||
         $(inputField).val() == $(inputField).attr("title")) {
      $(inputField).focus();
      return false; // Don't submit form
    }

    return true; // Carry on
  }
});

App.TimetableViewSelector = Backbone.View.extend({
  initialize: function() {
    // Show team view by default
    this._showTeamView();
  },
  events: { 
    "click #view-selector li a": "render"
  },
  render: function(event) {
    var viewLink = event.target;
    var currentViewId = $("#view-selector .active").attr("id");
    var parentId = $(viewLink).parent().attr("id");

    if (parentId !== currentViewId) {
      // Clear view
      $('#content').empty();

      // Show relevant view
      if (parentId === "team-view-selector") {
        this._showTeamView();
      } else if (parentId === "project-view-selector") {
        this._showProjectView();
      }
      this._setActiveView("#" + parentId);
    }

    return false;
  },
  _setActiveView: function(viewSelector) {
    $("#view-selector .active").each(function() {
      $(this).removeClass("active");
    });
    $(viewSelector).addClass("active");
  },
  _showTeamView: function() {
    App.userListingView = App.userListingView || new App.UserListingView({ el: $("#main") });
    App.userListingView.render();
  },
  _showProjectView: function() {
    App.projectListingView = App.projectListingView || new App.ProjectListingView({ el: $("#main") });
    App.projectListingView.render();
  }
});

App.UserListingView = Backbone.View.extend({
  events: { 
    "click #new-team-member-form .submit-button": "handleNewUser"
  },
  initialize: function() {
    var listingView = this;
    App.users.bind('sync', function(user) {
      listingView._renderUser(user);
      App.flashView.render("success", "Successfully added '<em>" + user.get('name') + "</em>'.");
    });

    App.users.bind('error', function(response) {
      if (response) {
        try {
          respJson = JSON.parse(response.responseText);
          App.flashView.render(("warning", respJson["message"]));
        } catch(error) {
          console.log(error);
          App.flashView.renderError();
        }
      } else {
        App.flashView.renderError();
      }
    });
  },
  handleNewUser: function(event) {
    var inputField = $('input[name=new_team_member_name]');
    
    // Hijack submit button if nothing is in textbox (either empty or labelified value)
    if (($(inputField).val() == "") ||
         $(inputField).val() == $("#new-team-member-form .new-object-text-box").attr("title")) {

      $("#new-team-member-form .new-object-text-box").focus();
    } else {
      var tm = new App.User({
        name: inputField.val()
      });

      tm.save();
      App.users.add(tm);

      inputField.val('');
    }

    return false; // Don't submit form
  },
  // Either add to #main or replace #timetable
  render: function() {
    // Put week scaffold on page
    var weekTable = _.template($("#week-template").html());
    if ($("#timetable").length <= 0) {
      $(this.el).append(weekTable);
    } else {
      $("#timetable").replaceWith(weekTable);
    }
    var newUserRow = _.template($("#new-team-member-row-template").html());
    $("#timetable").append(newUserRow);
    labelifyTextBoxes();
    
    // Add team members
    var listingView = this;
    App.users.each(function(tm) {
      listingView._renderUser(tm);
    });

    return this;
  },
  _renderUser: function(user) {
    // console.log("Render team member row for: " + JSON.stringify(user) + " (" + user.get("id") + "): " + user.get("name"));
    
    var rowNum = $(this.el).find(".team-member").length + 1 + 1; // 1 to increment and 1 for header row
    var rowClass = "row" + rowNum;
    var oddOrEvenClass = rowNum % 2 == 0 ? "even" : "odd";
    var weekTemplateVars = {
      tmId: user.get("id"),
      tmName: user.get("name"),
      oddOrEvenClass: oddOrEvenClass,
      rowClass: rowClass,
      tmProjects: user.get("timetable_items"),
      isFirst: (App.users.first() == user)
    };
    var week = _.template($("#team-member-template").html(), weekTemplateVars);
    
    $(this.el).find('#content').append(week);

    setupEditUserDialog();
    setupNewProjectDialog();
    setupProjectEvents();
  }
});

App.ProjectListingView = Backbone.View.extend({
  render: function() {
    // Put week scaffold on page
    var weekTable = _.template($("#week-template").html());
    if ($("#timetable").length <= 0) {
      $(this.el).append(weekTable);
    } else {
      $("#timetable").replaceWith(weekTable);
    }

    var projectListingVars = {
      projects: App.teamProjects.toArray(),
      users: App.users.toArray()
    };
    var projectListing = _.template($("#project-listing-template").html(), projectListingVars);
    $("#content").append(projectListing);

    return this;
  }
});

App.ExistingProjectsView = Backbone.View.extend({
  events: {
    "click #existing-projects-listing button": "existingProjectButtonClickHandle"
  },
  render: function() {
    // TODO: Figure out how to DRY this up
    var existingProjTemplate = _.template($("#existing-projects-listing-template").html());
    var projListingHtml = existingProjTemplate({
      projects: App.teamProjects.toArray()
    });
    $(this.el).replaceWith(projListingHtml);
    this.setElement($("#existing-projects-listing")); // Re-initialise element after replacement

    return this;
  },
  existingProjectButtonClickHandle: function(event) {
    var button = event.target;

    // TODO: Figure out how to DRY this up
    var projectTemplate = _.template($("#existing-project-template").html());

    var userId = $(button).parents('#new-tm-project-form').find("input[name=team_member_id]").val();
    var projId = $(button).val();
    var projDate = $(button).parents('#new-tm-project-form').find("input[name=date]").val();
    var projName = $(button).attr("title");
    var projHandleCssClass = $(button).parent().find(".handle").attr("class");
    
    timetableItem = new App.TimetableItem({
      project_id: projId,
      project_name: projName,
      team_id: TEAM_ID,
      user_id: userId,
      date: projDate
    });
    
    timetableItem.save();
    
    // Show temporary project
    var tempProject = projectTemplate({
      tmId: userId,
      tmProjId: '',
      projHandleCssClass: projHandleCssClass,
      projDate: projDate,
      projName: projName
    });
    var projContainer = $(".box[data-team-member-id=" + userId + "][data-date='" + projDate + "']");

    $(projContainer).append(tempProject);      
    var newProj = $(projContainer).find(".project").last();
    $(newProj).addClass('is_loading');

    timetableItem.on("sync", function(resp) {
      var ttItem = resp.get("timetable_item");
      var tmProjId = ttItem["id"];
      
      // Regenerate project using template
      submittedProj = projectTemplate({
        tmId: userId,
        tmProjId: tmProjId,
        projHandleCssClass: projHandleCssClass,
        projDate: projDate,
        projName: projName
      });
      $(newProj).replaceWith(submittedProj);
      setupProjectEvents();

      // Update model
      App.users.addTimetableItemToUser(ttItem, userId);

      App.flashView.render("success", resp.get("message"));
    });
    timetableItem.on("error", function(data) {
      $(newProj).remove();
      $(newProj).removeClass('is_loading');
      
      App.flashView.render("warning", JSON.parse(data.responseText)["message"]);
    });

    // Hide dialog box
    $("#new-project-dialog").hide();
    
    return false;
  } // existingProjectButtonClickHandle
});

App.ProjectDialogView = Backbone.View.extend({
  // Can't figure out how to do this as per http://ricostacruz.com/backbone-patterns/#inline_templates
  //projectTemplate: _.template($("#existing-project-template").html()),

  events: {
    "click .box": "openProjectDialog"
  },
  openProjectDialog: function(event) {
    var box = event.target;
    this.render(box);

    $("#new-project-dialog form input[name=date]").val($(box).attr("data-date"));
    $("#new-project-dialog form input[name=team_member_id]").val($(box).attr("data-team-member-id"));
    
    // If clicked on weekend add class for weekend, and place dialog on the left
    // Otherwise, place dialog on the right
    $( "#new-project-dialog" ).removeClass("is-weekend");
    var new_project_dialog_top_offset = -46;
    var new_project_dialog_left_offset = 0;
    if ($(box).hasClass("col7") || $(box).hasClass("col8")) {
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
  }, // openProjectDialog

  render: function(box) {
    if ($("#new-project-dialog").length <= 0) {
      var newProjectDialog = _.template($("#new-project-dialog-template").html());
      $(this.el).append(newProjectDialog());

      // Add project to existing project list
      this.existingProjectsView().render();

      this.setupNewProjectDialog(box, this);

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
      }); // keydown
    }

    return this;
  },

  existingProjectsView: function() {
    return new App.ExistingProjectsView({el: $("#existing-projects-listing")});
  },

  setupNewProjectDialog: function(box, projectDialog) {
    // Hide if clicking outside #new-project-dialog
    $('html').click(function() {
      $("#new-project-dialog").hide();
    });
    
    $("#new-project-dialog").click(function(event) {
      event.stopPropagation(); // Prevent clicking on form from hiding the form
    });

    $("#new-project-dialog .close").click(function() {
      $("#new-project-dialog").hide();
      return false;
    });



    // Delete project link
    $("#new-project-dialog .delete").click(function() {
      $( "#delete-project-dialog" ).dialog('open');
      $("#new-project-dialog").hide();
      overlayCloseOnClick();

      // Fill in form
      var deleteProjectDialog = _.template($("#delete-project-dialog-template").html());

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
    }); // $("#new-project-dialog .delete")

    // AJAX-ify add existing project
    var projectTemplate = _.template($("#existing-project-template").html());
    var existingProjectsTemplate = _.template($("#existing-projects-listing-template").html());

    // AJAX-ify add new project
    $("#new-project-dialog .new-object-fieldset .submit-button").click(function() {
      var userId = $(this).parents('#new-tm-project-form').find("input[name=team_member_id]").val();
      var projDate = $(this).parents('#new-tm-project-form').find("input[name=date]").val();
      var projNameTextbox = $(this).parent().find("input[name=project_name]");
      var projName = projNameTextbox.val();
      
      if (projName.length <= 0) {
        // Focus textbox and exit
        $(projNameTextbox).focus();
      } else {
        var timetableItem = new App.TimetableItem({
          // No project_id because it is new
          project_name: projName,
          team_id: TEAM_ID,
          user_id: userId,
          date: projDate
        });
        
        timetableItem.save();
        
        // Show temporary project
        var tempProject = projectTemplate({
          tmId: userId,
          tmProjId: '',
          projHandleCssClass: 'handle',
          projDate: projDate,
          projName: projName
        });
        var projContainer = $(".box[data-team-member-id=" + userId + "][data-date='" + projDate + "']");

        $(projContainer).append(tempProject);      
        var newProj = $(projContainer).find(".project").last();
        $(newProj).addClass('is_loading');

        timetableItem.on("sync", function(resp) {
          var ttItem = resp.get("timetable_item");
          var tmProjId = ttItem["id"];

          // Update project styles
          var retProj = new App.Project(resp.get("project"));
          App.teamProjects.add(retProj);

          var projectCssSel = '.' + retProj.css_class();
          var projectCssStyle = 'background-color: ' + retProj.get("hex_colour") + ';';
          var projectStyles = document.createStyleSheet();
          projectStyles.addRule(projectCssSel, projectCssStyle);
          
          // Add project to existing project list
          projectDialog.existingProjectsView().render();

          // Regenerate project using template
          submittedProj = projectTemplate({
            tmId: userId,
            tmProjId: tmProjId,
            projHandleCssClass: 'handle ' + retProj.css_class(),
            projDate: projDate,
            projName: projName
          });
          $(newProj).replaceWith(submittedProj);

          setupProjectEvents();

          // Update model
          App.users.addTimetableItemToUser(ttItem, userId);

          App.flashView.render("success", resp.get("message"));
        });
        timetableItem.on("error", function(data) {
          $(newProj).remove();
          $(newProj).removeClass('is_loading');
          
          App.flashView.render("warning", JSON.parse(data.responseText)["message"]);
        });

        // Clear new project name textbox
        $("#new-project-dialog .new-object-fieldset input[name=project_name]").val("");

        // Hide dialog box
        $("#new-project-dialog").hide();
      }

      setupProjectEvents();

      return false;
    }); // $("#new-project-dialog .new-object-fieldset .submit-button").click

    setupProjectEvents();
  } // setupNewProjectDialog
});


///////////////////////////////////////////////////////////////
// Setup
///////////////////////////////////////////////////////////////

$(function () {

  // Dynamically add stylesheets
  // From http://stackoverflow.com/a/524798
  if (typeof document.createStyleSheet === 'undefined') {
    document.createStyleSheet = (function() {
      function createStyleSheet(href) {
        if(typeof href !== 'undefined') {
          var element = document.createElement('link');
          element.type = 'text/css';
          element.rel = 'stylesheet';
          element.href = href;
        }
        else {
          var element = document.createElement('style');
          element.type = 'text/css';
        }

        document.getElementsByTagName('head')[0].appendChild(element);
        var sheet = document.styleSheets[document.styleSheets.length - 1];

        if(typeof sheet.addRule === 'undefined')
          sheet.addRule = addRule;

        if(typeof sheet.removeRule === 'undefined')
          sheet.removeRule = sheet.deleteRule;

        return sheet;
      }

      function addRule(selectorText, cssText, index) {
        if(typeof index === 'undefined')
          index = this.cssRules.length;

        this.insertRule(selectorText + ' {' + cssText + '}', index);
      }

      return createStyleSheet;
    })();
  }
  
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
  
  // Declare dialogs (but don't open by default)
  {
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
  
  // Add help body class
  $("#top-nav .action-bar .help").click(function() {
    $("body").toggleClass("help-on");
    
    return false;
  });
  
  //remove help body class
  $("#overlay-bg, #help-nav, #help-week, #help-new, #help-close, #help-project, help-team").click(function() {
    $("body").removeClass("help-on");
  });

  labelifyTextBoxes();
});


///////////////////////////////////////////////////////////////
// Helper functions
///////////////////////////////////////////////////////////////

function setupProjectEvents() {
  $(".project").click(function(event) {
    $("#new-project-dialog").hide();
    event.stopPropagation(); // Prevent opening new project dialog
  });

  // Timetable item delete button
  // Only show on hover
  $(".project .delete-tm-project-form button").hide();
  $(".project").hover(
    function() {
      $(this).find(".delete-tm-project-form button").fadeIn(200);
    },
    function() {
      $(this).find(".delete-tm-project-form button").fadeOut(100);
    }
  );
  
  // AJAX-ify delete
  $(".project .delete-tm-project-form button").click(
    function(event) {
      deleteTimetableItem($(this).first().parents(".project").first());
      return false;
    }
  ); // $(".project .delete-tm-project-form button").click

  // Hide project add button on .project hover
  $(".project").hover(
    function() {
      $(this).parents(".box").addClass("remove-add-img")
    },
    function() {
      $(this).parents(".box").removeClass("remove-add-img")
    }
  );
}

function setupNewProjectDialog() {
  // Drag and drop for projects
  $('table .box').sortable({
      connectWith: '.box',
      cursor: 'move',
      placeholder: 'placeholder',
      forcePlaceholderSize: true,
      opacity: 0.4,
      stop: function(event, ui) {
        var project = ui.item;
        var projectUserId = $(project).attr("data-team-member-id");
        var projectDate = $(project).attr("data-date");
        
        var containerUserId = $(project).parents(".team-member").first().attr("data-team-member-id");
        var containerDate = $(project).parents(".box").first().attr("data-date");
        
        if ((projectUserId != containerUserId) || (projectDate != containerDate)) {
          updateTimetableItem(project);
        }
        
        // Hide new dialog in case a click gets triggered and shows it
        $("#new-project-dialog").hide();
      }
  })
  .disableSelection();
}

function setupEditUserDialog() {
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
  var fromUserId = $(proj).attr("data-team-member-id");
  var toUserId = $(proj).parents('.team-member').first().attr("data-team-member-id");
  var timetableItemId = $(proj).attr("data-team-member-project-id");
  var toDate = $(proj).parents('.box').first().attr("data-date");
    
  var url = "/" + TEAM_ID + "/team-member-project/" + timetableItemId + "/update.json";
  $(proj).addClass('is_loading');
  $.post(url, { from_team_member_id: fromUserId, to_team_member_id: toUserId, to_date: toDate })
    .success(function(resp) {
      // Update team member project info in data attributes
      $(proj).attr("data-team-member-id", toUserId);
      $(proj).attr("data-date", toDate);
      
      // Update delete link
      var delete_url = $(proj).find(".delete-tm-project-form").attr("action");
      // Should be in the form /team-member/[team member id]/project/[team member project id]/delete
      var old_team_member_id = delete_url.split("/")[2];
      var new_delete_url = delete_url.replace(old_team_member_id, toUserId);
      $(proj).find(".delete-tm-project-form").attr("action", new_delete_url);

      setupProjectEvents();

      // Update model
      App.users.updateTimetableItemForUser(resp["timetable_item"], fromUserId, toUserId);
    })
    .error(function(response) {
      // Move team member project back
      var fromDate = $(proj).attr("data-date");
      var fromLocation = $(".team-member[data-team-member-id=" + fromUserId + "]").find(".box[data-date=" + fromDate + "]");
      
      $(proj).remove();
      $(fromLocation).append(proj);
    })
    .complete(function(data, status) {
      response = JSON.parse(data.responseText);
      if (status == "success") {
        App.flashView.render("success", response["message"]);
      } else {
        if (response) {
          App.flashView.render("warning", response["message"]);
        } else {
          App.flashView.render("warning", "Something weird happened. Please contact support about it.");
        }
      }
      
      $(proj).removeClass('is_loading');
    });
  
}

// Delete team member project
function deleteTimetableItem(proj) {
  var deleteButton = $(proj).find(".delete-tm-project-form button");

  if ($(deleteButton).is(":enabled")) {
    var userId = $(proj).attr("data-team-member-id");
    var timetableItemId = $(proj).attr("data-team-member-project-id");
      
    var url = "/team-member/" + userId + "/project/" + timetableItemId + "/delete.json";
    $(proj).addClass('is_loading');
    $(deleteButton).attr("disabled", "disabled");

    $.post(url)
      .success(function(resp) {
        $(proj).fadeOut("slow", function() {
          $(this).remove();

          // Remove from collection
          App.users.removeTimetableItemIdFromUser(resp["timetable_item_id"], userId);
        });
      })
      .error(function(response) {
        // Re-enable delete button
        $(deleteButton).removeAttr("disabled");
        setupProjectEvents();
      })
      .complete(function(data, status) {
        response = JSON.parse(data.responseText);
        if (status == "success") {
          App.flashView.render("success", response["message"]);
        } else {
          if (response) {
            App.flashView.render("warning", response["message"]);
          } else {
            App.flashView.render("warning", "Something weird happened. Please contact support about it.");
          }
        }
        
        $(proj).removeClass('is_loading');
      });
  }
}

})();


///////////////////////////////////////////////////////////////
// Helper functions
///////////////////////////////////////////////////////////////

// Labelify new object text boxes
function labelifyTextBoxes() {
  $(".new-object-text-box").labelify({ labelledClass: "new-object-text-box-label" });
}

// Overlays - close dialogs when clicking (Note: need to run this after dialogs are created)
function overlayCloseOnClick() {
  $(".ui-widget-overlay").live('click', function(){
     $(".ui-dialog-titlebar-close").trigger('click');
  });
}

