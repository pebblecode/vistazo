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

App.UserTimetable = Backbone.Model.extend({
  // // Use user_id as the id
  idAttribute: "user_id",
  // Convenience method fo getting access to the user name
  userName: function() {
    var user = App.users.get(this.get("user_id"));

    if (user === undefined) {
      console.log("Undefined user (for userName): " + this.escape("user_id"));
      return "";
    } else {
      return user.escape("name");  
    }
  },
  // Convenience method fo getting access to the user email
  userEmail: function() {
    var user = App.users.get(this.get("user_id"));

    if (user === undefined) {
      console.log("Undefined user (for userEmail): " + this.escape("user_id"));
      return "";
    } else {
      return user.escape("email");
    }
  },
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

App.UserTimetables = Backbone.Collection.extend({
  model: App.UserTimetable,
  addTimetableItemForUser: function(ttItem, userId) {
    var userTimetable = this.get(userId);
    userTimetable.addTimetableItem(ttItem);
  },
  removeTimetableItemIdFromUser: function(ttItemId, userId) {
    var userTimetable = this.get(userId);
    userTimetable.removeTimetableItemId(ttItemId);
  },
  updateTimetableItemForUser: function(ttItem, fromUserId, toUserId) {
    this.removeTimetableItemIdFromUser(ttItem["id"], fromUserId);
    this.addTimetableItemForUser(ttItem, toUserId);
  },

  // Array of timetables that are visible
  visibleTimetables: function() {
    return _.filter(this.models, function(tt) {
      return tt.get("is_visible") === true;
    });
  },
  // Array of other timetables that are not visible
  otherTimetables: function() {
    return _.filter(this.models, function(tt) {
      return tt.get("is_visible") !== true;
    });
  }  
});

App.User = Backbone.Model.extend({
  defaults: {
    name: "",
    email: ""
  },
  // Can't use built in validate because of http://stackoverflow.com/q/9709968/111884
  hasErrors: function() {
    errors = {};
    if (_.isEmpty(this.get("name"))) {
      errors["name"] = "Name can't be blank";
    }

    var email = this.get("email");
    // Regex from http://www.regular-expressions.info/email.html
    var valid_email = email.match(/(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i);
    if (_.isEmpty(email)) {
      errors["email"] = "Email can't be blank";
    } else if (!valid_email) {
      errors["email"] = "Email is invalid";
    }

    return _.any(errors) ? errors : null;
  }
});

App.Users = Backbone.Collection.extend({
  model: App.User
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
    return "/" + this.get("team_id") + "/users/" + this.get("user_id") + "/timetable-items/new.json";
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
    return "project-" + _.escape(formattedId);
  }
});

App.Projects = Backbone.Collection.extend({
  model: App.Project
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
    if (this._isMonthPage()) {
      this._showMonthView();
      this._setActiveView("#view-selector #month-view-selector");
    } else if (this._isTeamPage()) {
      this._showTeamView();
      this._setActiveView("#view-selector #team-view-selector");
    } else if (this._isProjectPage()) {
      this._showProjectView();
      this._setActiveView("#view-selector #project-view-selector");
    } else {
      console.log("Unknown timetable page");
    }
  },
  events: { 
    "click #view-selector li a": "render"
  },
  render: function(event) {
    var viewLink = event.target;
    var currentViewId = $("#view-selector .active").attr("id");
    var parentId = $(viewLink).parent().attr("id");

    if (parentId !== currentViewId) {
      if (this._isMonthPage()) {
        // Do nothing, let it pass through to the link location
      } else {
        if (parentId === "team-view-selector") {
          $('#content').empty();

          this._showTeamView();
          this._setActiveView("#" + parentId);
          event.preventDefault();
        } else if (parentId === "project-view-selector") {
          $('#content').empty();

          this._showProjectView();
          this._setActiveView("#" + parentId);
          event.preventDefault();
        } else if (parentId === "month-view-selector") {
          // Do nothing, let it pass through to the link location
        }
      }
    } else {
      event.preventDefault();
    }
  },
  _projectPageHashValue: "project-view",
  _isMonthPage: function() {
    return window.location.pathname.split('/')[3] === "month";
  },
  _isTeamPage: function() {
    var isWeekPage = (window.location.pathname.split('/')[3] === "week");
    var notProjectView = !(window.location.hash.substring(1) === this._projectPageHashValue);

    return (isWeekPage && notProjectView);
  },
  _isProjectPage: function() {
    var isWeekPage = (window.location.pathname.split('/')[3] === "week");
    var isProjectView = (window.location.hash.substring(1) === this._projectPageHashValue);

    return (isWeekPage && isProjectView);
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

    window.location.hash = "";
    replaceClass("#timetable", "week-view");
  },
  _showProjectView: function() {
    App.projectListingView = App.projectListingView || new App.ProjectListingView({ el: $("#main") });
    App.projectListingView.render();

    window.location.hash = this._projectPageHashValue;
    replaceClass("#timetable", "project-view");
  },
  _showMonthView: function() {
    App.monthListingView = App.monthListingView || new App.MonthListingView({ el: $("#main") });
    App.monthListingView.render();
  }
});

App.AddUserDialogView = Backbone.View.extend({
  events: { 
    "click #add-user-button": "render"
  },
  initialize: function() {
    var addUserDialog = _.template($("#add-user-dialog-template").html());
    $(this.el).append(addUserDialog);
    $("#add-user-dialog").dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 470,
      minHeight: 65,
      autoOpen: false,
      position: 'top',
      closeText: "'"
    });
  },
  render: function(event) {
    // Remove errors
    $("#add-user-form-errors").remove();

    $("#add-user-dialog").dialog('open');
    overlayCloseOnClick();

    event.preventDefault();
  }
});

App.EditUserDialogView = Backbone.View.extend({
  events: {
    // For both visible and other user timetables
    "click .week-view .user-name": "render"
  },
  render: function(event) {
    var nameButton = event.target;
    var editUserDialogId = "#edit-user-dialog";

    var userId = $(nameButton).parents(".user").first().attr("data-user-id");
    var userTimetable = App.userTimetables.get(userId);
    var editUserVars = {
      userTimetable: userTimetable
    };

    // Create dialog
    var editUserDialog = _.template($("#edit-user-dialog-template").html(), editUserVars);

    if ($(editUserDialogId).length <= 0) {
      $(this.el).append(editUserDialog);
    } else {
      $(editUserDialogId).replaceWith(editUserDialog);
    }

    $(editUserDialogId).dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 470,
      minHeight: 85,
      autoOpen: true,
      position: 'top',
      closeText: "'",
      open: function() {
        overlayCloseOnClick();
      },
      close: function() {
        $(editUserDialogId).remove();
      }
    });

    event.preventDefault();
  }
});



App.UserListingView = Backbone.View.extend({
  events: { 
    "click #add-user-dialog .submit-button": "handleNewUser"
  },
  handleNewUser: function(event) {
    var newUser = new App.User({
      name: $('input[name=name]').val(),
      email: $('input[name=email]').val()
    });

    var errors = newUser.hasErrors();
    if (!errors) {
      
      this._addUserToUserTimetables(newUser);

      $('input[name=name]').val('');
      $('input[name=email]').val('');
      $('input[name=is_visible]').prop("checked", true);

      $("#add-user-dialog").dialog('close');
    } else {
      errorsHtml = _.template($("#errors-template").html(), {
        id: "add-user-form-errors",
        errors: errors
      });
      if ($("#add-user-form-errors").length > 0) {
        $("#add-user-form-errors").replaceWith(errorsHtml);
      } else {
        $("#add-user-form").prepend(errorsHtml);
      }

      $("#add-user-form-errors").hide(0, function() {
        $(this).fadeIn(1000);
      });
      $("#add-user-form input[name=name]").focus();
    }

    event.preventDefault();
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
    var newUserRow = _.template($("#new-user-row-template").html());
    $("#timetable").append(newUserRow);
    labelifyTextBoxes();
    
    // Show users
    this._renderVisibleUserTimetables();
    this._renderOtherUsers();

    return this;
  },
  _addUserToUserTimetables: function(user) {
    var url = "/" + TEAM_ID + "/user-timetables/new-user.json";
    var listingView = this;

    $.post(url, $("#add-user-form").serialize())
    .success(function(response) {
      var user = new App.User(response["user"]);
      App.users.add(user);

      var userTimetable = new App.UserTimetable(response["user_timetable"]);
      App.userTimetables.add(userTimetable);

      if (userTimetable.get("is_visible") === true) {
        listingView._renderVisibleUserTimetable(userTimetable);  
      } else {
        listingView._renderOtherUsers(userTimetable);
      }
      
      App.flashView.render("success", "Successfully added '" + user.escape('name') + "'.");
    })
    .error(function(data) {
      if (data) {
        try {
          response = JSON.parse(data.responseText);
          App.flashView.render("warning", response["message"]);
        } catch(error) {
          console.log(error);
          App.flashView.renderError();
        }
      } else {
        App.flashView.renderError();
      }
    });
  },
  _renderVisibleUserTimetables: function() {
    thisView = this;
    _.each(App.userTimetables.visibleTimetables(), function(userTimetable) {
      thisView._renderVisibleUserTimetable(userTimetable);
    });
  },
  _renderVisibleUserTimetable: function(userTimetable) {
    // console.log("Render team member row for: " + JSON.stringify(user) + " (" + user.escape("id") + "): " + user.escape("name"));
    
    var rowNum = $(this.el).find(".user").length + 1 + 1; // 1 to increment and 1 for header row
    var oddOrEvenClass = rowNum % 2 == 0 ? "even" : "odd";
    var userTemplateVars = {
      userTimetable: userTimetable,
      oddOrEvenClass: oddOrEvenClass
    };
    var userTimetableHtml = _.template($("#visible-user-template").html(), userTemplateVars);
    
    $(this.el).find('#content').append(userTimetableHtml);

    setupNewProjectDialog();
    setupProjectEvents();
  },

  _renderOtherUsers: function() {
    var otherUsersVars = {
      userTimetables: App.userTimetables.otherTimetables()
    };
    var otherUsersHtml = _.template($("#other-users-template").html(), otherUsersVars);

    if ($("#other-users").length > 0) {
      $("#other-users").replaceWith(otherUsersHtml);
    } else {
      $("#new-user-row").after(otherUsersHtml);  
    }
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
      userTimetables: App.userTimetables.toArray()
    };
    var projectListing = _.template($("#project-listing-template").html(), projectListingVars);
    $("#content").append(projectListing);

    return this;
  }
});

App.MonthListingView = Backbone.View.extend({
  render: function() {
    // Put month scaffold on page
    var monthTable = _.template($("#month-template").html());
    if ($("#timetable").length <= 0) {
      $(this.el).append(monthTable);
    } else {
      $("#timetable").replaceWith(monthTable);
    }
    // Show users
    this._renderVisibleUserTimetables();
    // this._renderOtherUsers(); // TODO

    return this;
  },
  _renderVisibleUserTimetables: function() {
    thisView = this;
    _.each(App.userTimetables.visibleTimetables(), function(userTimetable) {
      thisView._renderVisibleUserTimetable(userTimetable);
    });
  },
  _renderVisibleUserTimetable: function(userTimetable) {
    // console.log("Render team member row for: " + JSON.stringify(user) + " (" + user.escape("id") + "): " + user.escape("name"));
    
    var rowNum = $(this.el).find(".user").length + 1 + 1; // 1 to increment and 1 for header row
    var oddOrEvenClass = rowNum % 2 == 0 ? "even" : "odd";
    var userTemplateVars = {
      userTimetable: userTimetable,
      oddOrEvenClass: oddOrEvenClass
    };
    var userTimetableHtml = _.template($("#month-visible-user-template").html(), userTemplateVars);
    
    $(this.el).find('#content').append(userTimetableHtml);

    setupNewProjectDialog();
    setupProjectEvents();
  },
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

    var userId = $(button).parents('#new-timetable-item-form').find("input[name=team_member_id]").val();
    var projId = $(button).val();
    var projDate = $(button).parents('#new-timetable-item-form').find("input[name=date]").val();
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
    var projContainer = $(".box[data-user-id=" + userId + "][data-date='" + projDate + "']");

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
      App.userTimetables.addTimetableItemForUser(ttItem, userId);

      App.flashView.render("success", resp.escape("message"));
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
    $("#new-project-dialog form input[name=team_member_id]").val($(box).attr("data-user-id"));
    
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

      // Set up delete project dialog view - only gets called 
      // when needed
      this.deleteProjectDialogView();

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

  deleteProjectDialogView: function() {
    return new App.DeleteProjectDialogView({ el: $("#new-project-dialog") });
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

    // AJAX-ify add existing project
    var projectTemplate = _.template($("#existing-project-template").html());
    var existingProjectsTemplate = _.template($("#existing-projects-listing-template").html());

    // AJAX-ify add new project
    $("#new-project-dialog .new-object-fieldset .submit-button").click(function() {
      var userId = $(this).parents('#new-timetable-item-form').find("input[name=team_member_id]").val();
      var projDate = $(this).parents('#new-timetable-item-form').find("input[name=date]").val();
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
        var projContainer = $(".box[data-user-id=" + userId + "][data-date='" + projDate + "']");

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
          var projectCssStyle = 'background-color: ' + retProj.escape("hex_colour") + ';';
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
          App.userTimetables.addTimetableItemForUser(ttItem, userId);

          App.flashView.render("success", resp.escape("message"));
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

App.DeleteProjectDialogView = Backbone.View.extend({
  events: {
    "click #new-project-dialog .delete": "render"
  },
  render: function(event) {
    var button = event.target;
    var deleteProjectDialog = _.template($("#delete-project-dialog-template").html());

    $("#main").append(deleteProjectDialog({
      teamId: TEAM_ID, 
      projectId: $(button).parent().find("button[name=project_id]").val(),
      projectName: $(button).parent().find("button[name=project_id]").text()
    }));
    $("#delete-project-dialog").dialog({
      modal: true,
      closeOnEscape: true,
      minWidth: 480,
      minHeight: 70,
      position: 'top',
      autoOpen: true,
      closeText: "'",
      open: function() {
        overlayCloseOnClick();
      },
      close: function() {
        $("#delete-project-dialog").remove();
      }
    });

    event.preventDefault();
  } // render

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
  $(".project .delete-timetable-item-form button").hide();
  $(".project").hover(
    function() {
      $(this).find(".delete-timetable-item-form button").fadeIn(200);
    },
    function() {
      $(this).find(".delete-timetable-item-form button").fadeOut(100);
    }
  );
  
  // AJAX-ify delete
  $(".project .delete-timetable-item-form button").click(
    function(event) {
      deleteTimetableItem($(this).first().parents(".project").first());
      return false;
    }
  ); // $(".project .delete-timetable-item-form button").click

  // Hide project add button on .project hover
  $(".project").hover(
    function() {
      $(this).parents(".box").addClass("remove-add-img")
    },
    function() {
      $(this).parents(".box").removeClass("remove-add-img")
    }
  );

  // Add tool tips (for month view only)
  {
    var projectRegex = /(project-.+)/;
    $("#timetable.month-view .handle").tipTip({
      delay: 25,
      enter: function(event) {
        var handleElem = event.target;
        var handleClass = $(handleElem).attr("class");

        // Add project class to tip tip content
        if (projectRegex.test(handleClass)) {
          var projectClass = handleClass.match(projectRegex)[1];
          replaceClass("#tiptip_content", projectClass);
        }
      }
    });
  }
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
        var projectUserId = $(project).attr("data-user-id");
        var projectDate = $(project).attr("data-date");
        
        var containerUserId = $(project).parents(".user").first().attr("data-user-id");
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

// Update timetable item
function updateTimetableItem(proj) {
  var fromUserId = $(proj).attr("data-user-id");
  var toUserId = $(proj).parents('.user').first().attr("data-user-id");
  var timetableItemId = $(proj).attr("data-timetable-item-id");
  var toDate = $(proj).parents('.box').first().attr("data-date");
    
  var url = "/" + TEAM_ID + "/timetable-items/" + timetableItemId + "/update.json";
  $(proj).addClass('is_loading');
  $.post(url, { from_user_id: fromUserId, to_user_id: toUserId, to_date: toDate })
    .success(function(response) {
      // Update timetable item info in data attributes
      $(proj).attr("data-user-id", toUserId);
      $(proj).attr("data-date", toDate);
      
      // Update delete link
      var delete_url = $(proj).find(".delete-timetable-item-form").attr("action");
      // Should be in the form /users/[user id]/project/[timetable id]/delete
      var old_user_id = delete_url.split("/")[2];
      var new_delete_url = delete_url.replace(old_user_id, toUserId);
      $(proj).find(".delete-timetable-item-form").attr("action", new_delete_url);

      setupProjectEvents();

      // Update model
      App.userTimetables.updateTimetableItemForUser(response["timetable_item"], fromUserId, toUserId);
      App.flashView.render("success", response["message"]);
      
      $(proj).removeClass('is_loading');
    })
    .error(function(data) {
      // Move timetable item back
      var fromDate = $(proj).attr("data-date");
      var fromLocation = $(".user[data-user-id=" + fromUserId + "]").find(".box[data-date=" + fromDate + "]");
      
      $(proj).remove();
      $(fromLocation).append(proj);

      setupProjectEvents();
      $(proj).removeClass('is_loading');

      try {
        response = JSON.parse(data.responseText);
        if (response) {
          App.flashView.render("warning", respJson["message"]);
        } else {
          App.flashView.renderError();  
        }
      } catch(error) {
        console.log(error);
        App.flashView.renderError();
      }

    });
  
}

// Delete timetable item
function deleteTimetableItem(proj) {
  var deleteButton = $(proj).find(".delete-timetable-item-form button");

  if ($(deleteButton).is(":enabled")) {
    var userId = $(proj).attr("data-user-id");
    var timetableItemId = $(proj).attr("data-timetable-item-id");
      
    var url = "/" + TEAM_ID + "/users/" + userId + "/timetable-items/" + timetableItemId + "/delete.json";
    $(proj).addClass('is_loading');
    $(deleteButton).attr("disabled", "disabled");

    $.post(url)
      .success(function(resp) {
        $(proj).fadeOut("slow", function() {
          $(this).remove();

          // Remove from collection
          App.userTimetables.removeTimetableItemIdFromUser(resp["timetable_item_id"], userId);
        });
      })
      .error(function(response) {
        // Re-enable delete button
        $(deleteButton).removeAttr("disabled");
        setupProjectEvents();
      })
      .complete(function(data, status) {
        $(proj).removeClass('is_loading');

        try {
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
        } catch(error) {
          console.log(error);
          App.flashView.renderError();
        }
      });
  }
}

})();


///////////////////////////////////////////////////////////////
// Helper functions
///////////////////////////////////////////////////////////////

// Delete the class attribute and replace with new class
function replaceClass(selector, newClass) {
  $(selector).attr("class", "");
  $(selector).addClass(newClass);
}

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

